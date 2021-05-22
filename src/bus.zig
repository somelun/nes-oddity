const mem = @import("std").mem;

pub const Bus = struct {
    const RAM_BEGIN: u16 = 0x0000;
    const RAM_MIRROR_END: u16 = 0x1FFF;
    const PPU_BEGIN: u16 = 0x2000;
    const PPU_MIRROR_END: u16 = 0x3FFF;

    // 2KB of Work RAM available for the CPU
    wram: [0x800]u8 = [_]u8{0} ** 0x800,

    pub fn init() Bus {
        return Bus{};
    }

    pub fn read8(self: *Bus, address: u16) u8 {
        var data: u8 = 0x00;

        switch (address) {
            RAM_BEGIN...RAM_MIRROR_END => {
                data = self.wram[address & 0x07FF];
            },
            else => {
                // TODO: memory access for PPU
            },
        }

        return data;
    }

    pub fn write8(self: *Bus, address: u16, data: u8) void {
        switch (address) {
            RAM_BEGIN...RAM_MIRROR_END => {
                self.wram[address & 0x07FF] = data;
            },
            else => {
                // TODO: memory access for PPU
            },
        }
    }

    // sugar function
    pub fn read16(self: *Bus, address: u16) u16 {
        const lo: u16 = self.read8(address);
        const hi: u16 = self.read8(address + 1);
        return (hi << 8) | (lo);
    }

    // sugar function
    pub fn write16(self: *Bus, address: u16, data: u16) void {
        const hi = @intCast(u8, data >> 8);
        const lo = @intCast(u8, data & 0xFF);
        self.write8(address, lo);
        self.write8(address + 1, hi);
    }

    pub fn loadProgram(self: *Bus, program_code: []const u8) void {
        const program_len = program_code.len;
        mem.copy(u8, self.wram[0x0600 .. 0x0600 + program_len], program_code[0..program_len]);
    }
};
