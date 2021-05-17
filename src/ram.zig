const mem = @import("std").mem;

pub const RAM = struct {
    memory: [0xFFFF]u8 = [_]u8{0} ** 0xFFFF,
    stack_pointer: u8 = 0xFD,

    pub fn init() RAM {
        return RAM{};
    }

    pub fn read8(self: *RAM, address: u16) u8 {
        return self.memory[address];
    }

    pub fn write8(self: *RAM, address: u16, data: u8) void {
        self.memory[address] = data;
    }

    pub fn read16(self: *RAM, address: u16) u16 {
        const lo: u16 = self.read8(address);
        const hi: u16 = self.read8(address + 1); //TODO: check maybe + should be %+
        return (hi << 8) | (lo);
    }

    pub fn write16(self: *RAM, address: u16, data: u16) void {
        const hi = @intCast(u8, data >> 8);
        const lo = @intCast(u8, data & 0xFF);
        self.write8(address, lo);
        self.write8(address + 1, hi);
    }

    pub fn pushToStack(self: *RAM, value: u8) void {
        self.write8(0x0100 + @intCast(u16, self.stack_pointer), value);
        self.decrementStackPointer();
    }

    pub fn popFromStack(self: *RAM) u8 {
        self.incrementStackPointer();
        return self.read8(0x0100 + @intCast(u16, self.stack_pointer));
    }

    pub fn incrementStackPointer(self: *RAM) void {
        self.stack_pointer += 1;
        self.stack_pointer &= 0xFF;
    }

    pub fn decrementStackPointer(self: *RAM) void {
        self.stack_pointer -= 1;
        self.stack_pointer &= 0xFF;
    }

    pub fn loadProgram(self: *RAM, program_code: []const u8) void {
        const program_len = program_code.len;
        mem.copy(u8, self.memory[0x0600 .. 0x0600 + program_len], program_code[0..program_len]);
    }
};
