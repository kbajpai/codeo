# Issue #207 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/207 |
| Branch | `feat/207-stop-parallel-issues-colliding-shared` |
| Updated | 2026-11-28 |

## Where this stands

Round 1, stopped at step 2: `overlap.sh 207` found a new overlap with #217. Q1 is open; the pass resumes from step 2 once it is answered.

## Questions

### Q1 — #217 overlaps on `skills/init/SKILL.md`, `tests/init-skill.test.sh`, `docs/skills-inventory.md`, `tests/fixtures/skills-inventory.rules.sha256`, `README.md`, `docs/skills.md` and `docs/release-checklist.md`: proceed, sequence, or re-scope?

**Why it matters:** `overlap.sh 207` printed, for #217 (branch `feat/217-add-codeo-go-codeo-done`, assignee kbajpai, step `plan (working)`, waiting on `/codeo:implement`; its branch has changed only its plan file so far):

```
217	README.md
217	docs/release-checklist.md
217	docs/skills-inventory.md
217	docs/skills.md
217	glob:README.md
217	glob:docs/release-checklist.md
217	glob:docs/skills-inventory.md
217	glob:docs/skills.md
217	glob:skills/init/SKILL.md
217	glob:tests/fixtures/skills-inventory.rules.sha256
217	glob:tests/init-skill.test.sh
217	skills/init/SKILL.md
217	tests/fixtures/skills-inventory.rules.sha256
217	tests/init-skill.test.sh
```

Both change the `init` skill, which is the case this issue's `skill` lease exists for; #217's footprint says `exclusive: none` because the resource is only on this branch. Its footprint also lists `CHANGELOG.md`, which this branch replaces with fragments.

- Proceed and coordinate: this branch is built and in QC; it merges first, and #217 merges `main` at its next `/codeo:implement` round. The pin file then conflicts only line by line, and #217 writes `changelog.d/217.md` instead of editing `CHANGELOG.md`.
- Sequence after #217: this pull request waits for #217, which has not started implementing.
- Re-scope: this branch cannot avoid `skills/init/SKILL.md` (Task 8) without dropping a planned task.

I recommend proceed and coordinate, #207 merging first.

**Options:** proceed and coordinate (recommended) · sequence after #217 · re-scope.

**Answer:**

## Notes

Round 1 so far (step 2):
- `sync-main.sh --abort-on-conflict` → `sync-main: merged origin/main (1 commit(s))`, `sync-main: also changed on main: .codeo/config.json` (the pin moved to `v1.0.11`; the branch's `resources` entry for `skill` is intact: `[{"name":"skill","paths":["skills/**","tests/*-skill.test.sh"],"parameterised":true}]`).
- Base graded this round, if it continues on this merge: `origin/main` at 13ac02c.
- `overlap.sh 207` → the lines quoted in Q1 (exit 0).

## Outcome

_Pending — written at the verdict._

## Log

- 2026-11-28 — Q1 raised (overlap with #217 found at step 2) · cost: 0m · opus-5-5 329k in + 379k cached / 763 out
