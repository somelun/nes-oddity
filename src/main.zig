const std = @import("std");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Bus = @import("bus.zig").Bus;
const CPU = @import("cpu.zig").CPU;

const Color = struct { r: u8 = 0, g: u8 = 0, b: u8 = 0 };

pub fn main() anyerror!void {
    c.srand(@intCast(c.time(0)));

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
        std.debug.print("Cannot create texture: {s}", .{c.SDL_GetError()});
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyTexture(texture);

    var bus = Bus.init();
    if (!bus.loadRom("roms/donkey.nes")) {
        return;
    }

    var cpu = CPU.init(&bus);
    cpu.reset();

    var buffer: [32 * 32]u24 = undefined;

    var count: u32 = 30;

    // sdl loop
    var quit = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;

        // TODO: someday switch to https://stackoverflow.com/questions/11699183/what-is-the-best-way-to-read-input-from-keyboard-using-sdl
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_KEYUP, c.SDL_KEYDOWN => {
                    const down = event.type == c.SDL_KEYDOWN;

                    if (event.key.keysym.sym == c.SDLK_w and down) {
                        bus.write8(0xFF, 0x77);
                    }
                    if (event.key.keysym.sym == c.SDLK_s and down) {
                        bus.write8(0xFF, 0x73);
                    }
                    if (event.key.keysym.sym == c.SDLK_a and down) {
                        bus.write8(0xFF, 0x61);
                    }
                    if (event.key.keysym.sym == c.SDLK_d and down) {
                        bus.write8(0xFF, 0x64);
                    }
                },
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }
        // input requires random number at 0xFE
        bus.write8(0xFE, @intCast(@rem(c.rand(), 16) + 1));

        // TODO: count cycles and remove hardcoded count
        _ = cpu.cycle();

        readScreenState(&cpu, &buffer);
        _ = c.SDL_UpdateTexture(texture, 0, &buffer[0], 32 * @sizeOf(u24));

        count -= 1;
        if (count == 0) {
            count = 30;

            _ = c.SDL_RenderClear(renderer);
            _ = c.SDL_RenderCopy(renderer, texture, null, null);
            c.SDL_RenderPresent(renderer);
        }

        std.time.sleep(16 * 1000 * 10);

        // TODO: NES cpu works with 1.7 MHz, every game runs at 60 fps
        // that is what required to implement, I'll do this after implementing Bus and PPU
    }
}

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
        const value = cpu.bus.read8(i);
        const color: Color = convertByteToColor(value);

        buffer[index] = (@as(u24, color.r) << 16) + (@as(u24, color.g) << 8) + @as(u24, color.b);
        index += 1;
    }
}
