# Issue #50 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/50 |
| Branch | `feat/name-dev-container-after-its` |
| Updated | 2026-11-09 |

## Where this stands

Round 1, done. Plan tasks 1-3 are built and committed; `bash tests/run.sh` passes. Task 4 (the host checks) is the engineer's and waits for `/codeo:qc`. Next: `/codeo:qc`.

## Questions

None.

## Outcome

### Round 1

**Built** (plan `docs/plans/2026-11-09-name-dev-container-after-its-clone.md`, committed as `f245cf7`), inline in this session rather than through subagents — three small edits:
- Task 1 — `runArgs` in `.devcontainer/devcontainer.json` is `["--name=${localWorkspaceFolderBasename}-${devcontainerId}","--memory=4g","--cpus=2"]` (the engineer's edit, committed with the test); `tests/devcontainer.test.sh` gains `run_args_name_the_container_after_its_clone`, `run_args_cap_memory_and_cpus` now checks both caps are present, and the header comment names the new check. Red first: with the edit reverted the new case failed (`runArgs has no --name=…`); with it, `bash tests/run.sh devcontainer` passed.
- Task 2 — one Unreleased `CHANGELOG.md` bullet: the name, that a rebuild is needed, the `docker rm` for a same-named leftover.
- Task 3 — `bash tests/run.sh` passes.

**Documentation moved:** `CHANGELOG.md` only; no page under `docs/`, no wiki module.

**Build:** the `shell` suite's `build` is `true`; exit 0. No shared environment is configured: no lease, no deployment.

**Deviations from the plan:** none in what was built. Two small points: step 2a's `sync-main.sh` refuses a tree with tracked changes, so the engineer's `devcontainer.json` edit was stashed for the sync and popped; and the new case carries a `# shellcheck disable=SC2016` (the `${…}` is the text under test), so `shellcheck` reports only the one SC2016 note that was already on `main`.

**Still open for the engineer (Task 4):** rebuild again and see the same name; start a second clone with the same folder name and see a different suffix.

## Log

- 2026-11-09 — implemented: plan tasks 1-3 · cost: 2m · sonnet-5-5 19k in + 1.2M cached / 5k out
