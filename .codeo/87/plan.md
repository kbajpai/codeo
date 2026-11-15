# Issue #87 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/87 |
| Branch | `fix/dev-container-start-script-reports` |
| Updated | 2026-11-15 |

## Where this stands

Round 1. The issue's own dossier settled the behaviour (report and leave the file; the start script only), so the one thing left to ask was the `CHANGELOG.md` overlap with #83, and Q1 is answered. Nothing is open. The plan is being drafted as `.codeo/87/plan-draft.md` for review; nothing is written under `docs/plans/` until it is approved.

## Questions

### Q1 — Overlap with #83 on `glob:CHANGELOG.md`: proceed and coordinate, sequence after #83, or re-scope?

**Why it matters:** criterion 5 needs a bullet under `## Unreleased` in `CHANGELOG.md`, and #83 (branch `feat/re-run-haiku-5-5`, assignee kbajpai, step `qc`, working) lists `CHANGELOG.md` in its footprint and has changed it on its branch. Whichever branch merges second gets a conflict in that section. *Proceed* means the plan's last task merges `origin/main` first and keeps both bullets; *sequence* means that task waits for #83 to merge; *re-scope* would drop the CHANGELOG entry, which criterion 5 does not allow. What overlaps is the path `CHANGELOG.md` and nothing else. (#73 is also in flight and shares no file with this plan.)

**Options:** proceed and coordinate (recommended) · sequence after #83 · re-scope.

**Answer:**
Proceed and coordinate. Go with the recommendation (engineer, in the conversation, 2026-11-15).

## Notes

Read before drafting, so the plan does not re-ask it:

- `devcontainer-start.sh` step 3a: `[[ -s .codeo/active ]]` is the "a lock is held" test, the first arm of the chain that otherwise reports a detached HEAD or calls `lock.sh take container`. A zero-byte file is removed just before it (#57).
- `container-name.sh:34` reads the number with `^issue:[[:space:]]*#*\([0-9]\{1,\}\)`. That is the rule for "names an issue" (`issue.md` Q1, Key Requirements).
- `folder-check.sh` is silent for the folder `codeo-home` whatever the branch, and for `codeo-<digits>` off the base branch, when the file names no issue. So with the folders the tests use, the new TODO is the only one.
- `tests/devcontainer.test.sh` already has the harness: `ds_setup`, `ds_lock_stub`, `ds_branch`, `ds_lock_ready`, `ds_todos`, `ds_lock_calls`, and the `start_*lock_file*` cases at lines 512-544.
- The `shell` suite has no `filter`; the proof of a task is the whole `bash tests/run.sh`.
- No overlay section for `plan` (`plan-shape`, `proof-of-done`, `wiki-rules` all exit 3); no invariants document, no shared environment, no `wiki` module, no `resources[]`.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-15 — Q1 raised and answered in the conversation (#83, glob:CHANGELOG.md: proceed and coordinate); plan drafted as .codeo/87/plan-draft.md, awaiting review · cost: 3m · fable-5-2 103k in + 575k cached / 16k out
