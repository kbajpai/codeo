# Issue #87 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/87 |
| Branch | `fix/dev-container-start-script-reports` |
| Updated | 2026-11-15 |

## Where this stands

Round 1, done. The issue's own dossier settled the behaviour (report and leave the file; the start script only), so the one thing to ask was the `CHANGELOG.md` overlap with #83, and Q1 is answered. Nothing is open. The plan was approved and written to `docs/plans/2026-11-15-report-lock-file-naming-no-issue.md`; the next step is `/codeo:implement`.

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

2026-11-15

**Plan:** `docs/plans/2026-11-15-report-lock-file-naming-no-issue.md`, a scoped executable plan (two tasks) under `docs/plans/`, approved by the engineer and left unstaged. No reference doc under `docs/`: there is no standing decision here.

**Decisions.** Q1 = proceed and coordinate: #83 also adds a bullet under `## Unreleased` in `CHANGELOG.md`, so Task 2 merges `origin/main` first and keeps both bullets. Approach A: a new first arm in step 3a of `devcontainer-start.sh`, testing the file with `container-name.sh`'s pattern (`^issue:[[:space:]]*#*[0-9]+`); report and leave the file, take no lock, on any branch (`issue.md` Q1, Q2). Calls made in the plan: a file naming no issue on a detached HEAD gives the file's TODO alone; an `issue:` line with no number is reported; a `.codeo/active` that is a directory stays unreported; the file is compared byte for byte with `cmp`.

**Rejected.** Asking `container-name.sh --docker` whether the name is "home" (a new dependency and failure path for one line of pattern); a shared helper both scripts source (changes `container-name.sh`, out of scope).

**Documentation.** `.devcontainer/README.md` (*What the start script does*) and `CHANGELOG.md`. No page under `docs/` describes the start script, so none moves. No intake question was resolved here.

### Footprint

```
files:      .devcontainer/scripts/devcontainer-start.sh, tests/devcontainer.test.sh, .devcontainer/README.md, CHANGELOG.md, docs/plans/2026-11-15-report-lock-file-naming-no-issue.md
wiki:       none
exclusive:  none
sequenced:  none — CHANGELOG.md overlaps #83; proceed and coordinate (Q1)
```

## Log

- 2026-11-15 — Q1 raised and answered in the conversation (#83, glob:CHANGELOG.md: proceed and coordinate); plan drafted as .codeo/87/plan-draft.md, awaiting review · cost: 3m · fable-5-2 103k in + 575k cached / 16k out
- 2026-11-15 — planned: docs/plans/2026-11-15-report-lock-file-naming-no-issue.md · cost: 5m · fable-5-2 115k in + 844k cached / 18k out · sonnet-5-5 112k in + 163k cached / 1k out
