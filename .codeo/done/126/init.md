# Issue #126 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/126 |
| Branch | `feat/put-issue-number-branch-name` |
| Updated | 2026-11-18 |

## Where this stands

Branch `feat/put-issue-number-branch-name` cut off `main` at `9f1446158255d557f79970bd3774d418af75c733`, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/126 — Put the issue number in the branch name /codeo:init cuts |
| State | open · labels `enhancement` |
| Branch | `feat/put-issue-number-branch-name` off `main` at `9f14461` |
| Board | Ready → In progress |

**Problem.** `/codeo:init` cuts a branch named `<type>/<first five title words>` by `scripts/branch-name.sh`; the number is never part of it, so a developer cannot tell the issue from the branch alone (`feat/live-signal-leftovers-104-refresh` is #118, and the `104` is another issue). The name should carry the number: `<type>/<N>-<slug>`, type and slug derived as today. Everything that derives or looks up a branch by name must use the new shape, and workflows already on old-style branches must still resume by their dossier. The same-title refusal in `claim.sh` is kept or dropped on its merits.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] `bash scripts/branch-name.sh <N>` prints `<type>/<N>-<slug>` for an issue with a mapped label and for one with none (`chore`).
- [ ] Two issues with the same title derive two different branch names.
- [ ] `/codeo:init #<N>` cuts and pushes the numbered branch for a new issue.
- [ ] A workflow already on an old-style branch is resumed, not started a second time.
- [ ] `claim.sh` behaves as the plan decides for same-title issues, and its tests and message match.
- [ ] `tests/branch-name.test.sh`, `tests/run.sh` and the docs agree with the new shape; the old "number is never part of it" statement is gone.

**Out of scope.** Renaming branches already cut or pushed, and any command to rename an in-flight branch; changing the `<type>` mapping (`labelTypes`) or how many title words the slug keeps; putting the number in sandbox or container names, which already carry it.

**Open at intake.** None stated by the issue beyond one decision left to the plan: whether the same-title refusal in `claim.sh` (`scripts/claim.sh:210`) is kept or dropped.

## Log

- 2026-11-18 — initialized: branch feat/put-issue-number-branch-name off main at 9f14461 · cost: unavailable
