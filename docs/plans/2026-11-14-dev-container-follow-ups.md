# Dev Container Follow-ups from #55 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the non-blocking findings `/codeo:qc` recorded for #55 (F2-F7) and its deferred minors: `folder-check.sh` honours the configured base branch, `codeo-root.sh` never takes another project's `lock.sh`, an empty `.codeo/active` no longer blocks the lock silently, and the Docker-name wording and the shared-folder-name limit are stated correctly.

**Architecture:** Five small changes to `.devcontainer/scripts/`, each driven by a failing case in the test file that already guards the script. `folder-check.sh` reads `baseBranch` from `.codeo/config.json` the way `devcontainer-start.sh` does. `codeo-root.sh` filters the registry's `codeo@codeo` entries by `projectPath` and takes the first that is this clone's, else the first with no `projectPath`. The start script removes a zero-byte `.codeo/active` before step 3a and puts a failed `lock.sh`'s output in its one TODO only. The wording and the limit are documentation: the `container-name.sh` header, `.devcontainer/README.md`, and `CHANGELOG.md`.

**Tech Stack:** bash, jq, git, `bash tests/run.sh`.

**Spec:** `.codeo/57/init.md` (`## Outcome`: the seven acceptance criteria); plan Q1-Q5 of `.codeo/57/plan.md`; the findings are `.codeo/done/55/qc.md` round 1 (F2-F7) and `.codeo/done/55/implement.md` ("Deferred minors").

## Global Constraints

- Nothing under `scripts/`, `lib/`, `hooks/` or `skills/` changes. The container runs the pinned plugin, so a change to this repository's own `scripts/lock.sh` would not reach it before the next pin bump.
- `devcontainer-start.sh` still always exits 0, and every failure stays a TODO line.
- No path to a codeo plugin is ever guessed: `codeo-root.sh` fails rather than take another project's entry (Q3).
- Docker name (Q1, document only): `devcontainer.json`'s `runArgs` does not change, so no container needs rebuilding for this change.
- Empty lock (Q2): only a zero-byte `.codeo/active` is removed. A file with content that names no issue is left as it is today and is not this plan's business.
- Deferred minors: all five are fixed (Tasks 1, 3 and 4); none is dismissed, so the PR description lists each with the task that fixed it.
- CHANGELOG (Q4, Q5): the `## v1.0.4` bullet for #55 is edited in place and the Unreleased bullet says so. `CHANGELOG.md` is also on #76's footprint; the second branch to merge keeps both bullets. This branch was cut at `09e3013`; Task 5 merges `origin/main` first.
- Documentation: the one page this change moves is `.devcontainer/README.md` (Task 5). No page under `docs/` describes the dev container, so none moves; `README.md`'s dev container section only links to it.
- Ordering: every task is proved by the `shell` suite in this checkout. There is no shared environment, so no task carries `Needs lease:`; no task runs on the engineer's host, so none carries `Runs on:`; no invariants document is configured. The Docker host checks for #55 are out of scope.
- The `shell` suite has no `filter`, so a task's proof is the whole `bash tests/run.sh` (prints `all cases passed`, exit 0). The file named in a task is the quick loop: `bash tests/<file>`.

## Review Focus

- `folder-check.sh`: the folder `codeo-home` stays silent on a branch that is not the base (the bare `-home` minor), and `codeo-12` on the home clone is now reported (Task 1).
- `codeo-root.sh`: an entry for another project is never chosen, even when it is first and its `installPath` has a `lock.sh` (Task 2, `start_uses_this_projects_lock_sh`).
- An empty `.codeo/active` is removed on the base branch as well as on an issue branch, and `lock.sh` is called only on the latter (Task 3).
- A crashing `lock.sh`'s output appears once, inside the TODO, and not on stdout (Task 3).
- `window-title.sh` shows no `container-name.sh` warning in the title it writes (Task 4).

---

### Task 1: `folder-check.sh` honours the configured base branch (F2)

**Files:**
- Modify: `tests/folder-check.test.sh` (`fc_setup`, new cases, `cases=( ... )`, header comment)
- Modify: `.devcontainer/scripts/folder-check.sh` (base branch; the two TODO texts; header comment)

**Interfaces:**
- Produces: `fc_setup <name> <branch> [base]` writes `"baseBranch":"<base>"` into the scratch `.codeo/config.json` when a third argument is given. `folder-check.sh` takes the base branch from `.codeo/config.json`'s `baseBranch` (the clone's root found with `git rev-parse --show-toplevel`), else `main`, an empty value counting as absent, exactly as `devcontainer-start.sh` does.

- [ ] **Step 1: Write the failing cases.** Change line 43 of `fc_setup` to write the config with `${3:+,"baseBranch":"$3"}` after the codename. Add these cases, each beginning `fc_setup <name> <branch> [base] || return 0`, and list them in `cases=( ... )`:
  - `home_folder_on_a_configured_base_is_silent` (criterion 4): `fc_setup base develop develop`, then `silent codeo-home`. It passes before the fix; it pins the criterion.
  - `wrong_folder_on_a_configured_base_names_the_home_folder`: `fc_setup basewrong develop develop`, then `todo scratch "'codeo-home'"`. Fails before the fix: the line names `codeo-<N>`.
  - `issue_folder_on_the_home_clone_is_reported`: `fc_setup basenum develop develop`, then `todo codeo-12 "'codeo-home'"`. Fails before the fix: `codeo-12` is silent.
  - `home_folder_off_the_base_branch_is_silent` (deferred minor: a bare `-home` folder on a non-main branch): `fc_setup offbase feat/x`, then `silent codeo-home`.
  The existing `wrong_folder_on_main` already covers a config with no `baseBranch`.

- [ ] **Step 2: Run them to see them fail.**
  Run: `bash tests/folder-check.test.sh`
  Expected: exit 1, with `FAIL wrong_folder_on_a_configured_base_names_the_home_folder` and `FAIL issue_folder_on_the_home_clone_is_reported`; the other new cases pass.

- [ ] **Step 3: Fix `folder-check.sh`.** After `codename=...` read the base: `root=$(git -C "$dir" rev-parse --show-toplevel)`, `base=$(jq -r '.baseBranch // empty' "$root/.codeo/config.json" 2>/dev/null || true)`, `[[ -n $base ]] || base=main`. Replace `$branch == main` by `$branch == "$base"`, and `its clone is on main with no lock` in the TODO text by `its clone is on $base with no lock`. Update the header comment: "On the base branch (`baseBranch`, else `main`) the clone is the home container".

- [ ] **Step 4: Run them to see them pass.**
  Run: `bash tests/folder-check.test.sh`
  Expected: `all cases passed`, exit 0.

- [ ] **Step 5: Prove nothing else moved.**
  Run: `bash tests/run.sh`
  Expected: `all cases passed`, exit 0.

- [ ] **Step 6: Commit.**

```bash
git add tests/folder-check.test.sh .devcontainer/scripts/folder-check.sh
git commit -m "fix: judge the clone folder against the configured base branch (#57)"
```

### Task 2: `codeo-root.sh` takes this project's registry entry (F3)

**Files:**
- Modify: `tests/codeo-root.test.sh` (a clone fixture, `registry` taking entries, new cases, `cases=( ... )`, header comment)
- Modify: `tests/devcontainer.test.sh` (new cases `start_uses_this_projects_lock_sh`, `start_ignores_another_projects_codeo`; `cases=( ... )`)
- Modify: `.devcontainer/scripts/codeo-root.sh` (entry selection; header comment)

**Interfaces:**
- Produces: the registry selection rule of Q3. The clone's root is `git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel` run through `pwd -P` (the same physical path the registry records). The chosen entry is the first of `.plugins["codeo@codeo"]` whose `projectPath` equals that root, else the first with no `projectPath`; an entry whose `projectPath` is another path is never chosen. The existing failure line, `codeo-root: no installed codeo@codeo with scripts/lock.sh in <registry>; ...`, is kept for every case where no entry qualifies or the chosen one has no `scripts/lock.sh`.
- `tests/codeo-root.test.sh` runs the script from a scratch git clone holding a copy of it, so the clone's root is known: add `cr_clone` (created in `setup`, with `git init -q`, the script copied to `$cr_clone/.devcontainer/scripts/codeo-root.sh`) and make `cr_run` run that copy. `registry` becomes `registry <path>...`, each argument `installPath` or `installPath@projectPath`, written in order, so an existing call with one plain path still means one entry with no `projectPath`.

- [ ] **Step 1: Write the failing cases.**
  In `tests/codeo-root.test.sh`:
  - `other_projects_entry_first_is_skipped` (criterion 2): two plugin roots with a `lock.sh`; registry lists the first with `projectPath` `/somewhere/else`, then the second with no `projectPath`; the output is the second.
  - `this_projects_entry_wins_over_a_user_entry`: registry lists a user entry (no `projectPath`) first and then one whose `projectPath` is `$cr_clone`; the output is the second.
  - `only_another_projects_entry_fails`: one entry with `projectPath` `/somewhere/else` whose root has a `lock.sh`; `fails_cleanly`.
  - `an_older_registry_without_project_paths_still_works`: the existing `registry_install_path` already covers it; keep it unchanged.
  In `tests/devcontainer.test.sh`, beside `start_without_codeo_installed_is_a_todo`:
  - `start_uses_this_projects_lock_sh` (criterion 2): `ds_setup`, `ds_branch feat/x`, two stub plugin roots whose `lock.sh` logs `$STUB_DIR/lock-calls-<name>` (`other` and `mine`), a registry in `$ds_dir/claude/plugins/installed_plugins.json` listing `other` with `projectPath` `/somewhere/else` first and `mine` with `projectPath` the clone's physical path second, and `DS_CODEO_ROOT` unset; after `ds_lock_ready`, only `lock-calls-mine` has a line.
  - `start_ignores_another_projects_codeo`: the same with the `mine` entry left out; no `lock.sh` is called and one TODO matches `codeo is not installed`.

- [ ] **Step 2: Run them to see them fail.**
  Run: `bash tests/codeo-root.test.sh; bash tests/devcontainer.test.sh`
  Expected: both exit 1, naming `other_projects_entry_first_is_skipped`, `this_projects_entry_wins_over_a_user_entry`, `only_another_projects_entry_fails`, `start_uses_this_projects_lock_sh` and `start_ignores_another_projects_codeo`.

- [ ] **Step 3: Rewrite the registry lookup in `codeo-root.sh`** (line 24): compute `clone=$(cd "$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)" && pwd -P)`; then `jq -r --arg c "$clone" '[.plugins["codeo@codeo"][]? | select(.projectPath == $c)][0].installPath // ([.plugins["codeo@codeo"][]? | select(.projectPath == null)][0].installPath) // empty' "$registry" 2>/dev/null || true`. Update the header comment to say which entry is chosen and that another project's entry never is.

- [ ] **Step 4: Run them to see them pass.**
  Run: `bash tests/codeo-root.test.sh; bash tests/devcontainer.test.sh`
  Expected: each prints `all cases passed`, exit 0.

- [ ] **Step 5: Prove nothing else moved.**
  Run: `bash tests/run.sh`
  Expected: `all cases passed`, exit 0.

- [ ] **Step 6: Commit.**

```bash
git add tests/codeo-root.test.sh tests/devcontainer.test.sh .devcontainer/scripts/codeo-root.sh
git commit -m "fix: take this project's codeo from the plugin registry (#57)"
```

### Task 3: The start script handles an empty `.codeo/active` and a crashed `lock.sh` (F6, a minor)

**Files:**
- Modify: `tests/devcontainer.test.sh` (new and changed cases, `cases=( ... )`)
- Modify: `.devcontainer/scripts/devcontainer-start.sh` (step 3a; header comment)

**Interfaces:**
- Produces: before step 3a's test of `.codeo/active`, a regular file of zero bytes there is removed and the script prints `devcontainer-start: .codeo/active was empty and held no lock: removed it`; step 3a then runs as for a clone with no lock. When `lock.sh` exits non-zero, its output is not printed line by line: the one TODO `codeo's lock.sh failed (exit <rc>): <output>` carries it. A zero exit keeps today's handling (lines printed, `lock: TODO — ` lines become TODOs).

- [ ] **Step 1: Write the failing cases**, each beginning `ds_setup <name> || return 0`, with `ds_lock_stub` and, for the first, `ds_branch feat/x`, and listed in `cases=( ... )`:
  - `start_empty_lock_file_is_removed_and_the_lock_taken` (criterion 3): an empty `$ds_dir/codeo-home/.codeo/active` on `feat/x`; after `ds_lock_ready`, `lock-calls` holds one `take container`, stdout has the removal line and `lock: took the lock for #55 on feat/x`, and `.codeo/active` names issue 55.
  - `start_empty_lock_file_on_the_base_branch_is_removed`: the same file on `main`: removed, stdout has the removal line, `lock-calls` is empty.
  - `start_nonempty_lock_file_is_left_alone`: a file holding `issue:   55` is kept and `lock-calls` is empty (the existing re-run case; extend it with the file kept).
  Change `start_lock_crash_is_a_todo`: with `STUB_LOCK_RC=3 STUB_LOCK_OUT='boom'`, `boom` is not in stdout and occurs once in stderr.

- [ ] **Step 2: Run them to see them fail.**
  Run: `bash tests/devcontainer.test.sh`
  Expected: exit 1, naming `start_empty_lock_file_is_removed_and_the_lock_taken`, `start_empty_lock_file_on_the_base_branch_is_removed` and `start_lock_crash_is_a_todo`.

- [ ] **Step 3: Fix the script.** Before `if [[ -s .codeo/active ]]`, add `if [[ -f .codeo/active && ! -s .codeo/active ]] && rm -f .codeo/active; then say ".codeo/active was empty and held no lock: removed it"; fi` (a failed `rm` becomes `add_todo ".codeo/active is empty and could not be removed: remove it, then re-run this script"`). In the `lock.sh` branch, print the lines only when `lock_rc` is 0, by moving the `while` loop under `((lock_rc == 0))` and leaving the failure TODO as it is. Update the header comment of step 3a.

- [ ] **Step 4: Run them to see them pass.**
  Run: `bash tests/devcontainer.test.sh`
  Expected: `all cases passed`, exit 0.

- [ ] **Step 5: Prove nothing else moved.**
  Run: `bash tests/run.sh`
  Expected: `all cases passed`, exit 0.

- [ ] **Step 6: Commit.**

```bash
git add tests/devcontainer.test.sh .devcontainer/scripts/devcontainer-start.sh
git commit -m "fix: remove an empty lock file at start and report a lock crash once (#57)"
```

### Task 4: Window title and overlay test minors

**Files:**
- Modify: `tests/devcontainer.test.sh` (a case beside `title_is_home_without_a_lock`; `cases=( ... )`)
- Modify: `.devcontainer/scripts/window-title.sh` (line 22)
- Modify: `tests/init-overlay.test.sh` (the needle list)

**Interfaces:**
- Produces: `window-title.sh` takes the title from `container-name.sh`'s stdout only; on failure it still reports `container-name.sh`'s message through its own `window-title: could not name the container: ...` line, as `title_outside_a_repository_says_so` expects.

- [ ] **Step 1: Write the failing case.** `title_ignores_a_warning_on_stderr`: `wt_setup warn`, then overwrite `$wt_dir/.devcontainer/scripts/container-name.sh` with a stub that prints `a warning` on stderr and `codeo [home]` on stdout and exits 0; `wt_run --print` gives exactly `codeo [home]`. Add it to `cases=( ... )`.

- [ ] **Step 2: Run it to see it fail.**
  Run: `bash tests/devcontainer.test.sh`
  Expected: exit 1, `FAIL title_ignores_a_warning_on_stderr`: `--print` gave the warning and the title on two lines.

- [ ] **Step 3: Fix `window-title.sh`.** Capture stderr apart: `errf=$(mktemp)`, `trap 'rm -f "$errf"' EXIT`, `title=$(bash ... "$root" 2>"$errf") || die "could not name the container: $(sed ':a;N;$!ba;s/\n/ \/ /g;s/^container-name: //' "$errf")"`. Keep `title_outside_a_repository_says_so` passing.

- [ ] **Step 4: Tighten the overlay needle.** In `tests/init-overlay.test.sh` replace the bare `'.codeo/active'` with `'This skill does not write `.codeo/active`'` (the backticks stay inside the single quotes; the overlay's sentence is `**This skill does not write `.codeo/active`**`).

- [ ] **Step 5: Run them to see them pass.**
  Run: `bash tests/devcontainer.test.sh; bash tests/init-overlay.test.sh`
  Expected: each prints `all cases passed`, exit 0.

- [ ] **Step 6: Prove nothing else moved.**
  Run: `bash tests/run.sh`
  Expected: `all cases passed`, exit 0.

- [ ] **Step 7: Commit.**

```bash
git add tests/devcontainer.test.sh .devcontainer/scripts/window-title.sh tests/init-overlay.test.sh
git commit -m "fix: keep a container-name warning out of the window title; pin the overlay line (#57)"
```

### Task 5: Say where the Docker name comes from, and what the folder limit is (F4, F5, F7)

**Files:**
- Modify: `.devcontainer/scripts/container-name.sh` (header comment, lines 2-9)
- Modify: `.devcontainer/README.md` (*What the start script does*, *The folder rule*, *Rebuilding*)
- Modify: `CHANGELOG.md` (the `## v1.0.4` #55 bullet; a new bullet under `## Unreleased`)

**Interfaces:**
- Documentation only; no test changes. The proof is that `bash tests/run.sh` still passes (`tests/agnostic.test.sh` guards the wording of tracked files) and the check in Step 5.

- [ ] **Step 1: Merge `main`.**
  Run: `git merge origin/main`
  Expected: a clean merge or a conflict only in `CHANGELOG.md` (#76 and others add under Unreleased); on a conflict keep both bullets. Exit 0 once resolved.

- [ ] **Step 2: Correct the `container-name.sh` header.** Say that the script names the VS Code window (`window-title.sh`) and every Claude session in it (`session-title.sh`) and that `--docker` prints what the container's Docker name should be; the Docker name itself is the clone folder, set by `runArgs` `--name=${containerWorkspaceFolderBasename}` in `.devcontainer/devcontainer.json`, and `folder-check.sh` reports a folder that disagrees. Drop "All three names come from this one script so they cannot drift apart."

- [ ] **Step 3: Update `.devcontainer/README.md`.**
  - *What the start script does* (line 25): name the file by its real path, `.devcontainer/scripts/devcontainer-start.sh`.
  - Add to *What the start script does* one bullet: an empty `.codeo/active` holds no lock, so the script removes it, says so, and goes on to take the lock on an issue branch.
  - *The folder rule*: add that the Docker name is the folder's name, so two containers whose folders share a name cannot run at once. This happens when a host folder is opened with **Reopen in Container** from two paths with the same last name (`~/a/codeo` and `~/b/codeo`); Docker then reports `name already in use`. Give one of them another folder name, or use the named-volume flow above, whose folders `codeo-home` and `codeo-<N>` never clash.
  - *Rebuilding*: say that `name already in use` also means a second container with the same folder name, and point at the folder rule.

- [ ] **Step 4: Update `CHANGELOG.md`.**
  - In the `## v1.0.4` bullet for #55, change the clause "`container-name.sh` and `folder-check.sh` (a `todo:` line names the right folder)" so that `container-name.sh` is described as printing the window title and the name the container should have, the Docker name itself being the folder (`runArgs`).
  - Add under `## Unreleased` one bullet, in the style of its neighbours: `folder-check.sh` honours `baseBranch`, `codeo-root.sh` takes this project's registry entry and never another's, an empty `.codeo/active` is removed at start, a crashed `lock.sh`'s output is reported once, `window-title.sh` ignores a `container-name.sh` warning; the `container-name.sh` header and the README path are corrected; the README and CHANGELOG state that two same-named folders cannot run at once; the `## v1.0.4` bullet for #55 was corrected in place; nothing in `scripts/`, `lib/`, `hooks/` or `skills/` changes; `(#57)`.

- [ ] **Step 5: Prove it.**
  Run: `bash tests/run.sh`
  Expected: `all cases passed`, exit 0.
  Run: `grep -n "scripts/devcontainer-start.sh" .devcontainer/README.md`
  Expected: every hit reads `.devcontainer/scripts/devcontainer-start.sh`, none a bare `scripts/devcontainer-start.sh`.

- [ ] **Step 6: Commit.**

```bash
git add .devcontainer/scripts/container-name.sh .devcontainer/README.md CHANGELOG.md
git commit -m "docs: say where the Docker name comes from and what the folder limit is (#57)"
```

## Acceptance map

| Criterion | Task and proof |
|---|---|
| Two checkouts with one folder name: the limit and the fix are stated | Task 5, Step 3 and Step 4 (Q1: document only) |
| Registry with another project's entry first; the start script uses this project's `lock.sh` | Task 2, `start_uses_this_projects_lock_sh` |
| A container with an empty `.codeo/active` sees a lock taken | Task 3, `start_empty_lock_file_is_removed_and_the_lock_taken` |
| `folder-check.sh` on a non-`main` base, on its home clone, gets no wrong-folder TODO | Task 1, `home_folder_on_a_configured_base_is_silent` and its neighbours |
| The comment, the CHANGELOG line and the README path match the code | Task 5, Steps 2-5 |
| Each deferred minor is fixed or dismissed in the PR description | Tasks 1, 3, 4 (all five fixed); the PR description lists them |
| `bash tests/run.sh` passes and `CHANGELOG.md` records the change | every task's last proof; Task 5, Step 4 |
