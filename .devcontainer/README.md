# Dev container

The dev container comes in two kinds. Each is its own clone in its own Docker volume.

| | Home container | Issue container |
|---|---|---|
| Clone of | `main` | the branch `/codeo:init` pushed |
| Clone folder and volume | `codeo-home` | `codeo-<N>` |
| Docker name (`docker ps`) | `codeo-home` | `codeo-<N>` |
| VS Code window title | `codeo [home]` | `codeo [#<N>]` |
| Workflow lock | none | taken at start |
| Where these run | `/codeo:issue`, `/codeo:init`, `/codeo:triage`, `/codeo:cleanup` | `/codeo:plan` through `/codeo:close` |

`/codeo:doctor` and `/codeo:setup` run in either.

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
- It fills a `user.name` or `user.email` that the `codeo-git` volume's git config lacks, each on its own, from the `~/.gitconfig` VS Code copies in from the host, else from `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`, and prints which key it set and from where (never the value). It never changes a value already in the volume and copies nothing else from the host file. VS Code's copy can arrive after the script starts, so when a value is missing and the file is not there yet, the script waits for it for up to 10 seconds (`CODEO_GITCONFIG_WAIT`, where a value that is not a whole number counts as 10); a container whose volume already has the identity never waits. When no source has a value, it lists a TODO that names the sources it tried.

## Roles and the guard

`.devcontainer/scripts/role.sh` says what role a container plays, from the clone folder (the container's Docker name), the workflow lock and the branch. It runs no container-engine command.

| Role | Means | What the guard does |
|---|---|---|
| `home` | no lock, on the base branch, in the folder `codeo-home` | Lets `/codeo:issue`, `/codeo:init`, `/codeo:triage` and `/codeo:cleanup` run. `/codeo:plan` through `/codeo:close` also pass the guard, and their own step 0 stops them because there is no lock. |
| `issue:<N>` | locked for `<N>`, in the folder `codeo-<N>` | Lets `/codeo:plan`, `/codeo:implement`, `/codeo:qc` and `/codeo:close` run. Refuses the home-only skills and names the home container. |
| `stale:<N>`, `stale:?` | no lock, and not the home container on the base branch: `stale:<N>` in the folder `codeo-<N>`, `stale:?` in `codeo-home` on another branch | Refuses every guarded skill in one line that names the role and, from the clone's own dossier, what happened to the workflow: finished (nothing more runs here; `/codeo:cleanup` in the home container prints how to remove it), stashed or abandoned (`/codeo:init #<N>` in the home container is the way back, never the start script), a live dossier with no lock (re-run `bash .devcontainer/scripts/devcontainer-start.sh` to take the lock), or nothing the dossier says. A home-only skill is always sent to the home container. |
| `mismatch:<N>:<folder>` | locked for `<N>`, in a folder other than `codeo-<N>` | Refuses every guarded skill. |
| `unguarded` | not a guarded container (see below) | Lets everything run, as it does without a guard. |

The guard applies only when all of these hold: `/.dockerenv` exists, `CLAUDE_CODE_REMOTE` is not `true`, and the clone folder is named `codeo-home` or `codeo-<digits>`. A hosted web session, a plain local checkout, and a container in any other folder are `unguarded` and run every skill as before.

Each guarded skill (`/codeo:issue`, `/codeo:init`, `/codeo:triage`, `/codeo:cleanup`, `/codeo:plan`, `/codeo:implement`, `/codeo:qc`, `/codeo:close`) has a `role-guard` section in its overlay, `.codeo/overlays/<skill>.md`, that runs `bash .devcontainer/scripts/role.sh --check <skill>` as the skill's first step. `--check` exits 0 and prints nothing when the skill may run, and exits 1 with one line naming where the skill runs and this container's role when it may not; any other exit (the script is missing, or failed) is reported by the overlay text, which then goes on. A refusal ends the step; nothing the engineer says lifts it, and the way forward is the container the message names. `role.sh` with no arguments prints the role.

A container whose clone lacks the role script and the guard overlays, such as one created from a branch cut before the guard existed, is not guarded: it runs every skill as before until it is removed.

## Removing a finished container

Nothing inside a container removes a container. At the end of a workflow `/codeo:close` prints the commands that remove the issue's container and its volume. `/codeo:cleanup`, which runs in the home container, lists the other finished issues' containers the same way: it proves five things for each issue (the issue is closed, its pull request is merged, its branch is gone from origin, no branch still carries its dossier, and the issue holds no lease and waits for none on the intake branch) and prints a removal command only for an issue that passes all five, built from this project's overlay; a pull request whose head branch name is missing fails the branch proof. Origin cannot show whether a clone holds unpushed work or whether the workflow ended in that container, so a lease the issue still holds is the one trace of an unfinished close, and it lists the issue as not proven.

After `/codeo:close` finishes, the container holds no lock and is `stale`, so `/codeo:triage` and `/codeo:cleanup` run in the home container, and the finished close's closing block names it. The removal commands are printed only for a workflow hosted in a container.

Both only print. Run the commands in a shell on the host, and run `git status` in that clone first: unpushed work is lost with the volume. The home container has no container engine on purpose and no Docker socket is mounted into it, so it cannot run the commands for you.

## The folder rule

The clone folder is the container's Docker name (`runArgs` `--name=${containerWorkspaceFolderBasename}`). Docker accepts names that match `[a-zA-Z0-9][a-zA-Z0-9_.-]+` and refuses anything else before any script runs, so a container cannot start with another folder and the start script never gets to report it. Use the folders above; if you typed another, remove the container and clone again with the right folder.

The Docker name is the folder's name, so two containers whose folders share a name cannot run at once. This happens when a host folder is opened with **Reopen in Container** from two paths with the same last name (`~/a/codeo` and `~/b/codeo`): Docker reports `name already in use`. Give one of them another folder name, or use the named-volume flow above, whose folders `codeo-home` and `codeo-<N>` never clash.

## Rebuilding

A container created before the name was the clone folder alone has a different Docker name. Rebuild it once to get the new name. If Docker reports that the name is already in use, a container with that name is left over: remove it with `docker rm <name>` and open the container again. The same message also means a second container with the same folder name: see *The folder rule*.

A container created before the move to Ubuntu 26.04 is still on the older image. Rebuild it once (**Dev Containers: Rebuild Container**) to get the new one. The clone and the `codeo-gh` and `codeo-git` volumes are kept. Expect all of `~/.claude` to be lost on a rebuild (the Claude Code login, past sessions and user settings), because it is not on a volume: run `claude auth login` again, and the start script reinstalls the plugins.
