// NES Memory Layot
//
//
// ----------------------| 0x0000
//                       |
// Zero Page             |
//                       |
// ----------------------| 0x0100
//                       |
// Stack                 |
//                       |
// ----------------------| 0x0200
//                       |
// RAM                   |
//                       |
// ----------------------| 0x0800
//                       |
// Mirrors               |
//                       |
// ----------------------| 0x2000
//                       |
// I/O Registers         |
//                       |
// ----------------------| 0x2008
//                       |
// Mirrors               |
//                       |
// ----------------------| 0x4000
//                       |
// I/O Registers         |
//                       |
// ----------------------| 0x4020
//                       |
// Expansion Rom         |
//                       |
// ----------------------| 0x6000
//                       |
// SRAM                  |
//                       |
// ----------------------| 0x8000
//                       |
// PRG Rom Lower Bank    |
//                       |
// ----------------------| 0xC000
//                       |
// PRG Rom Uppder Bank   |
//                       |
// ----------------------| 0x10000
//
//

const mem = @import("std").mem;
const Rom = @import("rom.zig").Rom;

pub const Bus = struct {
    const RAM_BEGIN: u16 = 0x0000;
    const RAM_MIRROR_END: u16 = 0x1FFF;
    const PPU_BEGIN: u16 = 0x2000;
    const PPU_MIRROR_END: u16 = 0x3FFF;

    // 2KB of Work RAM available for the CPU
    wram: [0x800]u8 = [_]u8{0} ** 0x800,

    rom: *Rom = undefined,

    pub fn init(rom: *Rom) Bus {
        var bus: Bus = Bus{};
        bus.rom = rom;

        return Bus{};
    }

    pub fn read8(self: *Bus, address: u16) u8 {
        var data: u8 = undefined;

        switch (address) {
            RAM_BEGIN...RAM_MIRROR_END => {
                data = self.wram[address & 0x07FF];
            },
            PPU_BEGIN...PPU_MIRROR_END => {
                // TODO: memory access for PPUmemory
            },
            0x8000...0xFFFF => {
                return self.readPrgRom(address);
            },
            else => {},
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

    fn readPrgRom(self: *Bus, address: u16) u8 {
        var addr: u16 = address - 0x8000;
        if (mem.len(self.rom.prg_rom) == 0x4000 and addr >= 0x4000) {
            //mirror if needed
            addr = addr % 0x4000;
        }
        return self.rom.prg_rom[addr];
    }
};
