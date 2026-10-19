---
name: qc
description: Quality-check what /codeo:implement produced — the build, the configured test suites, the issue's acceptance criteria, the project's invariants, an independent code review and, when the project has a shared environment, what it actually runs — then report findings and route the engineer forward to a pull request or back to /codeo:implement or /codeo:plan. Trigger on "qc", "quality check", "run the checks", or right after /codeo:implement finishes a plan. Never fixes what it finds; reporting and routing are the whole job.
argument-hint: "[optional — defaults to the locked workflow]"
model: opus
---

Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

# Quality-checking `$ARGUMENTS`

This skill is the gate between building and merging. It runs the checks, judges the change against
what was actually asked for, and routes: forward to a pull request when everything holds, back to
`/codeo:implement` when the code is wrong, back to `/codeo:plan` when the plan was.

<!-- rule: qc-01 -->
**It never fixes what it finds.** A skill that both judges and repairs will quietly lower its bar
to avoid the work, and it would be doing `/codeo:implement`'s job besides. Report, route, and
stop — the engineer decides which way the change goes. No code, test, plan, documentation page or
other skill's dossier is edited here, however small the fix looks.

<!-- rule: qc-02 -->
Findings are scoped to the diff under review. Pre-existing debt this change happens to sit next to
is not a finding; say so once if it is load-bearing, and move on.

Where things go is read from the project's config, never assumed:

```bash
DOCS=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.docsDir // "docs"')
ENV_RESOURCE=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .environment.resource)
INVARIANTS=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .invariants)
WIKI=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.modules[]? | select(. == "wiki")')
SUBAGENT_MODEL=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.models.subagent // "sonnet"')
REVIEWER_MODEL=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.models.reviewer // "opus"')
```

`$DOCS`, `$SUBAGENT_MODEL` and `$REVIEWER_MODEL` always have a value. The reads behind
`$ENV_RESOURCE`, `$INVARIANTS` and `$WIKI` exit 1 with nothing printed when the key is absent, and
that is an answer, not a failure: no shared environment (nothing in this skill about the
environment applies, and `qc.md` says nothing about one), no invariants file (the reviewer works
from the acceptance criteria, the diff and the overlay's further rules, if any), no `wiki` module
(the documentation check covers the pages under `$DOCS`).

## Workflow

0. **Read `.codeo/active` before anything else.** The lock names the issue this workflow is
   bound to, which is what makes a bare invocation unambiguous here — the engineer named the issue
   when they ran `/codeo:init`. No lock means no workflow here: name `/codeo:init #<N>` as the
   step that was skipped — or, when the project's host workflow binds the lock in another checkout,
   say to run this step there — and stop. A lock whose `branch` disagrees with
   `git branch --show-current`, or an argument naming a different issue, is a hard stop too.
   `${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → The lock` has all three checks. `<N>` below is the
   lock's `issue`.

1. **Establish what is under review.** The lock gives the issue and the branch; the dossiers give
   the rest. Read the acceptance criteria in `.codeo/<N>/init.md`'s `## Outcome`, the task
   checklist of the plan that `.codeo/<N>/plan.md`'s `## Outcome` names, and
   `.codeo/<N>/implement.md`'s `## Outcome` — the criteria are the standard to judge against, the
   implementer's outcome is only what it claims to have done, and the latest round in it is the
   one under review. If `implement.md`'s outcome is still `_Pending_`, there is nothing to check
   yet: say so and stop. If there is no `init.md` or no plan, say so and stop rather than inventing
   a standard to judge against.

   This step's dossier is `.codeo/<N>/qc.md`. Every question it raises — an overlap at step 2, or
   anything later that would change the verdict — is a numbered question in that file, in the form
   `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → The shape of a file` gives and under the rules in
   `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Questions, and the cycle`. Re-invoked with questions
   answered, resume from the file: re-read it and take the answers rather than asking again.

2. **Scope the diff.** `<base>` below is the config's `baseBranch`
   (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .baseBranch`).
   Start the round from it: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/sync-main.sh" --abort-on-conflict`,
   because other workflows merge to `<base>` while this one runs, and a stale `origin/<base>` hides
   both their changes and any conflict with them. Exit 0 after a merge: the round continues on the
   merged tree, and its `also changed on <base>:` lines go into this round in `qc.md`, quoted, as
   files to re-check against this branch's work. Exit 2: the merge was aborted and the tree is as
   before; a conflict is a send-back to `/codeo:implement` naming each file the script printed —
   write the round, route, and stop, since `qc` resolves nothing. Exit 1 is a stop: report the one
   line it printed — tracked changes in the tree, or a merge that failed without a conflict — and
   stop.

   Then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlap.sh" <N>`. Each line it prints is an overlap not
   already raised in this issue's dossiers, and becomes a numbered question in `qc.md`: quote `#M`
   and the printed `what` verbatim, with the other issue's branch, assignee and step from
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/inflight.sh"`, and the options *proceed and coordinate* ·
   *sequence after #M* · *re-scope*. The step stops until it is answered: append this
   invocation's `## Log` line, ending ` · cost: ` with what
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" qc` prints, commit and push the dossier with the
   questions open, print the path and the numbers, and end the turn.

   Then `git diff origin/<base>...HEAD --stat`, then the diff itself. Every finding must point at a
   line this change touched. Checking is cheap; re-litigating the whole repository is not, and a
   report padded with pre-existing issues gets skimmed and ignored.

   Then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/scope.sh" origin/<base> HEAD` — the same rule the
   project's CI applies, so this pass and CI agree on which suites the change needs. Quote its
   output in `qc.md`: its `suite.<name>=` lines are the evidence for whatever steps 3 and 4 skip,
   and its `deploy=` line — printed only when an environment and at least one suite are
   configured — is read at step 9. With no suites configured it prints nothing at all and exits 0:
   say so; steps 3 and 4 have nothing to run, and with no `deploy=` line step 9 decides from
   `git diff origin/<base>...HEAD`, read directly, and says so. A non-zero exit whose line is
   `scope: cannot diff …` means a revision does not resolve here: `git fetch` once and run it
   again; still failing, run every configured suite at steps 3 and 4, and say so and why. Any other
   non-zero exit is a stop: report the line it printed, and stop.
   <!-- rule: qc-03 -->
   The script never overrules the diff you read: a suite it calls `false` for a change that
   plainly alters what that suite's code does is a finding against the script and the
   configuration it reads, and that suite runs anyway — say why.

3. **Build.** For each suite whose `suite.<name>` line is `true`, read its build command with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.suites[]? | select(.name == "<n>") | .build'`
   and run it from the project root; a suite with no `build` has nothing to run here. A suite that
   is `false` is skipped: say so in `qc.md`, quoting its line. With no suites configured, say there
   is no build command to run and record that as the build result — never invent one.
   <!-- rule: qc-04 -->
   A broken build ends the pass. Report it with the real output, write the round and route back to
   `/codeo:implement` at once, rather than running tests or judging criteria against something
   that does not build.

4. **Run the suites.** For each suite whose `suite.<name>` line is `true`, read its test command
   with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.suites[]? | select(.name == "<n>") | .test'`
   and whether it may run alongside others with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.suites[]? | select(.name == "<n>") | .parallel // false'`.
   Start the suites marked `parallel` together, in the background, before the others; then run the
   rest one at a time, in the order the config lists them. They share nothing, so running them in
   series only adds wall time. A suite with no `test` has nothing to run; a suite that is `false`
   is skipped like its build, quoting its line. Single tests through a suite's `filter` template
   are allowed when the diff is narrow, and `qc.md` says which ran and why; but a narrow run
   never replaces the full `test` of a suite whose code the diff alters in a way an acceptance
   criterion depends on — that suite runs whole. Quote real output — counts, the names of
   failures — never a paraphrase. Each failure is a finding, classified at step 8.

   With no suites configured, say so, run nothing, and judge each acceptance criterion by reading
   the diff at step 5. A criterion only the shared environment can prove is not run here: with
   `$ENV_RESOURCE` set, step 9 settles it.

5. **Check each acceptance criterion, one at a time.**
   <!-- rule: qc-05 -->
   A criterion is met, not met, or untestable as written; say which for every one, and name the
   test or the line that settles it. "All criteria met" without that mapping is the failure mode
   this step exists to prevent. A criterion only the shared environment can prove is left to
   step 9, which settles it with the command it ran and that command's output.

6. **Check the diff against the project's rules, its footprint and its documentation.**
   <!-- point: qc/invariants-extra -->
   Fetch the project's further rules with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" qc invariants-extra`: on exit 0, the printed
   text is rules the invariants file does not state — judge every line the diff touched against
   them, and step 7 hands the same text to the reviewer; on exit 3, there are none, and the
   invariants file (`$INVARIANTS`, when set) and the criteria are the whole standard, which step
   7's reviewer judges; on exit 1, 2 or 4, report the one `codeo:` line it printed to the engineer
   and carry on without them. A breach is a finding, classified at step 8. The `$INVARIANTS` file's
   text is judged by step 7's reviewer, not in a separate invariants check here; this step judges
   only the overlay's further rules itself.

   Then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlap.sh" --outside <N>`. Every path it prints is a
   finding — *the branch changed a file outside its footprint* — classified at step 8 like any
   other, and not blocking by rule: the footprint is what other workflows were told this one would
   touch, so the engineer should hear about the gap, but the change may still be right.

   **Then the documentation.** For every behaviour the diff changes — an interface, a flow, a
   state, a configuration key, a screen, a deployment step — find the page under `$DOCS` (and, with
   `$WIKI` set, the wiki page) that describes it, and check that it now says what the code does. A
   page the plan named but the diff left untouched, a page that still describes the old behaviour,
   a diagram that no longer matches the flow, and a changed behaviour no page covers are all
   findings; the last is the plan's when the plan named no page for it. A page that talks about the
   issue instead of the system — "now", "no longer", an issue number — is a finding too, because it
   is read long after anyone remembers the issue. When the plan says the change moves no page,
   check that claim rather than taking it.
   <!-- point: qc/wiki-rules -->
   Fetch the project's documentation rules with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" qc wiki-rules`: on exit 0, check every page and
   diagram the diff touches or should have touched against the printed text — how its pages are
   written, linked and indexed, and how its diagrams are checked, a render step included; on exit
   3, the checks are only the conventions the existing pages under `$DOCS` already follow; on exit
   1, 2 or 4, report the one `codeo:` line and use those conventions. A diagram the rules say to
   render that cannot be rendered here is said so in `qc.md`; never pass a diagram unseen.

7. **Get an independent code review.** Invoke `superpowers:requesting-code-review` via the Skill
   tool and dispatch its reviewer with `model: "$REVIEWER_MODEL"` — the config's `models.reviewer`,
   opus when unset — and a `description` starting `QC review:`. It is the one dispatch in a codeo
   workflow allowed off the subagent model, and the plugin's hook denies a reviewer on any other
   model or without that description (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Spinning out subagents`).
   Every other dispatch this skill makes passes `model: "$SUBAGENT_MODEL"`.
   <!-- rule: qc-06 -->
   The reviewer judges what was *asked for*, not what was intended, so it gets the acceptance
   criteria and never the implementer's account of the change. Fill its template that way:
   - `{PLAN_OR_REQUIREMENTS}` is the acceptance criteria from `init.md` verbatim, plus the text of
     the `$INVARIANTS` file verbatim when one is configured, plus the further rules step 6's
     overlay printed, if any. With neither, it is the criteria alone, and the reviewer works from
     them and the diff.
   - `{BASE_SHA}` is `git merge-base origin/<base> HEAD`; `{HEAD_SHA}` is `HEAD`.
   - `{DESCRIPTION}` is one line naming the issue — never the plan, never `implement.md`, never any
     other dossier. A reviewer handed the implementer's account of the change grades the account.

   Tell it to find defects, and documentation that says something untrue, not matters of style.
   This is an independent opinion on the same diff, not a re-run of steps 3-6. The review skill's
   *Act on feedback* section does not apply here: its findings go to step 8 for classification,
   nothing is fixed, and a finding the engineer would reject is recorded with the evidence, not
   argued.

   Two lessons about how much one round says, guidance rather than new rules: report every defect
   this pass can find in this round — the reviewer's and your own together — rather than one per
   round, because each further round costs a whole pass; and open no further round for
   non-blocking polish — a non-blocking finding is recorded and routed, and on its own it never
   sends the change back.

8. **Classify every finding before reporting it.**
   <!-- rule: qc-07 -->
   Every finding gets two answers, both required, and a cause found by debugging stops at Phase 1:
   - **Blocking or not.** Blocking means the change should not merge as it stands.
   - **Whose it is.** A finding is `/codeo:implement`'s when the code doesn't do what the plan
     says; it is `/codeo:plan`'s when the code does what the plan says and the plan was wrong. That
     distinction is the routing decision, so make it deliberately rather than defaulting everything
     to the implementer.

   Write the first answer in those words: every finding in `qc.md` says `blocking` or
   `non-blocking`, so a reader — or the dossier checker — can tell a round that must not go to
   `/codeo:close` (`${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → What a finished dossier looks like`).

   For a failing test or a finding whose cause is not obvious from the diff, invoke
   `superpowers:systematic-debugging` via the Skill tool and run *Phase 1: Root Cause
   Investigation* only. The root cause is what decides whose finding it is. **Stop at the end of
   Phase 1** — Phases 2-4 form a hypothesis and implement a fix, and fixing is the one thing this
   skill never does. Record the cause in the finding, not a proposed patch.

9. **Environment evidence — only when `$ENV_RESOURCE` is set.** With it empty there is no shared
   environment: skip this step, and `qc.md` says nothing about one. With it set, this step settles
   the criteria step 5 left to the environment and writes what it found as a `#### Environment`
   block in this round of `qc.md`: the deployed revision it read, the `deployed` hook's rows, the
   ancestor and scope checks of each row that is not an orphan, the orphans, and each environment
   criterion's result with the command it ran and its output. It runs when `implement.md` records
   a `Deployed revision:` or a criterion needs the environment — a deployed branch is checked for
   a stale, stopped or orphaned workload even when every criterion was settled by a test. When
   neither holds, the block is one line saying so, and nothing below runs.

   **Stopping here.** A stop in this step keeps the pass so far: write it under
   `## Where this stands` and `## Notes` in `qc.md`, append this invocation's `## Log` line as at
   step 11, commit the file, staged by name, with the subject
   `docs(codeo): qc dossier for #<N> — stopped at step 9`, and push, then stop. A push that fails because origin
   is down is reported and the commit kept (`${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Durability`:
   a failed push is loud but not fatal).

   **This skill never deploys.** Only `/codeo:implement` deploys, builds for the environment or
   takes the lease. Here the lease is only checked, and re-taken by its holder when this checkout
   needs the activation; anything that would change what the environment runs — the take and the
   deploy included — is a send-back to `/codeo:implement`.

   <!-- rule: qc-13 -->
   Evidence the environment cannot give yet is never a pass: when this issue does not hold the
   lease, or the `deployed` hook could not answer — the identity it needs is missing in this
   checkout, say — each criterion that needs the environment is *not yet checkable*, and the block
   says why. Those criteria are not themselves the send-back: when the lease is not held, what goes
   back to `/codeo:implement` is the take and the deploy it still owes. When the lease is held and
   the `deployed` hook still cannot answer, the verdict is not clear: the round records the failure
   as a blocking finding owned by neither skill, raised as a numbered question at step 10. A workload nobody declares
   is an orphan: a non-blocking finding, never a send-back.

   **The evidence hook comes first**, before any lease is looked at:

   ```bash
   deployed=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .environment.hooks.deployed)
   ```

   Absent or empty: say plainly that no evidence hook exists, and mark every criterion that needs
   the environment *untestable here — no evidence hook*. That result is recorded in the round; it
   is not a question, and it does not stop the verdict. There is no lease check and no send-back
   for evidence that can never be read; nothing below runs.

   **The revision.** Read the most recent `Deployed revision: <x>` in `.codeo/<N>/implement.md` —
   the one under `## Where this stands` when there is one, else the last in `## Outcome` — and
   quote it in the block, with any `lease <resource> taken with override: <reason>` on that file's
   `## Log` lines. With none, while step 2's `scope.sh origin/<base> HEAD` printed `deploy=true`
   (or, with no `deploy=` line, the diff plainly alters what the environment runs) and a criterion
   needs the environment, this branch was never put there: that is a send-back to
   `/codeo:implement` naming the missing deploy. With none, while `scope.sh` printed
   `deploy=false` (or the diff shows no environment change) and a criterion still needs the
   environment, `/codeo:implement` owes nothing by its own rule — it takes the lease only for a
   task that needs it — so this is a plan gap: an environment criterion with no task that leases
   the environment. Route it back to `/codeo:plan`, naming the gap — write the round and route —
   or, when the engineer must settle what the criterion meant, raise it as a numbered question at
   step 10 instead; either way, nothing below runs.

   **A later round** — after a send-back or a review round — starts from the revision the previous
   round's block recorded: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/scope.sh" <that revision> HEAD`.
   A previous round that recorded no revision — its criteria were not yet checkable, or it sent
   back a missing deploy — gives nothing to start from: run the step as in a first round.
   `deploy=false` means no environment work since: the block says
   "environment evidence from round <n> stands: <revision>", quotes the line, and nothing below
   runs. `deploy=true` means the step runs as in a first round. No `deploy=` line means decide from
   `git diff <that revision>...HEAD`, read directly, and say so. A `scope: cannot diff` line means
   `git fetch` once and run it again; still failing, run the step as in a first round, and say
   why. Any other non-zero exit is a stop: report the line it printed, and stop as under
   *Stopping here*.

   **The lease.** `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease check "$ENV_RESOURCE" <N>`.
   - **Exit 0**: this issue holds it — `/codeo:implement` took it and keeps it until this skill's
     clear verdict — so go on to the rows. Nothing is re-taken up front.
   - **Exit 1**: this issue does not hold it. Quote the check's line, which names the holder or
     says it is not held; each criterion that needs the environment is *not yet checkable*, and the
     take and the deploy this branch still owes are a send-back to `/codeo:implement`. Write the
     round with the line `Lease not held: <the check's line>`, route, and run nothing below. The
     send-back asks for the take and a redeploy whatever `scope.sh` prints since the recorded
     revision: while the lease was not held, another issue may have put something else there.
     Record no wait: `/codeo:implement`'s own take records one if it is queued. (When
     `/codeo:implement` owes nothing — no `Deployed revision:` and no environment change — *The
     revision* above has already routed the plan gap to `/codeo:plan`.)
   - **Exit 2**: origin cannot be asked — report its line, and stop as under *Stopping here*.

   **The rows.** Run the evidence hook from the project root as
   `CODEO_ISSUE=<N> CODEO_RESOURCE="$ENV_RESOURCE" bash -c "$deployed"` and read its exit status.
   Exit 0: one line per workload, `name<TAB>revision<TAB>state<TAB>declared`; quote them in the
   block. Non-zero, with output saying the activation or identity it needs is missing in this
   checkout: re-take the lease once as its holder,
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease take "$ENV_RESOURCE" <N> "qc"` — a
   holder's re-take runs the activation hooks again here and keeps the lease whatever they answer,
   and, taken without an override, it drops a stale `override:` line the lease still records —
   then re-run the `deployed` hook once. Still non-zero, or non-zero for any other reason: the
   criteria are *not yet checkable*, never a pass — quote what it printed.

   That re-take's refusals are handled apart, and none is ever retried with an override, since
   nothing this skill does changes what the lease guards:
   - **A hook** — `intake: <resource> refused — the <name> hook exited <rc>`: report the hook and
     what it printed, and record no wait. The lease stays with this issue, unchanged, and the
     criteria are *not yet checkable*. A failing hook is the project's to fix.
   - **A stale base** — `this branch does not contain origin/<base>`: the base branch moved during
     this round, so the build, the suites and the review judged a tree that a merge would replace.
     Run this pass again from step 2, sync included, rather than only taking again — once only: a
     second such refusal is a stop, as under *Stopping here*. The restarted attempt is the same
     round, and the superseded attempt's output is not quoted.
   - **Anything else**: report the one line it printed, and stop as under *Stopping here*.

   <!-- point: qc/environment-evidence -->
   Fetch the project's evidence notes with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" qc environment-evidence`: on exit 0, follow
   the printed text — a diagnostic to run before reading a failing row as stale, the remedy to name
   for an orphan, how to read a state — as it adds to the rules below; on exit 3, the evidence is
   the hook's output and nothing more; on exit 1, 2 or 4, report the one `codeo:` line and carry
   on without it.

   A row whose `declared` is `no` is an orphan: the block records it, with the overlay's remedy
   when it names one, as a non-blocking finding routed to `/codeo:triage`, and it is left out of
   every check below — its revision is usually an abandoned branch's, which is no ancestor of
   `HEAD`. A row with no fourth column is unknown: it is checked like a declared one, and the block
   makes no orphan statement about it. Every other row must be `running`, and each distinct
   revision among them must pass `git merge-base --is-ancestor <revision> HEAD` and
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/scope.sh" <revision> HEAD` printing `deploy=false` (no
   `deploy=` line: decide from `git diff <revision>...HEAD`, read directly, and say so; a
   `scope: cannot diff` line: `git fetch` once and run it again, and still failing, the revision
   fails; any other non-zero exit: report its line, and stop as under *Stopping here*). The block
   records each result against its row.

   A `stopped` row: read the start step,

   ```bash
   start=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .environment.hooks.start)
   ```

   run it once as `CODEO_ISSUE=<N> CODEO_RESOURCE="$ENV_RESOURCE" bash -c "$start"` (absent, say
   so), then re-run the `deployed` hook once and read its rows as above. A row still not `running`
   then is read like a `rolling` one. A `rolling` row, or a revision that fails either check, means
   the environment is not running what is being cleared: that is a send-back to `/codeo:implement`
   to redeploy, never a build or a deploy here.

   **The criteria.** With every row that is not an orphan `running` a revision that passes both
   checks, run each criterion that needs the environment, and record it met or not met with the
   command and its output — evidence from this round, never a claim carried over from another.

10. **Write the dossier, and stop if anything must be asked.** `.codeo/<N>/qc.md` carries the
    commands this pass ran and their real output, the criterion-by-criterion result, the
    documentation check, and every finding with both its answers from step 8 — under `## Notes`
    and `## Where this stands` until step 11 writes them into the round.
    <!-- rule: qc-08 -->
    A question comes before the verdict, never after it: anything the engineer must settle before
    this pass can reach one — an acceptance criterion untestable as written, a finding whose
    severity turns on intent the diff does not show — is a numbered question in `qc.md`, and no
    verdict is written while it is open. A verdict issued over an open question is a guess wearing
    a verdict's clothes. With a question open, append this invocation's `## Log` line as at
    step 11, commit the file, staged by name, with the subject
    `docs(codeo): qc dossier for #<N> — Q<a>-Q<b> raised`, push, print the path and the open
    numbers, and end the turn (`${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → The gate`).

    An earlier step that says *write the round, route, and stop* — a conflict at step 2, a broken
    build at step 3, a send-back at step 9 — comes here with what the pass found so far, and runs
    steps 11 and 12 on it.

11. **Write `qc.md`'s `## Outcome`.** Append a dated `### Round <n> — <YYYY-MM-DD>` beneath the
    last one rather than overwriting it — how many rounds a change took is worth more to a later
    reader than a tidy final verdict. The round records the commands run and their real output, the
    criterion-by-criterion result with the test or line that settles each, the documentation check,
    the `#### Environment` block when step 9 ran, every finding with its classification, the number
    of any issue `/codeo:issue` filed for this pass, and the routing decision.
    The criterion-by-criterion result is a table with one row per acceptance criterion in
    `init.md`. Each row's verdict cell begins with `met`, `not met`, `untestable` or
    `not yet checkable` — a prefix, after which any text may follow in the cell, and further
    columns may carry more — so step 9's *untestable here — no evidence hook* stands as written.
    A criterion step 9 settles names the environment in its settled-by column (`environment`),
    which points at this round's `#### Environment` block for the command and its output.
    A round that stopped early — a conflict at step 2, a broken build at step 3, a send-back at
    step 9 — still has a row for every criterion: those the pass did not reach read
    `not yet checkable — pass stopped at step <k>`.
    <!-- rule: qc-09 -->
    The decision is a bold span, `**Verdict: …**` or `**Routing: …**`, with the label inside the
    bold, and only the last such span of the round counts. The project's `qc-verdict` check
    (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/qc-verdict.sh" <base> <head>`) reads the latest
    `### Round <n>` under `## Outcome` and judges its last span alone, so an unbolded decision, a
    label outside the bold (`**Verdict:** clear`), or a bold recap written after the decision fails
    the pull request closed or decides it wrongly. Write a clear verdict exactly as

    <!-- example: clear -->
    **Verdict: clear — forward to `/codeo:close`.**

    and a send-back as ``**Verdict: back to `/codeo:implement`.**`` or
    ``**Verdict: back to `/codeo:plan`.**``, and put nothing bold labelled Verdict or Routing after
    it in the round: the reviewer's verdict, or an earlier round's, is quoted in plain text.

    Append one `## Log` line, ending ` · cost: ` with what
    `bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" qc` prints, then commit the dossier, staged by
    name, and push, with the subject `docs(codeo): qc dossier for #<N>` (`— round <n>` for a later
    round; `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Durability`).

12. **Report and route.**
    <!-- rule: qc-10 -->
    A verdict is a completion claim, so `superpowers:verification-before-completion` applies to it:
    every statement in it — the build passed, N tests passed, a criterion is met — traces to
    command output from *this* pass, quoted in `qc.md`, never to an earlier round, to
    `implement.md` or to memory. The one carry-over step 9 allows, environment evidence from an
    earlier round, stands only on the `deploy=false` this pass printed.

    The routing decision is the deliverable: a list of findings with no verdict leaves the engineer
    doing the classification this skill exists to do, and the bar does not move because a round is
    tiring. State the verdict plainly, and exactly one of:
    - **Clear** — no blocking finding. With `$ENV_RESOURCE` set, once the round and its `## Log`
      line are written, run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease check "$ENV_RESOURCE" <N>`.
      Exit 0, this issue holds it: run
      `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease release "$ENV_RESOURCE" <N>`, append one
      line to the round — `Environment released at the clear verdict: <the script's output>` — and
      commit and push the dossier once, as at step 11. Exit 1, it is not held: there is nothing to
      release, and the report says so, quoting the check's line. Exit 2, origin cannot be asked:
      report its line, and treat it as a release that failed.
      <!-- rule: qc-11 -->
      A release that fails is reported and never retried in a loop: append
      `Environment NOT released: <the script's output>` to the round instead (the check's line,
      for exit 2), and still hand off: `/codeo:close` releases everything this issue holds at
      every exit.

      Then hand off to `/codeo:close`, which opens the pull request.
    - **Back to `/codeo:implement`** — name the findings and what specifically must change.
    - **Back to `/codeo:plan`** — name what the plan got wrong and why the code cannot fix it.

    A verdict that is not clear does not release the lease: the environment stays with this issue,
    which may still owe it a redeploy. A send-back is a hand-off: write the round, name what must
    change, route it, and stop (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → A send-back`).

    <!-- rule: qc-12 -->
    When a send-back returns here, re-run the whole pass from step 0 and open a new round in
    `qc.md`. A partial re-check on a changed diff is how a regression ships.

## Hand-off

`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md` is the protocol; this is this skill's half of it.

- **Reads** the diff, the plan file, every other skill's dossier file, the pages under `$DOCS` (and
  the wiki pages, with the `wiki` module), the project's overlay sections for this skill, every
  other in-flight workflow's footprint through `inflight.sh` and `overlap.sh`, and the output of
  the suites it runs.
- **Writes** `.codeo/<N>/qc.md` — its questions, its `## Outcome` rounds (with the
  `#### Environment` block when the project has a shared environment), and one `## Log` line per
  invocation — committed and pushed on every turn it writes it. Nothing else.
- **Never touches** code, tests, the plan's text, the issue's text, a documentation page, or
  another skill's dossier file. A test it wishes existed, or a page it wishes said something else,
  is a finding, not something to go and write.
- **Checks the lease** on `$ENV_RESOURCE`, when one is configured, re-takes it only as its holder
  (step 9), and records no wait on it. It **releases** it at a clear verdict and only then, through
  `intake.sh lease release "$ENV_RESOURCE" <N>` when this issue holds it, with the script's output
  appended to the round.
- **Hands off to** exactly one of three routes: forward to `/codeo:close`, back to
  `/codeo:implement`, or back to `/codeo:plan` — and only once nothing in `.codeo/<N>/qc.md` is
  still open. A send-back is still a hand-off: it names the findings and stops; it does not start
  the fixing.
- **May call** `/codeo:issue` for a real problem that is out of scope for this change — a call, not
  a hand-off: control returns, and this skill records the number in its own `## Outcome` and
  `## Log` line (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → A call is not a hand-off`).
- **Spins out subagents** on the configured subagent model (`$SUBAGENT_MODEL`: `models.subagent`,
  sonnet when unset), passed explicitly on every dispatch — except step 7's reviewer, on
  `$REVIEWER_MODEL` (`models.reviewer`, opus when unset) with a `description` starting
  `QC review:` — and prefers a direct `grep`/`Read` over an agent when the target is already known
  — see `${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Spinning out subagents`.

## Non-goals

- Doesn't fix anything it finds — not the code, not a test, not a typo. That's
  `/codeo:implement`'s purview, and fixing while judging corrupts the judgment.
- Doesn't edit the plan or re-scope the work — that's `/codeo:plan`'s purview.
- Doesn't open, merge or approve a pull request — opening one on a clear verdict is
  `/codeo:close`'s. It pushes its own dossier commits and nothing else — the merge commit step 2's
  sync made rides the same push.
- Doesn't deploy, build for the environment, or take the lease to change what the environment
  runs. It reads what is deployed and sends back what is stale.
- Doesn't invent acceptance criteria. If `init.md` has none to judge against, that is itself the
  finding, and it routes back to whoever owed them.
