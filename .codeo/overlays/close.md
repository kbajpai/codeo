Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

## role-guard

Run `bash .devcontainer/scripts/role.sh --check close` from the project root. Exit 0: go on. Exit 1: print its one line to the engineer and stop; that is the whole answer and nothing in this session lifts it. Exit 2: report its `role:` line and go on. Any other exit (the script is missing, or failed): report what it printed and go on.

## host-workflow

When the lock's `host` is `container`:

After a finished close (the pull request merged): print `docker rm -f <volume>; docker volume rm <volume>`, with `<volume>` the lock's `volume:` line, only when that line matches `^codeo-[0-9]+$` and its number is the lock's `issue`; for any other value, including `unknown` and another issue's number, print no command and say to find the container with `docker ps` on the host. The command is for the host's shell, not this container's: it is one line with `;` between the commands, and it runs unmodified in PowerShell and in bash. Say to the engineer that these commands run on the host, not inside this container, and that they run `git status` in that clone first, because unpushed work is lost with the volume. This container holds no lock, so `/codeo:triage` and `/codeo:cleanup` are refused here. Tell the engineer to run them in the home container, `codeo-home`, and make that the closing block's first step.

After a stash: print no removal command. This container holds no lock, so `/codeo:init #<N>` is refused here: it runs in the home container, `codeo-home`, and that is the closing block's step. The resume opens a new `codeo-<N>` container, so this one has to be removed first, because two containers cannot share the name. Say that the engineer removes it by hand on the host once `git status` here shows nothing unpushed; `.devcontainer/README.md` says how.

After an abandon: print no removal command. `/codeo:triage` is refused here: it runs in the home container, `codeo-home`, and that is the closing block's first step. When the branch was kept, the container holds nothing the branch lacks, and the engineer may remove it by hand on the host after `git status`; `.devcontainer/README.md` says how. When the branch was deleted, this container holds the only copy of the work: say so and name no removal.

For any other host there is nothing to remove: say so.
