const std = @import("std");

const c = @cImport({
    @cDefine("SOKOL_NO_ENTRY", "");
    @cDefine("SOKOL_METAL", "");
    @cInclude("sokol_log.h");
    @cInclude("sokol_app.h");
    @cInclude("sokol_gfx.h");
    @cInclude("sokol_glue.h");
    @cInclude("sokol_audio.h");
});

const Bus = @import("bus.zig").Bus;
const CPU = @import("cpu.zig").CPU;

// if false will just print all the tiles
const GAME_LOOP = true;
const SCREEN_W = 256;
const SCREEN_H = 240;

const State = struct {
    pip: c.sg_pipeline,
    bind: c.sg_bindings,
    img: c.sg_image,
    bus: Bus,
    cpu: CPU,
    rgba_buf: [SCREEN_W * SCREEN_H * 4]u8,
    frame_count: u32,
    rom_loaded: bool,
};

var state: State = undefined;

const vs_src =
    \\#include <metal_stdlib>
    \\using namespace metal;
    \\struct vs_in { float2 pos [[attribute(0)]]; float2 uv [[attribute(1)]]; };
    \\struct vs_out { float4 pos [[position]]; float2 uv; };
    \\vertex vs_out vs_main(vs_in in [[stage_in]]) {
    \\    vs_out out;
    \\    out.pos = float4(in.pos, 0.0, 1.0);
    \\    out.uv = in.uv;
    \\    return out;
    \\}
;

const fs_src =
    \\#include <metal_stdlib>
    \\using namespace metal;
    \\struct fs_in { float2 uv; };
    \\fragment float4 fs_main(fs_in in [[stage_in]],
    \\                        texture2d<float> tex [[texture(0)]],
    \\                        sampler smp [[sampler(0)]]) {
    \\    return tex.sample(smp, in.uv);
    \\}
;

export fn init() void {
    c.sg_setup(&c.sg_desc{
        .environment = c.sglue_environment(),
        .logger = .{ .func = c.slog_func },
    });

    const vertices = [_]f32{
        -1.0, -1.0, 0.0, 1.0,
        1.0,  -1.0, 1.0, 1.0,
        1.0,  1.0,  1.0, 0.0,
        -1.0, 1.0,  0.0, 0.0,
    };
    const indices = [_]u16{ 0, 1, 2, 0, 2, 3 };

    state.bind.vertex_buffers[0] = c.sg_make_buffer(&c.sg_buffer_desc{
        .data = c.sg_range{ .ptr = &vertices, .size = @sizeOf(@TypeOf(vertices)) },
    });
    state.bind.index_buffer = c.sg_make_buffer(&c.sg_buffer_desc{
        .usage = .{ .index_buffer = true },
        .data = c.sg_range{ .ptr = &indices, .size = @sizeOf(@TypeOf(indices)) },
    });

    state.img = c.sg_make_image(&c.sg_image_desc{
        .width = SCREEN_W,
        .height = SCREEN_H,
        .pixel_format = c.SG_PIXELFORMAT_RGBA8,
        .usage = .{ .stream_update = true },
    });

    const view = c.sg_make_view(&c.sg_view_desc{
        .texture = .{ .image = state.img },
    });
    state.bind.views[0] = view;

    state.bind.samplers[0] = c.sg_make_sampler(&c.sg_sampler_desc{
        .min_filter = c.SG_FILTER_NEAREST,
        .mag_filter = c.SG_FILTER_NEAREST,
    });

    const shd = c.sg_make_shader(&c.sg_shader_desc{
        .vertex_func = .{ .source = vs_src, .entry = "vs_main" },
        .fragment_func = .{ .source = fs_src, .entry = "fs_main" },
        .views = blk: {
            var v: [32]c.sg_shader_view = @splat(.{});
            v[0] = .{ .texture = .{
                .stage = c.SG_SHADERSTAGE_FRAGMENT,
                .image_type = c.SG_IMAGETYPE_2D,
                .sample_type = c.SG_IMAGESAMPLETYPE_FLOAT,
                .msl_texture_n = 0,
            } };
            break :blk v;
        },
        .samplers = blk: {
            var s: [12]c.sg_shader_sampler = @splat(.{});
            s[0] = .{
                .stage = c.SG_SHADERSTAGE_FRAGMENT,
                .sampler_type = c.SG_SAMPLERTYPE_FILTERING,
                .msl_sampler_n = 0,
            };
            break :blk s;
        },
        .texture_sampler_pairs = blk: {
            var p: [32]c.sg_shader_texture_sampler_pair = @splat(.{});
            p[0] = .{
                .stage = c.SG_SHADERSTAGE_FRAGMENT,
                .view_slot = 0,
                .sampler_slot = 0,
            };
            break :blk p;
        },
    });

    state.pip = c.sg_make_pipeline(&c.sg_pipeline_desc{
        .shader = shd,
        .index_type = c.SG_INDEXTYPE_UINT16,
        .layout = blk: {
            var layout: c.sg_vertex_layout_state = .{};
            layout.attrs[0] = .{ .format = c.SG_VERTEXFORMAT_FLOAT2 };
            layout.attrs[1] = .{ .format = c.SG_VERTEXFORMAT_FLOAT2 };
            break :blk layout;
        },
    });

    state.rom_loaded = false;
    state.bus = Bus.init();
    if (!state.bus.loadRom("roms/pacman1.nes")) {
        std.debug.print("failed to load rom\n", .{});
        return;
    }
    state.rom_loaded = true;
    state.cpu = CPU.init(&state.bus);
    state.cpu.reset();
    state.frame_count = 0;

    if (!GAME_LOOP) {
        showAllTiles();
    }
}

fn convertFrameBuffer() void {
    const fb = &state.bus.ppu.frame_buffer;
    var i: usize = 0;
    while (i < SCREEN_W * SCREEN_H) : (i += 1) {
        state.rgba_buf[i * 4 + 0] = fb[i * 3 + 0];
        state.rgba_buf[i * 4 + 1] = fb[i * 3 + 1];
        state.rgba_buf[i * 4 + 2] = fb[i * 3 + 2];
        state.rgba_buf[i * 4 + 3] = 0xFF;
    }
}

fn showAllTiles() void {
    var bank: u8 = 0;
    while (bank <= 1) : (bank += 1) {
        var tile_n: u16 = 0;
        while (tile_n < 256) : (tile_n += 1) {
            const tile_x = tile_n % 16;
            const tile_y = tile_n / 16;
            const offset_x = @as(u16, bank) * 128 + tile_x * 8;
            const offset_y = tile_y * 8;
            state.bus.ppu.showTile(bank, @intCast(tile_n), offset_x, offset_y);
        }
    }
}

export fn frame() void {
    if (!state.rom_loaded) return;
    if (GAME_LOOP) {
        const cycles_start = state.bus.cycles;
        while (state.bus.cycles - cycles_start < 29780) {
            _ = state.cpu.cycle();
        }
    }

    convertFrameBuffer();

    c.sg_update_image(state.img, &c.sg_image_data{
        .mip_levels = blk: {
            var d: [16]c.sg_range = @splat(.{});
            d[0] = .{ .ptr = &state.rgba_buf, .size = @sizeOf(@TypeOf(state.rgba_buf)) };
            break :blk d;
        },
    });

    c.sg_begin_pass(&c.sg_pass{ .swapchain = c.sglue_swapchain() });
    c.sg_apply_pipeline(state.pip);
    c.sg_apply_bindings(&state.bind);
    c.sg_draw(0, 6, 1);
    c.sg_end_pass();
    c.sg_commit();

    state.frame_count += 1;
}

const JoypadButton = @import("joypad.zig").JoypadButton;

fn setButton(key: c_uint, pressed: bool) void {
    const btn: u8 = switch (key) {
        c.SAPP_KEYCODE_J => @intFromEnum(JoypadButton.ButtonA),
        c.SAPP_KEYCODE_K => @intFromEnum(JoypadButton.ButtonB),
        c.SAPP_KEYCODE_SPACE => @intFromEnum(JoypadButton.Select),
        c.SAPP_KEYCODE_ENTER => @intFromEnum(JoypadButton.Start),
        c.SAPP_KEYCODE_W => @intFromEnum(JoypadButton.Up),
        c.SAPP_KEYCODE_S => @intFromEnum(JoypadButton.Down),
        c.SAPP_KEYCODE_A => @intFromEnum(JoypadButton.Left),
        c.SAPP_KEYCODE_D => @intFromEnum(JoypadButton.Right),
        else => return,
    };
    if (pressed) {
        state.bus.joypad.buttons |= btn;
    } else {
        state.bus.joypad.buttons &= ~btn;
    }
}

export fn on_event(e: [*c]const c.sapp_event) void {
    switch (e.*.type) {
        c.SAPP_EVENTTYPE_KEY_DOWN => {
            if (e.*.key_code == c.SAPP_KEYCODE_ESCAPE) {
                c.sapp_quit();
                return;
            }
            setButton(e.*.key_code, true);
        },
        c.SAPP_EVENTTYPE_KEY_UP => {
            setButton(e.*.key_code, false);
        },
        else => {},
    }
}

export fn cleanup() void {
    c.sg_shutdown();
}

pub fn main() void {
    c.sapp_run(&c.sapp_desc{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = on_event,
        .cleanup_cb = cleanup,
        .width = 512,
        .height = 480,
        .window_title = "nes oddity",
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = c.slog_func },
    });
}
