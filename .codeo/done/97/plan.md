# Issue #97 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/97 |
| Branch | `docs/docs-skill-wording-test-guard` |
| Updated | 2026-11-15 |

## Where this stands

Round 3, done. The round-3 plan was approved and written to `docs/plans/2026-11-15-docs-skill-wording-test-guard-round-3.md`; nothing is open. The next step is `/codeo:implement`.

## Questions

### Q1 — Where does the mechanical check on a re-planned footprint live?

**Why it matters:** `tests/overlap.test.sh` (lines 289-300) already proves that `overlap.sh --outside` prints round 1's paths when round 2's block omits them. What nothing does is fail when a real dossier's second-round `### Footprint` omits a path its branch still changes: `dossier-check.sh` judges shape only and never runs `overlap.sh`. The choice decides which script gains the check, which fixtures and tests are written, and whether a planner who skips the skill's sentence is caught before merge or only in a test.
**Options:**
- **(a) `qc-verdict.sh`, recommended.** It already runs as the required `qc-verdict` check on every pull request and fails closed on a dossier problem. It would also fail when the head's archived `plan.md` leaves a path `overlap.sh --outside <N>` prints. The one real check; I have not yet verified that `overlap.sh` can run in CI's checkout (it reads `origin/<base>...HEAD` and `done/<N>/plan.md`), and will read both before drafting the task.
- **(b) `dossier-check.sh` gains a branch-aware mode** that calls `overlap.sh --outside`. It is a shape-only, config-free script today, so this changes its character, and CI does not run it on real dossiers, only on fixtures.
- **(c) A fixture test only**, in `tests/overlap.test.sh` or `tests/dossier-check.test.sh`: a second-round dossier that omits a path must fail. Meets the acceptance criterion literally and is the smallest change, but a real planning pass that skips the rule is still caught by nobody.

**Answer:**
(a) `qc-verdict.sh`. Go with the recommendation (engineer, in the conversation, 2026-11-15: "go ahead"). Feasibility in CI is checked before the task is drafted.

### Q2 — #98 also edits `skills/plan/SKILL.md`, `tests/plan-skill.test.sh`, `docs/dossier.md` and `CHANGELOG.md`. Proceed, sequence or re-scope?

**Why it matters:** #98 (`fix/fix-sync-main-sh-exiting`, assigned to kbajpai, at `implement`, working) has already changed `CHANGELOG.md`, `docs/dossier.md`, `skills/plan/SKILL.md` and `tests/plan-skill.test.sh` on its branch, and its footprint lists the same four. Overlap tokens: `CHANGELOG.md`, `docs/dossier.md`, `skills/plan/SKILL.md`, `tests/plan-skill.test.sh`, `glob:CHANGELOG.md`, `glob:docs/dossier.md`, `glob:skills/plan/SKILL.md`, `glob:tests/plan-skill.test.sh`. This issue rewrites step 8's host-task paragraph and step 10's send-back paragraph in the same skill and pins both in `tests/plan-skill.test.sh`. Sequencing puts those tasks on top of #98's text; proceeding means whoever merges second rebases.
**Options:** proceed and coordinate · sequence after #98 · re-scope. **Recommendation:** sequence after #98, for the `skills/plan/SKILL.md` and `tests/plan-skill.test.sh` tasks only (ordered last in the plan): it is nearest to merging and the same pin tests move under both.

**Answer:**
Sequence after #98 for the `skills/plan/SKILL.md` and `tests/plan-skill.test.sh` tasks, ordered last. Go with the recommendation (engineer, in the conversation, 2026-11-15: "go ahead").

### Q3 — #70 also edits `skills/**`, `tests/**`, `docs/handoff.md`, `docs/skills.md` and `CHANGELOG.md`, and `skills/close/SKILL.md` step 17 in particular. Proceed, sequence or re-scope?

**Why it matters:** #70 (`feat/guard-home-only-skills-against`, assigned to kbajpai, at `plan`, working, planned but not yet built) overlaps on `glob:skills/**`, `glob:tests/**`, `glob:docs/handoff.md`, `glob:docs/skills.md` and `glob:CHANGELOG.md`. Its plan changes close step 17's removal commands and the handoff lock section; this issue rewrites step 17's lead, adds the abandon blocks beside it, and adds exception-table rows to `docs/handoff.md`. The issue says no sequence is promised and this check raises it. Both can be written independently; the second to merge rebases the same paragraph.
**Options:** proceed and coordinate · sequence after #70 · re-scope. **Recommendation:** proceed and coordinate, with the `skills/close/SKILL.md`, `docs/handoff.md` and `tests/closing-exits.test.sh` tasks ordered last in the plan, so most of the work does not wait on #70.

**Answer:**
Proceed and coordinate; the close, handoff and `tests/closing-exits.test.sh` tasks ordered last. Go with the recommendation (engineer, in the conversation, 2026-11-15: "go ahead").

### Q4 — #71 also edits `scripts/board.sh`, `skills/triage/SKILL.md`, `tests/closing-exits.test.sh`, `docs/handoff.md`, `docs/skills.md` and `CHANGELOG.md`. Proceed, sequence or re-scope?

**Why it matters:** #71 (`feat/file-new-issues-straight-board`, assigned to kbajpai, at `init`, no plan yet) lists `glob:scripts/board.sh`, `glob:skills/triage/SKILL.md`, `glob:tests/closing-exits.test.sh`, `glob:docs/handoff.md`, `glob:docs/skills.md` and `glob:CHANGELOG.md`. It has no plan and no diff to compare, so the real size of the overlap is unknown. `scripts/board.sh` matters most: this issue changes its failure messages and its 50-item lookup in `set`, and a feature that files issues onto the board likely touches the same function.
**Options:** proceed and coordinate · sequence after #71 · re-scope. **Recommendation:** proceed and coordinate; #71 has not planned yet, so its plan can name this issue's `board.sh` change when it reaches its own footprint check.

**Answer:**
Proceed and coordinate. Go with the recommendation (engineer, in the conversation, 2026-11-15: "go ahead").

### Q5 — #96 also edits `lib/env.sh` and `CHANGELOG.md`. Proceed, sequence or re-scope?

**Why it matters:** #96 (`feat/dev-container-follow-ups-40`, assigned to kbajpai, at `plan`, working) lists `glob:lib/env.sh` and `glob:CHANGELOG.md`. This issue changes one comment line in `lib/env.sh` (the `statuses` key reference, lines 28-31) and #96 changes the key reference for `plugin`, a different line; both add a bullet under `## Unreleased`. A sequence would not buy anything.
**Options:** proceed and coordinate · sequence after #96 · re-scope. **Recommendation:** proceed and coordinate.

**Answer:**
Proceed and coordinate. Go with the recommendation (engineer, in the conversation, 2026-11-15: "go ahead").

### Q6 — #71 has since added `tests/board.test.sh` to its footprint, beside `scripts/board.sh`. Proceed, sequence or re-scope?

**Why it matters:** raised by the overlap check run while drafting the plan. #71 (`feat/file-new-issues-straight-board`, assigned to kbajpai, now at `plan`, working) lists `glob:tests/board.test.sh` as well as the `glob:scripts/board.sh` Q4 already covered. Tasks 3 and 4 of the draft change `board.sh set`'s messages and lookup and add five cases and two stub variables to `tests/board.test.sh`; a feature that files issues straight onto the board probably extends the same stub, so the two edits would collide in one file. Q4 was answered *proceed and coordinate* when #71 had no plan; this is the same pair with more detail.
**Options:** proceed and coordinate · sequence after #71 · re-scope. **Recommendation:** proceed and coordinate, as Q4: Tasks 3-4 add only new stub variables and new cases, and whichever of the two merges second rebases.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-15).

### Q7 — Once a plan has a second round, is a changed path outside the footprint blocking in `/codeo:qc`, and where does the recovery go?

**Why it matters:** round 2, answering the send-back from `qc.md` round 1 (F3). `skills/qc/SKILL.md` step 6 says every path `overlap.sh --outside <N>` prints is "not blocking by rule", but round 1's Task 6 made the required `qc-verdict` check fail a pull request on exactly those paths when the archived `plan.md` has a `### Round 2` or later. As built, `qc` can clear a change, `/codeo:close` opens the pull request, and the required check then fails on a footprint that sits in an answered, archived round, with no skill saying what to do. The answer decides which skill texts this round changes and what `qc-verdict` keeps enforcing.
**Options:**
- **(a) `qc` blocks it, recommended.** In `skills/qc/SKILL.md` step 6: when `plan.md` has a `### Round 2` or later, each `--outside` path is a blocking finding, `/codeo:plan`'s, because the pull request cannot merge with it; a one-round plan keeps today's non-blocking rule. The footprint is then corrected by a new plan round (the normal send-back) before any pull request exists, and `qc-verdict` stays as the backstop. Changes `skills/qc/SKILL.md`, its pin in `tests/qc-skill.test.sh` and the `qc` entry of `docs/skills.md`.
- **(b) (a), plus `/codeo:close` names the recovery** when the check fails anyway (a path added after `qc` cleared): a send-back to `/codeo:plan`. Covers the last gap, but edits `skills/close/SKILL.md` again, where #70 is also working.
- **(c) Drop the `qc-verdict` rule** and keep only a fixture test. Removes the conflict, and with it the enforcement Q1 chose.

**Answer:**
(a) `qc` blocks it. Go with the recommendation (engineer, in the conversation, 2026-11-15).

## Notes

What exploration found, so the plan does not re-ask it.

**Settled before this pass.** #43's intake Q1 (50-item `board.sh set` lookup) was answered *include it as a requirement*, and its Q2 left the footprint check's location to this plan (Q1 above). No board, wiki, shared environment, invariants document or `resources[]` is configured, so the plan has no lease task, no wiki task and no exclusive lock. The one suite is `shell` (`bash tests/run.sh`, build `true`); every task's proof is a named test file run through `bash tests/run.sh <file-name-fragment>`.

**#41.** `tests/skills-doc.test.sh`: the Extension points `N`/`B` rule has no `!fence` condition; missing/extra point lines iterate `${!wc[@]}` and `${!gc[@]}`, which is unordered; line ~84 interpolates `$s` into `=~` unescaped. No case covers a fenced bullet, a metacharacter name or output order. `docs/skills.md`: `doctor` (lines ~266-267) omits `lib/extension-points.tsv` (`doctor.sh:194`), the installed-plugins file (`doctor.sh:240`), the `command -v` PATH checks (`gh`, suite commands, `jq`, `git`, bash version) and the `ci.requiredChecks` fallback to `tests` and `qc-verdict` (`doctor.sh:128-129`); `qc` says it "pushes its own dossier commits and nothing else", where `skills/qc/SKILL.md:507-509` says the step-2 sync merge rides the same push.

**#43.** `scripts/board.sh set`: the "no project … is on has the option" message (line 282) fires when every synced project lacks the option, so "is on" is wrong whether or not the issue is on a board; the failed title read (214-220) reuses the add-failure text; the delete (270) sends stderr to `/dev/null`; the lookup is `projectItems(first:50)` on the issue with no pagination, so a card past the 50th reads as absent, `item-add` returns the existing item, `fresh` is set, and a failed write deletes a card that was already there. `tests/board.test.sh`: no case omits `statuses`; `undo-fails` (245-257) asserts no log line; the stub returns `GH_STUB_ROWS` whatever the query, so a pagination case needs the stub extended. The "bash 4.3 guard" is the `${probed[@]+"${probed[@]}"}` idiom at line 248, uncommented; `doctor.sh` already requires bash ≥ 4.3.

**#74.** `skills/close/SKILL.md`: the abandon section (about 634-663) has no closing block, and the lock is deleted last, kept on a failed deletion. Existing labels: `finished` (530), `lock kept` (533), `stash interrupted` (623), `stash completed` (628). `docs/handoff.md` lists close's exits at 351-353 without the abandon and has no `abandon` or `issue — Status unreadable` row; the `init — no lock` row (384) names `lock.sh take local` unconditionally, though `lock.sh` prints `lock: TODO` after taking the lock on `host: container` when the volume name cannot be read. `tests/closing-exits.test.sh`: `case_init_no_lock` (107-115) passes on an empty `step` result; a missing `init — no lock` row fails with `no [init — no lock]` then `no [lock.sh take local]`. `tests/close-skill.test.sh` has an env override (`CLOSE_SKILL`) that makes the "bites against a mutated copy" proof possible there; `closing-exits.test.sh` has none.

**My calls, to be shown again at the review gate (no question needed):**

- *Pagination.* `lookup` gains a cursor loop over `projectItems` (`pageInfo`, `after`), and the `gh` stub is extended to answer pages; the failed-write case on a card beyond item 50 asserts no `item-delete`.
- *Bash 4.3.* The idiom stays: `doctor.sh` requires bash ≥ 4.3 and `board.sh` is where it matters. It cannot be proved here, because a bash 5 container accepts `${arr[@]}` on an empty array under `set -u`, so the plan adds the explanatory comment `github.sh:189` already has and dismisses the "prove it" half with that reason.
- *Abandon blocks.* `**Closing block — abandon finished:**` (lock deleted: the goal is the next piece of work or the loose ends; first step `/codeo:triage`, then the host's checkout clean-up as step 17 relays it) and `**Closing block — abandon interrupted:**` (lock kept: first step `/codeo:close`, run again in this checkout; names what failed). Neither names `/codeo:init #<N>` or `/codeo:close --stash`. Two matching rows in `docs/handoff.md`'s exceptions table, plus `issue — Status unreadable` (first step: the fix its line names) and a reworded `init — no lock` row.
- *Step 17 lead.* "Report that the workflow is finished." becomes a conditioned lead (finished only when step 16 deleted `.codeo/active`), and `tests/closing-exits.test.sh` gains a `lacks` check on the old unconditional sentences in step 17 and the stash prose, proved against a mutated copy through a new root override.
- *`init — no lock` and the empty `step` guard.* The guard gets an `-n` check as `issue_step8` has; the missing-row message says the row is gone.
- *Left minors.* Fixed: the step-17 lead, the empty-`step` guard, the missing-row message, the host-task paragraph's wrapping and overlap (rewritten anyway), `closing-exits.test.sh` FAIL lines to stderr as `closing-block.test.sh` does (no effect on `run.sh`, which merges both streams). Dismissed: long lines in `skills/issue/SKILL.md` (line 3 is frontmatter and cannot wrap; 177-181 are closing-block paragraphs, a rewrap is churn in a file #71 also edits); `docs/skills.md` lines that do not enumerate every exit (the page defers to `docs/handoff.md → Closing block`, which Q3's task completes).
- *One pull request.* The three parts are separable but share `docs/skills.md`, `docs/handoff.md`, `CHANGELOG.md` and one branch; the issue is one planning pass.

**Round 2 (send-back from `qc.md` round 1).** The code follows round 1's plan; three blocking findings are the plan's.

- *F1.* Task 7 guarded step 17's old lead; the sentence #74 and #69's qc G2 name is the old ending, "End with the closing block: the goal is the loose ends found, the first step `/codeo:triage`, then the host's checkout clean-up above." (`skills/close/SKILL.md` before `2a86915`, lines 524-525). Round 2 guards that sentence too, and keeps the lead guard.
- *F2.* The old stash text wrapped: "Report that `/codeo:init #<N>`" / "resumes it, on any machine." and ended "End with the closing block: the goal is resuming the work, the first step `/codeo:init #<N>`." (lines 607-611). Round 2 matches both with line breaks joined, and `bites` restores each sentence as it was wrapped.
- *F3.* Q7.
- *Non-blocking, taken (small, in files the round already edits):* F4 (restore "where no such language is known, ask and label `Shell: <name>`" in step 8), F5 (drop the repeated "goes under `## Notes` again" sentence in step 10), F6 (the abandon-finished block allows for no board), F7 (`overlap.sh` header says what `--base` alone does), F9 (the changelog entry states when the host-task rule applies).
- *Non-blocking, left:* F8 (the stub cannot page; a paging stub is a larger rewrite of a file #71 is editing, and the flag assertion already bites); F10 (`skills/init/SKILL.md` saying "there is no lock" after any `lock: TODO` is a behaviour question for `init`, outside this issue; it stays recorded in `qc.md` for `/codeo:triage`); the minors carried from `implement.md`.

**Round 3 (send-back from `qc.md` round 2).** All twenty criteria are met; one blocking finding, the plan's. No question is needed: each fix below follows from the finding and from answers already given (Q1, Q7).

- *F11.* Round 1's Task 6 scoped the footprint rule to "an archive the diff touches", so a pull request that merely edits an old re-planned archive is compared with it and fails. Round 3 scopes it to an archive whose `plan.md` the diff adds or renames into place, which is what `/codeo:close`'s archive commit produces, with a case for each side.
- *F14, taken.* `overlap.sh`'s `changes()` swallows git errors, so a `--base`/`--head` that does not resolve makes the required check pass; a given ref that does not resolve becomes an error.
- *F13, taken.* `qc` step 6 said a round-2 gap is always the plan's; whose it is follows step 8 (a stray edit is `/codeo:implement`'s to revert). The step also says how a second round is recognised.
- *F12, taken.* The abandon text is conditioned on the branch being kept.
- *F15, taken.* The changelog entry is reworded so the host-task rule does not read as new, and so the footprint rule's scope matches F11's fix.
- *Left:* F8, F10 and the unanchored `^## Outcome` match, recorded in `qc.md` for `/codeo:triage`.

## Outcome

2026-11-15

**Plan:** `docs/plans/2026-11-15-docs-skill-wording-test-guard.md`, a scoped executable plan (ten tasks, one pull request), approved by the engineer and left unstaged. No reference doc under `docs/`: nothing here is a standing decision beyond what the plan's tasks write into the pages below.

**Decisions.** Q1 the re-planned-footprint rule is enforced by `qc-verdict.sh`, scoped to archived plans with a `### Round 2` or later, through a new optional `--base`/`--head` on `overlap.sh --outside` (CI's checkout was read: `qc-verdict` runs with full history and is handed the merge base and head). Q2 the `skills/plan/SKILL.md` and `tests/plan-skill.test.sh` tasks wait for #98 to merge. Q3, Q4, Q6 proceed and coordinate with #70 and #71, the close, handoff and board tasks ordered last. Q5 proceed with #96. Calls made in the plan, shown at the gate: `gh api --paginate` for the 50-item lookup, observable in the stub only by its flag; the bash 4.3 idiom kept and commented, not tested; step 10's `--outside` check moved to sub-step 1 by making the earlier block's removal the first edit of a send-back pass; abandon-finished names `/codeo:triage` and abandon-interrupted names `/codeo:close`, neither naming `/codeo:init #<N>` or `/codeo:close --stash`.

**Rejected.** A branch-aware `dossier-check.sh` (it is config-free and shape-only, and CI does not run it on real dossiers); a fixture test only (it protects no real planning pass); three pull requests; proving the bash 4.3 guard (a newer bash cannot show it biting); fixing `skills/issue/SKILL.md`'s long lines and enumerating every exit in `docs/skills.md` (dismissed with reasons in the plan's Self-Review).

**Documentation.** `docs/skills.md` (`doctor`, `qc`, `close`), `docs/handoff.md` (exits, rows, the replacing-footprint sentence, the `qc-verdict` check), `docs/dossier.md` (when the footprint check runs), `lib/env.sh`'s key reference, `skills/triage/SKILL.md`, `CHANGELOG.md`. No wiki module or invariants document.

**Intake.** #43's Q1 (the 50-item lookup) was already answered at filing: a requirement. #70's overlap, which `init.md` left open, is resolved by Q3.


### Round 2

2026-11-15
(send-back from qc.md round 1)

**Plan:** `docs/plans/2026-11-15-docs-skill-wording-test-guard-round-2.md`, a five-task plan approved by the engineer and left unstaged; round 1's plan file stays as built. No reference doc.

**Decisions.** Q7 (a): `/codeo:qc` treats a changed path outside the footprint as blocking, and `/codeo:plan`'s, once `plan.md` has a `### Round 2` or later, so the footprint is corrected by a new plan round before any pull request exists and `qc-verdict` stays the backstop; a first-round plan keeps the non-blocking rule. F1 and F2 (the #74 guards) are rebuilt to catch the old step 17 ending and the old stash sentences with line breaks joined, shown to bite when restored as they were originally wrapped. Taken as small fixes: F4 and F5 (plan skill), F6 (abandon-finished allows for no board), F7 (`overlap.sh --base` alone), F9 (the changelog's trigger condition).

**Rejected.** (b) `/codeo:close` naming a recovery as well (edits `skills/close/SKILL.md` again, where #70 works, for a case (a) already prevents); (c) dropping the `qc-verdict` rule (removes the Q1 enforcement). Left out, with reasons in the plan's constraints: F8, a paging `gh` stub (a larger rewrite of a file #71 edits, and the `--paginate` assertion bites); F10, `skills/init/SKILL.md`'s "there is no lock" after any `lock: TODO` (`init`'s behaviour; recorded in `qc.md` for `/codeo:triage`).

**Documentation.** `docs/skills.md` (`qc` entry), `skills/qc/SKILL.md`, `skills/plan/SKILL.md`, `skills/close/SKILL.md`, `scripts/overlap.sh`'s header comment, `CHANGELOG.md`. No wiki module or invariants document.

**Intake.** None resolved this round.

### Round 3

2026-11-15
(send-back from qc.md round 2)

**Plan:** `docs/plans/2026-11-15-docs-skill-wording-test-guard-round-3.md`, a five-task plan approved by the engineer and left unstaged; the earlier plan files stay as built. No reference doc.

**Decisions.** F11: the `qc-verdict` footprint rule judges only an archive whose `plan.md` the pull request adds or renames into place (`--diff-filter=AR`), so a pull request that merely edits an old re-planned archive is not compared with it; `docs/handoff.md` says so. F14: a given `--base`/`--head` that does not resolve makes `overlap.sh --outside` exit 1, so the required check cannot pass on a failed diff. F13: `/codeo:qc` step 6 keeps a round-2 footprint gap blocking but leaves whose it is to step 8's test (a stray edit is `/codeo:implement`'s to revert, a file the work needs is `/codeo:plan`'s), and says how a second round is recognised. F12: the abandon text is conditioned on the branch being kept. F15: the changelog entry is reworded.

**Rejected.** Keeping the rule scoped to "an archive the diff touches" with an allow-list of old plans (the failing PRs would still need editing an archive); exempting archives older than the union rule by date (a heuristic the dossier format does not carry). Left out, with reasons in `qc.md`: F8 (a paging `gh` stub), F10 (`skills/init/SKILL.md` after a `lock: TODO`), the unanchored `## Outcome` match in `qc-verdict.sh`.

**Documentation.** `docs/handoff.md` (the required-check sentence), `skills/qc/SKILL.md`, `skills/close/SKILL.md`, `scripts/qc-verdict.sh` and `scripts/overlap.sh` header comments, `CHANGELOG.md`. No wiki module or invariants document.

**Intake.** None resolved this round.

### Footprint

```
files:      docs/skills.md, tests/skills-doc.test.sh, scripts/board.sh, tests/board.test.sh, lib/env.sh, skills/triage/SKILL.md, scripts/qc-verdict.sh, scripts/overlap.sh, tests/qc-verdict.test.sh, tests/overlap.test.sh, skills/plan/SKILL.md, tests/plan-skill.test.sh, skills/close/SKILL.md, tests/closing-exits.test.sh, tests/close-skill.test.sh, docs/handoff.md, docs/dossier.md, CHANGELOG.md, skills/qc/SKILL.md, tests/qc-skill.test.sh, docs/plans/2026-11-15-docs-skill-wording-test-guard.md, docs/plans/2026-11-15-docs-skill-wording-test-guard-round-2.md, docs/plans/2026-11-15-docs-skill-wording-test-guard-round-3.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log
- 2026-11-15 — Q1-Q5 raised · cost: 3m · fable-5-2 95k in + 591k cached / 7k out · sonnet-5-5 292k in + 1.5M cached / 35k out
- 2026-11-15 — Q1-Q5 answered in the conversation; plan drafted at .codeo/97/plan-draft.md, awaiting approval · engineering:architecture and engineering:system-design not loaded, Q1's Options/Decision structure applied directly · cost: 12m · fable-5-2 95k in + 591k cached / 7k out · sonnet-5-5 372k in + 3.4M cached / 83k out
- 2026-11-15 — planned: docs/plans/2026-11-15-docs-skill-wording-test-guard.md · engineering:architecture and engineering:system-design not loaded, Q1's Options/Decision structure applied directly · cost: 27m · fable-5-2 95k in + 591k cached / 7k out · sonnet-5-5 378k in + 4.8M cached / 90k out
- 2026-11-15 — round 2 after qc.md round 1: Q7 raised · cost: 1m · fable-5-2 420k in + 468k cached / 5k out
- 2026-11-15 — planned round 2: docs/plans/2026-11-15-docs-skill-wording-test-guard-round-2.md (send-back from qc.md round 1) · engineering:architecture and engineering:system-design not loaded, Q7's options applied directly · cost: 8m · fable-5-2 423k in + 1.4M cached / 6k out · sonnet-5-5 34k in + 2.3M cached / 14k out
- 2026-11-15 — round 3 after qc.md round 2: plan drafted at .codeo/97/plan-draft.md, awaiting approval · cost: 1m · fable-5-2 533k in + 580k cached / 9k out
- 2026-11-15 — planned round 3: docs/plans/2026-11-15-docs-skill-wording-test-guard-round-3.md (send-back from qc.md round 2) · engineering:architecture and engineering:system-design not loaded · cost: 8m · fable-5-2 541k in + 1.7M cached / 11k out
