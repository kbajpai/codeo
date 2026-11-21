# Issue #149 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/149 |
| Branch | `fix/close-non-blocking-findings-143` |
| Updated | 2026-11-21 |

## Where this stands

Round 3 done, answering `qc.md` round 2: F9 (blocking), F10 and F11 are fixed in `8d2b49e`, `7dd063a` and `5d1fd04`, reviewed by a second subagent (one duplicated README sentence found and removed). Next step: `/codeo:qc`, from step 0.

## Questions

None.

## Notes

The plan commit (`5f11268`) was uncommitted when the step started; the engineer confirmed it was final and it was committed first. `sync-main.sh` merged one commit from `origin/main` (`6e18538`); it printed no `also changed on` lines, and `overlap.sh` printed nothing.

## Outcome

**Built, one commit per task** (every code and test task started from a failing test; each implementer recorded the RED output and the mutation that makes the new test fail):

| Task | Finding | Commit | What changed |
|---|---|---|---|
| 1 | F14 | `d2a1674` | `main` makes `CODEO_HOME` absolute once; `t_relative_codeo_home_rm`; README clause |
| 2 | F6 | `6a14f89` | `cmd_rm` runs `workspace_mount` before `container_check`, which takes `--no-restart` (passed when the inspect failed without `--force`); `t_rm_inspect_fails_no_restart`; `t_rm_container_clean` call order |
| 3 | F13 | `ad73eb6` | `sbx_has` helper shared with `host_kinds`; after a failed `end --force` the hint prints only when `sbx ls` still lists `codeo-<N>` or cannot list; `t_rm_sandbox_force_gone` |
| 4 | F12, F15, F16, F9 | `2d50fa2` | READMEs, one `codeo help` line, a corrected code comment, the redrawn flowchart |
| 5 | #144 F4 | `3f170fa` | overlap sentences in `skills/implement` and `skills/close` follow "The step stops until it is answered"; `must_precede` pins |
| 6 | #144 F5a | `3fdeeee` | `skills/init` step 11: either TODO case ends the turn; `docs/handoff.md`'s row already agreed and is unchanged |
| 7 | #144 F5b | `da6afe8` | the stop sentence reads "with or without an …" in seven places; `tests/overlap-stop.test.sh` pins it |
| 8 | #144 F3, F5c | `3b2afee` | `qc_verdict_replan` pins `qc-verdict.sh`'s plan round; the send-back reader varies `close.md` alone |
| 9 | — | `fbb7128` | one `CHANGELOG.md` bullet |
| fix wave | review | `b2c2d7d` | README lists every nameless sandbox refusal; two flowchart edges made exclusive; node H worded to the code |

**Documentation pages changed:** `.devcontainer/README.md`, `.sbx/README.md`, the `codeo help` text, `skills/implement`, `skills/close`, `skills/init`, the stop sentence in `skills/plan`, `skills/qc` and `docs/handoff.md`, and `CHANGELOG.md`. `.sbx/codeo-sandbox.sh` is not edited. `scripts/` is not edited.

**Build result:** the `shell` suite's build command is `true`; it exits 0. The full `bash tests/run.sh` printed `all cases passed` in each implementer's report; this step did not run it again and no baseline run was made before Task 1 (it was stopped after two minutes so as not to edit under it). The grading run is `/codeo:qc`'s.

**Deviations from the plan, and why:**
- **Task 7 also edits `tests/close-skill.test.sh` and `tests/implement-skill.test.sh`** (one line each): Task 5's `must_precede` pins held the old string `A non-zero exit, with an`, which Task 7 reworded. Both files are in the footprint.
- **Task 8 adds a third argument `unanswered` to the test's `inflight_with`**, which leaves out `implement.md`'s send-back marker. The plan said to vary `close.md`'s heading alone with the expectation unchanged; with qc round 2 clear, read and unread both ended on `/codeo:close`, so the fixture could not tell them apart. Reviewed sound: only `close_send_back()`'s heading match decides the outcome now. Both mutations the plan names (`inflight.sh` `close_send_back()` tightened to `/^## Outcome$/`; `qc-verdict.sh` plan-round awk loosened to a prefix match) passed `outcome-heading` before the change and fail it after.
- **Fix wave (`b2c2d7d`) added `could not remove codeo-<N>`** to the README's list of nameless refusals, which the review's finding did not name; the re-review confirmed it is a real refusal naming no command.
- **No task reviewer for Task 9** (one changelog bullet read in full); the whole-branch review covered it. The whole-branch review ran on the configured subagent model, as `implement-06` requires, not a more capable one.
- **F5d** (`CHANGELOG.md` calling the no-lock closing block "unchanged") stays dismissed, as the plan decided.

**Parked minors, none blocking** (the whole-branch review listed them, and none contradicts the code):
- The README says "adds nothing" after `no sandbox codeo-<N>` without repeating that a failing `sbx ls` keeps the hint; the sentence two lines earlier says "or cannot list".
- The flowchart omits the `docker rm -f` and `docker volume rm` failure paths; the prose covers them.
- `t_rm_inspect_fails_no_restart` does not assert the first read ran.
- `recognised_by_qc_verdict_replan` reads `$crlf` and then declares `local crlf=`; it works.
- `recognised_by_inflight_send_back` inlines its own `case` instead of extending `waits_is`.
- Some wrapped lines in `skills/plan` and `skills/qc` are longer after Task 7 (cosmetic).

No environment is configured, so no lease was taken, no deploy ran and there is no `Deployed revision:`. No issue was filed.

### Round 2

2026-11-21
(send-back from qc.md round 1)

`sync-main.sh` found the branch already containing `origin/main`; `overlap.sh` printed nothing. Each QC finding was checked against the code before any work: all of F1 and F3-F6 held (F1 reproduced: `codeo issue 5` with `~/codeo` a git checkout and `CODEO_HOME` unset printed the stop line twice).

| Finding | Fix | Commit |
|---|---|---|
| F1 (blocking) | `cmd_issue` runs `home_dir >/dev/null` as a plain statement before `kind=${kind_flag:-$(saved_default)}`, so the stop prints once; `t_home_checkout_collision` now compares `issue 5`'s whole stderr (it failed with two lines before the fix) and `issue 5 --container`'s | `fc8a5ac` |
| F3 | the removal flowchart gains an error edge out of the `docker rm -f` / `volume rm` node | `41e9c3d` |
| F4 | `.devcontainer/README.md` says the second read is skipped when `docker inspect` failed without `--force` | `41e9c3d` |
| F5 | `.sbx/README.md` says the `--force` hint also prints when `sbx ls` cannot list | `41e9c3d` |
| F6 | the README's list of refusals that name no command gains `no sandbox codeo-<N>` and `could not list sandboxes with <sbx>` | `41e9c3d` |

**Build result:** the `shell` suite's `build` is `true`: exit 0. The implementer reported the full `bash tests/run.sh` as `all cases passed`; this step did not run it again, and `/codeo:qc` grades it. The F1 reproduction prints exactly one line for `codeo issue 5` and for `codeo issue 5 --container`.

**Documentation pages changed:** `.devcontainer/README.md` and `.sbx/README.md`. No other page.

**Behaviour change worth knowing:** with a refused home directory, `codeo issue 5 --rebuild --sandbox` now prints the home stop instead of the "--rebuild applies only to a container" usage error, because the home check precedes the kind. Both exit non-zero, and it matters only on a refused home.

**Not done, in writing:**
- F2 (the `--force` hint can still print when `sbx ls` fails right after the script's message) is the plan's Q3 choice, answered by the engineer; no change.
- F7 (a stopped container is started and left running before a refusal known up front) predates this change; not touched.
- F8's cosmetic test nits (`recognised_by_qc_verdict_replan` reading `$crlf` before `local crlf=`; `recognised_by_inflight_send_back` inlining its own `case`; the new `rm` test not asserting the first read ran) are dismissed: they work and change no behaviour.
- The round 2 review's two Minors are parked: the flowchart's removal-failure edge leaves only `G`, not the keep-the-volume path `H`; and the sandbox refusal list still omits `sbx is not installed: …` from `pick_sbx`, which names an install action rather than a command (the sentence says "name no command" and does not claim to be exhaustive).

No environment is configured: no lease, no deploy, no `Deployed revision:`. No issue was filed.

### Round 3

2026-11-21
(send-back from qc.md round 2)

`sync-main.sh` found the branch already containing `origin/main`; `overlap.sh` printed nothing. Each QC finding was checked against the code before any work, and all held; F9 was the regression round 2's own F1 fix introduced (`codeo issue 5 --sandbox --rebuild` with `~/codeo` a git checkout and `CODEO_HOME` unset printed the home stop and exited 1, where the base code printed the `--rebuild` usage error and exited 2).

| Finding | Fix | Commit |
|---|---|---|
| F9 (blocking) | `cmd_issue` takes the kind from the flag and reads the home directory (a plain statement, so its stop ends the command once) only when no `--container`/`--sandbox` was given, before `saved_default`; the `--rebuild` usage test therefore runs first whenever a flag fixes the kind. `t_home_checkout_collision` gains `issue 5 --sandbox --rebuild` (exit 2, the usage message; it failed with exit 1 on the round 2 code) and `issue 5 --rebuild` (exit 1, the whole stderr is the one stop line). `.devcontainer/README.md` says the one usage error that needs the kind reads the home directory only for the saved default | `8d2b49e` |
| F10 | the README sentence on what can refuse after the restart names a failed `docker volume rm` | `7dd063a` |
| F11 | the flowchart gains `H -- "docker rm -f failed" --> Y` | `7dd063a` |
| (review) | the new README sentence was in the paragraph twice; one copy deleted | `5d1fd04` |

**Build result:** the `shell` suite's `build` is `true`: exit 0. The implementer reported the full `bash tests/run.sh` as `all cases passed`; this step did not run it again, and `/codeo:qc` grades it. The F9 matrix with a refused home, run here: `issue 5 --sandbox --rebuild` exits 2 with the usage message; `issue 5`, `issue 5 --sandbox`, `issue 5 --container`, `issue 5 --rebuild` and `issue 5 --container --rebuild` each print the stop once and exit 1.

**Documentation pages changed:** `.devcontainer/README.md` only.

**Deviation:** the scoped re-review of the one-sentence deletion (`5d1fd04`) was a check of the diff and of `grep -o 'The one usage error that needs the kind' .devcontainer/README.md | wc -l` (1), not a second subagent.

**Not done, in writing:** F2 (the plan's Q3 choice) and F7 (a stopped container started and left running before a refusal known up front, which predates this change) stay recorded and unrouted. Parked from earlier rounds and still open: the new `rm` test does not assert the first read ran, `recognised_by_qc_verdict_replan` reads `$crlf` before declaring `local crlf=`, `recognised_by_inflight_send_back` inlines its own `case`, and the README's list of nameless sandbox refusals omits `sbx is not installed: …` (an install action, not a command; the sentence does not claim to be exhaustive).

No environment is configured: no lease, no deploy, no `Deployed revision:`. No issue was filed.

## Log

- 2026-11-21 — implemented: plan committed, Tasks 1-9 done and reviewed, whole-branch review ready, one fix wave · cost: 103m · sonnet-5-5 823k in + 27.3M cached / 125k out
- 2026-11-21 — round 2 (send-back from qc.md round 1): F1 and F3-F6 fixed, reviewed · cost: 10m · sonnet-5-5 125k in + 4.3M cached / 17k out
- 2026-11-21 — round 3 (send-back from qc.md round 2): F9, F10, F11 fixed, reviewed · cost: 12m · sonnet-5-5 92k in + 5.7M cached / 20k out
