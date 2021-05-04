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
                address = @intCast(u16, self.memory.read8(self.program_counter));
                self.program_counter += 1;
            },

            AddressingMode.ZeroPageX => {
                address = @intCast(u16, self.memory.read8(self.program_counter) +% self.register_x);
                self.program_counter += 1;
            },

            AddressingMode.ZeroPageY => {
                address = @intCast(u16, self.memory.read8(self.program_counter) +% self.register_y);
                self.program_counter += 1;
            },

            AddressingMode.Relative => {
                // TODO:
                // address = memory.read8(self.program_counter);
                // self.program_counter += 1;
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
                    self.adc(addressing_mode);
                    continue;
                },

                0x00 => { // BRK
                    return;
                },

                // LDA
                0xA9, 0xA5, 0xB5, 0xAD, 0xBD, 0xB9, 0xA1, 0xB1 => {
                    self.lda(addressing_mode);
                    continue;
                },

                // TAX
                0xAA => {
                    self.tax();
                },

                0xE8 => { //INX
                    self.inx();
                },

                else => { // unknown instruction or already used data
                    continue;
                },
            }
        }
    }

    fn updateZeroAndNegativeFlag(self: *CPU, value: u8) void {
        // self.setFlag(StatusFlag.Z, value);
        // self.setFlag(StatusFlag.N, value & 0x0080);
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
        return self.status & number;
    }

    fn updateZeroFlag(self: *CPU, value: u8) void {
        if (value == 0) {
            self.status = self.status | 0b0000_0010;
        } else {
            self.status = self.status | 0b1111_1101;
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

    fn adc(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        const value = self.memory.read8(address);
    }

    fn lda(self: *CPU, mode: AddressingMode) void {
        const address: u16 = self.getOperandAddress(mode);
        const value = self.memory.read8(address);

        self.register_a = value;
        self.updateZeroAndNegativeFlag(self.register_a);
    }

    fn tax(self: *CPU) void {
        self.register_x = self.register_a;
        self.updateZeroAndNegativeFlag(self.register_x);
    }

    fn inx(self: *CPU) void {
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
    // std.debug.warn("Z: {b}\n", .{cpu.getFlag(StatusFlag.Z)});
    // std.debug.warn("N: {b}\n", .{cpu.getFlag(StatusFlag.N)});
    // std.debug.assert(cpu.getFlag(StatusFlag.Z) == 0);
    // std.debug.assert(cpu.getFlag(StatusFlag.N) == 0);
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

// test "status_flags" {
//     var cpu = CPU.init();
//     std.debug.warn("before {b}\n", .{cpu.status});
//     const t: u8 = 0;
//     cpu.setFlag(StatusFlag.Z, t == 0x00);
//     cpu.setFlag(StatusFlag.N, t & 0x80);
//     std.debug.warn("after {b}\n", .{cpu.status});
// }
