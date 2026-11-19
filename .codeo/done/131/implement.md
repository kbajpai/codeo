# Issue #131 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/131 |
| Branch | `feat/make-sbx-sandbox-lock-follow` |
| Updated | 2026-11-18 |

## Where this stands

Round 1 is done and handed off to `/codeo:qc`.

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

Round 1. All 13 tasks of the plan are done, each reviewed, and the whole-branch review came back clean.

**Built.**
- `scripts/lock.sh` takes `--sandbox <name>` and writes a `sandbox:` line with no `volume:` line; the dev container lock is unchanged. `scripts/live.sh` labels a sandbox lock's machine with the sandbox name.
- The start script passes `--sandbox`, naming the sandbox from the marker, else the clone folder's name. `.sbx/codeo-sandbox.sh` writes the sandbox name into the marker, names the way out when the start script fails, needs no pin for an existing sandbox, and `end` names `sbx rm --force` for a sandbox it cannot read.
- `/codeo:close` (overlay and SKILL.md) covers finished, stash and abandon for a sandbox lock and names `codeo-sandbox.sh end <N>`.
- Tests: lock, live, devcontainer, sandbox and close-removal suites gained cases for each criterion (failed `run -d`, no-pin rerun, `end` with and without `--force`, the no-marker case with `$HOME/.codeo-sandbox` present).
- Pages: `docs/handoff.md`, `docs/extension-points.md`, `.sbx/README.md` (marker, `issue` diagram, unreadable-sandbox paragraph), `.devcontainer/README.md`, `CHANGELOG.md` (`## Unreleased`).

**Deviation from plan.md Q1.** Its fallback wording would have recorded `codeo-home` when the marker is empty. The start script now falls back to the clone folder's name (commit `e5f838a`).

**Build and tests.** Suite `shell`, build `true`: nothing to build. `bash tests/run.sh` passes ("all cases passed", exit 0), also with `HOME` holding a `.codeo-sandbox`. No shared environment: no lease, no deploy. All 12 acceptance criteria in init.md are covered by a test or a page change; no test reads `CHANGELOG.md` by line number.

**Base branch.** `sync-main.sh`: the branch already contains `origin/main`. Overlaps with #133 and #126 were handled by "proceed and coordinate" (Q1, Q2); the second PR to merge resolves any conflict in the README, CHANGELOG and handoff pages.

**Note.** The installed plugin (v1.0.7) `lock.sh` ignores `--sandbox` for container hosts, so a real sandbox shows the `sandbox:` line only after a plugin release and pin bump.

## Log
- 2026-11-19 · implement round 1 · all 13 tasks done · cost: 131m · sonnet-5-5 1.1M in + 27M cached / 152k out
