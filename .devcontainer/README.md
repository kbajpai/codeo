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

`scripts/devcontainer-start.sh` runs when the container is created.

- On `main` (the base branch) it takes no lock. On an issue's branch it takes the workflow lock with codeo's `lock.sh`, from the `init.md` on that branch, and prints `lock: took the lock for #<N> on <branch>`.
- It checks the clone folder against what the lock says. A folder that does not match is reported as a `todo:` line naming the folder to open the container with, and the container is left running.

## The folder rule

The clone folder is the container's Docker name (`runArgs` `--name=${containerWorkspaceFolderBasename}`). Docker accepts names that match `[a-zA-Z0-9][a-zA-Z0-9_.-]+` and refuses anything else before any script runs, so a container cannot start with another folder and the start script never gets to report it. Use the folders above; if you typed another, remove the container and clone again with the right folder.

## Rebuilding

A container created before the name was the clone folder alone has a different Docker name. Rebuild it once to get the new name. If Docker reports that the name is already in use, a container with that name is left over: remove it with `docker rm <name>` and open the container again.

A container created before the move to Ubuntu 26.04 is still on the older image. Rebuild it once (**Dev Containers: Rebuild Container**) to get the new one. The clone and the `codeo-gh` and `codeo-git` volumes are kept. The Claude Code login is not kept, because `~/.claude` is not on a volume: run `claude auth login` again, and the start script reinstalls the plugins.
