# Issue #161 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/161 |
| Branch | `docs/documentation-leftovers-154-146-removal` |
| Updated | 2026-11-24 |

## Where this stands

Written after the work was done, from the commits `6cf2227` and `a2c7114`. The edits were made directly in a hosted web session, not through `/codeo:implement`, so there was no per-task subagent dispatch and no per-task review. Next step: `/codeo:qc`.

## Questions

None.

## Outcome

**Built** (two commits on top of `9cca4d9`, `6cf2227` and `a2c7114`):

- **Task 1** (`6cf2227`, `.devcontainer/README.md`): the `G` edge names the failed follow-up `docker ps -a` listing under `--force`; the `H` edge loses its `--force` parenthesis; node `Q` reads `refuse: nothing removed (a container codeo started for the read is stopped again)`.
- **Task 2** (`6cf2227`): the inspect paragraph says "A container `codeo` knows it started for that read is stopped again", and that a failed `docker ps -a` leaves a started container running.
- **Task 3** (`6cf2227`): the sandbox paragraph says the script refuses at the missing clone "with or without `--force`", and still names `sbx rm --force codeo-<N>`.
- **Task 4** (`6cf2227`, `CHANGELOG.md`): the v1.0.8 `Shared state:` line names the exact `## Outcome` match in `dossier-check.sh`, `inflight.sh` and `qc-verdict.sh`, and the `### Round <n> — stashed|abandoned` reader (`is_parked`, under `CODEO_LOCK_SKIP_PARKED=1`) in `lock.sh`.
- **Task 5** (`6cf2227`, `docs/release-checklist.md`): step 6 names the README installer examples and the `tests/install.test.sh` stubs as files a release also moves.
- **Task 6:** `bash tests/run.sh` was run in the sandbox: `install.test.sh` and `live.test.sh` failed. `install.test.sh` fails the same way on the parent commit (`rm: command not found`, exit 127, a sandbox `PATH` problem); `live.test.sh`'s `two_simultaneous_beats_from_one_checkout_leave_a_fresh_signal` reads no file this change edits, and was not re-run on the parent commit.

**Documentation pages changed:** `.devcontainer/README.md`, `CHANGELOG.md`, `docs/release-checklist.md`. No wiki module.

**Build result:** the change is documentation only; the `shell` suite's `build`, if configured, was not run separately.

**Deviations from the plan, and why:**
- `a2c7114` adds a `SessionStart` hook that runs `install.sh` in a cloud session when `codeo@codeo` or `superpowers@superpowers-marketplace` is missing (`.claude/hooks/session-start.sh`, a second `SessionStart` group in `.claude/settings.json`). It is not in #161. It was added at the engineer's request so the `/codeo:*` commands load in a web session. The command is gated on `CLAUDE_CODE_REMOTE`, because `tests/devcontainer.test.sh` requires every hook other than session-title to be.
- `tests/live-signal.test.sh`: the `SessionStart groups` assertion went from 1 to 2, since the repo now has two `SessionStart` groups. The check beside it that `SessionStart` takes no lock is untouched. `tests/devcontainer.test.sh` and `tests/live-signal.test.sh` both ended `all cases passed` after the change.
- The work ran on `claude/ecstatic-mendel-n3qyzl`, as the session required, and was fast-forwarded onto `docs/documentation-leftovers-154-146-removal` at the engineer's request so the lock's branch holds it.
- Neither `/codeo:plan` nor `/codeo:implement` ran for this issue; the plan file and these two dossiers were written afterwards.

**Minor findings left for `/codeo:qc`, none blocking:**
- The `.devcontainer/codeo` line numbers the issue cites are stale (`docker ps -a … || die` is now at `.devcontainer/codeo:701`, not `:658`). No README text carries a line number, so nothing is wrong there.
- The hook change widens the PR beyond a documentation fix; whether it belongs here is the engineer's call.

**Subagents:** none dispatched.

## Log

- 2026-11-24 — implementation recorded after the work: 6cf2227, a2c7114 · cost: unavailable
