# Issue #122 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/122 |
| Branch | `feat/triage-s-flight-judging-103` |
| Updated | 2026-11-19 |

## Where this stands

Explored `scripts/inflight.sh`, `scripts/claim.sh`, `skills/triage/SKILL.md`, `skills/init/SKILL.md`, `docs/handoff.md`, `docs/skills.md` and the two test files (`tests/inflight.test.sh`, `tests/triage-skill.test.sh`). Three choices change what gets built and are raised as Q1-Q3. Everything else is settled and listed under `## Notes` as the calls the draft will make. Blocked on Q1-Q3; no draft yet.

## Questions

### Q1 — How long does a dismissal of an unassigned workflow's question last (F14)?

**Why it matters:** it decides whether the plan changes triage's fingerprints (a new fingerprint kind in `skills/triage/SKILL.md`, its wording checks, and `docs/skills.md`) or only adds a sentence stating the limit. #103's Q4 left it open and the issue accepts either.
**Proposal:** split the two reasons a workflow is asked about. A workflow raised because nobody is assigned gets the fingerprint `unassigned:<N>`, which has no date, so a dismissal holds across pushes for as long as that row is in the ledger. A workflow raised because it is quiet past `triage.parkedDays` keeps `parked:<N>:<touched date>`, as today. One that is both carries both fingerprints in its single question, by the existing one-workflow-one-question rule. So a dismissed, unassigned, active workflow is not asked about again after a push, and it still comes back if it later goes quiet past the threshold.
**Options:**
- `unassigned:<N>`, as proposed (recommended). A dismissal is permanent for the unassigned reason; age still raises it.
- Keep `parked:<N>:<touched date>` and state the limit in `skills/triage/SKILL.md` and `docs/skills.md`: a dismissal of an unassigned workflow holds only until its next push. No behaviour change.
- Stop asking about an unassigned workflow that is within the threshold; list it in the run's `## Outcome` with a note that nobody is assigned. This reverses part of #103's Q4.

**Answer:**

### Q2 — What board Status does triage expect while an abandon is live (F18)?

**Why it matters:** it decides the table row at `skills/triage/SKILL.md:134` and whether triage has to consult its ledger to judge a board mismatch. Today the row expects Backlog only, so after the engineer answers *resume* (which sets Ready) the next run proposes `board.sh set <N> backlog`.
**Options:**
- Accept either Backlog or Ready for a live abandon (recommended). One changed table row and one sentence saying why: Ready is where *resume* puts the card before `/codeo:init` takes the work up again. The cost: an abandoned card someone moved to Ready by hand is not flagged either, which is the same state.
- Accept Ready only when the ledger holds a *resume* decision for that issue, otherwise Backlog. More exact, but the rule then depends on the model reading the ledger correctly while judging the board, and a hand-moved card is flagged.

**Answer:**

### Q3 — For a resumed stash, does `step:` change as well as `waits:` (F19)?

**Why it matters:** it decides whether the fix touches only the fallback in `waits_of` or also `last_step`, which feeds the `step:` line and the fourth column of `--tsv` that status reporters read.
**Proposal:** only `waits:` changes. When the last finished step is `close`, nothing earlier in `waits_of` applied, and the dossier is at `.codeo/<N>/`, the fallback uses the last finished step before `close` (`init` gives `/codeo:plan`, `plan` gives `/codeo:implement`, `implement` gives `/codeo:qc`). The same applies to a resumed abandon. `step:` goes on printing `close (working)` and `--tsv` goes on printing `close`, because both mean "the last step whose dossier has an outcome", which is still true.
**Options:**
- `waits:` only, as proposed (recommended).
- Also make `step:` and the `--tsv` column look past a spent stash or abandon, so they print `init`. This changes what `--tsv` consumers see and the header's definition of the last step.

**Answer:**

## Notes

Calls the draft will make unless an answer above changes them. They are shown again in the draft for review.

- **Shape.** One implementation plan at `docs/plans/2026-11-19-triage-in-flight-judging-follow-ups-122.md`, one pull request, no reference doc. Tests come first in each task; the suite is `shell` (`bash tests/run.sh`), which has no single-test filter, so each task's proof is `bash tests/run.sh <pattern>` for the file it changes and the last task runs the whole suite.
- **F13, *resume* wording.** *Resume* for a workflow with no live stash or abandon names what its `waits:` line shows, whatever raised it (age or no assignee): a step (`/codeo:plan`, `/codeo:implement`, `/codeo:qc`, `/codeo:close`) is named to run in that issue's checkout; `engineer — …` names the dossier files and question numbers to answer; `review — dossier archived` names the pull request to review; `nothing known` names the checkout and quotes the `step:` line, and says no step can be named. No card move in any of these.
- **F19 test.** A new case in `tests/inflight.test.sh`: `init.md` with an outcome and a `resumed: … after the stash of` log line, `close.md` with `### Round 1 — stashed`, `plan.md` pending; expects `waits:     /codeo:plan`.
- **F20, F21.** `docs/handoff.md` (*Who else is in flight*) lists the `waits:` values in the script's order and ends with `nothing known`. `docs/skills.md` (triage, *Reads and writes*) says a mismatch is named with its `board.sh set` command, or with `/codeo:close` in that issue's checkout when there is no pull request or it was closed unmerged.
- **F22.** Fixed in code: `touched_of` no longer returns when the tip's date does not parse; it starts with no best date and reads the dossier dates, which is what the header says. It cannot be reached through git today, so it is proved by the existing `touched:` cases still passing.
- **F23.** Noted in a comment: the comment above `close_send_back` says rounds are read only inside `## Outcome` and that the heading match is a prefix match, as in `last_qc_round`. No behaviour change.
- **Other workflows in flight.** #102 (`feat/codeo-issue-assign-every-filed`) and #108 (`feat/follow-ups-97-left-overlap`), both assigned to kbajpai and at `init` with no footprint and no changed files yet, so there is nothing to compare so far. The footprint check runs again once this plan's footprint is written.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-19 — Q1-Q3 raised · cost: 3m · fable-5-2 83k in + 518k cached / 4k out
