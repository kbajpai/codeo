# Issue #195 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/195 |
| Branch | `feat/195-identify-acting-user-strictly-verify` |
| Updated | 2026-11-27 |

## Where this stands

Round 1, stopped at step 2. `sync-main.sh --abort-on-conflict` reported the branch already contains
`origin/main`. `overlap.sh 195` then printed overlaps with three workflows started after this
plan's footprint was checked (at plan time `inflight.sh` showed none). Q1-Q3 are open; no build,
suite, criterion or review has run yet, and no verdict is written while they are open.

All three are at `plan (working)`, assigned to `kbajpai` (the same engineer as this issue), and
their branches have changed only their own plan file so far. None names an `exclusive` resource.
This branch is past implement, so it is likely to merge first; the others then meet these changes
at their own `/codeo:implement` step 2a (`sync-main.sh`).

## Questions

### Q1 — Overlap with #188 (`docs/188-close-177-qc-leftovers-utc`): proceed, sequence, or re-scope?

`overlap.sh 195` printed, for #188 (assignee `kbajpai`, step `plan (working)`):
`CHANGELOG.md`, `glob:CHANGELOG.md`, `glob:skills/close/SKILL.md`, `glob:tests/cleanup-skill.test.sh`,
`glob:tests/close-removal.test.sh`, `glob:tests/close-skill.test.sh`, `skills/close/SKILL.md`,
`tests/close-skill.test.sh`.

**Why it matters:** both change `skills/close/SKILL.md` and `tests/close-skill.test.sh` (this
branch: step 0's `lock.sh verify` paragraph, rule `close-15`, and the stash/abandon owner removal,
`close-16`), and both add a `CHANGELOG.md` `## Unreleased` bullet. #188 has written no code yet.
**Options:** proceed and coordinate · sequence after #188 · re-scope.
**Recommendation:** proceed and coordinate — this branch merges first; #188 re-checks its close
edits against `close-15`/`close-16` and the rule-inventory hash when it syncs at implement.

**Answer:**

### Q2 — Overlap with #204 (`chore/204-fix-codeo-close-opens-pr`): proceed, sequence, or re-scope?

`overlap.sh 195` printed, for #204 (assignee `kbajpai`, step `plan (working)`):
`CHANGELOG.md`, `README.md`, `docs/dossier.md`, `docs/handoff.md`, `docs/skills-inventory.md`,
`docs/skills.md`, `glob:CHANGELOG.md`, `glob:README.md`, `glob:docs/dossier.md`,
`glob:docs/handoff.md`, `glob:docs/skills-inventory.md`, `glob:docs/skills.md`,
`glob:skills/close/SKILL.md`, `glob:skills/init/SKILL.md`, `glob:tests/**`, `skills/close/SKILL.md`,
`skills/init/SKILL.md`, `tests/claim.test.sh`, `tests/close-skill.test.sh`,
`tests/fixtures/skills-inventory.rules.sha256`, `tests/github.test.sh`,
`tests/implement-skill.test.sh`, `tests/init-skill.test.sh`, `tests/inventory.test.sh`,
`tests/live-signal.test.sh`, `tests/live.test.sh`, `tests/lock-verify.test.sh`,
`tests/lock.test.sh`, `tests/plan-skill.test.sh`, `tests/qc-skill.test.sh`,
`tests/readme.test.sh`, `tests/skills-doc.test.sh`.

**Why it matters:** the widest overlap. Most of the test-file lines come from #204's `tests/**`
glob, not from files it has actually changed (it has changed only its plan). The real contact is
`skills/close/SKILL.md`, `skills/init/SKILL.md`, the docs pages, and — if #204 adds a rule —
`docs/skills-inventory.md`, the `want` map in `tests/inventory.test.sh` and the pinned
`tests/fixtures/skills-inventory.rules.sha256`, which every rule change regenerates.
**Options:** proceed and coordinate · sequence after #204 · re-scope.
**Recommendation:** proceed and coordinate — this branch merges first; #204 takes the new rule
ids (`init-11`, `close-15`, `close-16`, …) into its own numbering and regenerates the hash after
syncing.

**Answer:**

### Q3 — Overlap with #206 (`fix/206-codeo-cleanup-prints-codeo-rm`): proceed, sequence, or re-scope?

`overlap.sh 195` printed, for #206 (assignee `kbajpai`, step `plan (working)`, waiting on its
own `issue.md` Q1):
`CHANGELOG.md`, `README.md`, `docs/skills.md`, `glob:CHANGELOG.md`, `glob:README.md`,
`glob:docs/skills.md`, `glob:tests/cleanup-skill.test.sh`, `glob:tests/cleanup.test.sh`.

**Why it matters:** shared documentation pages and the changelog only; #206's code
(`scripts/cleanup.sh`, `skills/cleanup/SKILL.md`) does not meet this branch's.
**Options:** proceed and coordinate · sequence after #206 · re-scope.
**Recommendation:** proceed and coordinate — a line-level conflict in a doc page is the most it
can cause.

**Answer:**

## Notes

Step 2 so far (commands run this pass):

- `sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main` (exit 0).
- `overlap.sh 195` → the lines quoted in Q1-Q3 (exit 0).
- `git diff origin/main...HEAD --stat` → 36 files changed, 1704 insertions(+), 78 deletions(-).
- `scope.sh origin/main HEAD` → `suite.shell=true` (exit 0; no `deploy=` line — no environment is configured).
- `overlap.sh --outside 195` → nothing printed (exit 0): every changed path is inside the footprint.
- `overlay.sh qc invariants-extra` → exit 3 (no further rules); `overlay.sh qc wiki-rules` → exit 3. No invariants file and no shared environment are configured.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-27 — Q1-Q3 raised (overlaps with #188, #204, #206 found at step 2) · cost: 1m · opus-5-5 337k in + 738k cached / 2k out
