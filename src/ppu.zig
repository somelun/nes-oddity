// NES PPU Memory Layout
//
//
//       PPU Memory Map                       PPU Registers
//
// |------------------------| 0xFFFF   |-------------------------|
// |                        |          | Controller      0x2000  |
// |   Mirrors for range    |          |-------------------------|
// |    [0x0000-0x3FFF]     |          | Mask            0x2001  |
// |                        |          |-------------------------|
// |------------------------| 0x4000   | Status          0x2002  |
// |       Palettes         |          |-------------------------|
// |                        |          | OAM Address     0x2003  |
// |------------------------| 0x3F00   |-------------------------|
// |                        |          | OAM Data        0x2004  |
// |      Name Tables       |          |-------------------------|
// |         (VRAM)         |          | Scroll          0x2005  |
// |                        |          |-------------------------|
// |------------------------| 0x2000   | Address         0x2006  |
// |                        |          |-------------------------|
// |     Pattern Tables     |          | Data            0x2007  |
// |       (CHR Rom)        |          |-------------------------|
// |                        |          | OAM DMA         0x4014  |
// |------------------------| 0x0000   |-------------------------|
//
// https://wiki.nesdev.com/w/index.php/PPU_registers
//
//
//

const Mirroring = @import("rom.zig").Mirroring;

pub const PPU = struct {
    chr_rom: []u8 = undefined,
    palette_table: [0x20]u8 = [_]u8{0} ** 0x20,
    vram: [0x800]u8 = [_]u8{0} ** 0x800,
    oam_data: [0x100]u8 = [_]u8{0} ** 0x100,

    mirroring: Mirroring,

    addressRegister: AddressRedister,

    pub fn init(rom_data: []u8, mirroring: Mirroring) PPU {
        var ppu: PPU = PPU{};

        ppu.chr_rom = rom_data;
        ppu.mirroring = mirroring;
        ppu.addressingRegister = AddressingRegister.init();

        return ppu;
    }
};

pub const AddressRegister = struct {
    hi_byte: u8 = 0,
    lo_byte: u8 = 0,
    hi_byte_in_use: bool = true,

    pub fn init() AddressRegister {
        return AddressRegister{};
    }

    pub fn set(self: *AddressRegister, data: u16) void {
        hi_byte = @as(u8, data >> 8);
        lo_byte = @as(u8, data & 0xFF);
    }

    pub fn get(self: *AddressRegister) u16 {
        return (hi_byte << 8) | lo_byte;
    }

    pub fn update(self: *AddressRegister, data: u8) void {
        if (self.hi_byte_in_use) {
            hi_byte = data;
        } else {
            lo_byte = data;
        }

        const fetched: u16 = self.get();
        if (fetched > 0x3FFF) {
            // mirroring address down below 0x3FFF
            self.set(fetched & 0b11111111111111);
        }

        self.hi_byte_in_use = !self.hi_byte_in_use;
    }

    pub fn increment(self: *AddressRegister, inc: u16) void {
        var lo: u8 = self.lo_byte;
        self.lo_byte +%= inc;
        if (lo > self.lo_byte) {
            self.hi_byte +%= 1;
        }

        const fetched: u16 = self.get();
        if (fetched > 0x3FFF) {
            // mirroring address down below 0x3FFF
            self.set(fetched & 0b11111111111111);
        }
    }

    pub fn reset_latch(self: *AddressRegister, data: u16) void {
        self.hi_byte_in_use = true;
    }
};
