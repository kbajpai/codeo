Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

## role-guard

Run `bash .devcontainer/scripts/role.sh --check close` from the project root. Exit 0: go on. Exit 1: print its one line to the engineer and stop; that is the whole answer and nothing in this session lifts it. Exit 2: report its `role:` line and go on. Any other exit (the script is missing, or failed): report what it printed and go on.

## host-workflow

When the lock's `host` is `container` and it has a `volume:` line:

After a finished close (the pull request merged): print `codeo rm <N>`, with `<N>` the lock's `issue`, only when the `volume:` line matches `^codeo-[0-9]+$` and equals `codeo-<N>` (its number is the lock's `issue`); for any other value, including `unknown` and another issue's number, print no command and say to find the container with `docker ps` on the host. The command is for the host's shell, not this container's: it is one line, run in a bash shell on the host (Linux, macOS, or WSL2 on Windows). Say to the engineer that this command runs on the host, not inside this container, and that they run `git status` in that clone first, because unpushed work is lost with the volume (`codeo rm` itself also refuses over unsaved work). Add one sentence for an engineer without `codeo` on the host: without it, run `docker rm -f codeo-<N>` and then `docker volume rm codeo-<N>`; the issue's tracking-comment rows then stay `active` until marked with `bash .devcontainer/codeo-track.sh mark <N> container codeo-<N> removed`, and the same for the volume and for the image `codeo-dev:codeo-<N>`; `docker rm` does not check for unpushed work. This container holds no lock, so `/codeo:triage` and `/codeo:cleanup` are refused here. Tell the engineer to run them in a home checkout (the host clone named `codeo-home`, or the `codeo-home` container), and make that the closing block's first step.

After a stash: print no removal command. This container holds no lock, so `/codeo:init #<N>` is refused here: it runs in a home checkout (the host clone named `codeo-home`, or the `codeo-home` container), and that is the closing block's step. The resume opens a new `codeo-<N>` container, so this one has to be removed first, because two containers cannot share the name. Say that the engineer removes it on the host with `codeo rm <N>` once `git status` here shows nothing unpushed; `.devcontainer/README.md` says how.

After an abandon: print no removal command. `/codeo:triage` is refused here: it runs in a home checkout (the host clone named `codeo-home`, or the `codeo-home` container), and that is the closing block's first step. When the branch was kept, the container holds nothing the branch lacks, and the engineer may remove it on the host with `codeo rm <N>` after `git status`; `.devcontainer/README.md` says how. When the branch was deleted, this container holds the only copy of the work: say so and name no removal.

When the lock has a `sandbox:` line (an sbx sandbox, not a container volume):

After a finished close (the pull request merged): print `codeo rm <N>`, with `<N>` the lock's `issue`, for the engineer to run on the host. `codeo rm` itself refuses while anything is unpushed, so no `git status` check is needed first. Say that it runs on the host, not inside the sandbox. The sandbox holds no lock, so `/codeo:triage` and `/codeo:cleanup` run in a home checkout (the host clone named `codeo-home`, or the `codeo-home` container); make that the closing block's first step.

After a stash: print no removal command. The sandbox may stay. To resume, run `/codeo:init #<N>` in a home checkout (the host clone named `codeo-home`, or the `codeo-home` container), then `bash codeo-sandbox.sh issue <N> <branch>` again on the host.

After an abandon: print no removal command. `/codeo:triage` runs in a home checkout (the host clone named `codeo-home`, or the `codeo-home` container), and that is the closing block's first step. When the branch was kept, `codeo rm <N>` is safe on the host. When the branch was deleted, the sandbox holds the only copy of the work, and the removal refuses without `--force`: say so.

For a `container` lock with neither a `volume:` nor a `sandbox:` line, print no command and say to find the container with `docker ps` on the host. For any other host there is no checkout to remove: say so.

For every lock host, not only a container or a sandbox: when the branch was deleted at step 14 (the engineer said yes and the push succeeded), run `bash .devcontainer/codeo-track.sh mark <N> branch <branch> deleted` from the project root, with `<N>` the lock's `issue` and `<branch>` the lock's `branch:` line. Relay any `track:` line it prints and carry on whatever its exit status. When the branch was kept, run nothing.
