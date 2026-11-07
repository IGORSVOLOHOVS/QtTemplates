# qt-templates

Qt Creator add-ons for the parts of a C++ CMake project that are tedious to wire
up by hand: SWIG bindings for Python, Doxygen documentation, protobuf with gRPC,
and lcov coverage. Written for Linux in April 2025.

## What is here

- `scripts/` holds four Bash scripts, each run from a project's build folder:
  - `swig.sh` creates `swig/python/interface.i` and the two `CMakeLists.txt`
    files that build a `swig_python` module with `swig_add_library`.
  - `documentation.sh` writes a minimal `Doxyfile` with class diagrams, runs
    `doxygen` and opens the result in Google Chrome.
  - `protobuf.sh` writes `structs/structs.proto` with a sample `Person` message
    and a `Greeter` service, runs `protoc` with the gRPC C++ plugin, and drops a
    commented-out server example beside the generated code.
  - `coverage.sh` captures an lcov report, filters system and test paths out of
    it, renders it with `genhtml` and opens it in Google Chrome.
- `scripts/README.md` is the usage guide: the `add_subdirectory`, `interface.i`
  and compiler-flag edits each script expects in the target project.
- `qtexternal/` holds the four matching Qt Creator external-tool definitions, so
  the scripts appear under the `MeExternalCpp` menu.
- `snippets/patterns.xml` holds 23 C++ editor snippets: the 22 Gang of Four
  patterns, as declarations with Doxygen comments, and a `docs` block.
- `install.sh` copies the external tools and the snippets to where Qt Creator
  reads them.

## Use

On Linux, from the repository folder:

```bash
./install.sh
```

It rewrites the `<arguments>` path in each `qtexternal/*.xml` to this folder's
`scripts/`, in place, so the checkout shows modified files afterwards. The
committed XML files point at `/home/igors/Projects/QtTemplates/scripts/`.
Snippets go to `$HOME/Qt/Tools/QtCreator/share/qtcreator/snippets`, which exists
only for a Qt installed by the online installer. Restart Qt Creator afterwards.

The scripts need what they call: `swig`, `doxygen`, `protoc` with
`grpc_cpp_plugin`, `lcov` and `genhtml`. None of them is installed or checked
here. `swig.sh` and `protobuf.sh` write into `../../`, two folders above the
build folder, which is the project root only for Qt Creator's default
`build/<kit>` layout.

## Working on it

This repository ships no program. `.\recipe.ps1` is still its whole interface:
`.\recipe.ps1 test` runs pytest and ruff over `.claude`, and `.\recipe.ps1 info`
prints the metadata. The other verbs print `nothing to <verb>`. `CLAUDE.md`
holds the rules.

## License

MIT. See [LICENSE](LICENSE).

## Lab requirements

This repository complies with [revision 4.0.0](http://127.0.0.1:3000/igors-lab/software-requirements/src/tag/v4.0.0/BEST_REQUIREMENTS.md) of the lab requirements, except R-02 (#7), R-09 (#8), R-37 (#9), R-41 (#10), R-42 (#11).
