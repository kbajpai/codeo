#!/usr/bin/env bash
# Starts, opens and ends one Docker Sandboxes (sbx) sandbox per GitHub issue. It runs on a Linux or
# WSL2 host (never macOS) under bash 4.3 or later, and drives sbx, or sbx.exe from WSL2.
#
#   codeo-sandbox.sh issue <N> <branch>
#   codeo-sandbox.sh open <N>
#   codeo-sandbox.sh shell <N>
#   codeo-sandbox.sh end <N> [--force]
#
# CODEO_SBX  the sbx program to run, instead of sbx or sbx.exe found on PATH
set -euo pipefail

sbx=''
windows=0

# die <message> [exit-code]: print the message as one line on stderr and exit (1 by default).
die() {
    echo "codeo-sandbox: $1" >&2
    exit "${2:-1}"
}

# usage: print the usage line on stderr and exit 2.
usage() {
    echo 'usage: codeo-sandbox.sh issue <N> <branch> | open <N> | shell <N> | end <N> [--force]' >&2
    exit 2
}

# pick_sbx: set sbx to the program to run (CODEO_SBX, else sbx, else sbx.exe) and windows to 1 when
# its name ends in .exe, else 0.
pick_sbx() {
    if [[ -n "${CODEO_SBX:-}" ]]; then
        sbx=$CODEO_SBX
    elif command -v sbx >/dev/null 2>&1; then
        sbx=sbx
    elif command -v sbx.exe >/dev/null 2>&1; then
        sbx=sbx.exe
    else
        die "sbx is not installed: install Docker Sandboxes (sbx), or from WSL2 make sbx.exe reachable on PATH"
    fi
    # shellcheck disable=SC2034 # read by the sub-commands to come
    if [[ "${sbx##*/}" == *.exe ]]; then windows=1; else windows=0; fi
}

# valid_number <N>: a positive integer with no leading zero.
valid_number() {
    [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

# valid_branch <branch>: starts with a letter or digit, holds only A-Za-z0-9._/- and has no "..".
valid_branch() {
    [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ && "$1" != *..* ]]
}

# sandbox_state <name>: print missing, stopped or running from the rows of "$sbx" ls (name in column 1,
# state word in column 3).
sandbox_state() {
    local name=$1 row_name _agent status _rest listing
    listing=$("$sbx" ls) || die "could not list sandboxes with $sbx"
    while read -r row_name _agent status _rest; do
        [[ "$row_name" == "$name" ]] || continue
        if [[ "$status" == running* ]]; then echo running; else echo stopped; fi
        return 0
    done <<<"$listing"
    echo missing
}

cmd_issue() {
    (($# == 2)) || usage
    valid_number "$1" || usage
    valid_branch "$2" || usage
    pick_sbx
    die 'not yet'
}

cmd_open() {
    (($# == 1)) || usage
    valid_number "$1" || usage
    pick_sbx
    die 'not yet'
}

cmd_shell() {
    (($# == 1)) || usage
    valid_number "$1" || usage
    pick_sbx
    die 'not yet'
}

cmd_end() {
    (($# == 1 || $# == 2)) || usage
    valid_number "$1" || usage
    if (($# == 2)); then [[ "$2" == --force ]] || usage; fi
    pick_sbx
    die 'not yet'
}

main() {
    (($# >= 1)) || usage
    local cmd=$1
    shift
    case "$cmd" in
        issue) cmd_issue "$@" ;;
        open) cmd_open "$@" ;;
        shell) cmd_shell "$@" ;;
        end) cmd_end "$@" ;;
        *) usage ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
