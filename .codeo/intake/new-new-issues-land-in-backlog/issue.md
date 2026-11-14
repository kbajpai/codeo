# Issue — new issues land in Backlog

| | |
|---|---|
| Status | draft, waiting for approval |
| Updated | 2026-11-14 |

## Where this stands

Q1-Q3 answered in the conversation. Draft below, waiting for the engineer's approval before filing.

## Questions

### Q1 — Should codeo set Backlog, or is GitHub Projects' built-in auto-add / set-Status workflow enough?

**Answer:** codeo does it: `/codeo:issue` runs `board.sh set <N> backlog` after filing.

### Q2 — What happens if the Backlog move fails at filing?

**Answer:** report it and keep going; the issue is still filed and its number returned.

### Q3 — Should triage still ask about a new Backlog issue with no ledger row?

**Answer:** yes, once; "leave in the backlog" then just records it.

## Draft

**Title:** File new issues straight into the board's Backlog so marking Ready moves Backlog → Ready
**Labels:** `enhancement` · **Issue Type:** none (user-owned repository)

### Description

When a board is configured, `/codeo:issue` should put every issue it files on the gate project with Status **Backlog**, right after the issue is created. Marking the issue Ready (in `/codeo:triage`) then moves the card from Backlog to Ready, instead of adding a card that was never on the board.

### Motivation / Context

`/codeo:issue` files an issue and makes no board call, so the new issue isn't on the board at all (`board.sh status <N>` prints `none`). It doesn't appear in the board's Backlog column, and the first card anyone sees appears when triage marks it Ready. On 2026-11-14 that happened to #67, #69 and #70: each was missing from the Backlog view until triage ran `board.sh set <N> ready`, which printed `#70 (not on the board) → Ready on #3 Codeo`. The board isn't a complete list of the open issues codeo filed.

### Key Requirements

- With a board configured, `/codeo:issue` sets the new issue's Status to Backlog once the issue exists, through `board.sh set <N> backlog` (which already adds an issue that isn't on the board). With no board configured it makes no board call, as today.
- A failed Backlog move doesn't fail the filing. The issue number is still returned and reported. The report quotes the script's message and the command that fixes it, for example a missing `project` token scope or a hosted web session where `board.sh set` is unavailable.
- When `/codeo:triage` or another skill calls `/codeo:issue`, the issue lands in Backlog the same way, and the caller's follow-up "is it ready to work on?" moves it Backlog → Ready.
- `/codeo:triage` still asks once about an open, never-started issue it has no ledger row for, even if the issue is already in Backlog. "Leave in the backlog" then records the decision, with no card move needed, and the issue isn't shown again (rule triage-05). Being in Backlog doesn't count as a triage decision.
- The issue skill's hand-off and non-goals text, and triage's description of who writes Backlog, say that `/codeo:issue` writes the Backlog Status at filing.

### Acceptance Criteria

- [ ] On a project with a board, `board.sh status <N>` prints `Backlog` straight after `/codeo:issue` files issue N.
- [ ] Marking that issue Ready in `/codeo:triage` prints a `board.sh` line whose old status is `Backlog`, not `(not on the board)`.
- [ ] On a project with no board, `/codeo:issue` files the issue and makes no `board.sh` call.
- [ ] When `board.sh set` fails, the issue is still filed, its number is reported, and the failure is quoted with its fix.
- [ ] `/codeo:triage` asks about a new Backlog issue with no ledger row, and once that issue is decided it isn't shown again.
- [ ] The skill tests cover the new `/codeo:issue` board step and the unchanged no-board path.

### Out of Scope

- Issues filed outside codeo, for example in the GitHub web UI. GitHub Projects' built-in "Auto-add to project" and "Item added → set Status" workflows can cover those. That's a board setting, not codeo's.
- Moving existing open issues that aren't on the board into Backlog.
- Any other Status move. In progress, In review and Done stay with `/codeo:init` and `/codeo:close`.

### Reference

- `skills/issue/SKILL.md` steps 7–8 (filing, report and closing block). #69 is reworking that closing block on `feat/fix-closing-blocks-that-name`, so this issue should land after #69.
- `skills/triage/SKILL.md`, rule triage-05 and step 5 "Leave in the backlog".
- `scripts/board.sh` `set <N> backlog`.
- Triage runs `.codeo/intake/triage/2026-11-14.md`, `2026-11-14-2.md`, `2026-11-14-4.md` (#67, #69, #70 arriving as `none`).
