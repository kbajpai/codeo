# Issue #118 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/118 |
| Branch | `feat/live-signal-leftovers-104-refresh` |
| Updated | 2026-11-18 |

## Where this stands

Round 2 is built, reviewed and pushed: the two QC round 1 findings the engineer chose to fix, F1 and F2, are done in `tests/live.test.sh` (round 1: all four plan tasks built, whole-branch review clean). Nothing is open. Next: `/codeo:qc`.

## Questions

None raised.

## Notes

- Step 2a merged `origin/main` (1 commit, #99). Its only file in this plan's footprint is `CHANGELOG.md`, the overlap plan Q3 already settled (proceed and coordinate); the merge was clean and Task 4 added its bullet on top. `overlap.sh` printed nothing new.
- `sync-main.sh` exited 1 once after the clean merge, from `comm` complaining about sort order (the locale ordering issue the changelog's #92 bullet describes); the merge was committed and a second run exited 0.

## Outcome

2026-11-18.

**Built** (plan tasks 1-4, in order; each by a fresh sonnet implementer, each followed by a task review):
- Task 1, `f7e4351`: the "refresh 0" case in `tests/live.test.sh` is labelled "a non-positive refresh interval never throttles" and keeps `-100`; `hooks/live-signal.sh`'s header is re-wrapped at 100 columns, pinned by the new case `hook_header_fits_100_columns`.
- Task 2, `731a7c5`: `scripts/live.sh`'s `CODEO_LIVE_PUSH_TIMEOUT` comment names `github.sh ref put` and `github.sh ref delete` (pinned by `live_sh_comment_names_both_bounded_calls`); `docs/handoff.md` and `live.sh`'s *Limits* say the `SessionEnd` 20 seconds assumes the default timeout of 8.
- Task 3, `eae49ae`: `two_simultaneous_beats_from_one_checkout_leave_a_fresh_signal` in `tests/live.test.sh` (seen failing with a temporary `return 0` in `beat()`, then restored; run 7 times without a flake); the collision is documented in `live.sh` and `docs/handoff.md`, pinned by two phrases in `docs_state_the_live_signal_limits`.
- Task 4, `24c48c4`: one `CHANGELOG.md` bullet for #118.

**Documentation changed:** `docs/handoff.md` (*Who is working right now*), `CHANGELOG.md`. No wiki module.

**Build:** the `shell` suite's build command ran and exited 0. Each task also ran `bash tests/run.sh` (`all cases passed`); QC owns the full grading.

**Deviations from the plan:**
- Task 1: the relabelled assert line was 146 columns, so it is split and the ref lookup moved into a `third` variable; the check is the same.
- `docs/handoff.md`'s bullet stays one long line, as the file's other bullets are (40 lines over 100 columns before and after), so the plan's 100-column cap is met in scripts, hook and tests but not in that bullet.
- The changelog bullet sits after the #113 bullet and before the `/codeo:triage` bullet that came in from main, not as the very last one. Its sentence that the docs "now say" the session is deliberately not told overstates by a little: `docs/handoff.md` already said it, and this branch adds no new wording for it.
- Task 3's review left two Minor notes, neither blocking: the final-round blind spot of the age check (a ref left by an earlier round passes if under 5 seconds old), and the test not saying which beat printed the `live:` line.


### Round 2

2026-11-18

(send-back from qc.md round 1)

QC round 1 was clear; the engineer chose to fix two of its six non-blocking findings, F1 and F2, and left F3-F6 for `/codeo:triage`. Both were checked against the code first and hold: the F1 label claimed a non-positive interval though the case runs `-100` only, and the concurrent-beats case never asserted that each round published.

**Built** (`48aaae3`, `tests/live.test.sh` only, one sonnet implementer and a task review):
- F1: the assert label is "a negative refresh interval republishes" and the `assert_pushed_quietly` label is `negative`; the `-100` command line and its check are unchanged.
- F2: `two_simultaneous_beats_from_one_checkout_leave_a_fresh_signal` records the ref's sha before each round and asserts it is non-empty and changed after both beats finish. `tests/live.test.sh` ran 11 times without a flake.

**Sync.** `sync-main.sh` merged `origin/main` (1 commit, the v1.0.7 release); it changed `CHANGELOG.md` only, which this round's change does not touch. It exited 1 after the clean merge, from `comm` complaining about sort order, as in round 1; `overlap.sh` printed only the settled #99 line.

**Build:** the `shell` suite's build command exited 0.

**Deviations from the plan:** the plan's Task 1 names the label "a non-positive refresh interval never throttles"; this round replaces it on the engineer's say-so, after QC, and the plan file is not edited. The implementer's red demonstration did not isolate the new assertion (the stub it used broke other cases too), so the assertion has not been shown to fail when both beats fail in a round. The task review's one residual risk: the `seq` counter in `live()` is read and written without a lock, so in a sub-millisecond window a counter value could repeat and, within one wall-clock second, make a published round read as unchanged. Very unlikely; recorded, not fixed.

No whole-branch review this round: the diff is one test file, +6/-2, reviewed whole by the task reviewer.

## Log

- 2026-11-18 — implemented tasks 1-4, whole-branch review clean, build green · cost: 33m · sonnet-5-5 412k in + 8.1M cached / 46k out
- 2026-11-18 — round 2: F1 and F2 fixed in tests/live.test.sh, build green · cost: 17m · sonnet-5-5 108k in + 3.7M cached / 15k out
