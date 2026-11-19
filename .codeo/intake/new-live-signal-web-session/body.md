### Description

The live-session signal does not work in a hosted web session, so #104's acceptance criterion "it works in a web session" is not met. #112's real web-session run found three defects, filed together because they are one feature seen from one environment and the first decides the design of the others:

1. Neither write path publishes the signal: the agent proxy refuses both.
2. The `codeo` plugin is not installed there, so the hook that publishes the signal cannot fire.
3. Even if it published, the signal would name the wrong user and machine.

### Motivation / Context

#112 ran the check in a hosted web session bound to `feat/verify-live-session-signal-hosted` (the session's own output, transcribed from screenshots).

**1. Both writes refused.** `bash -x scripts/live.sh beat --force` exited 0 with `live: could not publish — github: ref put refs/codeo/live/112/vm: could not create the commit`. The signal commit was built locally; `git push` to `refs/codeo/live/112/vm` returned HTTP 403 (`RPC failed; HTTP 403, remote end hung up`), which the session read as the agent proxy letting pushes through to the development branch only; the fallback `github.sh ref put` was refused with "Write access to this GitHub API path is not permitted through this proxy (HTTP 403)". The branch tip on origin was unchanged (`4b55d8e97c313952674ce3a554172ce54511839c` before and after). After `live.sh fetch`, `inflight.sh --live` listed only the container session for 112, and no `112/vm` ref existed.

**2. No hook.** `.claude/settings.json` enables `codeo@codeo`, but `claude plugin list` in the web session shows nine plugins (`pdf-viewer`, `design`, `sanity`, `fastly-agent-toolkit`, `qt-development-skills`, `cockroachdb`, `productivity`, `engineering`, `cowork-plugin-management`) and not `codeo`. Even installed, its `beat` would meet the two refusals above.

**3. Wrong labels.** `bash scripts/lock.sh take web` ran without a session id, so `.codeo/active` there reads `host: web`, `session: unknown`. `git config user.name` printed `Claude`. The signal would therefore name the user `Claude`, not the engineer's login (`GET /user` is refused on a web session, so the fallback is `$CODEO_GITHUB_LOGIN`, then `git config user.name`), and the machine `vm`, not `web-<8 characters>`.

A web session is therefore invisible to `inflight.sh`, so another machine cannot tell a workflow running there is being worked now.

### Key Requirements

- A workflow running in a hosted web session is either visible through a live signal, or the documentation states plainly that web sessions publish none and what a reader should expect instead.
- Whatever is chosen needs no write the agent proxy refuses: no push outside the development branch and no REST path the proxy blocks.
- If a signal is published from a web session, something publishes it without a manual `beat` (the plugin's hook, or another trigger that works there), and it names the engineer's GitHub login and a `web-<8 characters>` machine.
- The signal stays information only; nothing blocks or waits on it.
- The choice is recorded with the alternatives considered, since the design must change (`/codeo:plan`'s work, not this issue's).

### Acceptance Criteria
- [ ] In a hosted web session, a workflow bound to an issue shows as live in `bash scripts/inflight.sh --live` on another clone, or the documentation states that web sessions publish no signal.
- [ ] The publish path used in a web session performs no write that returned HTTP 403 in #112's run (a push to `refs/codeo/live/*`, or `git/commits` and `git/refs` through REST).
- [ ] A web session's publish does not change the feature branch's tip on origin.
- [ ] When a web session publishes, it does so without a manual `beat`, and the plugin or trigger that does it is present in a web session.
- [ ] When a web session publishes, the signal names the engineer's GitHub login and a machine of the form `web-<8 characters>`, not `Claude` and `vm`.
- [ ] `docs/handoff.md` (*Who is working right now*) matches what a web session does after the change.
- [ ] The tests cover the chosen web-session behaviour, including the lock taken with and without a session id.

### Out of Scope

- Blocking or locking anything on liveness.
- Other findings of #104's QC and #118's leftovers.

### Reference

- #112 round 1: `.codeo/112/implement.md` → Notes → Round 1 and Later work, on `feat/verify-live-session-signal-hosted`; findings F1, F2 and F3.
- #104, whose criterion "it works in a web session" this leaves unmet.
- `scripts/live.sh`, `scripts/lock.sh` (`take web`), `scripts/github.sh` (`ref put|delete`, `user login`), `hooks/live-signal.sh`, `docs/handoff.md` → *Who is working right now*.

### Open questions

- Which route works from a web session, if any: a ref under `refs/heads/`, an existing development-branch write, or no signal there. Nobody can answer this until the proxy's rules are known.
- Whether a plugin can be made available in a hosted web session, or the trigger must live elsewhere.
