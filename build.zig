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

    mod.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    mod.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });

    mod.linkSystemLibrary("SDL3", .{});
    mod.linkSystemLibrary("iconv", .{});
    mod.linkFramework("AppKit", .{});
    mod.linkFramework("AudioToolbox", .{});
    mod.linkFramework("Carbon", .{});
    mod.linkFramework("Cocoa", .{});
    mod.linkFramework("CoreAudio", .{});
    mod.linkFramework("CoreFoundation", .{});
    mod.linkFramework("CoreGraphics", .{});
    mod.linkFramework("CoreHaptics", .{});
    mod.linkFramework("CoreVideo", .{});
    mod.linkFramework("ForceFeedback", .{});
    mod.linkFramework("GameController", .{});
    mod.linkFramework("IOKit", .{});
    mod.linkFramework("Metal", .{});

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
