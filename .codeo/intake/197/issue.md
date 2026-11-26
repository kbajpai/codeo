# Issue #197 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/197 |
| Branch | none |
| Updated | 2026-11-26 |

## Where this stands

Filed as #197.

## Problem as restated

Multi-user safety gap found by a read-only audit of the whole repository (scripts, skills, containers, repo policy); details in the draft below. Parent tracker: #194.

## Questions

None open. The engineer chose to file all twelve groups, then asked to merge them into fewer issues.

## Draft

**Title:** Claim per issue, and make shared-state checks and board moves fail closed and conditional

**Type:** none (user-owned repository). **Labels:** enhancement, priority label as filed.

#### Description
Make claims atomic per issue and make the shared-state checks and writes fail closed and conditional, so a race or an unreadable check never reads as all clear.

#### Motivation / Context
**Claim per issue**
The branch name is derived from the issue title and labels (`scripts/branch-name.sh:101-122`), which anyone can edit. Two `init`s on one issue after a retitle or relabel derive different names, and the create-only push at `scripts/claim.sh:288` succeeds for both (A8, D9). The assignee-add comes after the claim and is additive (A9).

**Fail closed**
A failed fetch in `scripts/inflight.sh:79` only prints a note and reads stale refs, and `scripts/overlap.sh:269` discards inflight's stderr and exit status, so any failure reads as "no overlap" (A10). The tracking comment is read, edited and rewritten with no lock, so simultaneous adds lose rows; it matches any comment containing the marker; every caller ignores its failures; and `confirm` lets you proceed when `gh` cannot read it (C5). `.codeo/active` is per checkout, so two engineers can start the same issue on their own hosts and only the claim stops them (C6).

**Board moves**
`scripts/board.sh:195-299` writes a status unconditionally: a late stash `Ready` can overwrite a concurrent resume's `In progress` (A11). Triage runs `board.sh set ready|backlog` on answers to stale run files, so if B already ran `/codeo:init #50` the card moves backwards (B5). A web session's `unavailable` also skips the Ready gate.

#### Key Requirements
**Claim per issue**
- The same atomic push also creates a create-only per-issue ref (for example `refs/codeo/claim/<N>`), so a second claim of the same issue fails whatever the branch is called; or the name is frozen at first claim.
- A refused claim names the existing branch and owner.
- The assignee is checked before the claim and set as part of it where GitHub allows.

**Fail closed**
- A stale or failed fetch makes inflight and overlap exit non-zero, and callers refuse or ask rather than proceed.
- The tracker comment is matched by author and marker, updated with a compare on the comment's revision, and its failures surface.
- `confirm` refuses when the comment cannot be read.

**Board moves**
- `board.sh set` takes `--from <status>` and refuses when the card's current status differs.
- Triage and stash re-check status, assignee and in-flight state immediately before writing.
- An `unavailable` status in a web session is reported, not silently treated as passing the gate.

#### Acceptance Criteria
- [ ] Retitling an issue between two `init`s leaves the second refused.
- [ ] Two concurrent `init`s of one issue: exactly one succeeds.
- [ ] `--resume` still works on the claimed branch.
- [ ] Tests cover each case.
- [ ] With the remote unreachable, overlap and start refuse with one line.
- [ ] Two simultaneous tracker adds both survive.
- [ ] A foreign comment containing the marker is not treated as the tracker.
- [ ] Tests cover each case.
- [ ] A move whose `--from` no longer matches is refused with the current status shown.
- [ ] Triage does not move a card that has since been started.
- [ ] Tests cover each case.

#### Out of Scope
Changing the branch naming scheme.

A separate status service.

Locking the project board.

#### Reference
Parent #194.
