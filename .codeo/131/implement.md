# Issue #131 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/131 |
| Branch | `feat/make-sbx-sandbox-lock-follow` |
| Updated | 2026-11-18 |

## Where this stands

Round 1. The plan is committed and the branch already contains `origin/main`. No task is dispatched: `overlap.sh` found #133 touching three of this plan's files, and Q1 must be answered first.

## Questions

### Q1 — #133 (`feat/codeo-command-host-short-bash`, kbajpai, at `init`) also edits `glob:.devcontainer/README.md`, `glob:.sbx/README.md` and `glob:CHANGELOG.md`. How do we proceed?

**Why it matters:** both plans edit these three files (this plan's Tasks 11 and 12 touch them; #133's footprint lists them with `.devcontainer/codeo` and `tests/codeo-command.test.sh`). The code files do not overlap, so only the documentation tasks are at risk. Two branches editing the same README sections or the same `## Unreleased` CHANGELOG bullet area can conflict at merge. #133 has not started implementing yet (`changed: none`).
**Options:**
- **Proceed and coordinate (my pick).** Build all 13 tasks now. The README and CHANGELOG edits are small, separate hunks (the `issue` marker step, *Ending a sandbox*, a sentence in the dev container README, one CHANGELOG bullet), so whichever PR merges second resolves a textual conflict with `sync-main.sh`.
- **Sequence after #133.** Pause until #133 merges, then build on top of it; no conflict, but this work waits on a workflow that has not begun implementing.
- **Re-scope.** Drop Tasks 11-12 (the README and CHANGELOG pages) from this plan and file them as a follow-up; this needs `/codeo:plan` again.

**Answer:**

## Notes

- `sync-main.sh` reported the branch already contains `origin/main`; nothing merged.
- No shared environment is configured: no lease, no deploy, no redeploy check.
- Subagent model for every dispatch: `sonnet` (`models.subagent` unset).

## Outcome

_Pending — written at the hand-off._

## Log
