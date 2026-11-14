# Issue #69 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/69 |
| Branch | `feat/fix-closing-blocks-that-name` |
| Updated | 2026-11-14 |

## Where this stands

Round 1 is written: one blocking finding (F1), owned by `/codeo:plan`. Nothing is open. Next: `/codeo:plan`.

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

## Log

- 2026-11-14 — qc round 1: build and suite pass, 8 of 8 criteria met, one blocking finding (handoff table row names `/codeo:plan` for the no-lock exit), back to `/codeo:plan` · cost: 6m · opus-5-5 183k in + 2.2M cached / 15k out · sonnet-5-5 101k in + 538k cached / 1k out
