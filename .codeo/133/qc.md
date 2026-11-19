# Issue #133 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/133 |
| Branch | `feat/codeo-command-host-short-bash` |
| Updated | 2026-11-19 |

## Where this stands

Round 4 is written and the change goes back to `/codeo:implement`: one blocking finding (F24, `rm` refuses a finished, squash-merged issue). Nothing is open.

## Questions

None.

## Notes

Commands run this pass (the branch already contained `origin/main`; `sync-main.sh` merged nothing; `overlap.sh 133` and `overlap.sh --outside 133` printed nothing):

```
scope.sh origin/main HEAD
  suite shell needed for unclassified paths: .codeo/133/implement.md, init.md, issue.md, plan.md, CHANGELOG.md
  suite.shell=true
build (suite shell, build command `true`): exit 0
bash tests/run.sh (suite shell, whole): exit 1 — only live.test.sh failed:
  FAIL: beat_without_a_lock_or_on_the_base_branch_does_nothing — no lock: stamp: want [no] got [yes]
  FAIL: beat_without_a_lock_or_on_the_base_branch_does_nothing — base: stamp: want [no] got [yes]
  FAIL: clear_deletes_the_ref_and_the_stamp — stamp gone: want [no] got [yes]
  3 assertion(s) failed / failed: live.test.sh
bash tests/run.sh codeo-command: all cases passed
bash tests/run.sh live in a clean git worktree of origin/main: all cases passed
```

`live.test.sh` is environmental: this container's checkout holds a live-signal stamp `.git/codeo-live-beat` (written by the live hook), which the test expects to be absent; a clean `origin/main` worktree passes, and this branch changes nothing under `scripts/`, `hooks/` or `tests/live.test.sh`. Not a finding against this change.

No shared environment, no invariants file, no `wiki` module and no overlay for `qc` are configured: step 9 and the invariants check do not apply. `$DOCS` was checked by reading the diff of `.devcontainer/README.md`, `.sbx/README.md` and `CHANGELOG.md` against `.devcontainer/codeo`: no "now", "no longer" or issue number in the READMEs; the changelog bullet cites `(#133)` like its neighbours; the plan's "documentation moved" claim holds (no other page describes these scripts).

## Outcome

### Round 1 — 2026-11-19

Independent review (opus): no Critical, two Important, six Minor; verdict "With fixes". Its findings were checked against the code; F1 is confirmed at `.devcontainer/codeo:175-177` (`host_kinds`) and `:297` (`cmd_list`), where a failing `docker ps` is read as "none".

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | One download line installs `codeo`; `codeo help` prints the commands | met | `t_help_lists_commands`; the line is in `.devcontainer/README.md` and `CHANGELOG.md` |
| 2 | `codeo update` replaces all three; a failed download changes nothing | met | `t_update_replaces_three`, `t_update_failed_download_changes_nothing`, `t_update_empty_file_refused`, `t_update_not_a_script_refused`, the two partial-move cases |
| 3 | `home`, `shell`, `issue` run the container script from the `codeo` directory | met | `t_home_runs_script`, `t_runs_from_any_directory`, `t_shell_container`, `t_relative_codeo_home` |
| 4 | `issue <N>` with no branch uses the origin branch carrying `.codeo/<N>/init.md`; none or several: one line, nothing created | met — with F3 (git's own progress lines on a first real run; non-blocking) | `t_issue_branch_lookup_one`, `t_issue_lookup_none`, `t_issue_lookup_several` |
| 5 | Container or sandbox by flag or saved default; sandbox create, open, shell, end reachable | met | `t_issue_sandbox_flag`, `t_issue_default_sandbox`, `t_open_sandbox`, `t_shell_sandbox`, `t_rm_sandbox` |
| 6 | `list` shows each container and sandbox with number and branch, nothing misleading when none | not met | F1: with `docker` installed but failing (daemon down), `codeo list` prints `no issue containers or sandboxes` and exits 0, and `shell`/`open`/`rm` say `no container or sandbox codeo-<N> found`; `t_list_docker_down` asserts the silent behaviour. A stopped container shows `-` for its branch (F2, the engineer's Q5 answer, non-blocking) |
| 7 | `rm` refuses naming what is unpushed or uncommitted; removes container and volume, or the sandbox; override removes anyway | met | `t_rm_container_clean`, `t_rm_container_untracked`, `_unpushed`, `_stash`, `_detached`, `t_rm_container_force`, `t_rm_exec_failure_is_not_clean`, `t_rm_sandbox`, `t_rm_sandbox_force` |
| 8 | Bad number, missing argument, unknown command: usage line, non-zero exit, nothing run | met | `expect_usage` (exit 2, `usage:` line, empty calls log) over each |
| 9 | Test against stubs covering each command, argument errors, lookup none/one/several; `tests/run.sh` passes | met | `tests/codeo-command.test.sh` (all cases passed); the whole `bash tests/run.sh` fails only on the environmental `live.test.sh` above, which passes on a clean `origin/main` worktree |
| 10 | Both READMEs show the `codeo` forms beside the long ones; CHANGELOG entry | met | `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md` `## Unreleased`; reviewer's wording gaps are F5, F6 (non-blocking) |

**Findings**

- **F1 — blocking — `/codeo:implement`'s.** `codeo list`, `shell`, `open` and `rm` treat a failing `docker ps -a` or `sbx ls` as "nothing there": `host_kinds` (`.devcontainer/codeo:175-177`) and `cmd_list` (`:297`, and the sbx side) fold a failing call into the missing-program case. The plan skips only a *missing* program (Q5; Global Constraints: "a missing one counts as 'none of that kind'"); the code goes further. With the Docker daemon down, `codeo list` tells the user their containers do not exist and `codeo rm 5` advises `codeo issue 5`, which fails too. Criterion 6 requires "nothing misleading". Cause (read from the code, Phase 1): the `if command -v … && listing=$(…)` chains in both functions cannot tell "program absent" from "program failed". Needed: when a program is installed but its listing fails, say so on stderr (`codeo: could not list docker containers` and the program's first error line when there is one); print `no issue containers or sandboxes` only when every installed program answered; make `detect_kind` say it could not ask docker or sbx instead of "no container or sandbox found"; change `t_list_docker_down` to assert that, and add one for `shell`/`rm`.
- **F2 — non-blocking — the plan's (and the engineer's).** A stopped container's branch is `-` in `list`, which is what the engineer chose at plan Q5 ("a stopped container is not started, and its branch is `-`"); the README says so. The reviewer notes that after a host reboot every container is stopped, so `list` then shows no branches; `docker cp codeo-<N>:/workspaces/codeo-<N>/.git/HEAD -` reads the branch from a stopped container without starting it. Recorded for the engineer: a change of that decision is a `/codeo:plan` round, not a fix.
- **F3 — non-blocking — `/codeo:implement`'s.** `git clone --bare` and `git fetch` in `find_branch` (`.devcontainer/codeo:119,125`) print progress and `From …` lines on stderr, so a failed lookup on a real first run prints those lines before the one `codeo:` line; the tests pass because the git stub is silent. Add `-q` to both.
- **F4 — non-blocking — `/codeo:implement`'s.** `cmd_home` (`:152-156`) accepts any number of `--rebuild`, so `codeo home --rebuild --rebuild` downloads a missing script and runs `codeo-container.sh`, which prints its own usage; the README's "exits 2 without running … a script" is therefore too strong. Allow at most one argument.
- **F5 — non-blocking — `/codeo:implement`'s.** The help and usage text and the README tables leave out `--container|--sandbox` on `shell`, `open` and `rm` (`.devcontainer/codeo:22-31,64-72`), which the code accepts and the "both exist" message tells the user to add.
- **F6 — non-blocking — `/codeo:implement`'s.** `CHANGELOG.md` says `codeo update` replaces the files "all or nothing"; that holds for the downloads only, the moves can fail part-way (the README says so correctly). Reword to "a failed download changes nothing".
- **F7 — non-blocking — `/codeo:implement`'s.** `find_branch` (`:132`) reads `git for-each-ref` through a process substitution, so a failing ref listing reads as "no branch holds" rather than an error.
- **F8 — non-blocking — `/codeo:implement`'s.** `cmd_update`'s `mkdir -p "$dir"` (`:455`) prints mkdir's raw error on failure, unlike `ensure_home` (`:94`); `codeo rm` leaves a stopped container running after it starts it for the check and then refuses.
- Carried from `implement.md`'s deferred minors, not re-raised: `codeo issue N` with `HOME` and `CODEO_HOME` unset and no kind flag prints its one-line error twice; the lookup lazily fetches one blob per matching branch.

No issue was filed for this pass.

**Verdict: back to `/codeo:implement`.**


### Round 2 — 2026-11-19

Re-checks `implement.md` round 2 (fix commit `bb31110`), the whole pass again from step 0. HEAD `548e0f2`.

Commands run this pass:

```
role.sh --check qc: exit 0
sync-main.sh --abort-on-conflict: "sync-main: the branch already contains origin/main" (exit 0)
overlap.sh 133: nothing printed · overlap.sh --outside 133: nothing printed
scope.sh origin/main HEAD
  scope: suite shell needed for unclassified paths: .codeo/133/implement.md, init.md, issue.md, plan.md, qc.md, CHANGELOG.md
  suite.shell=true
overlay.sh qc invariants-extra: exit 3 (none) · overlay.sh qc wiki-rules: exit 3 (none) · no invariants, no environment
build (suite shell, `true`): exit 0
bash tests/run.sh (suite shell, whole): exit 1 — only live.test.sh:
  FAIL: beat_without_a_lock_or_on_the_base_branch_does_nothing — no lock: stamp: want [no] got [yes]
  FAIL: beat_without_a_lock_or_on_the_base_branch_does_nothing — base: stamp: want [no] got [yes]
  FAIL: clear_deletes_the_ref_and_the_stamp — stamp gone: want [no] got [yes]
  3 assertion(s) failed / failed: live.test.sh
bash tests/run.sh codeo-command: all cases passed (85 test functions)
```

`live.test.sh` is the same environmental failure as round 1: the stamp `.git/codeo-live-beat` (written 2026-11-19 12:50 by the live hook) is present in this checkout, the test expects it absent, round 1 showed it passes in a clean `origin/main` worktree, and the branch touches nothing under `scripts/`, `hooks/` or `tests/live.test.sh`. Not a finding against this change.

Independent review (opus, description "QC review: …", given the criteria only): no Critical, two Important, four Minor; its verdict "With fixes". Its findings are F9-F14 below, each checked against the code.

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | One download line installs `codeo`; `codeo help` prints the commands | met | `t_help_lists_commands`, `t_help_names_kind_flags`; the line in `.devcontainer/README.md` and `CHANGELOG.md` |
| 2 | `codeo update` replaces all three; a failed download changes nothing | met | `t_update_replaces_three`, `t_update_failed_download_changes_nothing` and the refused-file and partial-move cases |
| 3 | `home`, `shell`, `issue` run the container script from the `codeo` directory | met | `t_home_runs_script`, `t_runs_from_any_directory`, `t_shell_container` |
| 4 | `issue <N>` with no branch uses the origin branch carrying `.codeo/<N>/init.md`; none or several: one line, nothing created | met — with F10 (a failed lazy blob fetch is read as "not there"; non-blocking) and F9 | `t_issue_branch_lookup_one`, `t_issue_lookup_none`, `t_issue_lookup_several`, `t_lookup_quiet_git`, `t_lookup_branch_list_failure`; the reviewer re-ran the lookup with real git against a local repository |
| 5 | Container or sandbox by flag or saved default; sandbox create, open, shell, end reachable | met | `t_issue_sandbox_flag`, `t_issue_default_sandbox`, `t_open_sandbox`, `t_shell_sandbox`, `t_rm_sandbox` |
| 6 | `list` shows each container and sandbox with number and branch, nothing misleading when none | met | `t_list_docker_down`, `t_list_sbx_down`, `t_list_one_down_nothing_shown`; `.devcontainer/codeo` `cmd_list` prints "no issue containers or sandboxes" only when every installed program answered. F13, F14 non-blocking |
| 7 | `rm` refuses naming unpushed or uncommitted work; removes container and volume, or the sandbox; override removes anyway | met | `t_rm_container_clean`, `t_rm_container_unpushed` and the untracked/stash/detached cases, `t_rm_container_force`, `t_rm_refusal_stops_started_container`, `t_rm_listing_down_nothing_found`, `t_rm_sandbox` |
| 8 | Bad number, missing argument, unknown command: usage line, non-zero exit, nothing run | met | `expect_usage` cases (exit 2, `usage:` line, empty calls log), `t_home_rebuild_twice_usage` |
| 9 | Stub test covering each command, argument errors, lookup none/one/several; `tests/run.sh` passes | met | `tests/codeo-command.test.sh`: all cases passed; the whole `tests/run.sh` fails only on the environmental `live.test.sh` above |
| 10 | Both READMEs show the `codeo` forms beside the long ones; CHANGELOG entry | met | `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md` `## Unreleased`; F15, F16 non-blocking |

**Documentation check.** The READMEs and the changelog match the code on every behaviour round 2 changed (failed listings, `home` arguments, kind flags, the update wording in `CHANGELOG.md`); no "now", "no longer" or issue number in the READMEs. Gaps are F14-F16.

**Findings**

- F1 (blocking in round 1) — fixed by `bb31110`: a failing installed `docker`/`sbx` is reported on stderr, `list` exits 1 and withholds "no issue containers or sandboxes", and `shell`/`open`/`rm` say they could not ask. F3-F8 (non-blocking in round 1) — fixed by `bb31110`. F2 stands as recorded in round 1 (the engineer's plan Q5 answer).
- **F9 — non-blocking — `/codeo:implement`'s.** `find_branch` (`.devcontainer/codeo:117-126`) clones `.lookup.git` once and fetches its saved `origin` thereafter, so a later change of `CODEO_REPO_URL` is ignored while the error message names the new URL; the reviewer reproduced a false "no branch holds .codeo/11/init.md" against a fork. Cause: no `remote set-url` (or URL-keyed clone) before the fetch. Rare: the default URL is fixed and a fork user sets it before first use.
- **F10 — non-blocking — `/codeo:implement`'s.** `git cat-file -e <branch>:.codeo/<N>/init.md` (`:131`) lazily downloads the blob in the blob-less clone; a network failure there exits 128 and is read as "this branch does not hold it", so a transient failure can give a false "no branch holds", or, with two matching branches, pick the other as the single match. Cause: an existence check that needs the network and treats every failure as absence. `git rev-parse -q --verify "<branch>:<path>"` reads only trees the clone already has. Narrow window (right after a successful fetch), hence non-blocking; same class as round 1's F1.
- **F11 — non-blocking — `/codeo:implement`'s.** `codeo rm <N> --container` with no such container: `detect_kind` takes the flag unchecked, `docker start` fails, and the user reads "could not check codeo-N for unsaved work" (with `--force`: "could not remove volume") instead of "no container codeo-N".
- **F12 — non-blocking — `/codeo:implement`'s.** `container_check` (`:406-414`): when `docker ps` fails but `docker start` succeeds, a container that was already running is marked started and is stopped again on refusal. Needs a flaky daemon.
- **F13 — non-blocking — `/codeo:implement`'s.** `cmd_list` (`:338-342`) shows every docker state but `running` as `stopped`, so `paused` and `restarting` containers read as stopped.
- **F14 — non-blocking — `/codeo:implement`'s.** `.devcontainer/README.md`'s `codeo list` paragraph does not say that a failed listing prints a warning on stderr, withholds the "no issue containers or sandboxes" line and exits 1.
- **F15 — non-blocking — `/codeo:implement`'s.** `.devcontainer/README.md:99` still says "It is all or nothing" for `codeo update`, then describes the part-way case; round 1's F6 reworded only the changelog.
- **F16 — non-blocking — `/codeo:implement`'s.** `.sbx/README.md`'s `shell` and `open` rows do not show `--container|--sandbox`; the `rm` row does.
- **F17 — non-blocking — `/codeo:implement`'s.** Two comment lines in `.devcontainer/codeo` (about `:291` and `:438`) are overlong after the round 2 rewording.
- Reviewer's "declined to judge" list was read; nothing in it is a finding (stopped container `-` is F2; ignored files in the rm check and the sandbox branch read from the host clone are by design; real Docker/sbx is out of scope).

No issue was filed for this pass.

**Verdict: clear — forward to `/codeo:close`.**


### Round 3 — 2026-11-19

Re-checks `implement.md` round 3 (send-back from `close.md` round 2: the CI `tests` failure; fix commits `6c77860`, `b0999d9`), the whole pass again from step 0. HEAD `9156929`, merge base `fcda349`.

Commands run this pass:

```
role.sh --check qc: exit 0
sync-main.sh --abort-on-conflict: "sync-main: the branch already contains origin/main" (exit 0)
overlap.sh 133: nothing printed · overlap.sh --outside 133: nothing printed
scope.sh origin/main HEAD
  scope: suite shell needed for unclassified paths: .codeo/133/close.md, implement.md, init.md, issue.md, plan.md, qc.md, CHANGELOG.md
  suite.shell=true
no invariants, no qc overlay rules, no environment
build (suite shell, `true`): exit 0
bash tests/run.sh (suite shell, whole): exit 0 — "all cases passed"
PATH="<fake docker and sbx, each printing a line and exiting 0>:$PATH" bash tests/run.sh codeo-command: all cases passed (the CI condition)
github.sh pr checks 136 at 9156929: tests completed success · qc-verdict completed failure (the dossier is live during the send-back; close archives it)
```

The whole suite passes in this checkout this time, `live.test.sh` included.

Independent review (opus, description "QC review: …", given the criteria only): no Critical, no Important, six Minor; its verdict "With fixes", naming the CHANGELOG placement as the one item to fix. Each was checked against the code.

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | One download line installs `codeo`; `codeo help` prints the commands | met | `t_help_lists_commands`, `t_help_names_kind_flags` |
| 2 | `codeo update` replaces all three; a failed download changes nothing | met | `t_update_replaces_three`, `t_update_failed_download_changes_nothing` and the refused-file and partial-move cases |
| 3 | `home`, `shell`, `issue` run the container script from the `codeo` directory | met | `t_home_runs_script`, `t_runs_from_any_directory`, `t_shell_container` |
| 4 | `issue <N>` with no branch uses the origin branch carrying `.codeo/<N>/init.md`; none or several: one line, nothing created | met | `t_issue_branch_lookup_one`, `t_issue_lookup_none`, `t_issue_lookup_several`, `t_lookup_checks_file_without_blob`, `t_lookup_repoints_clone_at_url`; the reviewer re-ran the lookup with real git over `file://` |
| 5 | Container or sandbox by flag or saved default; sandbox create, open, shell, end reachable | met | `t_issue_sandbox_flag`, `t_issue_default_sandbox`, `t_open_sandbox`, `t_shell_sandbox`, `t_rm_sandbox` |
| 6 | `list` shows each container and sandbox with number and branch, nothing misleading when none | met | `t_list_rows`, `t_list_docker_down`, `t_list_sbx_down`, `t_list_one_down_nothing_shown`, `t_list_no_programs` (now isolated from host programs) |
| 7 | `rm` refuses naming unpushed or uncommitted work; removes container and volume, or the sandbox; override removes anyway | met | `t_rm_container_*`, `t_rm_container_not_found`, `t_rm_refusal_stops_started_container`, `t_rm_unlisted_state_not_stopped_by_us`, `t_rm_sandbox` |
| 8 | Bad number, missing argument, unknown command: usage line, non-zero exit, nothing run | met | `expect_usage` cases, `t_home_rebuild_twice_usage` |
| 9 | Stub test covering each command, argument errors, lookup none/one/several; `tests/run.sh` passes | met | `bash tests/run.sh`: exit 0, all cases passed; `t_run_path_has_no_host_programs`; CI `tests` check success at `9156929` |
| 10 | Both READMEs show the `codeo` forms beside the long ones; CHANGELOG entry | not met | F18: the entry is there but sits inside the `## Unreleased` header block and the blank line before `## v1.0.7` is gone; the READMEs are met (F23 non-blocking) |

**Documentation check.** `.devcontainer/README.md` and `.sbx/README.md` match the code on failed listings, the `paused`/`restarting` states, the kind flags and `update`; no "now", "no longer" or issue number. `CHANGELOG.md` is F18.

**Findings**

- F1 (blocking in round 1) — fixed by `bb31110`. The CI `tests` failure from `close.md` round 2 — fixed by `6c77860`: every test run uses `PATH=$cm_dir/bin:$cm_dir/sys`, and the suite passes with fake host programs first on `PATH` and on the CI runner. F9-F17 (non-blocking in round 2) — fixed by `b0999d9`.
- **F18 — blocking — `/codeo:implement`'s.** `CHANGELOG.md:3-13`: the `codeo` bullet sits between `## Unreleased` and its `Config schema: 1` / `Shared state: …` / `Safe to bump mid-workflow: yes` lines, after a double blank line, and the blank line before `## v1.0.7 — 2026-11-18` is gone. Every section on `origin/main` reads heading, blank line, those three lines, blank line, bullets; the release plans under `docs/plans/` rely on that shape, and on `main` the misplaced bullet would push the section's upgrade notes, which operators read before a bump, below an unrelated entry. Cause: the merges of `origin/main` (`2141d44`, `9b7ce8c`) brought in #126's header lines around this branch's bullet, and nothing re-placed it, against the agreement at plan Q6 and implement Q1 that whichever merges second keeps both entries intact. Needed: the bullet below `Safe to bump mid-workflow: yes` with the other bullets, one blank line after the heading, and the blank line before `## v1.0.7` restored.
- **F19 — non-blocking — `/codeo:implement`'s.** `.devcontainer/codeo:227-229`: when one listing fails and the other finds `codeo-<N>`, `shell`/`open`/`rm` use the found kind after a warning, so the "both exist, pick one" rule is skipped silently (reproduced: docker down, sbx lists `codeo-5`, `codeo rm 5` runs `codeo-sandbox.sh end 5`). Nothing is lost (`end` has its own check), and `t_shell_docker_down_sandbox_found` asserts the behaviour; requiring a kind flag in that case would be safer.
- **F20 — non-blocking — `/codeo:implement`'s.** `.devcontainer/codeo:431,477`: a detached HEAD alone makes `rm` refuse with "holds work that exists only there", which is untrue when that commit is on origin. Safe, but the message overstates.
- **F21 — non-blocking — the plan's.** `~/codeo` is also what `git clone` of this repository creates in `~`; there codeo writes its scripts, `default`, `.lookup.git` and `codeo-<N>` clones into the user's checkout. Documented (`CODEO_HOME`), nothing lost; a name choice from plan Q1.
- **F22 — non-blocking — `/codeo:implement`'s.** `tests/codeo-command.test.sh:67-68`: the git stub's comment still says `cat-file -e`; it answers `rev-parse`.
- **F23 — non-blocking — `/codeo:implement`'s.** `.devcontainer/README.md` (Installing): "Otherwise the exit status is the called script's" is not true for `list`, container `rm`, `default` or `update`, which call no script.
- Reviewer's "declined to judge" list was read; nothing in it is a finding (an `issue` lookup that finds none still creates `~/codeo` and `.lookup.git`, read as "creates no container or sandbox"; out-of-scope platforms; `codeo-sandbox.sh`'s own rules).
- Carried as deferred minors from `implement.md` round 3, not re-raised: `cm_sys` skips a missing tool silently; a few long comment lines.

No issue was filed for this pass.

**Verdict: back to `/codeo:implement`.**


### Round 4 — 2026-11-19

Re-checks `implement.md` round 4 (send-back from round 3; fix commit `27c68a2`), the whole pass again from step 0. HEAD `19544d8`, merge base `fcda349`.

Commands run this pass:

```
role.sh --check qc: exit 0
sync-main.sh --abort-on-conflict: "sync-main: the branch already contains origin/main" (exit 0)
overlap.sh 133: nothing printed · overlap.sh --outside 133: nothing printed
scope.sh origin/main HEAD: suite shell needed for unclassified paths (.codeo/133/*, CHANGELOG.md); suite.shell=true
no invariants, no qc overlay rules, no environment
build (suite shell, `true`): exit 0
bash tests/run.sh (suite shell, whole): exit 0 — "all cases passed"
PATH="<fake docker and sbx>:$PATH" bash tests/run.sh codeo-command: all cases passed
round 4's new tests against the round 3 code (scratch worktree at HEAD with .devcontainer/codeo from ab794d0):
  FAIL t_shell_docker_down_sandbox_found: exit 0, want 1 (and two more lines)
  FAIL t_rm_container_detached_pushed: exit 1, err: detached HEAD: (and two more lines)
  — both fail without the fix, so neither is vacuous
git diff origin/main -- CHANGELOG.md: only the added `codeo` bullet and its blank line
git log --format='%h %p %s' -3 origin/main: every commit has one parent (squash merges)
```

Independent review (opus, description "QC review: …", given the criteria only): no Critical, two Important, four Minor; its verdict "With fixes". Each was checked against the code.

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | One download line installs `codeo`; `codeo help` prints the commands | met | `t_help_lists_commands`, `t_help_names_kind_flags` |
| 2 | `codeo update` replaces all three; a failed download changes nothing | met | `t_update_replaces_three`, `t_update_failed_download_changes_nothing` and the refused-file and partial-move cases |
| 3 | `home`, `shell`, `issue` run the container script from the `codeo` directory | met | `t_home_runs_script`, `t_runs_from_any_directory`, `t_shell_container` |
| 4 | `issue <N>` with no branch uses the origin branch carrying `.codeo/<N>/init.md`; none or several: one line, nothing created | met | `t_issue_branch_lookup_one`, `t_issue_lookup_none`, `t_issue_lookup_several`; the reviewer re-ran it with real git |
| 5 | Container or sandbox by flag or saved default; sandbox create, open, shell, end reachable | met | `t_issue_sandbox_flag`, `t_issue_default_sandbox`, `t_open_sandbox`, `t_shell_sandbox`, `t_rm_sandbox` |
| 6 | `list` shows each container and sandbox with number and branch, nothing misleading when none | met | `t_list_rows`, `t_list_docker_down`, `t_list_sbx_down`, `t_list_one_down_nothing_shown`, `t_list_no_programs`; stopped-container branch `-` is F2 |
| 7 | `rm` refuses naming unpushed or uncommitted work; removes container and volume, or the sandbox, when there is none; override removes anyway | not met | F24: a container whose issue was squash-merged and whose branch `/codeo:close` deleted holds no unpushed work, yet `rm` refuses it as "commits not pushed to origin"; F25 non-blocking |
| 8 | Bad number, missing argument, unknown command: usage line, non-zero exit, nothing run | met | `expect_usage` cases, `t_home_rebuild_twice_usage` |
| 9 | Stub test covering each command, argument errors, lookup none/one/several; `tests/run.sh` passes | met | `bash tests/run.sh`: exit 0, all cases passed, also with fake host programs on `PATH` |
| 10 | Both READMEs show the `codeo` forms beside the long ones; CHANGELOG entry | met | `.devcontainer/README.md`, `.sbx/README.md`; `CHANGELOG.md` diff against `origin/main` is the one bullet |

**Documentation check.** The READMEs match the code on the round 4 changes (the exit-status sentence, the half-failed listing refusal); `CHANGELOG.md` has the section shape of `origin/main`. No "now", "no longer" or issue number in the READMEs.

**Findings**

- F18 (blocking in round 3) — fixed by `27c68a2`. F19, F20, F22, F23 (non-blocking in round 3) — fixed by `27c68a2`; F21 stands as the plan's.
- **F24 — blocking — `/codeo:implement`'s.** `container_check` (`.devcontainer/codeo:430,440`) fetches `origin` and lists `git rev-list --branches --not --remotes=origin`. This repository squash-merges (every commit on `origin/main` has one parent), and `/codeo:close` step 14 deletes the merged branch with `git push origin --delete <branch>` from the container's own checkout, which also removes its `refs/remotes/origin/<branch>`. The issue branch's commits are then on no origin ref, so `codeo rm <N>` on a finished issue prints them as "commits not pushed to origin" and dies "holds work that exists only there; nothing removed" — untrue, on the command's main use, and it teaches `--force`, which also skips the check for real unpushed work. The reviewer reproduced the ref state with real git. Cause: the check treats only branch refs as delivered; `codeo-sandbox.sh`'s `end` (`.sbx/codeo-sandbox.sh:387`) also fetches `+refs/pull/*/head:refs/remotes/origin/pr/*` first, so commits under a pull-request head count as delivered. The round 4 detached-HEAD check (`:437`, `branch -r --contains HEAD`) rests on the same refs and has the same gap. Needed: count pull-request heads as delivered in both checks, as the sandbox script does (a failed fetch of them is "could not check", never "clean"); a test where the branch's commits are only under a pull-request head and `rm` removes.
- **F25 — non-blocking — `/codeo:implement`'s.** For a sandbox, `codeo rm <N> --force` passes `--force` to `codeo-sandbox.sh end`, which still refuses when there is no clone `codeo-<N>` in `~/codeo` (a sandbox made by running the script from another directory) or when it cannot start or fetch the sandbox. Criterion 7's override holds for a sandbox `codeo` created; `codeo-sandbox.sh` cannot change, so `codeo` should at least say how to remove such a sandbox (`sbx rm --force codeo-<N>`) when `end` refuses.
- **F26 — non-blocking — `/codeo:implement`'s.** `codeo` looks for `sbx` only on `PATH` (`:193,201,333,357`) and ignores `CODEO_SBX`, which `codeo-sandbox.sh` honours; with `sbx` only at `CODEO_SBX`, `list`/`shell`/`open`/`rm` say none is installed or found.
- **F27 — non-blocking — `/codeo:implement`'s.** `rm` (`:500-506`): when `docker rm -f` succeeds but `docker volume rm` fails, the message does not say the container is already gone.
- **F28 — non-blocking — `/codeo:implement`'s.** A branch the lookup finds (`:262`) is not checked with `valid_branch`; an odd name reaches the script, which prints its own usage as if the user erred.
- F2 stands (stopped container's branch `-`, the plan's Q5; the reviewer again notes `docker cp` reads `.git/HEAD` from a stopped container).
- Reviewer's "declined to judge" list was read; nothing in it is a finding.

No issue was filed for this pass.

**Verdict: back to `/codeo:implement`.**

## Log

- 2026-11-19 — qc round 1: back to implement (F1 blocking: list/shell/open/rm read a failing docker/sbx as none) · cost: 6m · opus-5-5 355k in + 2.4M cached / 18k out · sonnet-5-5 37k in + 1.1M cached / 2k out
- 2026-11-19 — qc round 2: clear (F1 fixed; F9-F17 non-blocking) · cost: 6m · opus-5-5 226k in + 1.9M cached / 19k out
- 2026-11-19 — qc round 3: back to implement (F18 blocking: CHANGELOG entry misplaced by the main merges; CI fix and F9-F17 verified) · cost: 6m · opus-5-5 332k in + 2.2M cached / 21k out
- 2026-11-19 — qc round 4: back to implement (F24 blocking: rm refuses a squash-merged issue whose branch close deleted; F18 fixed) · cost: 6m · opus-5-5 385k in + 2.5M cached / 22k out
