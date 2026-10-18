# Skills inventory — the rules that must survive the move

Source: the seven skills of the pipeline codeo was extracted from (`issue`, `init`, `plan`,
`implement`, `qc`, `close`, `triage`), read in October 2026. This file holds only the generic part.
Anything specific to a project (its paths, tools and domain rules) belongs in that project's own
repository, never here.

"Hard rule" below means a rule a project overlay may not override; the skill states this once, at
the top. Each skill's rewrite is checked against its list: a rule that disappears is a regression.

## issue

- [issue-01] A bare invocation asks; it never infers what to file.
- [issue-02] For a bug, run systematic-debugging Phase 1 only; a suspected but unshown cause goes in as an open
  question.
- [issue-03] Two kinds of unknown: one the engineer can answer blocks the skill; one nobody can answer yet goes
  verbatim into the draft.
- [issue-04] The caller supplies the finding, not the answers.
- [issue-05] Acceptance criteria are checkable outcomes, not a contract.
- [issue-06] File through REST because `gh issue create` cannot set the Issue Type; take the number and URL from
  the response, never reconstruct them.
- [issue-07] Never set Priority or Effort.

## init

- [init-01] Decide "is this a pull request" from `html_url` containing `/pull/`, not from an exit code.
- [init-02] A closed issue: ask, never reopen it.
- [init-03] The create-only push is the claim and runs before the assignee is added; earlier checks are advisory.
- [init-04] A resume is pushed against the tip it saw, so of two resumes exactly one wins.
- [init-05] The resume line's wording belongs to the script; write nothing else on it, and put an override in
  Notes, never on that line.
- [init-06] `unavailable` is not a failure, but the Ready check is never skipped just because it could not run.
- [init-07] Never merge, rebase or reset a container's unpushed commits.
- [init-08] Acceptance criteria are copied verbatim.
- [init-09] The state directory's `.gitignore` must be committed.

## plan

- [plan-01] Brainstorm before writing the questions.
- [plan-02] Commit and push before ending the turn, so the questions survive the machine.
- [plan-03] Out-of-scope work goes to `issue`; neither widen the scope nor drop it.
- [plan-04] Every task carries a runnable proof of done, because a subagent sees only the plan.
- [plan-05] An exclusive-resource overlap means recommend sequencing; an init-only workflow has no footprint
  yet, so say so.
- [plan-06] Run the overlap check after the footprint is written, because it cannot read a draft.
- [plan-07] The draft file is not committed and the plan doc stays unstaged.
- [plan-08] A missing optional plugin means apply its structure directly; a missing required skill is a stop.

## implement

- [implement-01] The plan is the file the dossier names, not the newest file.
- [implement-02] An uncommitted plan is a stop.
- [implement-03] Never rebase or force-push a branch that has a pull request.
- [implement-04] A finding that does not hold becomes a question with evidence, never an argument written into QC's file.
- [implement-05] A design question means the plan was wrong: a send-back, not a round.
- [implement-06] Run systematic-debugging before a fix round; no escalation off the cheap model.
- [implement-07] Never release a lease here; never wait in its own loop; an environment deploy with no lease marker is
  a plan gap.
- [implement-08] Behaviour no documentation task covers is a plan gap, not an unplanned page.
- [implement-09] Build only; never grade its own work.

## qc

- [qc-01] Never fixes what it finds.
- [qc-02] Findings are scoped to the diff.
- [qc-03] The scope script never overrules the diff you read.
- [qc-04] A broken build ends the pass.
- [qc-05] Map every acceptance criterion to the test or line that settles it.
- [qc-06] The reviewer gets the acceptance criteria, never the implementer's account.
- [qc-07] Classify every finding on two axes, blocking and whose; Phase 1 only.
- [qc-08] A question comes before the verdict.
- [qc-09] The bold verdict span counts only as the last one in the round.
- [qc-10] Evidence must come from this pass.
- [qc-11] A failed release still hands off.
- [qc-12] A send-back return means a full re-run.
- [qc-13] A missing lease or deploy identity means "not yet checkable"; an orphan is non-blocking.

## close

- [close-01] Work out the phase from facts, with GitHub's REST merged semantics.
- [close-02] Account for the single-PR lookup gap.
- [close-03] The clear round must be newer than the review round.
- [close-04] Never sweep work-in-progress into the PR; never resolve a conflict here.
- [close-05] Check again for a PR template.
- [close-06] A release after approval goes in a PR comment, not a commit.
- [close-07] For squash merges, the proof is GitHub's state plus the tip match.
- [close-08] Ask once before deleting the branch.
- [close-09] Nothing is committed to the base branch after the merge.
- [close-10] Release the lock last.
- [close-11] Never infer a stash from a failing verdict.
- [close-12] Before an irreversible put-back, stop and show the engineer.
- [close-13] Never use `finishing-a-development-branch`.

## triage

- [triage-01] The intake-branch ledger is authoritative and merged row by row.
- [triage-02] Fingerprints must survive the code moving.
- [triage-03] Read with `git show`; never switch branches.
- [triage-04] Say "possibly #N"; the engineer confirms.
- [triage-05] A backlog decision is recorded once, not re-listed.
- [triage-06] A mark-Ready script failure leaves the item unrecorded, so it comes back.
- [triage-07] Sources unavailable in a web session are reported, not skipped silently.
- [triage-08] Never re-judge QC's classification.
- [triage-09] Quote the evidence; one item can have many sources.

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
