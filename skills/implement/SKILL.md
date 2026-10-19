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
SUBAGENT_MODEL=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.models.subagent // "sonnet"')
```

`$DOCS` and `$SUBAGENT_MODEL` always have a value. `$ENV_RESOURCE` and `$WIKI` exit 1 with
nothing printed when the key is absent, and that is an answer, not a failure: no shared
environment (no lease to take, no deploy to run, and nothing in this skill about the environment
applies — step 5), no `wiki` module (the plan names no wiki pages, and its documentation tasks are
pages under `$DOCS`).

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
    the files and how each was resolved in the outcome. Exit 1 is a stop: report the one line it
    printed — tracked changes in the tree, or a merge that failed without a conflict — and stop.
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

5. **Invoke the plan's own required sub-skill.** Every plan `/codeo:plan` writes opens with the
   `REQUIRED SUB-SKILL` banner that `superpowers:writing-plans` writes. Follow that banner via the
   Skill tool — default to `superpowers:subagent-driven-development` for independent tasks worked
   in this session; use `superpowers:executing-plans` instead if the engineer wants
   checkpoint-by-checkpoint review across separate sessions. This skill does not re-implement task
   dispatch, checkbox tracking or per-task review — that is what the sub-skill already does.
   <!-- rule: implement-06 -->
   One thing it does override: the sub-skill's *Model Selection* section. Every implementer,
   reviewer and fix-round dispatch passes `model: "$SUBAGENT_MODEL"`, the rounds where the
   sub-skill says to move to a more capable model included — never an escalation, never an omitted
   `model` (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Spinning out subagents`). When a task fails its
   review or its proof-of-done, invoke `superpowers:systematic-debugging` before dispatching the
   next fix round, and put the root cause it finds in that round's prompt — a retry without one is
   a guess made twice. A task still failing at the last fix round on the subagent model is a task
   the plan under-specified: stop and report it, and never escalate it to another model instead.

   **The shared environment — only when `$ENV_RESOURCE` is set.** With it empty there is no
   shared environment: no lease to take, no deploy to run, nothing in the rest of this part
   applies, and the round's outcome says nothing about a deployment. With it set:

   <!-- point: implement/environment-lease-notes -->
   Fetch the project's notes on its environment with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" implement environment-lease-notes`: on exit 0,
   follow the printed text — anything the project says about taking, holding and deploying to its
   environment — as it adds to or narrows the paragraphs below; on exit 3, there are none and the
   paragraphs below are the whole rule; on exit 1, 2 or 4, report the one `codeo:` line it printed
   to the engineer and carry on without notes.

   **The first task marked `Needs lease: <the value of $ENV_RESOURCE>` takes the lease, and this
   workflow keeps it.** Before dispatching it:
   - Step 2a has already merged the base branch in. The environment is about to run this branch,
     and the take refuses one that does not contain `origin/<baseBranch>`, since it would roll
     back already-merged work; if it refuses on that, run step 2a again, then take again.
   - `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease take "$ENV_RESOURCE" <N> "<task name>"`.
     The take also runs the project's environment hooks (`start`, `preflight`, `activate`) before
     it publishes anything. Its refusals are handled apart:
     - **The queue.** The refusal names the issue that holds the lease
       (`<resource> is leased to #<M>`) or the waiter whose turn it is
       (`<resource> is #<M>'s turn — … keeps right of way until <time>`). That is a wait — *A take
       that is queued*, below.
     - **A hook.** The refusal reads `intake: <resource> refused — the <name> hook exited <rc>`, and
       nothing was published. That is not a wait: report the hook and what it printed to the
       engineer, record no wait, and stop. A failing hook is the project's to fix, and
       `--override` does not get past it.
     - **Anything else** — origin unreachable, a push that failed after its retries: report the one
       line it printed and stop, and record no wait.
   - Only with the engineer's say-so take it with `--override "<reason>"` — the reason goes to the
     hooks, which decide whether it excuses anything — and put
     `lease <resource> taken with override: <reason>` in this round's `## Log` line.

   **Then deploy — right after the take, before dispatching the task that needed it**, so that task
   runs against this branch as deployed. Read the project's deploy step with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .environment.hooks.deploy`. Nothing printed
   (exit 1) while the plan has a `Needs lease:` task is a plan gap: stop and report it — the plan
   needs the environment and the project has no way to put this branch there. Otherwise, from the
   project root, note `git rev-parse HEAD`, then run the hook as
   `CODEO_ISSUE=<N> CODEO_RESOURCE="$ENV_RESOURCE" bash -c "$cmd"` (`$cmd` being the printed
   command), capturing its stdout:
   - Its last stdout line is the revision it deployed: record it in this round's `## Outcome` as
     `Deployed revision: <x>`. An empty last line means the `HEAD` noted before the hook ran;
     record that, and say the hook printed no revision.
   - A non-zero exit is a failed task, not a lease refusal: the debugging rule above applies.
   - Anything `git status --porcelain` prints after the hook is a stop. The hook commits its own
     bookkeeping, so a dirty tree is work it left undone: report the paths, and never commit them.

   <!-- rule: implement-07 -->
   Once taken, **the lease is never released here** — not after the task, not at the hand-off, not
   on a send-back. It is held until `/codeo:qc`'s clear verdict, which releases it, so a later
   environment task and `/codeo:qc`'s environment checks all run on what this issue left. Never
   wait for it in a loop of your own, and never deploy without it. A deploy with no `Needs lease:`
   line in its task is a plan gap: take the lease anyway, and report the gap
   (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Parallel workflows`).

   **A take that is queued** stops at that task. Record the wait with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease wait "$ENV_RESOURCE" <N>`. Every task
   before it is done and committed, so write `## Where this stands` in `.codeo/<N>/implement.md`
   to say so and who holds the lease or has the turn, commit and push the dossier as at step 4,
   and end the turn. Offer the engineer a background watch instead of a bare stop — the Monitor
   tool, which notifies the session and costs nothing while it waits; the watch is the engineer's
   to accept, never a loop this skill runs itself:
   - after `is leased to #<M>`, a watch until the resource leaves the held list —
     `until ! bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease list | grep -qFx "== $ENV_RESOURCE — held"; do sleep 300; done`;
   - after `is #<M>'s turn`, the resource is already free, so that watch would fire at once: watch
     instead until the `keeps right of way until <time>` the refusal names has passed —
     `until (( $(date -u +%s) >= $(date -u -d "<time>" +%s) )); do sleep 300; done`.

   When it fires, resume from this task, taking the lease first — the holder or the waiter ahead
   may still have it, or someone else may have been quicker, and a refusal then is handled as
   above.

   **Before the hand-off to QC, in every round — the first included — check whether the
   environment still runs this branch**, since a later task can change what it runs. The revision
   to compare is the last `Deployed revision:` in this file's `## Outcome` (only this skill
   deploys). With none, the issue never used the environment: there is nothing to compare, so take
   the lease only if this round newly needs it. Otherwise run
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/scope.sh" <that revision> HEAD` and read its `deploy=`
   line. `deploy=false` means no environment work and no take. `deploy=true` means take the lease
   (`lease take "$ENV_RESOURCE" <N> "<round>"`, a re-take while this issue still holds it, else
   queued behind any waiter: a queue refusal is the same record-a-wait stop as above), deploy as
   above, and record the new `Deployed revision:` in the round's outcome.
   With no suites configured the script prints no `deploy=` line at all and exits 0: decide from
   `git diff <revision>...HEAD` yourself, and say so in the outcome.
   A non-zero exit from the script, with its `scope:` line, means the revision does not resolve
   here (a tag not fetched, say): `git fetch` once and run it again. Still failing, decide from
   `git diff <revision>...HEAD` yourself, or redeploy when the revision cannot be resolved at all,
   and say which you did, and why, in the outcome.
   The script never overrules the diff you read: a change you can see alters what the environment
   runs is a redeploy whatever it prints — say why.

   **Documentation tasks are tasks like any other**, dispatched and reviewed the same way: pages
   under `$DOCS`, and wiki pages when `$WIKI` is set. A page describes what the system does
   *after* this change — present tense, no issue numbers, no "now", no history of what it used to
   do — because it is read long after anyone remembers the issue. Draw each diagram the way the
   plan's task says to; if a diagram tool the task names cannot run, stop and say so in
   `## Outcome` rather than committing a diagram it did not produce.
   <!-- point: implement/wiki-rules -->
   Fetch the project's documentation rules with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" implement wiki-rules`: on exit 0, follow the
   printed text — how its pages are written, linked and indexed, and which diagrams are drawn with
   which tool — for every documentation task; on exit 3, the rules are only the conventions the
   existing pages under `$DOCS` already follow; on exit 1, 2 or 4, report the one `codeo:` line and
   use those conventions.
   <!-- rule: implement-08 -->
   Behaviour the code gained that no documentation task covers is a plan gap: report it in
   `## Outcome` rather than writing an unplanned page.

6. **Confirm it builds, and stop there.** Read the configured suites with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.suites[]? | [.name, .build, (.parallel // false)] | @tsv'`
   and run each suite's `build` command from the project root, so a broken build is caught here
   rather than wasting a QC pass; suites whose `parallel` is `true` may run together, the rest one
   at a time, and a suite with no `build` has nothing to run here. Nothing printed means no suites
   are configured: say there is no build command to run, and record that as the build result —
   never invent one.
   <!-- rule: implement-09 -->
   Build only, and never grade your own work. The full suites, the acceptance criteria, the
   project's invariants and the code review all belong to `/codeo:qc` — running them here would
   duplicate its work and, worse, let the skill that wrote the code grade it.

7. **Don't claim the tasks are done on your own say-so.**
   `superpowers:verification-before-completion` applies to what this skill asserts — that the
   plan's tasks were dispatched and the tree builds — not to the change's quality. Evidence before
   assertions, within this skill's own scope.

8. **Write `implement.md`'s `## Outcome` before reporting.** Nothing in `.codeo/<N>/implement.md`
   may still be open at this point. Record what was built, the documentation pages changed, the
   build result, `Deployed revision: <x>` when the round deployed, and anything that deviated from
   the plan and why; a round after a send-back goes beneath the first as its own dated
   `### Round <n>`. Append one `## Log` line, ending `· cost: ` with what
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" implement` prints, then commit the dossier, staged
   by name, and push as at step 4, with the subject `docs(codeo): implement dossier for #<N>`
   (`— round <n>` for a later round; `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Durability`).

9. **Report** which checklist tasks completed, the build result, and hand off to `/codeo:qc`.
   This skill does not declare the change good — it declares the plan's tasks done.

## Hand-off

`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md` is the protocol; this is this skill's half of it.

- **Reads** the committed plan file, `.codeo/<N>/init.md` and `plan.md`, `qc.md` or `close.md`
  when sent back, the codebase, the pages under `$DOCS` (and the wiki pages, with the `wiki`
  module) that the plan's documentation tasks name, the project's overlay sections for this skill,
  and every other in-flight workflow's footprint through `inflight.sh` and `overlap.sh`.
- **Takes** the lease on `$ENV_RESOURCE`, when one is configured, at the first task that needs it,
  and records a wait when another issue holds it or has the turn — through `intake.sh lease` only
  — and again before any round's hand-off when the change since the last deployed revision alters
  what the environment runs (`scope.sh`'s `deploy=true`, or the diff read directly). It never
  releases it; that is `/codeo:qc`'s, at its clear verdict.
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
- **Spins out subagents** on the configured subagent model (`$SUBAGENT_MODEL`: `models.subagent`,
  sonnet when unset), passed explicitly on every dispatch, the sub-skill's own included, and
  never escalated to another model on a later round; it prefers a direct `grep`/`Read` over an
  agent when the target is already known — see
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
