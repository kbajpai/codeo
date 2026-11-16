# Issue new-cmd-mode — issue

| | |
|---|---|
| Working title | Cmd mode: start and use the home and issue containers from a Linux command line, without VS Code |
| Source | Engineer's request: "how can we add 'cmd mode' codeo, devcontainer, etc. all to run on Linux command line instead of VS Code" |
| Updated | 2026-11-16 |

## Where this stands

Restated: codeo's scripts, hooks and skills are bash and already run from a plain shell, but the only documented way to create and name the `codeo-home` and `codeo-<N>` containers is a VS Code Dev Containers command, and a few start-up pieces assume VS Code. The request is a second, command-line route to the same containers. All three questions are answered and the draft is approved.

Checked, not assumed:
- **No duplicate.** The open issues hold nothing on this. #99 (sbx issue sandbox, Windows + WSL2) is the nearest; it is a different launcher and stays separate.
- **Where VS Code is assumed:** `.devcontainer/README.md` and the `init` hand-off in `.codeo/overlays/init.md` (the only documented way in); `devcontainer.json`'s `--name=${containerWorkspaceFolderBasename}`; `window-title.sh` writing `.vscode/settings.json`; `session-title.sh` exiting unless `REMOTE_CONTAINERS=true`; `devcontainer-start.sh` waiting for the `~/.gitconfig` VS Code copies in.
- **Already editor-agnostic:** `scripts/*.sh`, `lib/env.sh`, the hooks, and `role.sh`, `folder-check.sh`, `container-name.sh`, `plugins.sh`, `codeo-root.sh` and most of `devcontainer-start.sh`.
- **Earlier decisions:** the plans for #36 and #44 ruled the `devcontainer` CLI and Codespaces out of scope.

## Questions

### Q1 — What should come out of this: an issue, or an implementation?

**Why it matters:** the skill was invoked as `/codeo:issue`, which was not installed in the session, so the request arrived as a plain question.

**Options:** file the issue (recommended) · implement it now · both.

**Answer:**
File the issue (engineer, in the conversation, 2026-11-16).

### Q2 — How should cmd mode start the containers?

**Why it matters:** it decides what the host needs and whether `devcontainer.json` stays the single source.

**Options:**
- *Plain docker script* (recommended): builds the existing Dockerfile and runs docker with the same names, volumes and start script. Needs only Docker on the host.
- *`devcontainer` CLI*: needs Node on the host; rejected in #36's plan.
- *Docker Sandboxes (sbx)*: fold into #99.
- *Leave it open* for the plan step.

**Answer:**
Plain docker script (engineer, in the conversation, 2026-11-16).

### Q3 — Besides starting the containers, which VS Code-only pieces should cmd mode cover?

**Why it matters:** it sets the issue's scope and its acceptance criteria.

**Options (any of):** session/window titles · the `init` hand-off text · git identity seeding · docs.

**Answer:**
All four (engineer, in the conversation, 2026-11-16).

## Draft

**Title:** Cmd mode: start and use the home and issue containers from a Linux command line, without VS Code

**Type:** Feature. **Labels:** `enhancement`.

### Description

Add a "cmd mode": a way to create, enter and work in the `codeo-home` and `codeo-<N>` containers from a Linux command line with only Docker on the host. Today the only documented way to open either container is a VS Code command, and a few start-up pieces assume VS Code. The VS Code route stays as it is; cmd mode is a second route to the same containers.

### Motivation / Context

codeo's scripts, hooks and skills are bash and already run from a plain shell. VS Code is needed only for the container around them:

- `.devcontainer/README.md` and the `init` hand-off (`.codeo/overlays/init.md`) tell the engineer to run "Dev Containers: Clone Repository in Named Container Volume…".
- The container's name comes from `${containerWorkspaceFolderBasename}` in `devcontainer.json`, which only a devcontainer tool fills in.
- `window-title.sh` writes the title to `.vscode/settings.json`, and `session-title.sh` exits unless `REMOTE_CONTAINERS=true`, so sessions outside VS Code get no issue title.
- `devcontainer-start.sh` waits for the `~/.gitconfig` VS Code copies in; without it the engineer gets a `todo:` unless `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL` are set.

An engineer on a Linux server over SSH, or one who does not use VS Code, cannot follow the documented workflow.

### Key Requirements

- A plain shell script, needing only Docker on the host, creates and starts the home container and an issue container for a branch `/codeo:init` pushed. It uses the existing `Dockerfile`, the same container and volume names (`codeo-home`, `codeo-<N>`), the same `codeo-gh` and `codeo-git` volumes, and runs `devcontainer-start.sh`.
- The same route gives a shell in a running container, from which `claude` starts.
- An issue container started this way takes its lock from the branch's `init.md`, and the folder check and role guard behave as in a VS Code container.
- Git identity is seeded from the host's git config when the container is started from the command line, else from `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`; a value already set is never overwritten.
- A Claude Code session in a cmd-mode container is titled with its issue, and the terminal shows which container it is in, without writing `.vscode/settings.json`.
- The `init` hand-off prints the command-line step alongside the VS Code one.
- `.devcontainer/README.md` documents the command-line route: create, enter, rebuild, remove.
- The VS Code route is unchanged and keeps working.

### Acceptance Criteria

- [ ] On a Linux host with Docker and no VS Code, one documented command starts `codeo-home` and ends with the start script's `ready` line or its `todo:` list.
- [ ] One documented command, given a pushed issue branch, starts `codeo-<N>` and prints `lock: took the lock for #<N> on <branch>`.
- [ ] `docker ps` shows the containers named `codeo-home` and `codeo-<N>`, and the removal commands `/codeo:close` and `/codeo:cleanup` print remove them.
- [ ] One documented command opens a shell in a running container; `claude` starts there and `/codeo:plan` passes the role guard in `codeo-<N>`.
- [ ] In a container started this way with a host git identity, `git config user.name` and `git config user.email` print it; running the start again changes neither.
- [ ] A Claude Code session in cmd-mode `codeo-<N>` is titled with the issue, and no `.vscode/settings.json` is created.
- [ ] `/codeo:init` in cmd-mode `codeo-home` prints the command-line step with the branch and `codeo-<N>` filled in.
- [ ] Opening the same repository through VS Code's Dev Containers command still works as before.
- [ ] `bash tests/run.sh` passes.

### Out of Scope

- Retiring or replacing the VS Code route.
- The `devcontainer` CLI (`@devcontainers/cli`) and Codespaces.
- Docker Sandboxes (`sbx`): #99.
- Non-Linux hosts (macOS, Windows without WSL).
- A single `codeo` host command that wraps the plugin's scripts.

### Open Questions

- The Claude login lives in `/home/dev/.claude`, which is not on a volume, so it is lost on every rebuild. Whether cmd mode should keep it across rebuilds is undecided.
- Whether Remote Control (`remoteControlAtStartup`) works in a container started without VS Code has not been tried.

### Reference

- `.devcontainer/devcontainer.json`, `.devcontainer/Dockerfile`, `.devcontainer/README.md`
- `.devcontainer/scripts/devcontainer-start.sh`, `window-title.sh`, `session-title.sh`, `container-name.sh`
- `.codeo/overlays/init.md` (host-workflow hand-off)
- `docs/plans/2026-11-07-dev-container.md` and `docs/plans/2026-11-08-dev-container-session-titles.md`, which ruled the `devcontainer` CLI out of scope at the time
- Related: #99 (sbx issue sandbox)

## Log

- 2026-11-16 — Q1-Q3 raised and answered; draft approved by the engineer · cost: unavailable
