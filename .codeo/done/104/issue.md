# Issue #104 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/104 |
| Updated | 2026-11-15 |

## Where this stands

Questions answered in the conversation; the draft below was approved and filed.

## Questions

### Q1 — What must triage be able to tell about an in-flight workflow?
**Answer:**
When it was last touched, what it waits on, a board-vs-dossier mismatch, and a live session right now (engineer, in the conversation, 2026-11-15).

### Q2 — When is a workflow parked?
**Answer:**
A config setting, default 7 days (engineer, 2026-11-15).

### Q3 — May `inflight.sh`'s existing output change?
**Answer:**
Additive only (engineer, 2026-11-15).

### Q4 — Liveness in this issue or its own?
**Answer:**
Separate issue (engineer, 2026-11-15).

### Q5 — Liveness constraints?
**Answer:**
No commits on the feature branch; expires on its own; works in web sessions; names machine and user (engineer, 2026-11-15).

## Draft

### Description
Each codeo session working on an issue should publish a short-lived signal that it is active. The signal names the issue, the user and the machine. `inflight.sh`, and through it triage, should report which workflows have a live session.

### Motivation / Context
The workflow lock `.codeo/active` is local to one checkout and never pushed. No pushed fact distinguishes a workflow being worked right now from one whose checkout was closed days ago. Triage and the overlap checks can only infer activity from dates. That evidence is what issue A adds, and it still cannot say "someone is in it now".

### Key Requirements
- Adds no commits or files to the issue's branch or its PR. The intake branch or another ref is acceptable.
- Expires on its own: a session that crashed or closed stops reading as live after a set time, with no cleanup step.
- Works in a hosted web session: git push and REST only, no GraphQL.
- Names the user and the machine (host or container).
- How the signal is stored, refreshed and read is for `/codeo:plan` to decide.

### Acceptance Criteria
- [ ] While a codeo skill is working an issue, `inflight.sh` run from another clone shows that workflow as live, with the user and the machine.
- [ ] After the session ends or crashes, the workflow stops showing as live within the documented expiry, with no manual step.
- [ ] Neither the feature branch nor its PR gains a commit from the signal.
- [ ] It works in a web session.
- [ ] `bash tests/run.sh` passes. `CHANGELOG.md` records the change.

### Out of Scope
- Dates, what a workflow waits on, and board mismatch. That is issue A.
- Blocking or locking anything on the basis of liveness. It is information only.

### Reference
- Issue A (number filled in at filing)
- `.codeo/active` handling in `skills/init/SKILL.md`
- `scripts/intake.sh` (leases, which are a pushed, shared-state precedent)

## Log

- 2026-11-15 — Q1-Q5 answered; draft written
- 2026-11-15 — filed as #104
