# Issue #138 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/138 |
| Branch | `fix/live-session-signal-does-not` |
| Updated | 2026-11-21 |

## Where this stands

Tasks 1-6 of `docs/plans/2026-11-21-live-signal-web-session-138.md` are built, reviewed task by task and as a whole branch, and the full `shell` suite is green. Task 7, the hosted-session check, is the engineer's and is not run here. Next: `/codeo:qc`. One finding for the engineer is under `## Notes`: a file outside the plan's footprint changed.

## Questions

None.

## Notes

**A file outside the plan's footprint changed.** `bash scripts/overlap.sh --outside 138` prints `tests/devcontainer.test.sh`. The plan's footprint lists nine files and does not name it. Cause: Task 4's hook groups in `.claude/settings.json` broke `session_title_hooks_are_registered` there, an exact-match check that the file holds only two hook events. The fix (`bd8b322`) keeps the session-title groups as the first of their events and adds the check that every other hook is gated on `CLAUDE_CODE_REMOTE`. The footprint is in `plan.md`'s outcome, which this skill never edits, so it is reported: `/codeo:qc` will see the path outside the footprint, and the engineer decides whether a plan round adds it.

**Later work, to file with `/codeo:issue` in the home checkout** (it refuses in this container):
- `live.sh fetch` aborts with `fatal: Cannot fetch both refs/codeo/live/<issue>/<machine> and refs/heads/codeo-live/<issue>/<machine> to refs/codeo/live/<issue>/<machine>` when a container or local signal and a web signal for one issue have the same machine label (`CODEO_MACHINE` set alike in both, or a hostname fallback that matches). `inflight.sh` then prints `live: unknown (could not fetch the signals)` for every reader, for as long as the never-deleted web branch exists. Found by the whole-branch review; reproduced with git 2.53.
- The `codeo-live/<issue>/web-<id>` branches a web session leaves on origin need removing (already noted in `plan.md`).

**Process note.** An implementer reported the full suite green when it had not finished. The first complete run, in Task 6, found the `tests/devcontainer.test.sh` failure above. The final run was made by the controller to its last line (`all cases passed`).

## Outcome

**Plan:** `docs/plans/2026-11-21-live-signal-web-session-138.md`. **Sync:** `bash scripts/sync-main.sh` merged `origin/main` (1 commit, #145) at the start (`1d33714`) and found the branch already current in each later check; `overlap.sh 138` printed nothing. Main's changes in `skills/triage/SKILL.md`, `tests/triage-skill.test.sh`, `docs/handoff.md` and `CHANGELOG.md` were re-read before Tasks 3, 5 and 6; the bullet Task 3 edits was unchanged.

**Built** (each task reviewed by a fresh reviewer: spec compliant, no Critical or Important findings):
- **Task 1** (`ea20340`): `scripts/live.sh` publishes a web session's signal to `refs/heads/codeo-live/<issue>/<machine>` (`push_ref`), with no REST fallback; `clear` is a no-op for web (branch never deleted, it expires); `fetch` maps both namespaces into `refs/codeo/live/*`. Five new cases in `tests/live.test.sh`; the `machine_by_host` web assertion moved with the route.
- **Task 2** (`352c2d0`): the web machine is `web-` plus 8 characters of the lock's session, else `CLAUDE_CODE_REMOTE_SESSION_ID`, with a leading `cse_` or `session_` removed, else the hostname; the user is `CODEO_GITHUB_LOGIN`, else `GET /user`, else for web the issue's assignee, else `git config user.name`. Eight cases.
- **Task 3** (`7341942`): `skills/triage/SKILL.md` ignores `codeo-live/` branches; one `must_contain` line.
- **Task 4** (`e210a08`): `.claude/settings.json` gains a `SessionStart` group (`lock.sh take web <id>`) and `UserPromptSubmit` and `PostToolUse` groups (`live-signal.sh beat`), each gated on `CLAUDE_CODE_REMOTE=true`; four cases in `tests/live-signal.test.sh`.
- **Task 5** (`48d1a9b`): `docs/handoff.md`, *Who is working right now* and its diagram; case `docs_state_the_web_session_signal`.
- **Task 6** (`93db318`): one `CHANGELOG.md` bullet.
- **Fix round** (`bd8b322`): `tests/devcontainer.test.sh`, see `## Notes`.
- **Final-review fix wave** (`1a83d6e`): the `CHANGELOG.md` bullet states that `CODEO_GITHUB_LOGIN` now wins over `GET /user` for every session, and `live.sh`'s header lists `CODEO_GITHUB_LOGIN` and `CLAUDE_CODE_REMOTE_SESSION_ID`; comments and one clause only.

**Not built:** Task 7 (the hosted-session check), which is `Runs on: the engineer's host`. Whether the repository's `UserPromptSubmit` and `PostToolUse` hooks fire in a cloud session, and whether `SessionStart` runs `lock.sh take web` with a usable id, stay unverified until it runs.

**Documentation pages changed:** `docs/handoff.md` (*Who is working right now*) and `CHANGELOG.md`; no wiki pages.

**Build:** the `shell` suite's `build` is `true`: rc 0. (Full `bash tests/run.sh` also ran, to its last line: `all cases passed`; grading is `/codeo:qc`'s.)

**Deviations from the plan.** (1) `tests/devcontainer.test.sh` changed, outside the footprint (`## Notes`). (2) Task 1 changed the existing `machine_by_host` web assertion in `tests/live.test.sh`, which asserted the old route. (3) Minor review findings left as they are: no test for a failing `issue view`, none for an unset session id at `SessionStart`, a loose `codeo-live/` pattern in the triage test, one long line in the triage bullet. No environment is configured, so there was no deployment.

## Log

- 2026-11-21 — round 1: Tasks 1-6 built and reviewed, one fix round and one final-review fix wave, full suite green, build rc 0 · cost: 65m · sonnet-5-5 740k in + 25.6M cached / 111k out
