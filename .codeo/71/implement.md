# Issue #71 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/71 |
| Branch | `feat/file-new-issues-straight-board` |
| Updated | 2026-11-15 |

## Where this stands

Round 1, built and ready for `/codeo:qc`. All six plan tasks are done; #70 has merged and `sync-main.sh` brought it in, so this branch's rule is now `issue-09`. Nothing is open.

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

### Round 1

**Built:** the six plan tasks (`51236ec`, `2359638`, `7e0b56c`, `8a53282`, `04194f4`, `66edd68`) and the final review's wording fixes (`f7b9e49`): `/codeo:issue` step 8 moves the new issue into Backlog when a board is configured, a failed move never fails the filing, `/codeo:triage` finds the card already there, and `docs/handoff.md`, `docs/skills.md`, `board.sh`'s header and the changelog describe it.

**Merge of the base branch (`17a6cf3`):** #70 had merged, so `sync-main.sh` exited 2 with conflicts in five files, resolved against both changes' intent:
- `skills/issue/SKILL.md` merged cleanly but carried two `issue-08` markers; this branch's was renamed to `issue-09`.
- `docs/skills-inventory.md`: #70's `[issue-08]` (role check) kept, this branch's rule appended as `[issue-09]`.
- `tests/inventory.test.sh`: #70's counts with `[issue]=9`.
- `tests/fixtures/skills-inventory.rules.sha256`: regenerated with `bash tests/inventory.test.sh --update` (`d67ced5c…`).
- `tests/closing-exits.test.sh`: both branches' cases kept, `issue-backlog` added to the case list and its header.
- `CHANGELOG.md`: this branch's entry first, now naming `issue-09`, followed by #70's side of the #51 and #52 entries (the wording #70 had updated).

`also changed on main` lines: none printed (the script stopped on the conflicts). `overlap.sh 71` prints nothing.

**Documentation pages changed:** as planned (`docs/handoff.md`, `docs/skills.md`, `docs/skills-inventory.md`, `CHANGELOG.md`); no unplanned page.

**Build:** the suite's `build` is `true`; passed. No shared environment is configured, so there is no lease and no deploy. Not graded here: `bash tests/run.sh` also printed `all cases passed` after the merge.

**Deviations from the plan:** the rule is `issue-09`, not the plan's `issue-08`, because #70 took `issue-08` (Q1, answered: sequence after #70). The plan's text is left as written.

## Log

- 2026-11-15 — built all six plan tasks; Q1 raised (overlap and rule-ID collision with #70) · cost: 17m · sonnet-5-5 525k in + 14.5M cached / 64k out
- 2026-11-15 — Q1 answered: sequence after #70; waiting for it to merge · cost: 19m · sonnet-5-5 529k in + 15.8M cached / 67k out
- 2026-11-15 — #70 merged; merged main, renumbered the rule to issue-09, regenerated the hash, suite passes; handed off to qc · cost: 4m · sonnet-5-5 34k in + 920k cached / 4k out
