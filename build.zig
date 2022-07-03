const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const target = std.zig.CrossTarget{
        .cpu_arch = .avr,
        .cpu_model = .{ .explicit = &std.Target.avr.cpu.atmega328p },
        .os_tag = .freestanding,
        .abi = .none,
    };

    const demos_step = b.step("demos", "Build all demos");

    inline for (.{
        "blink",
        "serial",
        "button",
        "playground",
    }) |demo| {
        const demo_exe = b.addExecutable(demo, "demo/" ++ demo ++ ".zig");
        demo_exe.setTarget(target);
        demo_exe.setBuildMode(.ReleaseSmall);
        demo_exe.addPackagePath("arduino-uno", "arduino-uno/uno.zig");
        demo_exe.setLinkerScriptPath(.{ .path = "arduino-uno/linker.ld" });
        demo_exe.bundle_compiler_rt = false;
        demo_exe.install();

        const exe_step = b.step(demo, "Build demo (" ++ demo ++ ")");
        exe_step.dependOn(&demo_exe.step);
        demos_step.dependOn(&demo_exe.step);
    }

    const docs = b.addTest("src/uno.zig");
    docs.setBuildMode(.ReleaseSmall);
    docs.emit_docs = .emit;
    const docs_step = b.step("docs", "Build documentation");
    docs_step.dependOn(&docs.step);

    b.default_step.dependOn(demos_step);
}
