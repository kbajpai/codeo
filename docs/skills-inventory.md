# Skills inventory — the rules that must survive the move

Source: the eight skills: the seven of the pipeline codeo was extracted from (`issue`, `init`, `plan`,
`implement`, `qc`, `close`, `triage`), read in October 2026, and `cleanup`, which was written for codeo
and has its own `## cleanup` section. This file holds only the generic part.
Anything specific to a project (its paths, tools and domain rules) belongs in that project's own
repository, never here.

"Hard rule" below means a rule a project overlay may not override; the skill states this once, at
the top. Each skill's rewrite is checked against its list: a rule that disappears is a regression.

What the lint and the pin do not cover: the sentence under a `rule` marker (a skill can keep the
marker and gut the sentence; the task-scoped rules review in each commit message is the guard),
that an extension point's defaults agree across the registry, the doc and the skill, that
`→ Heading` citations into the protocol docs still resolve, and that script verbs and flags named
in prose exist (only the script's existence is checked).

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

- [issue-07] Priority only under issue.priority and with the engineer's approval at the gate, as a label; never Effort.

- [issue-08] A refusal from the role check ends the step; no override.

- [issue-09] A failed Backlog move never fails the filing; report the number and quote the fix.

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

- [init-10] A refusal from the role check ends the step; no override.

- [init-11] `init` resolves the user with `user whoami` before any claim; exit 1 stops it, and the login (an `unverified` one included) is recorded as the Owner and compared with the assignees like any other.

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

- [plan-09] A refusal from the role check ends the step; no override.

- [plan-10] Step 0 runs `lock.sh verify`: exit 1 prints its line and stops; `--override` only on the engineer's explicit words.

- [plan-11] An overlap question's answer is written to the footprint's `sequenced:` line before the footprint is committed: `after #M — <why> (Q<k>)` for *sequence after*, `beside #M — <what overlaps> (Q<k>)` for *proceed and coordinate*, `rescoped — <what was dropped> because of #M (Q<k>)` for *re-scope*, `locked — <resource> behind #M (Q<k>)` for an exclusive overlap the lease settles, `none` when no overlap was raised.

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

- [implement-10] A refusal from the role check ends the step; no override.

- [implement-11] Step 0 runs `lock.sh verify`: exit 1 prints its line and stops; `--override` only on the engineer's explicit words.

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

- [qc-14] A refusal from the role check ends the step; no override.

- [qc-15] Step 0 runs `lock.sh verify`: exit 1 prints its line and stops; `--override` only on the engineer's explicit words.

- [qc-16] Each round that was graded records the base commit its tree contains, `git merge-base HEAD origin/<base>`, on a `Graded base:` line, and a round that merged base commits first says how many.

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

- [close-14] A refusal from the role check ends the step; no override.

- [close-15] Step 0 runs `lock.sh verify`: exit 1 prints its line and stops; `--override` only on the engineer's explicit words, and its line is committed with close's dossier commit.

- [close-16] A stash or abandon removes the recorded owner (`lock.sh owner`); with no owner it removes the verified caller (`user whoami`) only when `verify` passed without an override, else skips and says so; never a login that was not verified.

- [close-17] Archive and push the dossier before opening the pull request.

- [close-18] Before a moved base is merged, or when the branch already holds it, `base-moved.sh` names the graded files the base changed since; any path is a send-back to `/codeo:implement` as a `— base moved` round, never a merge.

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

- [triage-10] A refusal from the role check ends the step; no override.

## cleanup

- [cleanup-01] A refusal from the role check ends the step; no override.

- [cleanup-02] A removal command is printed only for an issue the script proved; an issue that failed only `name` can still get the `leftover` branch delete.

- [cleanup-03] Never run a container command, and never mount or ask for the container engine's socket.

- [cleanup-04] Print only what the script printed; never build a name or a command in the skill.

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
