# Issue #138 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/138 |
| Branch | `fix/live-session-signal-does-not` |
| Updated | 2026-11-21 |

## Where this stands

Round 2 (after `plan.md` round 2) is built: Tasks 1-5 of `docs/plans/2026-11-21-live-signal-web-session-138-round-2.md` (the web user ends at `unknown`; the beat hook takes the lock in a web session; the `SessionStart` lock group is gone; the handoff page and the changelog say so), each reviewed and the round reviewed as a whole, and the full `shell` suite is green. Task 6, the hosted-session check with no manual lock, is the engineer's and is not run here. Next: `/codeo:qc`, which re-runs the pass from the start. Round 1 (Tasks 1-6 of the first plan) stands as built; its note on `tests/devcontainer.test.sh` outside the footprint is answered by the footprint now naming it.

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

### Round 2 — 2026-11-21

(after plan.md round 2)

**Plan:** `docs/plans/2026-11-21-live-signal-web-session-138-round-2.md` (answers `qc.md` round 1: F1, F4, F11, F5, F7, F8, F10). **Sync:** `bash scripts/sync-main.sh`: `sync-main: the branch already contains origin/main`, exit 0, at the start and before Tasks 4 and 5; `overlap.sh 138` and `overlap.sh --outside 138` printed nothing (the footprint now names `tests/devcontainer.test.sh`).

**Built** (Tasks 1-5, each reviewed by a fresh reviewer: spec compliant, no Critical or Important findings; then one whole-round review, same result):
- **Task 1** (`6b250bf`): `scripts/live.sh` `user_label` skips `git config user.name` for a web session, leaving `unknown`; the web case in `tests/live.test.sh` becomes `web_user_without_a_login_or_assignee_is_unknown`.
- **Task 2** (`dd9961b`): `hooks/live-signal.sh beat` takes the lock when none exists: `CLAUDE_CODE_REMOTE=true`, a `.codeo/` directory, at most once per `CODEO_LIVE_REFRESH_SECONDS` (stamp `codeo-live-lock-try`), detached with every stream closed (`lock.sh take web <id minus cse_>`, then `live.sh beat`). Six cases in `tests/live-signal.test.sh` and a helper `new_world_with_dossier`.
- **Task 3** (`acb5839`): `.claude/settings.json` loses the `SessionStart` group that ran `lock.sh take web`; the registration case is tightened, the old lock case is deleted and `settings_beat_hook_takes_the_lock_and_publishes` is added.
- **Task 4** (`c211255`): `docs/handoff.md` (*Who is working right now* and its diagram) states the lock take, the two hook sources, the user chain with the first assignee, and `CODEO_GITHUB_LOGIN`'s order.
- **Task 5** (`a2140b3`): the `CHANGELOG.md` bullet is rewritten to match.

**Not built:** Task 6, the hosted-session check (`Runs on: the engineer's host`): a fresh hosted session on this branch with one ordinary prompt and no manual `lock.sh`, then `.codeo/active` in the session and `inflight.sh --live` here. Whether the first prompt takes the lock in a hosted session stays unverified until it runs.

**Documentation pages changed:** `docs/handoff.md` (*Who is working right now*) and `CHANGELOG.md`; no wiki pages.

**Build:** the `shell` suite's `build` is `true`: rc 0. The whole `bash tests/run.sh` ran by the controller to its last line: `all cases passed` (the implementers ran only the focused runs; round 1's lesson).

**Deviations from the plan.** (1) Task 2 defines a helper `new_world_with_dossier` that Task 3 keeps while deleting the case that built the same world inline (a ruling at the preflight scan: avoids Task 3 breaking Task 2's cases). (2) Left as they are, from the reviews: the stamp check and write in the hook are not atomic (two simultaneous hooks can both spawn a take); a no-op `wait_for_file` line and a relative-path assumption of `git rev-parse --git-path` in tests; cosmetic long lines in `docs/handoff.md`; the page says "either way nothing else is needed" without saying the branch must carry a committed dossier; the changelog bullet does not mention that a later take can check out the dossier branch mid-session. No environment is configured, so there was no deployment.

## Log

- 2026-11-21 — round 1: Tasks 1-6 built and reviewed, one fix round and one final-review fix wave, full suite green, build rc 0 · cost: 65m · sonnet-5-5 740k in + 25.6M cached / 111k out
- 2026-11-21 — round 2 (after plan.md round 2): Tasks 1-5 built and reviewed, full suite green, build rc 0 · cost: 23m · sonnet-5-5 413k in + 16.3M cached / 65k out
