# Issue #71 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/71 |
| Branch | `feat/file-new-issues-straight-board` |
| Updated | 2026-11-15 |

## Where this stands

Branch `feat/file-new-issues-straight-board` to be cut off `main` at 90075d4, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/71 — File new issues straight into the board's Backlog so marking Ready moves Backlog → Ready |
| State | open · labels `enhancement` |
| Branch | `feat/file-new-issues-straight-board` off `main` at `90075d4` |
| Board | Ready → In progress |

**Problem.** `/codeo:issue` files an issue and makes no board call, so a new issue is not on the board (`board.sh status <N>` prints `none`) and is missing from the Backlog view until `/codeo:triage` marks it Ready. With a board configured, `/codeo:issue` should set the new issue's Status to Backlog right after filing, through `board.sh set <N> backlog`, so marking Ready moves Backlog → Ready. A failed move must not fail the filing, and with no board there is no board call.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] On a project with a board, `board.sh status <N>` prints `Backlog` straight after `/codeo:issue` files issue N.
- [ ] Marking that issue Ready in `/codeo:triage` prints a `board.sh` line whose old status is `Backlog`, not `(not on the board)`.
- [ ] On a project with no board, `/codeo:issue` files the issue and makes no `board.sh` call.
- [ ] When `board.sh set` fails, the issue is still filed, its number is reported, and the failure is quoted with its fix.
- [ ] `/codeo:triage` asks about a new Backlog issue with no ledger row, and once that issue is decided it isn't shown again.
- [ ] The skill tests cover the new `/codeo:issue` board step and the unchanged no-board path.

**Out of scope.**
- Issues filed outside codeo (GitHub's built-in project workflows can cover those; a board setting, not codeo's).
- Moving existing open issues that aren't on the board into Backlog.
- Any other Status move: In progress, In review and Done stay with `/codeo:init` and `/codeo:close`.

**Open at intake.** None. The issue's Reference notes it should land after #69, which has since merged.

## Log

- 2026-11-15 — initialized: branch feat/file-new-issues-straight-board off main at 90075d4 · cost: unavailable
