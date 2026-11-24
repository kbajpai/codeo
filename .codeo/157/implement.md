# Issue #157 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/157 |
| Branch | `fix/live-session-signal-leftovers-138` |
| Updated | 2026-11-23 |

## Where this stands

Built (round 2, after the send-back in `qc.md` round 1): the three tasks of `docs/plans/2026-11-23-live-signal-leftovers-157-round-2.md` are done and pushed, the build passes (`true`, the `shell` suite's `build`) and nothing is open. Next step: `/codeo:qc`.

## Questions

None.

## Notes

- **Later work, no issue number:** none promised. Small findings left as they are, listed under `## Outcome`.

## Outcome

**Built** (eight commits, `6143c40..d1cb064`, each task reviewed by a fresh reviewer, then one whole-branch review that found nothing Critical or Important):

| Task | Commit | What |
|---|---|---|
| 1 | `415cd4b` | `live.sh fetch` puts web branches in `refs/codeo/live-web/*`; `list` reads both namespaces, so equal labels give two rows and `fetch` exits 0 (F22). |
| 2 | `7d3673f` | A web beat keeps its first label in `<git dir>/codeo-live-machine` until `clear`; `CODEO_MACHINE` is never saved; an unsafe or empty saved label is ignored (F25). |
| 3 | `936ee79` | The web signal's subject is `codeo live signal [skip ci]` (F23, CI). |
| 4 | `1648125` | New `live.sh sweep`: deletes the issue's `codeo-live/<issue>/*` branches, no-op in a web session, one `live:` line and exit 0 on failure (F23). |
| 5 | `0bb2ec8`, `d1cb064` | `/codeo:close` step 16 runs `clear; sweep; rm -f .codeo/active`; the stash and abandon sentences say the same; the rationale names both verbs. |
| 6 | `2559ea9` | `cleanup.sh` prints a `leftover` line with `git push origin --delete …` after a proven issue's line; the skill relays it. Names outside `^codeo-live/<N>/[A-Za-z0-9._-]+$` are skipped. |
| 7 | `e45d784` | `docs/handoff.md` (paragraph and diagram), `docs/skills.md` (`close`, `cleanup`), `CHANGELOG.md` (`## Unreleased`, three bullets); pins in `tests/live-signal.test.sh` changed first. |

**Documentation pages changed:** `docs/handoff.md`, `docs/skills.md`, `CHANGELOG.md`, `scripts/live.sh`'s header, `scripts/cleanup.sh`'s header, `skills/close/SKILL.md`, `skills/cleanup/SKILL.md`.

**Build result:** the configured `shell` suite's `build` is `true`: exit 0. No shared environment is configured, so no lease, no deploy and no redeploy check. (`bash tests/run.sh`, the whole `shell` suite, also printed `all cases passed` after the last commit; grading it is `/codeo:qc`'s.)

**Mutation check (plan task 8, step 2):** with the `live-web` refspec put back to `refs/codeo/live/*`, `bash tests/run.sh live.test` failed four assertions in the two new fetch cases (fetch exit 1; no rows; the stale web copy left in `refs/codeo/live/`); the refspec was restored and the file passes.

**Deviations from the plan:**
- Task 2 changed the existing case `two_web_sessions_on_one_issue_publish_two_branches` to delete the label file before its second beat, since it modelled two checkouts in one; the saved label now collapses that.
- Task 5 got a second commit (`d1cb064`) from the final review: step 16's rationale said only `clear` needs the lock, and `sweep` does too.
- The sync merge from `main` at the start of the round (`6143c40`) changed `scripts/cleanup.sh`, `skills/cleanup/SKILL.md`, `tests/cleanup.test.sh`, `tests/cleanup-skill.test.sh` and `CHANGELOG.md` (#152's work); task 6 was written against the merged files and the plan's line numbers were approximate.

**Left as they are** (reviewers' minors, none a requirement):
- No test for an empty saved label file, though the code ignores it.
- No test for a failing `ls-remote` in `sweep` (the refused-delete case has the same warn-once, exit-0 shape).
- The cleanup cases for issue 70-versus-7 and for a failed proof assert absence only and pass before the change; the trailing-slash prefix and the anchored regex are what hold it.
- The pins in `tests/live-signal.test.sh` for the new doc text are token-level.
- `skills/cleanup/SKILL.md`'s frontmatter description does not mention leftover branches.
- A branch on origin whose name the regex rejects is skipped without a message.
- `CHANGELOG.md:25` (released v1.0.8 entry) still says the fetch maps onto `refs/codeo/live/*`; it is history and stays.

**Rulings I made** (the plan runs under a controller that rules rather than asks):
- Every task also ran `bash tests/run.sh live-signal`, since a header comment edit can trip a pin there. Cost if wrong: one extra quick test file per task.
- The mutation check was done by the controller, not an implementer, because `implement.md` is the controller's file.
- Task 2's test adaptation above is correct for the planned behaviour. Cost if wrong: a test only.
- Task 4's missing failing-`ls-remote` test is acceptable for the reason above. Cost if wrong: an untested warn branch.
- Task 6's absence-only cases are acceptable for the reason above. Cost if wrong: a regression in the prefix match goes unpinned.

### Round 2 — 2026-11-24
(after plan.md round 2, answering qc.md round 1)

**Built** (three commits, `0c0b2ef..63eb330`; tasks 1 and 2 each reviewed by a fresh reviewer, no Critical or Important findings):

| Task | Commit | What |
|---|---|---|
| 1 | `c6da81d` | `live.sh clear` removes only the throttle stamp and keeps `<git dir>/codeo-live-machine`, so a web session that ends and resumes under another id shows as one row (F1). The test `web_clear_forgets_the_label` became `web_clear_keeps_the_label`; the header comments say the same. |
| 2 | `4396240` | `docs/handoff.md` (the label names the checkout; the `create` event is not suppressed by `[skip ci]`), `docs/skills.md` (`cleanup` prints the leftover-branch delete command and reads `refs/remotes/origin/codeo-live/<N>/*`), `CHANGELOG.md` (`Shared state`, `Safe to bump mid-workflow` and the label bullet); pins first in `tests/live-signal.test.sh` (F1 wording, F2, F4, F5). |
| 3 | `63eb330` | `tests/inflight.test.sh` case `live_survives_a_web_and_a_container_signal_with_equal_labels`: `inflight.sh --live` with the real `live.sh` exits 0, prints a container row and a web row and no `live:` line (F3). With the old refspec put back the case failed (`Cannot fetch both refs/codeo/live/7/codeo-7 and refs/heads/codeo-live/7/codeo-7`); restored. |

**Documentation pages changed:** `docs/handoff.md`, `docs/skills.md`, `CHANGELOG.md`, `scripts/live.sh`'s header.

**Build result:** the `shell` suite's `build` is `true`: exit 0. No shared environment is configured, so no lease, deploy or redeploy check. `bash tests/run.sh` also printed `all cases passed` after the last commit; grading it is `/codeo:qc`'s.

**Deviations from the plan:** task 2 added one pin for `docs/skills.md` (`refs/remotes/origin/codeo-live/<N>/*`) in a new case, `changelog_and_skills_state_the_saved_label`, which the brief did not list. Task 3 had no separate reviewer: the controller read its 17-line diff, and the mutation check above is its proof. There was no whole-branch review this round; round 1's covered the rest, and the round-2 diff is three commits.

**Left as they are** (reviewers' minors): `scripts/live.sh` header lines 18-20 read awkwardly (a dangling "and its branch"); `docs/skills.md:108` says `cleanup` prints the leftover command for each issue, where the script prints it only when leftovers exist; the label bullet in `CHANGELOG.md` is a long sentence.

**Rulings I made:**
- Task 3 reviewed by the controller, not a fresh reviewer, because the diff is one test case with a mutation proof. Cost if wrong: a test-quality issue found at `/codeo:qc`.
- No whole-branch review for round 2. Cost if wrong: an interaction between the three commits found at `/codeo:qc`.

## Log

- 2026-11-23 — built: 8 commits `6143c40..d1cb064`, build exit 0, whole-branch review clean · cost: 35m · sonnet-5-5 629k in + 13.7M cached / 84k out
- 2026-11-24 — round 2 built: 3 commits `0c0b2ef..63eb330`, build exit 0 · cost: 14m · sonnet-5-5 337k in + 3.7M cached / 19k out
