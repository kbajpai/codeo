---
name: plan
description: Brainstorm, architect, and document a feature or change for this project before any code is written — explores existing conventions, asks clarifying questions in the dossier, produces Mermaid diagrams, checks the change's footprint against every other workflow in flight, and saves a reference doc or implementation plan under the project's docs or plans directory only after explicit review. Trigger on "plan out", "design", "architect", before starting non-trivial implementation work, or right after /codeo:init hands off. Never writes application code.
argument-hint: "[optional: which part of the locked issue to plan]"
model: fable
---

Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

# Planning `$ARGUMENTS`

This skill produces a reviewed planning artifact under the project's docs or plans directory. It
never edits application code — that is a separate, later step, `/codeo:implement`, which hands the
plan to `superpowers:executing-plans` or `superpowers:subagent-driven-development` once this
skill's output is approved.

This is the pipeline's thinking step, so it runs on the strongest model available and draws on
whatever `superpowers:*` skill fits the work — `brainstorming` and `writing-plans` below are the
two that always apply, not the only two it may use. A skill that would sharpen the design is worth
the tokens here; this is the one place in the flow where that trade is obviously correct.

Where things go is read from the project's config, never assumed:

```bash
DOCS=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.docsDir // "docs"')
PLANS=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.plansDir // "docs/plans"')
INVARIANTS=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .invariants)
ENV_RESOURCE=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .environment.resource)
WIKI=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.modules[]? | select(. == "wiki")')
```

`$DOCS` and `$PLANS` always have a value. The other three exit 1 with nothing printed when the key
is absent, and that is an answer, not a failure: no invariants document (nothing to check the plan
against), no shared environment (no environment tasks and no lease marker — step 8), no `wiki`
module (no wiki pages to name, and the footprint's `wiki:` line says `none`). The test suites the
plan's proofs run are the config's `suites[]`, each with a `name`, the `paths` that trigger it, and
its `build` and `test` commands, and an optional `filter` — a command template that runs one test,
`{}` standing for the test's name (`pytest -k {}`, say):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.suites[]? | .name'
bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.suites[]? | select(.name == "<suite>") | .test'
```

(and the same with `.build`, `.filter` or `.paths[]?`). The `?` forms matter: an absent array or
field then exits 1 with nothing printed rather than a config fault. No suites configured is an
answer too: each task then names its own proof command in full (step 8).

## Workflow

0. **Read `.codeo/active` before anything else.** The lock names the issue this workflow is
   bound to, which is what makes a bare invocation unambiguous here — the engineer named the issue
   when they ran `/codeo:init`. No lock means no workflow here: name `/codeo:init #<N>` as the
   step that was skipped — or, when the project's host workflow binds the lock in another checkout,
   say to run this step there — and stop. A lock whose `branch` disagrees with
   `git branch --show-current`, or an argument naming a different issue, is a hard stop too.
   `${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → The lock` has all three checks. `<N>` below is the
   lock's `issue`.

1. **Read what came before, then restate the request.** Read `.codeo/<N>/init.md` — its
   `## Outcome` carries the issue restated, the acceptance criteria verbatim, and what intake left
   open, so don't re-fetch the issue or re-ask what it already answers — and `.codeo/<N>/issue.md`
   when `init` adopted one. An argument, when there is one, narrows scope *within* the locked issue
   rather than replacing it. Then skim the project's agent instructions (its `CLAUDE.md` or
   equivalent), the pages under `$DOCS` for the area the change touches — and, with the `wiki`
   module, the wiki pages for it — and recent plans under `$PLANS` for prior art, terminology, and
   conventions already in use. With `$INVARIANTS` set, read that document in full: it is what the
   plan is checked against at step 8. Don't reinvent a pattern that already exists in this
   project.

2. **Explore read-only.** Look at the actual code, the shared abstractions, and the test patterns
   the change would touch, so the plan is grounded in what's really there rather than assumed
   structure. For anything beyond a quick, targeted lookup, delegate to an Explore agent, on the
   configured subagent model (below).

3. **Invoke `superpowers:brainstorming` via the Skill tool, then write the questions into the
   dossier.**
   <!-- rule: plan-01 -->
   Brainstorming runs *before* the questions, not after — superpowers' own rule is that it
   precedes any creative work, and it is what structures this exploration. Then open
   `.codeo/<N>/plan.md` and put everything materially ambiguous in it as numbered questions:
   scope, which components are affected, PR-splitting preference, non-functional requirements.
   This is the step that most needs a file rather than the conversation — planning questions take
   prose to answer and they arrive in batches. `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → The shape
   of a file` is the format, and `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Questions, and the cycle`
   the rules for a question.

4. **Stop until they are answered.**
   <!-- rule: plan-02 -->
   Commit `.codeo/<N>/plan.md` and push before saying anything — staged by name, with the subject
   `docs(codeo): plan dossier for #<N> — Q<first>-Q<last> raised`
   (`${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Durability`). This is the stop that hands control
   back to a human indefinitely, so it is the one that most needs to survive the machine. Then
   print the dossier's path and the numbers still open, and end the turn. Do not draft past an
   unresolved unknown. Re-invoking this skill resumes *from the file*: re-read it, take the
   answers, and either raise follow-ups as new numbers or carry on. Raise the follow-ups — a plan
   drafted around a half-answer costs more to unpick later than another round costs now.
   <!-- rule: plan-03 -->
   When exploration turns up real work that doesn't belong in this plan, neither widen the scope
   to absorb it nor drop it: delegate it to `/codeo:issue`, which files it as its own issue and
   hands the number back.

5. **Decide the output's shape, and say so before drafting.**
   <!-- point: plan/plan-shape -->
   Fetch the project's house conventions with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" plan plan-shape`: on exit 0, follow the
   printed text — exemplar plans and reference docs to match, and the sections the project's
   documents carry — as it adds to or narrows the shapes below; on exit 3, use the generic shape
   below as it stands; on exit 1, 2 or 4, report the one `codeo:` line it printed to the engineer
   and use the generic shape.
   - **`$DOCS/<slug>.md`** (a status banner and a `## Contents` table of contents) when the output
     is a *standing decision or subsystem reference* that will still be read long after the work
     ships.
   - **`$PLANS/YYYY-MM-DD-<slug>.md`** (Goal / Architecture / Tech Stack / Spec / Global
     Constraints, checkbox tasks, opening with the `REQUIRED SUB-SKILL` banner that
     `superpowers:writing-plans` writes) when the output is a *scoped, executable body of work*
     meant to be picked up task-by-task.
   - If both apply — a real architectural choice plus concrete build steps — produce the plan doc
     with a `**Spec:**` line pointing at a `$DOCS/<slug>.md` reference doc, creating or updating
     that reference doc too.

6. **Pull in `engineering:system-design`** via the Skill tool when the work involves new
   components, data flows, or API/service boundaries, to structure the deep-dive (data model, API,
   caching, error handling, scale).

7. **Pull in `engineering:architecture`** via the Skill tool whenever a real technology or
   architectural choice is being decided, even if the final artifact is an implementation plan
   rather than a standalone ADR. Fold its Context / Decision / Options Considered / Trade-off
   Analysis / Consequences / Action Items structure into the doc chosen in step 5 instead of always
   emitting a separate file.

   <!-- rule: plan-08 -->
   A missing optional plugin means apply its structure directly; a missing required skill is a
   stop. Steps 6 and 7 use the `engineering` plugin, which is optional and may not be installed
   where this runs. When its skill is not listed, apply the structure above directly — the section
   names are all this step needs — and say in `plan.md`'s `## Log` line that the skill was
   unavailable. The `superpowers:*` skills are different: the pipeline requires them, and a missing
   one is a broken installation, so stop and say to install `superpowers` (`/codeo:doctor`'s
   `superpowers` check reports it).

8. **Draft the document** — pull in `superpowers:writing-plans` via the Skill tool when step 5
   chose a plan under `$PLANS`, since that skill owns the task-decomposition shape the plans use.
   Follow the convention chosen in step 5 exactly: section names, ordering, and tone should match
   the existing files under `$DOCS` and `$PLANS` rather than invent a new format. Add Mermaid
   diagrams (fenced ` ```mermaid ` blocks) wherever they clarify flow, state, or sequencing; they
   render natively in Markdown on GitHub, so the diagram travels with the doc. With `$INVARIANTS`
   set, check the draft against that document and state under Global Constraints each invariant
   the change touches and how the plan keeps it; with none set, there is no such check to make.

   <!-- rule: plan-04 -->
   **Every task in a plan under `$PLANS` ends with its own proof of done**: the exact command and
   the result it must give. Each task is executed by a subagent that sees only the plan, so "done"
   has to be something it can run rather than something it has to judge.
   <!-- point: plan/proof-of-done -->
   Fetch the project's form for it with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" plan proof-of-done`: on exit 0, follow the
   printed text; on exit 3, the proof is the default — for the configured suite whose `paths` the
   task touches, the suite's `filter` with `{}` replaced by the name of the test the task writes; a
   suite without `filter` has no single-test form, and its whole `test` command is the proof. A
   task with no test to write is proved by the suite's `build`; a documentation-only task by a
   check the task names — the documentation builds, its links resolve, or the suite's `build` —
   never by no proof at all. On exit 1, 2 or 4, report the one `codeo:` line and use the default.
   With no suites configured, the task names its proof command in full — whatever runs the check
   it writes. Name the suite and the test, never a tool the config does not name. Write the tasks the
   way `superpowers:test-driven-development` runs them — the failing test first, its expected
   failure, then the code that makes it pass — so that check exists before the code it proves.

   **Name the documentation the change moves.** A change to what the application does — an
   endpoint, a flow, a status, a configuration key, a screen, a deployment step — makes some page
   under `$DOCS` (and, with the `wiki` module, some wiki page) wrong the moment it merges. Find
   which, and give each its own task: the page, the section, and what it must say afterwards, with
   any diagram that has to change. A flow, a sequence or a state machine is Mermaid. A change that
   moves no page says so in one line under Global Constraints, so `/codeo:qc` can tell a
   deliberate "nothing to document" from a forgotten one. The *why* stays in the plan and the
   reference docs; the documentation task describes what the system does and links there.
   <!-- point: plan/wiki-rules -->
   Fetch the project's documentation rules with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" plan wiki-rules`: on exit 0, follow the
   printed text — how its pages are written, linked and indexed, and which diagrams are drawn with
   which tool — for every documentation task; on exit 3, the rules are only the conventions the
   existing pages under `$DOCS` already follow; on exit 1, 2 or 4, report the one `codeo:` line and
   use those conventions.

   **Mark the tasks that need the shared environment, and put them last** — when one is
   configured. With `$ENV_RESOURCE` empty there is no shared environment: no task carries a lease
   marker, and every task is proved in the issue's own checkout. With one, a task that runs against
   the environment rather than in this checkout — deploys to it, runs something there, changes it
   — starts with `Needs lease: <the value of $ENV_RESOURCE>`. Everything else runs in the issue's
   own checkout — builds and the configured suites, in parallel with every other issue — so order
   the plan with every task the suites can prove first, and the environment tasks after them, and
   say so under Global Constraints. The reason is the lease: `/codeo:implement` takes it at the
   first `Needs lease:` task and keeps it until `/codeo:qc`'s clear verdict releases it, so every
   task placed after the first environment task holds the environment away from every other issue
   while it runs — `${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Parallel workflows`. Whether a review
   round needs the environment again is not the plan's business: `/codeo:implement` decides that
   from `scope.sh`'s `deploy=` line.
   <!-- point: plan/environment-lease-notes -->
   Fetch the project's notes on environment tasks with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" plan environment-lease-notes` when
   `$ENV_RESOURCE` is set: on exit 0, follow the printed text — what counts as an environment task
   here, and anything the project says about holding the lease; on exit 3, there are none and the
   paragraph above is the whole rule; on exit 1, 2 or 4, report the one `codeo:` line and carry on
   without notes.

   **Check the footprint against every other workflow in flight.** Draft the `### Footprint`
   block (`${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → The footprint`) from the plan's File Structure
   (`files:`), its wiki tasks (`wiki:`, the page names — `none` without the `wiki` module), and the
   exclusive resources it changes (`exclusive:`, names from
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.resources[]? | .name'` — nothing printed
   means none are configured — whose `paths` the plan's files fall under; a parameterised one is
   written `<name>:<suffix>`). `exclusive:` never
   lists `$ENV_RESOURCE`: the later steps lease the environment from its first task, not the plan.
   A key with nothing under it says `none`. Then run
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/inflight.sh" --except <N>` — one block per other workflow:
   its issue, branch, assignee, last finished step, its plan's footprint lines when it has one,
   and the files its branch has changed — and compare. Each overlap becomes a numbered question in
   `plan.md`: shared files, a shared page, or above all a shared `exclusive` resource. The
   question names the other issue as `#M`, its branch, its assignee, its step and exactly what
   overlaps — a path, a page, or `exclusive:<name>` — and offers *proceed and coordinate* ·
   *sequence after #M* · *re-scope*. Quote `#M` and the printed token verbatim (`wiki:<Page>`,
   `glob:<glob>`, `exclusive:<name>`, or the path), as at step 10 sub-step 2: that is what lets
   `overlap.sh` recognise the pair as already raised.
   <!-- rule: plan-05 -->
   For an `exclusive` overlap, recommend sequencing: two changes to one exclusive resource on
   parallel branches do not merge cleanly, whatever the diff looks like. The gate below waits on
   these like any other open question. A workflow that is only at `init` has no footprint yet, so
   say so rather than assuming it touches nothing — its `changed:` line is all there is to compare.

9. **Review gate — do not skip or shortcut this:**
   - **Write the draft to a preview file first**, then present it in the conversation. The file
     goes under `.codeo/<N>/` as `plan-draft.md` (and `<slug>-draft.md` for a reference doc) — a
     Mermaid diagram is unreadable as fenced text, and a long draft can exceed what one message may
     carry, so the file is what the engineer actually reviews; the conversation carries the whole
     draft too, or a faithful summary plus the path when it will not fit.
     <!-- rule: plan-07 -->
     The draft file is a working artifact: it is not committed, and it is deleted once the real
     file under `$PLANS` or `$DOCS` is written after approval — which itself stays unstaged, below.
   - Anything still unresolved goes back to the dossier as a new numbered question, and the gate
     waits. A draft presented over an open question asks the engineer to approve a guess.
   - Ask the engineer explicitly to approve, request changes, or reject.
   - Only write the file under `$PLANS` or `$DOCS` after approval.
   - Do not `git commit` or open a PR automatically. Leave the new or changed file unstaged so the
     engineer reviews it via `git diff`/`git status` like any other change in this project.
     Committing or opening a PR is a distinct step the engineer asks for separately, never implied
     by "save the plan."

10. **Check the footprint as written, then write `plan.md`'s `## Outcome` before reporting
    anything.** The checks come first and the outcome last, because an `## Outcome` that is not
    `_Pending — written at the hand-off._` tells every other workflow, through `inflight.sh`, that
    this one is past `plan` — and no outcome is written while a question is open
    (`${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → The gate`).

    1. **Write the footprint down.** Put the `### Footprint` block, as step 8 drafted it and the
       answers since have amended it (with a `sequenced:` line when an overlap question was
       answered that way), under `plan.md`'s `## Notes`, leaving `## Outcome` pending. Commit it
       alone, staged by name, with the subject `docs(codeo): plan dossier for #<N> — footprint`,
       and push.
       <!-- rule: plan-06 -->
       Only now run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlap.sh" <N>` — step 8 compared a
       draft, which `overlap.sh` cannot read; it reads the `### Footprint` in this checkout's
       `plan.md`, wherever in the file it sits, and every other workflow's pushed branch. It prints
       one `M<TAB>what` line per overlap not already raised in this issue's dossiers, where `what`
       is a path, `glob:<glob>`, `wiki:<Page>` or `exclusive:<name>`, and nothing when there is
       none.
    2. **Raise what it prints.** Each line becomes a numbered question that quotes `#M` and the
       printed `what` verbatim — `overlap.sh` drops a pair as already raised only when a `### Q`
       block names both — together with the other issue's branch, assignee and step from
       `inflight.sh`, and the options *proceed and coordinate* · *sequence after #M* ·
       *re-scope*; for `exclusive:` a lock replaces *sequence after*. With any question raised,
       commit and push the dossier as at step 4 and stop, `## Outcome` still pending. Re-invoked
       once they are answered, amend the footprint in `## Notes` and run this step again from
       sub-step 1, which commits it (skip the commit when the footprint is unchanged).
    3. **Take the locks the footprint names.** For each `exclusive` entry,
       `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease take <resource> <N> "<plan slug>"`. A
       refusal names the holder: record the wait
       (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease wait <resource> <N>`), write it under
       `## Where this stands`, commit, push, and stop with `## Outcome` still pending — the
       hand-off waits for the lock as `implement` waits for the environment; re-invoked, run this
       step again from sub-step 1. For exclusive resources the lock replaces *sequence after*;
       `sequenced:` remains for files and pages.
    4. **Write the outcome — only when nothing was raised and every lock is held.** Nothing in
       `.codeo/<N>/plan.md` may still be open. The outcome is the plan file's path, the shape
       chosen in step 5, the decisions made and the options rejected, the documentation pages the
       plan will change, any intake question this skill resolved, and — last, by the
       dossier convention — the `### Footprint`, moved out of `## Notes` to end it
       (`${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → The footprint`). Append one `## Log` line —
       `- <date> — planned: <plan path> · cost: <output of bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" plan>`
       (or `cost: unavailable` and why, when it cannot run), naming any `/codeo:issue` number
       filed and any optional skill that was unavailable. Commit the dossier, staged by name, with
       the subject `docs(codeo): plan dossier for #<N>`, and push, as at step 4. A failed push is
       loud but not fatal (`${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Durability`).

       After a send-back from `/codeo:qc`, the first outcome stays as it was written: this pass's
       outcome goes beneath it as the next `### Round <n>` (the unheaded first is round 1), with
       the date as its first line, followed by `(send-back from qc.md round <n>)` naming the
       `qc.md` round it answers. The `### Footprint` moves to the end of that round, so the file
       still holds one (`${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → What a finished dossier looks like`).

11. **Report** the file path and a one-line summary, and suggest `/codeo:implement` to execute
    the plan once the engineer has committed it. If this plan tracks a GitHub issue but no branch
    exists yet, `/codeo:init #<number>` is the step that was skipped — it runs upstream of this
    one.

## Hand-off

`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md` is the protocol; this is this skill's half of it.

- **Reads** `.codeo/<N>/init.md` and `issue.md`, the pages under `$DOCS` (and the wiki pages,
  with the `wiki` module), the plans under `$PLANS`, the invariants document when one is
  configured, the codebase, the project's overlay sections for this skill, and every other
  in-flight workflow's footprint through `inflight.sh` and `overlap.sh`.
- **Writes** `$PLANS/YYYY-MM-DD-<slug>.md` or `$DOCS/<slug>.md`, and `.codeo/<N>/plan.md` — its
  questions, its `## Outcome`, and one `## Log` line per invocation — committed and pushed on
  every turn it writes it; and the leases on the exclusive resources its footprint names, through
  `intake.sh lease`. The plan doc itself stays unstaged — it is awaiting the engineer's approval;
  the dossier is not.
- **Never touches** the issue's text, the documentation pages other than the reference doc step 5
  chose (it names them; `/codeo:implement` writes them), code, the branch, the lease on
  `$ENV_RESOURCE`, or another skill's dossier file.
  An intake question this skill resolves is recorded in its own `## Outcome`, never struck from
  `init.md`.
- **May call** `/codeo:issue` for out-of-scope findings — a call, not a hand-off: control
  returns, and this skill records the number in its own outcome and log line
  (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → A call is not a hand-off`).
- **Hands off to** `/codeo:implement`, naming the committed plan file — and only once nothing in
  `.codeo/<N>/plan.md` is still open.
- **Spins out subagents** on the configured subagent model (`models.subagent`, sonnet when unset),
  passed explicitly, and prefers a direct `grep`/`Read` over an agent when the target is already
  known — see `${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Spinning out subagents`.

## Non-goals

- Doesn't author a GitHub issue itself — that's `/codeo:issue`'s purview. This skill consumes a
  filed issue as input, and may delegate an out-of-scope finding back to that skill, but it never
  writes the issue's text.
- Doesn't write or edit application code, or run its own build/test/review loop — that's
  `/codeo:implement`'s purview once this skill's doc is approved and committed.
- Only creates or modifies files under `$PLANS` and `$DOCS`, besides its own dossier and the
  draft files beside it.

## Tips

- State constraints up front (as plans do under "Global Constraints") rather than discovering
  them mid-draft.
- Name explicit options when a real choice is being made — "we considered X, Y, Z" — even if the
  answer seems obvious; that's what the ADR's Options Considered table is for.
- A plan that reads as a checklist of surprises for the implementer has failed; a plan that reads
  as a checklist of already-resolved decisions has succeeded.
