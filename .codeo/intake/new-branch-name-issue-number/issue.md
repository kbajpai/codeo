# Issue — issue

## Questions

1. Branch shape → `<type>/<N>-<slug>` (engineer). 2. Old branches → leave them, keep working (engineer). 3. Scope of the consolidated issue → F19-F21 + F24 and the deferred minors (engineer).

## Draft

**Title:** Put the issue number in the branch name /codeo:init cuts
**Type:** none (user-owned repository) · **Labels:** enhancement

### Description

`/codeo:init` cuts a branch whose name comes from `scripts/branch-name.sh`: `<type>/<first five title words>`. The issue number is never part of it (the script's header says so). A developer looking at `feat/live-signal-leftovers-104-refresh` cannot tell the issue is #118, and the `104` in that name is a different issue. They have to open the dossier or the pull request to find out.

The branch name should carry the issue number, so a developer can identify the issue from the branch alone.

### Motivation / Context

Raised by the engineer during `/codeo:triage` on 2026-11-18: "I want the branch to somehow have the issue number in the branch so that developer can identify the issue from branch." Two branches in this repository show the gap: #99's `feat/make-sbx-issue-sandbox-usable` and #118's `feat/live-signal-leftovers-104-refresh`.

A title-only name also has a cost today. `claim.sh` refuses a second issue whose title derives the same name ("retitle #N … or wait for #M to close"). A name that carries the number cannot collide between issues.

### Key Requirements

- `branch-name.sh <N>` prints `<type>/<N>-<slug>`, for example `feat/118-live-signal-leftovers-104-refresh`. The type and the slug are derived as they are today.
- The number is the first part of what follows the type, so branches sort and read by issue.
- Everything that derives or looks up a branch by name (`/codeo:init`'s collision and resume checks, `claim.sh`, and any skill or script that names the branch) uses the new name.
- A workflow already under way on an old-style branch keeps working: `/codeo:init` recognises it by its dossier, as it does for a branch of any other name. Existing branches are not renamed.
- The title-collision refusal in `claim.sh` is kept or dropped on its merits. If dropped, its message, docs and tests go with it.
- The docs and `CHANGELOG.md` describe the new name, including the header comment in `branch-name.sh`.

### Acceptance Criteria

- [ ] `bash scripts/branch-name.sh <N>` prints `<type>/<N>-<slug>` for an issue with a mapped label and for one with none (`chore`).
- [ ] Two issues with the same title derive two different branch names.
- [ ] `/codeo:init #<N>` cuts and pushes the numbered branch for a new issue.
- [ ] A workflow already on an old-style branch is resumed, not started a second time.
- [ ] `claim.sh` behaves as the plan decides for same-title issues, and its tests and message match.
- [ ] `tests/branch-name.test.sh`, `tests/run.sh` and the docs agree with the new shape; the old "number is never part of it" statement is gone.

### Out of Scope

- Renaming branches that are already cut or pushed, and any command to rename an in-flight branch.
- Changing the `<type>` mapping (`labelTypes`) or how many title words the slug keeps.
- Putting the number in the sandbox or container names, which already carry it.

### Reference

- `scripts/branch-name.sh` (its header and the slug rule), `scripts/claim.sh:210` (the same-name refusal), `skills/init/SKILL.md` step 6.
- Branches that prompted it: `feat/make-sbx-issue-sandbox-usable` (#99), `feat/live-signal-leftovers-104-refresh` (#118).
- Raised in `/codeo:triage` run 6, 2026-11-18.

## Log

2026-11-18 — drafted, awaiting approval · cost: unavailable
