const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "nes-oddity",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    exe.addLibraryPath(b.path("./lib"));
    exe.linkSystemLibrary("SDL2");

    exe.addIncludePath(.{ .cwd_relative = ("/opt/homebrew/include") });

    b.installArtifact(exe);

    exe.linkSystemLibrary("iconv");
    exe.linkFramework("AppKit");
    exe.linkFramework("AudioToolbox");
    exe.linkFramework("Carbon");
    exe.linkFramework("Cocoa");
    exe.linkFramework("CoreAudio");
    exe.linkFramework("CoreFoundation");
    exe.linkFramework("CoreGraphics");
    exe.linkFramework("CoreHaptics");
    exe.linkFramework("CoreVideo");
    exe.linkFramework("ForceFeedback");
    exe.linkFramework("GameController");
    exe.linkFramework("IOKit");
    exe.linkFramework("Metal");

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
