# Home Container and a Container per Issue Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** codeo's dev container comes in two kinds — a home container (clone on `main`, no lock) where `/codeo:init` runs, and one container per issue (clone of the pushed branch) that takes the issue's lock when it starts — with the name, window title and clone folder all derived from the lock.

**Architecture:** Three small scripts in `.devcontainer/scripts/` (`container-name.sh`, `folder-check.sh`, `codeo-root.sh`) and one overlay (`.codeo/overlays/init.md`, `## host-workflow`). `container-name.sh` is the single source of the window title and the Docker name; `window-title.sh` calls it. `devcontainer-start.sh` gains two steps: take the lock with the installed plugin's `lock.sh take container`, and report a clone folder that disagrees with the lock. `devcontainer.json` names the container from the clone folder alone. No plugin change: 1.0.3's `lock.sh` already has the `container` host.

**Tech Stack:** bash, jq, git; the shell suite (`tests/*.test.sh`, run by `tests/run.sh`).

**Spec:** GitHub issue #55 as restated in `.codeo/55/init.md` → `## Outcome`; decisions in `.codeo/55/plan.md` Q1–Q4; the reference is `/workspaces/the reference project` (`.devcontainer/scripts/{container-name,folder-check}.sh`, `.codeo/codeo-root.sh`, `.codeo/overlays/init.md`).

## Options considered

| Decision | Chosen | Rejected | Why |
|---|---|---|---|
| Folders Docker rejects (Q1) | valid by construction (`codeo-home`, `codeo-<N>`) and the reason in the README and CHANGELOG | a script fallback name; keeping `-${devcontainerId}` | `devcontainer.json` cannot sanitise a variable and no host script runs for a volume clone; a suffix does not make an invalid folder valid |
| Name logic (Q2) | `container-name.sh` + `folder-check.sh` + `codeo-root.sh`, codename read with `jq` from `.codeo/config.json` | porting the reference project's `.codeo/project.sh` | codeo has no secrets store; `window-title.sh` already reads the codename this way |
| Where the how-to lives (Q3) | `.devcontainer/README.md`, linked from `README.md` | a `README.md` section; nothing | the rebuild and folder-name notes belong beside the container definition |
| Overlays (Q4) | `init` only | `init` + `close` | the criteria ask for `init`; the `close` overlay is its own issue |
| Taking the lock | call the installed plugin's `lock.sh take container` | writing `.codeo/active` in the start script | one writer for the lock format |

## Global Constraints

- Files that change: `.devcontainer/devcontainer.json`, `.devcontainer/scripts/{window-title,devcontainer-start}.sh`, `.codeo/config.json`, `tests/devcontainer.test.sh`, `README.md`, `CHANGELOG.md`. New: `.devcontainer/scripts/{container-name,folder-check,codeo-root}.sh`, `.devcontainer/README.md`, `.codeo/overlays/init.md`, `tests/{container-name,folder-check,codeo-root,init-overlay}.test.sh`. Nothing under `scripts/`, `lib/`, `hooks/` or `skills/`.
- Names: lock `issue: 55` → title `codeo [#55]`, Docker name `codeo-55`, folder `codeo-55`; no lock → `codeo [home]`, `codeo-home`, `codeo-home`. The codename is `.codeo/config.json`'s `codename`, else the clone directory's name (what `window-title.sh` does today).
- `runArgs` is exactly `["--name=${containerWorkspaceFolderBasename}","--memory=4g","--cpus=2"]`. This replaces #50's `${localWorkspaceFolderBasename}-${devcontainerId}`; a rebuild is needed to get the new name, and a leftover container of the same name makes the start fail with "name already in use" (`docker rm`).
- The lock is taken by the installed plugin's `lock.sh take container`, never written by hand. The start script prints its `lock: took the lock for #<N> on <branch>` line **verbatim** (acceptance criterion 4 quotes it); its `lock: TODO — …` lines become TODOs. On the base branch (`.codeo/config.json`'s `baseBranch`, else `main`) the script does not call it at all.
- The suite is `shell` (`bash tests/run.sh`, `build` is `true`, no `filter`), so a task's proof is `bash tests/run.sh <pattern>` for its test file and the whole suite at the end. `.codeo/overlays/**` is added to the suite's `paths` (Task 5) so an overlay change triggers it.
- Invariants document: none. Wiki module: none. Shared environment: none, so no task carries `Needs lease:`.
- Documentation moved: `.devcontainer/README.md` (new), `README.md` (one link line), `CHANGELOG.md` (Task 7). `docs/extension-points.md` already documents `init/host-workflow`; it does not change.
- Docker's container-name rule is `[a-zA-Z0-9][a-zA-Z0-9_.-]+`. Docker refuses a folder outside it before any script runs, so acceptance criterion 7 is met by the README and CHANGELOG stating the rule and the fix (re-clone with a valid folder), not by a container that starts (Q1).
- Acceptance criteria 1–3 and 8 are proved by hand on the host (Task 8): this container has no `docker` and `init` is not runnable under the test suite.

## Review Focus

- A `.codeo/active` with no parsable `issue:` line gives the home name, not an empty one (Task 1 test).
- An issue container that already holds the lock is re-run: no second `lock.sh` call, no lock line (Task 4 test).
- Detached HEAD in the start script: one TODO, no `lock.sh` call (Task 4 test).
- `lock.sh` crashing (non-zero exit) is a TODO and the script still exits 0 (Task 4 test).
- A folder check that cannot name the container (not a git clone) is a TODO naming the cause, never a stray error followed by `ready` (Task 4 test).

---

## File Structure

| File | Responsibility |
|---|---|
| `.devcontainer/scripts/container-name.sh` (new) | `[--docker] [dir]` → title or Docker name from the lock |
| `.devcontainer/scripts/folder-check.sh` (new) | `<folder> [dir]` → nothing, or one `todo:` line |
| `.devcontainer/scripts/codeo-root.sh` (new) | prints the installed `codeo@codeo` plugin root |
| `.devcontainer/scripts/window-title.sh` | title now from `container-name.sh` |
| `.devcontainer/scripts/devcontainer-start.sh` | lock step and folder check |
| `.devcontainer/devcontainer.json` | the `--name` |
| `.codeo/overlays/init.md` (new) | `init` runs in the home container |
| `.codeo/config.json` | suite `paths` gain `.codeo/overlays/**` |
| `.devcontainer/README.md` (new), `README.md`, `CHANGELOG.md` | documentation |
| `tests/container-name.test.sh`, `folder-check.test.sh`, `codeo-root.test.sh`, `init-overlay.test.sh` (new); `tests/devcontainer.test.sh` | proofs |

## Tasks

### Task 1: `container-name.sh`, and `window-title.sh` uses it

**Files:**
- Create: `.devcontainer/scripts/container-name.sh`, `tests/container-name.test.sh`
- Modify: `.devcontainer/scripts/window-title.sh`, `tests/devcontainer.test.sh` (`wt_setup`, `st_setup`, `ds_setup`: copy `container-name.sh` beside `window-title.sh`)

**Interfaces:**
- Produces: `container-name.sh [--docker|--codename] [dir]` — stdout one line (`--codename` prints the codename alone); `dir` anywhere inside the clone (default `.`). Exit 0; exit 1 with one `container-name: …` line on stderr when `dir` is not in a git repository. Used by Tasks 2 and 4.

- [ ] **Step 1: Write `tests/container-name.test.sh`** in the style of `tests/devcontainer.test.sh` (a `cases=(…)` array, `fail`, "all cases passed"), each case in a scratch git repo with `.codeo/config.json` `{"codename":"codeo"}` and the real script copied in. Cases and assertions:
  - `home_without_a_lock`: no `.codeo/active` → `codeo [home]`; `--docker` → `codeo-home`.
  - `lock_names_the_issue`: lock `issue:   55` → `codeo [#55]`, `--docker` → `codeo-55`.
  - `lock_tolerates_hash_and_tabs`: `issue:\t#7` → `codeo [#7]`.
  - `first_issue_line_wins`: two `issue:` lines (`3`, `9`) → `codeo [#3]`.
  - `unparsable_lock_is_home`: a lock with `issue: abc` or no `issue:` line → `codeo [home]` (Review Focus 1).
  - `codename_falls_back_to_the_directory`: no config → the clone directory's name in both forms.
  - `works_from_a_subdirectory`: `dir` = `<clone>/sub` gives the same answer.
  - `codename_flag_prints_the_codename`: `--codename` → `codeo` (config), the directory name with no config.
  - `outside_a_repository_fails`: `dir` = a plain temp directory → exit 1, stderr one line starting `container-name:`.
- [ ] **Step 2: Run it to see it fail.** `bash tests/run.sh container-name` → `FAIL` lines (script absent).
- [ ] **Step 3: Implement `container-name.sh`.** Root is `git -C "$dir" rev-parse --show-toplevel`; the lock is `$root/.codeo/active`, parsed as `window-title.sh` parses it today (first `issue:` line, digits after optional spaces, tabs or `#`); the codename is `jq -r '.codename // empty'` of `.codeo/config.json`, else `basename "$root"`, as today. `set -euo pipefail`, header comment in the house style.
- [ ] **Step 4: Make `window-title.sh` call it.** Replace its own codename/lock/title derivation with `title=$(bash "$(dirname "${BASH_SOURCE[0]}")/container-name.sh" "$root")`; a failure is `die "could not name the container: <its message>"`. `--print`, the exclude handling and every other behaviour stay.
- [ ] **Step 5: Update the three scratch setups** in `tests/devcontainer.test.sh` to copy `container-name.sh` (line ~383 `ds_setup`, ~1043 `wt_setup`, ~1286 `st_setup`).
- [ ] **Step 6: Run** `bash tests/run.sh container-name` and `bash tests/run.sh devcontainer` → both exit 0, no `FAIL`. Commit `.devcontainer/scripts/container-name.sh`, `window-title.sh`, both test files: `feat: container-name.sh derives the title and the Docker name from the lock (#55)`.

**Proof of done:** `bash tests/run.sh container-name` and `bash tests/run.sh devcontainer` exit 0 with no `FAIL`; `shellcheck .devcontainer/scripts/container-name.sh .devcontainer/scripts/window-title.sh tests/container-name.test.sh` is clean.

### Task 2: `folder-check.sh`

**Files:**
- Create: `.devcontainer/scripts/folder-check.sh`, `tests/folder-check.test.sh`

**Interfaces:**
- Consumes: Task 1's `container-name.sh --docker [dir]` (want = its output) and `--codename [dir]`.
- Produces: `folder-check.sh <folder> [dir]` — stdout nothing, or exactly one line `todo: …` naming the correct folder; exit 0 either way; exit 1 with one `folder-check: …` stderr line when `container-name.sh` fails.

- [ ] **Step 1: Write `tests/folder-check.test.sh`** (same style, scratch repos with Task 1's script and the real `folder-check.sh`). Cases:
  - `home_folder_on_main_is_silent`: branch `main`, no lock, folder `codeo-home` → no output.
  - `wrong_folder_on_main`: folder `scratch` → one line, starts `todo:`, contains `'codeo-home'`.
  - `locked_right_folder_is_silent`: lock `issue: 55`, folder `codeo-55` → no output.
  - `locked_wrong_folder_names_the_right_one`: lock `issue: 55`, folder `codeo-home` → one `todo:` line containing `'codeo-55'`.
  - `issue_branch_without_lock_leaves_an_issue_folder_alone`: branch `feat/x`, no lock, folder `codeo-12` → no output; folder `scratch` → a `todo:` line.
  - `not_a_clone_fails`: `dir` outside a repository → exit 1, stderr `folder-check:`.
- [ ] **Step 2: Run to see it fail.** `bash tests/run.sh folder-check` → `FAIL` lines.
- [ ] **Step 3: Implement `folder-check.sh`**: `want=$(container-name.sh --docker "$dir")`; locked when `want != <codename>-home`; the three branches above; each line ends with `(.devcontainer/README.md)`. The codename comes from `container-name.sh --codename`, so there is one copy of that logic.
- [ ] **Step 4: Run** `bash tests/run.sh folder-check` → exit 0. Commit: `feat: folder-check.sh reports a clone folder that disagrees with the lock (#55)`.

**Proof of done:** `bash tests/run.sh folder-check` and `bash tests/run.sh container-name` exit 0, no `FAIL`; `shellcheck` clean on both scripts and both tests.

### Task 3: `codeo-root.sh`

**Files:**
- Create: `.devcontainer/scripts/codeo-root.sh`, `tests/codeo-root.test.sh`

**Interfaces:**
- Produces: `codeo-root.sh` — stdout the plugin root and exit 0, or exit 1 with one `codeo-root: …` stderr line. `$CODEO_ROOT` wins when set and must hold `scripts/lock.sh` (otherwise exit 1, no fallthrough); else `.plugins["codeo@codeo"][0].installPath` from `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/installed_plugins.json`, which must hold `scripts/lock.sh`. No path is guessed.

- [ ] **Step 1: Write `tests/codeo-root.test.sh`.** Cases: `override_wins`; `bad_override_fails_without_falling_through` (valid registry present, `CODEO_ROOT` pointing at an empty dir → exit 1); `registry_install_path`; `registry_path_without_lock_sh_fails`; `no_registry_fails`; each with `HOME` or `CLAUDE_CONFIG_DIR` pointed at a scratch directory.
- [ ] **Step 2: Run to see it fail.** `bash tests/run.sh codeo-root` → `FAIL`.
- [ ] **Step 3: Implement `codeo-root.sh`** per the contract above (the reference project's `.codeo/codeo-root.sh` with the probe changed from `scripts/scope.sh` to `scripts/lock.sh`).
- [ ] **Step 4: Run** `bash tests/run.sh codeo-root` → exit 0. Commit: `feat: codeo-root.sh finds the installed plugin (#55)`.

**Proof of done:** `bash tests/run.sh codeo-root` exits 0 with no `FAIL`; `shellcheck` clean on both files.

### Task 4: The start script takes the lock and checks the folder

**Files:**
- Modify: `.devcontainer/scripts/devcontainer-start.sh` (header comment; a lock step after step 3 `plugins.sh` and before 3b `window-title.sh`; a folder-check step after it), `tests/devcontainer.test.sh`

**Interfaces:**
- Consumes: Tasks 1–3 (`codeo-root.sh`, `folder-check.sh`, `container-name.sh` via `window-title.sh`); the plugin's `lock.sh take container`.
- Produces: output lines `lock: …` verbatim from `lock.sh`; TODOs for each `lock: TODO — …` line, for a `lock.sh` exit ≠ 0 (`codeo's lock.sh failed (exit <rc>): …`), for no installed codeo, for a detached HEAD, and for a `todo:` line or a failure of `folder-check.sh`; `note:` lines from `folder-check.sh` are not produced. Still always exit 0.

- [ ] **Step 1: Write the failing cases** in `tests/devcontainer.test.sh` using `ds_setup` with a stub plugin root (`CODEO_ROOT` pointing at a scratch directory whose `scripts/lock.sh` is a stub that records its arguments and, when run on a non-base branch, writes `.codeo/active` and prints `lock: took the lock for #55 on <branch>`), run on branch `feat/x`:
  - `start_takes_the_lock_on_an_issue_branch`: stub called once with `take container`; stdout contains `lock: took the lock for #55 on feat/x`; `.codeo/active` names issue 55.
  - `start_takes_no_lock_on_the_base_branch`: on `main`, the stub is never called and no `.codeo/active`.
  - `start_rerun_with_a_lock_does_not_take_another`: existing non-empty `.codeo/active` → the stub is not called (Review Focus 2).
  - `start_detached_head_is_a_todo`: detached HEAD → one TODO mentioning the detached HEAD, stub not called (Review Focus 3).
  - `start_lock_todo_lines_become_todos`: stub prints `lock: TODO — no single init.md names branch feat/x (found 0)` → that text is a TODO, script exits 0.
  - `start_lock_crash_is_a_todo`: stub exits 3 → a TODO containing `lock.sh failed (exit 3)`, exit 0 (Review Focus 4).
  - `start_without_codeo_installed_is_a_todo`: `CODEO_ROOT` unset and no registry → a TODO saying codeo is not installed, no lock call.
  - `start_reports_a_wrong_folder`: clone folder named `scratch` on `main` → a TODO containing `'codeo-home'`; and a stub `folder-check.sh` that exits 1 → a TODO containing `the folder check failed` (Review Focus 5).
  Adjust the existing `ds_setup` so its scratch repo has the new scripts and a `.codeo/config.json` with `baseBranch`.
- [ ] **Step 2: Run to see them fail.** `bash tests/run.sh devcontainer` → `FAIL start_…` lines for the new cases only.
- [ ] **Step 3: Implement the two steps** in `devcontainer-start.sh`, modelled on the reference project's (`.devcontainer/scripts/devcontainer-start.sh` lines 197–235): base branch from `jq -r '.baseBranch // "main"' .codeo/config.json`; the lock step is skipped when `.codeo/active` is non-empty or the branch is the base branch; `lock.sh`'s `lock: TODO` lines go to `add_todo`, every other line is printed unchanged; `|| rc=$?` guards a crash. The folder check runs `folder-check.sh "$(basename "$clone")"` captured, with `todo:` lines to `add_todo` and a failing check to one TODO. Update the header comment (the home container takes no lock; an issue container takes it from the `init.md` on its branch).
- [ ] **Step 4: Run** `bash tests/run.sh devcontainer` → exit 0. Commit: `feat: the dev container takes the issue's lock and checks its clone folder (#55)`.

**Proof of done:** `bash tests/run.sh devcontainer` exits 0 with no `FAIL`; `shellcheck .devcontainer/scripts/devcontainer-start.sh tests/devcontainer.test.sh` is clean.

### Task 5: `devcontainer.json` name and the suite path

**Files:**
- Modify: `.devcontainer/devcontainer.json`, `.codeo/config.json`, `tests/devcontainer.test.sh` (`run_args_name_the_container_after_its_clone`, `run_args_cap_memory_and_cpus`, `config_has_codename_pin_and_suite_path`, header comment)

- [ ] **Step 1: Change the tests first.** `run_args_name_the_container_after_its_clone` asserts `.runArgs == ["--name=${containerWorkspaceFolderBasename}","--memory=4g","--cpus=2"]` exactly (the single-quoted `jq` argument keeps bash off the `${…}`), which also covers an extra or duplicate `--memory`/`--cpus`; `run_args_cap_memory_and_cpus` stays. `config_has_codename_pin_and_suite_path` also asserts the `shell` suite `paths` contain `.codeo/overlays/**`.
- [ ] **Step 2: Run to see them fail.** `bash tests/run.sh devcontainer` → `FAIL run_args_name_the_container_after_its_clone` and `FAIL config_has_codename_pin_and_suite_path`.
- [ ] **Step 3: Edit** `devcontainer.json`'s `runArgs[0]` and add `".codeo/overlays/**"` to the suite's `paths` in `.codeo/config.json`.
- [ ] **Step 4: Run** `bash tests/run.sh devcontainer` → exit 0. Commit: `feat: name the dev container after its clone folder alone (#55)`.

**Proof of done:** `bash tests/run.sh devcontainer` exits 0 with no `FAIL`; `jq -e . .devcontainer/devcontainer.json .codeo/config.json` exits 0.

### Task 6: The `init` overlay

**Files:**
- Create: `.codeo/overlays/init.md`, `tests/init-overlay.test.sh`

- [ ] **Step 1: Write `tests/init-overlay.test.sh`**: `bash scripts/overlay.sh init host-workflow` (the repo's own, from the repo root) exits 0 and the output contains each of: `home container`; `.codeo/active`; `Clone Repository in Named Container Volume`; `https://github.com/kbajpai/codeo/tree/`; `codeo-<N>`; `git worktree remove`; `git branch -D`; `/codeo:plan`; and does **not** contain `claude --cloud`. Also `bash scripts/overlay.sh init no-such-point` exits 2 (the registry still guards typos).
- [ ] **Step 2: Run to see it fail.** `bash tests/run.sh init-overlay` → exit 3 from `overlay.sh`, `FAIL`.
- [ ] **Step 3: Write the overlay** (`Project overlay text adds to or narrows a step…` line, then `## host-workflow`), adapted from the reference project's: runs in the home container; a `.codeo/active` here means the session is inside an issue's container — stop and say to run `init` in the home container; nothing is switched or stashed here; the lock is not written here; after the claim `git worktree remove <scratch>` and `git branch -D <branch>`; hand off by printing the clone instructions — *Dev Containers: Clone Repository in **Named** Container Volume…*, the URL `https://github.com/kbajpai/codeo/tree/<branch>`, volume `codeo-<N>`, folder `codeo-<N>` — and that the issue container's start script reports `lock: took the lock for #<N>`, after which `/codeo:plan` runs there; if the start script lists a TODO, that comes first. No `claude --cloud` launch.
- [ ] **Step 4: Run** `bash tests/run.sh init-overlay` → exit 0. Commit: `feat: /codeo:init runs in the home container and hands off to the issue's container (#55)`.

**Proof of done:** `bash tests/run.sh init-overlay` exits 0, no `FAIL`; `bash scripts/overlay.sh init host-workflow; echo $?` prints the text and `0`.

### Task 7: Documentation

**Files:**
- Create: `.devcontainer/README.md`
- Modify: `README.md` (one line linking it), `CHANGELOG.md` (one bullet under `## Unreleased`)

- [ ] **Step 1: Write `.devcontainer/README.md`**: the two kinds of container and their names (`codeo-home` / `codeo-<N>`, window `codeo [home]` / `codeo [#<N>]`); how to open the home container and an issue's (the Clone-in-Named-Volume values `init` prints); what the start script does (lock from the branch's `init.md`; none on `main`; folder check); **the folder rule** — Docker accepts `[a-zA-Z0-9][a-zA-Z0-9_.-]+` only and refuses anything else before any script runs, so use the folders above and re-clone if you typed another; the one-time rebuild to get the new name and `docker rm <name>` for a leftover container (#50 → #55).
- [ ] **Step 2: Add the one-line link in `README.md`** and the CHANGELOG bullet: the home/issue container workflow, the new scripts and overlay, the name now `<clone folder>` alone (`runArgs --name=${containerWorkspaceFolderBasename}`), rebuild once, the folder rule and its reason (#55; folds in #54's name requirement as documentation).
- [ ] **Step 3: Verify.** `grep -c '#55' CHANGELOG.md` → `1`; `grep -n 'devcontainer/README.md' README.md` shows the link; `grep -n '\[a-zA-Z0-9\]\[a-zA-Z0-9_.-\]+' .devcontainer/README.md CHANGELOG.md` shows both.
- [ ] **Step 4: Commit**: `docs: describe the home and issue containers (#55)`.

**Proof of done:** the three `grep`s above print what they should, and `bash tests/run.sh` still exits 0 (`docs/**` and `README.md` are not read by the new tests; this is the check that nothing else moved).

### Task 8: Run everything, then the host checks

**Files:** none.

- [ ] **Step 1: Run the whole suite.** `bash tests/run.sh` → exit 0, no failing file; `shellcheck .devcontainer/scripts/*.sh tests/*.test.sh` → clean.
- [ ] **Step 2: Host checks, by the engineer, recorded in `.codeo/55/qc.md`'s hand-off** (acceptance criteria 1–5, 8; this container has no `docker`): rebuild so the name takes effect; open `codeo-home` and run `/codeo:init` on a Ready issue → branch pushed, issue assigned, card In progress, no `.codeo/active` here, clone instructions printed; clone the printed URL into volume and folder `codeo-<N>` → the start script prints `lock: took the lock for #<N>`, `docker ps` shows `codeo-<N>`, the window reads `codeo [#<N>]`; keep both open at once and confirm neither changes the other's `.codeo/active`; `/codeo:init` inside the issue container stops.

**Proof of done:** `bash tests/run.sh` exits 0; the host checks are the engineer's, written into `qc.md`.
