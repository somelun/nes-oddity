const std = @import("std");
const AutoHashMap = std.AutoHashMap;

const RAM = @import("ram.zig").RAM;

const OpcodesAPI = @import("opcodes.zig");
const Opcode = OpcodesAPI.Opcode;
const AddressingMode = OpcodesAPI.AddressingMode;

const program_counter_address: u16 = 0xFFFC;

const StatusFlag = enum(u8) {
    C = (1 << 0), // carry
    Z = (1 << 1), // zero
    I = (1 << 2), // interrupt disable
    D = (1 << 3), // decimal
    B = (1 << 4), // break
    U = (1 << 5), // unused?
    V = (1 << 6), // overflow
    N = (1 << 7), // negative
};

pub const CPU = struct {
    register_a: u8 = 0x00,
    register_x: u8 = 0x00,
    register_y: u8 = 0x00,
    status: u8 = 0x00,
    stack_pointer: u8 = 0xFF,
    program_counter: u16 = 0x0000,

    memory: RAM,
    opcodes: AutoHashMap(u8, Opcode),

    pub fn init() CPU {
        return CPU{
            .memory = RAM.init(),
            .opcodes = OpcodesAPI.generateOpcodes(),
        };
    }

    pub fn reset(self: *CPU) void {
        self.register_a = 0;
        self.register_x = 0;
        self.status = 0;

        self.program_counter = self.memory.read16(program_counter_address);
    }

    pub fn loadAndRun(self: *CPU, program_code: []const u8) void {
        self.load(program_code);
        self.reset();
        self.run();
    }

    fn load(self: *CPU, program_code: []const u8) void {
        self.memory.loadProgram(program_code);

        // program counter stored in memory at 0xFFFC
        self.memory.write16(program_counter_address, 0x8000);
    }

    fn getOperandAddress(self: *CPU, mode: AddressingMode) u16 {
        var address: u16 = undefined;

        switch (mode) {
            AddressingMode.Implied => {},

            AddressingMode.Accumulator => {
                address = self.register_a;
            },

            AddressingMode.Immediate => {
                address = self.program_counter;
                self.program_counter += 1;
            },

            AddressingMode.ZeroPage => {
                address = self.memory.read8(self.program_counter);
                self.program_counter += 1;
            },

            AddressingMode.ZeroPageX => {
                address = self.memory.read8(self.program_counter) +% self.register_x;
                self.program_counter += 1;
            },

            AddressingMode.ZeroPageY => {
                address = self.memory.read8(self.program_counter) +% self.register_y;
                self.program_counter += 1;
            },

            AddressingMode.Relative => {
                const offset: u8 = self.memory.read8(self.program_counter);
                self.program_counter += 1;

                address = self.program_counter + offset;
                if (offset >= 0x80) {
                    address -= 0x0100;
                }
            },

            AddressingMode.Absolute => {
                address = self.memory.read16(self.program_counter);
                self.program_counter += 2;
            },

            AddressingMode.AbsoluteX => {
                address = self.memory.read16(self.program_counter) +% self.register_x;
                self.program_counter += 2;
            },

            AddressingMode.AbsoluteY => {
                address = self.memory.read16(self.program_counter) +% self.register_y;
                self.program_counter += 2;
            },

            AddressingMode.Indirect => {
                const ptr: u16 = self.memory.read16(self.program_counter);
                self.program_counter += 2;

                // TODO: test this
                if (ptr & 0x00FF == 0x00FF) {
                    address = (@intCast(u16, self.memory.read8(ptr & 0xFF00)) << 8) | self.memory.read8(ptr + 0);
                } else {
                    address = (@intCast(u16, self.memory.read8(ptr + 1)) << 8) | self.memory.read8(ptr + 0);
                }
            },

            AddressingMode.IndirectX => {
                const ptr: u8 = self.memory.read8(self.program_counter) +% self.register_x;
                self.program_counter += 1;

                const lo: u16 = self.memory.read8(ptr);
                const hi: u16 = self.memory.read8(ptr +% 1);
                address = (hi << 8) | (lo);
            },

            AddressingMode.IndirectY => {
                const base: u8 = self.memory.read8(self.program_counter);
                self.program_counter += 1;

                const lo: u16 = self.memory.read8(base);
                const hi: u16 = self.memory.read8(base +% 1);

                const deref = (hi << 8) | (lo);
                address = deref +% self.register_y;
            },
        }

        return address;
    }

    fn run(self: *CPU) void {
        while (self.program_counter < 0xFFFC) { //TODO: remove magic number
            const value = self.memory.read8(self.program_counter);
            self.program_counter += 1;

            const opcode: ?Opcode = self.opcodes.get(value);
            if (opcode == null) {
                continue;
            }

            const addressing_mode = opcode.?.addressing_mode;

            switch (value) {
                // ADC
                0x69, 0x65, 0x75, 0x6D, 0x7D, 0x79, 0x61, 0x71 => {
                    self._adc(addressing_mode);
                },

                // AND
                0x29, 0x25, 0x35, 0x2D, 0x3D, 0x39, 0x21, 0x31 => {
                    self._and(addressing_mode);
                },

                // ASL
                0x0A, 0x06, 0x16, 0x0E, 0x1E => {
                    self._asl(addressing_mode);
                },

                // BCC
                0x90 => {
                    self._bcc();
                },

                // BCS
                0xB0 => {
                    self._bcs();
                },

                // BEQ
                0xF0 => {
                    self._beq();
                },

                // BRK
                0x00 => {},

                // CLC
                0x18 => {
                    self._clc();
                },

                // LDA
                0xA9, 0xA5, 0xB5, 0xAD, 0xBD, 0xB9, 0xA1, 0xB1 => {
                    self._lda(addressing_mode);
                },

                // TAX
                0xAA => {
                    self._tax();
                },

                // INX
                0xE8 => {
                    self._inx();
                },

                // unknown instruction or already used data
                else => {},
            }
        }
    }

    fn updateZeroAndNegativeFlag(self: *CPU, value: u8) void {
        self.updateZeroFlag(value);
        self.updateNegativeFlag(value);
    }

    fn setFlag(self: *CPU, flag: StatusFlag, value: bool) void {
        const number = @enumToInt(flag);
        if (value) {
            self.status = self.status | number;
        } else {
            self.status = self.status & (~number);
        }
    }

    fn getFlag(self: *CPU, flag: StatusFlag) u8 {
        const number = @enumToInt(flag);
        return if (self.status & number > 0) 1 else 0;
    }

    fn updateZeroFlag(self: *CPU, value: u8) void {
        if (value == 0) {
            self.status = self.status | 0b0000_0010;
        } else {
            self.status = self.status & 0b1111_1101;
        }
    }

    fn updateNegativeFlag(self: *CPU, value: u8) void {
        if (value & 0b1000_0000 != 0) {
            self.status = self.status | 0b1000_0000;
        } else {
            self.status = self.status & 0b0111_1111;
        }
    }

    ///////////////////////////////////////////////////////
    // Instructions

    fn _adc(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        const fetched: u16 = @intCast(u16, self.memory.read8(address));
        const value: u16 = @intCast(u16, self.register_a) + fetched + @intCast(u16, self.getFlag(StatusFlag.C));

        self.setFlag(StatusFlag.C, value > 255);

        self.setFlag(StatusFlag.V, (~(@intCast(u16, self.register_a) ^ fetched) & (@intCast(u16, self.register_a) ^ value)) & 0x0080 != 0);

        self.updateZeroAndNegativeFlag(@intCast(u8, value & 0x00FF));

        self.register_a = @intCast(u8, value & 0x00FF);
    }

    fn _and(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        const value: u8 = self.memory.read8(address);

        self.register_a = self.register_a & value;

        self.updateZeroAndNegativeFlag(self.register_a);
    }

    // ASL: Arithmetic Shift Left
    // A = C <- (A << 1) <- 0
    // Flags: N, Z, C
    fn _asl(self: *CPU, mode: AddressingMode) void {
        if (mode == AddressingMode.Accumulator) {
            self.setFlag(StatusFlag.C, (self.register_a >> 7) == 1);
            self.register_a <<= 1;
            self.updateZeroAndNegativeFlag(self.register_a);
        } else {
            const address: u16 = self.getOperandAddress(mode);
            var value: u8 = self.memory.read8(address) << 1;

            self.setFlag(StatusFlag.C, (value >> 7) == 1);
            value <<= 1;
            self.updateZeroAndNegativeFlag(value);
            self.memory.write8(address, value);
        }
    }

    fn _bcc(self: *CPU) void {
        if (self.getFlag(StatusFlag.C) == 0) {
            const jump: u8 = self.memory.read8(self.program_counter);
            const jump_address = self.program_counter +% @intCast(u16, jump);

            self.program_counter = jump_address;
        }
    }

    fn _bcs(self: *CPU) void {
        if (self.getFlag(StatusFlag.C) == 1) {
            const jump: u8 = self.memory.read8(self.program_counter);
            const jump_address = self.program_counter +% @intCast(u16, jump);

            self.program_counter = jump_address;
        }
    }

    fn _beq(self: *CPU) void {
        if (self.getFlag(StatusFlag.Z) == 1) {
            const jump: u8 = self.memory.read8(self.program_counter);
            const jump_address = self.program_counter +% @intCast(u16, jump);

            self.program_counter = jump_address;
        }
    }

    fn _clc(self: *CPU) void {
        self.setFlag(StatusFlag.C, false);
    }

    fn _lda(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        const value = self.memory.read8(address);

        self.register_a = value;
        self.updateZeroAndNegativeFlag(self.register_a);
    }

    fn _tax(self: *CPU) void {
        self.register_x = self.register_a;
        self.updateZeroAndNegativeFlag(self.register_x);
    }

    fn _inx(self: *CPU) void {
        self.register_x +%= 1;
        self.updateZeroAndNegativeFlag(self.register_x);
    }
};

///////////////////////////////////////////////////////////
// Tests

test "0xA9_LDA_immidiate_load_data" {
    var cpu = CPU.init();
    cpu.loadAndRun(&[_]u8{ 0xA9, 0x05, 0x03, 0x00 });
    std.testing.expect(cpu.register_a == 0x05);
    std.debug.assert(cpu.status & 0b0000_0010 == 0b00);
    std.debug.assert(cpu.status & 0b1000_0000 == 0);
}

test "0xA9_LDA_zero_flag" {
    var cpu = CPU.init();
    cpu.loadAndRun(&[_]u8{ 0xA9, 0x00, 0x00 });
    std.debug.assert(cpu.status & 0b0000_0010 == 0b10);
}

test "0xA9_LDA_negative_flag" {
    var cpu = CPU.init();
    cpu.loadAndRun(&[_]u8{ 0xa9, 0xff, 0x00 });
    std.debug.assert(cpu.status & 0b1000_0000 == 0b1000_0000);
}

test "0xAA_TAX_move_a_to_x" {
    var cpu = CPU.init();
    cpu.loadAndRun(&[_]u8{ 0xA9, 0xA, 0xAA, 0x00 });
    std.testing.expect(cpu.register_x == 10);
}

test "INX_overflow" {
    var cpu = CPU.init();
    cpu.register_x = 0xFF;
    cpu.loadAndRun(&[_]u8{ 0xA9, 0xFF, 0xAA, 0xE8, 0xE8, 0x00 });
    std.testing.expect(cpu.register_x == 1);
}

test "5_ops_working_together" {
    var cpu = CPU.init();
    cpu.loadAndRun(&[_]u8{ 0xA9, 0xC0, 0xAA, 0xE8, 0x00 });
    std.testing.expect(cpu.register_x == 0xc1);
}

test "adc_different" {
    var cpu = CPU.init();
    cpu.loadAndRun(&[_]u8{ 0xA9, 0x12, 0x69, 0x12, 0x00 });
    std.testing.expect(cpu.register_a == 0x24);
}

test "multiplication" {
    var cpu = CPU.init();
    cpu.loadAndRun(&[_]u8{
        0xA2, 0x0A, 0x8E, 0x00, 0x00, 0xA2, 0x03, 0x8E,
        0x01, 0x00, 0xAC, 0x00, 0x00, 0xA9, 0x00, 0x18,
        0x6D, 0x01, 0x00, 0x88, 0xD0, 0xFA, 0x8D, 0x02,
        0x00, 0xEA, 0xEA, 0xEA,
    });
    // std.testing.expect(cpu.register_a == 0x1E);
}

// test "status_flags" {
//     var cpu = CPU.init();
//     std.debug.warn("before {b}\n", .{cpu.status});
//     const t: u8 = 0;
//     cpu.setFlag(StatusFlag.Z, 1);
//     cpu.setFlag(StatusFlag.N, 1);
//
//     cpu.setFlag(StatusFlag.C, 1);
//
//     std.debug.warn("after {b}\n", .{cpu.status});
// }
