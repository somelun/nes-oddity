const std = @import("std");

const Bus = @import("bus.zig").Bus;

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
    status: u8 = 0x00,
    stack_pointer: u8 = 0xFF,
    program_counter: u16 = 0x0000,
    memory: [0xFFFF]u8 = [_]u8{0} ** 0xFFFF, //TODO: make separate struct later

    pub fn init() CPU {
        return CPU{};
    }

    pub fn reset(self: *CPU) void {
        self.register_a = 0;
        self.register_x = 0;
        self.status = 0;

        self.program_counter = self.memoryRead16(program_counter_address);
    }

    pub fn loadAndRun(self: *CPU, commands: []const u8) void {
        self.load(commands);
        self.reset();
        self.run();
    }

    fn load(self: *CPU, commands: []const u8) void {
        std.mem.copy(u8, self.memory[0x8000 .. 0x8000 + commands.len], commands[0..commands.len]);
        // program counter stored in memory at 0xFFFC
        self.memoryWrite16(program_counter_address, 0x8000);
    }

    fn memoryRead(self: *CPU, address: u16) u8 {
        return self.memory[address];
    }

    fn memoryRead16(self: *CPU, address: u16) u16 {
        const low: u16 = self.memoryRead(address);
        const high: u16 = self.memoryRead(address + 1);
        return (high << 8) | (low);
    }

    fn memoryWrite(self: *CPU, address: u16, data: u8) void {
        self.memory[address] = data;
    }

    fn memoryWrite16(self: *CPU, address: u16, data: u16) void {
        const high = @intCast(u8, data >> 8);
        const low = @intCast(u8, data & 0xFF);
        self.memoryWrite(address, low);
        self.memoryWrite(address + 1, high);
    }

    fn run(self: *CPU) void {
        while (self.program_counter < 0x8010) { //TODO: remove magic number
            const opcode = self.memoryRead(self.program_counter);
            self.program_counter += 1;

            switch (opcode) {
                0xA9 => { // LDA
                    const param = self.memoryRead(self.program_counter);
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

test "load_and_run" {
    var cpu = CPU.init();
    cpu.loadAndRun(&[_]u8{ 0xA9, 0xC0, 0xAA, 0xE8, 0x00 });
}
