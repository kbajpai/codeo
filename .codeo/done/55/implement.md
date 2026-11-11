# Issue #55 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/55 |
| Branch | `feat/dev-container-home-container-starting` |
| Plan | `docs/plans/2026-11-10-home-and-issue-containers.md` |
| Updated | 2026-11-10 |

## Where this stands

Round 1 done: all eight tasks built and reviewed; build step is the `shell` suite's `build` (`true`). No open question.

## Questions

None.

## Outcome

**Built** (commits `a829747`..`5ea1be1` on top of the plan commit `1291d4d`):
- Task 1 — `.devcontainer/scripts/container-name.sh` (`[--docker|--codename] [dir]`) and `tests/container-name.test.sh`; `window-title.sh` takes its title from it.
- Task 2 — `folder-check.sh` and `tests/folder-check.test.sh`.
- Task 3 — `codeo-root.sh` and `tests/codeo-root.test.sh`.
- Task 4 — `devcontainer-start.sh` takes the lock (`lock.sh take container`, output verbatim, none on the base branch or when a lock is held, TODOs for a detached HEAD, a crash, a missing codeo) and runs the folder check; eight new cases in `tests/devcontainer.test.sh`; one fix round (the mount-prefix boundary case kept its strength after the scratch clone was renamed to `codeo-home`).
- Task 5 — `runArgs` is `["--name=${containerWorkspaceFolderBasename}","--memory=4g","--cpus=2"]`, pinned exactly; `.codeo/overlays/**` added to the `shell` suite paths.
- Task 6 — `.codeo/overlays/init.md` (`## host-workflow`) and `tests/init-overlay.test.sh`.
- Task 7 — `.devcontainer/README.md`, a "Dev container" section in `README.md`, one CHANGELOG bullet.
- Task 8 — whole suite run; the host checks (rebuild, `init` from `codeo-home`, clone into `codeo-<N>`, both containers open, the `${containerWorkspaceFolderBasename}` substitution) are the engineer's and are not run here.

**Documentation changed:** `.devcontainer/README.md` (new), `README.md`, `CHANGELOG.md`.

**Build result:** the suite's `build` is `true`. `bash tests/run.sh`: every file passes except `tests/agnostic.test.sh`; `shellcheck -S warning` is clean on the scripts and tests this branch touches.

**Deviations from the plan, and a finding for the engineer:**
- `tests/agnostic.test.sh` fails on four tracked files that name the private reference project: `.codeo/55/init.md`, `.codeo/55/issue.md`, `.codeo/55/plan.md` and `docs/plans/2026-11-10-home-and-issue-containers.md`. None is a file this skill may edit (other skills' dossiers and the approved plan), so they were left as they are and no file this branch adds names the project. `/codeo:qc` will see the suite red until the engineer rewords those four files (and decides on #55's GitHub body, which also names it) or exempts them.
- `devcontainer-start.sh` prints the plugin's `lock:` lines verbatim, as the plan says; the folder check's `note:` lines are not produced (no legacy folder exists here).

**Deferred minors** (reviewers, none blocking): `folder-check.sh` hard-codes `main` where the start script honours `baseBranch`; header wording in `container-name.sh`; `window-title.sh` captures `container-name.sh` with `2>&1`; an untested bare `-home` folder on a non-main branch; the `lock.sh` crash output repeated in its failure TODO; the weak `.codeo/active` needle in `tests/init-overlay.test.sh`.

## Log

- 2026-11-10 — implemented: 8 tasks, 1 fix round on Task 4 · cost: unavailable
