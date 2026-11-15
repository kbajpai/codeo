# Issue #97 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/97 |
| Branch | `docs/docs-skill-wording-test-guard` |
| Updated | 2026-11-15 |

## Where this stands

Round 3, done (after a second send-back from `/codeo:qc`, round 2). Tasks 1-5 of the round-3 plan are built and reviewed (`cc04ebf`..`2f7a37e`), the build and the full suite pass, and nothing is open. The next step is `/codeo:qc`.

## Questions

### Q1 — #70 has now changed `skills/plan/SKILL.md`, `skills/triage/SKILL.md` and `tests/plan-skill.test.sh` on its branch. Proceed, sequence or re-scope?

**Why it matters:** #70 (`feat/guard-home-only-skills-against`, assigned to kbajpai, now at `implement`, working) has added a role-guard step to the head of `## Workflow` and a sentence to step 4 in `skills/plan/SKILL.md`, ten lines to `skills/triage/SKILL.md`, and four lines to `tests/plan-skill.test.sh`. The overlap check names it as `#70` with `skills/plan/SKILL.md`, `skills/triage/SKILL.md` and `tests/plan-skill.test.sh`. This issue's Task 3 changes one line of `skills/triage/SKILL.md` (the "adds the issue to the board" sentence, ~220), and Task 9 rewrites step 8's host-task paragraph and step 10's send-back paragraph in `skills/plan/SKILL.md` and their pins in `tests/plan-skill.test.sh`. The hunks are in different places, so the second branch to merge should rebase cleanly; sequencing would make Task 9 wait for #70 on top of its existing wait for #98 (now at `qc`). Q3 of the plan already answered *proceed and coordinate* for #70's wider overlap; this is the same pair with three more paths.
**Options:** proceed and coordinate · sequence after #70 · re-scope. **Recommendation:** proceed and coordinate, as Q3 did: build Tasks 1-8 now, and read both #98's and #70's merged text before Task 9.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-15: "go with the recommendation").

### Q2 — #70's footprint now covers four more test files this issue has changed. Proceed, sequence or re-scope?

**Why it matters:** raised by the overlap check run after Task 6 and the merge of `origin/main` (which brought in #98). #70 (`feat/guard-home-only-skills-against`, assigned to kbajpai, now at `qc`, working) prints as `#70` with `tests/board.test.sh`, `tests/overlap.test.sh`, `tests/qc-verdict.test.sh` and `tests/skills-doc.test.sh`. None of the four is changed on #70's branch: they are paired only because #70's `files` list has the glob `tests/**` and Tasks 1, 3, 4, 5 and 6 here changed them. Q3 of the plan and Q1 here already answered *proceed and coordinate* for #70 and `tests/**`, and its qc is nearly done, so the second to merge rebases. No sequencing is needed unless #70's QC adds edits to those four files.
**Options:** proceed and coordinate · sequence after #70 · re-scope. **Recommendation:** proceed and coordinate, as Q1.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-15).

### Q3 — #70's `tests/**` glob now pairs with `tests/close-skill.test.sh`, which Task 7 changed. Proceed, sequence or re-scope?

**Why it matters:** raised by the overlap check run before Task 9. #70 (`feat/guard-home-only-skills-against`, assigned to kbajpai, at `qc`, working) prints as `#70` with `tests/close-skill.test.sh`. Task 7 added pins for close step 17's lead and the two abandon blocks there; #70's `files` list has the glob `tests/**`, and its branch also changes `skills/close/SKILL.md`, so a pin in this file could collide with one #70 adds for its own step 17 text. Q1 and Q2 answered *proceed and coordinate* for #70's other paths. The remaining tasks (9, 10) change only `skills/plan/SKILL.md`, `tests/plan-skill.test.sh`, `docs/dossier.md` and `CHANGELOG.md`, each already named in an answered question, so no further pairing with #70 is expected.
**Options:** proceed and coordinate · sequence after #70 · re-scope. **Recommendation:** proceed and coordinate, as Q1 and Q2.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-15).

## Notes

## Outcome

2026-11-15

**Built.** All ten tasks of `docs/plans/2026-11-15-docs-skill-wording-test-guard.md`, each reviewed by a fresh reviewer on the subagent model; Tasks 6 and 9 each took one fix round. Commits `ce0b13d`..`3fd6bd8` on this branch, with `origin/main` (carrying #98) merged at `1bf8458`.

- Task 1 `tests/skills-doc.test.sh`: fenced lines in an Extension points part are not counted, a skill name is matched literally, missing/extra output is sorted (`LC_ALL=C`), with three new cases.
- Task 2 `docs/skills.md`: `doctor` Reads lists the extension-point registry, the installed-plugins file, the PATH checks and the `ci.requiredChecks` fallback; `qc` mentions the sync merge commit.
- Task 3 `scripts/board.sh`, `tests/board.test.sh`, `lib/env.sh`, `skills/triage/SKILL.md`: "no synced project has the option …", a title read is not an add, a failed removal gives its reason, the `undo-fails` case asserts `item-delete`, a case with `board.statuses` absent, the bash 4.3 idiom commented; two descriptions corrected.
- Task 4 `scripts/board.sh`: `lookup` uses `gh api graphql --paginate`; `board.sh status 97` ran against GitHub and printed `In progress`.
- Task 5 `scripts/overlap.sh`: `--outside <N> [--base <ref>] [--head <ref>]`.
- Task 6 `scripts/qc-verdict.sh`: fails a pull request whose archived `plan.md` has a `### Round 2` or later and whose footprint omits a path `overlap.sh --outside` prints; a failed `overlap.sh` is reported by name and collected.
- Task 7 `skills/close/SKILL.md` and its tests: `abandon finished` and `abandon interrupted` closing blocks, step 17's lead conditioned, guards shown to bite against a copy with the old sentences restored.
- Task 8 `docs/handoff.md` and `tests/closing-exits.test.sh`: the abandon among close's exits, rows for both abandon exits and `issue — Status unreadable`, the reworded `init — no lock` row, the replacing-footprint and required-check sentences; FAIL lines to stderr, the empty-`step` guard, the missing-row message.
- Task 9 `skills/plan/SKILL.md`, `tests/plan-skill.test.sh`, `docs/dossier.md`: on a send-back pass sub-step 1 removes the earlier block and runs `overlap.sh --outside`; step 8's host-task paragraph is consistent; pins and `must_lack`/`must_order` helpers.
- Task 10 `CHANGELOG.md`: the v1.0.4 entry corrected and one `## Unreleased` bullet.

**Build.** The `shell` suite's build command is `true` and exits 0; `bash tests/run.sh` prints `all cases passed`. No shared environment is configured: no lease taken, nothing deployed.

**Documentation pages changed.** `docs/skills.md`, `docs/handoff.md`, `docs/dossier.md`, `lib/env.sh`'s key reference, `skills/triage/SKILL.md`, `CHANGELOG.md`.

**Deviations from the plan.** `board.sh`'s header comment and one existing `tests/board.test.sh` assertion pinned the old "is on has the option" wording and were updated with the message (Task 3). Task 9 relaxed one pin (`is marked with a line`, with `Runs on: the engineer's host` still pinned) because the rewrap splits the old quote across lines. `tests/closing-exits.test.sh` lost its executable bit in Task 7 and regained it in Task 8. `sync-main.sh` of the installed plugin (1.0.6) exits 1 after a clean merge because of the `comm` locale bug #98 fixed; the merge itself committed.

**Minors left for `/codeo:qc`** (reviewers' non-blocking notes; none fixed): `qc-verdict.sh` matches `/^## Outcome/` without anchoring, so `## Outcomes` would match; no `qc-verdict` case for a PR that only adds files under `docs/plans` and `.codeo`, nor for a `### Round 2` outside `## Outcome`; `overlap.sh`'s `changes()` swallows git errors for a mistyped `--base` or `--head` (`qc-verdict` passes refs it resolved itself); `overlap.sh`'s non-`done/` plan path under `--head` is untested; `tests/board.test.sh`'s `title-read-fails` does not assert the exit code; step 17's lead and the sub-step 1 sentence in step 10 are long single lines because their pins are single-line; `row_for` in `tests/closing-exits.test.sh` matches a label's suffix only; the `RETURN` trap in `bites` stays set; two consecutive "On a pass after a send-back" sentences in step 10.

`Deployed revision:` none: no environment.


### Round 2

2026-11-15
(send-back from qc.md round 1)

**Built.** All five tasks of `docs/plans/2026-11-15-docs-skill-wording-test-guard-round-2.md`, each reviewed by a fresh reviewer on the subagent model, none needing a fix round. Commits `eb399da`..`5a1306b`; `origin/main` had not moved, so nothing was merged.

- Task 1 `tests/closing-exits.test.sh` (F1, F2): `flat` joins a text's lines; `case_close_step17_lead` and `case_stash_prose` now also refuse step 17's old ending ("End with the closing block: the goal is the loose ends found") and the old stash sentence and ending, and `case_bites` restores each of them with the line break the original text had; each mutation fails its case by name before the guard and after.
- Task 2 `skills/close/SKILL.md`, `tests/closing-exits.test.sh` (F6): the abandon-finished block says the card is at `$BACKLOG` with a board and that with no board there is no card.
- Task 3 `skills/qc/SKILL.md`, `tests/qc-skill.test.sh`, `docs/skills.md` (F3, Q7 (a)): a changed path outside the footprint is non-blocking on a first-round plan and blocking, `/codeo:plan`'s, once `plan.md`'s `## Outcome` has a `### Round 2` or later; three pins, shown to bite against `origin/main`'s skill; the `qc` entry says so.
- Task 4 `skills/plan/SKILL.md`, `tests/plan-skill.test.sh` (F4, F5): step 8 says where no language is known the script cannot be neutral and is asked about and labelled; step 10 sub-step 1 no longer repeats where the draft goes.
- Task 5 `scripts/overlap.sh` (header comment only), `CHANGELOG.md` (F7, F9): `--base` alone is described; the `## Unreleased` bullet says when the host-task rule applies and that `qc` blocks a footprint gap from plan round 2.

**Build.** The `shell` suite's build command is `true` and exits 0; `bash tests/run.sh` prints `all cases passed`. No shared environment: no lease, no deploy.

**Documentation pages changed.** `docs/skills.md` (`qc` entry), `skills/qc/SKILL.md`, `skills/plan/SKILL.md`, `skills/close/SKILL.md`, `scripts/overlap.sh`'s header comment, `CHANGELOG.md`.

**Deviations from the plan.** Task 4's `must_lack` pins the fragment `footprint goes under \`## Notes\` again all the same` instead of the full sentence, because the skill wraps the sentence over two lines and a line-based `grep` for the whole sentence could never fail. Task 2's first edit split "with no board" across a line break; the implementer rewrapped it onto one line before committing.

**Minors left for `/codeo:qc`:** `skills/qc/SKILL.md` step 6 does not say how to detect a second round (look for a `### Round <n>` heading with n ≥ 2 in `plan.md`'s `## Outcome`); the Task 4 sentence is a long single line because its pin is single-line; and the minors round 1 recorded stand. Out of scope, as the plan says: F8 (a paging `gh` stub) and F10 (`skills/init/SKILL.md`'s "there is no lock" after any `lock: TODO`), both for `/codeo:triage`.

`Deployed revision:` none: no environment.

### Round 3

2026-11-15
(send-back from qc.md round 2)

**Built.** All five tasks of `docs/plans/2026-11-15-docs-skill-wording-test-guard-round-3.md`, each reviewed by a fresh reviewer on the subagent model, none needing a fix round. Commits `cc04ebf`..`2f7a37e`; `origin/main` had not moved, so nothing was merged.

- Task 1 `scripts/qc-verdict.sh`, `tests/qc-verdict.test.sh`, `docs/handoff.md` (F11): the footprint check runs only for an archive whose `done/<N>/plan.md` the pull request adds or renames into place (`--diff-filter=AR` over `done/*/plan.md`); a pull request that merely edits an old re-planned archive is no longer compared with it. New cases: an old archive that is only touched is not checked (it failed before the fix with `round 2 footprint omits: c.txt`), and an archive renamed into place is checked. QC round 2's reproduction, re-run against the fixed script, now prints `qc-verdict: .codeo/done/7/qc.md: round 1 clear` and exits 0 (it exited 1 before).
- Task 2 `scripts/overlap.sh`, `tests/overlap.test.sh` (F14): a given `--base` or `--head` that does not resolve to a commit makes `overlap.sh --outside` exit 1 with `overlap: cannot resolve <ref>`; the default path, pair mode and `changes()` are unchanged.
- Task 3 `skills/qc/SKILL.md`, `tests/qc-skill.test.sh` (F13): step 6 keeps a round-2 footprint gap blocking, leaves whose it is to step 8's test, and says a second round shows as a `### Round <n>` heading, n ≥ 2, under `plan.md`'s `## Outcome`.
- Task 4 `skills/close/SKILL.md`, `tests/closing-exits.test.sh`, `tests/close-skill.test.sh` (F12): the abandon text and the abandon-finished block are conditioned on the branch being kept; after a deleted branch the checkout is the last copy.
- Task 5 `CHANGELOG.md` (F15, F11): the #97 bullet says the footprint rule judges only an archive a pull request delivers and that the host-task rule is stated consistently, with its condition.

**Build.** The `shell` suite's build command is `true` and exits 0; `bash tests/run.sh` prints `all cases passed`. No shared environment: no lease, no deploy.

**Documentation pages changed.** `docs/handoff.md` (the required-check sentence), `skills/qc/SKILL.md`, `skills/close/SKILL.md`, `scripts/qc-verdict.sh` and `scripts/overlap.sh` header comments, `CHANGELOG.md`.

**Deviations from the plan.** Task 3's "still says" check unwraps the skill text (`tr '\n' ' ' | tr -s ' '`) before matching, because the phrase it forbids wrapped over two lines and a line-based `grep -F` could never fail on it. Task 1's renamed-archive case already passed before the fix (git reports the rename as `R`, which the old code also judged); it stays as a regression guard.

**Minors left for `/codeo:qc`:** the comment above `touched` in `qc-verdict.sh` does not say only delivered archives are footprint-checked; round 2's "still says" check on `and not blocking by rule:` in `tests/qc-skill.test.sh` is line-based and would pass if a later edit wrapped that phrase; awkward hard-wrap breaks around the one-line pins in the abandon text. Out of scope, for `/codeo:triage`: F8 (a paging `gh` stub), F10 (`skills/init/SKILL.md` after a `lock: TODO`), the unanchored `^## Outcome` match in `qc-verdict.sh`.

`Deployed revision:` none: no environment.

## Log

- 2026-11-15 — Q1 raised before dispatch · cost: 3m · sonnet-5-5 11k in + 1M cached / 2k out
- 2026-11-15 — Tasks 1-6 built and reviewed, origin/main merged; Q2 raised before Task 7 · cost: 17m · sonnet-5-5 525k in + 20.2M cached / 80k out
- 2026-11-15 — Tasks 7-8 built and reviewed; Q3 raised before Task 9 · cost: 32m · sonnet-5-5 694k in + 26.8M cached / 114k out
- 2026-11-15 — built Tasks 1-10 (two fix rounds), build ok · cost: 74m · sonnet-5-5 918k in + 37.3M cached / 158k out
- 2026-11-15 — round 2: built the five round-2 tasks (no fix rounds), build ok · cost: 14m · sonnet-5-5 341k in + 18.8M cached / 44k out
- 2026-11-15 — round 3: built the five round-3 tasks (no fix rounds), build ok · cost: 13m · sonnet-5-5 377k in + 22.6M cached / 52k out
