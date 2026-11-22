# Issue — issue (new: live-signal leftovers from #138)

## Questions

1. **F23 — what counts as done for the leftover `codeo-live/*` branches?** `scripts/live.sh` pushes a web session's signal to `refs/heads/codeo-live/<issue>/web-<id>` and nothing deletes it; in a project with `on: push` for all branches each beat also triggers CI, and the docs do not say so. Options: (a) something removes a branch when the workflow closes or the signal goes stale (`/codeo:close`, `live.sh` or triage); (b) docs only: warn about the CI trigger and say how to delete; (c) both. Recommended: (c), with the removal mechanism left to `/codeo:plan`.
2. **F25 — fix or accept the duplicate row?** A web session whose harness session id changes publishes under a new label (`web-01Sa1Zqc` then `web-01Sa1Zqb`); the old row shows for up to 15 minutes. Options: (a) require a stable label, so the duplicate cannot appear; (b) accept it and document it. Recommended: (a) as a requirement, with how left to `/codeo:plan`.
3. **Out of scope.** Proposed: F24 (`timeout 8` around `lock.sh take web`, the plan's own Q11 a choice) and any change to which ref namespace a web session writes (that is #138's settled design). Right?

## Draft (title, body, type, labels)

**Title:** Live-session signal leftovers from #138: a fetch that aborts on equal labels, web branches nothing deletes, and a label that changes with the session id

**Issue Type:** none (`issue-types` printed nothing). **Labels:** `bug`.

```markdown
### Description

#138 made a hosted web session publish its live-session signal as a branch, `refs/heads/codeo-live/<issue>/<machine>`, because it cannot write `refs/codeo/live/*`. Three problems were left, recorded in #138's `qc.md` round 4 as non-blocking later work (F22, F23, F25).

- **F22.** `live.sh fetch` maps `refs/codeo/live/*` and `refs/heads/codeo-live/*` onto one destination (`scripts/live.sh:208`). When both exist for one `<issue>/<machine>`, git aborts with `fatal: Cannot fetch both refs/codeo/live/<n>/<m> and refs/heads/codeo-live/<n>/<m>` (rc 128), reproduced by the reviewer. `inflight.sh` then prints `live: unknown (could not fetch the signals)` for every reader, for as long as the web branch exists.
- **F23.** Every web session leaves a `codeo-live/<issue>/web-<id>` branch that nothing deletes (a hosted run left two for one session). In a project with `on: push` for all branches, each beat also runs CI. The docs do not warn about that.
- **F25.** One web session published under two labels (`web-01Sa1Zqc`, then `web-01Sa1Zqb`) because the harness session id changed. The older row drops from `--live` only after the TTL, so the engineer sees a duplicate for up to 15 minutes.

### Motivation / Context

F22 turns the signal off for everyone, not only the web session: a stale branch makes every reader's `--live` result `unknown`. F23 is what keeps that branch around, and F25 creates a second one.

### Key Requirements

- A web signal and a container or local signal with the same `<issue>/<machine>` do not make `live.sh fetch` fail; both are read, or one is chosen by a stated rule.
- A `codeo-live/*` branch does not outlive the workflow it belongs to, or the docs say how and when to delete it and name the CI trigger.
- A web session shows as one row when the harness session id changes, or the docs state the duplicate and its 15-minute bound.

### Acceptance Criteria
- [ ] With `refs/codeo/live/<n>/<m>` and `refs/heads/codeo-live/<n>/<m>` both on origin, `live.sh fetch` exits 0 and `inflight.sh --live` does not print `live: unknown` for that cause (a test reproduces the collision).
- [ ] After a workflow is closed, no `codeo-live/<issue>/*` branch for it remains on origin, or the docs say how to remove one.
- [ ] The docs for the web signal name the CI trigger on every beat in a project with `on: push` for all branches.
- [ ] A session whose id changes between two beats shows as one live row, or the docs state that it can show twice for up to the TTL.

### Out of Scope

- F24: `timeout 8` around `lock.sh take web` (#138's plan, Q11 a).
- Changing which ref namespace a web session writes.

### Reference

- `.codeo/done/138/qc.md` round 4 (F22, F23, F24, F25), `.codeo/done/138/implement.md` `## Outcome`.
- `scripts/live.sh:208` (fetch refspecs), `hooks/live-signal.sh`.
- Surfaced in `/codeo:triage` run 17 (`qc:138:F22-F23-F25`).
```
