# Issue #118 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/118 |
| Branch | `feat/live-signal-leftovers-104-refresh` |
| Updated | 2026-11-18 |

## Where this stands

Round 2 of the pass is paused at step 2: `overlap.sh` found #100 editing `CHANGELOG.md`, which no dossier of this issue has raised (round 1 mistook it for the settled #99 overlap). Q1 is open. The round 2 checks run so far are not written up yet; resume by answering Q1.

## Questions

### Q1 — #100 also edits `CHANGELOG.md`: proceed and coordinate, sequence after #100, or re-scope?

**Why it matters:** `overlap.sh 118` prints `100 CHANGELOG.md` and `100 glob:CHANGELOG.md`: this workflow's footprint and #100's both name `CHANGELOG.md`. #100 is branch `chore/release-v1-0-7-once` ("Release v1.0.7 once #70, #71, #96, #97 and #98 are closed, and pin codeo to it", still open), assigned to kbajpai, at step `implement (working)`; its footprint is `.claude-plugin/plugin.json, CHANGELOG.md, .codeo/config.json, docs/plans/2026-11-18-release-v1-0-7.md, .codeo/100/**`. The release itself has landed on `main` (`7b25bc2 release: v1.0.7 (#127)`, merged into this branch at the start of round 2 with no conflict), while #100 is still open and its branch is still on origin. Round 1 of this file and `implement.md` read the same line as the #99 overlap that `plan.md` Q3 settled; they were wrong: #99 has merged and was a different workflow, and no dossier of this issue has raised #100.

This branch adds one bullet at the end of `## Unreleased` and changes nothing else in `CHANGELOG.md`. If #100's branch still edits `## Unreleased` (retitling it to a version heading is what a release does), whichever of the two merges second gets a conflict in that file, and it is mine to resolve in `/codeo:close` or its own, not a code problem.

**Options:**
- **(a) Proceed and coordinate (recommended).** The release is already on `main`, the bullet merged in cleanly, and the conflict, if any, is one file with both sides kept. Verdict for round 2 is then written on the tree as it stands.
- **(b) Sequence after #100.** Hold this pull request until #100 is merged or closed, then re-run the round.
- **(c) Re-scope.** Drop the `CHANGELOG.md` bullet from this change and file it separately after the release.

**Answer:** (a) proceed and coordinate — 2026-11-18.

## Notes

Non-blocking findings (each points at a line this change touched; none sends the change back):

- **F1 — non-blocking, the plan's.** `tests/live.test.sh:212`: the label "a non-positive refresh interval never throttles" says more than the case runs. The case runs `-100` only, `0` is not run (the plan keeps `-100` on purpose: a literal `0` flakes when the clock steps back a second), and even `-100` throttles after a step back of more than 100 seconds. The code does what the plan says; "a negative refresh interval republishes" would be the exact wording. The engineer may want to weigh this one, since the issue's complaint was a label that says more than its case.
- **F2 — non-blocking, the plan's.** `tests/live.test.sh:497-522`: the concurrent-beats case never checks that each round published. A ref from round 1 still satisfies "one ref" and the `0-5` age at the end, and a round where both beats fail with `live: could not publish` is accepted. Recording `ref_sha` before each round and asserting it changed would pin "fresh either way" per round. The reviewer measured 10 REST fallback calls in 10 rounds, three runs out of three, so the case does exercise real contention.
- **F3 — non-blocking, the plan's.** `tests/live.test.sh:134-135`: the two background `live` calls race on the `seq` read-modify-write in `live()`. Harmless (an empty read gives 1, no assertion depends on the dates), but the new case is the first to call `live()` concurrently.
- **F4 — non-blocking, the plan's.** `docs/handoff.md:185-186`: "Two containers sharing a volume name are two checkouts of that kind" understates the effect: those containers replace each other's signal for the whole session, not only in a lost-lock race. Line 170 already says it.
- **F5 — non-blocking, the plan's.** `docs/handoff.md:173` and `scripts/live.sh:51`: "two bounds at the default of 8" omits that this is 16 seconds of the hook's 20; accurate, easy to misread as 2 x 10.
- **F6 — non-blocking, implement's.** The `CHANGELOG.md` bullet says the docs "now say" a session is deliberately not told when a signal cannot be published; `docs/handoff.md` already said it and this branch adds no wording for it. The substance is documented (implement.md already records this deviation).

Declined to judge by the reviewer, and agreed here: `scripts/live.sh` lines over 100 columns that predate the change (line 11 is over only by a multibyte dash); long `docs/handoff.md` lines in a file that already has 40 of them; surfacing failures in the session (the F2 decision of the plan); `hooks.json` reading the timeout from the environment (criterion 6 allows either); the missing `timeout` binary on macOS (already on #116's list); #112.

## Outcome

### Round 1 — 2026-11-18

**Scope.** `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`. `overlap.sh 118`: one line, `100 CHANGELOG.md` / `100 glob:CHANGELOG.md`, the overlap with #99 that plan Q3 settled (proceed and coordinate); #99 has since merged and nothing new was raised. `overlap.sh --outside 118`: nothing, so no changed file lies outside the footprint. `git diff origin/main...HEAD --stat`: 11 files, 391 insertions, 14 deletions: `hooks/live-signal.sh`, `scripts/live.sh`, `tests/live.test.sh`, `tests/live-signal.test.sh`, `docs/handoff.md`, `CHANGELOG.md`, the plan and the four dossier files. `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/118/implement.md
  .codeo/118/init.md
  .codeo/118/issue.md
  .codeo/118/plan.md
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line and no shared environment configured, so there is no `#### Environment` block.

**Build.** `shell` suite, `true`: exit 0.

**Tests.** `shell` suite, `bash tests/run.sh`, run whole: exit 0, last line `all cases passed`.

**Criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| The test label and its case match. | met — the case relabelled "a non-positive refresh interval never throttles" and still runs `CODEO_LIVE_REFRESH_SECONDS=-100`; the wording is looser than the case (F1, non-blocking) | `tests/live.test.sh:210-214` |
| `hooks/live-signal.sh`'s header lines fit the file's line-length convention. | met — no line over 100 columns, both header claims kept | `hooks/live-signal.sh:2-11`; `hook_header_fits_100_columns` in `tests/live-signal.test.sh` |
| A test or the docs cover two concurrent beats from one machine. | met — a test and the docs | `two_simultaneous_beats_from_one_checkout_leave_a_fresh_signal` in `tests/live.test.sh`; `scripts/live.sh:46-48`; `docs/handoff.md:183-186` |
| The F2 decision (surface failures or leave them) is recorded in the plan. | met — "stay silent" | `docs/plans/2026-11-18-live-signal-leftovers-118.md`, Global Constraints, first bullet |
| The `live.sh` comment names both calls the timeout bounds (`ref put` and `ref delete`). | met — the `CODEO_LIVE_PUSH_TIMEOUT` entry names both | `scripts/live.sh:58-61`; `live_sh_comment_names_both_bounded_calls` reads that entry only |
| The docs say the 20-second `SessionEnd` figure assumes the default `CODEO_LIVE_PUSH_TIMEOUT`, or the hook timeout is derived from it. | met — documented, not derived; `hooks.json` still reads `10 10 20` | `docs/handoff.md:173`; `scripts/live.sh:50-52`; `docs_state_the_live_signal_limits` |

**Documentation.** The plan moves `docs/handoff.md` (*Who is working right now*) and `CHANGELOG.md`, and both are in the diff. The new `docs/handoff.md` sentences are present tense and carry no issue number; their claims were checked against the code: `clear` makes two bounded calls (`scripts/live.sh:173-174`), the default is 8 (`live.sh:69`), `SessionEnd` has `"timeout": 20`, a losing beat prints `live: could not publish — …` (`live.sh:73,166`). No project overlay rules for invariants or wiki (both exit 3), no invariants file, no wiki module. `docs/skills.md`, `README.md` and `docs/dossier.md` describe nothing this change alters.

**Independent review.** Opus, given the criteria and the diff only (not the plan's account or the dossiers). It ran `tests/live.test.sh` three times and `tests/live-signal.test.sh` once (all passed), found every criterion met and every claim it checked true, and returned I1 (F1 here), M1 (F2), M2 (F3), M3 (F4) and M4 (F5) with the verdict "ready to merge with fixes". Its I1 was rated Important by the reviewer; here it is non-blocking because the label's wording is the plan's decision, the criterion's two sides (label, case) agree on a non-positive interval, and the case does test a real non-positive value. F6 is mine.

**Findings.** F1-F6 above, all non-blocking: F1-F5 are the plan's, F6 is implement's. No issue was filed for this pass; `/codeo:triage` collects them.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-18 — round 1: build, suite, six criteria met, independent review, six non-blocking findings · cost: 8m · opus-5-5 65k in + 333k cached / 7k out · sonnet-5-5 43k in + 2.4M cached / 8k out
- 2026-11-18 — round 2 paused at step 2: Q1 raised (#100 also edits CHANGELOG.md) · cost: 1m · sonnet-5-5 25k in + 1.5M cached / 6k out
