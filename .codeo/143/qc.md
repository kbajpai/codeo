# Issue #143 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/143 |
| Branch | `fix/codeo-host-command-close-leftovers` |
| Updated | 2026-11-21 |

## Where this stands

Round 1 is written: back to `/codeo:implement` for F1 and F2 (blocking). F3-F11 are non-blocking. Nothing is open.

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

## Log
- 2026-11-21 — qc round 1: back to implement (F1 blocking: `rm --force` reports a container removed when `docker rm -f` of a missing one exits 0; F2 blocking: sandbox hint without `--force` claims kept commits and a working `--force` where neither holds; F3-F11 non-blocking) · cost: 6m · opus-5-5 253k in + 4.2M cached / 30k out
