# Skills inventory — the rules that must survive the move

Source: the seven RoadMaster skills (`issue`, `init`, `plan`, `implement`, `qc`, `close`, `triage`)
read in October 2026. This file holds only the generic part, so it can live in a public repo. The
per-line map of RoadMaster-specific passages (paths, tools, domain rules) is kept in RoadMaster's
private repository and is the working document for the rewrite.

"Hard rule" below means a rule a project overlay may not override; the skill states this once, at
the top. Each skill's rewrite is checked against its list: a rule that disappears is a regression.

## issue

- A bare invocation asks; it never infers what to file.
- For a bug, run systematic-debugging Phase 1 only; a suspected but unshown cause goes in as an open
  question.
- Two kinds of unknown: one the engineer can answer blocks the skill; one nobody can answer yet goes
  verbatim into the draft.
- The caller supplies the finding, not the answers.
- Acceptance criteria are checkable outcomes, not a contract.
- File through REST because `gh issue create` cannot set the Issue Type; take the number and URL from
  the response, never reconstruct them.
- Never set Priority or Effort.

## init

- Decide "is this a pull request" from `html_url` containing `/pull/`, not from an exit code.
- A closed issue: ask, never reopen it.
- The create-only push is the claim and runs before the assignee is added; earlier checks are advisory.
- A resume is pushed against the tip it saw, so of two resumes exactly one wins.
- The resume line's wording belongs to the script; write nothing else on it, and put an override in
  Notes, never on that line.
- `unavailable` is not a failure, but the Ready check is never skipped just because it could not run.
- Never merge, rebase or reset a container's unpushed commits.
- Acceptance criteria are copied verbatim.
- The state directory's `.gitignore` must be committed.

## plan

- Brainstorm before writing the questions.
- Commit and push before ending the turn, so the questions survive the machine.
- Out-of-scope work goes to `issue`; neither widen the scope nor drop it.
- Every task carries a runnable proof of done, because a subagent sees only the plan.
- An exclusive-resource overlap means recommend sequencing; an init-only workflow has no footprint
  yet, so say so.
- Run the overlap check after the footprint is written, because it cannot read a draft.
- The draft file is not committed and the plan doc stays unstaged.
- A missing optional plugin means apply its structure directly; a missing required skill is a stop.

## implement

- The plan is the file the dossier names, not the newest file.
- An uncommitted plan is a stop.
- Never rebase or force-push a branch that has a pull request.
- A finding that does not hold becomes a question with evidence, never an argument written into QC's file.
- A design question means the plan was wrong: a send-back, not a round.
- Run systematic-debugging before a fix round; no escalation off the cheap model.
- Never release a lease here; never wait in its own loop; an environment deploy with no lease marker is
  a plan gap.
- Behaviour no documentation task covers is a plan gap, not an unplanned page.
- Build only; never grade its own work.

## qc

- Never fixes what it finds.
- Findings are scoped to the diff.
- The scope script never overrules the diff you read.
- A broken build ends the pass.
- Map every acceptance criterion to the test or line that settles it.
- The reviewer gets the acceptance criteria, never the implementer's account.
- Classify every finding on two axes, blocking and whose; Phase 1 only.
- A question comes before the verdict.
- The bold verdict span counts only as the last one in the round.
- Evidence must come from this pass.
- A failed release still hands off.
- A send-back return means a full re-run.
- A missing lease or deploy identity means "not yet checkable"; an orphan is non-blocking.

## close

- Work out the phase from facts, with GitHub's REST merged semantics.
- Account for the single-PR lookup gap.
- The clear round must be newer than the review round.
- Never sweep work-in-progress into the PR; never resolve a conflict here.
- Check again for a PR template.
- A release after approval goes in a PR comment, not a commit.
- For squash merges, the proof is GitHub's state plus the tip match.
- Ask once before deleting the branch.
- Nothing is committed to the base branch after the merge.
- Release the lock last.
- Never infer a stash from a failing verdict.
- Before an irreversible put-back, stop and show the engineer.
- Never use `finishing-a-development-branch`.

## triage

- The intake-branch ledger is authoritative and merged row by row.
- Fingerprints must survive the code moving.
- Read with `git show`; never switch branches.
- Say "possibly #N"; the engineer confirms.
- A backlog decision is recorded once, not re-listed.
- A mark-Ready script failure leaves the item unrecorded, so it comes back.
- Sources unavailable in a web session are reported, not skipped silently.
- Never re-judge QC's classification.
- Quote the evidence; one item can have many sources.

## Riskiest places to rewrite (generic and project text interleaved)

1. `implement`: the paragraph deciding whether a change needs an environment deploy. Its default
   is the inverse of `scope.sh`'s fail-safe, so a rename keeps the wrong rule.
2. `qc`: the environment-evidence block (tag and ancestor rules, declared versus orphan workloads,
   starting a stopped environment) is woven with generic rules (an orphan is non-blocking; no lease
   is a wait, not a send-back).
3. `qc`: the scope, build and suites block (skip semantics, "never decides against the diff", a
   background run, a self-hosting rule). The quoted evidence format also changes.
4. `close`: the put-back section mixes tool-specific steps with "stop before irreversible" and
   "orphans are not removed".
5. `implement` and `qc`: the lease refusal kinds. A schema or base-sync refusal is not a wait; a
   holder refusal is a recorded wait. Hooks and queue refusals must stay distinct.
6. `plan`: proof of done, environment-task ordering, and why the lease is held until QC.
7. Documentation rules across `plan`, `implement` and `qc`: module rules and tool details share
   sentences.
8. `qc`: the invariants fed to the reviewer, which assumed a list it could count; with an invariants
   file the reviewer receives the file's text verbatim.

Also: `init`'s home-container versus issue-container distinction runs through four of its steps.

## Config gaps found

No key for: a deploy hook, a put-back step (decided: an overlay, not a key), the docs/plans/wiki
directories, a suite `parallel` flag, plan-shape exemplar files (decided: an overlay point).
