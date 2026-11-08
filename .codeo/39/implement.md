# Issue #39 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/39 |
| Branch | `fix/fix-board-sh-set-logical` |
| Updated | 2026-11-08 |

## Where this stands

Round 1 is built and handed to `/codeo:qc`. All five tasks of `docs/plans/2026-11-08-board-keys-and-footprint-union.md` are done, each reviewed, and a whole-branch review found nothing blocking. No shared environment is configured, so nothing was leased or deployed.

## Questions

None.

## Outcome

**Plan:** `docs/plans/2026-11-08-board-keys-and-footprint-union.md`, executed with `superpowers:subagent-driven-development`; every implementer and reviewer ran on `sonnet`. The base branch was already merged in (`sync-main.sh`), and `overlap.sh 39` printed nothing.

**Built**
- Task 1 — `bd9f19c`: `scripts/board.sh` defaults `ready`, `backlog`, `inProgress`, `inReview` and `done` to `Ready`, `Backlog`, `In progress`, `In review` and `Done` when `board.statuses` leaves them out; a configured entry wins; any other string passes through. Cases added to `tests/board.test.sh`.
- Task 2 — `b980753`, `c3f5bca`: `set` probes every synced project's Status options before adding the issue anywhere, adds only where the option exists, and deletes a card it just added when the write fails (a failed delete is reported with the item to remove by hand). One fix round: the empty `probed` array was expanded unguarded under `set -u`, which fails on bash 4.3.
- Task 3 — `4e54088`: `skills/plan/SKILL.md` step 10 sub-step 4 says a footprint block written after a send-back covers the branch, checked with `overlap.sh --outside <N>` once the earlier block is replaced. Tests: new pins in `tests/plan-skill.test.sh`; `replaced-block`, `union-block` and `both-blocks` cases in `tests/overlap.test.sh`. `overlap.sh`, `inflight.sh` and `dossier-check.sh` are unchanged.
- Task 4 — `b7abef9`, `fb98bb2`: `docs/handoff.md` and one sentence of `skills/init/SKILL.md` describe the above; one fix round softened "leaves the board as it found it" to a best-effort removal and refreshed a stale comment in `scripts/board.sh`.
- Task 5 — `dc127b3`: `docs/dossier.md`, `docs/handoff.md` (send-back paragraph) and a `CHANGELOG.md` bullet.

**Documentation pages changed:** `docs/handoff.md`, `docs/dossier.md`, `skills/init/SKILL.md`, `CHANGELOG.md`. No wiki module.

**Build:** the `shell` suite's build command is `true`: exit 0. The implementers ran `bash tests/run.sh` before each commit (`all cases passed`), and so did I once more at the end of the round (`all cases passed`); that was bookkeeping, and `/codeo:qc` grades the suites independently. `shellcheck scripts/board.sh` reports 6 findings, the same 6 as at the base commit.

**Deviations from the plan, and why**
- The plan's proof for Tasks 1-2 said `shellcheck` would be silent. `scripts/board.sh` already had 6 findings, so the proof used was "no new findings".
- Task 3 omitted the plan's `rewrite_plan` helper: `scenario` with `SC_A_FILES` already writes the single block, so the helper would have been unused.
- Task 4 also changed a comment in `scripts/board.sh` (comment only), which the plan did not list: it contradicted the new behaviour.

**Deferred findings, for `/codeo:qc` to weigh** (none blocking, per the whole-branch review)
- `CHANGELOG.md` says `set` "removes a card whose write failed"; the code removes only a card it added. User-facing and slightly wrong; a one-word edit.
- `scripts/board.sh`: a failed title read in the probe pass prints `could not add #N to project …`, which is misleading; a code comment near the removal says "so the board is as it was" although the removal is best effort.
- `tests/board.test.sh`: the `undo-fails` case does not assert that `item-delete 1` is in the gh log; the bash 4.3 guard is not proven by the suite, since modern bash passes with or without it.
- `docs/handoff.md` says the replacing footprint block "carries the earlier round's files too", a little broader than the skill's "still changes"; `docs/dossier.md` does not say the check runs after the earlier block is replaced.
- `skills/triage/SKILL.md:220` says the script "adds the issue to the board if it is not on it"; still true where the Status option exists, and not a page the plan names, so it was left alone.
- Unlikely: if the issue is on a project but beyond the first 50 items the lookup reads, a failed write would delete a card that already existed. Pre-existing lookup limit; the delete is best effort.

**Issues filed:** none.

## Log

- 2026-11-08 — implemented: 5 tasks, 8 task and fix commits (`bd9f19c`..`dc127b3`), build `true` exit 0 · cost: pending
