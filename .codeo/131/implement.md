# Issue #131 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/131 |
| Branch | `feat/make-sbx-sandbox-lock-follow` |
| Updated | 2026-11-18 |

## Where this stands

Round 1. Q1 and Q2 are answered (proceed and coordinate); dispatching the plan's tasks.

## Questions

### Q1 — #133 (`feat/codeo-command-host-short-bash`, kbajpai, at `init`) also edits `glob:.devcontainer/README.md`, `glob:.sbx/README.md` and `glob:CHANGELOG.md`. How do we proceed?

**Why it matters:** both plans edit these three files (this plan's Tasks 11 and 12 touch them; #133's footprint lists them with `.devcontainer/codeo` and `tests/codeo-command.test.sh`). The code files do not overlap, so only the documentation tasks are at risk. Two branches editing the same README sections or the same `## Unreleased` CHANGELOG bullet area can conflict at merge. #133 has not started implementing yet (`changed: none`).
**Options:**
- **Proceed and coordinate (my pick).** Build all 13 tasks now. The README and CHANGELOG edits are small, separate hunks (the `issue` marker step, *Ending a sandbox*, a sentence in the dev container README, one CHANGELOG bullet), so whichever PR merges second resolves a textual conflict with `sync-main.sh`.
- **Sequence after #133.** Pause until #133 merges, then build on top of it; no conflict, but this work waits on a workflow that has not begun implementing.
- **Re-scope.** Drop Tasks 11-12 (the README and CHANGELOG pages) from this plan and file them as a follow-up; this needs `/codeo:plan` again.

**Answer:**
Proceed and coordinate, my pick, as the engineer chose ("A", 2026-11-18). (Transcribed from the chat answer.)

### Q2 — #126 (`feat/put-issue-number-branch-name`, kbajpai, at `plan`, waiting for `/codeo:implement`) also edits `glob:CHANGELOG.md` and `glob:docs/handoff.md`. How do we proceed?

**Why it matters:** #126's footprint is new since Q1 was raised. This plan's Tasks 10 and 12 edit `docs/handoff.md` (the lock's `container` bullet, the live signal's machine paragraph) and `CHANGELOG.md`; #126 edits both too (and `docs/dossier.md`, `scripts/branch-name.sh`, `scripts/claim.sh`, `skills/init/SKILL.md`, none of which this plan touches). #126 has not started implementing (`changed:` lists only its plan).
**Options:**
- **Proceed and coordinate (my pick).** Same reasoning as Q1: the edits are small separate hunks, and whichever PR merges second resolves any textual conflict with `sync-main.sh`.
- **Sequence after #126.** Wait for #126 to merge.
- **Re-scope.** Drop Tasks 10 and 12 into a follow-up; needs `/codeo:plan` again.

**Answer:**
Proceed and coordinate, as the engineer chose (2026-11-18). (Transcribed from the chat answer.)
## Notes

- `sync-main.sh` reported the branch already contains `origin/main`; nothing merged.
- No shared environment is configured: no lease, no deploy, no redeploy check.
- Subagent model for every dispatch: `sonnet` (`models.subagent` unset).

## Outcome

_Pending — written at the hand-off._

## Log
