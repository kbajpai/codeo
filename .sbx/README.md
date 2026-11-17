# Docker Sandboxes (sbx) issue sandbox

An issue's work can run in a Docker Sandboxes (sbx) sandbox instead of a dev container. One script does it: `.sbx/codeo-sandbox.sh`. The home container stays a dev container; only the issue's work moves. A sandbox is named `codeo-<N>`, after its issue, and works in a clone folder `codeo-<N>` on the host.

## Prerequisites

The host is Linux or WSL2 (never macOS) with bash 4.3 or later, `git` and `curl`.

- `sbx` v0.53.0, or `sbx.exe` reachable on `PATH` from WSL2. The script uses `sbx`, else `sbx.exe`; `CODEO_SBX` names the program instead.
- `sbx login`.
- `sbx secret set github --command 'gh auth token'`. The sandbox's `gh` holds a placeholder token that the sandbox's proxy replaces; the real token stays on the host, and pushes work.
- `sbx setup ssh` (experimental). It makes the `*.sbx` hosts resolve, which `open` needs.
- VS Code with Remote - SSH, and this user setting, which installs the extensions in every sandbox:

```json
"remote.SSH.defaultExtensions": ["anthropic.claude-code", "timonwong.shellcheck", "bierner.markdown-mermaid"]
```

No file under `.vscode/` is committed. The first time VS Code connects to each `codeo-<N>.sbx` host it asks for the remote platform; `remote.SSH.remotePlatform` maps the host to `linux` and stops the question.

## Getting the script

Download the script once:

```bash
curl -fsSL -o codeo-sandbox.sh https://raw.githubusercontent.com/kbajpai/codeo/main/.sbx/codeo-sandbox.sh
```

Run the commands from the directory that holds the downloaded file. The clone `codeo-<N>` is made in that directory. `codeo-sandbox.sh` reads the image pin from `claude-image` beside it; `CODEO_SBX_IMAGE` names another file, and `CODEO_REPO_URL` names another repository to clone (default `https://github.com/kbajpai/codeo.git`).

## Commands

| Command | What it does |
|---|---|
| `bash codeo-sandbox.sh issue <N> <branch>` | Clones `<branch>` into `./codeo-<N>` (or checks the clone is on `<branch>`), creates the sandbox `codeo-<N>` with 2 CPUs and 4 GB of memory at the pinned image, and runs the dev container's start script in it. That prints `lock: took the lock for #<N> on <branch>` and then `ready` or `TODO` lines. Run again, it creates nothing and starts a stopped sandbox. It prints one `todo:` line when the sandbox's lock names another issue. |
| `bash codeo-sandbox.sh open <N>` | Writes the window title in the sandbox and opens the sandbox's working folder in VS Code over SSH (`codeo-<N>.sbx`). It checks `ssh codeo-<N>.sbx -- true` first (`ssh.exe` with `sbx.exe`) and, when that fails, says to run `sbx setup ssh`. |
| `bash codeo-sandbox.sh shell <N>` | Opens a login bash in the sandbox's working folder. Start `claude` there. |
| `bash codeo-sandbox.sh end <N> [--force]` | Removes the sandbox when nothing in it is unpushed (see Ending a sandbox). |

```mermaid
sequenceDiagram
    participant E as Engineer (Linux or WSL2 bash)
    participant S as codeo-sandbox.sh
    participant G as host git / git.exe
    participant X as sbx or sbx.exe
    participant B as sandbox codeo-N
    E->>S: issue N branch
    S->>G: git clone --branch branch into ./codeo-N (or check the clone is on branch)
    S->>G: git.exe safe.directory line, only with sbx.exe and only when missing
    S->>X: create --clone --name codeo-N at the pinned image (only when it does not exist; else start it)
    S->>B: write the sandbox marker
    S->>B: env CODEO_CMD_MODE=1 GIT_AUTHOR_* bash .devcontainer/scripts/devcontainer-start.sh
    B-->>E: lock: took the lock for #N on branch, then ready or TODO lines
    S->>B: container-name.sh --docker, compared with codeo-N
    S-->>E: one todo: line when the lock names another issue
```

With `sbx.exe` from WSL2, the sandbox's working folder is `/wsl.localhost/$WSL_DISTRO_NAME<the clone's path on the host>`, and only Windows Git can fetch from the sandbox. `issue` adds a `safe.directory` entry for that path to Windows Git's global config once, or prints the `git.exe config` line as a `todo:` when `git.exe` is missing; `end` fetches with `git.exe`.

The start script turns on `remoteControlAtStartup` in the sandbox, as it does in a dev container. That is untried in a sandbox, and so is Remote Control from one.

## Ending a sandbox

`end <N>` replaces the `docker rm -f codeo-<N>; docker volume rm codeo-<N>` line that `/codeo:close` and `/codeo:cleanup` print for a dev container. Close any VS Code window connected to `codeo-<N>.sbx` first: the removal uses `sbx rm --force`, which cuts the window off.

```mermaid
flowchart TD
    A[end N] --> B{sandbox exists?}
    B -- no --> Z1[exit 1: no sandbox codeo-N]
    B -- yes --> C[start it if stopped]
    C --> D[git fetch sandbox-codeo-N in ./codeo-N]
    D -- fails --> Z2[exit 1, nothing removed]
    D --> F[git fetch origin]
    F -- fails --> Z3[exit 1: cannot prove anything is pushed, nothing removed]
    F --> E{any branch under refs/sandboxes/codeo-N/?}
    E -- none, no --force --> Z5[exit 1: nothing can be proved, nothing removed]
    E -- some, or --force --> G{commits under refs/sandboxes/codeo-N/ not on any origin branch?}
    G -- none --> R[sbx rm --force codeo-N, print removed]
    G -- some, no --force --> Z4[list up to 10 commits, exit 1, nothing removed]
    G -- some, --force --> R2[sbx rm --force codeo-N, say the commits are kept in refs/sandboxes/codeo-N/]
```

`end` fetches the sandbox's branches into `refs/sandboxes/codeo-<N>/` in `./codeo-<N>` and lists the commits that are on no `origin` branch. With none, it removes the sandbox. With some, it removes nothing and lists up to 10 of them: push them from the sandbox, or run `end <N> --force`, which removes the sandbox and keeps the commits in `refs/sandboxes/codeo-<N>/` in the clone. It also refuses when the fetch leaves no branches under that prefix, because then nothing can be proved; `--force` removes it anyway. It needs the clone `./codeo-<N>` and refuses without it.

`end` checks commits only. Uncommitted changes, stashes and work on a detached HEAD in the sandbox are not detected: commit them on a branch and push them first.

## The image pin

`.sbx/claude-image` is one line, the Claude image as `docker.io/sbx/claude@sha256:<64 hex digits>`. `issue` creates the sandbox from it, and refuses a file that is missing or holds anything else. Moving the pin is an edit to that file, with a line in `CHANGELOG.md`. A sandbox that exists keeps the image it was created from.

## Stopped sandboxes

A sandbox has been seen stopped when its work was not finished; the cause is not known. `open`, `shell`, `end` and a repeated `issue` start a stopped sandbox themselves. To start it by hand, run `sbx run -d --name codeo-<N>`.
