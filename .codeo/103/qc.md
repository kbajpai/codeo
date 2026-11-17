# Issue #103 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/103 |
| Branch | `feat/let-codeo-triage-judge-flight` |
| Updated | 2026-11-17 |

## Where this stands

Round 2 is written: back to `/codeo:implement` for one blocking finding (F12). `close_send_back` never sees a send-back in a real `close.md`, because the `## Log` section ends the round.

## Questions

None.

## Outcome

### Round 1 — 2026-11-17

Under review: `implement.md` round 1 (`06d6ba1..06a5778`), plan `docs/plans/2026-11-17-triage-judges-in-flight-work.md`.

**Commands and output**
- `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main` (exit 0).
- `overlap.sh 103`: nothing printed (exit 0). `overlap.sh --outside 103`: nothing printed (exit 0).
- `scope.sh origin/main HEAD`: `suite.shell=true` (the dossiers and `CHANGELOG.md` listed as unclassified paths that need the suite). No `deploy=` line: no environment is configured.
- Build: `shell` suite build `true`, exit 0.
- Test: `bash tests/run.sh`, exit 0, `all cases passed` (4m08s). `bash tests/inflight.test.sh` and `bash tests/triage-skill.test.sh` each print `all cases passed`.
- Overlays: `qc invariants-extra` and `qc wiki-rules` exit 3 (none). No invariants file.
- The branch's `scripts/inflight.sh` run against origin printed `touched:`, `waits:` and `verdict:` for #103, #99 and #116. For #116 it printed `touched:   2026-11-17 (qc.md log), 0 days ago`, `waits:     /codeo:plan` and `verdict:   round 1 — back to /codeo:plan.`. `--tsv` printed five columns and `--branches` three, as before.
- The reviewer (opus, given the acceptance criteria only) ran `bash tests/run.sh`: all cases passed. Verdict: "With fixes".

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | `inflight.sh` prints a last-touched date for every workflow, matching the newest pushed evidence | met | `tests/inflight.test.sh` `touched_*` cases (:425-447); the live run printed one for all three workflows |
| 2 | An unanswered dossier question is shown as waiting on the engineer, with the step file and question number | met | `waits_on_the_engineer` (:592); `scripts/inflight.sh:189`. F2 is about what that precedence hides. |
| 3 | A workflow whose `qc.md` has a verdict shows that verdict | met | `waits_after_a_send_back` (:610), `verdict_reads_the_last_round` (:614); the live run printed #116's `verdict:` line |
| 4 | Untouched beyond the threshold is asked; within it, listed and not asked | met | `skills/triage/SKILL.md:113-119`; wording checks in `tests/triage-skill.test.sh`. F3 is about the wording for an unassigned workflow. |
| 5 | Triage flags a board Status that disagrees with the dossier and PR state, quoting both | met | `skills/triage/SKILL.md:123-147` (table, quoting the `status` line, `step:` and the PR state). F2 is a false positive this rule raises. |
| 6 | `--tsv` columns and human block lines unchanged; consumers' tests pass | met | `tsv_and_branches_are_unchanged` (:449) and the existing `--tsv`/`--branches` equality cases; full suite passes |
| 7 | The config setting is documented with its default | met | `lib/env.sh:60`, `docs/skills.md:224` |
| 8 | `bash tests/run.sh` passes; `CHANGELOG.md` records the change | met | the run above; `CHANGELOG.md` `## Unreleased`, last bullet |

**Documentation.** `docs/handoff.md` (*Who else is in flight*), `docs/skills.md` (*triage*), `lib/env.sh` and `scripts/inflight.sh`'s header all describe the new lines and key in the present tense, with no issue numbers. The `docs/handoff.md` paragraph has one unwrapped long line (F11).

**Findings**
- **F1 — blocking, `/codeo:plan`'s.** `waits:` follows qc's last verdict even after a later round has answered it. Seen live: #116's `qc.md` round 1 sent it back to `/codeo:plan`; its `plan.md` has since written `### Round 2` ("planned (round 2, send-back from qc.md round 1)") and its `implement.md` round 2 is under way, yet the block says `waits:     /codeo:plan`. In the same way, #103's own block says `waits:     nothing known` with `implement.md`'s outcome written and qc not yet run. Cause: Q2's rule, as the plan wrote it (`scripts/inflight.sh:180-200` does what it says), reads only `qc.md` and never asks whether a later step's round, whose second line names `(send-back from qc.md round <k>)`, has answered it. Triage quotes `waits:` as evidence, so it would tell the engineer that #116 waits on a re-plan that is already done. The rule needs to take the latest step's own state into account (a send-back already answered, an implement outcome awaiting qc).
- **F2 — blocking, `/codeo:plan`'s.** An open question hides a stash or abandon. `waits_of` returns `engineer — …` before it runs `claim.sh --stash-live` (`scripts/inflight.sh:188-190`), and the skill takes stash and abandon from `waits:` (`skills/triage/SKILL.md:126`). A workflow stashed while a plan or implement question is open is therefore read as "no live stash", expected In progress, and the Ready that `/codeo:close` correctly set is raised as a mismatch, whose *fix it* names `board.sh set <N> inProgress` and would undo the stash. Both the precedence (Q2) and "stash and abandon come from `waits:`" (Task 3) are the plan's. The stash state has to reach triage whatever the open questions are, and a test should pin a stashed workflow with an open question.
- **F3 — non-blocking, `/codeo:implement`'s.** `skills/triage/SKILL.md:115-119` asks about a workflow "more than the threshold, or … assigned to nobody", then says "One within the threshold is listed … and not asked about". For an unassigned workflow inside the threshold, the two rules disagree. `plan.md` Q4's answer settles it (an unassigned workflow is asked about whatever its date), so the second sentence should say "within the threshold and assigned".
- **F4 — non-blocking, `/codeo:plan`'s.** `waits:     review — PR open` is printed for any archived dossier (`scripts/inflight.sh:194`), including one whose pull request was closed unmerged or never opened, the state the skill's table treats as "none fits". The existing `step: … (PR open)` label has the same limit. The wording should not claim a PR is open when only the archive was seen.
- **F5 — non-blocking, `/codeo:plan`'s.** For a workflow raised only for age (no stash), *resume* runs `board.sh set <N> ready` (`SKILL.md:246`), and the new table then expects In progress for it, so the next triage run flags the Ready it set itself.
- **F6 — non-blocking, `/codeo:plan`'s.** "One workflow is one question" (`SKILL.md:142-147`) does not say how one answer maps to each fingerprint. For example, what a *resume* records for `board:<N>:…`, or whether a combined *dismiss* silences the board mismatch too.
- **F7 — non-blocking, `/codeo:plan`'s.** The skill does not say what to do when `board.sh status` fails (exit 1 or 2, such as a missing `project` scope). Per `triage-06`/`triage-07`'s spirit, it should report the failure and raise no mismatch.
- **F8 — non-blocking, `/codeo:implement`'s.** The check `tests/triage-skill.test.sh:43` "send-back is In progress with a PR open" only finds `dossier at `.codeo/<N>/``, so it would pass with the row mapped to any Status.
- **F9 — non-blocking, `/codeo:implement`'s.** In the `## Log` date read, a date-only line ending in CRLF is skipped (`open_questions_in` strips CR; this awk does not). A malformed `CODEO_TODAY` prints an empty day count.
- **F10 — non-blocking, `/codeo:implement`'s.** There is no test where a log date ties an `Updated` row in the same file.
- **F11 — non-blocking, `/codeo:implement`'s.** There are unwrapped long lines in `docs/handoff.md` (*Who else is in flight*), `skills/triage/SKILL.md:119` and `lib/env.sh:60`.

**Routing.** F1 and F2 are blocking, and both come from rules the plan set (Q2's `waits:` precedence and Task 3's "stash and abandon come from `waits:`"). The code does what the plan says, so the fix starts at the plan. F4-F7 are the plan's too and are worth settling in the same pass. F3 and F8-F11 are the implementer's and ride along with the next implement round.

**Verdict: back to `/codeo:plan`.**

### Round 2 — 2026-11-17

Under review: `implement.md` round 2 (`779af7c..9e91d75`, with the dossier at `9b35ae0`), plan `docs/plans/2026-11-17-triage-judges-in-flight-work-round-2.md`. This is a whole new pass over `6699326..9b35ae0`.

**Commands and output**
- `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main` (exit 0).
- `overlap.sh 103`: nothing printed (exit 0). `overlap.sh --outside 103`: nothing printed (exit 0).
- `scope.sh origin/main HEAD`: `suite.shell=true` (the dossiers and `CHANGELOG.md` listed as unclassified paths that need the suite). There is no `deploy=` line because no environment is configured.
- Build: the `shell` suite's build is `true`, exit 0.
- Test: `bash tests/run.sh` exited 0 and printed `all cases passed`. The suite has no `filter`, so it ran whole.
- Overlays: `qc invariants-extra` and `qc wiki-rules` both exit 3 (none). There is no invariants file.
- `bash scripts/inflight.sh` against origin printed, for #103: `touched:   2026-11-17 (qc.md log), 0 days ago`, `waits:     /codeo:qc` and `verdict:   round 1 — back to /codeo:plan.`. For #99: `waits:     /codeo:implement`. For #116 (PR open): `waits:     review — dossier archived` and `verdict:   round 2 — clear — forward to /codeo:close.`.
- The reviewer (opus, given only the acceptance criteria) ran `tests/inflight.test.sh` and `tests/triage-skill.test.sh`, and both pass. Its verdict was "With fixes".
- F12 was reproduced here. `close_send_back`'s awk was run over a `close.md` containing `### Round 2 — review feedback`, then `qc round at review: 1`, then `## Log`. It printed nothing. The reviewer's run of the same input without `## Log` printed `2 1`.

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | `inflight.sh` prints a last-touched date for every workflow, matching the newest pushed evidence | met | `touched_*` cases in `tests/inflight.test.sh` (tie and CRLF included); the live run printed a date for all three workflows |
| 2 | An unanswered dossier question shows as waiting on the engineer, with step file and question number | met | `waits_on_the_engineer` and `waits_stash_before_questions`; `scripts/inflight.sh:239-243` |
| 3 | A workflow whose `qc.md` has a verdict shows that verdict | met | `verdict_*` cases; `scripts/inflight.sh:344-346`; the live run shows the verdicts for #103 and #116 |
| 4 | Untouched beyond the threshold is asked; within it, listed and not asked | met | `skills/triage/SKILL.md` step 1.2 (with "within the threshold and assigned") and its wording checks in `tests/triage-skill.test.sh` |
| 5 | Triage flags a board Status that disagrees with the dossier and PR state, quoting both | met | the *Board mismatch* bullet and table in `skills/triage/SKILL.md`; the quoting rule names the `status` line, `step:` and the PR state. F12 makes `waits:` wrong after a close send-back, but the table reads only `resume — `, which F12 does not touch. |
| 6 | `--tsv` columns and human block lines unchanged; consumers' tests pass | met | `tsv_and_branches_are_unchanged` and the existing `--tsv`/`--branches` cases; full suite passes |
| 7 | The config setting is documented with its default | met | `lib/env.sh` (`triage{parkedDays}`, default 7), `docs/skills.md` triage *Reads* bullet |
| 8 | `bash tests/run.sh` passes; `CHANGELOG.md` records the change | met | the run above; the #103 bullet under `## Unreleased` |

**Documentation.**
- `docs/handoff.md` (*Who else is in flight*), `docs/skills.md` (triage), `lib/env.sh` and `scripts/inflight.sh`'s header all describe the three lines, the `waits:` order and the key, in the present tense and with no issue number.
- The `scripts/inflight.sh` header (lines 17-19) and `docs/handoff.md` both say `waits:` follows a close send-back, which F12 shows is not true of a real dossier. That is the same defect, not a separate finding.
- The `CHANGELOG.md` bullet is accurate otherwise.

**Round 1 recap.**
- F1 (blocking in round 1) — fixed by `779af7c`.
- F2 (blocking in round 1) — fixed by `779af7c` and `de17297`.
- F3, F5, F6, F7 and F8 — fixed by `de17297`.
- F4 — fixed by `779af7c` (the line reads `review — dossier archived`).
- F9 (CRLF), F10 (tie test) and F11 (wraps) — fixed by `779af7c` and `de17297`.

**Findings**
- **F12 — blocking, `/codeo:implement`'s.** `close_send_back` never sees a send-back in a real `close.md`.
  - Cause: the rule `!f && t ~ /^## / { sendback = 0 }` (`scripts/inflight.sh:209`) resets the flag at `## Log`. Every dossier has `## Log` after `## Outcome` (`docs/dossier.md`, the file's shape), so the `END` block prints nothing.
  - Effect: after review feedback or a conflict send-back from `/codeo:close`, `waits:` falls through to qc's earlier clear verdict and prints `/codeo:close`. That stays wrong both before and after implement answers it, when `/codeo:implement` and then `/codeo:qc` are owed. Triage quotes `waits:`, and *resume* for a quiet workflow names the step it shows.
  - Why it is implement's: the plan's rule is "`close.md`'s last round when it is a send-back", and the code does not do that. The tests miss it because every send-back fixture (`waits_after_review_feedback`, `waits_after_conflicts_with_base`, `waits_after_review_round_rechecked`) ends at the round, with no `## Log`.
  - Needed: the round must end only where `## Outcome` ends or the next `### Round` begins, and the send-back fixtures need a `## Log` section.
- **F13 — non-blocking, `/codeo:plan`'s.** For a quiet workflow, *resume* says to "name the step its `waits:` line shows" (`skills/triage/SKILL.md`, parked-work options and step 5's **Resume**). That has no step to name when `waits:` is `engineer — …`, `review — dossier archived` or `nothing known`. It also has none for an unassigned workflow that has no stash and is not over the threshold, because it is not "raised only for its age".
- **F14 — non-blocking, `/codeo:plan`'s.** An unassigned workflow is asked about whatever its date, and its fingerprint `parked:<N>:<touched date>` changes with every push. So an active, unassigned workflow is asked about again after each touch, and a dismissal does not hold. Q4 chose to ask about an unassigned workflow; how long a dismissal of one lasts was left open.
- **F15 — non-blocking, `/codeo:implement`'s.** `waits_of` calls `claim.sh --stash-live "$n" "$branch" .` (`scripts/inflight.sh:236`). `claim.sh` reads `.codeo/<N>/` from the repository root, but `inflight.sh` finds dossiers under `$state_rel`, which carries a `projectPath` prefix. In a project kept in a subdirectory, a live stash would never be seen, and the board table would flag the card's correct Ready as a mismatch. The limit is in `claim.sh` and predates this change; this change adds a caller that inherits it.
- **F16 — non-blocking, `/codeo:plan`'s.** For a close send-back round with no `qc round at review:` line, `waits:` stays `/codeo:qc` even after qc re-grades. The plan says so explicitly ("Without one, C2 reads 'no'"). `/codeo:close` always writes the line, so only an older or hand-edited dossier would hit this.
- **F17 — non-blocking, `/codeo:implement`'s.** `verdict_of` (`scripts/inflight.sh:177`) does not strip CR, unlike the other new readers. A Verdict span wrapped over two CRLF lines keeps a `\r` in the printed `verdict:` line.

**Routing.** F12 is the one blocking finding. It is a defect in code that does not do what the plan says, so it goes back to `/codeo:implement`. F15 and F17 are the implementer's too and can ride along. F13, F14 and F16 are the plan's: they are recorded here for `/codeo:triage` or a later plan round, and on their own they do not send the change back.

**Verdict: back to `/codeo:implement`.**

## Log

- 2026-11-17 — qc round 1: build exit 0, `bash tests/run.sh` all cases passed, all 8 criteria met, F1-F2 blocking (plan's), back to /codeo:plan · cost: 12m · opus-5-5 140k in + 5M cached / 21k out
- 2026-11-17 — qc round 2: build exit 0, `bash tests/run.sh` all cases passed, all 8 criteria met, F12 blocking (implement's), back to /codeo:implement · cost: 5m · opus-5-5 224k in + 4M cached / 24k out
