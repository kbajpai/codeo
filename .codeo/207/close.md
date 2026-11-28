# Issue #207 — close

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/207 |
| Branch | `feat/207-stop-parallel-issues-colliding-shared` |
| Updated | 2026-11-28 |

## Where this stands

Round 2, sent back: #222 conflicts with `main` after #217 merged. Next step: `/codeo:implement` merges the base branch and resolves the conflicts, then `/codeo:qc`, then `/codeo:close`.

## Questions

None.

## Notes

None.

## Outcome

### Round 1 — pull request opened

2026-11-28

#222 https://github.com/kbajpai/codeo/pull/222

Went out on `qc.md` round 3, whose verdict is "clear — forward to `/codeo:close`". No override.

### Round 2 — conflicts with main

2026-11-28

#222 cannot merge: GitHub reports `CONFLICTING`. `git merge-tree --write-tree --name-only origin/main HEAD` lists three conflicting files; each was changed on `main` by the same merge.

- `tests/fixtures/skills-inventory.rules.sha256` — `f8b6441 feat: add codeo go and codeo done, a --version flag and a more verbose codeo update (#217) (#221)`
- `tests/init-skill.test.sh` — `f8b6441` (the same)
- `tests/inventory.test.sh` — `f8b6441` (the same)

`scripts/base-moved.sh 207` (this branch's copy; the installed plugin has none) also prints, as files QC graded that `main` changed since: `README.md`, `docs/release-checklist.md`, `docs/skills-inventory.md`, `docs/skills.md`, `skills/init/SKILL.md`, and the three files above. Git merged the first five without a conflict, and the merged tree still has to be re-checked against this branch's work and graded again. #217 is the overlap QC raised at `qc.md` Q1 and Q2, answered *proceed and coordinate*.

qc round at review: 3

## Log

- 2026-11-28 — archived the dossier, opened #222 · board: In review on #207 · cost: 0m · sonnet-5-5 27k in + 1.1M cached / 3k out
- 2026-11-28 — conflicts with main (#222, after #217 merged): sent back to /codeo:implement; dossier un-archived · board: In progress on #207 · cost: 13m · sonnet-5-5 33k in + 2.7M cached / 8k out
