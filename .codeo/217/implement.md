# Issue #217 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/217 |
| Branch | `feat/217-add-codeo-go-codeo-done` |
| Updated | 2026-11-28 |

## Where this stands

Round 2 (send-back from `qc.md` round 1), not started on code: `sync-main.sh` merged nothing (the branch already contains `origin/main`), and `overlap.sh 217` printed two overlaps with #181 that Q1 asks about. The round is to fix F1, F2 and F4 (blocking) and F3 and F5-F11 (non-blocking); I checked F1, F2, F3, F7, F8 and F10 against the code and each holds. Nothing is built until Q1 is answered.

## Questions

### Q1 — #181 overlaps on `.devcontainer/README.md` and `CHANGELOG.md`: proceed, sequence, or re-scope?

**Why it matters:** round 2 edits `.devcontainer/README.md` (F4: four untrue statements in its `codeo go` section, F7/F9 sentences) and `CHANGELOG.md` (the entry for the fixes). `overlap.sh 217` printed `181	glob:.devcontainer/README.md` and `181	glob:CHANGELOG.md`. #181 (branch `feat/181-session-title-prefix-session-id`, assignee kbajpai, step `plan` (working), waiting on `/codeo:implement`) lists both files in its footprint beside `.devcontainer/scripts/session-title.sh` and `tests/devcontainer.test.sh`. Both change different sections of the README and add a changelog entry, so the second to merge resolves the overlap at its sync and its `/codeo:qc` re-runs the suite on the merged tree.

- Proceed and coordinate: both go on; whichever merges second resolves the two files.
- Sequence after #181: this round waits until #181 merges, then syncs and builds; #181 is only at `plan`, so the wait is open-ended.
- Re-scope: the F4 documentation fixes cannot move out of `.devcontainer/README.md` without leaving untrue statements in it.

I recommend proceeding and coordinating.

**Options:** proceed and coordinate (recommended) · sequence after #181 · re-scope.

**Answer:**

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

## Log

- 2026-11-28 — implemented: nine tasks, 15 commits (a7fa31c..6658163); build ok; 6 fix rounds (Tasks 5, 6, 7, 8, 9 and the final wave) · cost: 49m · sonnet-5-5 1.2M in + 38.1M cached / 220k out
- 2026-11-28 — round 2 started: send-back from qc.md round 1 read, findings checked, Q1 raised (#181 overlap) · cost: 0m · sonnet-5-5 13k in + 901k cached / 1k out
