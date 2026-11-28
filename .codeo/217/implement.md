# Issue #217 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/217 |
| Branch | `feat/217-add-codeo-go-codeo-done` |
| Updated | 2026-11-28 |

## Where this stands

Round 2 (send-back from `qc.md` round 1), done. F1-F11 are fixed and reviewed; the tree builds. Next step: `/codeo:qc`.

## Questions

### Q1 — #181 overlaps on `.devcontainer/README.md` and `CHANGELOG.md`: proceed, sequence, or re-scope?

**Why it matters:** round 2 edits `.devcontainer/README.md` (F4: four untrue statements in its `codeo go` section, F7/F9 sentences) and `CHANGELOG.md` (the entry for the fixes). `overlap.sh 217` printed `181	glob:.devcontainer/README.md` and `181	glob:CHANGELOG.md`. #181 (branch `feat/181-session-title-prefix-session-id`, assignee kbajpai, step `plan` (working), waiting on `/codeo:implement`) lists both files in its footprint beside `.devcontainer/scripts/session-title.sh` and `tests/devcontainer.test.sh`. Both change different sections of the README and add a changelog entry, so the second to merge resolves the overlap at its sync and its `/codeo:qc` re-runs the suite on the merged tree.

- Proceed and coordinate: both go on; whichever merges second resolves the two files.
- Sequence after #181: this round waits until #181 merges, then syncs and builds; #181 is only at `plan`, so the wait is open-ended.
- Re-scope: the F4 documentation fixes cannot move out of `.devcontainer/README.md` without leaving untrue statements in it.

I recommend proceeding and coordinating.

**Options:** proceed and coordinate (recommended) · sequence after #181 · re-scope.

**Answer:**
Proceed and coordinate, as recommended. Given in the conversation: "go with your picks".

## Notes

- Task 8's live case could not be run by the test file on the engineer's Mac (the suite assumes Linux tools: `flock`, GNU `stat` and `sed`, unresolved `/var` paths), so on 2026-11-28 the engineer ran its two checks by hand there with the plugin at v1.0.8: `claude -p` lists `codeo:init` among its slash commands, and `claude -p … --output-format json --permission-prompts none --allowedTools Skill Read Glob Grep Write Edit Bash --max-turns 1` returned `subtype` success, `is_error` false and no `permission_denials`. That proves the command is listed and the flags are accepted together; it does not yet prove that `/codeo:init #<N> --approved` runs headless, which needs a plugin release that has `--approved` and a real `codeo go`.
- The macOS keychain check is stubbed in the tests and not verified on a real Mac, as the issue allows.

## Outcome

**Built.** All nine tasks, in order, one commit per task and per fix round (`a7fa31c`..`6658163`, fifteen commits on top of `ff9a3ef`).

| Task | Built |
|---|---|
| 1 | `CODEO_VERSION`, `codeo --version` and `-v`, a test that it equals `.claude-plugin/plugin.json` (both copies of `codeo`) |
| 2 | `codeo update` prints downloads, then `version: <old> -> <new>`, then installs, and the unchanged last line |
| 3 | `keychain_check`, `home_clone`, `plugin_root`; `CODEO_HOME_CLONE` |
| 4 | `cleanup.sh prove <N>` |
| 5 | `codeo done <N>`: proofs, `cmd_rm` (never `--force`) in a subshell, then the removal record; a record failure is a warning |
| 6 | `/codeo:init #<N> --approved`, rule `init-12`, inventory line, regenerated hash |
| 7 | `codeo go <N>`: keychain, home, branch, board, init, verify, container; `branches_for` split out of `find_branch` |
| 8 | the opt-in live case plus two canned cases for its stream parsing |
| 9 | documentation, release checklist step 6, `CHANGELOG.md` `## Unreleased` |

**Documentation changed.** `.devcontainer/README.md` (command list, `update` output, a new *Starting and finishing an issue with one command* section with the flow diagram, the keychain section, what the headless run may do), `README.md`, `docs/home-checkout.md`, `docs/release-checklist.md` step 6, `CHANGELOG.md`, and for `init-12` `docs/skills-inventory.md` and `docs/skills.md`.

**Build result.** The `shell` suite's `build` is `true`: exit 0. The test files were run by the task implementers; grading them is `/codeo:qc`'s.

**Deviations from the plan, and why.**
- `tests/inventory.test.sh` changed (the init rule count 11 → 12) and is not in the plan's footprint; `bash tests/inventory.test.sh` fails without it. `overlap.sh 217` is clean, but #207 also lists this file, so the footprint in `plan.md` needs it added and the overlap with #207 is the same *proceed and coordinate* as Q7/Q8.
- `codeo update` prints the `version:` line after the downloads, not first: the new version is only known from the downloaded file. The plan's Produces list and its Step 3 disagreed; Step 3 governs.
- `cmd_rm` runs in a subshell inside `done` (the plan said "same shell"): its sandbox branch ends with `exit`, which would skip the record.
- `go` reports a failed `plugin_root` under the step name `home`; and `go`'s `board not configured` line reads `codeo: go: board: not configured, skipped`.
- Two Task 3 tests were edited because a home failure now reads `codeo: go: home: …`.
- `t_version_flags_print_the_constant` derives its version from `plugin.json` (Task 9) so a release needs no edit there.
- Task 8's added canned cases (`t_init_check_*`) and the shared `check_init_command` function are beyond the plan's single case; they prove the stream parsing without `claude`.

**Left as minor, not fixed.** Untested branches in `go` (a failing `board.sh set`, a missing `jq`, a custom Backlog name); no timeout on the headless call (documented); a weak test that `prove` ignores the overlay; help-column alignment; two near-duplicate argument loops in `go` and `done`; a long line at `skills/init/SKILL.md:121`.

**Rulings made.** The plan's Produces/Step 3 order for `update` (above); `prove`'s exit status for a failed proof is 0, so a non-zero exit is an error, not a failed proof; the headless flags are not a code defect: `claude --help` lists them, and the live check is the engineer's.

### Round 2

2026-11-28
(send-back from qc.md round 1)

**Built.** F1-F11 of `qc.md` round 1, in three commits (`9f8c487`, `8abaf2f`, `0a5f631`), each finding checked against the code first (F1, F2, F3, F7, F8 and F10 by reading it, the rest from the reviewer's account), each fix written test-first, then reviewed: every finding came back fixed, with no Critical or Important issue. The base-branch sync merged nothing: the branch already contains `origin/main`. `overlap.sh 217` printed `181` on `.devcontainer/README.md` and `CHANGELOG.md`, answered in Q1 as *proceed and coordinate*.

| Finding | Fix |
|---|---|
| F1 blocking | `cmd_go` creates `CODEO_HOME` (`mkdir -p`, no script download) before the branch lookup; one `go: home:` line when it cannot |
| F2 blocking | the Ready and Backlog names are read from `board.statuses`, and the refusal names them |
| F4 blocking | the four untrue statements in `.devcontainer/README.md`'s `codeo go` section corrected: result text follows the failure line, `verify` has its own failure node, `--approved` no longer covers "the lock", the engineer's own settings also apply to the headless run |
| F3 | the last line of `claude`'s stderr is in `go: init: claude exited <rc>: …` |
| F5 | `board.sh status`'s stderr is kept apart from the status |
| F6 | `cmd_update` ignores SIGPIPE and its progress prints are best-effort |
| F7 | a missing login keychain file is not a locked keychain |
| F8 | `go` prints `sandbox:` for a sandbox |
| F9 | the docs say `go`/`done` run the current directory's scripts when `CODEO_HOME_CLONE` is unset |
| F10 | the note init records reads `approved in advance by the engineer (--approved)`, true for a hand-typed flag too |
| F11 | `t_keychain_skipped_off_macos` and the `prove` overlay test strengthened |

**Documentation changed.** `.devcontainer/README.md` (the `codeo go` section and its diagram), `CHANGELOG.md` (the `sandbox:` label and the new behaviours).

**Build result.** The `shell` suite's `build` is `true`: exit 0. The full suite and the focused test files were run by the implementer; grading them is `/codeo:qc`'s.

**Deviations from the plan, and why.** The recorded `--approved` note differs from the text the plan's Task 6 fixed (it dropped "through codeo go") because that text was untrue for a hand-typed flag; rule `init-12` and the inventory hash are unchanged. `plan.md`'s footprint still lacks `tests/inventory.test.sh` (F12, the plan's).

**Left as minor.** The flow diagram still labels the card statuses `Ready` and `Backlog` literally rather than as configured; the F6 test closes stdout and does not exercise an exited reader's SIGPIPE directly; untested `go` branches (a failing `board.sh set`, a missing `jq`); no timeout on the headless call (documented).

**Rulings made.** The `--approved` note text change (above); a card with the literal status `Ready` is refused when the board renames Ready, as the fix's brief said; no separate whole-branch review of this round, because the round's own reviewer saw the whole delta and `/codeo:qc` follows with an independent review.


## Log

- 2026-11-28 — implemented: nine tasks, 15 commits (a7fa31c..6658163); build ok; 6 fix rounds (Tasks 5, 6, 7, 8, 9 and the final wave) · cost: 49m · sonnet-5-5 1.2M in + 38.1M cached / 220k out
- 2026-11-28 — round 2 started: send-back from qc.md round 1 read, findings checked, Q1 raised (#181 overlap) · cost: 0m · sonnet-5-5 13k in + 901k cached / 1k out
- 2026-11-28 — round 2: fixed F1-F11 of qc.md round 1 in three commits (9f8c487..0a5f631); build ok; reviewed, no open finding · cost: 9m · sonnet-5-5 199k in + 7.9M cached / 38k out
