# Issue #108 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/108 |
| Branch | `feat/follow-ups-97-left-overlap` |
| Updated | 2026-11-19 |

## Where this stands

Round 3, done: clear. The build and the full suite pass on the merged tree and all six criteria are met. Five non-blocking notes (F4, F6, F8-F10) ride along. Next: `/codeo:close`.

## Questions

None.

## Notes

Environment: none configured, so no lease check and no environment block. Overlaps: `overlap.sh 108` printed nothing (the #102 and #122 pairs are named in Q6 and Q7 of `plan.md`). `sync-main` merged `origin/main` (one commit, #122's `41368e7`) into the branch as `47c56b0`; it changed `CHANGELOG.md`, `docs/handoff.md` and `docs/skills.md`, all three also touched here, and a check afterwards showed this branch's edits to each still in place (`last copy` once in each doc, the `(#108)` bullet at the top of `## Unreleased`).

Round 2: `overlap.sh 108` printed `112	glob:CHANGELOG.md` and `112	glob:docs/handoff.md` — the #112 overlap already raised and answered (proceed and coordinate) as Q1 in `implement.md`; not raised again here. `overlap.sh --outside 108` printed nothing. `scope.sh origin/main HEAD` → `suite.shell=true`.

## Outcome

### Round 1 — 2026-11-19

**Commands and output (this pass).**

- `bash scripts/sync-main.sh --abort-on-conflict` → `sync-main: merged origin/main (1 commit(s))`, `also changed on main: CHANGELOG.md`, `docs/handoff.md`, `docs/skills.md`; exit 0.
- `bash scripts/overlap.sh 108` → no output, exit 0. `bash scripts/overlap.sh --outside 108` → no output, exit 0: no changed path sits outside the footprint.
- `git diff origin/main...HEAD --stat` → 16 files changed, 735 insertions, 38 deletions (code, tests, docs, the plan and `.codeo/108/`).
- `bash scripts/scope.sh origin/main HEAD` → `suite.shell=true` (unclassified paths: `.codeo/108/{implement,init,issue,plan}.md`, `CHANGELOG.md`); no `deploy=` line, as no environment is configured.
- Build: the `shell` suite's build command is `true` → exit 0.
- Suite: `bash tests/run.sh` on the merged tree (`47c56b0`) → `all cases passed`, exit 0.
- Direct checks: `overlap.sh --outside 108 --base nosuchref` → `overlap: cannot resolve nosuchref`, exit 1; `--base ""` → `overlap: --base needs a ref`, exit 1; `--head ""` → `overlap: --head needs a ref`, exit 1. `grep` shows both `## Outcome` awk matches anchored (`scripts/qc-verdict.sh:72,134`); `grep -c 'so an issue on a large board is found' CHANGELOG.md` → 0; `grep -c 'introduced in v1.0.6' CHANGELOG.md` → 1.
- The reviewer's focused runs (overlap, qc-verdict, closing-exits, qc-skill, board: all pass) and its mutations in a scratch worktree are quoted under *Code review* below.

**Criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| `overlap.sh --outside <N> --base nosuchref` exits non-zero with a message; `--base ""` exits non-zero | met | the three commands above; `tests/overlap.test.sh` cases for an empty ref, an unresolved ref and a diff that cannot be made |
| `qc-verdict.sh` does not treat `## Outcomes` as `## Outcome`; the two new cases exist and pass | met | `scripts/qc-verdict.sh:72,134`; `tests/qc-verdict.test.sh:756` (`## Outcomes`), `:773` (`### Round 2` outside `## Outcome`), `:795` (a PR adding only plans and dossiers). Only the qc.md path has a case that bites (F2) |
| Each test guard named above fails when the text it guards is re-wrapped or the behaviour is broken (shown by a mutation) | not met — five of six guards are shown; `row_for`'s whole-label match is not (F1) | `tests/board.test.sh` (`title-read-fails` rc 1, `beyond-50` and the blank-row case in both orders); `tests/closing-exits.test.sh` (`close-step17-lead`, `RETURN` trap, `row_for`); `tests/qc-skill.test.sh` (flattened check) |
| `skills/init/SKILL.md`, `docs/handoff.md`, `skills/close/SKILL.md`, `docs/skills.md` and `skills/qc/SKILL.md` no longer disagree on the points named; a test pins each | met | `case_init_lock_wording`, `case_abandon_summaries`; `tests/qc-skill.test.sh:53-54` pins the two `skills/qc` points, which already agreed at the base |
| The two CHANGELOG clauses match the code | met | `CHANGELOG.md` v1.0.7 bullet (`reads every page of an issue's project items`; `introduced in v1.0.6`); `scripts/board.sh:93-97` reads the issue's own `projectItems`; the rule came in with v1.0.6's bullet |
| `bash tests/run.sh` passes and `CHANGELOG.md` records the change | met | the suite output above; the `(#108)` bullet at `CHANGELOG.md:9` |

**Documentation.** `skills/init/SKILL.md`, `docs/handoff.md`, `docs/skills.md` and `CHANGELOG.md` are the four pages the plan named and the diff changed; none is left untouched. The added text names no issue and no "now" or "no longer" (checked on the diff's added lines). Two readings are recorded as F5 and F6.

**Code review.** Reviewer on opus, handed the criteria and the diff, not the implementer's account. It ran the five focused suites and the mutations in a scratch worktree and found: `|| true` back on `changes()` fails five cases; dropping the empty-ref check fails the new case; removing the qc.md anchor fails the `## Outcomes` case; removing `failed=1` makes `title-read-fails` fail with `rc=0`; removing `trap - RETURN`, reverting the flat read in `close-step17-lead` and adding a wrapped `and not\n blocking by rule:` each fail their case. Its one important finding is F1, which I reproduced; its minors are F2-F6 below. Its assessment: ready to merge with fixes.

**Findings.**

- **F1 — blocking, `/codeo:implement`'s.** `tests/closing-exits.test.sh:338` (the `bites` mutation for `row_for`) renames `` `close — lock kept` `` to `` `close — stale lock kept` ``. The old suffix match (`grep -F "$1\` |"`) fails on that row as well, because the string `close — lock kept\` |` is gone from it (`grep -cF` on the mutated copy → 0). The suite therefore passes with `row_for` reverted to the old grep (the reviewer reran it: `all cases passed`), and criterion 3 is not shown for this guard. The guard itself is right; the mutation should put a prefix on the label (`` `stale close — lock kept` ``), which only a whole-label match rejects. Root cause: the plan's Task 4 named the mutation `lock kept` → `stale lock kept`, and the real label is `close — lock kept`, so the implementer's adaptation lost the distinction.
- **F2 — non-blocking, `/codeo:implement`'s.** `scripts/qc-verdict.sh:134` (the `plan_round` awk) is anchored but no case bites it: reverting it to `/^## Outcome/` leaves `tests/qc-verdict.test.sh` passing. A `plan.md` whose `## Outcomes` holds a `### Round 2` would. Criterion 2 names `qc-verdict.sh` not matching `## Outcomes`, which the qc.md path shows.
- **F3 — non-blocking, `/codeo:implement`'s.** `tests/qc-verdict.test.sh:795`: the case is named "a PR that only adds files under docs/plans and .codeo" but also adds `b.txt`, a path inside the footprint. It exercises the `docs/plans` exclusion; only the name says more.
- **F4 — non-blocking, `/codeo:plan`'s.** `skills/init/SKILL.md:354-358`: in the case the new text covers (a lock taken, then a volume or sandbox TODO), the no-lock block's goal "the lock taken" is already met and no next command is named, while the test forbids `/codeo:plan` in that paragraph. It agrees with `docs/handoff.md`'s "needs the fix alone", and Q4 chose wording only, so the code did what the plan said.
- **F5 — non-blocking, `/codeo:implement`'s.** `docs/skills.md:196`: "…`/codeo:triage` then the host clean-up, an abandon that finished included, unless the unmerged branch was deleted…" can be read as dropping `/codeo:triage` as well; `skills/close/SKILL.md` and `docs/handoff.md` attach the exception to the clean-up only.
- **F6 — non-blocking, `/codeo:plan`'s.** `skills/implement/SKILL.md:84`, `skills/qc/SKILL.md:92,166`, `skills/close/SKILL.md:216`, `skills/plan/SKILL.md:310` and `docs/handoff.md:209` run `overlap.sh` and none says that a non-zero exit with an `overlap: cannot diff` line is a stop, not "no overlap". The plan named no task for it; `implement.md` recorded it as a plan gap. A skill following a non-zero exit will probably report it. For `/codeo:triage` or an issue of its own if the engineer wants it covered.

**Routing.** One blocking finding, and it is the implementer's: the code does what the plan said; the guard's mutation uses a label that cannot tell the two matches apart. The fix is one line in `case_bites` plus a rerun; F2, F3 and F5 can go in the same round (a `plan.md` case, a rename, one clause). F4 and F6 are for the engineer or `/codeo:triage`. Nothing here was fixed.

**Verdict: back to `/codeo:implement`.**

### Round 2 — 2026-11-20

(after implement.md round 2)

**Commands and output (this pass).**

- `bash .devcontainer/scripts/role.sh --check qc` → exit 0.
- `bash scripts/sync-main.sh --abort-on-conflict` → `sync-main: conflict: CHANGELOG.md`, exit 2. The merge was aborted; `git status --short` is empty. `origin/main` gained one commit since round 1: `d3e957c feat: /codeo:issue proposes a priority label when the project opts in (#102) (#139)`, which also edits `CHANGELOG.md`.

The pass stops here by rule: a conflict with the base branch is a send-back, and `qc` resolves nothing. No build, suite, review or criterion was run on this round's diff.

**Criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| `overlap.sh --outside <N> --base nosuchref` exits non-zero with a message; `--base ""` exits non-zero | not yet checkable — pass stopped at step 2 | — |
| `qc-verdict.sh` does not treat `## Outcomes` as `## Outcome`; the two new cases exist and pass | not yet checkable — pass stopped at step 2 | — |
| Each test guard named above fails when the text it guards is re-wrapped or the behaviour is broken (shown by a mutation) | not yet checkable — pass stopped at step 2 | — |
| `skills/init/SKILL.md`, `docs/handoff.md`, `skills/close/SKILL.md`, `docs/skills.md` and `skills/qc/SKILL.md` no longer disagree on the points named; a test pins each | not yet checkable — pass stopped at step 2 | — |
| The two CHANGELOG clauses match the code | not yet checkable — pass stopped at step 2 | — |
| `bash tests/run.sh` passes and `CHANGELOG.md` records the change | not yet checkable — pass stopped at step 2 | — |

**Findings.**

- F1 (blocking in round 1) — addressed by `b48e624`, per `implement.md` round 2; not re-checked, since this pass stopped at step 2.
- **F7 — blocking, `/codeo:implement`'s.** `CHANGELOG.md` conflicts with `origin/main` (#102's `d3e957c`, merged after round 1). Both sides add to `## Unreleased`; the resolution keeps both bullets and this branch's two v1.0.7 clause corrections. #102 also changes `docs/skills.md`, which this branch edits (F5): it did not conflict, but the resolution should re-check line 196. This is the conflict implement.md Q1 anticipated with #112; it came from #102 instead.

**Routing.** A conflict with the base branch goes back to `/codeo:implement`, whose step 2a merges `origin/main` and resolves `CHANGELOG.md`. The next `/codeo:qc` runs the whole pass, round 3, on the merged tree.

**Verdict: back to `/codeo:implement`.**

### Round 3 — 2026-11-20

(after implement.md round 3)

**Commands and output (this pass).**

- `bash .devcontainer/scripts/role.sh --check qc` → exit 0.
- `bash scripts/sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main`, exit 0 (`origin/main` is `d3e957c`, #102's; round 2's merge `11e29b8` carries it). No `also changed on main:` lines.
- `bash scripts/overlap.sh 108` → `112	glob:CHANGELOG.md`, `112	glob:docs/handoff.md`: the #112 pair already raised and answered (proceed and coordinate) as Q1 in `implement.md`, not raised again. `bash scripts/overlap.sh --outside 108` → no output, exit 0.
- `git diff origin/main...HEAD --stat` → 17 files changed, 896 insertions, 38 deletions. `bash scripts/scope.sh origin/main HEAD` → `suite.shell=true` (unclassified paths: `.codeo/108/{implement,init,issue,plan,qc}.md`, `CHANGELOG.md`); no `deploy=` line, no environment configured.
- Build: the `shell` suite's build command is `true` → exit 0.
- Suite: `bash tests/run.sh` on the merged tree (`64dcb14`) → `all cases passed`, exit 0.
- Direct checks: `overlap.sh --outside 108 --base nosuchref` → `overlap: cannot resolve nosuchref`, exit 1; `--base ""` → `overlap: --base needs a ref`, exit 1; `--head ""` → `overlap: --head needs a ref`, exit 1. Both `## Outcome` awk matches anchored (`scripts/qc-verdict.sh:72,134`). `grep -c 'so an issue on a large board is found' CHANGELOG.md` → 0; `grep -c 'introduced in v1.0.6' CHANGELOG.md` → 1; no conflict markers in `CHANGELOG.md`, and `## Unreleased` holds the `(#108)` bullet, #102's bullet and the rest, each separated by a blank line.
- The reviewer's mutations in a scratch worktree are quoted under *Code review*.

**Criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| `overlap.sh --outside <N> --base nosuchref` exits non-zero with a message; `--base ""` exits non-zero | met | the three commands above; `tests/overlap.test.sh` cases for an empty ref, an unresolved ref and a diff that cannot be made |
| `qc-verdict.sh` does not treat `## Outcomes` as `## Outcome`; the two new cases exist and pass | met | `scripts/qc-verdict.sh:72,134`; `tests/qc-verdict.test.sh` cases for `## Outcomes` in qc.md, a `### Round 2` outside `## Outcome`, and (round 2) a `### Round 2` under `## Outcomes` in plan.md; each bites (reviewer's mutations of lines 72 and 134) |
| Each test guard named above fails when the text it guards is re-wrapped or the behaviour is broken (shown by a mutation) | met | reviewer's mutations: `title-read-fails` (`failed=1` removed → `rc=0`), `beyond-50` (`--paginate` removed; `status` reading one row), `close-step17-lead` (unflattened read), the `RETURN` trap (`trap - RETURN` deleted), `row_for` (suffix match → `the renamed handoff row passed rule`), the qc-skill flattened guard (a wrapped `and not\nblocking by rule:` fails it, and passes under the old guard) |
| `skills/init/SKILL.md`, `docs/handoff.md`, `skills/close/SKILL.md`, `docs/skills.md` and `skills/qc/SKILL.md` no longer disagree on the points named; a test pins each | met | `init-lock-wording`, `abandon-summaries` (each fails with its page restored to the base); `tests/qc-skill.test.sh` pins the two `skills/qc` points, which already agreed at the base |
| The two CHANGELOG clauses match the code | met | `CHANGELOG.md` v1.0.7 bullet; `scripts/board.sh` `lookup` reads the issue's own `projectItems`; the host-task rule came with v1.0.6 |
| `bash tests/run.sh` passes and `CHANGELOG.md` records the change | met | the suite output above; the `(#108)` bullet at the top of `## Unreleased` |

**Documentation.** `skills/init/SKILL.md`, `docs/handoff.md`, `docs/skills.md` and `CHANGELOG.md` are the pages the plan named and the diff changed. The added lines in those pages name no issue and no "now" or "no longer" (checked on the diff's added lines under `docs/` and `skills/`, leaving out the plan file). F4 and F6 below are the two readings of them that stay open.

**Code review.** Reviewer on opus, handed the criteria and the diff, not the implementer's account. Quoted in plain text: its assessment was "ready to merge", with no Critical or Important findings. It ran the focused suites (overlap, qc-verdict, board, closing-exits, qc-skill, init-skill, skills, close-skill, skills-doc, closing-block, usage, skills-lint: all pass) and 22 mutations, each reverted, each failing its suite: both `## Outcome` anchors and the `o && /^## /` exit in `qc-verdict.sh`; the plansDir skip, `changes()` back to `|| true`, `mine` without `exit 1`, the other-workflow failure made fatal or its warning removed, and both empty-ref checks in `overlap.sh`; `failed=1`, `--paginate` and the per-row reads in `board.sh`; the step-17 flatten, `row_for` back to a suffix match and to `lock kept`, and `trap - RETURN` in `closing-exits`; init, handoff and skills.md each restored to the base; and a re-wrapped qc-skill guard.

**Findings.**

- F1 (blocking in round 1) — fixed by `b48e624`; checked again this pass by the reviewer's `row_for` suffix-match mutation, which fails `bites`.
- F7 (blocking in round 2) — fixed by merge `11e29b8`; `sync-main` reports the branch contains `origin/main`, and no conflict markers remain.
- **F8 — non-blocking, `/codeo:implement`'s.** `scripts/overlap.sh:117-119` keeps the old one-line comment ("Changed paths against origin/<base> for a ref, dossiers left out.") above the new two-line comment for `changes`, so the same thing is said twice. I read the lines and it is as reported.
- **F9 — non-blocking, `/codeo:implement`'s.** `tests/closing-exits.test.sh:222-224`: the `abandon-summaries` check for `docs/skills.md` greps one physical line for `an abandon that finished` and flattens only that line. A re-wrap of that sentence would fail the test though the text is right (it cannot pass wrongly). The issue asks guards to survive a re-wrap; this one fails closed on it.
- **F4 — non-blocking, `/codeo:plan`'s** (carried from round 1; the reviewer found it independently). `skills/init/SKILL.md:351-358`: for a lock taken and then a `lock: TODO`, the no-lock block's goal is already met and no next command is named, while the test forbids `/codeo:plan` there. It agrees with `docs/handoff.md`'s "needs the fix alone"; Q4 chose wording only.
- **F6 — non-blocking, `/codeo:plan`'s** (carried from round 1; found independently). `skills/plan/SKILL.md:310`, `skills/implement/SKILL.md:84`, `skills/qc/SKILL.md:92,166`, `skills/close/SKILL.md:216` run `overlap.sh <N>` and none says a non-zero exit with `overlap: cannot diff …` is a stop to report, not "no overlap". The plan named no task for it.
- **F10 — non-blocking, out of scope.** `scripts/dossier-check.sh:479` and `scripts/inflight.sh:84,180,209,224` still match `/^## Outcome/` unanchored, so `dossier-check` and `qc-verdict` differ on a `## Outcomes` heading. `qc-verdict` fails closed and these files are outside the issue (pre-existing). For `/codeo:triage` if the engineer wants them aligned.

Round 1's F2, F3 and F5 were fixed in implement round 2 (`b48e624`); the reviewer's mutations show F2's anchor bites, and the F3 case is renamed as the issue words it.

**Routing.** No blocking finding. The five non-blocking ones go to the engineer or `/codeo:triage` (F4, F6, F10 are the plan's or out of scope; F8 and F9 are polish that on its own never sends the change back). Nothing here was fixed.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-19 — qc round 1: build and suite pass on the merged tree; five of six criteria met; one blocking finding (F1), five non-blocking (F2-F6); back to `/codeo:implement` · cost: 5m · opus-5-5 391k in + 4.3M cached / 21k out · sonnet-5-5 296k in + 686k cached / 1k out
- 2026-11-20 — qc round 2: stopped at step 2, `CHANGELOG.md` conflicts with origin/main (#102); back to `/codeo:implement` · cost: 0m · opus-5-5 121k in + 177k cached / 1k out
- 2026-11-20 — qc round 3: build and suite pass on the merged tree; all six criteria met; no blocking finding, five non-blocking (F4, F6, F8-F10); clear, forward to `/codeo:close` · cost: 7m · opus-5-5 289k in + 4.9M cached / 26k out · sonnet-5-5 165k in + 407k cached / 471 out
