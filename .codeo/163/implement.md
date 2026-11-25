# Issue #163 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/163 |
| Branch | `fix/close-152-leftovers-cleanup-overlay` |
| Updated | 2026-11-25 |

## Where this stands

Round 1, stopped before any task. The plan `docs/plans/2026-11-25-close-152-leftovers-cleanup-overlay-163.md` is committed and pushed (`50b2b80`), and the base branch is merged in (`b7a3ea0`; `sync-main.sh` listed no "also changed on" lines). `overlap.sh 163` now prints four lines for #166, which had no footprint when this plan was written: Q1-Q4. `.codeo/overlays/close.md` is in both footprints too, though `overlap.sh` did not print it. Nothing is built.

## Questions

### Q1 — `#166` and `glob:CHANGELOG.md`: proceed, sequence, or re-scope?

**Why it matters:** #166 (branch `docs/close-157-leftovers-hosted-web`, assignee kbajpai, step plan (working), waits on `/codeo:implement`) lists `CHANGELOG.md` in its footprint, and so does this plan. This plan adds a sentence and a bullet under `## Unreleased`; #166 will add its own bullets there. Whichever merges second rebases and keeps both sides; sequencing makes this issue wait for #166's plan, then its code.
**Options:** *proceed and coordinate* (my pick) · *sequence after #166* · *re-scope* (say what to leave out of `CHANGELOG.md`).

**Answer:**

### Q2 — `#166` and `glob:docs/skills.md`: proceed, sequence, or re-scope?

**Why it matters:** #166 (branch `docs/close-157-leftovers-hosted-web`, assignee kbajpai, step plan (working), waits on `/codeo:implement`) lists `docs/skills.md` in its footprint, and so does this plan. This plan adds one sentence to the `/codeo:cleanup` section; #166 also edits `docs/skills.md` and `scripts/cleanup.sh`, whose cleanup behaviour that section describes. Whichever merges second rebases and keeps both sides; sequencing makes this issue wait for #166's plan, then its code.
**Options:** *proceed and coordinate* (my pick) · *sequence after #166* · *re-scope* (say what to leave out of `docs/skills.md`).

**Answer:**

### Q3 — `#166` and `glob:tests/cleanup-skill.test.sh`: proceed, sequence, or re-scope?

**Why it matters:** #166 (branch `docs/close-157-leftovers-hosted-web`, assignee kbajpai, step plan (working), waits on `/codeo:implement`) lists `tests/cleanup-skill.test.sh` in its footprint, and so does this plan. This plan adds a `for needle` loop after the fallback assertion at `:97`; #166 changes `skills/cleanup/SKILL.md` and may edit the same file. Whichever merges second rebases and keeps both sides; sequencing makes this issue wait for #166's plan, then its code.
**Options:** *proceed and coordinate* (my pick) · *sequence after #166* · *re-scope* (say what to leave out of `tests/cleanup-skill.test.sh`).

**Answer:**

### Q4 — `#166` and `glob:tests/close-removal.test.sh`: proceed, sequence, or re-scope?

**Why it matters:** #166 (branch `docs/close-157-leftovers-hosted-web`, assignee kbajpai, step plan (working), waits on `/codeo:implement`) lists `tests/close-removal.test.sh` in its footprint, and so does this plan. This plan adds four needles to the list at `:20`; #166 also edits `.codeo/overlays/close.md`, which that test reads, and `skills/close/SKILL.md`. Whichever merges second rebases and keeps both sides; sequencing makes this issue wait for #166's plan, then its code.
**Options:** *proceed and coordinate* (my pick) · *sequence after #166* · *re-scope* (say what to leave out of `tests/close-removal.test.sh`).

**Answer:**

## Notes

None.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-25 — Q1-Q4 raised (overlap with #166) · cost: 1m · sonnet-5-5 12k in + 693k cached / 1k out
