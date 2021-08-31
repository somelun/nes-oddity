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

    pub fn writeToAddress(self: *PPU, data: u8) void {
        self.addressRegister.update(data);
    }

    pub fn writeToController(self: *PPU, data: u8) void {
        self.controllerRegister.update(data);
    }

    pub fn writeData(self: *PPU, data: u8) void {
        //
    }

    pub fn readData(self: *PPU) u8 {
        const address: u16 = self.addressRegister.get();
        self.incrementVRAMAddress();

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
                //addr space 0x3000..0x3eff is not expected to be used
            },

            0x3F00...0x3FFF => {
                return self.palette_table[address - 0x3F00];
            },

            else => {},
        }

        return 0;
    }

    fn incrementVRAMAddress(self: *PPU) void {
        self.addressRegister.increment(self.controllerRegister.VRAMAddressIncrement());
    }

    fn mirrorVRAMAddress(self: *PPU, address: u16) u16 {
        const mirrored_vram: u16 = address & 0b10111111111111; // mirror down 0x3000-0x3eff to 0x2000 - 0x2eff
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
pub const ControllerRegister = struct {
    const Value = enum(u8) {
        NametableLo = (1 << 0),
        NametableHi = (1 << 1),
        VRAMAddressIncrement = (1 << 2),
        SpritePatternAddress = (1 << 3),
        BackgroundPatternAddress = (1 << 4),
        SpriteSize = (1 << 5),
        MasterSlaveSelect = (1 << 6),
        GenerateNMI = (1 << 7),
    };

    value: u8 = 0,

    pub fn init() ControllerRegister {
        return ControllerRegister{};
    }

    pub fn VRAMAddressIncrement(self: *ControllerRegister) u8 {
        if (self.value & @enumToInt(Value.VRAMAddressIncrement) > 0) {
            return 32;
        } else {
            return 1;
        }
    }

    pub fn update(self: *ControllerRegister, data: u8) void {
        self.value = data;
    }
};

// PPU Address Register (0x2006)
pub const AddressRegister = struct {
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
        self.using_hi = true;
    }
};

// PPU Data Register (0x2007)
pub const DataRegister = struct {};
