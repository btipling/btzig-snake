const std = @import("std");
const zgui = @import("libs/zig-gamedev/libs/zgui/build.zig");
const glfw = @import("libs/zig-gamedev/libs/zglfw/build.zig");
const zopengl = @import("libs/zig-gamedev/libs/zopengl/build.zig");
const zstbi = @import("libs/zig-gamedev/libs/zstbi/build.zig");
const zaudio = @import("libs/zig-gamedev/libs/zaudio/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "btzigsnake",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const zgui_pkg = zgui.package(b, target, optimize, .{
        .options = .{ .backend = .glfw_opengl3 },
    });
    const zglf_pkg = glfw.package(b, target, optimize, .{});
    const zopengl_pkg = zopengl.package(b, target, optimize, .{});
    const zstbi_pkg = zstbi.package(b, target, optimize, .{});
    const zaudio_pkg = zaudio.package(b, target, optimize, .{});

    zgui_pkg.link(exe);
    zglf_pkg.link(exe);
    zopengl_pkg.link(exe);
    zstbi_pkg.link(exe);
    zaudio_pkg.link(exe);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
