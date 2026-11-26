# Issue #196 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/196 |
| Branch | none |
| Updated | 2026-11-26 |

## Where this stands

Filed as #196.

## Problem as restated

Multi-user safety gap found by a read-only audit of the whole repository (scripts, skills, containers, repo policy); details in the draft below. Parent tracker: #194.

## Questions

None open. The engineer chose to file all twelve groups, then asked to merge them into fewer issues.

## Draft

**Title:** Own and expire shared-environment leases and live signals, with an audited takeover

**Type:** none (user-owned repository). **Labels:** enhancement, priority label as filed.

#### Description
Make shared-environment leases and live signals owned, expirable and safe to take, so one engineer cannot release, hide or delete another's.

#### Motivation / Context
**Leases**
`scripts/intake.sh:555-598, 711-735` writes `by:` but never checks it: anyone who can name `#N` can release or re-take that lease, and the revoke/activate hooks fire (A1, B2). A crashed holder keeps the lease forever; the only way out is that unaudited release (A2, B3). The hooks run before the compare-and-swap (`intake.sh:621-640` vs 657), so two takers can both activate and the loser's `revoke` can undo the winner (A3). Queue order trusts each writer's clock (A13).

**Live signals**
The sandbox is always named `codeo-<N>` and the signal ref has no user in its path (`scripts/live.sh:177-179, 213, 230`), so two engineers share one ref; `beat` force-pushes over it and `clear` deletes it without checking who wrote it, hiding the very conflict the signal exists to show (A4). The machine label is the volume name, so users on different hosts publish the same `refs/codeo/live/12/codeo-12` (C4). `live.sh sweep` deletes every web signal for the issue (A5). Signals are informational and never refuse a second session (B14).

#### Key Requirements
**Leases**
- Release and re-take compare the lease's `by:` login (and checkout) to the current one.
- An audited `steal` is allowed only when the holder's live signal is stale, and records who took it and why.
- Take the lease first (compare-and-swap), then run the hooks; a loser never runs `revoke`.
- Queue order does not depend on a writer's local clock.

**Live signals**
- The login is part of the ref path, or writes use `--force-with-lease` against the last sha this writer saw.
- `clear` and `sweep` remove only the caller's own signals.
- A second session on a live issue is shown the other engineer's signal and asked before continuing.

#### Acceptance Criteria
- [ ] Releasing another login's lease is refused.
- [ ] A second checkout of the same issue is told who holds it and does not re-run the hooks.
- [ ] A stale holder can be stolen with a recorded entry; a live holder cannot.
- [ ] Two simultaneous takers: one wins, the other runs no hooks.
- [ ] Tests cover each case.
- [ ] Two logins on one issue publish two signals; neither overwrites the other.
- [ ] `clear` and `sweep` leave the other login's signal.
- [ ] A second session sees the first and must confirm.
- [ ] Tests cover each case.

#### Out of Scope
Changing what the hooks do.

Hard-refusing a second session.

#### Reference
Parent #194.
