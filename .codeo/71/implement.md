# Issue #71 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/71 |
| Branch | `feat/file-new-issues-straight-board` |
| Updated | 2026-11-15 |

## Where this stands

Round 1. All six plan tasks are built, committed and reviewed (each task review clean; the final
whole-branch review returned "Ready to merge: Yes" and its three wording fixes are in `f7b9e49`).
`bash tests/run.sh` prints `all cases passed`, and the suite's `build` is `true`. The hand-off is
held on Q1, answered *sequence after #70*: #70 (`feat/guard-home-only-skills-against`, at `qc`) has
no pull request yet and is not on `main`, so this round waits. When #70 has merged, re-invoke
`/codeo:implement`: it runs `sync-main.sh`, renames this branch's rule `issue-08` to `issue-09`
(the marker in `skills/issue/SKILL.md`, the bullet in `docs/skills-inventory.md`, `[issue]=` in
`tests/inventory.test.sh`, and the `issue-08` mentions in the tests and the plan's text if any),
regenerates the hash with `bash tests/inventory.test.sh --update`, re-runs `bash tests/run.sh`,
and writes the outcome. All six tasks are pushed.

## Questions

### Q1 — #70 now changes six of the same test files and reuses the rule ID `issue-08`: proceed and coordinate, sequence after #70, or re-scope?

**Why it matters:** the plan's Q2 answered "proceed and coordinate" for #70 when #70 had only a
plan. #70 is now at `qc` (`feat/guard-home-only-skills-against`, assignee kbajpai), and
`overlap.sh 71` prints these paths, which both branches change: `tests/board.test.sh`,
`tests/closing-exits.test.sh`, `tests/fixtures/skills-inventory.rules.sha256`,
`tests/inventory.test.sh`, `tests/issue-skill.test.sh` and `tests/triage-skill.test.sh`.
Two of them are a certain conflict, not an adjacent-line one:
- **The rule ID.** #70's `docs/skills-inventory.md` adds `[issue-08] A refusal from the role
  check ends the step; no override.` and its `tests/inventory.test.sh` sets `[issue]=8`. This
  branch adds `[issue-08] A failed Backlog move never fails the filing…` and also sets
  `[issue]=8`. Both cannot be `issue-08`: the second to merge renumbers its rule to `issue-09`
  (the marker in `skills/issue/SKILL.md`, the inventory bullet, the count in
  `tests/inventory.test.sh`).
- **The pinned hash.** `tests/fixtures/skills-inventory.rules.sha256` holds one hash over every
  rule text, so it conflicts whichever way the rules merge, and is regenerated with
  `bash tests/inventory.test.sh --update` after the merge.

The other four overlaps are test files both branches add cases to; they merge by keeping both.
The answer decides whether this branch merges `main` after #70 and renumbers its rule before
`/codeo:qc`, or renumbers later at the merge, and whether `sequenced:` is added to the footprint.
**Options:**
- **Sequence after #70 (recommended).** #70 is at `qc`, so it is likely to merge first. This
  branch waits for it, runs `sync-main.sh`, renames its rule to `issue-09`, regenerates the hash,
  re-runs the suite, and then goes to `/codeo:qc`. The footprint records `sequenced: after #70`.
  One planned rename, no surprise at merge.
- **Proceed and coordinate.** Go to `/codeo:qc` now. Whichever merges second renames its rule and
  regenerates the hash; if that is this branch, QC's verdict was given on an `issue-08` that the
  merge then changes.
- **Re-scope.** Not possible without dropping the rule the criterion on failed moves needs.

**Answer:**
Sequence after #70 (answered in the conversation: "Sequence after #70").

## Notes

- Built from `main` at `90075d4` (`sync-main.sh`: the branch already contained `origin/main`; no
  `also changed on <base>` lines).
- Task commits: `51236ec` (1), `2359638` (2), `7e0b56c` (3), `8a53282` (4), `04194f4` (5),
  `66edd68` (6), and `f7b9e49` (the final review's wording fixes).
- **A miss in this round, recorded here:** the first `overlap.sh 71` of this round, run right
  after the plan was committed, printed `tests/fixtures/skills-inventory.rules.sha256` and
  `tests/inventory.test.sh` for #70. The line was seen and not raised as a question before the
  tasks were dispatched, which `/codeo:implement` step 2a requires. It is raised now, with the
  fuller list the same script prints today.
- Deferred minor findings from the task reviews, none blocking: `O_BACKLOG` grep in the new
  `tests/board.test.sh` case is unscoped like its neighbours; the wording tests are fixed-string
  pins by this repository's form; `skills/triage/SKILL.md`'s pinned `triage-05` text still says
  "the card moves to Backlog" where step 5 now makes no move for a card already there (the
  inventory hash pins that rule text, so it is left).

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-15 — built all six plan tasks; Q1 raised (overlap and rule-ID collision with #70) · cost: 17m · sonnet-5-5 525k in + 14.5M cached / 64k out
- 2026-11-15 — Q1 answered: sequence after #70; waiting for it to merge · cost: 19m · sonnet-5-5 529k in + 15.8M cached / 67k out
