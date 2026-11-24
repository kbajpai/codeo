# Issue #161 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/161 |
| Branch | `docs/documentation-leftovers-154-146-removal` |
| Updated | 2026-11-24 |

## Where this stands

Round 3 is written, answering `qc.md` round 2: F3, its one blocking finding, is fixed in `.devcontainer/README.md`. Written after the edit, in the same hosted web session, not through `/codeo:implement`, so there was no per-task subagent dispatch. F4-F8 are non-blocking and were left as they are. Next step: `/codeo:qc` for round 3, from step 0.

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

### Round 2 — 2026-11-24

(send-back from qc.md round 1)

**Built** (one commit on top of the `qc.md` round 1 commit `ac4b211`):

- **F1** (`.devcontainer/README.md`, the `H` edge): the label is now `docker rm -f failed`. `H` is reached only without `--force`, where `cmd_rm` dies on any `docker rm -f` failure with no listing (`.devcontainer/codeo:697`); the "only while the container is still listed" clause belongs to the `--force` branch at `:701`.
- **F2** (`.devcontainer/README.md`, node `Q`): the label is now `refuse: nothing removed (a container codeo knows it started for the read is stopped again)`, the wording the inspect paragraph already uses, because `stop_started` stops only a container `codeo` knows it started (`.devcontainer/codeo:477-478, 537`).

**Documentation pages changed:** `.devcontainer/README.md`. No wiki module.

**Build result:** documentation only. `tests/devcontainer.test.sh` and `tests/codeo-command.test.sh`, the two files that read this README, both exit 0 after the edit; the full `tests/run.sh` was not re-run (round 1's run failed only in `install.test.sh`, the same 57 cases as `origin/main`, from this sandbox's guard `rm`).

**Deviations from the round 1 findings, and why:** none for F1 and F2.

**Left as they are, none blocking:** F3 (the `G` edge wording), F4 (the release checklist's "latest release"), F5 (the hook's skip check) and F6 (the `SessionStart` hook outside the issue's scope). They are recorded in `qc.md` round 1 as non-blocking, so this round did not take them.

**Subagents:** none dispatched.

### Round 3 — 2026-11-24

(send-back from qc.md round 2)

**Built** (one commit on top of the `qc.md` round 2 commit):

- **F3** (`.devcontainer/README.md`, the `G` edge): the label is now `docker rm -f failed (with --force, only when the follow-up docker ps -a listing fails or still lists the container), or volume rm failed and the volume still exists`. Without `--force` any `docker rm -f` failure ends in `Y` (`.devcontainer/codeo:697`); with `--force` the follow-up listing runs only after `docker rm -f` has failed, and a failure there, or a listing that still names the container, ends in `Y` (`:699-701`).

**Documentation pages changed:** `.devcontainer/README.md`. No wiki module.

**Build result:** documentation only. `tests/devcontainer.test.sh` and `tests/codeo-command.test.sh`, the two files that read this README, both exit 0 after the edit; the full `tests/run.sh` was not re-run (round 2's run failed only in `install.test.sh`, the same 57 cases as `origin/main`, from this sandbox's guard `rm`).

**Deviations from the round 2 findings, and why:** none for F3.

**Left as they are, none blocking:** F4 (the release checklist's "latest release"), F5 (the hook's skip check), F6 (the `SessionStart` hook outside the issue's scope), F7 (`CHANGELOG.md:23`'s "no longer count" for `dossier-check.sh`) and F8 (the hook comment). They are recorded in `qc.md` round 2 as non-blocking, so this round did not take them.

**Subagents:** none dispatched.

## Log

- 2026-11-24 — implementation recorded after the work: 6cf2227, a2c7114 · cost: unavailable
- 2026-11-24 — round 2 recorded after the edits: F1, F2 from qc.md round 1 · cost: unavailable
- 2026-11-24 — round 3 recorded after the edit: F3 from qc.md round 2 · cost: unavailable
