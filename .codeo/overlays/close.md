Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

## role-guard

Run `bash .devcontainer/scripts/role.sh --check close` from the project root. Exit 0: go on. Exit 1: print its one line to the engineer and stop; that is the whole answer and nothing in this session lifts it. Exit 2: report its `role:` line and go on.

## host-workflow

Print `docker rm -f <volume>; docker volume rm <volume>`, with `<volume>` the lock's `volume:` line, only when that line matches `^codeo-[0-9]+$`; for any other value, including `unknown`, print no command and say to find the container with `docker ps` on the host.

The command is for the host's shell, not this container's: it is one line with `;` between the commands, and it runs unmodified in PowerShell and in bash.
