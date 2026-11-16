# Issue #71 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/71 |
| Branch | `feat/file-new-issues-straight-board` |
| Updated | 2026-11-15 |

## Where this stands

Round 2 is clear and forwards to `/codeo:close`. The build and the full suite pass, all six criteria are met, F1 from round 1 is fixed, and F7-F9 are non-blocking. Nothing is open.

## Questions

None.

## Notes

- Reviewed `implement.md` round 1, at `e4516df`, against base `cd9cd5e` (`git merge-base origin/main HEAD`).
- No shared environment (`environment.resource` is unset), no invariants file, and no `wiki` module.

## Outcome

### Round 1 — 2026-11-15

**Commands and output**
- `sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main` (exit 0, no `also changed on main:` lines).
- `overlap.sh 71` → nothing (exit 0). `overlap.sh --outside 71` → nothing (exit 0).
- `git diff origin/main...HEAD --stat` → 18 files, 652 insertions(+), 26 deletions(-). Product files: `CHANGELOG.md`, `docs/handoff.md`, `docs/skills-inventory.md`, `docs/skills.md`, `scripts/board.sh` (header comment only), `skills/issue/SKILL.md`, `skills/triage/SKILL.md`, `tests/{board,closing-exits,inventory,issue-skill,triage-skill}.test.sh`, `tests/fixtures/skills-inventory.rules.sha256`.
- `scope.sh origin/main HEAD` →
  ```
  scope: suite shell needed for unclassified paths:
    .codeo/71/implement.md
    .codeo/71/init.md
    .codeo/71/issue.md
    .codeo/71/plan.md
    CHANGELOG.md
  suite.shell=true
  ```
  No `deploy=` line: no environment is configured.
- Build (`shell`: `true`) → exit 0.
- Test (`shell`: `bash tests/run.sh`, run whole) → `all cases passed`, exit 0.
- `overlay.sh qc invariants-extra` → exit 3 (none). `overlay.sh qc wiki-rules` → exit 3 (the existing pages' conventions apply).
- Independent review: `superpowers:requesting-code-review`, on opus, given the criteria and a one-line description. Its assessment, quoted in plain text: "Ready to merge? With fixes".

**Acceptance criteria**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | On a project with a board, `board.sh status <N>` prints `Backlog` straight after `/codeo:issue` files issue N. | met | `skills/issue/SKILL.md` step 8 runs `board.sh" set <N> backlog` before the status read. `tests/board.test.sh` (new case "backlog off the board") shows that `set` adds an off-board issue to the gate project and writes `O_BACKLOG`. `tests/closing-exits.test.sh` `issue-backlog` pins `set` before `status`. |
| 2 | Marking that issue Ready in `/codeo:triage` prints a `board.sh` line whose old status is `Backlog`, not `(not on the board)`. | met | Follows from 1. `tests/board.test.sh`'s existing case asserts `Backlog → Ready on #2` for a card in Backlog. |
| 3 | On a project with no board, `/codeo:issue` files the issue and makes no `board.sh` call. | met | Step 8 is gated on `config.sh get .board`, and its text says "With no board, make no `board.sh` call at all". Pinned by `tests/issue-skill.test.sh` "no board, no call". |
| 4 | When `board.sh set` fails, the issue is still filed, its number is reported, and the failure is quoted with its fix. | met | Rule `issue-09`, `skills/issue/SKILL.md` step 8. The dossier is committed before the move, and the status read that follows still routes the closing block. Pinned by `tests/issue-skill.test.sh` "a failed move never fails the filing" and "the failure is quoted with its fix". |
| 5 | `/codeo:triage` asks about a new Backlog issue with no ledger row, and once that issue is decided it isn't shown again. | not met — see F1 | `skills/triage/SKILL.md:142` and `:232` key the decision on `issue:<N>` only. The intake source at `:132-133` raises the same issue under `intake:<N>`. |
| 6 | The skill tests cover the new `/codeo:issue` board step and the unchanged no-board path. | met | `tests/issue-skill.test.sh` (7 skill cases, 7 doc cases), `tests/triage-skill.test.sh` (new, 7 cases), and `closing-exits` `issue-backlog`. These are wording checks, in this repository's form (see F6). |

**Documentation check.** `docs/handoff.md` (board bullet, transition table, failure exception,
ownership table), `docs/skills.md`, `docs/skills-inventory.md`, `board.sh`'s header and
`CHANGELOG.md` describe the new behaviour. They are in the present tense and carry no issue
numbers outside the changelog. Two scope sentences were missed (F2).

**Findings**

- **F1 — blocking — `/codeo:plan`'s.** Criterion 5 is not reliably produced. Every issue
  `/codeo:issue` files has an `<N>/` dossier on `codeo/intake`. Triage step 1.2 therefore raises it
  as "filed and never started" (`skills/triage/SKILL.md:132-133`), and the fingerprint list
  (`:74`) gives that item `intake:<dir>`, which is `intake:<N>`. The new text records the decision only as
  `issue:<N>` → `backlog` (`:232`), and `:142` checks only for an `issue:<N>` row. On the next run,
  the intake source still yields `intake:<N>` with no ledger row, so the issue is asked about again
  unless the agent merges the two sources on its own. Nothing tells it to: triage-09's "one item
  with several sources" is about findings that several dossiers mention. Root cause (Phase 1):
  the plan, Task 2 steps 2 and 3 (`docs/plans/2026-11-15-file-new-issues-into-backlog.md:113-114`),
  names `issue:<N>` as the only fingerprint and does not account for the intake source. The code
  does what the plan says, so the plan has to change. It must say that a filed, never-started
  issue has one fingerprint, `issue:<N>`, whichever source finds it (or record both), and add a
  test that pins that sentence.
- **F2 — non-blocking — `/codeo:plan`'s.** Two scope sentences are now untrue, and the plan named neither:
  `skills/issue/SKILL.md:12` says "and that is all it does" and `docs/skills.md:26` says "does
  nothing else". The skill now also writes a board Status.
- **F3 — non-blocking — `/codeo:plan`'s.** `skills/triage/SKILL.md:29` says "*leave in the backlog*
  is for an issue that is not there yet". Step 4 still offers that option for Backlog issues, and
  step 5 handles the already-in-Backlog case. The wording is the plan's (Task 2 step 1).
- **F4 — non-blocking — `/codeo:plan`'s.** `skills/triage/SKILL.md:245-246`: after the new skip
  branch, "quoting the script's output line … note the backlog move (or its failure …)" still
  assumes a `set` ran. When the card is already in Backlog, the text should say to quote the
  `status` line instead. The plan's Task 2 step 4 said "Keep" the following text.
- **F5 — non-blocking — `/codeo:implement`'s.** `skills/issue/SKILL.md:176-179`: on success, the `set`
  line is described but never reported. Only a failure is quoted.
- **F6 — non-blocking — neither (noted).** The new skill tests are fixed-string checks, so none of
  them would catch F1. This matches the repository's existing skill-test form, and criterion 6 is met.
- Carried from `implement.md` (non-blocking, pre-existing pinned text): `triage-05`'s rule text
  still says "the card moves to Backlog".

**Routing.** F1 blocks criterion 5, and the cause is in the plan, not the code. A corrected plan
round should settle the fingerprint and can fold in F2–F4. F5 can ride along in the
implementation round that follows.

**Verdict: back to `/codeo:plan`.**

### Round 2 — 2026-11-16

Reviewed `implement.md` round 2, after `plan.md` round 2, at `bb1187e` against base `cd9cd5e` (`git merge-base origin/main HEAD`).

**Commands and output**
- `sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main` (exit 0, no `also changed on main:` lines).
- `overlap.sh 71` → nothing (exit 0; #104 and #107 were already raised and answered). `overlap.sh --outside 71` → nothing (exit 0).
- `git diff origin/main...HEAD --stat` → 19 files changed, 949 insertions(+), 33 deletions(-).
- `scope.sh origin/main HEAD` →
  ```
  scope: suite shell needed for unclassified paths:
    .codeo/71/implement.md
    .codeo/71/init.md
    .codeo/71/issue.md
    .codeo/71/plan.md
    .codeo/71/qc.md
    CHANGELOG.md
  suite.shell=true
  ```
- Build (`shell`: `true`) → `build-exit=0`.
- Test (`shell`: `bash tests/run.sh`, run whole) → `all cases passed`, `test-exit=0`.
- `overlay.sh qc invariants-extra` → exit 3. `overlay.sh qc wiki-rules` → exit 3.
- Independent review: `superpowers:requesting-code-review` on opus, given the criteria and a one-line description. It followed a new issue through filing and two triage runs. Run against the base revision, `triage-skill` fails 13 of 14 cases and `issue-skill` fails 9. Its assessment, quoted in plain text: "Ready to merge? Yes."

**Acceptance criteria**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | On a project with a board, `board.sh status <N>` prints `Backlog` straight after `/codeo:issue` files issue N. | met | `skills/issue/SKILL.md:175-183`: `set <N> backlog` comes before the `status <N>` read. `tests/board.test.sh` "backlog off the board" shows `set` adds an off-board issue and writes `O_BACKLOG`. `closing-exits` `issue-backlog` pins the order. |
| 2 | Marking that issue Ready in `/codeo:triage` prints a `board.sh` line whose old status is `Backlog`, not `(not on the board)`. | met | Follows from 1. `tests/board.test.sh` asserts `Backlog → Ready on #2`. |
| 3 | On a project with no board, `/codeo:issue` files the issue and makes no `board.sh` call. | met | `skills/issue/SKILL.md:183`: "With no board, make no `board.sh` call at all", gated on `config.sh get .board`. Pinned by `issue-skill` "no board, no call". |
| 4 | When `board.sh set` fails, the issue is still filed, its number is reported, and the failure is quoted with its fix. | met | Rule `issue-09` (`skills/issue/SKILL.md:181-182`). Pinned by `issue-skill` "a failed move never fails the filing" and "the failure is quoted with its fix". See F8 for a failure with no fix to quote. |
| 5 | `/codeo:triage` asks about a new Backlog issue with no ledger row, and once that issue is decided it isn't shown again. | met | `skills/triage/SKILL.md:77-79` (one fingerprint `issue:<N>` whichever source finds it), `:138-140` (the intake `<N>/` is the same item), `:147` (asked once), `:192-194` (left-in-the-backlog items dropped at step 2), `:237` and `:248-253` (decisions recorded as `issue:<N>`). Pinned by `triage-skill` (14 cases). |
| 6 | The skill tests cover the new `/codeo:issue` board step and the unchanged no-board path. | met | `tests/issue-skill.test.sh` (board step, no-board path, failure), `tests/triage-skill.test.sh`, `closing-exits` `issue-backlog`. These are wording checks, in this repository's form. |

**Documentation check.** `docs/handoff.md`, `docs/skills.md` (the `issue` section's opening sentence now names the Backlog write), `docs/skills-inventory.md` (`issue-09`), `board.sh`'s header and `CHANGELOG.md` describe what the skills do. The pages carry no issue numbers or "now" wording outside the changelog. The plan named no page for the fingerprint rule, and none states it, so there is nothing stale to update.

**Findings**

- F1 (blocking in round 1) — fixed by `6b32a53` (one fingerprint, `issue:<N>`).
- F2 (non-blocking in round 1) — fixed by `2ae9447`. F3, F4 (non-blocking in round 1) — fixed by `9638401`. F5 (non-blocking in round 1) — fixed by `2ae9447`.
- **F7 — non-blocking — `/codeo:plan`'s.** `skills/issue/SKILL.md:178-179` says `set` "prints one line naming the old and the new Status. Quote that line in the report." With several projects in `board.projects`, `board.sh set` prints one line per project written (`scripts/board.sh:286`, inside the per-project loop). The wording is the plan's (round 1 Task 1, round 2 Task 9).
- **F8 — non-blocking — `/codeo:plan`'s.** Because `/codeo:issue` now writes Backlog on every filing, a board with no `Backlog` option and no `board.statuses.backlog` mapping fails on every filing with `board.sh: no synced project has the option 'Backlog' (it has: …)` (`scripts/board.sh:291`). That message names no fix, so rule `issue-09`'s "quoted with the fix it names" has nothing to quote. The filing still stands. A note that the fix is `board.statuses.backlog` (or a doctor check) would help.
- **F9 — non-blocking — `/codeo:plan`'s.** `CHANGELOG.md`'s entry does not mention that a filed, never-started issue found on `codeo/intake` is fingerprinted `issue:<N>`. A ledger elsewhere holding an `intake:<N>` row would see that issue asked about once more after upgrading. This project's ledger has no `intake:<N>` rows.
- F6 (round 1, noted) still holds: the skill tests are wording checks. The reviewer confirmed they fail against the base revision.

**Routing.** No blocking finding. F7–F9 are polish for `/codeo:triage` to pick up, and on their own they do not send the change back.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-15 — round 1: build and suite pass; 5 of 6 criteria met; F1 (criterion 5 fingerprint) blocking, routed back to plan · cost: 4m · opus-5-5 193k in + 2.3M cached / 14k out
- 2026-11-16 — round 2: build and suite pass; 6 of 6 criteria met; F1 fixed; F7-F9 non-blocking; clear, forward to close · cost: 4m · opus-5-5 348k in + 2M cached / 15k out
