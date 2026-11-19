### Description

A hosted web session cannot publish the live-session signal by either write path, so #104's acceptance criterion "it works in a web session" is not met. The signal design (`refs/codeo/live/<issue>/<machine>`, written by `git push` with a REST fallback through `github.sh ref put|delete`) needs a way to publish from a web session, or an explicit decision that web sessions do not publish one.

### Motivation / Context

#112 ran the check in a real hosted web session bound to `feat/verify-live-session-signal-hosted`. `bash -x scripts/live.sh beat --force` exited 0 with `live: could not publish — github: ref put refs/codeo/live/112/vm: could not create the commit`. The trace:
- The signal commit was built locally; `git push` of it to `refs/codeo/live/112/vm` returned HTTP 403 (`RPC failed; HTTP 403, remote end hung up`), which the session read as the agent proxy letting pushes through to the development branch only.
- The REST fallback was refused: "Write access to this GitHub API path is not permitted through this proxy (HTTP 403)".
- `git ls-remote origin refs/heads/feat/verify-live-session-signal-hosted` printed `4b55d8e97c313952674ce3a554172ce54511839c` before and after, so nothing else changed.
- After `live.sh fetch`, `inflight.sh --live` listed only the container session for 112; no `112/vm` ref existed.

A web session is therefore invisible to `inflight.sh`, so another machine cannot tell a workflow running there is being worked now.

### Key Requirements

- A workflow running in a hosted web session is either visible through a live signal, or the documentation states plainly that web sessions publish none and what a reader should expect instead.
- Whatever is chosen needs no write the agent proxy refuses: no push outside the development branch and no REST path the proxy blocks.
- The signal stays information only; nothing blocks or waits on it.
- The choice is recorded with the alternatives considered, since the design must change (`/codeo:plan`'s work, not this issue's).

### Acceptance Criteria
- [ ] In a hosted web session, a workflow bound to an issue shows as live in `bash scripts/inflight.sh --live` on another clone, or the documentation states that web sessions publish no signal.
- [ ] The publish path used in a web session performs no write that returned HTTP 403 in #112's run (a push to `refs/codeo/live/*`, or `git/commits` and `git/refs` through REST).
- [ ] A web session's publish does not change the feature branch's tip on origin.
- [ ] `docs/handoff.md` (*Who is working right now*) matches what a web session does after the change.
- [ ] The tests cover the chosen web-session behaviour.

### Out of Scope

- The `codeo` plugin missing from the web session, so no hook runs there (filed separately).
- The user and machine labels a web session's signal would carry (filed separately).
- Blocking or locking anything on liveness.

### Reference

- #112 round 1: `.codeo/112/implement.md` → Notes → Round 1 and Later work, on `feat/verify-live-session-signal-hosted`; finding F1.
- #104, whose criterion "it works in a web session" this leaves unmet.
- `scripts/live.sh`, `scripts/github.sh` (`ref put|delete`), `docs/handoff.md` → *Who is working right now*.

### Open questions

- Which route works from a web session, if any: a ref under `refs/heads/`, an existing development-branch write, or no signal there. Nobody can answer this until the proxy's rules are known.
