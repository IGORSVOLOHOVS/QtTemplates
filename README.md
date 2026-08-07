# QtTemplates

Qt Creator templates and shell scripts for the parts of a C++ project that are
tedious to wire up by hand: SWIG bindings, Doxygen documentation, protobuf, and
coverage.

## What is here

- `scripts/` - `swig.sh`, `documentation.sh`, `protobuf.sh`, `coverage.sh`,
  each adding one capability to an existing CMake project.
  **`scripts/README.md` is the usage guide** - it shows the exact
  `add_subdirectory` and `interface.i` edits each one expects.
- `qtexternal/` - the matching Qt Creator external-tool definitions
  (`swig.xml`, `documentation.xml`, `protobuf.xml`, `coverage.xml`), so the
  scripts appear in the IDE menu instead of being run by hand.
- `snippets/patterns.xml` - editor snippets.
- `install.sh` - puts the external tools where Qt Creator looks for them.

## Use

```bash
./install.sh
```

Then read `scripts/README.md` for the per-script setup. Nothing here builds on
its own; every piece is meant to be dropped into another project.
