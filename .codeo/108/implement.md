# Issue #108 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/108 |
| Branch | `feat/follow-ups-97-left-overlap` |
| Updated | 2026-11-19 |

## Where this stands

Round 1 is built: the plan's nine tasks are done and committed on the branch (`531e55b`..`d019a6e`), each task reviewed, then one whole-branch review (ready to hand off). The build command (`true`) exits 0. Next: `/codeo:qc`.

## Questions

None.

## Outcome

**Built** (plan `docs/plans/2026-11-19-follow-ups-97-left-108.md`, committed as `c9e9aa6`):

- Task 1 — `scripts/overlap.sh`: a failed diff of this branch exits 1 with `overlap: cannot diff <range>` in both modes; in pair mode another workflow's failed diff warns `overlap: skipping #<M>'s changed paths` and its footprint is still compared; `--base ""` and `--head ""` exit 1; two-line usage; header updated. `tests/overlap.test.sh` gains seven cases (empty refs, `--base` alone, no merge base, pair mode with `origin/<base>` missing, a workflow with no merge base, an empty diff, a live-path plan under `--head`). `531e55b`.
- Task 2 — `scripts/qc-verdict.sh` anchors both `## Outcome` matches; three cases in `tests/qc-verdict.test.sh`; the comment above `touched` says only delivered archives are footprint-checked. `6c0748f`, `cf5f70b`.
- Task 3 — `tests/board.test.sh`: `title-read-fails` asserts exit 1; `beyond-50` keeps the `--paginate` and `endCursor` greps, says plainly the stub cannot page, and gains a blank-page-row case in both page orders. `scripts/board.sh` needed no change. `36b7880`.
- Task 4 — `tests/closing-exits.test.sh`: step 17's lead is checked on flattened text, `row_for` matches a whole label, `bites` clears its `RETURN` trap (and a check after the loop fails if one outlives it), two new mutations. `8b396a0`.
- Task 5 — `tests/qc-skill.test.sh`: the `and not blocking by rule:` guard checks flattened text. `4cf39f3`.
- Task 6 — `skills/init/SKILL.md` stops saying there is no lock after every `lock: TODO`; `case_init_lock_wording` pins it. `078b97d`.
- Task 7 — `docs/handoff.md`'s `abandon — finished` row and `docs/skills.md`'s close summary keep the last-copy exception; `case_abandon_summaries` pins both. `c7f2a50`.
- Task 8 — `CHANGELOG.md`: the two v1.0.7 clauses corrected in place, one `## Unreleased` bullet for #108. `1c16331`, `d019a6e`.

**Documentation pages changed:** `skills/init/SKILL.md`, `docs/handoff.md`, `docs/skills.md`, `CHANGELOG.md`. No wiki module.

**Build:** `true` (the `shell` suite's build) → exit 0. The whole suite, `bash tests/run.sh`, also printed `all cases passed` on `1c16331`, and `overlap.sh --outside 108` printed nothing; that is evidence for `/codeo:qc`, not a grade. No environment is configured: no lease taken, no deploy.

**Deviations from the plan, and why:**

- Task 3's mutation (c) ("`split_row` on the last row only") could not make the blank-row case fail, because every blank row carries the issue url. The case now runs both page orders, and the mutation that bites is accepting an empty `pnum` in `status`'s loop.
- Task 4: the real handoff row is `close — lock kept`, not `lock kept`; the whole-label match exposed that, and the loop entry and the mutation use the real label.
- Task 1 dropped `tests/overlap.test.sh`'s executable bit; restored by `11d84f8`.
- The comment clause above `touched` (Task 2) and the CHANGELOG "above"→"below" slip (found by the final review) were written by the controller, not an implementer subagent.
- Task 8 had no separate task reviewer; the controller read its diff and the whole-branch review covered it.

**Plan gap, not fixed here:** no task covers the skills and docs that run `overlap.sh <N>` (`skills/qc/SKILL.md:92,166`, `skills/close/SKILL.md:216`, `skills/implement/SKILL.md:84`, `docs/handoff.md:207`). A failed diff used to print nothing and read as "no overlap"; it now exits 1 with `overlap: cannot diff …`, and none of those texts says a non-zero exit is a failure to report. A skill following a non-zero exit will likely surface it anyway. For the engineer to take into `/codeo:qc` or `/codeo:triage`.

## Log

- 2026-11-19 — round 1 built: nine plan tasks, ten commits, build passes, whole-branch review ready · cost: 23m · sonnet-5-5 592k in + 23.5M cached / 88k out
