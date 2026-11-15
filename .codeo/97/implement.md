# Issue #97 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/97 |
| Branch | `docs/docs-skill-wording-test-guard` |
| Updated | 2026-11-15 |

## Where this stands

Round 1, done. Q1-Q3 are answered, Tasks 1-10 are built and reviewed (`ce0b13d`..`3fd6bd8`), the build and the full suite pass, and nothing is open. The next step is `/codeo:qc`.

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

## Log

- 2026-11-15 — Q1 raised before dispatch · cost: 3m · sonnet-5-5 11k in + 1M cached / 2k out
- 2026-11-15 — Tasks 1-6 built and reviewed, origin/main merged; Q2 raised before Task 7 · cost: 17m · sonnet-5-5 525k in + 20.2M cached / 80k out
- 2026-11-15 — Tasks 7-8 built and reviewed; Q3 raised before Task 9 · cost: 32m · sonnet-5-5 694k in + 26.8M cached / 114k out
- 2026-11-15 — built Tasks 1-10 (two fix rounds), build ok · cost: 74m · sonnet-5-5 918k in + 37.3M cached / 158k out
