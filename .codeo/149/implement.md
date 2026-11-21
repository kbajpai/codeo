# Issue #149 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/149 |
| Branch | `fix/close-non-blocking-findings-143` |
| Updated | 2026-11-21 |

## Where this stands

Round 2 done, answering `qc.md` round 1: F1 (blocking) and F3-F6 are fixed in `fc8a5ac` and `41e9c3d`, reviewed once by a second subagent (approved, no Critical or Important findings). Next step: `/codeo:qc`, from step 0.

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

## Log

- 2026-11-21 — implemented: plan committed, Tasks 1-9 done and reviewed, whole-branch review ready, one fix wave · cost: 103m · sonnet-5-5 823k in + 27.3M cached / 125k out
- 2026-11-21 — round 2 (send-back from qc.md round 1): F1 and F3-F6 fixed, reviewed · cost: 10m · sonnet-5-5 125k in + 4.3M cached / 17k out
