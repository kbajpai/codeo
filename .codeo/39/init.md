# Issue #39 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/39 |
| Branch | `fix/fix-board-sh-set-logical` |
| Updated | 2026-11-08 |

## Where this stands

Branch `fix/fix-board-sh-set-logical` off `main` at `245d10efc54bf0c68d4134026591361ff7d7a5cc`. Ready to hand off to `/codeo:plan`.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/39 — Fix `board.sh set` for logical status keys without `board.statuses`, and keep a re-planned footprint as the union of all rounds |
| State | open · labels `bug` |
| Branch | `fix/fix-board-sh-set-logical` off `main` at `245d10e` |
| Board | Ready → In progress |

**Problem.** Two defects found while running the pipeline on #36. (1) Triage passes the logical keys `ready` and `backlog` to `board.sh set`, but `scripts/board.sh` maps a logical key to an option name only when `board.statuses` configures it (`board.sh:123`); without it `set 36 ready` fails with `project #3 Codeo has no option 'ready'` after adding the card with Status `unset`, while `set 36 Ready` works. (2) A second `/codeo:plan` round's footprint replaces round 1's, so `overlap.sh --outside 36` listed `.devcontainer/devcontainer.json` and `CHANGELOG.md` as outside the footprint and other workflows were told too little.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] With `board.statuses` unset, the call triage makes to mark Ready moves the card to the project's Ready option.
- [ ] The same for Backlog.
- [ ] A `set` that fails leaves the card's prior state (or absence) unchanged.
- [ ] After a two-round plan, `overlap.sh --outside <N>` prints only files really outside the branch's changes.
- [ ] Tests cover each of the above.

**Out of scope.** Changing which Status names a project uses; any other board behaviour.

**Open at intake.** None recorded in the issue.

## Log

- 2026-11-08 — initialized: branch fix/fix-board-sh-set-logical off main at 245d10efc54bf0c68d4134026591361ff7d7a5cc · cost: 1m · sonnet-5-5 16k in + 706k cached / 3k out
