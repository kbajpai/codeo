# Issue #179 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/179 |
| Branch | `docs/179-close-171-leftovers-readme-wording` |
| Updated | 2026-11-25 |

## Where this stands

Round 2 is done: the findings of `qc.md` round 1 are fixed in `6b5de95` and the build ran. Next step: `/codeo:qc`.

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

## Log

- 2026-11-25 — implemented: plan docs/plans/2026-11-25-close-171-leftovers-179.md, tasks 1-4, build exit 0 · cost: 21m · sonnet-5-5 338k in + 9.1M cached / 59k out
- 2026-11-25 — implemented round 2 (send-back from qc round 1): F1, F2, F3, F5, F6 fixed in 6b5de95, build exit 0 · cost: 2m · sonnet-5-5 49k in + 1.7M cached / 8k out
