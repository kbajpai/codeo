# Issue #161 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/161 |
| Branch | `docs/documentation-leftovers-154-146-removal` |
| Updated | 2026-11-24 |

## Where this stands

Written after the work was done. The edits were made in a hosted web session without `/codeo:plan` having run there; the plan file and this dossier record them from the commits, and nothing here was decided ahead of the code. Next step: `/codeo:implement` is recorded the same way, then `/codeo:qc`.

## Questions

None.

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-24-documentation-leftovers-154-146-161.md` (written after the fact; the engineer approved the scope in conversation before the edits) |
| Shape | an executable plan under `docs/plans/`, six tasks; no reference doc, nothing here is a standing decision |

**Decisions.**
- Every `.devcontainer/README.md` wording is checked against `.devcontainer/codeo` and `.sbx/codeo-sandbox.sh` before it is written, so the fix does not trade one overstatement for another.
- The v1.0.8 `Shared state:` line is edited on `main` only. The published Release notes of `v1.0.8` are not repaired and the tag is not moved; the engineer said to skip the release edit.
- Out of scope, as the issue says: #154 F6, #146 F3.

**Documentation pages the plan changes:** `.devcontainer/README.md` (Tasks 1-3), `CHANGELOG.md` (Task 4), `docs/release-checklist.md` (Task 5). No wiki module.

**Intake questions resolved:** none; init's Open at intake was empty.

**Footprint beyond the plan's six tasks.** Two edits outside #161's scope were made in the same session and are listed so another workflow sees them: a `SessionStart` hook that installs the codeo plugins in cloud sessions (`.claude/hooks/session-start.sh`, `.claude/settings.json`) and the one test assertion it forced (`tests/live-signal.test.sh`). `implement.md` records them as a deviation.

### Footprint

```
files:      .devcontainer/README.md, CHANGELOG.md, docs/release-checklist.md, .claude/hooks/session-start.sh, .claude/settings.json, tests/live-signal.test.sh, docs/plans/2026-11-24-documentation-leftovers-154-146-161.md, .codeo/161/**
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-24 — plan recorded after the work: docs/plans/2026-11-24-documentation-leftovers-154-146-161.md · cost: unavailable
