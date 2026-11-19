# Issue #112 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/112 |
| Branch | `feat/verify-live-session-signal-hosted` |
| Updated | 2026-11-19 |

## Where this stands

Round 1: the web-session run (Tasks 1-5) is done and recorded under Notes; both writes were refused. Next: comment on #112 and write Task 7 (documentation). F1-F3 are not filed: `/codeo:issue` refuses in this container and they are listed under Notes for the home checkout. Earlier state: `origin/main` merged (`2cbbf5d`); baseline read before the run: `bash scripts/inflight.sh --live` lists #108 and #112 on `container` hosts only; the tip of `origin/feat/verify-live-session-signal-hosted` is `2cbbf5d8ae925d68185250280afb3f34031ec43a`.

## Questions

None.

## Notes

### Round 1 — the web-session run (Tasks 1-5), recorded 2026-11-19

Source: the engineer's screenshots of the hosted session on `feat/verify-live-session-signal-hosted` (its own words, transcribed; the wording is approximate where the image was small). The session was Sonnet 5.5; the checkout was already at the branch tip, `git pull` said "Already up to date".

**Task 1 — publish.** `bash scripts/lock.sh take web` ran without a session id, so `.codeo/active` there reads `issue: 112`, `branch: feat/verify-live-session-signal-hosted`, `host: web`, `session: unknown`. `git config user.name` printed `Claude`. `bash -x scripts/live.sh beat --force` exited 0 with `live: could not publish — github: ref put refs/codeo/live/112/vm: could not create the commit`. The trace: the signal commit was built locally; `git push` of it to `refs/codeo/live/112/vm` returned HTTP 403 (`RPC failed; HTTP 403, remote end hung up`), which the session read as the agent proxy letting pushes through to the development branch only; the fallback `github.sh ref put` was refused with "Write access to this GitHub API path is not permitted through this proxy (HTTP 403)". `git ls-remote origin refs/heads/feat/verify-live-session-signal-hosted` printed `4b55d8e97c313952674ce3a554172ce54511839c` before and after. After `live.sh fetch`, `live.sh list --tsv` and `inflight.sh --live` listed only `112 kbajpai codeo-112 container`, and `git for-each-ref refs/codeo/live` listed refs for 102, 108, 112 (`codeo-112`) and 132 and none for `112/vm`.

**Tasks 2-4 — not reachable.** Nothing was published, so there was no web line to read from this container, nothing for the override beat (`CODEO_GITHUB_LOGIN`) to change, and nothing to clear. The REST write was exercised once, as `beat`'s own fallback, and refused; the explicit `github.sh ref put`/`ref delete` pair of Task 3 was not run, since the fallback already showed the proxy's answer for `git/commits`.

**Task 5 — the hook.** `claude plugin list` in the web session shows nine plugins (`pdf-viewer`, `design`, `sanity`, `fastly-agent-toolkit`, `qt-development-skills`, `cockroachdb`, `productivity`, `engineering`, `cowork-plugin-management`) and not `codeo`. The hook cannot fire there. Even installed, its `beat` would meet the same two refusals.

**Acceptance criteria of #112**

| # | Criterion | Result |
|---|---|---|
| 1 | `beat --force` publishes, and which path | **not met** — neither the push nor the REST fallback carried it; both refused with HTTP 403 (texts above) |
| 2 | another clone lists the session and the `live:` line | **not reachable** — nothing was published |
| 3 | the user the signal names | **recorded** — no signal was published; the label it would have had is `Claude` (`git config user.name`); and the machine label was `vm`, not `web-<8>`, because the lock's `session:` was `unknown`; follow-up F3 below |
| 4 | the branch tip unchanged, and clear removes it | **met for the tip** (`4b55d8e…` before and after); clear has nothing to remove |
| 5 | the hook publishes by itself | **does not** — `codeo` is not installed in the web session; follow-up F2 below |
| 6 | both writes refused: record the text, state #104's criterion | **#104's criterion "it works in a web session" is not met**; follow-up F1 below |

**Findings to file** (nothing is fixed here): F1 — a hosted session cannot publish the signal by either path (design change); F2 — `codeo` is not installed in the web session, so no hook runs there; F3 — in a web session the signal would name `Claude` and the machine `vm` (lock taken without a session id).

### Later work — to file with `/codeo:issue` in the home checkout

`/codeo:issue` refused here (`/codeo:issue runs in the home container, but this container's role is issue:112`), so nothing is filed and no number exists. File these three from the home container; each draft's substance is the finding above.

- To file: a hosted web session cannot publish the live-session signal by either path (`git push` to `refs/codeo/live/…` gets HTTP 403 from the agent proxy, `github.sh ref put` is refused with "Write access to this GitHub API path is not permitted through this proxy (HTTP 403)"); #104's criterion "it works in a web session" is not met, so the design must change (F1).
- To file: the `codeo` plugin is not installed in the hosted web session although `.claude/settings.json` enables `codeo@codeo`, so the live-signal hook cannot fire there (F2).
- To file: in a web session the signal would name `Claude` (`git config user.name`) rather than the engineer's login and the machine `vm` rather than `web-<8 characters>`, because `lock.sh take web` ran without a session id and the lock says `session: unknown` (F3).

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-19 — round 1 started: synced origin/main (2cbbf5d), paused at Task 1 for the web session · cost: counted in the round's final line
