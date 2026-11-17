# Issue #103 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/103 |
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
`inflight.sh` should report, for each workflow, when it was last touched, what it is waiting on, and its board Status. `/codeo:triage` should then use those facts, together with a configurable parked threshold (default 7 days), to decide which in-flight workflows to ask about. It should quote the facts as evidence.

### Motivation / Context
Triage's only source for parked work is `inflight.sh`. That script prints `step: <last step with an Outcome> (working | PR open)`. `working` means only "dossier not archived yet", and the step is the last one that wrote an outcome, not one that is running. No date is printed, so the skill's "last step is weeks old" rule cannot be applied from evidence. A run either asks about nothing or falls back to ad-hoc lookups, such as branch commit dates. The facts already exist in what is pushed: each dossier's `Updated` row and `## Log` dates, the branch tip, open `**Answer:**` blocks, qc's verdict line, the PR state and the board Status. Nothing brings them together.

### Key Requirements
- For each workflow, `inflight.sh` reports a last-touched date taken from pushed data, and says which source the date came from.
- It reports what the workflow is waiting on, where the pushed state shows it: an unanswered dossier question (naming the step file and the question number), qc's last verdict, a PR open for review, or nothing known.
- Triage reads the board Status (`board.sh status`) and flags a workflow whose Status disagrees with what the dossier and PR show, for example `In progress` while a PR is open, or `In review` with no PR.
- The parked threshold is a project config setting with a documented default of 7 days. Triage cites the date and the threshold it applied.
- Additive only: the existing human block lines and the `--tsv` columns keep their meaning and order. Consumers in init, plan, implement, qc and close, and status reporters, are unaffected.
- Works in a hosted web session (REST and git only). When the board is unavailable, the report says so and doesn't drop it silently, per triage rule `triage-07`.

### Acceptance Criteria
- [ ] `inflight.sh` prints a last-touched date for every workflow, and the date matches the newest pushed evidence for that workflow.
- [ ] A workflow with an unanswered dossier question is shown as waiting on the engineer, with the step file and question number.
- [ ] A workflow whose `qc.md` has a verdict shows that verdict.
- [ ] A workflow untouched for longer than the configured threshold is raised by triage as a question. One touched within the threshold is listed but not asked about.
- [ ] Triage flags a board Status that disagrees with the dossier and PR state, quoting both.
- [ ] The existing `--tsv` columns and the human block lines are unchanged. The tests for every current consumer still pass.
- [ ] The config setting is documented, along with its default.
- [ ] `bash tests/run.sh` passes. `CHANGELOG.md` records the change.

### Out of Scope
- Whether a session is open right now (liveness). That is issue B.
- Changing the meaning of `(working)` or the step label.

### Reference
- `scripts/inflight.sh:46-57`, `:72-77`, `:96-104`
- `skills/triage/SKILL.md:95-96`
- `docs/dossier.md` (the `Updated` row, `## Where this stands`, `## Log`)
- Triage run 2026-11-15-6 on `codeo/intake`

## Log

- 2026-11-15 — Q1-Q5 answered; draft written
- 2026-11-15 — filed as #103
