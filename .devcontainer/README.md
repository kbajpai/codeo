# Dev container

The dev container comes in two kinds. Each is its own clone in its own Docker volume.

| | Home container | Issue container |
|---|---|---|
| Clone of | `main` | the branch `/codeo:init` pushed |
| Clone folder and volume | `codeo-home` | `codeo-<N>` |
| Docker name (`docker ps`) | `codeo-home` | `codeo-<N>` |
| VS Code window title | `codeo [home]` | `codeo [#<N>]` |
| Workflow lock | none | taken at start |
| Where these run | `/codeo:issue`, `/codeo:init`, `/codeo:triage` | `/codeo:plan` through `/codeo:close` |

`/codeo:init` runs in the home container and hands off to the issue's container. The home container and one or more issue containers can run at the same time, as can two issue containers: each has its own name, clone and volume.

## Opening a container

In VS Code, run **Dev Containers: Clone Repository in Named Container Volume…** (the unnamed variant never asks for a name).

- Home container: repository URL `https://github.com/kbajpai/codeo`, volume `codeo-home`, folder `codeo-home`.
- Issue container: repository URL `https://github.com/kbajpai/codeo/tree/<branch>`, volume `codeo-<N>`, folder `codeo-<N>`. `/codeo:init` prints these with the branch and number filled in.

## What the start script does

`.devcontainer/scripts/devcontainer-start.sh` runs when the container is created.

- On `main` (the base branch) it takes no lock. On an issue's branch it takes the workflow lock with codeo's `lock.sh`, from the `init.md` on that branch, and prints `lock: took the lock for #<N> on <branch>`.
- An empty `.codeo/active` holds no lock, so the script removes it, says so (`.codeo/active was empty and held no lock: removed it`) and goes on to take the lock on an issue branch.
- A `.codeo/active` that has content but names no issue holds no usable lock. A file names an issue when a line starts with `issue:` followed by a number (`issue:   87` or `issue: #87`); a file holding only a newline, or other text, does not. The script leaves such a file exactly as it is, takes no lock, and lists one TODO: `.codeo/active names no issue, so it holds no usable lock: look at it, remove it if it is not yours, then re-run this script`. This is the same on `main` and on an issue's branch. A file that names an issue is a held lock and is left alone.
- It checks the clone folder against what the lock says. A folder that does not match is reported as a `todo:` line naming the folder to open the container with, and the container is left running.
- It fills a `user.name` or `user.email` that the `codeo-git` volume's git config lacks, each on its own, from the `~/.gitconfig` VS Code copies in from the host, else from `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`, and prints which key it set and from where (never the value). Only values written directly in ~/.gitconfig count: an identity kept in a file it [include]s or [includeIf]s is not followed, because VS Code copies only ~/.gitconfig into the container. It never changes a value already in the volume and copies nothing else from the host file. VS Code's copy can arrive after the script starts, so when a value is missing the script waits for the file to be there, not empty, and to stop growing (size and modification time unchanged over 0.2 seconds) for up to 10 seconds (`CODEO_GITCONFIG_WAIT`, where a value that is not a whole number counts as 10); a container whose volume already has the identity never waits. When no source has a value, it lists a TODO that names the sources it tried.

## The folder rule

The clone folder is the container's Docker name (`runArgs` `--name=${containerWorkspaceFolderBasename}`). Docker accepts names that match `[a-zA-Z0-9][a-zA-Z0-9_.-]+` and refuses anything else before any script runs, so a container cannot start with another folder and the start script never gets to report it. Use the folders above; if you typed another, remove the container and clone again with the right folder.

The Docker name is the folder's name, so two containers whose folders share a name cannot run at once. This happens when a host folder is opened with **Reopen in Container** from two paths with the same last name (`~/a/codeo` and `~/b/codeo`): Docker reports `name already in use`. Give one of them another folder name, or use the named-volume flow above, whose folders `codeo-home` and `codeo-<N>` never clash.

## Rebuilding

A container created before the name was the clone folder alone has a different Docker name. Rebuild it once to get the new name. If Docker reports that the name is already in use, a container with that name is left over: remove it with `docker rm <name>` and open the container again. The same message also means a second container with the same folder name: see *The folder rule*.

A container created before the move to Ubuntu 26.04 is still on the older image. Rebuild it once (**Dev Containers: Rebuild Container**) to get the new one. The clone and the `codeo-gh` and `codeo-git` volumes are kept. Expect all of `~/.claude` to be lost on a rebuild (the Claude Code login, past sessions and user settings), because it is not on a volume: run `claude auth login` again, and the start script reinstalls the plugins.
