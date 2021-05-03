const std = @import("std");
const AutoHashMap = std.AutoHashMap;

const RAM = @import("ram.zig").RAM;

const OpcodeAPI = @import("opcode.zig");
const Opcode = OpcodeAPI.Opcode;
const AddressingMode = OpcodeAPI.AddressingMode;

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
            .opcodes = OpcodeAPI.generateOpcodes(),
        };
    }

    pub fn reset(self: *CPU) void {
        self.register_a = 0;
        self.register_x = 0;
        self.status = 0;

        self.program_counter = self.memory.read16(program_counter_address);
    }

    pub fn clock() void {
        //
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
        var address: u16 = indefined;

        switch (mode) {
            AddressingMode.Implicit => {},

            AddressingMode.Accumulator => {
                address = self.register_a;
            },

            AddressingMode.Immediate => {
                address = self.program_counter;
            },

            AddressingMode.ZeroPage => {
                address = @intCast(u16, self.memory.read8(self.program_counter));
            },

            AddressingMode.ZeroPageX => {
                address = @intCast(u16, self.memory.read8(self.program_counter) +% self.register_x);
            },

            AddressingMode.ZeroPageY => {
                address = @intCast(u16, self.memory.read8(self.program_counter) +% self.register_y);
            },

            AddressingMode.Relative => {
                //return
            },

            AddressingMode.Absolute => {
                address = memory.read16(self.program_counter);
            },

            AddressingMode.AbsoluteX => {
                address = self.memory.read16(self.program_counter) +% self.register_x;
            },

            AddressingMode.AbsoluteY => {
                address = self.memory.read16(self.program_counter) +% self.register_y;
            },

            AddressingMode.Indirect => {
                const ptr: u16 = self.memory.read16(self.program_counter);

                if (ptr and 0x00FF == 0x00FF) {
                    address = (self.memory.read8(ptr & 0xFF00) << 8) | self.memory.read8(ptr + 0);
                } else {
                    address = (self.memory.read8(ptr + 1) << 8) | self.memory.read8(ptr + 0);
                }
            },

            AddressingMode.IndirectX => {
                const base: u8 = self.memory.read8(self.program_counter) +% self.register_x;

                const lo: u16 = self.memory.read8(base);
                const hi: u16 = self.memory.read8(base +% 1);
                address = (hi << 8) | (lo);
            },

            AddressingMode.IndirectY => {
                const base: u8 = self.memory.read8(self.program_counter) +% self.register_y;

                const lo: u16 = self.memory.read8(base);
                const hi: u16 = self.memory.read8(base +% 1);
                address = (hi << 8) | (lo);
            },

            else => {},
        }

        return address;
    }

    fn run(self: *CPU) void {
        while (self.program_counter < 0xFFFC) { //TODO: remove magic number
            const value = self.memory.read8(self.program_counter);
            self.program_counter += 1;

            // const opcode = opcodes[value];
            switch (value) {
                // ADC
                0x69, 0x65, 0x75, 0x6D, 0x7D, 0x79, 0x61, 0x71 => {},

                0xA9 => { // LDA
                    const param = self.memory.read8(self.program_counter);
                    self.program_counter += 1;

                    self.lda(param);
                },

                0xAA => { //TAX
                    self.tax();
                },

                0xE8 => { //INX
                    self.inx();
                },

                0x00 => { // BRK
                    return;
                },

                else => { // unknown instruction or already used data
                    continue;
                },
            }
        }
    }

    fn updateZeroAndNegativeFlag(self: *CPU, value: u8) void {
        self.updateZeroFlag(value);
        self.updateNegativeFlag(value);
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

    fn lda(self: *CPU, value: u8) void {
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

test "0xA9_LDA_immidiate_load_data" {
    var cpu = CPU.init();
    cpu.loadAndRun(&[_]u8{ 0xA9, 0x05, 0x00 });
    std.testing.expect(cpu.register_a == 0x05);
    std.debug.assert(cpu.status & 0b0000_0010 == 0b00);
    std.debug.assert(cpu.status & 0b1000_0000 == 0);
}

// test "0xA9_LDA_zero_flag" {
//     var cpu = CPU.init();
//     cpu.loadAndRun(&[_]u8{ 0xA9, 0x00, 0x00 });
//     std.debug.assert(cpu.status & 0b0000_0010 == 0b10);
// }
//
// test "0xA9_LDA_negative_flag" {
//     var cpu = CPU.init();
//     cpu.loadAndRun(&[_]u8{ 0xa9, 0xff, 0x00 });
//     std.debug.assert(cpu.status & 0b1000_0000 == 0b1000_0000);
// }
//
// test "0xAA_TAX_move_a_to_x" {
//     var cpu = CPU.init();
//     cpu.loadAndRun(&[_]u8{ 0xA9, 0xA, 0xAA, 0x00 });
//     std.testing.expect(cpu.register_x == 10);
// }
//
// test "INX_overflow" {
//     var cpu = CPU.init();
//     cpu.register_x = 0xFF;
//     cpu.loadAndRun(&[_]u8{ 0xA9, 0xFF, 0xAA, 0xE8, 0xE8, 0x00 });
//     std.testing.expect(cpu.register_x == 1);
// }
//
// test "5_ops_working_together" {
//     var cpu = CPU.init();
//     cpu.loadAndRun(&[_]u8{ 0xA9, 0xC0, 0xAA, 0xE8, 0x00 });
//     std.testing.expect(cpu.register_x == 0xc1);
// }
//
// test "load_and_run" {
//     var cpu = CPU.init();
//     cpu.loadAndRun(&[_]u8{ 0xA9, 0xC0, 0xAA, 0xE8, 0x00 });
// }
