# Issue #133 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/133 |
| Branch | `feat/codeo-command-host-short-bash` |
| Updated | 2026-11-19 |

## Where this stands

Round 1 is written and the change goes back to `/codeo:implement`: one blocking finding (F1). Nothing is open.

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

## Log

- 2026-11-19 — qc round 1: back to implement (F1 blocking: list/shell/open/rm read a failing docker/sbx as none) · cost: 6m · opus-5-5 355k in + 2.4M cached / 18k out · sonnet-5-5 37k in + 1.1M cached / 2k out
