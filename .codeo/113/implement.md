# Issue #113 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/113 |
| Branch | `feat/cmd-mode-start-use-home` |
| Updated | 2026-11-16 |

## Where this stands

Round 3 is built: Tasks 1-3 of `docs/plans/2026-11-16-cmd-mode-existing-container.md` (QC round 2's R1-R6), reviewed, build passing, handed to `/codeo:qc`; Task 4 is the engineer's. Earlier, in round 1, Q1-Q3 were answered and Tasks 1-9 of `docs/plans/2026-11-16-cmd-mode-containers.md` are built, reviewed task by task and as a whole branch (verdict: ship), and pushed; the configured build (`true`) passes and the full `bash tests/run.sh` passed in each task. Task 10 is the engineer's (host checks on WSL2 and a Mac), not this skill's.

Q1-Q3 (#116's overlap) are answered: proceed and coordinate. Nothing is open.

## Questions

### Q1 — #116 also changes `.devcontainer/README.md`: proceed, sequence or re-scope?

**Why it matters:** this branch adds a section to `.devcontainer/README.md` (the command-line route, `--rebuild`, removal, the table row). #116 (branch `fix/follow-ups-70-71-104`, assignee kbajpai, at `init`) lists `.devcontainer/README.md` in its footprint, and `overlap.sh` prints `116  .devcontainer/README.md` and `116  glob:.devcontainer/README.md`. If #116 edits other paragraphs, whichever merges second resolves a text conflict; if both edit the same lines, the second has to merge by hand. The answer decides whether anything is changed here.

**Options:** *proceed and coordinate* (recommended: this branch only adds a new section after *Opening a container* and one table row, so a conflict is unlikely and small) · *sequence after #116* (this branch waits for #116's merge, then merges `main`) · *re-scope* (drop the README change from this branch; the docs task would be reopened).

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-16).

### Q2 — #116 also changes `CHANGELOG.md`: proceed, sequence or re-scope?

**Why it matters:** this branch adds one bullet under `## Unreleased`. #116 (branch `fix/follow-ups-70-71-104`, assignee kbajpai, at `init`) lists `CHANGELOG.md` in its footprint (`overlap.sh`: `116  CHANGELOG.md`, `116  glob:CHANGELOG.md`). Both add bullets to the same list; the second to merge resolves a one-line conflict.

**Options:** *proceed and coordinate* (recommended, as with #104, whose merge was clean) · *sequence after #116* · *re-scope* (leave `CHANGELOG.md` out).

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-16).

### Q3 — #116 also changes `tests/devcontainer.test.sh`: proceed, sequence or re-scope?

**Why it matters:** Tasks 1-2 added six cases and their `cases=( … )` entries, a `ds_run` line and an `st_run` line to `tests/devcontainer.test.sh`. #116 (branch `fix/follow-ups-70-71-104`, assignee kbajpai, at `init`) lists `tests/devcontainer.test.sh` in its footprint (`overlap.sh`: `116  tests/devcontainer.test.sh`, `116  glob:tests/devcontainer.test.sh`). A second branch to merge adds its own cases to the same `cases=( … )` array, so a conflict there is likely but mechanical.

**Options:** *proceed and coordinate* (recommended) · *sequence after #116* · *re-scope* (not workable: the cases belong with the code they test).

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-16).

## Outcome

### Round 1

Plan `docs/plans/2026-11-16-cmd-mode-containers.md`, Tasks 1-9 built and reviewed task by task and as a whole branch (verdict: ship). Task 10 is the engineer's (host checks), not this skill's.

**Built.**
- `.devcontainer/codeo-container.sh` (new, bash 3.2, builtins plus `docker` and `git`): `home [--rebuild]`, `issue <N> <branch> [--rebuild]`, `shell home|<N>`; image built from the GitHub URL, same names, volumes and memory cap as the VS Code route, host git identity passed as `GIT_AUTHOR_*` to the start script only.
- `.devcontainer/scripts/devcontainer-start.sh` and `session-title.sh`: `CODEO_CMD_MODE=1` skips `window-title.sh` and the `~/.gitconfig` wait and titles the session without `.vscode/settings.json`; the VS Code path is unchanged.
- `.codeo/overlays/init.md`: the hand-off prints both routes.
- Tests: `tests/cmd-mode.test.sh` (stub `docker`, call sequences, validation, bash 3.2 scan), six cases in `tests/devcontainer.test.sh`, three needles in `tests/init-overlay.test.sh`.

**Documentation changed.** `.devcontainer/README.md` (command-line route, Mermaid sequence diagram, rebuild, removal, identity, titles) and `CHANGELOG.md` (one bullet). No page under `docs/` moves.

**Build.** Configured `shell` suite build is `true`: exit 0. The full `bash tests/run.sh` passed in each task.

**Overlap.** #116 (`fix/follow-ups-70-71-104`) also lists `.devcontainer/README.md`, `CHANGELOG.md` and `tests/devcontainer.test.sh`; Q1-Q3 answered *proceed and coordinate*. `overlap.sh 113` prints nothing. `sync-main.sh`: the branch already contains `origin/main`; no "also changed on main" lines.

**Deviations.** None from the plan. Rulings made while building: `cm_run` in the tests runs with `GIT_AUTHOR_*` unset; minors from Tasks 3, 4 and 6 were carried into later tasks. Parked minors: the scan reports line numbers from the comment-stripped stream; `CODEO_CONTEXT` doc wording; `a//b` passes branch validation; the container id prints on stdout; `codeo-dev:<name>` images are never removed; `--rebuild` may reuse cached layers; `home` on a VS Code-created container runs the start script without `CODEO_CMD_MODE`.

**Not proved here** (Task 10, the engineer's): macOS `/bin/bash` 3.2, a real Docker/BuildKit build, login-shell PATH, Remote Control in cmd mode, the VS Code route, and the `/codeo:init` hand-off in a cmd-mode home container (after merge).

### Round 2
2026-11-16
(send-back from qc.md round 1)

QC round 1 held one blocking finding (F1) and six non-blocking ones; all seven were checked against the code and held.

**Fixed.**
- F1 (blocking): `.devcontainer/README.md` no longer says the hostname is the same as the VS Code route's; a bullet under "These differ" says it is the container's name. Pinned by `docs_readme_states_the_hostname_difference`.
- F2: `codeo-container.sh` reads the host git config only when git is usable: on Darwin `xcode-select -p` must succeed first, else the `GIT_AUTHOR_*` fallback applies (new `git_is_usable`; three cases with stub `uname`, `xcode-select` and `git`).
- F3: `shell` passes `-i` always and `-it` when stdin and stdout are terminals (`shell_without_a_terminal_passes_i_only`).
- F4: the README's removal paragraph names `docker image rm codeo-dev:codeo-<N>`.
- F5: the README describes the first-run TODOs as the logins in order (GitHub, then Claude Code).
- F6: `tests/cmd-mode.test.sh` is mode 100755.
- F7: the identity is read with `git config --global`, so a repository-local identity is never passed (`identity_comes_from_the_global_config_not_the_current_directory`); the README says so.

**Documentation changed.** `.devcontainer/README.md` only.

**Build.** Configured `shell` suite build `true`: exit 0. The three affected test files pass (`cmd-mode`, `devcontainer`, `init-overlay`); the full suite is `/codeo:qc`'s.

**Deviations.** None. The `-it` path of F3 has no test, since it needs a pseudo-terminal. `sync-main.sh`: already contains `origin/main`; `overlap.sh 113` prints nothing.

### Round 3
2026-11-16
(after plan.md round 2, answering qc.md round 2)

Plan `docs/plans/2026-11-16-cmd-mode-existing-container.md`, Tasks 1-3 built, each reviewed, then one review of the round as a whole. Task 4 is the engineer's (host check), not this skill's. QC round 2's R1-R6 were each checked against the code and held.

**Built.**
- Task 1 (R1): `issue <N> <branch>` on an existing `codeo-<N>`, running or stopped, exits 1 with one line naming `shell <N>`, `--rebuild` and removal, and starts nothing; with `--rebuild`, or a volume left without its container, the clone must be on `<branch>` (a detached HEAD counts as a mismatch). `home` keeps its re-run. Six new cases and an updated `issue_rebuild_and_rerun_follow_home`.
- Task 2 (R5, R6, R2's header): `require_docker` shows Docker's own first error line, falling back to the old text when stderr is empty; `session-title.sh` accepts any non-empty `CODEO_CMD_MODE`; the script header describes `CODEO_CONTEXT` as the `.devcontainer` directory of a local clone. Two new cases.
- Task 3 (R2, R3, R4, stash paragraph): `.devcontainer/README.md`, `.codeo/overlays/init.md` and the `(#113)` bullet in `CHANGELOG.md` say what the code does; three `docs_readme_*` cases and an overlay needle.
- Fix wave after the whole-round review: the branch-mismatch message names `docker rm -f codeo-<N>` before `docker volume rm codeo-<N>`, and prints `(no branch)` for a detached HEAD.

**Documentation changed.** `.devcontainer/README.md`, `.codeo/overlays/init.md`, `CHANGELOG.md`. No page under `docs/` moves.

**Build.** Configured `shell` suite build `true`: exit 0. The full `bash tests/run.sh` printed `all cases passed` in Tasks 1-3; the full suite is `/codeo:qc`'s.

**Overlap.** `sync-main.sh`: the branch already contains `origin/main`; `overlap.sh 113` prints nothing.

**Deviations.** One, from the plan's exact text for Task 1's branch-mismatch message. The plan says `remove the volume (docker volume rm codeo-<N>, …)`, but when the mismatch is found `ensure_container` has already created or recreated the container, which mounts the volume, so `docker volume rm` fails with "volume in use". The message now reads `remove it (docker rm -f codeo-<N>; docker volume rm codeo-<N>, once git status in it shows nothing unpushed)`. `docs/plans/2026-11-16-cmd-mode-existing-container.md` line 43 still quotes the old text; the plan is not edited here. Also, a detached HEAD prints `(no branch)` instead of `''`.

**Parked minors.** With `--rebuild` and a mismatch, the container is already rebuilt and left running when the refusal comes; `docker info`'s stderr is used raw (a leading blank line falls back to the generic text, control characters pass through); the init overlay's new sentence is appended to an already long line; the README's rebuild paragraph says the old container and volume must be removed, though `issue … --rebuild` on the same branch would also pass.

**Not proved here** (the engineer's, host): Task 4 (`issue` on a running `codeo-<N>` refuses and leaves `docker ps` unchanged), the first plan's Task 10, and the cmd-mode checks on Docker, Mac `/bin/bash` 3.2 and the VS Code route.

## Log

- 2026-11-16 — Tasks 1-9 built and reviewed, Q1-Q3 raised on #116's overlap · cost: 71m · sonnet-5-5 992k in + 26.4M cached / 160k out
- 2026-11-16 — Q1-Q3 answered (proceed and coordinate); outcome written, build passed, handed to qc · cost: 0m · sonnet-5-5 86k in + 348k cached / 2k out
- 2026-11-16 — round 2: fixed qc round 1's F1-F7, build passed, handed to qc · cost: 4m · sonnet-5-5 234k in + 1.8M cached / 15k out
- 2026-11-16 — round 3: built the follow-up plan (Tasks 1-3, each reviewed and the round as a whole), one fix wave, build passed, handed to qc · cost: 36m · sonnet-5-5 363k in + 9.7M cached / 58k out
