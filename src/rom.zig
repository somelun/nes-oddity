// NES file header
//
//
//
//  | String NES^Z
//  |
//  |           | Number of 16kB PRG ROM banks
//  |           |
//  |           |  | Number of 8kB CHR ROM banks
//  |           |  |
//  |           |  |  | Control Byte 1
//  |           |  |  |
//  |           |  |  |  | Control Byte 2
//  |           |  |  |  |
// 4E 45 53 1A 08 00 21 00 00 00 00 00 00 00 00 00
//                          |     |
//                          |     | Reserved, must be zero
//                          |
//                          | Size of PRG RAM in 8kB units
//
//
//
//
// Control Byte 1:
// 7 6 5 4 3 2 1 0
// | | | | | | | |
// | | | | | | | 0 for horizontal mirroring
// | | | | | | | 1 for vertical morroring
// | | | | | | |
// | | | | | | 1 for battery-backed RAM of 0x6000-0x7FFF
// | | | | | |
// | | | | | 1 for a 512-byte trainer at 0x7000-0x71FF
// | | | | |
// | | | | 1 for a four-screen VRAM layout
// | | | |
// | | | |
// Four lower bits of ROM mapper type
//
//
//
// Control Byte 2:
// 7 6 5 4 3 2 1 0
// | | | | | | | |
// | | | | | | | Should be 0 (for iNES 1.0 format)
// | | | | | | |
// | | | | | | Should be 0 (for iNES 1.0 format)
// | | | | | |
// | | | | if bits (3, 2) == 10, then its iNES 2.0 format
// | | | | if bits (3, 2) == 0, then its iNES 1.0 format
// | | | |
// | | | |
// Four upper bits of ROM mapper type
//
//
// More information about NES structure can be found here: https://formats.kaitai.io/ines/index.html

const std = @import("std");

const NES_HEADER = [_]u8{ 0x4E, 0x45, 0x53, 0x1A };

const ROMLoadError = error{ UnsupportedMapper, UnsupportedFormat, InvalidFormat };

// more about mirroring here: https://www.nesdev.org/wiki/Mirroring
pub const Mirroring = enum { Vertical, Horizontal, FourScreen };

pub const Rom = struct {
    prg_rom: []u8 = undefined,
    chr_rom: []u8 = undefined,
    mapper: u8 = 0,
    prg_rom_banks_number: u16 = 0,
    chr_rom_banks_number: u16 = 0,
    screen_mirroring: Mirroring,

    pub fn init(path: []const u8) !Rom {
        var rom: Rom = undefined;

        rom.load(path) catch |err| {
            switch (err) {
                error.FileNotFound => std.debug.print("File does not exist: {s}\n", .{path}),
                ROMLoadError.UnsupportedMapper => std.debug.print("Unsupported mapper: {s}\n", .{path}),
                ROMLoadError.UnsupportedFormat => std.debug.print("Unsupported format: {s}\n", .{path}),
                ROMLoadError.InvalidFormat => std.debug.print("Invalid format: {s}\n", .{path}),
                else => std.debug.print("Unknown error reading file: {s}\n", .{path}),
            }
            return err;
        };

        return rom;
    }

    pub fn deinit(self: *Rom) void {
        const allocator = std.heap.page_allocator;
        allocator.free(self.prg_rom);
        allocator.free(self.chr_rom);
    }

    // More info about the structure https://www.nesdev.org/wiki/INES
    fn load(self: *Rom, path: []const u8) !void {
        const io = std.Io.Threaded.global_single_threaded.io();
        const file = try std.Io.Dir.cwd().openFile(io, path, .{ .mode = .read_only });
        defer file.close(io);

        // reading header - first row of bytes
        var header: [16]u8 = undefined;
        const read = try file.readPositionalAll(io, &header, 0);
        if (read != 16) {
            return ROMLoadError.InvalidFormat;
        }

        if (!std.mem.eql(u8, header[0..4], &NES_HEADER)) {
            return ROMLoadError.UnsupportedFormat;
        }

        // reading all from the header
        self.prg_rom_banks_number = header[4]; // every bank is 16kB
        self.chr_rom_banks_number = header[5]; // every bank is 8kB
        const control_byte_1: u8 = header[6];
        const control_byte_2: u8 = header[7];
        // const prg_ram_size: u8 = header[8]; // in 8kB units

        // parsing control_byte_1
        const vertical_mirroring: bool = control_byte_1 & 0b1 == 0b1;
        // const battery: bool = control_byte_1 & 0b10 == 0b10;
        const trainer: bool = control_byte_1 & 0b100 == 0b100;
        const four_screen: bool = control_byte_1 & 0b1000 == 0b1000;

        self.mapper = ((control_byte_2 & 0b11110000) | (control_byte_1 & 0b11110000 >> 4));

        if (four_screen) {
            self.screen_mirroring = Mirroring.FourScreen;
        } else {
            self.screen_mirroring = if (vertical_mirroring) Mirroring.Vertical else Mirroring.Horizontal;
        }

        const prg_rom_size: u16 = self.prg_rom_banks_number * 16 * 1024;
        const chr_rom_size: u16 = self.chr_rom_banks_number * 8 * 1024;

        const prg_rom_start: u16 = if (trainer) 16 + 512 else 16;

        const allocator = std.heap.page_allocator;
        self.prg_rom = try allocator.alloc(u8, prg_rom_size);
        self.chr_rom = try allocator.alloc(u8, chr_rom_size);

        _ = try file.readPositionalAll(io, self.prg_rom, prg_rom_start);
        _ = try file.readPositionalAll(io, self.chr_rom, @as(u64, prg_rom_start) + prg_rom_size);
    }
};
