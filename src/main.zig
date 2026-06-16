const std = @import("std");

const c = @cImport({
    @cDefine("SOKOL_NO_ENTRY", "");
    @cDefine("SOKOL_METAL", "");
    @cInclude("sokol_log.h");
    @cInclude("sokol_app.h");
    @cInclude("sokol_gfx.h");
    @cInclude("sokol_glue.h");
});

const Bus = @import("bus.zig").Bus;
const CPU = @import("cpu.zig").CPU;

const SCREEN_W = 32;
const SCREEN_H = 32;

const Color = struct { r: u8 = 0, g: u8 = 0, b: u8 = 0 };

const State = struct {
    pip: c.sg_pipeline,
    bind: c.sg_bindings,
    img: c.sg_image,
    bus: Bus,
    cpu: CPU,
    pixel_buf: [SCREEN_W * SCREEN_H]u32,
    frame_count: u32,
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
         1.0, -1.0, 1.0, 1.0,
         1.0,  1.0, 1.0, 0.0,
        -1.0,  1.0, 0.0, 0.0,
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

    // create a texture view from the image for shader binding
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
            }};
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

    state.bus = Bus.init();
    if (!state.bus.loadRom("roms/snake.nes")) {
        std.debug.print("failed to load rom\n", .{});
        return;
    }
    state.cpu = CPU.init(&state.bus);
    state.cpu.reset();
    state.frame_count = 0;
}

export fn frame() void {
    state.bus.write8(0xFE, @intCast((state.frame_count % 15) + 1));

    var i: u32 = 0;
    while (i < 700) : (i += 1) {
        _ = state.cpu.cycle();
    }

    readScreenState(&state.pixel_buf);

    c.sg_update_image(state.img, &c.sg_image_data{
        .mip_levels = blk: {
            var d: [16]c.sg_range = @splat(.{});
            d[0] = .{ .ptr = &state.pixel_buf, .size = @sizeOf(@TypeOf(state.pixel_buf)) };
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

export fn on_event(e: [*c]const c.sapp_event) void {
    if (e.*.type == c.SAPP_EVENTTYPE_KEY_DOWN) {
        switch (e.*.key_code) {
            c.SAPP_KEYCODE_W => state.bus.write8(0xFF, 0x77),
            c.SAPP_KEYCODE_S => state.bus.write8(0xFF, 0x73),
            c.SAPP_KEYCODE_A => state.bus.write8(0xFF, 0x61),
            c.SAPP_KEYCODE_D => state.bus.write8(0xFF, 0x64),
            c.SAPP_KEYCODE_ESCAPE => c.sapp_quit(),
            else => {},
        }
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
        .width = 320,
        .height = 320,
        .window_title = "nes oddity",
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = c.slog_func },
    });
}

fn convertByteToColor(byte: u8) Color {
    return switch (byte) {
        0 => .{ .r = 0, .g = 0, .b = 0 },
        1 => .{ .r = 255, .g = 255, .b = 255 },
        2, 9 => .{ .r = 128, .g = 128, .b = 128 },
        3, 10 => .{ .r = 255, .g = 0, .b = 0 },
        4, 11 => .{ .r = 0, .g = 255, .b = 0 },
        5, 12 => .{ .r = 0, .g = 255, .b = 255 },
        6, 13 => .{ .r = 255, .g = 0, .b = 255 },
        7, 14 => .{ .r = 255, .g = 255, .b = 0 },
        else => .{ .r = 0, .g = 255, .b = 255 },
    };
}

fn readScreenState(buffer: *[SCREEN_W * SCREEN_H]u32) void {
    var index: u16 = 0;
    var i: u16 = 0x0200;
    while (i < 0x0600) : (i += 1) {
        const value = state.bus.read8(i);
        const color = convertByteToColor(value);
        // RGBA8: R in high byte
        buffer[index] = (@as(u32, color.r) << 24) | (@as(u32, color.g) << 16) | (@as(u32, color.b) << 8) | 0xFF;
        index += 1;
    }
}
