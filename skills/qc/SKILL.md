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

`$DOCS`, `$SUBAGENT_MODEL` and `$REVIEWER_MODEL` always have a value. `$ENV_RESOURCE`,
`$INVARIANTS` and `$WIKI` exit 1 with nothing printed when the key is absent, and that is an
answer, not a failure: no shared environment (nothing in this skill about the environment applies,
and `qc.md` says nothing about one), no invariants file (the reviewer works from the acceptance
criteria and the diff alone), no `wiki` module (the documentation check covers the pages under
`$DOCS`).

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
   *sequence after #M* · *re-scope*. The step stops until it is answered: commit and push the
   dossier with the questions open, print the path and the numbers, and end the turn.

   Then `git diff origin/<base>...HEAD --stat`, then the diff itself. Every finding must point at a
   line this change touched. Checking is cheap; re-litigating the whole repository is not, and a
   report padded with pre-existing issues gets skimmed and ignored.

   Then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/scope.sh" origin/<base> HEAD` — the same rule the
   project's CI applies, so this pass and CI agree on which suites the change needs. Quote its
   output in `qc.md`: its `suite.<name>=` lines are the evidence for whatever steps 3 and 4 skip,
   and its `deploy=` line, printed only when an environment is configured, is read at step 9.
   With no suites configured it prints nothing and exits 0: say so, and steps 3 and 4 have nothing
   to run. A non-zero exit, with its `scope:` line, means a revision does not resolve here:
   `git fetch` once and run it again; still failing, run every configured suite at steps 3 and 4,
   and say so and why.
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
   is skipped like its build, quoting its line. A narrower run — part of a suite, or single tests
   through its `filter` template — is allowed when the diff is narrow, and `qc.md` says which ran
   and why. Quote real output — counts, the names of failures — never a paraphrase. Each failure is
   a finding, classified at step 8.

   With no suites configured, say so, run nothing, and judge each acceptance criterion by reading
   the diff at step 5. A criterion only the shared environment can prove is not run here: with
   `$ENV_RESOURCE` set, step 9 settles it.

<!-- steps 5-12, hand-off and non-goals are added by the next tasks -->
