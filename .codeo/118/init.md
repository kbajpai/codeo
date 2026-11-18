# Issue #118 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/118 |
| Branch | `feat/live-signal-leftovers-104-refresh` |
| Updated | 2026-11-18 |

## Where this stands

Initialized: branch `feat/live-signal-leftovers-104-refresh` cut off `origin/main` at `0dc7fa5d428bcc9521e7701d0497568924ce0c99` and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/118 — Live-signal leftovers from #104: refresh label, header line, same-machine ref-lock collision, and failure surfacing |
| State | open · labels `enhancement` |
| Branch | `feat/live-signal-leftovers-104-refresh` off `main` at `0dc7fa5d428bcc9521e7701d0497568924ce0c99` |
| Board | Ready → In progress |

**Problem.** #104's live-session signal left four polish items: the "refresh 0" test sets `CODEO_LIVE_REFRESH_SECONDS=-100`, so its label is wrong; `hooks/live-signal.sh` has an over-long header line; two concurrent beats from one machine can collide on the origin's ref lock, silently failing a beat; and whether session failures should be surfaced was never decided (F2). Triage added two #116 QC findings: `live.sh`'s timeout comment names only `ref put` though `clear`'s `ref delete` is bounded too (F8), and the 20-second `SessionEnd` timeout assumes the default `CODEO_LIVE_PUSH_TIMEOUT` (F9).

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] The test label and its case match.
- [ ] `hooks/live-signal.sh`'s header lines fit the file's line-length convention.
- [ ] A test or the docs cover two concurrent beats from one machine.
- [ ] The F2 decision (surface failures or leave them) is recorded in the plan.
- [ ] The `live.sh` comment names both calls the timeout bounds (`ref put` and `ref delete`).
- [ ] The docs say the 20-second `SessionEnd` figure assumes the default `CODEO_LIVE_PUSH_TIMEOUT`, or the hook timeout is derived from it.

**Out of scope.** Everything #116 already lists. The hosted-web-session check, which is #112.

**Open at intake.** Whether failures should be surfaced in the session (F2) is decided in `/codeo:plan`; the issue assumes no answer. The ref-lock collision is either handled or its limit documented, also `/codeo:plan`'s call.

## Log

- 2026-11-18 — init dossier drafted for review
- 2026-11-18 — initialized: branch feat/live-signal-leftovers-104-refresh off main at 0dc7fa5 · cost: 1m · sonnet-5-5 18k in + 437k cached / 2k out
