# Issue — issue

| | |
|---|---|
| Issue | not filed yet |
| Updated | 2026-11-16 |

## Where this stands

Drafted from `/codeo:qc`'s round 1 on #104 (finding F3) at the engineer's request: the by-hand web-session check was skipped there and this issue carries it. No question is open: the engineer supplied the finding and its scope, and the unknowns below are content of the issue, not blockers. Draft ready for the engineer's approval.

## Questions

None.

## Draft

**Title:** Verify the live-session signal in a hosted web session

**Issue Type:** none (the repository is user-owned, so `issue-types` prints nothing). **Labels:** `enhancement` (the closest existing label: this completes #104's fourth criterion and may lead to a change).

### Description
#104 publishes a short-lived live-session signal as a git ref, `refs/codeo/live/<issue>/<machine>` (by `git push`, falling back to REST through `github.sh ref put|delete`), and `inflight.sh` shows it. Its fourth acceptance criterion, "it works in a web session", was never verified: every test uses a local origin and a stubbed `github.sh`, and none reaches a hosted web session or GitHub itself. Run the check in a real hosted web session and record what happens.

### Motivation / Context
The signal exists so another machine can tell a workflow is being worked right now, and a hosted web session is one of the places workflows run. A web session reaches GitHub only through git and REST over a proxy, and the proxy's rules are not visible from a dev container, so four things are unknown:
1. Whether the session's git proxy accepts a push to `refs/codeo/live/*`, a ref outside `refs/heads/`.
2. Whether the REST fallback (`POST git/commits` with the fixed `codeo-live <codeo-live@invalid>` identity, then `PATCH` or `POST git/refs`) is allowed by the session's credential, which matters if the push is refused.
3. Which user the signal names there. `GET /user` is refused on a web session, so the user is `$CODEO_GITHUB_LOGIN` when set and otherwise `git config user.name`, which a hosted session sets to the harness's identity and probably not the engineer's.
4. Whether the hook fires there once a release that carries it is pinned (the hook runs from the installed plugin, which lacks it until then).

### Key Requirements
- The check runs in a real hosted web session bound to an issue's branch, and its outcome is recorded in this issue (or the pull request that closes it) with the commands and their output.
- It covers both directions: the session publishes the signal, and another clone sees it through `inflight.sh --live` and the `live:` line, then the session clears it and the other clone stops seeing it.
- It states which write path carried the publish (push or REST) and which user the signal named.
- A finding that the web path does not work, or names the wrong user, is recorded as such and filed as its own issue (or sent to `/codeo:plan` if the design must change); this issue does not widen into the fix.

### Acceptance Criteria
- [ ] A recorded run in a real hosted web session shows `bash scripts/live.sh beat --force` publishing the signal, and says whether the push or the REST fallback carried it.
- [ ] From another clone, `bash scripts/inflight.sh --live` lists the session (issue, user, `web-<8 characters>`, `web`, an age under a minute), and `bash scripts/inflight.sh` prints the `live:` line in that issue's block.
- [ ] The user the signal names is the engineer's GitHub login, or the issue records what it named instead and files the follow-up.
- [ ] The feature branch's tip on origin is unchanged by the publish, and after `bash scripts/live.sh clear` the other clone no longer lists the session.
- [ ] Once a release carrying the hook is pinned in a web session, the hook publishes the signal without a manual `beat` (a prompt or a tool call is enough), or the issue records that it does not and files the follow-up.
- [ ] If both writes are refused, the issue records the refusal text and the criterion "it works in a web session" of #104 is stated as not met, with a follow-up filed for the design change.

### Out of Scope
- Fixing anything the check finds: a refused write, a wrong user label or a hook that does not fire is filed separately.
- The other findings of `/codeo:qc`'s round 1 on #104: the zero-padded `beat` that aborts `list` (F1), the documentation claim about a failure message (F2), a writer's clock running ahead (F5) and the `SessionEnd` timeout (F7).
- Blocking or locking anything on liveness; the signal is information only.

### Reference
- #104, whose fourth criterion this completes; `.codeo/104/qc.md` round 1, finding F3.
- `docs/plans/2026-11-15-live-session-signal.md`, Task 7 (the by-hand check and its steps).
- `scripts/live.sh`, `scripts/github.sh` (`ref put|delete`, `user login`), `scripts/inflight.sh`, `hooks/live-signal.sh`.
- Steps that were drafted for the check: check out a branch carrying #104 and run `bash scripts/lock.sh take web`; `bash -x scripts/live.sh beat --force` to see push versus REST; `git ls-remote origin 'refs/codeo/live/*'`; from another clone `bash scripts/inflight.sh --live`; confirm `git ls-remote origin refs/heads/<branch>` is unchanged; `bash scripts/live.sh clear`; optionally `CODEO_LIVE_TTL_SECONDS=60` on the reader and a 61-second wait.

## Log

- 2026-11-16 — drafted from #104's qc round 1 (F3); no questions; draft awaiting approval
