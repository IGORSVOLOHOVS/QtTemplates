# qt-templates - Software Requirements Specification

Reverse-engineered from the code at commit `4892b0c` on 2026-11-18. Each
requirement states what the files do now, with the line it comes from. It is
not a statement of what they ought to do; gaps are in section 9.
Documentation hub: [docs/README.md](docs/README.md).

## 1. Purpose and scope

The repository provides Qt Creator add-ons for C++ CMake projects on Linux:
generators for SWIG Python bindings, Doxygen documentation, protobuf/gRPC code
and lcov coverage reports, the Qt Creator external-tool definitions that run
them, 23 C++ editor snippets, and an installer that copies the definitions and
snippets into Qt Creator's folders (`README.md:3-26`).

In scope:

- `install.sh`, `qtexternal/*.xml`, `scripts/*.sh`, `snippets/patterns.xml`
  (the product).
- `recipe.ps1`, `.claude/hooks/`, `.gitea/workflows/` (the repository's
  development tooling), described in 3.3.

Out of scope (nothing in the repository does it):

- Installing or checking SWIG, Doxygen, protoc, gRPC, lcov, Graphviz or Chrome
  (`README.md:42-43`; `protobuf.sh` only checks for two of them, FR-20).
- Building, configuring or running the target project; the user edits its
  `CMakeLists.txt` by hand (`scripts/README.md`).
- Windows or macOS as a host for the product scripts.
- Uninstalling the add-ons from Qt Creator: no script removes them.

## 2. Context

Actors:

| Actor | Role | Source |
|---|---|---|
| C++ developer in Qt Creator | Runs `install.sh`, starts the external tools, types snippet triggers | `README.md:28-46` |
| Qt Creator | Reads the external-tool XML and the snippets, runs the scripts with `bash` | `qtexternal/*.xml:7-10` |
| Repository maintainer, Claude Code | Work through `recipe.ps1`, git hooks and the Claude Code hooks | `CLAUDE.md`, `.claude/settings.json` |
| Gitea server and its `windows` runner, `lab-bot` | Run the CI workflows | `.gitea/workflows/*.yaml` |

External systems:

| System | Used by | How |
|---|---|---|
| `doxygen`, Graphviz `dot` | `documentation.sh` | `doxygen Doxyfile`; `HAVE_DOT = YES` (`scripts/documentation.sh:46,78`) |
| `protoc`, `grpc_cpp_plugin` | `protobuf.sh` | `protoc --cpp_out --grpc_out --plugin=protoc-gen-grpc` (`scripts/protobuf.sh:103-108`) |
| `lcov`, `genhtml` | `coverage.sh` | `scripts/coverage.sh:2-5` |
| `google-chrome` | `documentation.sh`, `coverage.sh` | opens `index.html` (`scripts/documentation.sh:81-86`, `scripts/coverage.sh:6`) |
| SWIG, Python 3 libraries, CMake | generated `swig/` CMake files | `find_package(SWIG)`, `find_package(PythonLibs 3)` (`scripts/swig.sh:37,50`) |
| Gitea REST API | CI workflows | `${{ github.server_url }}/api/v1` with secret `LAB_BOT_TOKEN` (`.gitea/workflows/propose.yaml:17,24`) |

Runtime environment:

- Product: Linux, Bash, GNU `sed -i` (`README.md:30`, `install.sh:10`);
  Qt Creator, whose XML files say version 15.0.1 (`qtexternal/*.xml:2`).
- Tooling: Windows PowerShell (`powershell.exe` in `.claude/settings.json`
  and `.claude/hooks/git/*`; `shell: powershell` and `runs-on: windows` in
  every workflow), git, Python with pytest and ruff.

## 3. Functional requirements

No requirement below has an automated test; "no test" is written once per
table row. Where a check was run by hand while writing this spec, it is named.

### 3.1 Installation and Qt Creator integration

| ID | Requirement | Source | Verification |
|---|---|---|---|
| FR-1 | The system shall create `$HOME/.config/QtProject/qtcreator/externaltools` when it does not exist. | `install.sh:3-5` | no test |
| FR-2 | The system shall rewrite the `<arguments>` element of every `qtexternal/*.xml`, in place, to `$(pwd)/scripts/<xml base name>.sh`. | `install.sh:9-12` | no test |
| FR-3 | The system shall copy everything in `qtexternal/` into the external-tools folder of FR-1. | `install.sh:16` | no test |
| FR-4 | The system shall copy everything in `snippets/` into `$HOME/Qt/Tools/QtCreator/share/qtcreator/snippets`, without creating that folder. | `install.sh:20` | no test |
| FR-5 | The system shall print a completion message and ask for a Qt Creator restart, regardless of the outcome of the earlier steps. | `install.sh:22-24` | no test |
| FR-6 | The system shall define four Qt Creator external tools (`coverage` "Test coverage", `documentation` "Documentation", `protobuf` "Structures", `swig` "Swig") in category `MeExternalCpp`, each running `bash <script>` in `%{ActiveProject:BuildConfig:Path}` with output and errors shown in the pane. | `qtexternal/*.xml:3-11` | no test; all four files parse as XML (checked 2026-11-18) |
| FR-7 | The system shall provide 23 C++ snippets: 22 design patterns with triggers `gof_singleton` ... `gof_visitor` (declarations with Doxygen comments, then an example implementation section with stub bodies, commented out only in `gof_singleton`) and one `docs` trigger with a Doxygen example for a Fibonacci function. | `snippets/patterns.xml:3-2551` | no test; 23 `<snippet>` elements parsed (checked 2026-11-18) |

### 3.2 Scripts

All four scripts are run with the build folder as the working directory
(FR-6); `swig.sh`, `documentation.sh` and `protobuf.sh` address the project
root as `../../`, `coverage.sh` works in the working directory only.

#### SWIG (`scripts/swig.sh`)

| ID | Requirement | Source | Verification |
|---|---|---|---|
| FR-8 | The system shall create `../../swig/python` when it does not exist. | `scripts/swig.sh:2-9` | no test |
| FR-9 | The system shall write `../../swig/python/interface.i` (module `my_module`, `#include`/`%include` of `my_class/my_class.hpp`, the SWIG `std_string`, `std_vector`, `std_map`, `std_pair`, `std_set` libraries) only when the file does not exist, and otherwise print that it exists. | `scripts/swig.sh:12-28` | no test |
| FR-10 | The system shall write `../../swig/CMakeLists.txt` (placeholder `LIBS_FOR_SWIG set_it`, `find_package` of Threads and SWIG, `include(${SWIG_USE_FILE})`, `add_subdirectory(python)`) only when it does not exist. | `scripts/swig.sh:31-44` | no test |
| FR-11 | The system shall write `../../swig/python/CMakeLists.txt` that builds a shared Python module `swig_python` from `interface.i` with `swig_add_library`, links `LIBS_FOR_SWIG`, threads and Python libraries, and adds the project root to its include path, only when it does not exist. | `scripts/swig.sh:46-69` | no test |

#### Documentation (`scripts/documentation.sh`)

| ID | Requirement | Source | Verification |
|---|---|---|---|
| FR-12 | The system shall stop at the first failing command. | `scripts/documentation.sh:4` | no test |
| FR-13 | The system shall delete `docs/html` in the working directory before generating. | `scripts/documentation.sh:7` | no test |
| FR-14 | The system shall create `../../docs` when it does not exist. | `scripts/documentation.sh:10-12` | no test |
| FR-15 | When `../../docs/Doxyfile` exists, the system shall copy it to `./Doxyfile`. | `scripts/documentation.sh:16-19` | no test |
| FR-16 | Otherwise the system shall write a `./Doxyfile` (project `MyProject`, input `../../` recursive, output `docs/html`, `EXTRACT_ALL`, tree view, dot class diagrams in UML style, MathJax) and copy it to `../../docs/Doxyfile`. | `scripts/documentation.sh:21-62` | no test |
| FR-17 | The system shall create `../../README.md` with a two-line placeholder when it does not exist. | `scripts/documentation.sh:66-74` | no test |
| FR-18 | The system shall run `doxygen Doxyfile`. | `scripts/documentation.sh:78` | no test |
| FR-19 | The system shall open `docs/html/index.html` with `google-chrome` when that command is on `PATH`, and otherwise print the path to open by hand. | `scripts/documentation.sh:81-86` | no test |

#### Protobuf and gRPC (`scripts/protobuf.sh`)

| ID | Requirement | Source | Verification |
|---|---|---|---|
| FR-20 | The system shall exit with status 1 and print install hints for Debian/Ubuntu, Fedora and Homebrew when `protoc` or `grpc_cpp_plugin` is not on `PATH`. | `scripts/protobuf.sh:12-31` | no test |
| FR-21 | The system shall stop at the first failing command. | `scripts/protobuf.sh:4` | no test |
| FR-22 | The system shall create `../../structs`. | `scripts/protobuf.sh:7,38` | no test |
| FR-23 | The system shall write `../../structs/structs.proto` (proto3, package `tutorial`, messages `Person`, `HelloRequest`, `HelloReply`, service `Greeter`) only when it does not exist. | `scripts/protobuf.sh:41-96` | no test |
| FR-24 | The system shall generate C++ protobuf and gRPC sources from `structs.proto` into `../../structs` with `protoc` and the gRPC plugin found on `PATH`. | `scripts/protobuf.sh:32,103-108` | no test |
| FR-25 | The system shall list the generated `*.pb.*` files and print next steps with an example CMake integration. | `scripts/protobuf.sh:111-126` | no test |
| FR-26 | The system shall write `structs_server_example.cc` and `structs_client_example.cc` into `../../structs` only when each is absent; both files are entirely inside a `/* ... */` comment. | `scripts/protobuf.sh:131-201,205-317` | no test |

#### Coverage (`scripts/coverage.sh`)

| ID | Requirement | Source | Verification |
|---|---|---|---|
| FR-27 | The system shall delete `coverage_report` in the working directory. | `scripts/coverage.sh:1` | no test |
| FR-28 | The system shall capture coverage data from the working directory into `coverage.info` with `lcov --capture`. | `scripts/coverage.sh:2` | no test |
| FR-29 | The system shall remove from `coverage.info` the paths matching `/usr/*`, `*/test/*`, `*/third_party/*`, `*/build/*`, `*/lib/*`, `*/include/*`, `*/src/*`, `*/tests/*`. | `scripts/coverage.sh:4` | no test |
| FR-30 | The system shall render `coverage.info` to HTML in `coverage_report` with `genhtml` and open `coverage_report/index.html` with `google-chrome`. | `scripts/coverage.sh:5-6` | no test |

### 3.3 Repository tooling

| ID | Requirement | Source | Verification |
|---|---|---|---|
| FR-31 | `recipe.ps1` shall accept exactly one of the verbs `build`, `install`, `uninstall`, `clean`, `run`, `publish`, `info`, `test`. | `recipe.ps1:1-7` | no test |
| FR-32 | `recipe.ps1` shall load `NAME=value` lines from `.claude/.env` into the environment for every variable not already set. | `recipe.ps1:30-38` | no test |
| FR-33 | `recipe.ps1 test` shall set `core.hooksPath` to `.claude/hooks/git`, run pytest over `.claude` (exit 5, no tests, counts as a pass), `ruff check` and `ruff format` in place over `.claude`, and exit 1 on the first failure. | `recipe.ps1:41-55` | no test; `pytest --collect-only` collected nothing, exit 5 (checked 2026-11-18) |
| FR-34 | `recipe.ps1 info` shall print name, code, version and summary. | `recipe.ps1:56-62` | no test; run 2026-11-18, exit 0 |
| FR-35 | `recipe.ps1 clean` shall delete every `__pycache__`, `.pytest_cache` and `.ruff_cache` folder under the repository. | `recipe.ps1:63-68` | no test |
| FR-36 | The `commit-msg` hook shall refuse a message that starts with a UTF-8 BOM, a subject that does not match `<type>(<scope>): <text>` with the types and scopes listed in `recipe.ps1`, and a message without a `Signed-off-by` trailer; merge commits made by git pass. | `.claude/hooks/git/commit-msg.ps1:24-56`, `recipe.ps1:19-20` | no test |
| FR-37 | The `pre-push` hook shall refuse a branch name outside `<code>-<issue>/<type>/<slug>`, deleting `release`, and a push to `release` whose commits lack the override phrase and a `Why:` line; it hands the push to Git LFS first when `git-lfs` is installed. | `.claude/hooks/git/pre-push`, `.claude/hooks/git/pre-push.ps1:1-96` | no test |
| FR-38 | The Claude Code `PreToolUse` gate shall deny a Bash/PowerShell call it cannot parse, a recursive delete outside `$env:TEMP`, a force-push or mirror push, and `reset --hard` (except to `origin/<branch>`), `clean -f`, `commit --amend`, `rebase` or `filter-branch` on `test` or `release`. | `.claude/hooks/gate.ps1:34-36,137-177`, `.claude/settings.json:10-12` | no test |
| FR-39 | The Claude Code hooks shall append one JSON line per event to `.claude/logs/ai.jsonl` and move the file aside as `ai.jsonl.<timestamp>.bak` at session start when it exceeds 10 MB; `SessionStart` also sets `core.hooksPath` and reports branch and issue number. | `.claude/hooks/log.ps1:1-26`, `.claude/hooks/session-start-stop.ps1:25-49` | no test |
| FR-40 | The `propose` workflow shall, on a pull request into `test`, check the branch name and the wording of every commit, run `recipe.ps1 test` followed by `git diff --exit-code`, and request review from `$Reviewers` when the pull request is opened or reopened. | `.gitea/workflows/propose.yaml:1-193` | no test |
| FR-41 | The `test` workflow shall, on push to `test`, daily at 03:00 and on manual dispatch, check runner disk space and that `python`, `ruff`, `pytest`, `mypy` answer, then run `recipe.ps1 test`, `git diff --exit-code` and `recipe.ps1 build`. | `.gitea/workflows/test.yaml:1-60` | no test |
| FR-42 | The `release-gate` workflow shall, on a pull request into `release`, refuse any head branch other than `test`, run the tests and the build, and run a manual gate over `tests/manual/tests.json` that passes when the list is absent or empty. | `.gitea/workflows/release-gate.yaml:1-150` | no test |
| FR-43 | The `release` workflow shall, on push to `release`, read `$Version` from `recipe.ps1`, skip publishing when tag `v<version>` exists, and otherwise create the release with notes, a manual-test report and an SBOM, close the shipped issues and bring `test` level with `release`. | `.gitea/workflows/release.yaml:1-431` | no test |
| FR-44 | The `sweep` workflow shall, every Monday at 04:00, delete work branches already merged into `test`, comment on open pull requests idle for 30 days and close those idle for 60. | `.gitea/workflows/sweep.yaml:1-80` | no test |

### 3.4 Declared but not implemented

- `recipe.ps1` verbs `build`, `install`, `uninstall`, `run`, `publish` are
  accepted and only print `nothing to <verb>` (`recipe.ps1:3,69-72`).
  `recipe.ps1 install` does not run `install.sh`.
- `$RunArgs` is declared and used nowhere (`recipe.ps1:5-6`).
- The CI steps for an app or library - installer build and install/uninstall
  proof, wiki regeneration through `tools/wiki.py` - are skipped, because
  `recipe.ps1` sets no `$App` and an empty `$Provides`
  (`recipe.ps1:16-17`, `.gitea/workflows/test.yaml:46-110`); `tools/wiki.py`
  is not in the repository.
- `.claude/pytest.ini:2` exists "for the scripts this repository carries" and
  says "None yet".
- Commit `3cf4ff0` is titled "pin ruff and pytest"; only ruff is pinned
  (`.claude/ruff.toml:2`), `.claude/pytest.ini` names no version.
- The gRPC server and client examples are written commented out
  (FR-26); `scripts/README.md:40-63` gives `g++` commands to build them.
- `protobuf.sh` prints `protobuf_generate_grpc_cpp(...)` as CMake integration
  (`scripts/protobuf.sh:124`); the repository defines no such function.
- Manual tests: `release-gate.yaml` reads `tests/manual/tests.json`, which
  does not exist.

## 4. Interfaces

### 4.1 Command line

| Command | Run from | Arguments | Exit status |
|---|---|---|---|
| `./install.sh` | repository root (`README.md:30-34`) | none | status of the last `echo` (no `set -e`) |
| `bash scripts/swig.sh` | build folder | none | status of the last command (no `set -e`) |
| `bash scripts/documentation.sh` | build folder | none | non-zero at the first failure (`set -e`) |
| `bash scripts/protobuf.sh` | build folder | none | 1 if `protoc` or `grpc_cpp_plugin` is missing; non-zero at the first failure |
| `bash scripts/coverage.sh` | build folder | none | status of `google-chrome` (last command, no `set -e`) |
| `.\recipe.ps1 <verb>` | repository root | verb (FR-31) | `test`: 0 or 1; `info`, `clean`, others: 0 |

### 4.2 Qt Creator external-tool file (`qtexternal/*.xml`)

| Element / attribute | Value in this repository |
|---|---|
| `externaltool@id` | `coverage`, `documentation`, `protobuf`, `swig` |
| `displayname` | `Test coverage`, `Documentation`, `Structures`, `Swig` |
| `category` | `MeExternalCpp` |
| `executable@output`, `@error` | `showinpane` |
| `executable@modifiesdocument` | `no` |
| `path` | `bash` |
| `arguments` | absolute path of the matching script (rewritten by FR-2) |
| `workingdirectory` | `%{ActiveProject:BuildConfig:Path}` |

### 4.3 Snippet file (`snippets/patterns.xml`)

Root `<snippets>`, one `<snippet>` per entry with attributes `group="C++"`,
`trigger`, `id`, `complement` (description), body in `CDATA`. Inside the body,
`$Name$` marks an editable name (for example `$Singleton$`,
`snippets/patterns.xml:12`) and `$$` the cursor position
(`snippets/patterns.xml:2549`).

Triggers: `gof_singleton`, `gof_factory_method`, `gof_abstract_factory`,
`gof_builder`, `gof_prototype`, `gof_adapter`, `gof_bridge`,
`gof_composite`, `gof_decorator`, `gof_facade`, `gof_flyweight`,
`gof_proxy`, `gof_chain_of_responsibility`, `gof_command`,
`gof_interpreter`, `gof_iterator`, `gof_mediator`, `gof_memento`,
`gof_state`, `gof_strategy`, `gof_template_method`, `gof_visitor`, `docs`.

### 4.4 gRPC service written by `protobuf.sh`

| RPC | Request | Response | Source |
|---|---|---|---|
| `Greeter.SayHello` | `HelloRequest` | `HelloReply` | `scripts/protobuf.sh:85` |
| `Greeter.GreetPerson` | `Person` | `HelloReply` | `scripts/protobuf.sh:87` |

The commented-out example server binds `0.0.0.0:50051` with insecure
credentials; the client defaults to `localhost:50051` and takes another
target as its first argument (`scripts/protobuf.sh:174-179,291-296`).

### 4.5 CI triggers

| Workflow | Trigger | Source |
|---|---|---|
| `propose` | pull request into `test` (opened, reopened, synchronize) | `.gitea/workflows/propose.yaml:2-5` |
| `test` | push to `test`; cron `0 3 * * *`; manual | `.gitea/workflows/test.yaml:2-7` |
| `release-gate` | pull request into `release` | `.gitea/workflows/release-gate.yaml:2-5` |
| `release` | push to `release` | `.gitea/workflows/release.yaml:2-4` |
| `sweep` | cron `0 4 * * 1` | `.gitea/workflows/sweep.yaml:2-4` |

## 5. Data

There is no database. Everything is files.

Files written into the target project or its build folder:

| File | Writer | Overwritten on re-run |
|---|---|---|
| `../../swig/CMakeLists.txt`, `../../swig/python/{interface.i,CMakeLists.txt}` | `swig.sh` | no |
| `./Doxyfile` | `documentation.sh` | yes |
| `../../docs/Doxyfile`, `../../README.md` | `documentation.sh` | no |
| `./docs/html/` | `doxygen` via `documentation.sh` | deleted first (FR-13) |
| `../../structs/structs.proto`, `structs_*_example.cc` | `protobuf.sh` | no |
| `../../structs/structs.pb.{h,cc}`, `structs.grpc.pb.{h,cc}` | `protoc` via `protobuf.sh` | yes (inference: regenerated by every `protoc` run) |
| `./coverage.info` | `lcov` via `coverage.sh` | yes |
| `./coverage_report/` | `genhtml` via `coverage.sh` | deleted first (FR-27) |

Protobuf entities (`scripts/protobuf.sh:53-80`):

| Message | Fields |
|---|---|
| `Person` | `name` string 1, `id` int32 2, `email` string 3, `phones` repeated `PhoneNumber` 4 |
| `Person.PhoneNumber` | `number` string 1, `type` `PhoneType` 2 |
| `Person.PhoneType` (enum) | `MOBILE` 0, `HOME` 1, `WORK` 2 |
| `HelloRequest` | `name` string 1 |
| `HelloReply` | `message` string 1 |

Tooling data: `.claude/logs/ai.jsonl`, one JSON object per line with `ts`,
`event`, and when present `session`, `tool`, `decision`, `detail` (first 200
characters of the prompt, message, reason, source or file path)
(`.claude/hooks/log.ps1:4-13`, `.claude/hooks/gate.ps1:6-11`). The folder is
gitignored (`.gitignore:17`).

## 6. Non-functional requirements

| ID | Requirement | Source |
|---|---|---|
| NFR-1 | The product scripts run on Linux under Bash; `install.sh` needs GNU `sed -i`. | `README.md:30`, `qtexternal/*.xml:8`, `install.sh:10` |
| NFR-2 | The tooling runs in Windows PowerShell; CI uses a `windows` runner. | `.claude/settings.json:8-18`, `.gitea/workflows/*.yaml` (`runs-on: windows`) |
| NFR-3 | The generators do not overwrite a file that already exists in the project (except `./Doxyfile`, `docs/html`, the `protoc` output in `structs/`, `coverage.info`, `coverage_report`, see section 5). | `scripts/swig.sh:12,31,46`, `scripts/protobuf.sh:41,131,205`, `scripts/documentation.sh:16,66` |
| NFR-4 | `documentation.sh` and `protobuf.sh` stop at the first error; `install.sh`, `swig.sh` and `coverage.sh` do not. | `scripts/documentation.sh:4`, `scripts/protobuf.sh:4` |
| NFR-5 | CI job time limits: 60 min (`propose`, `test`, `release`, `release-gate` checks), 170 min (manual gate), 15 min (`sweep`); the manual gate waits 150 min for a verdict. | `.gitea/workflows/*.yaml` (`timeout-minutes`), `release-gate.yaml:101,279` |
| NFR-6 | Hook log writes retry 20 times with a wait of 10, 20, ... ms when the file is in use; the log rotates above 10 MB. | `.claude/hooks/log.ps1:20-24`, `.claude/hooks/session-start-stop.ps1:27-30` |
| NFR-7 | No key is committed: `.claude/.env` and `.claude/logs/` are gitignored; CI reads its token from the secret `LAB_BOT_TOKEN`; `test` and `release` check out without persisted credentials. | `.gitignore:17,20-24`, `CLAUDE.md` rule 4, `.gitea/workflows/test.yaml:30`, `release.yaml:35` |
| NFR-8 | Text files are checked out with LF, `*.ps1` with CRLF and UTF-8 working-tree encoding (the index holds LF for all of them, `git ls-files --eol`); PDF, PNG, JPG, ZIP and 7z go to Git LFS. | `.gitattributes:1-13` |
| NFR-9 | Runs that share the installer or release concurrency group wait for each other rather than cancel. | `.gitea/workflows/test.yaml:18-20`, `release-gate.yaml:20-22`, `release.yaml:15-17` |
| NFR-10 | ruff must be exactly 0.16.1. | `.claude/ruff.toml:2` |

## 7. Constraints and dependencies

There is no lock file and no package manifest. Versions are pinned only
where the table says so.

| Dependency | Used by | Version |
|---|---|---|
| Bash, GNU sed, coreutils | product scripts | not stated |
| Qt Creator | XML files, snippets | XML written by 15.0.1 (`qtexternal/*.xml:2`) |
| SWIG, CMake, Python 3 libraries | generated `swig/` files | `PythonLibs 3` (`scripts/swig.sh:50`); others not stated |
| doxygen, Graphviz | `documentation.sh` | not stated |
| protoc, grpc_cpp_plugin | `protobuf.sh` | proto3 syntax (`scripts/protobuf.sh:45`) |
| lcov, genhtml | `coverage.sh` | not stated |
| google-chrome | `documentation.sh`, `coverage.sh` | not stated |
| PowerShell, git, Git LFS | tooling | not stated |
| Python, pytest | `recipe.ps1 test` | not stated |
| ruff | `recipe.ps1 test` | `==0.16.1` (`.claude/ruff.toml:2`) |
| `actions/checkout` | all workflows | `v4` |

Licence: MIT (`LICENSE`).

## 8. Acceptance

Automated, as the repository defines it: `.\recipe.ps1 test` exits 0 and
`git diff --exit-code` is clean afterwards (`.gitea/workflows/test.yaml:54-58`).
This covers FR-33 only; no product requirement is exercised by it.

Checks for the product, by hand (none is scripted in the repository):

1. `bash -n install.sh scripts/*.sh` reports no syntax error (passed on
   2026-11-18).
2. All five XML files parse, and `snippets/patterns.xml` has 23 `<snippet>`
   elements (passed on 2026-11-18).
3. On a Linux account with Qt Creator: run `./install.sh` from the
   repository folder; check FR-1 to FR-4 by listing both target folders and
   reading `<arguments>` in the copied XML; restart Qt Creator and find the
   four tools under `MeExternalCpp` (FR-6); type `gof_singleton` in a C++
   file (FR-7).
4. In a CMake project built in `build/<kit>`: start each tool and compare the
   files with section 5; start it again and confirm that files marked "no"
   keep their content (NFR-3).
5. With `protoc` removed from `PATH`, `protobuf.sh` exits 1 and prints the
   install hints (FR-20).
6. Build with `--coverage`, run the tests, run `Test coverage`, and open
   `coverage_report/index.html` (FR-27 to FR-30).

## 9. Open questions

- Who uses these add-ons besides the author, and whether they are still in
  use: the product files are unchanged since 2025-04-17.
- Which Qt Creator, CMake, SWIG, Doxygen, protobuf/gRPC and lcov versions are
  targeted. Nothing pins them; the generated SWIG files call
  `find_package(PythonLibs)` and `find_package(PythonInterp)` and carry no
  `cmake_minimum_required`.
- Whether Qt Creator loads an additional `patterns.xml` from
  `share/qtcreator/snippets` of a Qt installation. `README.md:39-40` says the
  snippets go there; nothing in the repository confirms that Qt Creator reads
  them from that place.
- Whether `${PYTHONLIBS_VERSION_STRING}` at `scripts/swig.sh:51` was meant to
  be escaped like the other `${...}` in the same heredoc.
- Whether removing `*/src/*`, `*/include/*` and `*/lib/*` from the coverage
  report (`scripts/coverage.sh:4`) is intended; it drops sources kept in those
  folders.
- Why `coverage.sh` waits 2 seconds between capture and filter
  (`scripts/coverage.sh:3`).
- Whether the gRPC examples are commented out on purpose.
- Where `protobuf_generate_grpc_cpp` (`scripts/protobuf.sh:124`) is expected
  to come from.
- Whether a Gitea runner serves this repository; `CLAUDE.md` allows for the
  case where none does. The `origin` remote is GitHub, which has no workflow
  in `.github/`.
- What the lab requirements R-37, R-41 and R-42 and their exception issues
  #9-#11 say; the link in `README.md:61` points to a loopback address.
  Answered in `CLAUDE.md` for two of them: R-02 puts keys in a committed
  `.claude/.env`, reversed here by rule 4 (the file is gitignored); R-09 is
  relaxed because the history from before the lab was imported as it stood,
  not reworded or signed off ("Where this repository is deliberately
  relaxed").
