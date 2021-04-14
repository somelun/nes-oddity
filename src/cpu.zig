const std = @import("std");
const expect = std.testing.expect;
const assert = std.debug.assert;

const Bus = @import("bus.zig").Bus;

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
    A: u8 = 0x00,
    X: u8 = 0x00,
    Y: u8 = 0x00,
    status: u8 = 0x00,
    SP: u8 = 0xFF, // stack pointer
    PC: u16 = 0x0000, // program counter

    pub fn init() CPU {
        return CPU{};
    }

    pub fn interpret(self: *CPU, commands: []const u8) void {
        self.PC = 0;

        for (commands) |value| {
            self.PC += 1;

            switch (value) {
                0xA9 => { // LDA
                    const param = commands[self.PC];
                    self.PC += 1;

                    self.A = param;
                    if (self.A == 0) {
                        self.status = self.status | 0b0000_0010;
                    } else {
                        self.status = self.status | 0b1111_1101;
                    }

                    if (self.A & 0b1000_0000 != 0) {
                        self.status = self.status | 0b1000_0000;
                    } else {
                        self.status = self.status & 0b0111_1111;
                    }
                },

                0x00 => { // BRK
                    return;
                },

                else => {
                    return;
                },
            }
        }
    }
};

test "0xA9_LDA_immidiate_load_data" {
    var cpu = CPU.init();
    cpu.interpret(&[_]u8{ 0xA9, 0x05, 0x00 });
    expect(cpu.A == 0x05);
    assert(cpu.status & 0b0000_0010 == 0b00);
    assert(cpu.status & 0b1000_0000 == 0);
}

test "0xA9_LDA_zero_flag" {
    var cpu = CPU.init();
    cpu.interpret(&[_]u8{ 0xA9, 0x00, 0x00 });
    assert(cpu.status & 0b0000_0010 == 0b10);
}
