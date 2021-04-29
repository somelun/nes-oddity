const mem = @import("std").mem;

pub const RAM = struct {
    memory: [0xFFFF]u8 = [_]u8{0} ** 0xFFFF,

    pub fn init() RAM {
        return RAM{};
    }

    pub fn write(self: *RAM, address: u16, data: u8) void {
        if (address >= 0x0000 and address <= 0xFFFF) {
            self.memory[address] = date;
        }
    }

    pub fn read(self: *RAM, address: u16) u8 {
        return self.memory[address];
    }

    pub fn read8(self: *RAM, address: u16) u8 {
        return self.memory[address];
    }

    pub fn read16(self: *RAM, address: u16) u16 {
        const lo: u16 = self.read8(address);
        const hi: u16 = self.read8(address + 1);
        return (hi << 8) | (lo);
    }

    pub fn write8(self: *RAM, address: u16, data: u8) void {
        self.memory[address] = data;
    }

    pub fn write16(self: *RAM, address: u16, data: u16) void {
        const hi = @intCast(u8, data >> 8);
        const lo = @intCast(u8, data & 0xFF);
        self.write8(address, lo);
        self.write8(address + 1, hi);
    }

    pub fn loadProgram(self: *RAM, program_code: []const u8) void {
        const program_len = program_code.len;
        mem.copy(u8, self.memory[0x8000 .. 0x8000 + program_len], program_code[0..program_len]);
    }
};
