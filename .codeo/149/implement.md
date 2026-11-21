# Issue #149 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/149 |
| Branch | `fix/close-non-blocking-findings-143` |
| Updated | 2026-11-21 |

## Where this stands

Implemented: all nine tasks of `docs/plans/2026-11-21-close-non-blocking-findings-149.md` are committed (`d2a1674`..`b2c2d7d`), each reviewed by a second subagent, then a whole-branch review (verdict ready) and one README fix wave with a scoped re-review (clean). Not pushed from this step yet; the dossier push below carries the branch. Next step: `/codeo:qc`.

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

## Log

- 2026-11-21 — implemented: plan committed, Tasks 1-9 done and reviewed, whole-branch review ready, one fix wave · cost: 103m · sonnet-5-5 823k in + 27.3M cached / 125k out
