# Issue #108 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/108 |
| Branch | `feat/follow-ups-97-left-overlap` |
| Updated | 2026-11-19 |

## Where this stands

Round 2 is built: qc round 1 findings F1, F2, F3 and F5 are fixed. The build command (`true`) exits 0. Next: `/codeo:qc`.

## Questions

### Q1 — #112 touches `CHANGELOG.md` and `docs/handoff.md`, which this branch also changes. How should we go on?

**Why it matters:** `bash scripts/overlap.sh 108` printed `112 CHANGELOG.md`, `112 docs/handoff.md` and the two `glob:` forms. #112 (branch `feat/verify-live-session-signal-hosted`, assignee kbajpai, step qc, waiting on `/codeo:implement`, round 2) plans exactly those files and has changed them. This branch changes `CHANGELOG.md` (the `(#108)` bullet and the two v1.0.7 clauses) and `docs/handoff.md` (the `abandon — finished` row); round 2 may touch `docs/skills.md` (F5) too. Whichever merges second hits a conflict in `CHANGELOG.md`, at least.
**Options:**
- **A — proceed and coordinate (my pick).** Round 2 touches no file round 1 did not, so the overlap is no bigger than before; the one that merges second resolves the changelog and handoff conflict through `sync-main`.
- **B — sequence after #112.** Hold this round until #112 has merged, then start from the new base.
- **C — re-scope.** Drop the `docs/handoff.md` and `CHANGELOG.md` edits from this branch.

**Answer:**
A, proceed and coordinate, as the engineer chose in the session ("proceed & coordinate", 2026-11-19). (Transcribed by the skill from the engineer's chat answer.)

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

### Round 2 — 2026-11-19

(send-back from qc.md round 1)

Step 2a: `sync-main` said the branch already contains `origin/main`. `overlap.sh 108` printed #112 on `CHANGELOG.md` and `docs/handoff.md`; Q1 was answered *proceed and coordinate*. Round 2 touches no file round 1 did not.

**Built** (done directly by the controller: four small edits that no plan task covers):

- F1 (blocking): `tests/closing-exits.test.sh` — the `bites` mutation for `row_for` now renames `` `close — lock kept` `` to `` `stale close — lock kept` ``, which only a whole-label match rejects. Checked: with `row_for` reverted to the old suffix grep, `bites` fails (`the renamed handoff row passed rule`).
- F2: `tests/qc-verdict.test.sh` — new case "a ### Round 2 under a heading that only starts with ## Outcome is not a second round" (a plan.md with a `### Round 2` under `## Outcomes`). Checked: with line 134 of `scripts/qc-verdict.sh` reverted to `/^## Outcome/`, the case fails (`round 2 footprint omits: c.txt`).
- F3: the case formerly at `:795` is now named "docs/plans files a PR adds are not counted as paths it changed".
- F5: `docs/skills.md:196` says that when the unmerged branch was deleted the host clean-up is left out and `/codeo:triage` stays.

**Documentation pages changed:** `docs/skills.md`. **Build:** `true` → exit 0; `bash tests/run.sh` also printed `all cases passed` (evidence for `/codeo:qc`, not a grade). Mutations were restored; `scripts/` is unchanged this round.

**Not taken:** F4 and F6 are `/codeo:plan`'s, left to the engineer or `/codeo:triage`.

## Log

- 2026-11-19 — round 1 built: nine plan tasks, ten commits, build passes, whole-branch review ready · cost: 23m · sonnet-5-5 592k in + 23.5M cached / 88k out
- 2026-11-19 — round 2 started: sent back from qc round 1; overlap with #112 raised as Q1, nothing built yet · cost: 0m · sonnet-5-5 85k in + 357k cached / 2k out
- 2026-11-19 — round 2 built: F1, F2, F3, F5 fixed, build and suite pass; Q1 (#112 overlap) answered proceed and coordinate · cost: 11m · sonnet-5-5 101k in + 2.1M cached / 8k out
