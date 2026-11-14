# Issue #69 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/69 |
| Branch | `feat/fix-closing-blocks-that-name` |
| Updated | 2026-11-14 |

## Where this stands

Round 2 is written: no blocking finding; seven non-blocking findings (G1-G7) are recorded and routed. Nothing is open. Next: `/codeo:close`.

## Questions

None.

## Outcome

### Round 1 — 2026-11-14

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`. `overlap.sh 69` printed nothing. Diff `origin/main...HEAD`: 16 files, 872 insertions, 27 deletions. `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/69/implement.md
  .codeo/69/init.md
  .codeo/69/issue.md
  .codeo/69/plan.md
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line: no environment is configured, so step 9 does not apply and this round says nothing about one.

**Build.** The `shell` suite's `build` is `true`; it exited 0.

**Suites.** `bash tests/run.sh` (the `shell` suite's `test`, run whole): `all cases passed`, exit 0, no FAIL lines.

**Criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Close, lock kept: names `/codeo:close` first, no checkout removal | met | `skills/close/SKILL.md` step 17 `**Closing block — lock kept:**`; `tests/closing-exits.test.sh` case `close-lock-kept` |
| 2 | Interrupted stash names `/codeo:close --stash`; `/codeo:init #<N>` only after a completed stash, Ready repair first | met | `skills/close/SKILL.md` Stash section, `stash interrupted` and `stash completed`; cases `stash-interrupted`, `stash-completed` |
| 3 | After `lock: TODO` the block names a recovery, not `/codeo:plan` | met — the block does (see F1 for the reference table) | `skills/init/SKILL.md` step 11 `**Closing block — no lock:**`; case `init-no-lock` |
| 4 | `/codeo:issue`: not Ready names `/codeo:triage` first; no board or Ready names `/codeo:init #<N>` | met | `skills/issue/SKILL.md` step 8, three labelled paragraphs; cases `issue-ready`, `issue-not-ready`, `issue-unreadable` |
| 5 | A test fails if a block goes back to the command that cannot run | met | `tests/closing-exits.test.sh`; the reviewer mutated copies (clean-up before `/codeo:close`, `/codeo:init` in the interrupted stash, `/codeo:plan` in the no-lock block, init-only in the not-Ready block, base-commit reverts of close and init): each exited 1, the unmutated copy 0 |
| 6 | Host-run plan task: runs without editing or names its shell; `/codeo:plan` says how it decides | met | `skills/plan/SKILL.md` step 8 `**Mark the tasks the engineer runs on their own host.**`; pinned in `tests/plan-skill.test.sh` |
| 7 | `CHANGELOG.md` #67 entry corrected; `.devcontainer/README.md` says all of `~/.claude` is lost | met | `CHANGELOG.md` diff (`gh` and Claude Code exempted, coreutils "among them"); `.devcontainer/README.md` diff |
| 8 | `## Unreleased` entry for this change; `bash tests/run.sh` passes | met | `CHANGELOG.md` #69 bullet; suite output above |

**Footprint.** `overlap.sh --outside 69` printed `tests/close-skill.test.sh` (F6).

**Documentation.** `docs/handoff.md`, `docs/skills.md`, `.devcontainer/README.md` and `CHANGELOG.md` all say what the skills now do, apart from F1. No page talks about the issue; the issue number appears only in `CHANGELOG.md`, whose entries cite it by convention. The plan's claim that no wiki page moves holds: no `wiki` module is configured.

**Independent review** (opus, given the criteria and the diff only). Its assessment, quoted: "With fixes. The behaviour and the tests meet every acceptance criterion, but the new `init — no lock` row in `docs/handoff.md` names `/codeo:plan`, contradicting criterion 3 and the init skill." It also checked the commands against the scripts: `lock.sh take local` (`scripts/lock.sh`), `config.sh get .board` exiting 1 with no board, and `board.sh status` printing the name, `unset`, `none` or `unavailable`.

**Findings.**

- **F1 — blocking, `/codeo:plan`'s.** `docs/handoff.md:384`: the `init — no lock` row's first step reads "the recovery, then the default (`/codeo:plan`)". That is the reference every skill cites for the closing block, and it contradicts criterion 3 and `skills/init/SKILL.md:333` ("The plan is named only once the lock was taken"). A reader of the table would put `/codeo:plan` back into the no-lock block, and `case_rule` checks only that the row label exists, so no test sees it. Cause: the plan's Task 1 Step 3 dictated this cell ("the recovery, then the default"), and the code did what it said; the plan was wrong. The fix is one cell, for example "the fix the `lock: TODO` line names, then `lock.sh take local` again".
- **F2 — non-blocking, `/codeo:plan`'s.** `skills/plan/SKILL.md:170` says a host task "starts with `Runs on:`" and `:204` says a lease task "starts with `Needs lease:`", while `:179-181` lets a task carry both "in either order". Both cannot start the task. Harmless today, since `/codeo:implement` finds `Needs lease:` anywhere in a task; wording only ("carries" for "starts with").
- **F3 — non-blocking, `/codeo:plan`'s.** `skills/plan/SKILL.md:176-178`: "A `host: local` lock needs no question, because the session's own shell is the engineer's" fails where Claude Code runs commands in Git Bash on native Windows while the engineer types in PowerShell, which is #67's failure shape.
- **F4 — non-blocking, `/codeo:plan`'s.** `skills/plan/SKILL.md:173-174`: "anything longer becomes a script in the repository, run as one command" does not say the script's interpreter must exist on the engineer's host; `bash scripts/x.sh` is not neutral on a PowerShell-only host.
- **F5 — non-blocking, `/codeo:implement`'s.** `tests/closing-exits.test.sh` reads the labelled paragraphs but not that the old unconditional sentences are gone: restoring init's old "Either way, end with the closing block … `/codeo:plan`" beside the new paragraph would pass. A plain revert is caught, and `tests/close-skill.test.sh` covers step 17.
- **F6 — non-blocking, `/codeo:plan`'s.** `tests/close-skill.test.sh` changed but is not in the plan's footprint (`implement.md` records the one added case). The footprint is what other workflows were told; no in-flight workflow touches it.

Reviewer items declined as out of scope: how `/codeo:implement` treats `Runs on:` tasks, the unchanged closing blocks of other close stops, a failed `assignee-remove` at a stash, and cmd.exe quoting.

Pre-existing: none found load-bearing.

**Verdict: back to `/codeo:plan`.**

### Round 2 — 2026-11-14

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`. `overlap.sh 69` printed nothing. Diff `origin/main...HEAD`: 17 files, 1097 insertions, 28 deletions. `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/69/implement.md
  .codeo/69/init.md
  .codeo/69/issue.md
  .codeo/69/plan.md
  .codeo/69/qc.md
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line: no environment is configured, so step 9 does not apply and this round says nothing about one.

**Build.** The `shell` suite's `build` is `true`; it exited 0.

**Suites.** `bash tests/run.sh` (the `shell` suite's `test`, run whole): `all cases passed`, exit 0, no FAIL lines.

**Criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Close, lock kept: names `/codeo:close` first, no checkout removal | met | `skills/close/SKILL.md` step 17 `**Closing block — lock kept:**`; `tests/closing-exits.test.sh` case `close-lock-kept` |
| 2 | Interrupted stash names `/codeo:close --stash`; `/codeo:init #<N>` only after a completed stash, Ready repair first | met | `skills/close/SKILL.md` Stash section, `stash interrupted` and `stash completed`; cases `stash-interrupted`, `stash-completed` |
| 3 | After `lock: TODO` the block names a recovery, not `/codeo:plan` | met | `skills/init/SKILL.md` step 11 `**Closing block — no lock:**`; case `init-no-lock`; `docs/handoff.md:384` no longer names `/codeo:plan`, pinned by `case_rule` |
| 4 | `/codeo:issue`: not Ready names `/codeo:triage` first; no board or Ready names `/codeo:init #<N>` | met | `skills/issue/SKILL.md` step 8, three labelled paragraphs; cases `issue-ready`, `issue-not-ready`, `issue-unreadable` |
| 5 | A test fails if a block goes back to the command that cannot run | met | `tests/closing-exits.test.sh`; the reviewer mutated copies (`/codeo:triage` first in lock-kept, `/codeo:init` in the interrupted stash, `/codeo:plan` in the no-lock block, init before triage, init alone in the not-Ready block): each failed. See G2 for what a partial revert can slip past |
| 6 | Host-run plan task: runs without editing or names its shell; `/codeo:plan` says how it decides | met | `skills/plan/SKILL.md` step 8 `**Mark the tasks the engineer runs on their own host.**`; pinned in `tests/plan-skill.test.sh` |
| 7 | `CHANGELOG.md` #67 entry corrected; `.devcontainer/README.md` says all of `~/.claude` is lost | met | `CHANGELOG.md` and `.devcontainer/README.md` diffs, checked against the Dockerfile by the reviewer (`gh` from cli.github.com, Claude Code from claude.ai/install.sh, `~/.claude` not a volume) |
| 8 | `## Unreleased` entry for this change; `bash tests/run.sh` passes | met | `CHANGELOG.md` #69 bullet; suite output above |

**Footprint.** `overlap.sh --outside 69` printed nothing: round 1's F6 is fixed, since `tests/close-skill.test.sh` is now in the plan's footprint.

**Round 1 recap.** F1 (blocking in round 1) — fixed by 77df859: the `init — no lock` row names `lock.sh take local`, not `/codeo:plan`, and `case_rule` pins it. F5 — fixed by 77df859 (the step-11 guard in `case_init_no_lock`). F2, F3, F4 — fixed by eab7dc4. F6 — fixed in the plan's footprint.

**Documentation.** `docs/handoff.md`, `docs/skills.md`, `.devcontainer/README.md` and `CHANGELOG.md` say what the skills now do, apart from the non-blocking G3, G4 and G7 below. No page talks about the issue; the issue number appears only in `CHANGELOG.md`, by its convention. No `wiki` module is configured.

**Independent review** (opus, given the criteria and the diff only; it did not read the dossiers). Its assessment, quoted: "With fixes. Every acceptance criterion is met and the suite passes, but the abandon exit still has no closing block and borrows the stash blocks by analogy, and the new test misses an old sentence put back outside the labelled paragraphs. Both are small to fix." It rated no finding Critical. I read the abandon section at `skills/close/SKILL.md:634-659` and agree with the facts of G1; I class it by scope, below.

**Findings.** None is blocking.

- **G1 — non-blocking, `/codeo:plan`'s (out of the issue's four exits; for `/codeo:triage`).** `skills/close/SKILL.md:646-659`, the abandon exit: it keeps the lock when the branch deletion fails, says only that running `/codeo:close` again finishes the abandon, and names no closing block. It says it does "everything a stash does", so a reader can end with `/codeo:init #<N>`, which refuses an abandoned workflow, or with `/codeo:close --stash`, which would turn the abandon into a stash. `docs/handoff.md:351-353` still lists close's exits as "waiting on a merge, sent back, finished or stashed", and its exceptions table has no abandon row. The issue names four exits and abandon is not one of them, and the fault predates this change, so it is not this change's to fix; the fix is two labelled paragraphs, a table row and two test cases.
- **G2 — non-blocking, `/codeo:implement`'s.** `tests/closing-exits.test.sh:79-105`: old sentences put back beside the new labelled paragraphs pass: the stash line "Report that `/codeo:init #<N>` resumes it", and step 17's unconditional "End with the closing block: … the first step `/codeo:triage`, then the host clean-up". Init has such a guard (round 2's step-11 check); close and stash do not. `tests/close-skill.test.sh:197` partly covers step 17.
- **G3 — non-blocking, `/codeo:plan`'s.** `docs/handoff.md:384`: the `init — no lock` row says "then `lock.sh take local` again" unconditionally, but with a host workflow the recovery is what the host's text names (`skills/init/SKILL.md:331-335`), and on `host: container` `lock.sh` can print a `lock: TODO` line after taking the lock (`scripts/lock.sh:144`).
- **G4 — non-blocking, `/codeo:plan`'s.** `docs/handoff.md:378-385`: no row for `/codeo:issue`'s "Status unreadable" exit, whose first step (the fix its line names) is not the default.
- **G5 — non-blocking, `/codeo:plan`'s.** `skills/plan/SKILL.md:168-185`: the paragraph defines a host task as one run "outside this session's checkout" and then includes `host: local` on Windows, the same checkout; and it says to label `Shell: <name>` and then ask, where the working order is ask, then label. Round 2's wording left the ragged wrapping and the overlap `implement.md` records.
- **G6 — non-blocking, `/codeo:plan`'s.** `skills/plan/SKILL.md:171-172`: the "neutral" list omits single-quoted arguments, globs, `~` and `./script`, which also differ between bash, PowerShell and cmd; the general test ("one command a shell passes through unchanged") covers them.
- **G7 — non-blocking, `/codeo:plan`'s.** `CHANGELOG.md`, the #69 entry: says commands are written shell-neutral and omits the other branch (a command that cannot be neutral is asked about and labelled `Shell: <name>`).

Reviewer items declined as out of scope: a stash's failed assignee removal, close step 12's merge-proof stop, whether the manual Ready repair is needed, `/codeo:implement` not reading `Runs on:`, Windows Git Bash as a product fact, and `/codeo:issue` reading the Status when delegated to.

Pre-existing, noted once: the abandon exit's missing block (G1) predates this change; with this change's rule written, it is now the one close exit the rule does not cover.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-14 — qc round 1: build and suite pass, 8 of 8 criteria met, one blocking finding (handoff table row names `/codeo:plan` for the no-lock exit), back to `/codeo:plan` · cost: 6m · opus-5-5 183k in + 2.2M cached / 15k out · sonnet-5-5 101k in + 538k cached / 1k out
- 2026-11-14 — qc round 2: build and suite pass, 8 of 8 criteria met, no blocking finding (G1-G7 non-blocking), forward to /codeo:close · cost: 7m · opus-5-5 307k in + 2.8M cached / 21k out · sonnet-5-5 26k in + 1.4M cached / 5k out
