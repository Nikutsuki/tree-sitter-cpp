const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const shared = b.option(bool, "build-shared", "Build a shared library") orelse true;
    const reuse_alloc = b.option(bool, "reuse-allocator", "Reuse the library allocator") orelse false;

    const library_name = "tree-sitter-cpp";

    const grammar = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .pic = if (shared) true else null,
    });
    const lib: *std.Build.Step.Compile = b.addLibrary(.{
        .name = library_name,
        .linkage = if (shared) .dynamic else .static,
        .root_module = grammar,
    });

    grammar.addCSourceFiles(.{
        .files = &.{ "src/parser.c", "src/scanner.c" },
        .flags = &.{"-std=c11"},
    });

    if (reuse_alloc) {
        grammar.addCMacro("TREE_SITTER_REUSE_ALLOCATOR", "");
    }
    if (optimize == .Debug) {
        grammar.addCMacro("TREE_SITTER_DEBUG", "");
    }

    grammar.addIncludePath(b.path("src"));

    b.installArtifact(lib);
    b.installFile("src/node-types.json", "node-types.json");

    b.installDirectory(.{
        .source_dir = b.path("queries"),
        .install_dir = .prefix,
        .install_subdir = "queries",
        .include_extensions = &.{"scm"},
    });
}
