const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("bits", .{
        .source_file = .{ .path = "bits.zig" },
    });

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "bits.zig"},
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_tests.step);
}
