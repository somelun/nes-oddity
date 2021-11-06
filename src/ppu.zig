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

    internal_buffer: u8 = 0,

    mirroring: Mirroring = undefined,

    addressRegister: AddressRegister = undefined,
    controllerRegister: ControllerRegister = undefined,

    pub fn init(chr_rom: []u8, mirroring: Mirroring) PPU {
        var ppu = PPU{};

        ppu.chr_rom = chr_rom;
        ppu.mirroring = mirroring;
        ppu.addressRegister = AddressRegister.init();
        ppu.controllerRegister = ControllerRegister.init();

        return ppu;
    }

    pub fn writeToAddressRegister(self: *PPU, value: u8) void {
        self.addressRegister.update(value);
    }

    pub fn writeToControllerRegister(self: *PPU, value: u8) void {
        self.controllerRegister.update(value);
    }

    pub fn writeData(self: *PPU, value: u8) void {
        const address: u16 = self.addressRegister.get();
        switch (address) {
            0...0x1FFF => {
                // std.debug.print("attempt to write to chr rom space {X}", .{address});
            },

            0x2000...0x2FFF => {
                self.vram[self.mirrorVRAMAddress(address)] = value;
            },

            0x3000...0x3EFF => {},

            // Addresses $3F10/$3F14/$3F18/$3F1C are mirrors of $3F00/$3F04/$3F08/$3F0C.
            // https://wiki.nesdev.org/w/index.php/PPU_palettes
            0x3F00...0x3FFF => {
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
        self.incrementVRAMAddressRegister();
    }

    // instead of implementing PPU Data Register (0x2007) we just have this function
    pub fn readData(self: *PPU) u8 {
        const address: u16 = self.addressRegister.get();
        self.incrementVRAMAddressRegister();

        switch (address) {
            0...0x1FFF => {
                // read from chr_rom
                const result: u8 = self.internal_buffer;
                self.internal_buffer = self.chr_rom[address];
                return result;
            },

            0x2000...0x2FFF => {
                // read from RAM
                const result: u8 = self.internal_buffer;
                self.internal_buffer = self.vram[self.mirrorVRAMAddress(address)];
                return result;
            },

            0x3000...0x3EFF => {
                //address space 0x3000..0x3EFF is not expected to be used
            },

            // Addresses $3F10/$3F14/$3F18/$3F1C are mirrors of $3F00/$3F04/$3F08/$3F0C.
            // https://wiki.nesdev.org/w/index.php/PPU_palettes
            0x3F00...0x3FFF => {
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

            else => {},
        }

        return 0;
    }

    fn readStatusRegister() void {
        //
    }

    // Horizotal mirroring:
    // [A][a]
    // [B][b]
    //
    // Vertical mirroring:
    // [A][B]
    // [a][b]
    fn mirrorVRAMAddress(self: *PPU, address: u16) u16 {
        const mirrored_vram: u16 = address & 0b10111111111111; // mirror down 0x3000-0x3EFF to 0x2000 - 0x2EFF
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

    fn incrementVRAMAddressRegister(self: *PPU) void {
        self.addressRegister.increment(self.controllerRegister.VRAMAddressIncrement());
    }
};

// PPU Controller Register (0x2000)
const ControllerRegister = struct {
    // 7  bit  0
    // ---- ----
    // VPHB SINN
    // |||| ||||
    // |||| ||++- Base nametable address
    // |||| ||    (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
    // |||| |+--- VRAM address increment per CPU read/write of PPUDATA
    // |||| |     (0: add 1, going across; 1: add 32, going down)
    // |||| +---- Sprite pattern table address for 8x8 sprites
    // ||||       (0: $0000; 1: $1000; ignored in 8x16 mode)
    // |||+------ Background pattern table address (0: $0000; 1: $1000)
    // ||+------- Sprite size (0: 8x8 pixels; 1: 8x16 pixels)
    // |+-------- PPU master/slave select
    // |          (0: read backdrop from EXT pins; 1: output color on EXT pins)
    // +--------- Generate an NMI at the start of the
    //            vertical blanking interval (0: off; 1: on)
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

    pub fn nametable(self: *controllerregister) u16 {
        switch (self.flags & (@enumToInt(flags.nametablelo) ^ @enumToInt(flags.NametableHi))) {
            0 => return 0x2000,
            1 => return 0x2400,
            2 => return 0x2800,
            3 => return 0x2c00,
        }
    }

    pub fn VRAMAddressIncrement(self: *ControllerRegister) u8 {
        if (self.flags & @enumToInt(Flags.VRAMAddressIncrement) > 0) {
            return 32;
        } else {
            return 1;
        }
    }

    pub fn spritePatternAddress(self: *ControllerRegisger) u16 {
        switch (self.flags & @enumToInt(Flags.SpritePatternAddress)) {
            0 => return 0,
            1 => return 0x1000,
        }
    }

    pub fn spritePatternTableAddress(self: *ControllRegister) u16 {
        switch (self.flags & @enumToInt(Flags.SpritePatternTableAddress)) {
            0 => return 0,
            1 => return 0x1000,
        }
    }

    pub fn spriteSize(self: *ControllRegister) u8 {
        switch (self.flags & @enumToInt(Flags.SpritePatternTableAddress)) {
            0 => return 0x8,
            1 => return 0x10,
        }
    }

    pub fn masterSlaveSelect() bool {
        switch (self.flags & @enumToInt(Flags.MasterSlaveSelect)) {
            0 => return false,
            1 => return true,
        }
    }

    pub fn generateVBlanckNMI() bool {
        switch (self.flags & @enumToInt(Flags.generateVBlanckNMI)) {
            0 => return true,
            1 => return false,
        }
    }

    pub fn update(self: *ControllerRegister, data: u8) void {
        self.flags = data;
    }
};

// PPU Mask Register (0x2001)
const MaskRegister = struct {};

// PPU Status Register (0x2002)
const StatusRegister = struct {
    const Value = enum(u8) {
        Unused1 = (1 << 0),
        Unused2 = (1 << 1),
        Unused3 = (1 << 2),
        Unused4 = (1 << 3),
        Unused5 = (1 << 4),
        SpriteOverlow = (1 << 5),
        SpriteZeroHit = (1 << 6),
        VBlankStarted = (1 << 7),
    };

    value: u8 = 0,

    pub fn init() StatusRegister {
        return StatusRegister{};
    }

    // pub fn setVBlankStatus(self: *StatusRegister) void {
    //     //self.set(StatusRegister::VBLANK_STARTED, status);
    // }
    //
    // pub fn setSpriteZeroHit(self: *StatusRegister) void {
    //     //self.set(StatusRegister::SPRITE_ZERO_HIT, status);
    // }
    //
    // pub fn setSpriteOverflow(self: *StatusRegister) void {
    //     //self.set(StatusRegister::SPRITE_OVERFLOW, status);
    // }

    pub fn setFlag(self: *StatusRegister, flag: Value, value: bool) void {
        const number = @enumToInt(flag);
        if (value) {
            self.value = self.value | number;
        } else {
            self.value = self.value & (~number);
        }
    }

    pub fn isVBlankStarted(self: *StatusRegister) bool {
        return if (self.value & @enumToInt(Value.VBlackStarted) > 0) true else false;
    }

    pub fn snapshot(self: *StatusRegister) u8 {
        return self.value;
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
        self.hi_byte = @intCast(u8, data >> 8);
        self.lo_byte = @intCast(u8, data & 0xFF);
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
            self.set(fetched & 0b11111111111111);
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
            self.set(fetched & 0b11111111111111);
        }
    }

    pub fn reset_latch(self: *AddressRegister) void {
        self.using_hi = true;
    }
};

// PPU Data Register (0x2007)
const DataRegister = struct {};
