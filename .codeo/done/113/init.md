# Issue #113 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/113 |
| Branch | `feat/cmd-mode-start-use-home` |
| Updated | 2026-11-16 |

## Where this stands

Branch `feat/cmd-mode-start-use-home` cut off `main` at bb396d1, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/113 — Cmd mode: start and use the home and issue containers from a Linux or macOS command line, without VS Code |
| State | open · labels `enhancement` |
| Branch | `feat/cmd-mode-start-use-home` off `main` at `bb396d1` |
| Board | Ready → In progress |

**Problem.** The `codeo-home` and `codeo-<N>` containers can today only be opened through a VS Code Dev Containers command, and a few start-up pieces assume VS Code (the container name from `${containerWorkspaceFolderBasename}`, `window-title.sh` writing `.vscode/settings.json`, `session-title.sh` requiring `REMOTE_CONTAINERS=true`, `devcontainer-start.sh` waiting for VS Code's `~/.gitconfig` copy). The issue asks for a "cmd mode": a plain host-side shell script, needing only Docker, that creates, starts, enters and removes both containers on Linux and macOS (bash 3.2), alongside the VS Code route, which stays unchanged.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] On a Linux host with Docker and no VS Code, one documented command starts `codeo-home` and ends with the start script's `ready` line or its `todo:` list.
- [ ] The same command does the same on macOS under `/bin/bash` (3.2), with no GNU tools installed.
- [ ] One documented command, given a pushed issue branch, starts `codeo-<N>` and prints `lock: took the lock for #<N> on <branch>`.
- [ ] `docker ps` shows the containers named `codeo-home` and `codeo-<N>`, and the removal commands `/codeo:close` and `/codeo:cleanup` print remove them.
- [ ] One documented command opens a shell in a running container; `claude` starts there and `/codeo:plan` passes the role guard in `codeo-<N>`.
- [ ] In a container started this way with a host git identity, `git config user.name` and `git config user.email` print it; running the start again changes neither.
- [ ] A Claude Code session in cmd-mode `codeo-<N>` is titled with the issue, and no `.vscode/settings.json` is created.
- [ ] `/codeo:init` in cmd-mode `codeo-home` prints the command-line step with the branch and `codeo-<N>` filled in.
- [ ] Opening the same repository through VS Code's Dev Containers command still works as before.
- [ ] `bash tests/run.sh` passes.

**Out of scope.** Retiring or replacing the VS Code route; the `devcontainer` CLI and Codespaces; Docker Sandboxes (`sbx`, #99); Windows hosts without WSL; making codeo's in-container scripts (bash 4.3+) run under macOS's bash 3.2; a single `codeo` host command wrapping the plugin's scripts.

**Open at intake.** Whether cmd mode should keep the Claude login (`/home/dev/.claude`, not on a volume) across rebuilds; whether Remote Control (`remoteControlAtStartup`) works in a container started without VS Code.

## Log

- 2026-11-16 — initialized: branch feat/cmd-mode-start-use-home off main at bb396d1 · cost: unavailable
