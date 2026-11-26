# Issue #179 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/179 |
| Branch | `docs/179-close-171-leftovers-readme-wording` |
| Updated | 2026-11-25 |

## Where this stands

Round 4 is done: the conflict with `origin/main` found by `close.md` round 1 is resolved in `29b3df5` and the build ran. Next step: `/codeo:qc`.

## Questions

None.

## Notes

None.

## Outcome

**Plan:** `docs/plans/2026-11-25-close-171-leftovers-179.md`, tasks 1-4, executed through `superpowers:subagent-driven-development` on `sonnet` for every implementer and reviewer. `sync-main.sh` found the branch already contained `origin/main`; `overlap.sh` printed nothing (the #177 overlaps were answered at plan, Q5-Q7).

**Built:**
- **Task 1** (`daac339`): `tests/readme.test.sh` — `slugs()` gives a repeated heading GitHub's `-1`, `-2` suffix, with a self-check; the header names the path checks that hold only because codeo uses itself; new checks `lock-entry`, `setup-steps`, `troubleshooting-groups`, `adopting-guard`, `updating`, `skill-count`, and `start-here` extended for step 6. Seen failing before any page changed: exactly those seven checks.
- **Task 2** (`990cf9b`): `README.md` — step 6 says to run `/codeo:close` again; the lock entry separates the TODOs `/codeo:init #<N>` fixes from those that say to reconcile by hand; *Setting a project up* is three `###` steps with column-0 fences; the two non-doctor entries sit under `### Installing and the pin`; the role-guard entry links to the adoption section.
- **Task 3** (`ec84668`): `docs/home-checkout.md` — new `## Adopting the guard in your project`; `docs/extension-points.md` — one link to it.
- **Task 4** (`c05696f`): `docs/updating.md` — restart open sessions after updating superpowers; `docs/handoff.md` — "Six pipeline skills".
- **Final review fix** (`22feaee`): the README lock entry names both TODOs that say a local branch holds commits the other side lacks (`scripts/lock.sh:101,111`).

**Documentation pages changed:** `README.md`, `docs/home-checkout.md`, `docs/extension-points.md`, `docs/updating.md`, `docs/handoff.md` — all five the plan names, no others.

**Build:** the `shell` suite's `build` is `true`: exit 0. No shared environment, so no lease and no deploy. Evidence the tasks ran: `bash tests/run.sh readme` prints `all cases passed` (run by the controller after Tasks 2, 3 and the fix); the implementer of Task 4 reported `bash tests/run.sh` passing here and in a clean worktree. The full suite is `/codeo:qc`'s to run, not this step's.

**Deviations from the plan:**
- Task 4's sentence reads "Afterwards, restart every open Claude Code session, so it loads the updated plugin." The plan's "Restart every open …" cannot satisfy the `updating` check, which greps lowercase `restart`; the meaning is the same.
- Task 2's proof also saw `FAIL links:` for the README link to the adoption heading until Task 3 created it, which the plan's proof list left out (ruled at pre-flight).
- Task 4 had no review of its own (two lines, read in full by the controller); the final whole-branch review covered it. The final-review fix in `22feaee` was made directly and not re-reviewed.
- Three minor review notes left as they are: `grep -q` at the end of a pipe under `pipefail` in the new checks (the existing file does the same, inputs are a few KB); the `lock-entry` check is weak on the "fresh init fixes" group; "report what was printed" in `docs/home-checkout.md` against the overlay's "what it printed".

### Round 2 — 2026-11-25
(send-back from qc.md round 1)

`sync-main.sh`: the branch already contained `origin/main` (QC's own merge, `0ede470`); `overlap.sh 179` printed nothing. I read each finding against the code before acting (`scripts/lock.sh:158-170`, `skills/close/SKILL.md`, `skills/init/SKILL.md`, the guard page against `.codeo/overlays/plan.md`); F1, F2, F3, F5 and F6 held, F4 asked for no change. One sonnet implementer fixed the five in `6b5de95`; I read its diff and ran `bash tests/run.sh readme` (`all cases passed`).

- **F1:** the `tests/readme.test.sh` header names `.codeo/`, `.codeo/.gitignore`, `.codeo/config.json` and `docs/plans/` as the paths that resolve only because codeo uses itself.
- **F2:** the README lock entry says `/codeo:init #<N>` fixes the "found 0" and stashed-or-abandoned TODOs, that an abandoned issue's card is back in Backlog so `/codeo:init` waits for Ready (pointing at "A card that is not Ready"), and that "found more than one" means two issues' dossiers name the branch, to be settled by hand before re-running.
- **F3:** `docs/home-checkout.md` says the skill reads the exit and, on exit 1, the one line; on any other exit it reports what the check printed.
- **F5:** `troubleshooting-groups` fails with `the doctor group has no entry <name>.` for each of the twelve checks missing as a lead (proved on a scratch copy with one lead removed).
- **F6:** `skill-count` greps for line content, not line numbers, and fails if `docs/handoff.md` still says "Seven pipeline skills".
- **F4:** no change; the wording is the criterion's own.

**Documentation pages changed:** `README.md`, `docs/home-checkout.md`; guarded by `tests/readme.test.sh`.

**Build:** the `shell` suite's `build` is `true`: exit 0. No shared environment.

**Deviations from the plan:** none beyond round 1's. The fix commit was reviewed by the controller reading its diff, not by a separate reviewer.

### Round 3 — 2026-11-25
(send-back from qc.md round 2)

`sync-main.sh`: the branch already contained `origin/main`; `overlap.sh 179` printed nothing. I checked each finding against the code before acting: G1 against `skills/init/SKILL.md:119-127,178-195` and `skills/close/SKILL.md:684-711`, which the round's reviewer had read (an abandoned issue's branch is still on origin, so init skips the Ready gate and stops on `claim.sh` exit 4, and the way on is to say so in so many words or delete the old branch; round 1's F2, which introduced the Backlog clause, had not read them); G2 and G3 held; G4 asked for no change. One sonnet implementer fixed G1-G3 in `50a2d52`; I read its diff and ran `bash tests/run.sh readme` (`all cases passed`).

- **G1:** the README lock entry says `/codeo:init #<N>` fixes the "found 0" TODO and resumes a stashed issue; for an abandoned one it stops with `claim: #<N> was abandoned …`, and the two ways on are to say in so many words that you are taking the work up again, or to delete the old branch on origin and run `/codeo:init #<N>` again with the card Ready. The Backlog clause is gone.
- **G2:** the entry opens "do what it says, except as set out here", and the "found more than one" clause says that, despite the line's "run init for the issue", `/codeo:init` does not fix it.
- **G3:** the `tests/readme.test.sh` header says the four paths are the ones "these pages name for a user's project".
- **G4:** no change; the guard is the weaker part, the section is correct.

**Documentation pages changed:** `README.md`; guarded by `tests/readme.test.sh`.

**Build:** the `shell` suite's `build` is `true`: exit 0. No shared environment.

**Deviations from the plan:** none beyond the earlier rounds'. The fix commit was reviewed by the controller reading its diff, not by a separate reviewer.

### Round 4 — 2026-11-26
(send-back from close.md round 1)

`/codeo:close` found a conflict with `origin/main` after #177 (`3a36e47`, PR #186) merged. `superpowers:receiving-code-review` applied: the finding holds (`git merge-tree` exit 1 on `tests/readme.test.sh`; reproduced by `sync-main.sh`, exit 2).

**Resolved by hand, in `29b3df5`.** `sync-main.sh` merged `origin/main`; the only conflict was `tests/readme.test.sh`, one hunk in the header comment's list of checks. This branch added seven entries (`lock-entry` … `skill-count`) and #177 added one (`home-checkout`) at the same place; both sides' lines are kept, this branch's first, so the header names every check the file runs. The rest of the file merged without conflict: #177's `home-checkout` check and this branch's six new checks and two extended ones sit side by side. `docs/home-checkout.md` also merged without a conflict (#177 edited *The home checkout*; this branch's *Adopting the guard in your project* is its own section). `bash -n tests/readme.test.sh` is clean and `bash tests/run.sh readme` prints `all cases passed` on the merged tree.

`also changed on main:` — #177's change touched `.codeo/overlays/cleanup.md`, `.codeo/overlays/close.md`, `docs/handoff.md`, `docs/home-checkout.md`, `docs/skills.md`, `skills/cleanup/SKILL.md`, `skills/close/SKILL.md`, `docs/release-checklist.md`, `CHANGELOG.md`, `tests/readme.test.sh` and several tests. Re-checked against this branch's work: `docs/handoff.md` and `docs/skills.md` still say six pipeline skills (the `skill-count` check passes); the `lock-entry` and guard-page text reference no passage #177 changed.

**Documentation pages changed:** none in this round beyond the merge.

**Build:** the `shell` suite's `build` is `true`: exit 0. No shared environment.

**Deviations from the plan:** none. The resolution is a merge of two header-comment lists; no subagent was dispatched and none was needed.

## Log

- 2026-11-25 — implemented: plan docs/plans/2026-11-25-close-171-leftovers-179.md, tasks 1-4, build exit 0 · cost: 21m · sonnet-5-5 338k in + 9.1M cached / 59k out
- 2026-11-25 — implemented round 2 (send-back from qc round 1): F1, F2, F3, F5, F6 fixed in 6b5de95, build exit 0 · cost: 2m · sonnet-5-5 49k in + 1.7M cached / 8k out
- 2026-11-25 — implemented round 3 (send-back from qc round 2): G1-G3 fixed in 50a2d52, build exit 0 · cost: 1m · sonnet-5-5 57k in + 1.1M cached / 5k out
- 2026-11-26 — implemented round 4 (send-back from close round 1): merged origin/main after #177, one conflict in tests/readme.test.sh resolved in 29b3df5, build exit 0 · cost: 0m · sonnet-5-5 11k in + 1.2M cached / 931 out
