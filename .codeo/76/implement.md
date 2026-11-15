# Issue #76 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/76 |
| Branch | `feat/trial-doctor-setup-haiku-5` |
| Updated | 2026-11-14 |

## Where this stands

Round 2 (the `CHANGELOG.md` sentence qc round 1 asked for) is done. Nothing is open; the next step is `/codeo:qc`.

## Questions

None.

## Notes

The trial script, its fixtures, the 24 runs and both scorer versions' results are in the session scratchpad (`.../scratchpad/trial`), outside the repository and not committed, as the plan says. The raw reports are not kept on the issue (plan Q3).

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-14-trial-doctor-setup-haiku.md` |
| Build | the `shell` suite's build is `true`: nothing to run; `bash tests/run.sh` (run as the plan's Task 4 proof) printed `all cases passed` |
| Commits | `db43e58` — `CHANGELOG.md` entry; the plan itself `db6fa44` |
| Environment | none configured; no lease, no deploy |

**Built.** All four tasks. (1) The trial script and its fixture test; the skill's `model: haiku` line switches the model, so `--model haiku` was not needed. (2) The 24 runs (2 skills x 2 cases x 2 models x 3) in Claude Code 2.1.325. (3) The comparison, posted on #76: https://github.com/kbajpai/codeo/issues/76#issuecomment-6885759871. (4) `CHANGELOG.md`'s bullet. Neither `model:` line changed: all 6 Haiku runs of `doctor` and 1 of 6 of `setup` missed item 1 (a second Bash call to read `docs/handoff.md` where Sonnet used Read); Haiku passed every other item on every run, and Sonnet's own misses (item 5 of `doctor-fail`, runs 1 and 3) are recorded and not counted against it. Documentation changed: `CHANGELOG.md` only, as planned.

**Deviations from the plan, and why.**
- **A first pass of 24 runs was discarded.** The harness allowed only Bash, so the skills' read of `docs/handoff.md` was denied in headless mode and Sonnet itself failed items 3-5 on `setup-fresh`. Re-run after adding `Read` and `--add-dir`; no checklist item changed. The plan allows a re-run only for `gh` failures, so this is a ruling of mine (progress ledger).
- **The scorer was corrected after the second pass and the 24 saved streams re-scored** (`EXIT_CODE=N` lines, `exited with status 1`, item 5 of `doctor-pass` reading only the Next goal line and of `doctor-fail` demanding the word "fix"; the exit-detection regex for `EXIT_CODE`). Applied to both models; none touches item 1, the only item Haiku still misses, so the decision does not depend on them. Items 1-3 in the plan's Global Constraints describe what a pass is; the scorer v1 and v2 rows are kept in the scratchpad.
- **Item 5 of `setup-refuse` was read by hand** for all six runs: each goal is about the existing `.codeo/config.json`; all P.
- **The plan's Task 3 Step 3 command does not run** (`gh issue view --comments --json` is rejected); `--json comments` printed 8 matching lines. A plan gap, not worth a send-back.
- **The comment first said "9 of 12" runs** where it is 6 of 6 for `doctor`; corrected in place and checked (`9 of 12` no longer appears).
- **Task 2 was run by the controller** as one loop rather than a subagent, and no whole-branch review subagent was dispatched: the repository diff is one `CHANGELOG.md` bullet, and `/codeo:qc` reviews next.

**For `/codeo:qc`.** Criterion 2 reads "a skill whose Haiku run differed keeps `model: sonnet`, and the issue says how it differed": the comment says how (Haiku's reports matched; it reads the closing-block template with Bash instead of Read). Whether that counts as "differed" is the plan's Q2 = A rule, answered by the engineer.

### Round 2

2026-11-15
(send-back from qc.md round 1)

**Built.** `CHANGELOG.md:11`, the one sentence qc round 1 found wrong, rewritten in a single commit (`53aa18f`). F1 (blocking) held: each skill ran 3 times per model on 2 cases (4 in total, 24 runs in all), not "on 4 cases"; checked against the plan's case list and the comment on #76. F2 (non-blocking) held: on `doctor-fail` item 5 Sonnet passed 1 of 3 and Haiku 3 of 3, so "matched on every item but one" was inaccurate; it now says "Haiku passed every item but one". Neither `model:` line, no other file, and no plan text changed. F3 and F4 are the plan's and need no change here. Overlap with #57 on `CHANGELOG.md` stays *proceed and coordinate* (qc.md Q2).

**Build.** The `shell` suite's build `true` exited 0; `bash tests/run.sh` printed `all cases passed` (run as a check on the edit, not as grading).

**Deviations.** None. The edit is one sentence, so no sub-skill dispatch was used: the plan's `subagent-driven-development` loop has nothing to split here.

## Log

- 2026-11-14 — implemented: 4 tasks, 24 trial runs, comment on #76, `CHANGELOG.md` · cost: 25m · sonnet-5-5 116k in + 6.7M cached / 43k out
- 2026-11-15 — round 2: fixed the CHANGELOG.md sentence (qc round 1 F1, F2) · cost: 4m · sonnet-5-5 33k in + 778k cached / 1k out
