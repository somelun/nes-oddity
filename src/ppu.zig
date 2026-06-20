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
// More info about PPU register is here:
// https://wiki.nesdev.com/w/index.php/PPU_registers
// This is MUST READ!
//

const std = @import("std");
const Mirroring = @import("rom.zig").Mirroring;

const CHR_ROM_BEGIN: u16 = 0x0000;
const CHR_ROM_END: u16 = 0x1FFF;

const VRAM_BEGIN = 0x2000;
const VRAM_END = 0x2FFF;

const PALETTES_BEGIN = 0x3F00;
const PALETTES_END = 0x3FFF;

pub const SYSTEM_PALETTE: [64][3]u8 = .{
    .{ 0x80, 0x80, 0x80 }, .{ 0x00, 0x3D, 0xA6 }, .{ 0x00, 0x12, 0xB0 }, .{ 0x44, 0x00, 0x96 }, .{ 0xA1, 0x00, 0x5E },
    .{ 0xC7, 0x00, 0x28 }, .{ 0xBA, 0x06, 0x00 }, .{ 0x8C, 0x17, 0x00 }, .{ 0x5C, 0x2F, 0x00 }, .{ 0x10, 0x45, 0x00 },
    .{ 0x05, 0x4A, 0x00 }, .{ 0x00, 0x47, 0x2E }, .{ 0x00, 0x41, 0x66 }, .{ 0x00, 0x00, 0x00 }, .{ 0x05, 0x05, 0x05 },
    .{ 0x05, 0x05, 0x05 }, .{ 0xC7, 0xC7, 0xC7 }, .{ 0x00, 0x77, 0xFF }, .{ 0x21, 0x55, 0xFF }, .{ 0x82, 0x37, 0xFA },
    .{ 0xEB, 0x2F, 0xB5 }, .{ 0xFF, 0x29, 0x50 }, .{ 0xFF, 0x22, 0x00 }, .{ 0xD6, 0x32, 0x00 }, .{ 0xC4, 0x62, 0x00 },
    .{ 0x35, 0x80, 0x00 }, .{ 0x05, 0x8F, 0x00 }, .{ 0x00, 0x8A, 0x55 }, .{ 0x00, 0x99, 0xCC }, .{ 0x21, 0x21, 0x21 },
    .{ 0x09, 0x09, 0x09 }, .{ 0x09, 0x09, 0x09 }, .{ 0xFF, 0xFF, 0xFF }, .{ 0x0F, 0xD7, 0xFF }, .{ 0x69, 0xA2, 0xFF },
    .{ 0xD4, 0x80, 0xFF }, .{ 0xFF, 0x45, 0xF3 }, .{ 0xFF, 0x61, 0x8B }, .{ 0xFF, 0x88, 0x33 }, .{ 0xFF, 0x9C, 0x12 },
    .{ 0xFA, 0xBC, 0x20 }, .{ 0x9F, 0xE3, 0x0E }, .{ 0x2B, 0xF0, 0x35 }, .{ 0x0C, 0xF0, 0xA4 }, .{ 0x05, 0xFB, 0xFF },
    .{ 0x5E, 0x5E, 0x5E }, .{ 0x0D, 0x0D, 0x0D }, .{ 0x0D, 0x0D, 0x0D }, .{ 0xFF, 0xFF, 0xFF }, .{ 0xA6, 0xFC, 0xFF },
    .{ 0xB3, 0xEC, 0xFF }, .{ 0xDA, 0xAB, 0xEB }, .{ 0xFF, 0xA8, 0xF9 }, .{ 0xFF, 0xAB, 0xB3 }, .{ 0xFF, 0xD2, 0xB0 },
    .{ 0xFF, 0xEF, 0xA6 }, .{ 0xFF, 0xF7, 0x9C }, .{ 0xD7, 0xE8, 0x95 }, .{ 0xA6, 0xED, 0xAF }, .{ 0xA2, 0xF2, 0xDA },
    .{ 0x99, 0xFF, 0xFC }, .{ 0xDD, 0xDD, 0xDD }, .{ 0x11, 0x11, 0x11 }, .{ 0x11, 0x11, 0x11 },
};

pub const PPU = struct {
    chr_rom: []u8 = undefined, // visuals of the game, stored on a cartridge
    palette_table: [0x20]u8 = [_]u8{0} ** 0x20, // palette table used atm
    vram: [0x800]u8 = [_]u8{0} ** 0x800,
    oam_data: [0x100]u8 = [_]u8{0} ** 0x100,
    oam_address: u8 = 0,

    scanline: u16 = 0,
    cycles: u16 = 0,
    nmi_pending: bool = false,

    mirroring: Mirroring = undefined,

    controllerRegister: ControllerRegister = undefined,
    maskRegister: MaskRegister = undefined,
    statusRegister: StatusRegister = undefined,
    scrollRegister: ScrollRegister = undefined,
    addressRegister: AddressRegister = undefined,

    internal_buffer: u8 = 0,
    // frame buffer with black color by default
    frame_buffer: [256 * 240 * 3]u8 = [_]u8{0} ** (256 * 240 * 3),

    pub fn init() PPU {
        var ppu = PPU{};

        ppu.controllerRegister = ControllerRegister.init();
        ppu.maskRegister = MaskRegister.init();
        ppu.statusRegister = StatusRegister.init();
        ppu.scrollRegister = ScrollRegister.init();
        ppu.addressRegister = AddressRegister.init();

        return ppu;
    }

    pub fn tick(self: *PPU, cycles: u8) bool {
        self.cycles += cycles;
        if (self.cycles >= 341) {
            self.cycles = self.cycles - 341;
            self.scanline += 1;

            if (self.scanline == 241) {
                self.statusRegister.setVBlankStarted();
                if (self.controllerRegister.isGenerateVBlanckNMI()) {
                    return true;
                }
            }

            if (self.scanline >= 262) {
                self.scanline = 0;
                self.statusRegister.clearVBlankStarted();
                self.render();
            }
        }
        return false;
    }

    pub fn render(self: *PPU) void {
        const bank = self.controllerRegister.backgroundPatternAddress();

        for (0..0x03c0) |i| {
            const tile_idx = @as(u16, self.vram[i]);
            const tile_x: u16 = @intCast(i % 32);
            const tile_y: u16 = @intCast(i / 32);

            const start = bank + tile_idx * 16;
            const tile = self.chr_rom[start .. start + 16];

            const palette = self.bgPalette(tile_x, tile_y);

            for (0..8) |row| {
                const y: u16 = @intCast(row);
                var lower = tile[row];
                var upper = tile[row + 8];

                for (0..8) |col| {
                    const x: u16 = 7 - @as(u16, @intCast(col));
                    const value = (1 & upper) << 1 | (1 & lower);
                    upper = upper >> 1;
                    lower = lower >> 1;

                    const rgb = switch (value) {
                        0 => SYSTEM_PALETTE[self.palette_table[0]],
                        1 => SYSTEM_PALETTE[palette[0]],
                        2 => SYSTEM_PALETTE[palette[1]],
                        3 => SYSTEM_PALETTE[palette[2]],
                        else => unreachable,
                    };

                    self.setPixel(tile_x * 8 + x, tile_y * 8 + y, rgb);
                }
            }
        }
    }

    pub fn bgPalette(self: *PPU, tile_column: u16, tile_row: u16) [3]u8 {
        const attr_table_idx = (tile_row / 4) * 8 + (tile_column / 4);
        const attr_byte = self.vram[0x3C0 + attr_table_idx];

        const col_bit = (tile_column % 4) / 2;
        const row_bit = (tile_row % 4) / 2;

        const pallet_idx: u2 = switch ((row_bit << 1) | col_bit) {
            0b00 => @intCast(attr_byte & 0b11),
            0b01 => @intCast((attr_byte >> 2) & 0b11),
            0b10 => @intCast((attr_byte >> 4) & 0b11),
            0b11 => @intCast((attr_byte >> 6) & 0b11),
            else => unreachable,
        };

        const palette_start = 1 + (@as(usize, pallet_idx) * 4);

        return [3]u8{
            self.palette_table[palette_start],
            self.palette_table[palette_start + 1],
            self.palette_table[palette_start + 2],
        };
    }

    pub fn setPixel(self: *PPU, x: u16, y: u16, rgb: [3]u8) void {
        const index = (@as(usize, y) * 256 + x) * 3;
        self.frame_buffer[index] = rgb[0];
        self.frame_buffer[index + 1] = rgb[1];
        self.frame_buffer[index + 2] = rgb[2];
    }

    pub fn showTile(self: *PPU, bank: u8, tile_n: u8, offset_x: u16, offset_y: u16) void {
        const bank_address = @as(u16, bank) * 0x1000;

        const start = bank_address + @as(u16, tile_n) * 16;
        if (start + 16 > self.chr_rom.len) return;
        const tile = self.chr_rom[start .. start + 16];

        var y: u16 = 0;
        while (y <= 7) : (y += 1) {
            var upper = tile[y];
            var lower = tile[y + 8];

            var x: u16 = 8;
            while (x > 0) {
                x -= 1;

                const value = ((1 & upper) << 1) | (1 & lower);
                upper = upper >> 1;
                lower = lower >> 1;

                const rgb = switch (value) {
                    0 => SYSTEM_PALETTE[0x01],
                    1 => SYSTEM_PALETTE[0x23],
                    2 => SYSTEM_PALETTE[0x27],
                    3 => SYSTEM_PALETTE[0x30],
                    else => unreachable,
                };

                self.setPixel(offset_x + x, offset_y + y, rgb);
            }
        }
    }

    pub fn updateRomData(self: *PPU, chr_rom: []u8, mirroring: Mirroring) void {
        self.chr_rom = chr_rom;
        self.mirroring = mirroring;
    }

    pub fn read(self: *PPU, address: u16) u8 {
        var result: u8 = 0;
        switch (address) {
            // read status register
            0x2002 => {
                result = self.statusRegister.get();
                self.statusRegister.clearVBlankStarted();
                self.addressRegister.reset_latch();
                self.scrollRegister.reset_latch();
            },

            // read oam data
            0x2004 => {
                result = self.oam_data[self.oam_address];
            },

            else => {},
        }

        return result;
    }

    pub fn readData(self: *PPU) u8 {
        const address: u16 = self.addressRegister.get();

        // every read operation from the Data Register should increment
        // Address Register for the value from the Controller Register
        self.addressRegister.increment(self.controllerRegister.VRAMAddressIncrement());

        switch (address) {
            // read from CHAR ROM range
            CHR_ROM_BEGIN...CHR_ROM_END => {
                const result: u8 = self.internal_buffer;
                self.internal_buffer = if (address < self.chr_rom.len) self.chr_rom[address] else 0;
                return result;
            },

            // read from PPU VRAM
            VRAM_BEGIN...VRAM_END => {
                const result: u8 = self.internal_buffer;
                self.internal_buffer = self.vram[self.mirrorVRAMAddress(address)];
                return result;
            },

            // read from Palette Range
            PALETTES_BEGIN...PALETTES_END => {
                // Addresses 0x3F10/0x3F14/0x3F18/0x3F1C are mirrors of 0x3F00/0x3F04/0x3F08/0x3F0C.
                // https://wiki.nesdev.org/w/index.php/PPU_palettes
                switch (address) {
                    0x3F10, 0x3F14, 0x3F18, 0x3F1C => {
                        const add_mirror = address - 0x10;
                        return self.palette_table[add_mirror - 0x3F00];
                    },

                    else => {
                        return self.palette_table[address - 0x3F00];
                    },
                }
            },

            // not expected to read from any other memory address
            else => {},
        }

        return 0;
    }

    pub fn write(self: *PPU, address: u16, data: u8) void {
        switch (address) {
            // write to controll register
            0x2000 => {
                const prev_nmi = self.controllerRegister.isGenerateVBlanckNMI();
                self.controllerRegister.update(data);

                const cur_nmi = self.controllerRegister.isGenerateVBlanckNMI();
                if (prev_nmi != cur_nmi) {
                    if (cur_nmi and self.statusRegister.isVBlankStarted()) {
                        self.nmi_pending = true;
                    }
                }
            },

            // write to mask register
            0x2001 => {
                self.maskRegister.update(data);
            },

            // write to OAM address
            0x2003 => {
                self.oam_address = data;
            },

            // write to OAM data
            0x2004 => {
                self.oam_data[self.oam_address] = data;
                self.oam_address +%= 1;
            },

            // write to scroll regisger
            0x2005 => {
                self.scrollRegister.update(data);
            },

            // write to address register
            0x2006 => {
                self.addressRegister.update(data);
            },

            else => {},
        }
    }

    pub fn writeData(self: *PPU, value: u8) void {
        const address: u16 = self.addressRegister.get();

        self.addressRegister.increment(self.controllerRegister.VRAMAddressIncrement());

        switch (address) {
            CHR_ROM_BEGIN...CHR_ROM_END => {},

            VRAM_BEGIN...VRAM_END => {
                self.vram[self.mirrorVRAMAddress(address)] = value;
            },

            PALETTES_BEGIN...PALETTES_END => {
                // Addresses 0x3F10/0x3F14/0x3F18/0x3F1C are mirrors of $3F00/$3F04/$3F08/$3F0C.
                // https://wiki.nesdev.org/w/index.php/PPU_palettes
                switch (address) {
                    0x3F10, 0x3F14, 0x3F18, 0x3F1C => {
                        const add_mirror = address - 0x10;
                        self.palette_table[add_mirror - 0x3F00] = value;
                    },

                    else => {
                        self.palette_table[address - 0x3f00] = value;
                    },
                }
            },

            else => {},
        }
    }

    fn mirrorVRAMAddress(self: *PPU, address: u16) u16 {
        // Horizotal mirroring:
        // [A][a]
        // [B][b]
        //
        // Vertical mirroring:
        // [A][B]
        // [a][b]

        const mirrored_vram: u16 = address & 0x2FFF; // mirror down [0x3000-0x3EFF] to [0x2000 - 0x2EFF]
        const vram_index: u16 = mirrored_vram - 0x2000; // to vram vector
        const name_table: u16 = vram_index / 0x400; // to the name table index

        switch (self.mirroring) {
            Mirroring.Vertical => {
                switch (name_table) {
                    2, 3 => {
                        return vram_index - 0x800;
                    },

                    else => {},
                }
            },

            Mirroring.Horizontal => {
                switch (name_table) {
                    1, 2 => {
                        return vram_index - 0x400;
                    },

                    3 => {
                        return vram_index - 0x800;
                    },

                    else => {},
                }
            },

            else => {},
        }

        return vram_index;
    }
};

// PPU Controller Register (0x2000)
const ControllerRegister = struct {
    //
    // 7  bit  0
    // ---- ----
    // VPHB SINN
    // |||| ||||
    // |||| ||**- Base nametable address
    // |||| ||    (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
    // |||| ||
    // |||| |*--- VRAM address increment per CPU read/write of PPUDATA
    // |||| |     (0: add 1, going across; 1: add 32, going down)
    // |||| |
    // |||| *---- Sprite pattern table address for 8x8 sprites
    // ||||       (0: $0000; 1: $1000; ignored in 8x16 mode)
    // ||||
    // ||||
    // |||*------ Background pattern table address (0: $0000; 1: $1000)
    // |||
    // ||*------- Sprite size (0: 8x8 pixels; 1: 8x16 pixels)
    // ||
    // |*-------- PPU master/slave select
    // |          (0: read backdrop from EXT pins; 1: output color on EXT pins)
    // |
    // *--------- Generate an NMI at the start of the
    //            vertical blanking interval (0: off; 1: on)
    //
    const Flags = enum(u8) {
        NametableLo = (1 << 0),
        NametableHi = (1 << 1),
        VRAMAddressIncrement = (1 << 2),
        SpritePatternTableAddress = (1 << 3),
        BackgroundPatternAddress = (1 << 4),
        SpriteSize = (1 << 5),
        MasterSlaveSelect = (1 << 6),
        GenerateVBlanckNMI = (1 << 7),
    };

    flags: u8 = 0,

    pub fn init() ControllerRegister {
        return ControllerRegister{};
    }

    pub fn nametable(self: *ControllerRegister) u16 {
        const nametable_flag: u8 = (@intFromEnum(Flags.NametableLo) | @intFromEnum(Flags.NametableHi));
        switch (self.flags & nametable_flag) {
            0 => return 0x2000,
            1 => return 0x2400,
            2 => return 0x2800,
            3 => return 0x2c00,
        }
    }

    pub fn VRAMAddressIncrement(self: *ControllerRegister) u8 {
        if (self.flags & @intFromEnum(Flags.VRAMAddressIncrement) > 0) {
            return 32;
        } else {
            return 1;
        }
    }

    pub fn spritePatternTableAddress(self: *ControllerRegister) u16 {
        switch (self.flags & @intFromEnum(Flags.SpritePatternTableAddress)) {
            0 => return 0,
            1 => return 0x1000,
        }
    }

    pub fn backgroundPatternAddress(self: *ControllerRegister) u16 {
        if (self.flags & @intFromEnum(Flags.BackgroundPatternAddress) > 0) {
            return 0x1000;
        } else {
            return 0;
        }
    }

    pub fn spriteSize(self: *ControllerRegister) u8 {
        switch (self.flags & @intFromEnum(Flags.SpritePatternTableAddress)) {
            0 => return 8,
            1 => return 16,
        }
    }

    pub fn isMasterSlaveSelect(self: *ControllerRegister) bool {
        return (self.flags & @intFromEnum(Flags.MasterSlaveSelect)) > 0;
    }

    pub fn isGenerateVBlanckNMI(self: *ControllerRegister) bool {
        return (self.flags & @intFromEnum(Flags.GenerateVBlanckNMI)) > 0;
    }

    pub fn update(self: *ControllerRegister, data: u8) void {
        self.flags = data;
    }
};

// PPU Mask Register (0x2001)
const MaskRegister = struct {
    // 7  bit  0
    // ---- ----
    // BGRs bMmG
    // |||| ||||
    // |||| |||*- Greyscale (0: normal color, 1: produce a greyscale display)
    // |||| |||
    // |||| ||*-- 1: Show background in leftmost 8 pixels of screen, 0: Hide
    // |||| ||
    // |||| |*--- 1: Show sprites in leftmost 8 pixels of screen, 0: Hide
    // |||| |
    // |||| *---- 1: Show background
    // ||||
    // ||||
    // |||*------ 1: Show sprites
    // |||
    // ||*------- Emphasize red (green on PAL/Dendy)
    // ||
    // |*-------- Emphasize green (red on PAL/Dendy)
    // |
    // *--------- Emphasize blue
    //
    const Flags = enum(u8) {
        Greyscale = (1 << 0),
        ShowBackgroungInLeftmost8 = (1 << 1),
        ShowSpritesInLeftmost8 = (1 << 2),
        ShowBackground = (1 << 3),
        ShowSprites = (1 << 4),
        EmphasizeRed = (1 << 5),
        EmphasizeGreen = (1 << 6),
        EmphasizeBlue = (1 << 7),
    };

    flags: u8 = 0,

    pub fn init() MaskRegister {
        return MaskRegister{};
    }

    pub fn isGreyscale(self: *MaskRegister) bool {
        return (self.flags & @intFromEnum(Flags.Greyscale)) > 0;
    }

    pub fn isShowBackgroungInLeftmost8(self: *MaskRegister) bool {
        return (self.flags & @intFromEnum(Flags.ShowBackgroungInLeftmost8)) > 0;
    }

    pub fn isShowSpritesInLeftmost8(self: *MaskRegister) bool {
        return (self.flags & @intFromEnum(Flags.ShowSpritesInLeftmost8)) > 0;
    }

    pub fn isShowBackground(self: *MaskRegister) bool {
        return (self.flags & @intFromEnum(Flags.ShowBackground)) > 0;
    }

    pub fn isShowSprites(self: *MaskRegister) bool {
        return (self.flags & @intFromEnum(Flags.ShowSprites)) > 0;
    }

    pub fn emphasize(self: *MaskRegister) void {
        _ = self;
        // but it should return color I suppose
    }

    pub fn update(self: *MaskRegister, data: u8) void {
        self.flags = data;
    }
};

// PPU Status Register (0x2002)
const StatusRegister = struct {
    // 7  bit  0
    // ---- ----
    // VSO. ....
    // |||| ||||
    // |||*-****- Least significant bits previously written into a PPU register
    // |||        (due to register not being updated for this address)
    // ||
    // ||*------- Sprite overflow. The intent was for this flag to be set
    // ||         whenever more than eight sprites appear on a scanline, but a
    // ||         hardware bug causes the actual behavior to be more complicated
    // ||         and generate false positives as well as false negatives; see
    // ||         PPU sprite evaluation. This flag is set during sprite
    // ||         evaluation and cleared at dot 1 (the second dot) of the
    // ||         pre-render line.
    // ||
    // |*-------- Sprite 0 Hit.  Set when a nonzero pixel of sprite 0 overlaps
    // |          a nonzero background pixel; cleared at dot 1 of the pre-render
    // |          line.  Used for raster timing.
    // |
    // *--------- Vertical blank has started (0: not in vblank; 1: in vblank).
    //            Set at dot 1 of line 241 (the line *after* the post-render
    //            line); cleared after reading $2002 and at dot 1 of the
    //            pre-render line.
    //
    const Flags = enum(u8) {
        Unused1 = (1 << 0),
        Unused2 = (1 << 1),
        Unused3 = (1 << 2),
        Unused4 = (1 << 3),
        Unused5 = (1 << 4),
        SpriteOverflow = (1 << 5),
        SpriteZeroHit = (1 << 6),
        VBlankStarted = (1 << 7),
    };

    flags: u8 = 0,

    pub fn init() StatusRegister {
        return StatusRegister{};
    }

    pub fn get(self: *StatusRegister) u8 {
        return self.flags;
    }

    pub fn setSpriteOverflow(self: *StatusRegister) void {
        self.flags |= @intFromEnum(Flags.SpriteOverflow);
    }

    pub fn setSpriteZeroHit(self: *StatusRegister) void {
        self.flags |= @intFromEnum(Flags.SpriteZeroHit);
    }

    pub fn setVBlankStarted(self: *StatusRegister) void {
        self.flags |= @intFromEnum(Flags.VBlankStarted);
    }

    pub fn isSpriteOverflow(self: *StatusRegister) bool {
        return (self.flags & @intFromEnum(Flags.SpriteOverflow)) > 0;
    }

    pub fn isSpriteZeroHit(self: *StatusRegister) bool {
        return (self.flags & @intFromEnum(Flags.SpriteZeroHit)) > 0;
    }

    pub fn isVBlankStarted(self: *StatusRegister) bool {
        return (self.flags & @intFromEnum(Flags.VBlankStarted)) > 0;
    }

    pub fn clearVBlankStarted(self: *StatusRegister) void {
        self.flags = self.flags & ~@intFromEnum(Flags.VBlankStarted);
    }
};

// Scroll Register (0x2005)
const ScrollRegister = struct {
    scroll_x: u8 = 0,
    scroll_y: u8 = 0,
    latch: bool = false,

    pub fn init() ScrollRegister {
        return ScrollRegister{};
    }

    pub fn update(self: *ScrollRegister, data: u8) void {
        if (self.latch) {
            self.scroll_y = data;
        } else {
            self.scroll_x = data;
        }

        self.latch = !self.latch;
    }

    pub fn reset_latch(self: *ScrollRegister) void {
        self.latch = false;
    }
};

// PPU Address Register (0x2006)
const AddressRegister = struct {
    hi_byte: u8 = 0,
    lo_byte: u8 = 0,
    using_hi: bool = true,

    pub fn init() AddressRegister {
        return AddressRegister{};
    }

    pub fn set(self: *AddressRegister, data: u16) void {
        self.hi_byte = @intCast(data >> 8);
        self.lo_byte = @intCast(data & 0xFF);
    }

    pub fn get(self: *AddressRegister) u16 {
        return (@as(u16, self.hi_byte) << 8) | @as(u16, self.lo_byte);
    }

    pub fn update(self: *AddressRegister, data: u8) void {
        if (self.using_hi) {
            self.hi_byte = data;
        } else {
            self.lo_byte = data;
        }

        const fetched: u16 = self.get();
        if (fetched > 0x3FFF) {
            // mirroring address down below 0x3FFF
            self.set(fetched & 0x3FFF);
        }

        self.using_hi = !self.using_hi;
    }

    pub fn increment(self: *AddressRegister, inc: u8) void {
        const lo: u8 = self.lo_byte;
        self.lo_byte +%= inc;
        if (lo > self.lo_byte) {
            self.hi_byte +%= 1;
        }

        const fetched: u16 = self.get();
        if (fetched > 0x3FFF) {
            // mirroring address down below 0x3FFF
            self.set(fetched & 0x3FFF);
        }
    }

    pub fn reset_latch(self: *AddressRegister) void {
        self.using_hi = true;
    }
};

// OAM DMA Register (0x4014)

test "writeData writes to vram and increments address" {
    var ppu = PPU.init();
    // set address to 0x2300
    ppu.addressRegister.update(0x23);
    ppu.addressRegister.update(0x00);

    ppu.writeData(0xAB);

    try std.testing.expect(ppu.vram[ppu.mirrorVRAMAddress(0x2300)] == 0xAB);
    // and now we expect address + 1
    try std.testing.expect(ppu.addressRegister.get() == 0x2301);
}

test "address wraps around after 0x3FFF" {
    var ppu = PPU.init();
    ppu.addressRegister.update(0x2F);
    ppu.addressRegister.update(0xFF);

    ppu.writeData(0xAB);

    try std.testing.expect(ppu.vram[ppu.mirrorVRAMAddress(0x2FFF)] == 0xAB);
    try std.testing.expect(ppu.addressRegister.get() == 0x3000);
}

test "address wraps from 0x3FFF to 0x0000" {
    var ppu = PPU.init();
    ppu.addressRegister.update(0x3F);
    ppu.addressRegister.update(0x1F);

    ppu.writeData(0xAB);

    try std.testing.expect(ppu.palette_table[0x1F] == 0xAB);
    try std.testing.expect(ppu.addressRegister.get() == 0x3F20);
}

test "readData is buffered for VRAM" {
    var ppu = PPU.init();
    ppu.addressRegister.update(0x23);
    ppu.addressRegister.update(0x00);

    ppu.writeData(0xAB);

    try std.testing.expect(ppu.vram[ppu.mirrorVRAMAddress(0x2300)] == 0xAB);

    ppu.addressRegister.update(0x23);
    ppu.addressRegister.update(0x00);

    const first = ppu.readData(); // returns old buffer = 0x00
    const second = ppu.readData(); // returns 0xAB

    try std.testing.expect(first == 0x00);
    try std.testing.expect(second == 0xAB);
}

test "readData: palette returns immediately without buffering" {
    var ppu = PPU.init();
    ppu.addressRegister.update(0x3F);
    ppu.addressRegister.update(0x00);
    ppu.writeData(0xAB);

    ppu.addressRegister.update(0x3F);
    ppu.addressRegister.update(0x00);

    const first = ppu.readData(); // returns 0xAB, no buffering
    try std.testing.expect(first == 0xAB);
}

test "readData from chrom" {
    var data = [_]u8{ 0xA1, 0xA2, 0xA3, 0xA4, 0xA5 };

    var ppu = PPU.init();
    ppu.updateRomData(&data, Mirroring.Vertical);

    ppu.addressRegister.update(0x00);
    ppu.addressRegister.update(0x00);

    const first = ppu.readData(); // returns 0x00
    const second = ppu.readData(); // returns 0xA1
    const third = ppu.readData(); // returns 0xA2

    try std.testing.expect(first == 0x00);
    try std.testing.expect(second == 0xA1);
    try std.testing.expect(third == 0xA2);
}

test "controller register increment by 32" {
    var ppu = PPU.init();
    ppu.addressRegister.update(0x20);
    ppu.addressRegister.update(0x00);

    ppu.controllerRegister.update(0b00000100);

    ppu.writeData(0xAB);

    try std.testing.expect(ppu.addressRegister.get() == 0x2020);
}

test "vertical mirroring from VRAM" {
    var ppu = PPU.init();
    ppu.mirroring = Mirroring.Vertical;

    ppu.addressRegister.update(0x20);
    ppu.addressRegister.update(0x00);
    ppu.writeData(0xAB);

    ppu.addressRegister.update(0x28);
    ppu.addressRegister.update(0x00);
    _ = ppu.readData();
    const result = ppu.readData();

    try std.testing.expect(result == 0xAB);
}

test "horizontal mirroring from VRAM" {
    var ppu = PPU.init();
    ppu.mirroring = Mirroring.Horizontal;

    ppu.addressRegister.update(0x20);
    ppu.addressRegister.update(0x00);
    ppu.writeData(0xAB);

    ppu.addressRegister.update(0x24);
    ppu.addressRegister.update(0x00);
    _ = ppu.readData();
    const result = ppu.readData();

    try std.testing.expect(result == 0xAB);
}

test "palette mirroring" {
    var ppu = PPU.init();

    ppu.addressRegister.update(0x3F);
    ppu.addressRegister.update(0x00);
    ppu.writeData(0xA1);

    ppu.addressRegister.update(0x3F);
    ppu.addressRegister.update(0x10);
    const result = ppu.readData();

    try std.testing.expect(result == 0xA1);
}
