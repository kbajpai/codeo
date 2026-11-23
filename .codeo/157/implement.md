# Issue #157 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/157 |
| Branch | `fix/live-session-signal-leftovers-138` |
| Updated | 2026-11-23 |

## Where this stands

Built: all seven code and documentation tasks of `docs/plans/2026-11-23-live-signal-leftovers-157.md` are done and pushed, the build passes (`true`, the `shell` suite's `build`) and nothing is open. Next step: `/codeo:qc`.

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

## Log

- 2026-11-23 — built: 8 commits `6143c40..d1cb064`, build exit 0, whole-branch review clean · cost: 35m · sonnet-5-5 629k in + 13.7M cached / 84k out
