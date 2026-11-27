# Issue #204 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/204 |
| Branch | `chore/204-fix-codeo-close-opens-pr` |
| Updated | 2026-11-27 |

## Where this stands

Round 1. Q1 and Q2 are answered ("go with your picks": tests only; proceed and coordinate with #195). The plan is drafted at `.codeo/204/plan-draft.md` and waits for the engineer's approval.

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
