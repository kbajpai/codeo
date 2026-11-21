# Issue #143 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/143 |
| Branch | `fix/codeo-host-command-close-leftovers` |
| Updated | 2026-11-21 |

## Where this stands

Round 2 written (send-back from qc.md round 1): F1, F2, F4, F5, F7, F8 fixed and F3 documented; build passes. Task 9 was run by the engineer on their host and its output is recorded in round 2. Nothing is open. Next step: `/codeo:qc`.

## Questions

None.

## Notes

Executed with `superpowers:subagent-driven-development`: one implementer and one task reviewer per task, a whole-branch review at the end, every dispatch on `sonnet` (`models.subagent`, never escalated). The branch already contained `origin/main` (`sync-main.sh` merged nothing) and `overlap.sh 143` printed nothing at the start of the round.

## Outcome

**Built (Tasks 1-8, ten commits `2674eab`..`83b0831`, then the fix wave `574e357`).** All code is in `.devcontainer/codeo` and `tests/codeo-command.test.sh`; `.devcontainer/codeo-container.sh` and `.sbx/codeo-sandbox.sh` are unchanged.

| Task | Commit | What |
|---|---|---|
| 1 | `2674eab` | the container check fetches with `--prune` (before the pull-request fetch) and reads `status --porcelain --untracked-files=normal` |
| 2 | `0fe670b` | `container_read` split out; a container that was running is restarted after a clean first read and read again before removal (Q1 A); a failed restart is "could not check" |
| 3 | `7c92ab1` | `workspace_mount` reads `/workspaces`'s mount with `docker inspect`; a volume that is not `codeo-<N>` is kept without `--force`; `rm` reports only what it removed and says `nothing named codeo-<N> to remove` when nothing existed (F30) |
| 4 | `91dd59a`, `e701de3` | sandbox hint chosen by `--force` (F29); the script's stderr is captured and replayed; exact-number match; temp file removed by a trap |
| 5 | `2994886` | per-process temp files for the script downloads, the lookup clone in its own `mktemp -d` under `flock` on `.lookup.lock`; the lookup checks `refs/heads/<branch>:…` |
| 6 | `23ef678`, `a4b1477` | `~/codeo` that holds a `.git` (directory or file) with `CODEO_HOME` unset stops with one line; relative `CODEO_CONTEXT`, `CODEO_SBX_IMAGE` (and `CODEO_SBX` when it has a `/`) made absolute before the `cd`; `default`'s `mkdir` error is one line |
| 7 | `d0120d6` | `rm` with one failing listing pinned both ways (F19); a 120-column comment guard |
| 8 | `83b0831` | `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md` |
| fix wave | `574e357` | after the whole-branch review: without `--force` the sandbox hint is left out when the script already names `sbx rm --force`; with `--force`, a failed `docker ps -a` listing is "could not remove container", not "nothing named …"; four wording minors |

**Documentation pages changed:** `.devcontainer/README.md` (the command tables, *Installing the `codeo` command*, *Removing a finished container* with its flowchart), `.sbx/README.md` (*Ending a sandbox*), `CHANGELOG.md` (the `codeo` bullet under `## Unreleased`, rewritten in place; the diff against `origin/main` is that one bullet).

**Build:** suite `shell`, build command `true`: exit 0. `bash -n .devcontainer/codeo`: ok. (The suites themselves are `/codeo:qc`'s; the implementers ran `bash tests/run.sh` per task and the fix wave's run printed `all cases passed`.)

**Deviations from the plan, and why**
- **F17 comment re-wrap (Task 7 step 3) was a no-op:** no comment line in `.devcontainer/codeo` was over 120 columns (the longest is 119). `t_comments_within_120_columns` pins it.
- **Q3's hint refined by the final review:** Q3 A chose the hint by `--force` alone; without `--force` the script's own `die_unreadable` message already says nothing is removed "with or without --force" and names `sbx rm --force`, which made `codeo`'s line false. The `codeo` line is now left out in that case (the same exact-number grep as the `--force` branch). This also settles the `.sbx/README.md` sentence it had contradicted.
- **Task 3:** `t_rm_force_container_gone`'s old `removed codeo-5` assertion was a false claim by the new rule and now expects `removed volume codeo-5`.
- **Task 5:** downloaded scripts are made executable (`mktemp` creates mode 0600); the plan did not say so. `flock` covers the lookup only, not the downloads (they are race-free by per-process temp file and an atomic rename), and the README says exactly that.
- **Task 6:** `cmd_list` calls `home_dir` first, so a collision stops `list` before it queries docker.

**Parked Minors, for `/codeo:qc`** (none blocks): a test's "no `.rm-err` file left" is a negative check that sends no signal; interrupts can leave a `.<name>.XXXXXX` or `.lookup.XXXXXX` temp file in `~/codeo` (nothing reads them); a stale `.lookup.git.part` is never cleaned; `shell`/`open`/`rm` run `detect_kind` before `ensure_home` (read-only); a broken `.git` symlink in `~/codeo` is not refused; the F19 test does not assert there is no direct `sbx rm`; the removal flowchart omits the `--force`, restart-failure and no-container branches (the prose covers them); `exec 9>file || die` in `find_branch` is reached only through bash's own error; the docker listing in `container_check` failing and then `docker start` succeeding treats the container as already running (rare, safe, commented).

**Not done:** Task 9 — the plan's run against real Docker on the engineer's host (single commands on throwaway issue 99999; the branch must be pushed first, which the dossier push does). The stub suite cannot show `--prune` against a real remote, `docker restart` or the `docker inspect` format; Task 9 is where that is shown, and its output is the engineer's to report.

### Round 2 — 2026-11-21
(send-back from qc.md round 1)

**Built (two commits, `db9bcea`, `b545c0f`).** Each QC finding was checked against the code before work started; F1, F2, F3, F4, F5, F7 and F8 held and were fixed, F6, F9, F10 and F11 were not (see below). `.devcontainer/codeo-container.sh` and `.sbx/codeo-sandbox.sh` are unchanged.

| Finding | What changed |
|---|---|
| F1 (blocking) | `cmd_rm` counts the container as removed only when `docker rm -f` exited 0 and the container was known to exist: `container_check` rc 0 or 1 means it was read, rc 3 means a working listing showed no such name, rc 2 (`--force` only) asks `docker ps -a` itself, and a failing listing is treated as existed. `docker rm -f` of a missing container exits 0, so its exit status alone says nothing |
| F2 (blocking) | Without `--force` the hint `codeo rm <N> --force removes it anyway; its unpushed commits are kept in <home>/codeo-<N>, its uncommitted work is not` is printed only when no line of the script's captured stderr starts with `codeo-sandbox: ` (every refusal that is not over unpushed or uncommitted work is a `die`, which writes that prefix); the `--force` branch is unchanged. Both READMEs and the changelog bullet say the same |
| F4 | the final `removed …` line joins its items with `, ` and no trailing separator |
| F5 | `kept volume codeo-<N>` is printed only when `docker volume inspect` finds that volume |
| F7 | INT and TERM replay the captured stderr before exiting; a failing `mktemp` dies with `could not create a temporary file in <home>` |
| F8 | `.devcontainer/README.md` says the `/` condition belongs to `CODEO_SBX` only |
| F3 | `.devcontainer/README.md` says `shell`, `open` and `rm` stop and ask for `--container` or `--sandbox` when one listing failed. `.sbx/README.md` has no sentence on which kind is used, so it has no clause |

**Tests:** seven new cases (`t_rm_force_missing_container_rm_succeeds`, `t_rm_force_unchecked_container_counts_as_removed`, `t_rm_report_joins_items`, `t_rm_bind_mount_without_volume_says_nothing`, `t_rm_sandbox_no_hint_on_die`, `t_rm_sandbox_work_refusal_hint`, `t_rm_sandbox_interrupt_replays_stderr`); each was red before its fix. `t_rm_sandbox` and `t_rm_sandbox_hints` use exact-line matches. The stub's `docker start` now also fails when a container is `gone`, which models a missing container. The implementer ran `bash tests/run.sh` once after the code commit: `all cases passed`.

**Documentation pages changed:** `.devcontainer/README.md` (the relative-path sentence, the kind-choice sentence, the sandbox hint paragraph), `.sbx/README.md` (*Ending a sandbox*), `CHANGELOG.md` (the `codeo` bullet; the diff against `origin/main` is still that one bullet).

**Build:** suite `shell`, build command `true`: exit 0. `bash -n .devcontainer/codeo`: ok. The suites are `/codeo:qc`'s.

**Not changed, with the reason**
- F6 (`docker restart` runs before `docker inspect`) is the plan's ordering and was classed non-blocking and the plan's.
- F9 (the flowchart omits some branches) and F11 (the parked minors from round 1) are non-blocking and unchanged.
- The `rc 2` path with a listing that works and lacks the name (`existed=0`) has no test: the stub cannot reach it.
- The task review's Minors: a failure that writes no `codeo-sandbox: ` line (`bash` unable to run the script, a signal kill) also gets the "kept" hint, which is unlikely because `ensure_home` installs the script first.

**Not done:** Task 9, the run against real Docker on the engineer's host. It also settles `docker rm -f` of a missing container on their Docker version.

**Task 9, run by the engineer on their host (real Docker, `codeo-branch` downloaded from the pushed branch at `52a5a11`, issue `99999`, every `rm` with `--container` because `sbx` was not signed in).** Step 0 cleared a leftover from a first attempt, in which `rm 99999` without a kind flag stopped with `could not ask docker or sbx whether codeo-99999 exists as the other kind` (the rule for a failed listing, working as designed; the plan's steps 4-6 omitted the flag).
- Step 2: `issue 99999 main --container` built, cloned and printed the home-container and login TODO lines (expected for `main` with no lock).
- Step 3: `list` printed `#143  container  running  …` and `#99999  container  running  main`, then `codeo: could not list sbx sandboxes` / `error: not signed in to Docker`.
- Step 4: with `untracked.txt` created in the container, `rm 99999 --container` printed `uncommitted or untracked files:` / `?? untracked.txt` and `codeo: codeo-99999 holds work that exists only there; nothing removed (codeo rm 99999 --force removes it anyway)`, exit 1; `docker ps` still listed `codeo-99999`.
- Step 5: with `status.showUntrackedFiles no` set in the clone, the same output and exit 1 (the setting does not hide the file).
- Step 6: with the file removed, `docker ps` showed `codeo-99999  Up 46 seconds`; `rm 99999 --container` printed `removed codeo-99999 (the Claude Code login on its volume is gone with it)`, exit 0; neither `docker ps -a` nor `docker volume ls` listed `codeo-99999` afterwards. The restart itself was not observed (no `docker events` capture), so `docker restart` is shown only by the removal succeeding after it.
- Step 7: `rm 99999 --container --force` printed `--force: no container codeo-99999 found; removing its volume and image anyway` and `codeo: nothing named codeo-99999 to remove`, exit 1, and no line saying `removed container` (a real `docker rm -f` of a missing container exited 0 here, the case QC round 1 F1 was about).
The plan's Task 9 text omits `--container` on its `rm` steps; the plan is not edited here.

## Log
- 2026-11-21 — implemented: Tasks 1-8 (10 commits + 1 fix wave), build exit 0, Task 9 left to the engineer · cost: 88m · sonnet-5-5 1.1M in + 29.3M cached / 203k out
- 2026-11-21 — implemented round 2 (send-back from qc round 1): F1, F2, F4, F5, F7, F8 fixed, F3 documented, 2 commits, build exit 0, Task 9 left to the engineer · cost: 11m · sonnet-5-5 317k in + 4.3M cached / 34k out
