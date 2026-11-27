# Issue #204 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/204 |
| Branch | `chore/204-fix-codeo-close-opens-pr` |
| Updated | 2026-11-27 |

## Where this stands

Round 1. Q1 and Q2 are answered. The plan is approved and written (`docs/plans/2026-11-27-close-archive-before-pr-204.md`, unstaged), but #206 has since declared an overlapping footprint: Q3 is open, and `## Outcome` stays pending until it is answered.

## Questions

### Q1 — How is "the first CI run on a PR opened by `/codeo:close` passes qc-verdict" shown to be met?

**Why it matters:** it decides what `/codeo:qc` judges the first acceptance criterion on, and whether the plan carries a task outside the test suite. This repository runs the pinned plugin (v1.0.10), so #204's own pull request is still opened by the old skill and its first run will be red whatever the branch says.

- Tests only. `tests/close-skill.test.sh` pins the new order in the skill's text (archive and push before `pr create`, the record commit after it), and a new case in `tests/qc-verdict.test.sh` replays the two commits in a scratch repository: the archive commit with no pull-request round passes, and so does the record commit after it. `/codeo:qc` judges the criterion on these. The first live green run is seen on the first pull request after the next release and pin bump, and is not part of this issue.
- Tests, and a live run before the merge. As above, and you run #204's own close from this branch's skill text (for example a session started with `claude --plugin-dir` on this checkout), so its pull request's first run is the proof. The cost: a step on your machine that the plan marks `Runs on: the engineer's host`, and a close run on an unreleased plugin.

I recommend tests only.

**Options:** tests only (recommended) · tests and a live run of #204's own close · no preference, you pick.

**Answer:**
Tests only, as recommended. Given in the conversation: "go with your picks".

### Q2 — #195 is in flight and its footprint covers files this plan changes. Proceed, sequence, or re-scope?

**Why it matters:** `#195` (branch `feat/195-identify-acting-user-strictly-verify`, assignee kbajpai, step `plan (working)`, waiting on `/codeo:implement`) declares these, which this plan's footprint also has: `glob:CHANGELOG.md`, `glob:README.md`, `glob:docs/dossier.md`, `glob:docs/handoff.md`, `glob:docs/skills-inventory.md`, `glob:docs/skills.md`, `glob:skills/close/**`, `glob:skills/init/**`, `glob:tests/**`. Its branch has changed only its own plan file so far. No exclusive resource is shared.

This change is narrow: Phase 1 of `skills/close/SKILL.md` (steps 1 and 4-8), the paragraphs of the docs that state the order, and the close tests and fixtures. #195 changes how every skill identifies the acting user, so the two should meet in the same files but rarely in the same lines. `tests/fixtures/skills-inventory.rules.sha256` is the one file both are likely to rewrite whole, and whichever merges second regenerates it.

- Proceed and coordinate: both go on; whichever merges second merges the base branch and resolves what conflicts (through `/codeo:close`'s conflict send-back).
- Sequence after #195: this plan waits until #195 merges. #195 has not started implementing, so the wait is open-ended, and every pull request until then keeps its red first run.
- Re-scope: nothing here can be cut to avoid the shared files; the skill and its docs are the fix.

I recommend proceed and coordinate, with #204 merging first because it is the smaller change.

**Options:** proceed and coordinate (recommended) · sequence after #195 · re-scope.

**Answer:**
Proceed and coordinate, as recommended; #204 merges first. Given in the conversation: "go with your picks".

### Q3 — #206 now declares files this plan also changes. Proceed, sequence, or re-scope?

**Why it matters:** `#206` (branch `fix/206-codeo-cleanup-prints-codeo-rm`, assignee kbajpai, step `init (working)`, waiting on its own `issue.md` Q1) wrote its footprint after Q2 was answered. It overlaps this plan's on `glob:CHANGELOG.md`, `glob:README.md` and `glob:docs/skills.md`. The footprint's `tests/**` also covers its `tests/cleanup.test.sh` and `tests/cleanup-skill.test.sh`; this plan touches neither (`overlap.sh` prints them as `glob:tests/cleanup-skill.test.sh` and `glob:tests/cleanup.test.sh`). Its branch has changed nothing yet. No exclusive resource is shared.

The shared files are prose and a changelog; this change edits the `/codeo:close` paragraphs of `README.md` and `docs/skills.md` and one `CHANGELOG.md` bullet, and #206 edits the `/codeo:cleanup` ones. Conflicts, if any, are adjacent lines.

- Proceed and coordinate: both go on; whichever merges second merges the base branch and resolves what conflicts.
- Sequence after #206: this plan waits for #206's merge. #206 has not been planned, so the wait is open-ended and every pull request keeps its red first run meanwhile.
- Re-scope: nothing here can be cut to avoid the shared files.

I recommend proceed and coordinate, as for #195.

**Options:** proceed and coordinate (recommended) · sequence after #206 · re-scope.

**Answer:**

## Notes

**The design (my calls; corrected at the review gate if wrong).**

- New Phase 1 order in `skills/close/SKILL.md`: the checks (steps 2-3, unchanged) → archive (`git mv .codeo/<N> .codeo/done/<N>`), commit `docs(codeo): close dossier for #<N> — archived`, push → open the pull request → write the `— pull request opened` round and the `## Log` line into `.codeo/done/<N>/close.md`, commit `docs(codeo): close dossier for #<N> — PR #<pr>`, push → card to In review → report.
- The pull request's first CI run is on the archive commit, so `qc-verdict` passes. The record commit starts a second run, which passes too. A PR open still costs two runs; both are green. The record cannot go into the first commit because the pull request's number does not exist until it is opened, and `cleanup.sh` reads the `#<number> <url>` line from `done/<N>/close.md`.
- A failed push of the archive commit is a stop: no pull request is opened on a head that still carries the live dossier. A failed push of the record commit stays loud-but-kept, as today.
- Phase detection gains two rows: no pull request with the dossier under `done/` (interrupted after the archive: run the checks on the archived paths, skip the archive, open the pull request; a conflict found then un-archives in its send-back commit, as step 11 does), and an open pull request with the dossier under `done/` and no round recording it (interrupted after `pr create`: record it from the lookup). The existing "open pull request, live dossier, no review round" row stays, for a pull request opened by hand or by an older plugin.
- A return from review is unchanged: the pull request exists, so one commit archives and records, and its run passes. A send-back's un-archive is unchanged, so `qc-verdict` still fails until the dossier is archived again.
- `scripts/qc-verdict.sh` and `scripts/dossier-check.sh` do not change: an archive without an opened round already passes both.
- Reach: this repository runs the pinned plugin (v1.0.10), so the new order applies here after the next release and pin bump, both separate issues by this project's convention.

`#206` (`fix/206-codeo-cleanup-prints-codeo-rm`) is at `init` and has no footprint yet; its branch has changed nothing, so there is nothing to compare.

### Footprint

```
files:      skills/close/SKILL.md, skills/triage/SKILL.md, skills/init/SKILL.md, docs/dossier.md, docs/handoff.md, docs/skills.md, docs/skills-inventory.md, README.md, CHANGELOG.md, tests/**, docs/plans/2026-11-27-close-archive-before-pr-204.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-27 — Q1-Q2 raised · cost: 3m · fable-5-2 126k in + 1M cached / 14k out
- 2026-11-27 — Q1-Q2 answered (picks); drafted .codeo/204/plan-draft.md, awaiting approval · cost: 7m · fable-5-2 131k in + 1.7M cached / 17k out · sonnet-5-5 133k in + 330k cached / 11k out
- 2026-11-27 — plan approved and written: docs/plans/2026-11-27-close-archive-before-pr-204.md; Q3 raised (overlap with #206) · cost: 9m · fable-5-2 131k in + 1.7M cached / 17k out · sonnet-5-5 142k in + 987k cached / 13k out
