---
name: implement
description: Execute an approved, committed implementation plan task-by-task through the plan's own superpowers sub-skill, taking the project's shared environment lease when a task needs it, confirming the change builds, and handing off to /codeo:qc for grading. Trigger on "implement the plan", "let's build this", "start implementing <plan>", or right after a plan under the project's plans directory has been reviewed, approved and committed. Never drafts a plan or an issue — those are /codeo:plan and /codeo:issue.
argument-hint: "[optional: plan path or slug — defaults to the one plan.md names]"
model: sonnet
---

Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

# Implementing `$ARGUMENTS`

This skill executes an already-approved plan. It doesn't plan, draft issues, or decide
architecture itself — those are `/codeo:issue` and `/codeo:plan`. If the plan looks wrong or stale
once implementation starts, stop and say so rather than silently deviating from it, and suggest
re-running `/codeo:plan`. Work that surfaces mid-task but belongs to no task in the plan goes to
`/codeo:issue` as its own issue — the plan's scope is the plan's scope.

Where things go is read from the project's config, never assumed:

```bash
DOCS=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.docsDir // "docs"')
ENV_RESOURCE=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .environment.resource)
WIKI=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.modules[]? | select(. == "wiki")')
```

`$DOCS` always has a value. The other two exit 1 with nothing printed when the key is absent, and
that is an answer, not a failure: no shared environment (no lease to take, no deploy to run, and
nothing in this skill about the environment applies — step 5), no `wiki` module (the plan names no
wiki pages, and its documentation tasks are pages under `$DOCS`).

## Workflow

0. **Read `.codeo/active` before anything else.** The lock names the issue this workflow is
   bound to, which is what makes a bare invocation unambiguous here — the engineer named the issue
   when they ran `/codeo:init`. No lock means no workflow here: name `/codeo:init #<N>` as the
   step that was skipped — or, when the project's host workflow binds the lock in another checkout,
   say to run this step there — and stop. A lock whose `branch` disagrees with
   `git branch --show-current`, or an argument naming a different issue, is a hard stop too.
   `${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → The lock` has all three checks. `<N>` below is the
   lock's `issue`.

1. **Resolve the plan file from `plan.md`.**
   <!-- rule: implement-01 -->
   The plan is the file that `.codeo/<N>/plan.md`'s `## Outcome` names — the one `/codeo:plan`
   wrote — not whichever file under the config's `plansDir` looks most recent. An argument
   overrides it only within the locked issue, and a mismatch between the two is worth saying out
   loud before acting on either. If that outcome is still `_Pending_`, the previous step hasn't
   finished — say so and stop.

2. **Confirm the plan is a locked, reviewed artifact, not a moving draft.**
   <!-- rule: implement-02 -->
   An uncommitted plan is a stop. `/codeo:plan` deliberately leaves a new plan file unstaged after
   the engineer's approval — it never commits. Check `git status` and `git log` for the file: if it
   is uncommitted or only staged, stop and confirm with the engineer that it is final (and offer to
   commit it) before dispatching any implementation work against it. Implementation starts from a
   plan that cannot move out from under it.

2a. **Start the round from the base branch:** `bash "${CLAUDE_PLUGIN_ROOT}/scripts/sync-main.sh"`.
    A clean merge is committed by the script; copy its `also changed on <base>:` lines into this
    round's `## Outcome` and re-check this branch's work against each. A conflict (exit 2) is this
    round's first work: resolve each file against both changes' intent, `git commit`, and record
    the files and how each was resolved in the outcome. Exit 1 means the tree has tracked changes:
    say so and stop, since the merge cannot start over them.
    <!-- rule: implement-03 -->
    Never rebase or force-push a branch that already has a pull request — history on it is only
    ever added to.
    Then run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlap.sh" <N>`. Each line it prints is an
    overlap not already raised in this issue's dossiers, and becomes a numbered question in *this*
    step's dossier, `.codeo/<N>/implement.md`: quote `#M` and the printed `what` verbatim, with the
    other issue's branch, assignee and step from `bash "${CLAUDE_PLUGIN_ROOT}/scripts/inflight.sh"`,
    and the same three options — *proceed and coordinate* · *sequence after #M* · *re-scope*.
    The step stops until it is answered, as at step 4.

3. **Read the plan fully, and everything upstream of it** — Goal, Architecture, Tech Stack, Spec,
   Global Constraints and the task checklist, plus `.codeo/<N>/init.md` and `plan.md`. Between
   them they answer most of what would otherwise be a question; don't re-ask what they already
   settle.

   <!-- rule: implement-04 -->
   **Sent back?** From `/codeo:qc`, read the latest round in `.codeo/<N>/qc.md`'s `## Outcome`;
   from `/codeo:close` with review feedback on the pull request, the latest review round in
   `.codeo/<N>/close.md`'s. A send-back for a conflict with the base branch — a parallel workflow
   merged first — is work like any other, and step 2a already did its merge: record what was
   resolved and how in this round's outcome, under step 2a's rule on rebasing. Either way, invoke
   `superpowers:receiving-code-review` via the Skill tool before touching code, and check each
   finding against the code and the plan rather than agreeing with it on sight. A finding that
   holds becomes work in this round. One that does not — wrong about the code, or asking for
   something the plan rules out — goes into `.codeo/<N>/implement.md` as a numbered question with
   the evidence, for the engineer to settle at step 4. Never quietly skip it, and never argue it
   back into `qc.md` or `close.md`: those are those skills' files. Replying to the reviewer is the
   engineer's, or `/codeo:close`'s summary once the fix is through QC.

4. **Put any real ambiguity in the dossier, and stop.** Write `.codeo/<N>/implement.md` with one
   numbered question per thing that would change what gets built —
   `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → The shape of a file` is the format and
   `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Questions, and the cycle` the rules for a question.
   Commit it, staged by name, with the subject
   `docs(codeo): implement dossier for #<N> — Q<first>-Q<last> raised`, and push
   (`${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Durability`); then print the path and the numbers
   still open, and end the turn. Dispatching tasks around a guess is how a plan gets silently
   deviated from. Re-invoking this skill resumes from the file: re-read it and take the answers.
   <!-- rule: implement-05 -->
   Expect few questions here: the plan should have settled the design. A question that is really a
   design question means the plan was wrong, and that is a send-back to `/codeo:plan`, not a
   round of questions here.

<!-- steps 5-9 are added by the next task -->

## Hand-off

`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md` is the protocol; this is this skill's half of it.

- **Reads** the committed plan file, `.codeo/<N>/init.md` and `plan.md`, `qc.md` or `close.md`
  when sent back, the codebase, the pages under `$DOCS` (and the wiki pages, with the `wiki`
  module) that the plan's documentation tasks name, the project's overlay sections for this skill,
  and every other in-flight workflow's footprint through `inflight.sh` and `overlap.sh`.
- **Takes** the lease on `$ENV_RESOURCE`, when one is configured, at the first task that needs it,
  and records a wait when another issue holds it — through `intake.sh lease` only — and again in a
  review round when `scope.sh`'s `deploy=` line is `true`. It never releases it; that is
  `/codeo:qc`'s, at its clear verdict.
- **Writes** application and test code, the documentation pages the plan names, and
  `.codeo/<N>/implement.md` — its questions, its `## Outcome`, and one `## Log` line per
  invocation — committed and pushed on every turn it writes it.
- **Never touches** the plan's text, the issue's text, a documentation page the plan does not
  name, or another skill's dossier file. A plan that is wrong gets reported, not edited.
- **May call** `/codeo:issue` for out-of-scope findings — a call, not a hand-off: control
  returns, and this skill records the number in its own outcome and log line
  (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → A call is not a hand-off`).
- **Hands off to** `/codeo:qc`, naming the branch and the plan it worked from — and only once
  nothing in `.codeo/<N>/implement.md` is still open. It may be sent back here with findings; that
  opens a new round in the same file, never an edit to an answered one
  (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → A send-back`).
- **Spins out subagents** on the configured subagent model (`models.subagent`, sonnet when unset),
  passed explicitly on every dispatch — the sub-skill's own included, its escalation rounds too —
  and prefers a direct `grep`/`Read` over an agent when the target is already known — see
  `${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Spinning out subagents`.

## Non-goals

- Doesn't author an issue itself — that's `/codeo:issue`'s purview — though it delegates
  out-of-scope findings to that skill rather than absorbing them into this change.
- Doesn't design or write a plan — that's `/codeo:plan`'s.
- Doesn't invent its own task-execution loop: it delegates to the `superpowers:*` sub-skill the
  plan names, which already owns task dispatch, checkbox tracking and per-task review, so this
  skill stays a thin, project-aware dispatcher.
- Doesn't grade its own work: the full test suites, the acceptance criteria, the invariants and
  the code review are `/codeo:qc`'s purview.
- Only touches the code the plan's File Structure names and the documentation pages its tasks
  name, plus optionally committing the plan file itself (step 2) — it never edits the plan's
  content. That's `/codeo:plan`'s purview.
