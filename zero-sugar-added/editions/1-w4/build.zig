const std = @import("std");

pub fn build(b: *std.Build) !void {
    const w4 = b.findProgram(
        .{ .names = &.{"w4"} },
    ) orelse "./w4-macos-x86_64";

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const build_assets = b.addSystemCommand(&.{ w4, "png2src", "--zig" });
    build_assets.addFileArg(b.path("assets/landing.png"));
    build_assets.addArg("-o");
    const assets_file = build_assets.addOutputFileArg("assets.zig");

    const game = b.createModule(.{
        .root_source_file = b.path("src/lib/main.zig"),
        .target = target,
        .imports = &.{
            .{
                .name = "w4",
                .module = b.createModule(.{
                    .root_source_file = b.path("src/wasm4.zig"),
                    .target = target,
                }),
            },
            .{
                .name = "assets",
                .module = b.createModule(.{
                    .root_source_file = assets_file,
                    .target = target,
                }),
            },
        },
    });

    const exe = b.addExecutable(.{
        .name = "cart",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/exe/main.zig"),
            .target = target,
            .optimize = .ReleaseSmall,
            .imports = &.{.{
                .name = "game",
                .module = game,
            }},
        }),
    });

    exe.entry = .disabled;
    exe.root_module.export_symbol_names = &[_][]const u8{ "start", "update" };
    exe.import_memory = true;
    exe.initial_memory = 65536;
    exe.max_memory = 65536;
    exe.stack_size = 14752;

    b.installArtifact(exe);

    const run_exe = b.addSystemCommand(&.{ w4, "run-native" });
    run_exe.addArtifactArg(exe);

    const step_run = b.step("run", "compile and run the cart");
    step_run.dependOn(&run_exe.step);
}
