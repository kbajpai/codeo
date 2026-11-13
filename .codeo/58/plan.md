# Issue #58 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/58 |
| Branch | `feat/run-record-host-checks-55` |
| Updated | 2026-11-12 |

## Where this stands

Q1 and Q2 answered (both A). Draft plan written to `.codeo/58/plan-draft.md` (not committed), awaiting review.

What exploration found, which shapes the questions:
- **The checks were run, and only an attestation records them.** The runbook comment on #58 (`issuecomment-6808714302`) has all 19 steps ticked. A second comment (`issuecomment-6839269538`) records criteria 1, 2, 3, 4, 5, 7 and 8 as "held" on the engineer's word, and says the terminal output was not kept. The issue's requirement is "for each criterion, the command run and what it printed".
- **Some of criterion 1 is still provable from GitHub.** #59, the throwaway issue, is closed as not planned, assigned to `kbajpai`, and its card is Done. Its branch `chore/throwaway-target-issue-58-s` was on origin on 2026-11-12 (holding only the #59 init dossier, commit `b4e75e5`) and has since been deleted. That shows `/codeo:init #59` pushed a branch and assigned the issue. Nothing else is provable from here: this container has no `docker`.
- **#59 is already cleaned up.** Closed as not planned, branch deleted, card Done. No task is needed for it.
- **No code, test or documentation page changes.** The issue asks for a record in the issue, which intake Q1 settled. The branch will carry the dossier and, depending on Q2, a short plan file.
- **No other workflow is in flight**, so there is no footprint overlap to raise.

Decisions taken without a question: one PR; no change under `scripts/`, `lib/`, `hooks/`, `skills/`, `tests/` or `.devcontainer/`; no documentation page moves; no criterion failed, so no follow-up issue is filed.

## Questions

### Q1 — The issue asks for each command and its output, and only your attestation exists. What does the plan treat as done?

**Why it matters:** `/codeo:qc` maps each of the eight acceptance criteria to `met`, `not met` or `untestable`. With attestation alone it has no output to check, so it will most likely mark criteria 1-5, 7 and 8 `untestable`, which is where #55 already stood. The answer decides whether the plan has one task (record what exists) or a re-run.

What can be done:
- **A. Attestation, stated as such.** The plan's one task confirms the attestation comment is on #58 and adds what GitHub still shows for criterion 1 (#59 assigned, closed as not planned, card Done). The criteria are recorded as "held, engineer-attested, output not kept". `/codeo:qc` judges that; if it will not call them met, you state an override at `/codeo:close`, which is recorded verbatim. Cheapest, and honest about the gap. #51 changes the same `devcontainer-start.sh`, and this leaves no output to compare a regression against.
- **B. Re-run the cheap criteria and capture output.** Criteria 4, 5 and 8 need only the home container and one issue container open together: the `lock:` line, `cat .codeo/active`, `docker ps --format '{{.Names}}'` and the two window titles. About ten minutes, and it needs a new throwaway issue for criteria 1-3. Criterion 7 stays attested.
- **C. Re-run everything** with the runbook and paste the output. Meets the issue as written.

I recommend A if #51 is not about to start, and B if it is: the lock and name output in B is exactly what #51 could break.

**Options:** A (attestation, recorded as such) · B (re-run 4, 5 and 8 with output) · C (re-run everything) · something else.

**Answer:**
A — attestation, recorded as such (engineer, 2026-11-13)

### Q2 — Does this get a plan file under `docs/plans/`, or does the dossier carry it?

**Why it matters:** `/codeo:implement` executes a committed plan file task by task, and every task needs a proof command. With answer A to Q1 the whole plan is one task whose proof is `gh api repos/kbajpai/codeo/issues/comments/6839269538 --jq .body` printing the criteria table. A plan file for that is mostly boilerplate, but without one `/codeo:implement` has nothing to execute and the pipeline's later steps have no plan to grade against.

**Options:**
- **A. A short plan file**, `docs/plans/2026-11-12-record-host-checks-55.md`: Goal, Global Constraints ("no code or page changes"), and one to three tasks depending on Q1. Keeps the pipeline unchanged. Recommended.
- **B. No plan file.** You close #58 by hand and the workflow is stashed or abandoned with `/codeo:close`. Faster, and it leaves the branch unmerged, so the dossier never reaches `main`.

**Answer:**
A — a short plan file (engineer, 2026-11-13, after the recommendation)

## Notes

`superpowers:brainstorming` ran before these questions. The `engineering` plugin is not installed; steps 6 and 7 do not apply to a recording-only issue.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-12 — Q1-Q2 raised · cost: 0m · fable-5-2 80k in + 218k cached / 2k out
