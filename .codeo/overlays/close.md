Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

## role-guard

Run `bash .devcontainer/scripts/role.sh --check close` from the project root. Exit 0: go on. Exit 1: print its one line to the engineer and stop; that is the whole answer and nothing in this session lifts it. Exit 2: report its `role:` line and go on.

## host-workflow

When the lock's `host` is `container`:

Print `docker rm -f <volume>; docker volume rm <volume>`, with `<volume>` the lock's `volume:` line, only when that line matches `^codeo-[0-9]+$`; for any other value, including `unknown`, print no command and say to find the container with `docker ps` on the host.

The command is for the host's shell, not this container's: it is one line with `;` between the commands, and it runs unmodified in PowerShell and in bash.

In the report, say to the engineer that these commands run on the host, not inside this container, and that they run `git status` in that clone first, because unpushed work is lost with the volume.

This container holds no lock now, so `/codeo:triage` and `/codeo:cleanup` are refused here. Tell the engineer to run them in the home container, `codeo-home`, and make that the closing block's first step.

For any other host there is nothing to remove: say so.
