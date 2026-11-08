# Issue new-codeo-tooling-fixes — issue

Filed from triage 2026-11-08 Q1 + Q4 (`.codeo/intake/triage/2026-11-08.md`).

## Questions

### Q1 — Group `board.sh` key handling and the plan footprint rule in one issue?
They are unrelated code (`scripts/board.sh` vs the plan skill / `overlap.sh`), but both are small codeo-tooling defects found while using the pipeline. **Recommended:** one issue, two requirements. Alternative: two issues. **Answer:** _open_

## Draft

**Title:** Fix `board.sh set` for logical status keys without `board.statuses`, and keep a re-planned footprint as the union of all rounds

**Type:** none (user-owned repo has no Issue Types) · **Labels:** bug

### Description
Two defects surfaced while running the pipeline on #36.

1. The triage skill passes the logical keys `ready` and `backlog` to `board.sh set`. `scripts/board.sh` maps a logical key to an option name only when `board.statuses` configures it (`board.sh:123`); otherwise the string is treated as an option name. On a project without `board.statuses`, `board.sh set 36 ready` fails with `project #3 Codeo has no option 'ready'` (exit 1) after adding the card to the board with Status `unset`; `board.sh set 36 Ready` works.
2. When `/codeo:plan` runs a second round, round 2's footprint replaces round 1's. `overlap.sh --outside 36` on #36 then printed `.devcontainer/devcontainer.json` and `CHANGELOG.md` as outside the footprint, so other workflows were told too little.

### Motivation / Context
Every *mark Ready* and *leave in the backlog* triage runs fails on such a project and leaves a half-moved card. A too-small footprint lets a real overlap between workflows go unflagged.

### Key Requirements
- `board.sh set <N> ready` and `set <N> backlog` as triage calls them behave the same whether or not `board.statuses` is configured, or the skills stop passing keys the script may not accept.
- A failed `set` does not leave a card on the board with Status `unset` that was not there before.
- A footprint recorded for a later plan round covers every file of the earlier rounds still part of the branch.

### Acceptance Criteria
- [ ] With `board.statuses` unset, the call triage makes to mark Ready moves the card to the project's Ready option.
- [ ] The same for Backlog.
- [ ] A `set` that fails leaves the card's prior state (or absence) unchanged.
- [ ] After a two-round plan, `overlap.sh --outside <N>` prints only files really outside the branch's changes.
- [ ] Tests cover each of the above.

### Out of Scope
Changing which Status names a project uses; any other board behaviour.

### Reference
Triage 2026-11-08 Q1, Q4; triage run 2026-11-07-4 Outcome; qc.md for #36, N7; `scripts/board.sh:119-123`.
