# Issue #113 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/113 |
| Branch | `feat/cmd-mode-start-use-home` |
| Updated | 2026-11-16 |

## Where this stands

Round 2 is written: back to `/codeo:plan`. Build and the full suite pass; two blocking findings (R1, the plan's: `issue` reuses an existing container, bypassing the stash-resume safeguard; R2, implement's: `CODEO_CONTEXT` is misdocumented) and six non-blocking. No question is open.

## Questions

## Outcome

### Round 1 — 2026-11-16

Reviewed `35fcef4` (merge base) .. `c13da4f` (HEAD).

**Sync and overlap.** `sync-main.sh --abort-on-conflict`: the branch already contains origin/main (no "also changed on main" lines). `overlap.sh 113`: nothing new (Q1-Q3 of implement.md raised #116's overlap). `overlap.sh --outside 113`: nothing outside the footprint.

**Scope.** `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/113/implement.md  .codeo/113/init.md  .codeo/113/issue.md  .codeo/113/plan.md  CHANGELOG.md
suite.shell=true
```

No `deploy=` line: no shared environment is configured, so there is no environment step.

**Build.** Suite `shell`, build `true`: exit 0.

**Tests.** Suite `shell`, `bash tests/run.sh`, run whole (the diff changes the scripts the criteria depend on): `all cases passed`, exit 0.

**Criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Linux, one command starts `codeo-home`, ends with `ready`/`todo:` | met in code, not run on a host | `tests/cmd-mode.test.sh` home call sequence against a stub `docker`; the real run is Task 10 |
| 2 | Same on macOS `/bin/bash` 3.2, no GNU tools | not yet checkable — needs the Mac | bash 3.2 / BSD construct scan in `tests/cmd-mode.test.sh` passes; see F2 on stock-Mac git |
| 3 | One command starts `codeo-<N>`, prints the lock line | met in code, not run on a host | issue call-sequence test; the lock comes from `devcontainer-start.sh` with the volume at `/workspaces` |
| 4 | `docker ps` names; removal commands remove them | met | `--name codeo-<N>`, volume `codeo-<N>`, README line on the printed removal commands |
| 5 | One command opens a shell; `claude` starts; role guard passes | met in code, not run on a host | `shell` test; reviewer traced `role.sh` (`/.dockerenv`, `/workspaces/codeo-<N>`) |
| 6 | Host identity reaches `git config`; rerun changes nothing | met | `start_cmd_mode_seeds_the_identity_from_the_environment_once` and the identity tests |
| 7 | Session titled, no `.vscode/settings.json` | met | `session-title.sh` gate and the cmd-mode cases in `tests/devcontainer.test.sh` |
| 8 | `/codeo:init` hand-off prints the command-line step | untestable here — needs a cmd-mode home container after merge | `tests/init-overlay.test.sh` needles pass on the overlay text |
| 9 | VS Code route still works | not yet checkable — needs VS Code | cmd-mode changes are gated on `CODEO_CMD_MODE`; `session_title_with_both_variables_still_refreshes_the_window_title` pins it |
| 10 | `bash tests/run.sh` passes | met | `all cases passed`, exit 0 |

**Documentation.** Pages touched: `.devcontainer/README.md` (command-line section, diagram, rebuild, removal) and `CHANGELOG.md`; the plan says no page under `docs/` moves, and none does. One untrue sentence found (F1).

**Independent review** (opus, given the criteria only): no Critical or Important issues; "With fixes". Its findings are F1-F7 below.

**Findings.**
- **F1 — blocking, `/codeo:implement`'s.** `.devcontainer/README.md:65` says the container has "the same name, hostname, 4 GB memory cap" as the VS Code route's. `codeo-container.sh:67` passes `--hostname "$name"`, and `devcontainer.json` `runArgs` carry only `--name` and `--memory=4g`, so the hostnames differ. Fix: drop "hostname" from that sentence and list it among what differs.
- **F2 — non-blocking, implement's.** `codeo-container.sh` `run_start` calls `command -v git` then `git config`; on a stock Mac `/usr/bin/git` is a stub that opens the Command Line Tools install dialog. Guard the call on Darwin with `xcode-select -p` and fall back to `GIT_AUTHOR_*`. Recommended in the same round as F1, since it bears on criterion 2.
- **F3 — non-blocking.** `cmd_shell` uses `-it` only when stdin and stdout are both TTYs; piped stdin gets no `-i`. Pass `-i` whenever stdin is not a TTY.
- **F4 — non-blocking.** Each issue leaves a `codeo-dev:codeo-<N>` image tag that the printed removal commands never remove; the README says those commands "serve" a cmd-mode container. Mention `docker image rm codeo-dev:codeo-<N>`.
- **F5 — non-blocking.** README says the usual first TODO is the Claude login; the GitHub login TODO comes first on an empty `codeo-gh` volume. Reword to "run what the TODOs say in `shell`".
- **F6 — non-blocking.** `tests/cmd-mode.test.sh` is mode 100644, its siblings 100755.
- **F7 — non-blocking.** `run_start` reads the identity from the current directory's `git config`; a repository-local override leaks in. `git config --global` is more predictable.
- Also recorded from implement.md's outcome: `codeo-dev:<name>` images are never removed (F4), `--rebuild` may reuse cached layers, `home` on a VS Code-created container runs the start script without `CODEO_CMD_MODE`. None is a finding against the criteria.

**Not proved here** (Task 10, the engineer's): macOS bash 3.2, a real Docker/BuildKit build from the Git URL, login-shell PATH, Remote Control in cmd mode, the VS Code route, the post-merge `/codeo:init` hand-off check.

**Verdict: back to `/codeo:implement`.**


### Round 2 — 2026-11-16

Reviewed `35fcef4` (merge base) .. `269ba8b` (HEAD), after implement.md round 2.

**Recap of round 1.** F1 (blocking in round 1) — fixed by e00cbb8 (README no longer claims the same hostname). F2-F7 (non-blocking in round 1) — fixed by c37241b, 5c00fd7, e00cbb8 and 4642fcb.

**Sync and overlap.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 113`: nothing. `overlap.sh --outside 113`: nothing.

**Scope.** `scope.sh origin/main HEAD`: `suite.shell=true` (unclassified paths: the `.codeo/113/*` dossiers and `CHANGELOG.md`). No `deploy=` line; no shared environment is configured.

**Build.** `shell` build `true`: exit 0.

**Tests.** `bash tests/run.sh`, run whole: `all cases passed`, `exit=0`.

**Criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Linux, one command starts `codeo-home`, ends with `ready`/`todo:` | met in code, not run on a host | home call-sequence test in `tests/cmd-mode.test.sh` (stub `docker`); the real run is Task 10 |
| 2 | Same on macOS `/bin/bash` 3.2, no GNU tools | not yet checkable — needs the Mac | bash 3.2/BSD scan passes; Darwin `xcode-select` cases pass with stubs |
| 3 | One command starts `codeo-<N>`, prints the lock line | met in code, not run on a host | issue call-sequence test; see R1 for an existing container |
| 4 | `docker ps` names; removal commands remove them | met | `--name codeo-<N>`, volume `codeo-<N>`; README removal paragraph |
| 5 | One command opens a shell; `claude` starts; role guard passes | met in code, not run on a host | `shell` tests incl. `shell_without_a_terminal_passes_i_only`; `role.sh` sees `/.dockerenv` and `/workspaces/codeo-<N>` |
| 6 | Host identity reaches `git config`; rerun changes nothing | met | `start_cmd_mode_seeds_the_identity_from_the_environment_once`, `identity_comes_from_the_global_config_not_the_current_directory` |
| 7 | Session titled, no `.vscode/settings.json` | met | `session-title.sh` gate and the cmd-mode cases in `tests/devcontainer.test.sh` |
| 8 | `/codeo:init` hand-off prints the command-line step | untestable here — needs a cmd-mode home container after merge | `tests/init-overlay.test.sh` needles pass |
| 9 | VS Code route still works | not yet checkable — needs VS Code | changes gated on `CODEO_CMD_MODE`; `session_title_with_both_variables_still_refreshes_the_window_title` |
| 10 | `bash tests/run.sh` passes | met | `all cases passed`, `exit=0` |

**Documentation.** `.devcontainer/README.md` and `CHANGELOG.md` checked against the code; two statements are untrue (R1's line 116 for this route, R2) and one holds only for a moment (R3).

**Independent review** (opus, given the criteria only): no Critical; two Important, six Minor; "With fixes".

**Findings.**
- **R1 — blocking, `/codeo:plan`'s.** `codeo-container.sh issue <N> <branch>` on an existing `codeo-<N>` (running or stopped) starts it and re-runs the start script in the old clone (`ensure_container` lines 56-61, `ensure_clone` line 77 skips a clone that has `.git`), whatever branch or workflow state the clone is in. The plan specified exactly this re-run behaviour, so the code does what the plan says; the plan missed the stash → resume path. `role.sh:138` tells a stashed container "`/codeo:init #<N>` in the home container is the way back, never the start script … remove this one on the host first", and `.devcontainer/README.md:116` relies on Docker's `name already in use` to stop a second container. In cmd mode nothing stops it: the resume command `/codeo:init` prints runs the start script in the stale clone, `lock.sh` takes the lock from its old `init.md`, and the engineer works in an out-of-date clone; a mistyped branch is accepted the same way. The plan must decide what `issue` does with an existing container (refuse unless `--rebuild`/a reuse flag, or check the clone's branch and its `role.sh` state), and the README line 116 and the init hand-off must say what applies to this route.
- **R2 — blocking, `/codeo:implement`'s.** `CODEO_CONTEXT` is documented as "a local directory … for a developer's own clone" (`README.md:78`, `codeo-container.sh:12`, `CHANGELOG.md:22`), but `docker build "$CODEO_CONTEXT"` (line 65) needs the directory that holds the `Dockerfile`, `.devcontainer`; a clone root fails with no Dockerfile. The repository is still cloned from `CODEO_REPO_URL`, which the text does not say. Say "the `.devcontainer` directory of a local clone; only the image is built from it".
- **R3 — non-blocking, implement's; fix in the same round.** `shell` sets the title `codeo [#<N>]`, then `bash -l` reads Ubuntu's `~/.bashrc`, whose xterm `PS1` retitles the terminal to `dev@codeo-<N>: …` at the first prompt. README lines 10, 69 and 72 say the terminal title is `codeo [#<N>]`. Describe it accurately or make it last.
- **R4 — non-blocking.** The "These differ" list omits `--init` (`codeo-container.sh:67`; `devcontainer.json` sets none).
- **R5 — non-blocking.** `require_docker` prints "install it and start it" for any `docker info` failure, including a running daemon the user may not reach (not in the `docker` group).
- **R6 — non-blocking.** `devcontainer-start.sh` treats any non-empty `CODEO_CMD_MODE` as cmd mode; `session-title.sh:20` requires `1`. Only the script sets it, always to `1`.
- **R7 — non-blocking.** Bash 3.2 is proved only by a text scan; criterion 2 waits on the Mac (Task 10).
- **R8 — non-blocking.** The `codeo-dev:codeo-<N>` image is not in the commands `/codeo:close` and `/codeo:cleanup` print; the README says how to remove it.

**Routing.** R1 is the plan's: it decides what `issue` does on an existing container. R2 and R3 (and any of R4-R6 taken up) go to `/codeo:implement` with the re-planned task.

**Verdict: back to `/codeo:plan`.**

## Log

- 2026-11-16 — round 1: build and full suite pass; review found 1 blocking (README hostname claim), 6 non-blocking; sent back to implement · cost: 4m · opus-5-5 227k in + 2.4M cached / 22k out · sonnet-5-5 134k in + 342k cached / 4k out
- 2026-11-16 — round 2: build and full suite pass; review found R1 (blocking, plan's) and R2 (blocking, implement's), six non-blocking; sent back to plan · cost: 5m · opus-5-5 309k in + 2.3M cached / 28k out
