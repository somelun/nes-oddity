const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "nes-oddity",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const mod = exe.root_module;

    mod.addIncludePath(b.path("vendor"));
    mod.addIncludePath(b.path("src"));

    mod.addCSourceFile(.{
        .file = b.path("src/sokol_impl.c"),
        .flags = &.{"-ObjC"},
    });

    mod.linkFramework("Cocoa", .{});
    mod.linkFramework("QuartzCore", .{});
    mod.linkFramework("Metal", .{});
    mod.linkFramework("MetalKit", .{});
    mod.linkFramework("AudioToolbox", .{});

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
