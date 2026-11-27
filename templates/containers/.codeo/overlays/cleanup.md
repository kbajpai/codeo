Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

## role-guard

Run `bash .devcontainer/scripts/role.sh --check cleanup` from the project root. Exit 0: go on. Exit 1: print its one line to the engineer and stop; that is the whole answer and nothing in this session lifts it. Exit 2: report its `role:` line and go on. Any other exit (the script is missing, or failed): report what it printed and go on.

## removal-command

name: @CODENAME@-{N}
pattern: ^@CODENAME@-[0-9]+$
command: codeo rm {N}
fallback: if codeo is not installed on the host, first run git status in that clone and go on only when it shows nothing unpushed (docker rm does not check for unpushed work); then run docker rm -f {name}, then docker volume rm {name}, then docker rmi @CODENAME@-dev:{name}; for an issue run in an sbx sandbox run bash codeo-sandbox.sh end {N} from the folder that holds the script and the clone instead, which refuses over unpushed work, because docker rm does not end a sandbox, and which marks its row itself only when it finds the tracker (CODEO_TRACK names it, else codeo-track.sh sits beside it; otherwise it prints a note: and records nothing, and you mark the row by hand); the issue's other rows stay active in its tracking comment until you mark each one once the removal succeeds, on the host that created the container and not inside a container, from a clone of the project, with bash .devcontainer/codeo-track.sh mark {N} container {name} removed (and the same for volume {name} and for image @CODENAME@-dev:{name}, as in mark {N} image @CODENAME@-dev:{name} removed)
