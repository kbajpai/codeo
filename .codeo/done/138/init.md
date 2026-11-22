# Issue #138 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/138 |
| Branch | `fix/live-session-signal-does-not` |
| Updated | 2026-11-21 |

## Where this stands

Initialized: branch `fix/live-session-signal-does-not` cut off `origin/main` at `56598d3c7a5c83e357a5f8218f85050cc06568c8` and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/138 — The live-session signal does not work in a hosted web session: both writes are refused, the hook's plugin is not installed and the labels are unconfirmed |
| State | open · labels `bug` |
| Branch | `fix/live-session-signal-does-not` off `main` at `56598d3` |
| Board | Ready → In progress |

**Problem.** #112's real web-session run showed the live-session signal does not work in a hosted web session, so #104's criterion "it works in a web session" is unmet. Three defects: both write paths (a push to `refs/codeo/live/*` and REST `POST git/commits`) returned HTTP 403; the `codeo` plugin is not installed there, so the publishing hook cannot fire; and the labels (user, machine) are unconfirmed and probably wrong (`vm`, `Claude`). A web session is therefore invisible to `inflight.sh`.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] In a hosted web session, a workflow bound to an issue shows as live in `bash scripts/inflight.sh --live` on another clone, or the documentation states that web sessions publish no signal.
- [ ] The publish path used in a web session performs no write that returned HTTP 403 in #112's run (a push to `refs/codeo/live/*`, or `POST git/commits` through REST).
- [ ] A web session's publish does not change the feature branch's tip on origin.
- [ ] When a web session publishes, it does so without a manual `beat`, and the plugin or trigger that does it is present in a web session.
- [ ] When a web session publishes, the signal names the engineer's GitHub login and a machine of the form `web-<8 characters>`, not the harness identity or the hostname.
- [ ] `docs/handoff.md` (*Who is working right now*) matches what a web session does after the change.
- [ ] The tests cover the chosen web-session behaviour, including the lock taken with and without a session id.

**Out of scope.** Blocking or locking anything on liveness; other findings of #104's QC and #118's leftovers.

**Open at intake.** Which route works from a web session, if any: a ref under `refs/heads/`, an existing development-branch write, or no signal there (nobody can answer until the proxy's rules are known). Whether a plugin can be made available in a hosted web session, or the trigger must live elsewhere. Whether a real web session's start script passes a session id to `lock.sh take web`. Whether `GET /user` is refused there, and so what user the signal would name. Note: #145 (plan step) edits `docs/handoff.md` and #149 (plan step) edits `CHANGELOG.md`; `/codeo:plan` runs `overlap.sh` before settling its footprint.

## Log
- 2026-11-21 — initialized: branch fix/live-session-signal-does-not off main at 56598d3 · cost: 0m · sonnet-5-5 17k in + 499k cached / 3k out
