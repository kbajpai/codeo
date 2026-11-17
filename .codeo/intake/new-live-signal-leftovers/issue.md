# Issue — live-signal leftovers from #104

Raised by /codeo:triage run 2026-11-17-2, Q3. The engineer's answers: file it as a new issue that runs after #116 merges (not folded into #116 or #112).

## Draft

Title: Live-signal leftovers from #104: refresh label, header line, same-machine ref-lock collision, and failure surfacing
Issue Type: none (user-owned repository). Labels: enhancement.

### Description

Three small leftovers from #104's live-session signal were judged polish and never filed, and one design question was left open. None breaks a workflow: the signal is best-effort.

### Motivation / Context

From `.codeo/done/104/implement.md` (on `origin/main`), round 2:

- The test case labelled "refresh 0" sets `CODEO_LIVE_REFRESH_SECONDS=-100`, so it tests that a non-positive interval never throttles, not the literal `0`; the label is wrong.
- `hooks/live-signal.sh` has an over-long header line.
- Two concurrent beats from the same machine can collide on the origin's ref lock (a throttle race, untested, older than that round). A beat can then fail silently; the next beat refreshes the signal, so the cost is a stale `live:` signal for a short time.
- F2: the hook cannot make "the session says so once" true when nothing could be published; the claim was dropped from the docs. Surfacing failures in the session would be a design change.

#116 already holds other live-signal findings from #104 (`live.sh` edge cases, `github.sh ref delete`, clearing on `/codeo:close`, the duplicate volume name); none of these four.

### Key Requirements

- The "refresh 0" test's label says what it tests, or it tests the literal `0`.
- The over-long header line in `hooks/live-signal.sh` is shortened.
- The ref-lock collision between two same-machine beats is either handled or its limit stated in the docs.
- Whether failures should be surfaced in the session is decided in `/codeo:plan`; this issue does not assume the answer.

### Acceptance Criteria

- [ ] The test label and its case match.
- [ ] `hooks/live-signal.sh`'s header lines fit the file's line-length convention.
- [ ] A test or the docs cover two concurrent beats from one machine.
- [ ] The F2 decision (surface failures or leave them) is recorded in the plan.

### Out of Scope

- Everything #116 already lists.
- The hosted-web-session check, which is #112.

### Reference

- `.codeo/done/104/implement.md`, "Left as polish" and "The 'refresh 0' case" (on `origin/main`)
- `hooks/live-signal.sh`, `scripts/live.sh`, `tests/live.test.sh`
- `/codeo:triage` run 2026-11-17-2, Q3

Run after #116 merges: both change `scripts/live.sh` and its tests.

## Log

2026-11-17 — draft written, awaiting approval
