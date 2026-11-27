# Issue #195 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/195 |
| Branch | feat/195-identify-acting-user-strictly-verify |
| Updated | 2026-11-27 |

## Where this stands

Initialized: branch `feat/195-identify-acting-user-strictly-verify` cut off `main` at `d9345429b1f0d2758fc0d5db0c46c31e73e484cc`. Next: `/codeo:plan`.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/195 — Identify the acting user strictly and verify ownership at every workflow step |
| State | open · labels `enhancement`, `priority: high` |
| Branch | `feat/195-identify-acting-user-strictly-verify` off `main` at `d9345429b1f0d2758fc0d5db0c46c31e73e484cc` |
| Board | Ready → In progress |

**Problem.** codeo cannot tell reliably who is acting. `github.sh` falls back to an unverified `CODEO_GITHUB_LOGIN`, a shared bot token makes every engineer one login, and with no login `init` skips the assignee check. Later steps (plan, implement, qc, close, `lock.sh take`) never compare the person running them to the assignee or the last resume line, so a second engineer can run `close` on someone else's branch, or a stale checkout can act after another engineer resumed. Stash and abandon remove the current login rather than the real assignee.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] With `gh api user` failing and the variable set, `init` outside a web session refuses.
- [ ] With a Bot login, `init` refuses.
- [ ] A normal `init` records the login in `init.md`, the lock and the live signal.
- [ ] Tests cover each case.
- [ ] B running close, plan, implement or qc on A's branch is refused with one line naming the owner.
- [ ] A stale checkout of A after B resumed is refused.
- [ ] The override works once and is recorded.
- [ ] Stash by a non-owner does not remove the owner's assignment or move the card.
- [ ] Tests cover each step.

**Out of scope.** Comparing the recorded login at later steps (see the ownership-verify issue). Lease ownership (separate issue).

**Open at intake.** The issue's Out of Scope line "Comparing the recorded login at later steps (see the ownership-verify issue)" is a leftover from before the identity and ownership issues were merged: ownership verification is now this issue's own Key Requirements and Acceptance Criteria. `/codeo:plan` should treat the Key Requirements and Acceptance Criteria as authoritative; the issue text itself is not edited here.

## Log

- 2026-11-27 — initialized: branch feat/195-identify-acting-user-strictly-verify off main at d9345429b1f0d2758fc0d5db0c46c31e73e484cc · cost: 1m · sonnet-5-5 18k in + 602k cached / 3k out
