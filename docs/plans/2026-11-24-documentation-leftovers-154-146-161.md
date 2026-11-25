# Documentation leftovers from #154 and #146 Implementation Plan

> Written after the work was done, from the commits `6cf2227` and `a2c7114`. It records what the change set out to do and the order the tasks were done in; it was not drafted before the code.

**Goal:** The README's removal flowchart and two paragraphs, the v1.0.8 `Shared state:` line and release checklist step 6 say what the code and the release do, as #161's acceptance criteria require.

**Architecture:** Documentation only, four edits in three files. Each README wording is checked against `.devcontainer/codeo` and `.sbx/codeo-sandbox.sh` before it is written. No script or test is edited by the issue's own work.

**Spec:** `.codeo/161/init.md` (`## Outcome`: the six acceptance criteria); the issue's findings #154 F1-F5 and #146 F1-F2.

## Global Constraints

- The Release notes of `v1.0.8` are not edited and the tag is not moved (out of scope; the engineer chose to skip the release edit).
- Out of scope: #154 F6 and #146 F3.
- The `## Unreleased` changelog block is untouched; the v1.0.8 `Shared state:` line is the one edited.

## Tasks

- [x] **Task 1: flowchart edges and node Q** in `.devcontainer/README.md`. Name the failed follow-up `docker ps -a` listing under `--force` on the `G` edge (`.devcontainer/codeo`, the `--force` branch after `docker rm -f`); drop the `--force` parenthesis from the `H` edge, which is reached only without `--force`; reword node `Q` so it is true for the "no such container, no --force" edge, where nothing was started.
- [x] **Task 2: inspect paragraph** in `.devcontainer/README.md`. "A container `codeo` knows it started for that read is stopped again", and say a failed `docker ps -a` leaves a started container running.
- [x] **Task 3: sandbox paragraph** in `.devcontainer/README.md`. Replace "because the script stops before it reads `--force`" with the real reason (`cmd_end` parses `--force`, then dies at the missing clone either way); keep `sbx rm --force codeo-<N>` as the way out.
- [x] **Task 4: v1.0.8 `Shared state:` line** in `CHANGELOG.md`. Name the exact `## Outcome` match in `dossier-check.sh`, `inflight.sh` and `qc-verdict.sh`, and the `### Round <n> — stashed|abandoned` reader (`is_parked`) in `lock.sh`.
- [x] **Task 5: release checklist step 6** in `docs/release-checklist.md`. Name the README installer examples and the `tests/install.test.sh` stubs as files a release also moves.
- [x] **Task 6: run the suite.** `bash tests/run.sh`; a failure is compared with the parent commit before it is called this change's.
