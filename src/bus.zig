// NES Memory Layout
//
//
//
// |------------------------|  0x10000 |-------------------------|  0x10000
// |                        |          | PRG Rom Upper Bank      |
// |                        |          |                         |
// |        PRG Rom         |          |- - - - - - - - - - - - -|  0xC000
// |                        |          | PRG Rom Lower Bank      |
// |                        |          |                         |
// |------------------------|  0x8000  |-------------------------|  0x8000
// |         SRAM           |          | SRAM                    |
// |                        |          |                         |
// |------------------------|  0x6000  |-------------------------|  0x6000
// |     Expansion ROM      |          | Expansion ROM           |
// |                        |          |                         |
// |------------------------|  0x4020  |-------------------------|  0x4020
// |     I/O Registers      |          | I/O Registers           |
// |                        |          |                         |
// |------------------------|  0x4000  |-------------------------|  0x4000
// |                        |          | Mirrors for range       |
// |                        |          | [0x2000-0x2007]         |
// |     PPU Registers      |          |- - - - - - - - - - - - -|  0x2008
// |                        |          | PPU Registers           |
// |                        |          |                         |
// |------------------------|  0x2000  |-------------------------|  0x2000
// |                        |          | Mirrors for range       |
// |                        |          | [0x0000-0x07FF]         |
// |                        |          |- - - - - - - - - - - - -|  0x0800
// |                        |          | RAM                     |
// |                        |          |                         |
// |          RAM           |          |- - - - - - - - - - - - -|  0x0200
// |                        |          | Stack                   |
// |                        |          |                         |
// |                        |          |- - - - - - - - - - - - -|  0x0100
// |                        |          | Zero Page               |
// |                        |          |                         |
// |------------------------|  0x0000  |-------------------------|  0x0000
//
//
// What is Zero Page? https://en.wikipedia.org/wiki/Zero_page
//

const std = @import("std");
const mem = std.mem;

const Rom = @import("rom.zig").Rom;
const PPU = @import("ppu.zig").PPU;

const RAM_BEGIN: u16 = 0x0000;
const RAM_MIRROR_END: u16 = 0x1FFF;
const PPU_MIRROR_END: u16 = 0x3FFF;
const PRG_ROM_BEGIN: u16 = 0x8000;
const PRG_ROM_END: u16 = 0xFFFF;

pub const Bus = struct {
    // 2KB of Work RAM available for the CPU
    wram: [0x800]u8 = [_]u8{0} ** 0x800,

    ppu: PPU = undefined,
    rom: *Rom = undefined,

    pub fn init(rom: *Rom) Bus {
        var bus: Bus = Bus{};
        bus.rom = rom;

        bus.ppu = PPU.init(rom.chr_rom, rom.screen_mirroring);

        return bus;
    }

    pub fn read8(self: *Bus, address: u16) u8 {
        var data: u8 = undefined;

        switch (address) {
            RAM_BEGIN...RAM_MIRROR_END => {
                data = self.wram[address & 0x07FF];
            },

            0x2000, 0x2001, 0x2003, 0x2005, 0x2006, 0x4014 => {
                // std.debug.print("Attempt to read from write-only PPU address {:x}", .{address});
            },

            // 0x2002 => {
            //     self.ppu.read_status(),
            // },

            // 0x2004 => {
            //     self.ppu.read_oam_data(),
            // },

            0x2007 => {
                data = self.ppu.readData();
            },

            0x2008...PPU_MIRROR_END => {
                data = self.read8(address & 0x2007);
            },

            PRG_ROM_BEGIN...PRG_ROM_END => {
                data = self.readPrgRom(address);
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

            0x2000 => {
                self.ppu.writeToControllerRegister(data);
            },

            0x2006 => {
                self.ppu.writeToAddressRegister(data);
            },

            0x2007 => {
                self.ppu.writeData(data);
            },

            0x2008...PPU_MIRROR_END => {
                self.write8(address & 0x2007, data);
            },

            0x8000...0xFFFF => {},

            else => {},
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
        const hi: u8 = @intCast(data >> 8);
        const lo: u8 = @intCast(data & 0xFF);
        self.write8(address, lo);
        self.write8(address + 1, hi);
    }

    pub fn loadProgram(self: *Bus, program_code: []const u8) void {
        const program_len = program_code.len;
        mem.copy(u8, self.wram[0x0600 .. 0x0600 + program_len], program_code[0..program_len]);
    }

    // PRG Rom Size might be 16 or 32 KiB, if 16 KiB, then upper bank
    // should be mapped to the lower bank
    fn readPrgRom(self: *Bus, address: u16) u8 {
        var addr: u16 = address - 0x8000;
        if (self.rom.prg_rom.len == 0x4000 and addr >= 0x4000) {
            //mirror if needed
            addr = addr % 0x4000;
        }

        return self.rom.prg_rom[addr];
    }
};
