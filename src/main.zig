const std = @import("std");
const CPU = @import("cpu.zig").CPU;

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const time = @cImport({
    @cInclude("time.h");
});

const cstd = @cImport({
    @cInclude("stdlib.h");
});

// TODO:  move to other place later
const program_code = [_]u8{
    0x20, 0x06, 0x06, 0x20, 0x38, 0x06, 0x20, 0x0d, 0x06, 0x20, 0x2a, 0x06, 0x60, 0xa9, 0x02, 0x85,
    0x02, 0xa9, 0x04, 0x85, 0x03, 0xa9, 0x11, 0x85, 0x10, 0xa9, 0x10, 0x85, 0x12, 0xa9, 0x0f, 0x85,
    0x14, 0xa9, 0x04, 0x85, 0x11, 0x85, 0x13, 0x85, 0x15, 0x60, 0xa5, 0xfe, 0x85, 0x00, 0xa5, 0xfe,
    0x29, 0x03, 0x18, 0x69, 0x02, 0x85, 0x01, 0x60, 0x20, 0x4d, 0x06, 0x20, 0x8d, 0x06, 0x20, 0xc3,
    0x06, 0x20, 0x19, 0x07, 0x20, 0x20, 0x07, 0x20, 0x2d, 0x07, 0x4c, 0x38, 0x06, 0xa5, 0xff, 0xc9,
    0x77, 0xf0, 0x0d, 0xc9, 0x64, 0xf0, 0x14, 0xc9, 0x73, 0xf0, 0x1b, 0xc9, 0x61, 0xf0, 0x22, 0x60,
    0xa9, 0x04, 0x24, 0x02, 0xd0, 0x26, 0xa9, 0x01, 0x85, 0x02, 0x60, 0xa9, 0x08, 0x24, 0x02, 0xd0,
    0x1b, 0xa9, 0x02, 0x85, 0x02, 0x60, 0xa9, 0x01, 0x24, 0x02, 0xd0, 0x10, 0xa9, 0x04, 0x85, 0x02,
    0x60, 0xa9, 0x02, 0x24, 0x02, 0xd0, 0x05, 0xa9, 0x08, 0x85, 0x02, 0x60, 0x60, 0x20, 0x94, 0x06,
    0x20, 0xa8, 0x06, 0x60, 0xa5, 0x00, 0xc5, 0x10, 0xd0, 0x0d, 0xa5, 0x01, 0xc5, 0x11, 0xd0, 0x07,
    0xe6, 0x03, 0xe6, 0x03, 0x20, 0x2a, 0x06, 0x60, 0xa2, 0x02, 0xb5, 0x10, 0xc5, 0x10, 0xd0, 0x06,
    0xb5, 0x11, 0xc5, 0x11, 0xf0, 0x09, 0xe8, 0xe8, 0xe4, 0x03, 0xf0, 0x06, 0x4c, 0xaa, 0x06, 0x4c,
    0x35, 0x07, 0x60, 0xa6, 0x03, 0xca, 0x8a, 0xb5, 0x10, 0x95, 0x12, 0xca, 0x10, 0xf9, 0xa5, 0x02,
    0x4a, 0xb0, 0x09, 0x4a, 0xb0, 0x19, 0x4a, 0xb0, 0x1f, 0x4a, 0xb0, 0x2f, 0xa5, 0x10, 0x38, 0xe9,
    0x20, 0x85, 0x10, 0x90, 0x01, 0x60, 0xc6, 0x11, 0xa9, 0x01, 0xc5, 0x11, 0xf0, 0x28, 0x60, 0xe6,
    0x10, 0xa9, 0x1f, 0x24, 0x10, 0xf0, 0x1f, 0x60, 0xa5, 0x10, 0x18, 0x69, 0x20, 0x85, 0x10, 0xb0,
    0x01, 0x60, 0xe6, 0x11, 0xa9, 0x06, 0xc5, 0x11, 0xf0, 0x0c, 0x60, 0xc6, 0x10, 0xa5, 0x10, 0x29,
    0x1f, 0xc9, 0x1f, 0xf0, 0x01, 0x60, 0x4c, 0x35, 0x07, 0xa0, 0x00, 0xa5, 0xfe, 0x91, 0x00, 0x60,
    0xa6, 0x03, 0xa9, 0x00, 0x81, 0x10, 0xa2, 0x00, 0xa9, 0x01, 0x81, 0x10, 0x60, 0xa2, 0x00, 0xea,
    0xea, 0xca, 0xd0, 0xfb, 0x60,
};

const Color = struct {
    r: u8, g: u8, b: u8 = 0
};

fn convertByteToColor(byte: u8) Color {
    switch (byte) {
        0 => {
            // black
            return Color{ .r = 0, .g = 0, .b = 0 };
        },
        1 => {
            // white
            return Color{ .r = 255, .g = 255, .b = 255 };
        },
        2, 9 => {
            // grey
            return Color{ .r = 128, .g = 128, .b = 128 };
        },
        3, 10 => {
            // red
            return Color{ .r = 255, .g = 0, .b = 0 };
        },
        4, 11 => {
            // green
            return Color{ .r = 0, .g = 255, .b = 0 };
        },
        5, 12 => {
            // blue
            return Color{ .r = 0, .g = 255, .b = 255 };
        },
        6, 13 => {
            // magenta
            return Color{ .r = 255, .g = 0, .b = 255 };
        },
        7, 14 => {
            // yellow
            return Color{ .r = 255, .g = 255, .b = 0 };
        },
        else => {
            // cyan
            return Color{ .r = 0, .g = 255, .b = 255 };
        },
    }
}

fn readScreenState(cpu: *CPU, buffer: []u24) void {
    var index: u16 = 0;
    // reading color values from memory
    var i: u16 = 0x0200;
    while (i < 0x0600) : (i += 1) {
        const value = cpu.memory.read8(i);
        var color: Color = convertByteToColor(value);

        buffer[index] = (@as(u24, color.r) << 16) + (@as(u24, color.g) << 8) + @as(u24, color.b);
        index += 1;
    }
}

pub fn main() anyerror!void {
    cstd.srand(@intCast(u32, time.time(0)));

    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow("nes oddity", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, 320, 320, c.SDL_WINDOW_OPENGL) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(window);

    const renderer = c.SDL_CreateRenderer(window, -1, 0) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    const texture = c.SDL_CreateTexture(renderer, c.SDL_PIXELFORMAT_RGB888, c.SDL_TEXTUREACCESS_STREAMING, 32, 32) orelse {
        std.debug.warn("Cannot create texture: {s}", .{c.SDL_GetError()});
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyTexture(texture);

    // CPU
    var cpu = CPU.init();
    cpu.load(&program_code);
    cpu.reset();

    var buffer: [32 * 32]u24 = undefined;

    // sdl loop
    var quit = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;

        // TODO: someday switch to https://stackoverflow.com/questions/11699183/what-is-the-best-way-to-read-input-from-keyboard-using-sdl
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.@"type") {
                c.SDL_KEYUP, c.SDL_KEYDOWN => {
                    const down = event.type == c.SDL_KEYDOWN;

                    if (event.key.keysym.sym == c.SDLK_w and down) {
                        cpu.memory.write8(0xFF, 0x77);
                    }
                    if (event.key.keysym.sym == c.SDLK_s and down) {
                        cpu.memory.write8(0xFF, 0x73);
                    }
                    if (event.key.keysym.sym == c.SDLK_a and down) {
                        cpu.memory.write8(0xFF, 0x61);
                    }
                    if (event.key.keysym.sym == c.SDLK_d and down) {
                        cpu.memory.write8(0xFF, 0x64);
                    }
                },
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }
        // input requires random number at 0xFE
        cpu.memory.write8(0xFE, @intCast(u8, @rem(cstd.rand(), 16) + 1));

        cpu.cycle();

        readScreenState(&cpu, &buffer);
        const result: c_int = c.SDL_UpdateTexture(texture, 0, &buffer[0], @intCast(c_int, 32) * @sizeOf(u24));

        _ = c.SDL_RenderClear(renderer);
        _ = c.SDL_RenderCopy(renderer, texture, null, null);
        c.SDL_RenderPresent(renderer);

        c.SDL_Delay(17);
    }
}
