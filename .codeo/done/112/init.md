# Issue #112 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/112 |
| Branch | `feat/verify-live-session-signal-hosted` |
| Updated | 2026-11-19 |

## Where this stands

Initialized: branch `feat/verify-live-session-signal-hosted` cut off `origin/main` at `4a4572e9624bad14b5753a3f455190a31789b290` and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/112 — Verify the live-session signal in a hosted web session |
| State | open · labels `enhancement` |
| Branch | `feat/verify-live-session-signal-hosted` off `main` at `4a4572e` |
| Board | Ready → In progress |

**Problem.** #104 publishes a live-session signal as the git ref `refs/codeo/live/<issue>/<machine>` (by `git push`, falling back to REST through `github.sh ref put|delete`) and `inflight.sh` shows it. Its criterion "it works in a web session" was never verified: every test uses a local origin and a stubbed `github.sh`. The check must run in a real hosted web session and record what happens: whether the proxy accepts the push, whether the REST fallback is allowed, which user the signal names, and whether the hook fires once a release carrying it is pinned.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] A recorded run in a real hosted web session shows `bash scripts/live.sh beat --force` publishing the signal, and says whether the push or the REST fallback carried it.
- [ ] From another clone, `bash scripts/inflight.sh --live` lists the session (issue, user, `web-<8 characters>`, `web`, an age under a minute), and `bash scripts/inflight.sh` prints the `live:` line in that issue's block.
- [ ] The user the signal names is the engineer's GitHub login, or the issue records what it named instead and files the follow-up.
- [ ] The feature branch's tip on origin is unchanged by the publish, and after `bash scripts/live.sh clear` the other clone no longer lists the session.
- [ ] Once a release carrying the hook is pinned in a web session, the hook publishes the signal without a manual `beat` (a prompt or a tool call is enough), or the issue records that it does not and files the follow-up.
- [ ] If both writes are refused, the issue records the refusal text and the criterion "it works in a web session" of #104 is stated as not met, with a follow-up filed for the design change.

**Out of scope.** Fixing anything the check finds (a refused write, a wrong user label or a hook that does not fire is filed separately); the other findings of `/codeo:qc`'s round 1 on #104 (F1, F2, F5, F7); blocking or locking anything on liveness.

**Open at intake.** None. Note for planning: the check needs a real hosted web session, which a dev container cannot provide.

## Log

- 2026-11-19 — initialized: branch feat/verify-live-session-signal-hosted off main at 4a4572e · cost: 1m · sonnet-5-5 15k in + 266k cached / 2k out
