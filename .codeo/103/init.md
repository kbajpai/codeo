# Issue #103 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/103 |
| Branch | `feat/let-codeo-triage-judge-flight` |
| Updated | 2026-11-17 |

## Where this stands

Branch `feat/let-codeo-triage-judge-flight` cut off `main` at `6699326b8d5981bea91265e74b6c27daf332087a`, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/103 — Let `/codeo:triage` judge in-flight workflows from evidence: last-touched date, what each waits on, board mismatch |
| State | open · labels `enhancement` |
| Branch | `feat/let-codeo-triage-judge-flight` off `main` at `6699326` |
| Board | Ready → In progress |

**Problem.** `inflight.sh` prints only `step: <last step with an Outcome> (working | PR open)`: no date, and `working` means just "dossier not archived", so triage cannot tell a parked workflow from an active one and falls back to ad-hoc lookups. The facts exist in what is pushed (each dossier's `Updated` row and `## Log` dates, the branch tip, open `**Answer:**` blocks, qc's verdict line, the PR state, the board Status). The issue has `inflight.sh` report a last-touched date with its source and what each workflow waits on, and has `/codeo:triage` use them, the board Status and a configurable parked threshold (default 7 days) to decide which workflows to ask about, quoting the facts. Changes are additive only.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] `inflight.sh` prints a last-touched date for every workflow, and the date matches the newest pushed evidence for that workflow.
- [ ] A workflow with an unanswered dossier question is shown as waiting on the engineer, with the step file and question number.
- [ ] A workflow whose `qc.md` has a verdict shows that verdict.
- [ ] A workflow untouched for longer than the configured threshold is raised by triage as a question. One touched within the threshold is listed but not asked about.
- [ ] Triage flags a board Status that disagrees with the dossier and PR state, quoting both.
- [ ] The existing `--tsv` columns and the human block lines are unchanged. The tests for every current consumer still pass.
- [ ] The config setting is documented, along with its default.
- [ ] `bash tests/run.sh` passes. `CHANGELOG.md` records the change.

**Out of scope.** Whether a session is open right now (liveness; #104 covers it). Changing the meaning of `(working)` or the step label.

**Open at intake.** Nothing: the intake dossier's Q1-Q5 were answered (what triage must tell, a config threshold with default 7 days, additive output only, liveness in its own issue, liveness constraints). Requirements also say it must work in a hosted web session (REST and git only), and report an unavailable board rather than drop it (triage rule `triage-07`).

**Adopted.** `.codeo/103/issue.md`, from `codeo/intake`.

**Footprint note (for `/codeo:plan`).** Known files: `scripts/inflight.sh`, `skills/triage/SKILL.md`, the config docs, `docs/dossier.md` (reference only), `CHANGELOG.md`, tests. #99 (in flight) and #116 (in flight, qc) both list `CHANGELOG.md`; #116 also lists `docs/skills.md`, `docs/handoff.md` and `scripts/github.sh`. #112 (not started) shares `inflight.sh`. Raise through `overlap.sh` once the branch exists.

## Log

- 2026-11-17 — initialized: branch feat/let-codeo-triage-judge-flight off main at 6699326 · cost: 1m · sonnet-5-5 17k in + 541k cached / 3k out
