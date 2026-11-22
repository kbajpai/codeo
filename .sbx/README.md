# Docker Sandboxes (sbx) issue sandbox

An issue's work can run in a Docker Sandboxes (sbx) sandbox instead of a dev container. One script does it: `.sbx/codeo-sandbox.sh`. The home container stays a dev container; only the issue's work moves. A sandbox is named `codeo-<N>`, after its issue, and works in a clone folder `codeo-<N>` on the host.

## Prerequisites

The host is Linux or WSL2 (never macOS) with bash 4.3 or later, `git` and `curl`.

- `sbx` v0.53.0, or `sbx.exe` reachable on `PATH` from WSL2. The script uses `sbx`, else `sbx.exe`; `CODEO_SBX` names the program instead.
- `sbx login`.
- `sbx secret set github --command 'gh auth token'`. The sandbox's `gh` holds a placeholder token; inside the sandbox `gh auth token` and `GH_TOKEN` print it and a push works with no login; where the real token is held was not shown.
- `sbx setup ssh` (experimental). It makes the `*.sbx` hosts resolve, which `open` needs.
- A one-time network rule for the VS Code extension gallery, set before the setting below. Under the default `balanced` policy the VS Code server in the sandbox gets `Server returned 403` from `*.gallery.vsassets.io` and `*.gallerycdn.vsassets.io`, and the failed install stops the remote extension host. `remote.downloadExtensionsLocally` does not cover `remote.SSH.defaultExtensions`, so the rule is the way:

```bash
sbx policy allow network "*.gallery.vsassets.io,*.gallerycdn.vsassets.io"
```

  It adds two global rules, one per host, which apply to every sandbox. `sbx policy rm network --resource <host>` removes one of them, run once per host. From WSL2 the same line runs through `sbx.exe`.
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

The `codeo` command runs this script for you: `codeo issue <N> [<branch>] --sandbox`, `codeo open <N>`, `codeo shell <N>`, `codeo rm <N>` and `codeo list` stand for the commands below. Install it as `.devcontainer/README.md` describes in *Installing the `codeo` command*. `codeo` runs the script from `~/codeo` (`CODEO_HOME`), so the clone `codeo-<N>` is made there, whatever directory the command is run from. It downloads the script into `~/codeo` the first time, and `codeo update` replaces it.

Run the commands from the directory that holds the downloaded file. The clone `codeo-<N>` is made in that directory. When `CODEO_SBX_IMAGE` is set, the script reads the image pin from the file it names, and refuses when that file is missing. Otherwise it reads `codeo-<N>/.sbx/claude-image` in the clone, then `.sbx/claude-image` on `origin/HEAD` of the clone (`git -C codeo-<N> show origin/HEAD:.sbx/claude-image`). No file beside the script is read. `CODEO_REPO_URL` names another repository to clone (default `https://github.com/kbajpai/codeo.git`), and `CODEO_CODE` names the VS Code program `open` runs, in place of `code`.

## Commands

| Command | `codeo` form | What it does |
|---|---|---|
| `bash codeo-sandbox.sh issue <N> <branch> [--yes]` | `codeo issue <N> [<branch>] --sandbox [--yes]` | Clones `<branch>` into `./codeo-<N>` (or checks the clone is on `<branch>`; when the clone exists and the sandbox does not, it fetches `origin` and fast-forwards the clone to `origin/<branch>`, and stops with one line when it cannot), creates the sandbox `codeo-<N>` with 2 CPUs and 4 GB of memory at the pinned image, and runs the dev container's start script in it. That prints `lock: took the lock for #<N> on <branch>` and then `ready` or `TODO` lines. Run again, it creates nothing and starts a stopped sandbox. It prints one `todo:` line when the sandbox's lock names another issue. It ends by leaving the sandbox running detached (`sbx run -d`), so it does not stop when idle. Before it creates a sandbox it asks `codeo-track.sh confirm` and, when the issue already has an `active` container or sandbox on record or a container `codeo-<N>` exists here, lists them and asks before creating another (`--yes` answers yes; without a terminal and without it, `issue` stops); once created it records the `sandbox` row (see *The tracking comment* in `.devcontainer/README.md`). |
| `bash codeo-sandbox.sh open <N>` | `codeo open <N> [--container\|--sandbox]` | Starts the sandbox detached first (`sbx run -d`) when it is not, writes the window title in the sandbox and opens the sandbox's working folder in VS Code over SSH (`codeo-<N>.sbx`). It checks `ssh codeo-<N>.sbx -- true` first, without a prompt and with a 10-second timeout (`ssh.exe` with `sbx.exe`) and, when that fails, says to run `sbx setup ssh`. |
| `bash codeo-sandbox.sh shell <N>` | `codeo shell <N> [--container\|--sandbox]` | Opens a login bash in the sandbox's working folder. Start `claude` there. |
| `bash codeo-sandbox.sh end <N> [--force]` | `codeo rm <N> [--force] [--container\|--sandbox]` | Removes the sandbox when nothing in it is unpushed or uncommitted (see Ending a sandbox), and marks its row `removed` in the issue's tracking comment. |

`codeo issue <N> --sandbox` finds the branch when none is given: the branch that holds `.codeo/<N>/init.md` on origin (see *Installing the `codeo` command* in `.devcontainer/README.md`). `codeo default sandbox` saves sandbox, in `~/codeo/default`, as the kind `codeo issue <N>` uses without a flag; `codeo default container` saves the other, and `codeo default` shows it. `codeo open`, `codeo shell` and `codeo rm` find the kind from the host, a sandbox `codeo-<N>` in `sbx ls` or a container of that name; `--sandbox` picks when both exist. `codeo open <N>` works on a sandbox only. `codeo list` prints one row per issue container or sandbox: `#<N>  sandbox  <state>  <branch>` for a sandbox, where the state is `running`, `detached` or `stopped` and the branch comes from the clone `~/codeo/codeo-<N>` (`-` with no clone). When `sbx` fails to list, `codeo list` warns on stderr, still prints what the other program shows, and exits 1 (the full rule is in `.devcontainer/README.md`).

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
    S->>B: write the sandbox marker, holding the sandbox's name codeo-N
    S->>B: env CODEO_CMD_MODE=1 GIT_AUTHOR_* bash .devcontainer/scripts/devcontainer-start.sh
    B-->>E: lock: took the lock for #N on branch, then ready or TODO lines
    S-->>E: one codeo-sandbox: line naming the next step, when the start script fails
    S->>B: container-name.sh --docker, compared with codeo-N
    S-->>E: one todo: line when the lock names another issue
```

The marker holds the sandbox's name, `codeo-<N>`. The start script reads it and takes the lock with `sandbox: codeo-<N>` and no volume line. A sandbox made before the marker held the name keeps `volume: unknown` in its lock, and `end <N>` ends it all the same. When the start script fails, `issue` ends with one `codeo-sandbox:` line that names the next step: fix the cause and run `issue <N> <branch>` again, or run `shell <N>` to look inside.

With `sbx.exe` from WSL2, the sandbox's working folder is `/wsl.localhost/$WSL_DISTRO_NAME<the clone's path on the host>`, and only Windows Git can fetch from the sandbox. `issue` adds a `safe.directory` entry to Windows Git's global config once, or prints the `git.exe config` line as a `todo:` when `git.exe` is missing; `end` fetches with `git.exe`. The entry is written `%(prefix)///wsl.localhost/<distro><the clone's path on the host>`, which is the clone's path as Windows Git sees it.

The start script turns on `remoteControlAtStartup` in the sandbox, as it does in a dev container. That is untried in a sandbox, and so is Remote Control from one.

## Ending a sandbox

`end <N>`, or `codeo rm <N>` (which runs `bash codeo-sandbox.sh end <N>` from `~/codeo`, passes `--force` on, and adds one line on stderr when it exits non-zero: without `--force`, `codeo rm <N> --force removes it anyway; its unpushed commits are kept in ~/codeo/codeo-<N>, its uncommitted work is not`, only when the script refused over unpushed or uncommitted work, not when it could not read or reach the sandbox; with `--force`, `to remove it anyway, discarding whatever it holds: sbx rm --force codeo-<N>`, left out when the script already named that command, or when `sbx ls` lists no `codeo-<N>`; it is printed when `sbx ls` cannot list), replaces the `docker rm -f codeo-<N>; docker volume rm codeo-<N>` line that `/codeo:close` and `/codeo:cleanup` print for a dev container. `codeo rm` is the only way `codeo` ends a sandbox, and the rules below are the script's. Close any VS Code window connected to `codeo-<N>.sbx` first: the removal uses `sbx rm --force`, which cuts the window off.

```mermaid
flowchart TD
    A[end N] --> B{sandbox exists?}
    B -- no --> Z1[exit 1: no sandbox codeo-N]
    B -- yes --> C[start it if stopped]
    C --> D[git fetch sandbox-codeo-N in ./codeo-N]
    D -- fails --> Z2[exit 1, nothing removed: names sbx rm --force codeo-N]
    D --> F[git fetch origin]
    F -- fails --> Z3[exit 1: cannot prove anything is pushed, nothing removed]
    F --> P[git fetch origin pull-request heads into refs/remotes/origin/pr/]
    P -- fails --> Z6[exit 1: cannot prove anything is delivered, nothing removed]
    P --> E{any branch under refs/sandboxes/codeo-N/?}
    E -- none, no --force --> Z5[exit 1: nothing can be proved, nothing removed]
    E -- some, or --force --> G{commits under refs/sandboxes/codeo-N/ not on any origin branch or pull-request head?}
    G --> U{uncommitted changes, stashes or a detached HEAD in the sandbox?}
    U -- exec fails --> Z7[exit 1: could not check, nothing removed]
    U -- none, no unpushed commits, no --force --> R[sbx rm --force codeo-N] --> R1[delete the refs under refs/sandboxes/codeo-N/, print removed]
    U -- some, or unpushed commits, no --force --> Z4[list up to 10 commits, list the uncommitted work, exit 1, nothing removed]
    U -- with --force --> R2[sbx rm --force codeo-N]
    R2 --> R3[move the refs to refs/codeo/ended/codeo-N/UTC/, say where they are kept]
    R3 -- uncommitted work --> R4[say its uncommitted work was not kept]
```

`end` fetches the sandbox's branches into `refs/sandboxes/codeo-<N>/` in `./codeo-<N>`, fetches `origin` and its pull-request heads (`refs/remotes/origin/pr/*`), and lists the commits that are on no `origin` branch and no pull-request head: a commit reachable from a pull request's head counts as delivered. With none, a plain `end` removes the sandbox and deletes the refs under `refs/sandboxes/codeo-<N>/`. With some, it removes nothing and lists up to 10 of them: push them from the sandbox, or run `end <N> --force`, which removes the sandbox, with or without unpushed commits, and sets the refs aside under `refs/codeo/ended/codeo-<N>/<UTC>/` in the clone (`<UTC>` is the time as `20261118T021500Z`). Recover them with `git -C codeo-<N> log refs/codeo/ended/codeo-<N>/<UTC>/<branch>`; delete them with `git -C codeo-<N> for-each-ref --format='delete %(refname)' refs/codeo/ended/codeo-<N>/ | git -C codeo-<N> update-ref --stdin`. A ref step that fails after the removal is one line naming the clone, and exits 1, because the sandbox is already gone. `end` also refuses when the fetch leaves no branches under that prefix, because then nothing can be proved; `--force` removes it anyway. It needs the clone `./codeo-<N>` and refuses without it.

`end` also looks inside the sandbox before it removes anything, with `git status --porcelain --branch` and `git stash list` run through `sbx exec`. It lists uncommitted changes (up to 10 lines), stashes (up to 10) and a detached HEAD, and removes nothing while any of them is there: commit and push from the sandbox, or run `end <N> --force`, which removes the sandbox and says `its uncommitted work was not kept`. Uncommitted work is not saved under `refs/codeo/ended/`. When the check itself fails, `end` removes nothing, with or without `--force`.

When `end` cannot start the sandbox or fetch from it, it also removes nothing, with or without `--force`, and exits 1 with one line that names `sbx rm --force codeo-<N>`. That command removes the sandbox and discards whatever it holds, so run it only when nothing in the sandbox is wanted.

## The image pin

`.sbx/claude-image` is one line, the Claude image as `docker.io/sbx/claude@sha256:<64 hex digits>`. `issue` creates the sandbox from it, reading it from the file `CODEO_SBX_IMAGE` names when that is set, else from `codeo-<N>/.sbx/claude-image`, else from `origin/HEAD:.sbx/claude-image` in the clone, and refuses when none is found or the line holds anything else. Moving the pin is an edit to `.sbx/claude-image`, with a line in `CHANGELOG.md`. A sandbox that exists keeps the image it was created from.

## Stopped sandboxes

A sandbox that only `sbx create` and `sbx exec` have started stops by itself about a minute after the last `exec` ends, with nothing attached to it. A sandbox left idle that way is soon `stopped`, and an open VS Code window loses its host. One started with `sbx run -d --name codeo-<N>` stays `running (detached)` while idle: two sandboxes started that way stayed up through four idle minutes, and ten stop-and-start cycles of one left the other running. `issue` and `open` both start the sandbox with `sbx run -d --name codeo-<N>`, so it stays up while idle. `shell` and `end` start a stopped sandbox through `exec`, so after them the sandbox stops again when idle; `open <N>` brings it back.

## Recording the sandbox on the issue

`issue` adds a `sandbox` row (`codeo-<N>`, the host's name, `active`) to the issue's tracking comment, and `end` marks it `removed` once the sandbox is gone. `.devcontainer/codeo-track.sh` writes the comment; `codeo-sandbox.sh` runs it from beside itself (`CODEO_TRACK` names another), so download it next to the script or run `codeo update`, which fetches all three scripts:

```bash
curl -fsSL -o codeo-track.sh https://raw.githubusercontent.com/kbajpai/codeo/main/.devcontainer/codeo-track.sh
```

Without it the script prints one `codeo-sandbox: note:` line and records nothing. A record that fails (`gh` missing or not logged in) prints one `track:` line naming the row to add by hand and never fails `issue` or `end`. `.devcontainer/README.md` describes the comment.
