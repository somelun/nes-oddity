const std = @import("std");

const nes_header = [_]u8{ 0x4E, 0x45, 0x53, 0x1A };

const LoadError = error{ UnsupportedMapper, UnsupportedFormat, InvalidFormat };

const Mirroring = enum {
    vertical, horizontal, four_screen
};

pub const Rom = struct {
    // prg_rom: [_]u8,
    // chr_rom: [_]u8,
    // mapper: u8,
    // screen_mirroring: Mirroring,
    pub fn init(path: []const u8) !Rom {
        try loadRom(path);

        return Rom{};
    }
};

fn loadRom(path: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, std.fs.File.OpenFlags{ .read = true });
    defer file.close();

    // reading header - first row of bytes
    var header: [16]u8 = undefined;
    const read = try file.read(header[0..header.len]);
    if (read != 16) {
        return LoadError.InvalidFormat;
    }

    // if (!std.mem.eql(u8, header[0..3], &nes_header)) {
    //     return LoadError.UnsupportedFormat;
    // }

    std.debug.print("{X}\n", .{header});
}
