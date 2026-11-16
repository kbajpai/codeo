# Issue #104 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/104 |
| Branch | `feat/publish-live-session-signal-so` |
| Updated | 2026-11-15 |

## Where this stands

Branch `feat/publish-live-session-signal-so` cut off `main` at 896d6d6, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/104 — Publish a live-session signal so other machines can tell a workflow is being worked right now |
| State | open · labels `enhancement` |
| Branch | `feat/publish-live-session-signal-so` off `main` at 896d6d6 |
| Board | Ready → In progress |

**Problem.** The lock `.codeo/active` is local to one checkout and never pushed, so no pushed fact tells a workflow being worked right now from one whose checkout was closed days ago. A codeo session working an issue should publish a short-lived signal naming the issue, the user and the machine, without adding commits to the feature branch or its PR, expiring on its own, and working in a web session (git push and REST only). `inflight.sh`, and through it triage, report which workflows are live. How the signal is stored, refreshed and read is for `/codeo:plan` to decide.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] While a codeo skill is working an issue, `inflight.sh` run from another clone shows that workflow as live, with the user and the machine.
- [ ] After the session ends or crashes, the workflow stops showing as live within the documented expiry, with no manual step.
- [ ] Neither the feature branch nor its PR gains a commit from the signal.
- [ ] It works in a web session.
- [ ] `bash tests/run.sh` passes. `CHANGELOG.md` records the change.

**Out of scope.** Dates, what a workflow waits on, and board mismatch (#103). Blocking or locking anything on the basis of liveness; it is information only.

**Open at intake.** How the signal is stored, refreshed and read (the issue leaves it to `/codeo:plan`).

## Log

- 2026-11-15 — initialized: branch feat/publish-live-session-signal-so off main at 896d6d6 · cost: unavailable
