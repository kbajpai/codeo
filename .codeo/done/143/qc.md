# Issue #143 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/143 |
| Branch | `fix/codeo-host-command-close-leftovers` |
| Updated | 2026-11-21 |

## Where this stands

Round 2 is written: clear, forward to `/codeo:close`. No blocking finding; F12-F16 are non-blocking. Nothing is open.

## Questions

None.

## Notes

See round 1 under `## Outcome` for the commands and their output.

## Outcome

### Round 1 — 2026-11-21

Under review: `implement.md` round 1, `2e02100..4378b6f` (merge base `2e02100a256de327d5f85d51d57db98a98672da1`).

**Commands run this pass**

```
bash .devcontainer/scripts/role.sh --check qc: exit 0
sync-main.sh --abort-on-conflict: "sync-main: the branch already contains origin/main" (exit 0, nothing merged)
overlap.sh 143: no output (exit 0)
overlap.sh --outside 143: no output (exit 0)
scope.sh origin/main HEAD:
  scope: suite shell needed for unclassified paths:
    .codeo/143/implement.md
    .codeo/143/init.md
    .codeo/143/issue.md
    .codeo/143/plan.md
    CHANGELOG.md
  suite.shell=true
build (suite shell, `true`): exit 0
bash tests/run.sh (suite shell, whole): "all cases passed", exit=0
```

No shared environment, no invariants file, no `wiki` module are configured, and the `qc` overlay has no `invariants-extra` or `wiki-rules` text (exit 3 each): step 9 does not apply, and the documentation check uses the conventions of the existing pages. `.codeo/143/issue.md` still fails `dossier-check.sh` (log format, header); that predates this round and is not this diff's.

The independent review (opus, given the acceptance criteria and the diff only) answered "Ready to merge? With fixes". Its findings are folded into F1-F11 below after checking each against the code.

**Criteria**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Sandbox hint names `sbx rm --force` only when the refusal was not over work (F29) | met | `codeo:559-566`: without `--force` `codeo` never prints `sbx rm --force`; `t_rm_sandbox`, `t_rm_sandbox_hints`. The other hint it prints there can be false: F2 |
| 2 | `rm <N> --container --force` with no container never says a container was removed (F30) | not met | F1: `codeo:612-613` counts `docker rm -f`'s exit 0 as a removal, and `docker rm -f` of a missing container exits 0 (docker/cli #2678) |
| 3 | One listing fails and the other lists `codeo-<N>`: `rm` does not run until a kind is named (F19) | met | `detect_kind` `codeo:266`; `t_rm_one_listing_fails_needs_a_kind` (both directions) |
| 4 | The check is not clean on a stale remote-tracking ref alone, and sees new files under `showUntrackedFiles=no` | met | `fetch --prune origin` before the pull-request fetch (`codeo:503`), `status --porcelain --untracked-files=normal` (`codeo:456`); `t_rm_check_prunes_and_sees_untracked` (arguments and order; real git is Task 9's, see F10) |
| 5 | A write between the check and removal is not lost without `--force`, or the plan records why it cannot be prevented | met | restart and second read, `codeo:507-513`; `t_rm_restarts_running_container_and_reads_again`, `t_rm_write_after_check_refused`, `t_rm_restart_fails`; `plan.md` Q1 records that the window is narrowed, not closed, and why (closing it needs option B, a helper-container rewrite) |
| 6 | Two first-use commands started together both succeed with complete script and lookup clone | met | `ensure_home` per-process `mktemp` plus rename; `find_branch` under `flock`, clone in `mktemp -d`; `t_concurrent_first_use`, `t_lookup_clone_atomic` |
| 7 | F3, F4, F7, F8, F11, F12, F13, F20, F27, F28 and threads …636234, …636301, …636455, …636698 fixed or ruled out in the plan dossier | met | `plan.md` Q5 table, one row each (lines 68-97) |
| 8 | F26 and threads …636595, …636654 confirmed fixed and dropped | met | `plan.md` Q5 rows at lines 77-79; …636654's remainder fixed with `refs/heads/` (`t_lookup_checks_file_without_blob`) |
| 9 | Help and both READMEs show the kind flags; failed listing warns and exits 1; no "all or nothing"; changelog describes the command; F17, F22, F23 corrected; F21 documented or avoided | met | flags in help (`codeo:78-82`) and both READMEs' tables; failed listing for `list` at `.devcontainer/README.md:124`; `grep -i "all or nothing"` finds nothing; CHANGELOG bullet rewritten; F17: no comment over 120 columns (`t_comments_within_120_columns`); F22, F23 ruled out in Q5; F21 avoided (`t_home_checkout_collision`, `t_home_checkout_collision_git_file`). Gap in what the pages say about a failed listing for `shell`/`open`/`rm`: F3 |
| 10 | Tests cover each changed behaviour | not met | F1's case (a missing container whose `docker rm -f` exits 0) is not modelled: every F30 test sets `rm_fail`. The single-item `removed …` line is untested (F4) |

**Findings**

- **F1 — blocking — `/codeo:implement`'s.** `.devcontainer/codeo:612-613`: `removed_container=1` is set whenever `docker rm -f` exits 0. The Docker CLI has returned exit 0 for `docker rm -f` of a container that does not exist since docker/cli #2678 (2020); it only prints the not-found error. So in the `rc=3` path, where `container_check`'s working listing has already shown there is no container, `rm 5 --container --force` reports a container removal: `removed codeo-5 (the Claude Code login on its volume is gone with it)` when the volume exists, `removed container codeo-5, ` when it does not. The `rc=2` `--force` path (the listing failed) has the same root. Root cause: removal is inferred from `rm`'s exit status, which does not tell "removed" from "was not there". The plan's text asks that "the last line names only what was removed" and that the volume message "never says a container was removed", so this is the code not doing what the plan says. The plan's test specs (`rm_fail` on every F30 test) modelled the old behaviour, which is why the suite passes; the fix round needs a test with the stub's default `rm` (exit 0) plus `gone`.
- **F2 — blocking — `/codeo:implement`'s.** `.devcontainer/codeo:562-563`: without `--force`, every non-zero `codeo-sandbox.sh end` not naming `sbx rm --force` gets `its commits are kept in <home>/codeo-<N>; codeo rm <N> --force removes it anyway`. That is false when the script refused with `no clone codeo-<N> here: …` (`.sbx/codeo-sandbox.sh:381`): the directory does not exist, and `end --force` dies at the same line. It is also false for `no sandbox codeo-<N>` with `--sandbox`, and for the `could not fetch origin` / `pull-request heads` / `could not read the refs` / `could not list the commits` / `could not check … for uncommitted work` refusals (`:386-395`), all of which `--force` hits too. When the refusal is over uncommitted work only (`:404`), "its commits are kept" suggests `--force` is safe when it discards that work. Plan Q3 A worded it as `… and keeps its commits in ~/codeo/codeo-<N> when it can read them`. The code dropped the hedge, which is a departure from the plan. The same unconditional wording is in `.devcontainer/README.md` (last sandbox paragraph of *Removing a finished container*) and `.sbx/README.md:78`. This is false output of the kind this issue exists to remove.
- **F3 — non-blocking — `/codeo:plan`'s.** `.devcontainer/README.md:122` says of `shell`, `open` and `rm` "When only one exists it is used". When the other program's listing failed, `detect_kind` (`codeo:266`) instead refuses and asks for a flag, and no page says so. Plan Q5 read criterion 9's failed-listing clause as `list` only (F14); `.sbx/README.md` defers to `.devcontainer/README.md` for the command. One sentence would cover it.
- **F4 — non-blocking — `/codeo:implement`'s.** `codeo:646`: `printf ', %s' "${went[@]:1}"` with no further items prints `, `, so every single-item report ends `removed volume codeo-5, ` (checked: `went=("volume codeo-5")` prints `[removed volume codeo-5, ]`). Tests match substrings and miss it.
- **F5 — non-blocking — `/codeo:implement`'s.** `codeo:619-623`: with `/workspaces` not the volume and no `--force`, `kept volume codeo-<N> … docker volume rm codeo-<N>` is printed even when no such volume exists.
- **F6 — non-blocking — `/codeo:plan`'s.** `codeo:507-511` vs `:593-611`: `docker restart`, which ends the engineer's shells and agents, runs before `docker inspect`; when inspect then fails without `--force`, nothing is removed but the sessions were already ended. The plan orders the mount check after the check.
- **F7 — non-blocking — `/codeo:implement`'s.** `codeo:550-557`: the sandbox script's stderr is held in a file until it exits; on Ctrl-C the EXIT trap deletes it unprinted, so the script's lines are lost. A failing `mktemp` exits under `set -e` with no message.
- **F8 — non-blocking — `/codeo:implement`'s.** `.devcontainer/README.md:98`: "A relative `CODEO_CONTEXT`, `CODEO_SBX_IMAGE` or `CODEO_SBX` that holds a `/`" reads as if the `/` condition applies to all three; the code makes the first two absolute always. The CHANGELOG wording is right.
- **F9 — non-blocking — `/codeo:implement`'s.** The *Removing a finished container* flowchart omits the `--force` branches, the restart failure and the no-container case (the prose covers them), so it is a partial picture rather than a wrong one. Not rendered here: no renderer is installed and no project rule asks for one.
- **F10 — non-blocking — neither's: engineer's.** Task 9, the run against real Docker on the host, has not been run. The stub suite cannot show `--prune` against a real remote, `docker restart`, the `docker inspect` format, or (F1) real `docker rm -f` exit codes. Nothing here needs it to judge F1, but it is the plan's only real-Docker evidence.
- **F11 — non-blocking — `/codeo:implement`'s.** The minors parked in `implement.md` (an interrupt leaving `.<name>.XXXXXX`/`.lookup.XXXXXX` temp files, a stale `.lookup.git.part`, `detect_kind` before `ensure_home`, a broken `.git` symlink not refused, the weak F19 negative assertion, `exec 9>file || die`, a failed listing then a successful `docker start`) were read and none blocks.

The reviewer's verdict, quoted: "Ready to merge? With fixes."

**Routing.** F1 breaks criterion 2 outright on any Docker since 2020, and F2 prints false advice on the commonest sandbox refusals. Both are small changes to `cmd_rm`, and each needs one test that models the real behaviour. F4, F5, F7 and F8 are cheap to fix in the same round. F3 and F6 are the plan's but do not block.

**Verdict: back to `/codeo:implement`.**

### Round 2 — 2026-11-21

Under review: `implement.md` round 2, `2e02100..5cb1e5d` (merge base `2e02100a256de327d5f85d51d57db98a98672da1`). Round 1's findings F1 and F2 were the send-back; this pass re-ran everything from step 0.

**Commands run this pass**

```
bash .devcontainer/scripts/role.sh --check qc: exit 0
sync-main.sh --abort-on-conflict: "sync-main: the branch already contains origin/main" (exit 0, nothing merged)
overlap.sh 143: no output; overlap.sh --outside 143: no output
scope.sh origin/main HEAD:
  scope: suite shell needed for unclassified paths:
    .codeo/143/implement.md, init.md, issue.md, plan.md, qc.md, CHANGELOG.md
  suite.shell=true
build (suite shell, `true`): exit 0
bash tests/run.sh (suite shell, whole): "all cases passed", exit=0, no FAIL line
git diff origin/main...HEAD --stat -- .devcontainer/codeo-container.sh .sbx/codeo-sandbox.sh: empty (both unchanged)
```

No shared environment, invariants file, `wiki` module or `qc` overlay text (exit 3 each): step 9 does not apply. The engineer's real-Docker run of plan Task 9 (recorded in `implement.md` round 2) is quoted below where it settles a criterion; it is the engineer's evidence, not a command this pass ran.

The independent review (opus; acceptance criteria and diff only) answered "Ready to merge? With fixes", with no Critical issue and three Important ones. Each is checked against the code below; one was reproduced here with a probe.

**Criteria**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Sandbox hint names `sbx rm --force` only when the refusal was not over work (F29) | met | `codeo:559-566`: a work refusal (stdout, no `codeo-sandbox: ` line) never gets `sbx rm --force`; `t_rm_sandbox`, `t_rm_sandbox_hints`, `t_rm_sandbox_work_refusal_hint`, `t_rm_sandbox_no_hint_on_die`. Hint accuracy in rare `--force` paths: F4 |
| 2 | `rm <N> --container --force` with no container never says a container was removed (F30) | met | `existed`/`removed_container`, `codeo:594-603`, `:623-625`; `t_rm_force_missing_container_rm_succeeds` (stub `rm` exits 0, container gone); the engineer's real-Docker step 7: `--force: no container codeo-99999 found …`, `codeo: nothing named codeo-99999 to remove`, exit 1, no "removed container" line |
| 3 | One listing fails, the other lists `codeo-<N>`: `rm` does not run until a kind is named (F19) | met | `detect_kind` `codeo:266`; `t_rm_one_listing_fails_needs_a_kind`; seen on the engineer's host when `sbx` was not signed in: `codeo: could not ask docker or sbx whether codeo-99999 exists as the other kind; pick one with --container or --sandbox` |
| 4 | The check is not clean on a stale remote-tracking ref alone, and sees new files under `showUntrackedFiles=no` | met | `fetch --prune origin` (`codeo:503`), `--untracked-files=normal` (`codeo:456`); `t_rm_check_prunes_and_sees_untracked`; real Docker steps 4 and 5: `?? untracked.txt` named, exit 1, with `status.showUntrackedFiles no` set. The stale-ref case itself is covered with arguments only, not against real git |
| 5 | A write between the check and removal is not lost without `--force`, or the plan records why not | met | restart and second read, `codeo:507-513`; `t_rm_restarts_running_container_and_reads_again`, `t_rm_write_after_check_refused`, `t_rm_restart_fails`; `plan.md` Q1 records that the window is narrowed, not closed. The restart itself was not observed on the host (no `docker events` capture); the removal after it succeeded (real step 6) |
| 6 | Two first-use commands started together both succeed with complete script and lookup clone | met | `ensure_home` per-process `mktemp` plus rename, `find_branch` under `flock`; `t_concurrent_first_use`, `t_lookup_clone_atomic` |
| 7 | F3, F4, F7, F8, F11, F12, F13, F20, F27, F28 and threads …636234, …636301, …636455, …636698 fixed or ruled out in the plan dossier | met | `plan.md` Q5 table rows (lines 68-97). The …636698 fix does not cover a relative `CODEO_HOME` (F14 below), which that thread did not name |
| 8 | F26 and threads …636595, …636654 confirmed fixed and dropped | met | `plan.md` Q5 lines 77-79; `t_lookup_checks_file_without_blob` |
| 9 | Help and both READMEs show the kind flags; a failed listing warns on stderr and exits 1; no "all or nothing"; changelog describes the command; F17, F22, F23 corrected; F21 documented or avoided | met, with a gap | flags in help (`codeo:76-81`) and both READMEs; failed listing stated for `list` and for `shell`/`open`/`rm` in `.devcontainer/README.md:122-124`; no "all or nothing"; CHANGELOG bullet rewritten; `t_comments_within_120_columns`; F21 avoided (`t_home_checkout_collision*`). Gap: `.sbx/README.md` and the help text do not say it (F5) |
| 10 | Tests cover each changed behaviour | met | the round 1 gap is closed (`t_rm_force_missing_container_rm_succeeds`, `t_rm_report_joins_items` with exact-line matches, `t_rm_bind_mount_without_volume_says_nothing`, `t_rm_sandbox_*`, `t_rm_sandbox_interrupt_replays_stderr`). No test covers a relative `CODEO_HOME` or the `--force` hint after a partial failure (F3, F4) |

**Round 1 findings, recapped**
- F1 (blocking in round 1) — fixed by `db9bcea`: a container is counted as removed only when it was known to exist; confirmed on real Docker.
- F2 (blocking in round 1) — fixed by `db9bcea`, `b545c0f`: the "kept" hint appears only for a refusal over unpushed or uncommitted work; READMEs and changelog agree.
- F4, F5, F7, F8 (non-blocking in round 1) — fixed by `db9bcea`/`b545c0f`; F3 (non-blocking in round 1) — documented in `.devcontainer/README.md:122`. F6, F9, F10, F11 stay as recorded in round 1; F10 is now answered by the engineer's host run (restart not observed).

**New findings this round**
- **F12 — non-blocking — `/codeo:implement`'s.** `.devcontainer/README.md:202` says that when the script could not read or reach the sandbox, "the script's own `codeo-sandbox: ` message says what to do then". It does for `die_unreadable` and the no-refs refusal (`.sbx/codeo-sandbox.sh:366`, `:390`); it does not for `no clone … nothing removed` (`:381`), `could not fetch origin` / `pull-request heads` (`:386`, `:387`), `could not list the commits` and `could not check … uncommitted work` (`:392`, `:395`), which name no command. In those cases `codeo` prints no hint without `--force`. The comment at `codeo:561-562` ("--force would not get past it") is also wrong for the no-refs refusal, which `--force` passes. Criterion 1 says "only when", so printing nothing meets it; the sentence in the README is what is untrue. Nothing is lost by it.
- **F13 — non-blocking — `/codeo:implement`'s.** `codeo:564-566`: with `--force`, the hint `to remove it anyway, discarding whatever it holds: sbx rm --force codeo-<N>` is also printed after `codeo-sandbox: removed codeo-<N>, but could not set aside its refs …` (`.sbx/codeo-sandbox.sh:412`, `:416`), when the sandbox is already gone, and after `codeo-sandbox: no sandbox codeo-<N>`. Reproduced by the reviewer with a stub. It is advice to remove something already removed, on a rare partial-failure path; the form of the hint predates this change.
- **F14 — non-blocking — `/codeo:implement`'s.** A relative `CODEO_HOME` breaks `codeo rm <N>` of a sandbox: `cd "$(home_dir)"` is followed by calls to `home_dir`, which reads a relative value against the new directory. Reproduced here: `CODEO_HOME=rel codeo rm 5 --sandbox` → `mktemp: failed to create file via template '…/work/rel/rel/.rm-err.XXXXXX'` / `codeo: could not create a temporary file in …/rel/rel`, exit 1. The doubled path on the script line predates this change (`bash "$(home_dir)/codeo-sandbox.sh"` after the `cd`); the new `mktemp` line meets it first. Thread …636698 and the README name `CODEO_CONTEXT`, `CODEO_SBX_IMAGE` and `CODEO_SBX`, not `CODEO_HOME`. It fails loudly and removes nothing.
- **F15 — non-blocking — `/codeo:plan`'s.** `.devcontainer/README.md` says `codeo` "stops with one line" when `~/codeo` is a git checkout and `CODEO_HOME` is unset; `codeo rm <N>` of a container never reads the home directory, so it goes ahead (it writes nothing there). The stop is documented for every command but is not applied to that one. Criterion 9 only asks that the collision be documented or avoided.
- **F16 — non-blocking — `/codeo:plan`'s.** `.sbx/README.md` and the help text do not say that a failed listing warns on stderr and exits 1; the plan's Q5 scoped that criterion clause (F14) to `.devcontainer/README.md`. Criterion 9's wording lists help text and both READMEs; the engineer may judge that the plan's scoping was too narrow.
- **Parked from round 1 and re-seen by the reviewer, unchanged:** the restart runs before the mount check (F6), temp files left by an interrupted download or clone, a failed `docker volume inspect` read as "no volume" (it prints nothing false).

**Routing.** Nothing blocks. Every criterion is met on the tests and on the engineer's real-Docker run; the findings above print or say something inexact in rare paths (a sandbox refusal that names no remedy, a `--force` hint after the sandbox is already gone, one README sentence) or fail loudly on an uncommon setup (a relative `CODEO_HOME`), and none loses unsaved work. F12-F16 are recorded here and reach `/codeo:triage` through this dossier once it is archived; the engineer may instead send the change back for F12-F14, which are small and local to `cmd_rm` and one README sentence.

**Verdict: clear — forward to `/codeo:close`.**

## Log
- 2026-11-21 — qc round 1: back to implement (F1 blocking: `rm --force` reports a container removed when `docker rm -f` of a missing one exits 0; F2 blocking: sandbox hint without `--force` claims kept commits and a working `--force` where neither holds; F3-F11 non-blocking) · cost: 6m · opus-5-5 253k in + 4.2M cached / 30k out
- 2026-11-21 — qc round 2: clear (F1, F2 fixed and confirmed on real Docker; F12-F16 non-blocking) · cost: 6m · opus-5-5 86k in + 1.2M cached / 21k out · sonnet-5-5 24k in + 1.8M cached / 11k out
