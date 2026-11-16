# Cmd Mode: Existing Container and QC Round 2 Follow-ups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `codeo-container.sh issue <N> <branch>` no longer silently reuses an existing container's clone, and the documentation and small defects QC round 2 found (R2-R6) are fixed.

**Architecture:** `ensure_container` keeps `home`'s re-run but makes `issue` refuse a container that already exists unless `--rebuild` is given; `ensure_clone` compares an existing issue clone's branch with the requested one and refuses a mismatch. The README, the script header, the init hand-off and the changelog bullet are corrected to say what the code does. The first plan's text is not edited.

**Tech Stack:** bash (3.2 on the host script), Docker stub tests, `bash tests/run.sh`.

**Spec:** `docs/plans/2026-11-16-cmd-mode-containers.md` (the first plan); `.codeo/113/qc.md` round 2 (R1-R8); `.codeo/113/plan.md` Q5.

## Global Constraints

- The host script stays bash 3.2 and BSD-safe: builtins, `docker` and `git`; `uname` and `xcode-select` only where `git_is_usable` already uses them. `tests/cmd-mode.test.sh`'s portability scan must keep passing.
- Q5: `issue <N> <branch>` on an existing `codeo-<N>` (running or stopped), without `--rebuild`, changes nothing and exits 1 with one line. `home` keeps its re-run. The VS Code route is not touched.
- Documentation describes the system after the change: present tense, no issue numbers, no "now".
- Pages moved: `.devcontainer/README.md`, `.codeo/overlays/init.md`, `CHANGELOG.md` (the existing `(#113)` bullet is edited in place, not a second bullet).
- Not changed, deliberately: R7 (bash 3.2 on a real Mac is the engineer's host task) and R8 (the image's removal is in the README already).

## Review Focus

- `issue <N> <branch>` on a stopped `codeo-<N>`: refused, and the container is not started.
- `issue <N> <other-branch> --rebuild` on a volume whose clone is on `<branch>`: refused, naming both branches, after nothing is cloned.
- A clone in detached HEAD or an unreadable branch: refused as a mismatch, never passed.
- `docker info` failing for a reason Docker prints (permission denied on the socket): the reason reaches the engineer in the one line.
- `CODEO_CMD_MODE=true`: `session-title.sh` titles the session as the start script treats it as cmd mode.

---

### Task 1: `issue` refuses an existing container; a rebuilt clone must be on the branch

**Files:**
- Modify: `.devcontainer/codeo-container.sh` (`ensure_container`, `ensure_clone`, `cmd_issue`)
- Test: `tests/cmd-mode.test.sh`

**Interfaces:**
- Consumes: `container_state <name>` (missing|stopped|running), `die <message> [rc]`, `bring_up`.
- Produces: `bring_up <name> <ref> <rebuild> <fresh_only>`: `ensure_container` gains a fourth argument; `1` (passed by `cmd_issue`) makes a non-missing container with `rebuild=0` call `die` with the message below. `ensure_clone <name> <ref> <check_branch>`: with `1` (issue) and `.git` present, run `docker exec <name> git -C /workspaces/<name> branch --show-current` and `die` unless its output equals `<ref>`.

Messages (exact):
- existing container: `codeo-<N> already exists: enter it with 'bash codeo-container.sh shell <N>', rebuild it with 'bash codeo-container.sh issue <N> <branch> --rebuild', or remove it (docker rm -f codeo-<N>; docker volume rm codeo-<N>, once git status in it shows nothing unpushed) to start from a fresh clone`
- branch mismatch: `the clone in codeo-<N> is on '<current>', not '<branch>': remove the volume (docker volume rm codeo-<N>, once git status in it shows nothing unpushed) or give the branch it is on`

- [ ] **Step 1: Write the failing tests** in `tests/cmd-mode.test.sh`, listed in `cases=( … )`, using the stub (`state` file, `STUB_*` variables; add `STUB_BRANCH` so the stub answers `exec … git -C … branch --show-current` with its value, default empty):
  - `issue_on_a_running_container_is_refused`: state running; `issue 5 feat/x` exits 1, stderr is the existing-container line for `codeo-5`, and the recorded calls contain no `start`, `run`, `rm`, `build` and no `exec`.
  - `issue_on_a_stopped_container_is_refused_and_not_started`: state stopped; same exit and line; no `start` call.
  - `issue_rebuild_on_a_matching_clone_goes_ahead`: state running, `STUB_BRANCH=feat/x`, `issue 5 feat/x --rebuild` exits 0 and the calls end with the start script's `exec`.
  - `issue_rebuild_on_another_branch_is_refused`: `STUB_BRANCH=feat/old`, `issue 5 feat/x --rebuild` exits 1 with the mismatch line naming `feat/old` and `feat/x`, and no start-script `exec` is recorded.
  - `issue_on_a_volume_left_without_its_container_checks_the_branch`: state missing, clone present, `STUB_BRANCH=` (empty): exit 1, mismatch line.
  - `home_rerun_still_runs_the_start_script_on_an_existing_container`: state running; `home` exits 0 and records the start script's `exec` (the existing `home_rerun_on_a_running_container_creates_nothing` stays as it is).
  Update `issue_rebuild_and_rerun_follow_home` so its re-run assertion matches the new behaviour (the re-run is now a refusal).
- [ ] **Step 2: Run** `bash tests/cmd-mode.test.sh` → the new cases `FAIL`.
- [ ] **Step 3: Implement** the signatures and messages above in `.devcontainer/codeo-container.sh`; `cmd_home` passes `0`/`0`, `cmd_issue` passes `1`/`1`.
- [ ] **Step 4: Run** `bash tests/cmd-mode.test.sh` → `all cases passed`.
- [ ] **Step 5: Commit** `fix(codeo-container): issue refuses an existing container and a clone on another branch (#113)`.

**Proof of done:** `bash tests/cmd-mode.test.sh` prints `all cases passed`.

### Task 2: Small script fixes: the Docker reason (R5) and `CODEO_CMD_MODE` read alike (R6)

**Files:**
- Modify: `.devcontainer/codeo-container.sh` (`require_docker`, header comment), `.devcontainer/scripts/session-title.sh` (line 20)
- Test: `tests/cmd-mode.test.sh`, `tests/devcontainer.test.sh`

**Interfaces:**
- Produces: `require_docker` dies with `Docker is not available: <first line of docker info's stderr>`, or the existing `install it and start it, then run this again` text when stderr is empty. `session-title.sh` treats any non-empty `CODEO_CMD_MODE` as cmd mode, as `devcontainer-start.sh` does. The header's `CODEO_CONTEXT` line (R2) says: `the .devcontainer directory of a local clone, to build the image from instead of the Git URL (the repository is still cloned from CODEO_REPO_URL)`.

- [ ] **Step 1: Failing tests.** `tests/cmd-mode.test.sh`: `docker_failure_shows_dockers_own_reason` (stub `info` writes `permission denied while trying to connect to the Docker daemon socket` to stderr and exits 1; the one stderr line contains that text and starts `codeo-container: Docker is not available: `); the existing no-reason case keeps passing. `tests/devcontainer.test.sh`: `session_title_in_cmd_mode_accepts_any_value` (run the hook with `CODEO_CMD_MODE=true` and no `REMOTE_CONTAINERS`; it prints a session title as with `1`), listed in its `cases=( … )`.
- [ ] **Step 2: Run** both files → the two new cases `FAIL`.
- [ ] **Step 3: Implement** as above. The stub's `info` reads `STUB_INFO_ERR` and prints it to stderr.
- [ ] **Step 4: Run** `bash tests/cmd-mode.test.sh` and `bash tests/devcontainer.test.sh` → `all cases passed` each.
- [ ] **Step 5: Commit** `fix: show Docker's own reason, read CODEO_CMD_MODE alike in both scripts (#113)`.

**Proof of done:** both commands print `all cases passed`.

### Task 3: Documentation: the existing container, `CODEO_CONTEXT`, the title, `--init`

**Files:**
- Modify: `.devcontainer/README.md`, `.codeo/overlays/init.md`, `CHANGELOG.md` (the `(#113)` bullet, in place)
- Test: `tests/cmd-mode.test.sh`, `tests/init-overlay.test.sh`

What each must say afterwards:
- README, *Opening a container from the command line*: the paragraph on re-running says `issue` on an existing `codeo-<N>` refuses and names the three ways on (`shell <N>`, `--rebuild`, removal), and that a mismatching clone is refused; `home` on a running container runs the start script again; to see the TODO list again, `shell` and run `bash .devcontainer/scripts/devcontainer-start.sh`. The `CODEO_CONTEXT` row reads: the `.devcontainer` directory of a local clone, used only to build the image; the repository is still cloned from `CODEO_REPO_URL`. The table row and the two sentences about the terminal title say `shell` sets the title once and the prompt `dev@codeo-<N>` names the terminal after that. The list of differences gains: the container runs with `--init`, which the VS Code route does not set.
- README, *Rebuilding* and the stash paragraph (*After a stash …*): add that the command-line route needs the old container and volume removed before `issue` opens the resumed workflow, the same removal commands.
- `.codeo/overlays/init.md`, the command-line bullet: after the command, one sentence: if `codeo-<N>` exists (a stash being resumed), remove it first with `docker rm -f codeo-<N>; docker volume rm codeo-<N>`, once `git status` in it shows nothing unpushed, or the command refuses.
- `CHANGELOG.md`: the bullet's `CODEO_CONTEXT` clause matches the README; one clause says `issue` refuses an existing container.

- [ ] **Step 1: Failing tests.** `tests/cmd-mode.test.sh`: `docs_readme_says_issue_refuses_an_existing_container` (README contains `already exists` and `--rebuild`), `docs_readme_describes_codeo_context_as_the_devcontainer_directory`, `docs_readme_lists_init_among_the_differences`. `tests/init-overlay.test.sh`: a needle for `docker volume rm codeo-<N>` in the hand-off. Each fails first.
- [ ] **Step 2: Run** `bash tests/cmd-mode.test.sh` and `bash tests/init-overlay.test.sh` → the new cases `FAIL`.
- [ ] **Step 3: Edit** the three files as listed.
- [ ] **Step 4: Run** both test files → `all cases passed`, then `bash tests/run.sh` → `all cases passed`.
- [ ] **Step 5: Commit** `docs: describe the existing-container refusal, CODEO_CONTEXT and the title (#113)`.

**Proof of done:** `bash tests/run.sh` prints `all cases passed`.

### Task 4: The stash-resume check on the engineer's host

Runs on: the engineer's host

Added to Task 10 of the first plan, not replacing it. With a running `codeo-<N>` from `issue`, run `bash codeo-container.sh issue <N> <branch>` and check that it exits 1 with the `already exists` line and starts nothing; then run `bash codeo-container.sh shell <N>`.

**Proof of done:** the first command prints one line starting `codeo-container: codeo-<N> already exists` and `docker ps` still shows `codeo-<N>` unchanged.
