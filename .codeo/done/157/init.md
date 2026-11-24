# Issue #157 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/157 |
| Branch | `fix/live-session-signal-leftovers-138` |
| Updated | 2026-11-23 |

## Where this stands

Initialized: branch `fix/live-session-signal-leftovers-138` cut off `origin/main` at `5d6cba510d60a0ee3fc80de68fd08832f2762f44`, and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/157 — Live-session signal leftovers from #138: a fetch that aborts on equal labels, web branches nothing deletes, and a label that changes with the session id |
| State | open · labels `bug` |
| Branch | `fix/live-session-signal-leftovers-138` off `main` at `5d6cba5` |
| Board | Ready → In progress |

**Problem.** #138 made a hosted web session publish its live-session signal as a branch `refs/heads/codeo-live/<issue>/<machine>`. Three problems were left: `live.sh fetch` aborts (rc 128) when a web and a container or local signal share `<issue>/<machine>`, which turns `inflight.sh --live` to `live: unknown` for every reader (F22); every web session leaves a `codeo-live/<issue>/web-<id>` branch that nothing deletes, and each beat runs CI where `on: push` covers all branches (F23); and one web session published under two labels when the harness session id changed, so a duplicate row shows for up to the TTL (F25).

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] With `refs/codeo/live/<n>/<m>` and `refs/heads/codeo-live/<n>/<m>` both on origin, `live.sh fetch` exits 0 and `inflight.sh --live` does not print `live: unknown` for that cause (a test reproduces the collision).
- [ ] After a workflow is closed, no `codeo-live/<issue>/*` branch for it remains on origin, or the docs say how to remove one.
- [ ] The docs for the web signal name the CI trigger on every beat in a project with `on: push` for all branches.
- [ ] A session whose id changes between two beats shows as one live row, or the docs state that it can show twice for up to the TTL.

**Out of scope.** F24 (`timeout 8` around `lock.sh take web`, #138's plan Q11 a); changing which ref namespace a web session writes.

**Open at intake.** None; the issue left nothing unresolved.

## Log

- 2026-11-23 — initialized: branch fix/live-session-signal-leftovers-138 off main at 5d6cba5 · cost: 1m · sonnet-5-5 18k in + 765k cached / 3k out
