const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "myzql",
        .root_source_file = b.path("src/myzql.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zmpl_module = b.addModule("myzql", .{ 
        .root_source_file = b.path("src/myzql.zig"),
    });
    lib.root_module.addImport("myzql", zmpl_module);

    // -Dtest-filter="..."
    const test_filter = b.option([]const []const u8, "test-filter", "Filter for tests to run");

    // zig build unit_test
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/myzql.zig"),
    });
    if (test_filter) |t| unit_tests.filters = t;

    // zig build [install]
    b.installArtifact(unit_tests);

    // zig build -Dtest-filter="..." run_unit_test
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const unit_test_step = b.step("unit_test", "Run unit tests");
    unit_test_step.dependOn(&run_unit_tests.step);

    // zig build -Dtest-filter="..." integration_test
    const integration_tests = b.addTest(.{
        .root_source_file = b.path("./integration_tests/main.zig"),
    });
    integration_tests.root_module.addImport("myzql", zmpl_module);
    if (test_filter) |t| integration_tests.filters = t;

    // zig build [install]
    b.installArtifact(integration_tests);

    // zig build integration_test
    const run_integration_tests = b.addRunArtifact(integration_tests);
    const integration_test_step = b.step("integration_test", "Run integration tests");
    integration_test_step.dependOn(&run_integration_tests.step);
}
