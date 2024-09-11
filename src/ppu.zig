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

const Mirroring = @import("rom.zig").Mirroring;

const CHR_ROM_BEGIN: u16 = 0x0000;
const CHR_ROM_END: u16 = 0x1FFF;

const VRAM_BEGIN = 0x2000;
const VRAM_END = 0x2FFF;

const PALETTES_BEGIN = 0x3F00;
const PALETTES_END = 0x3FFF;

const CONTROLLER = 0x2000;
const ADDRESS = 0x2006;

pub const PPU = struct {
    chr_rom: []u8 = undefined, // visuals of the game, stored on a cartridge
    palette_table: [0x20]u8 = [_]u8{0} ** 0x20, // palette table used atm
    vram: [0x800]u8 = [_]u8{0} ** 0x800,
    oam_data: [0x100]u8 = [_]u8{0} ** 0x100,

    mirroring: Mirroring = undefined,

    addressRegister: AddressRegister = undefined,
    controllerRegister: ControllerRegister = undefined,

    internal_buffer: u8 = 0,

    pub fn init() PPU {
        var ppu = PPU{};

        ppu.addressRegister = AddressRegister.init();
        ppu.controllerRegister = ControllerRegister.init();

        return ppu;
    }

    pub fn updateRomData(self: *PPU, chr_rom: []u8, mirroring: Mirroring) void {
        self.chr_rom = chr_rom;
        self.mirroring = mirroring;
    }

    pub fn readData(self: *PPU) u8 {
        const address: u16 = self.addressRegister.get();

        // every read operation should increment Address Register for
        // the value from the Controller Register
        self.addressRegister.increment(self.controllerRegister.VRAMAddressIncrement());

        switch (address) {
            // read from chr_rom
            CHR_ROM_BEGIN...CHR_ROM_END => {
                const result: u8 = self.internal_buffer;
                self.internal_buffer = self.chr_rom[address];
                return result;
            },

            // read from VRAM
            VRAM_BEGIN...VRAM_END => {
                const result: u8 = self.internal_buffer;
                self.internal_buffer = self.vram[self.mirrorVRAMAddress(address)];
                return result;
            },

            // read from Palette
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

    pub fn writeData(self: *PPU, value: u8) void {
        const address: u16 = self.addressRegister.get();

        switch (address) {
            // PPU range
            0x2000...0x2FFF => {
                switch (address) {
                    CONTROLLER => {
                        self.controllerRegister.update(value);
                    },

                    ADDRESS => {
                        self.addressRegister.update(value);
                    },

                    0x2007 => {
                        self.addressRegister.increment(self.controllerRegister.VRAMAddressIncrement());
                    },

                    else => {
                        self.vram[self.mirrorVRAMAddress(address)] = value;
                    },
                }
            },

            0x3F00...0x3FFF => {
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
        switch (self.flags & @intFromEnum(Flags.BackgroundPatternAddress)) {
            0 => return 0,
            1 => return 0x1000,
        }
    }

    pub fn spriteSize(self: *ControllerRegister) u8 {
        switch (self.flags & @intFromEnum(Flags.SpritePatternTableAddress)) {
            0 => return 8,
            1 => return 16,
        }
    }

    pub fn isMasterSlaveSelect(self: *ControllerRegister) bool {
        return (self.flags & @intFromEnum(Flags.MasterSlaveSelect)) == 1;
    }

    pub fn isGenerateVBlanckNMI(self: *ControllerRegister) bool {
        return (self.flags & @intFromEnum(Flags.generateVBlanckNMI)) == 1;
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
        return (self.flags & @intFromEnum(Flags.Greyscale)) == 1;
    }

    pub fn isShowBackgroungInLeftmost8(self: *MaskRegister) bool {
        return (self.flags & @intFromEnum(Flags.ShowBackgroungInLeftmost8)) == 1;
    }

    pub fn isShowSpritesInLeftmost8(self: *MaskRegister) bool {
        return (self.flags & @intFromEnum(Flags.ShowSpritesInLeftmost8)) == 1;
    }

    pub fn isShowBackground(self: *MaskRegister) bool {
        return (self.flags & @intFromEnum(Flags.ShowBackground)) == 1;
    }

    pub fn isShowSprites(self: *MaskRegister) bool {
        return (self.flags & @intFromEnum(Flags.ShowSprites)) == 1;
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

    pub fn setSpriteOverflow(self: *StatusRegister) void {
        self.flags = self.flags & @intFromEnum(Flags.SpriteOverflow);
    }

    pub fn setSpriteZeroHit(self: *StatusRegister) void {
        self.flags = self.flags & @intFromEnum(Flags.SpriteZeroHit);
    }

    pub fn setVBlankStarted(self: *StatusRegister) void {
        self.flags = self.flags & @intFromEnum(Flags.VBlankStarted);
    }

    pub fn isSpriteOverflow(self: *StatusRegister) bool {
        return (self.flags & @intFromEnum(Flags.SpriteOverflow)) == 1;
    }

    pub fn isSpriteZeroHit(self: *StatusRegister) bool {
        return (self.flags & @intFromEnum(Flags.SpriteZeroHit)) == 1;
    }

    pub fn isVBlankStarted(self: *StatusRegister) bool {
        return (self.flags & @intFromEnum(Flags.VBlankStarted)) == 1;
    }
};

// OAM Adress Register (0x2003)
// OAM Data Register (0x2004)

// Scroll Register (0x2005)
const ScrollRegister = struct {
    scroll_x: u8 = 0,
    scroll_y: u8 = 0,
    latch: bool = false,

    pub fn init() ScrollRegister {
        return ScrollRegister{};
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
