#!/usr/bin/env bash
# install.sh: installs the codeo and superpowers Claude Code plugins in one command.
#
#   install.sh [--version vX.Y.Z] [--scope user|project]
#
# Exit codes: 0 done; 1 a prerequisite is missing or another failure; 2 a usage error, before any
# command runs. Every output line starts with "install: ". It never installs a system package.

# The prerequisite check comes first and uses only syntax bash 3.2 can parse (no [[ -v, associative
# arrays, ${var,,}, mapfile, &>>), so an old bash reaches the message below instead of a syntax error.
# CODEO_TEST_BASH_VERSION (<major>.<minor>) replaces BASH_VERSINFO, for the tests only.
if [ -n "${CODEO_TEST_BASH_VERSION:-}" ]; then
    bash_major=${CODEO_TEST_BASH_VERSION%%.*}
    bash_minor=${CODEO_TEST_BASH_VERSION#*.}
else
    bash_major=${BASH_VERSINFO[0]}
    bash_minor=${BASH_VERSINFO[1]}
fi
missing=""
if [ "$bash_major" -lt 4 ] || { [ "$bash_major" -eq 4 ] && [ "$bash_minor" -lt 3 ]; }; then
    missing="${missing}install: bash 4.3 or later is required (found ${bash_major}.${bash_minor})
"
fi
command -v jq >/dev/null 2>&1 || missing="${missing}install: jq is not installed
"
command -v git >/dev/null 2>&1 || missing="${missing}install: git is not installed
"
command -v gh >/dev/null 2>&1 || missing="${missing}install: gh is not installed
"
command -v claude >/dev/null 2>&1 || missing="${missing}install: claude (Claude Code) is not installed
"
if [ -n "$missing" ]; then
    printf '%s' "$missing" >&2
    echo "install: nothing was installed. Install the tools above with your system's package manager, then run this again." >&2
    exit 1
fi
unset bash_major bash_minor missing

set -euo pipefail

usage_text='install: usage: install.sh [--version vX.Y.Z] [--scope user|project]'
want_version=""
scope="user"

# say <text>: one line on stdout.
say() { printf 'install: %s\n' "$*"; }

# die <text> [code]: one line on stderr, then exit (default 1).
die() {
    local code=${2:-1}
    printf 'install: %s\n' "$1" >&2
    exit "$code"
}

# usage [reason]: the reason (when given) and the usage line on stderr, exit 2.
usage() {
    [[ -z ${1:-} ]] || printf 'install: %s\n' "$1" >&2
    printf '%s\n' "$usage_text" >&2
    exit 2
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h | --help)
                printf '%s\n' "$usage_text"
                exit 0 ;;
            --version)
                [[ $# -ge 2 ]] || usage "missing value for --version"
                [[ $2 =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]] || usage "malformed version: $2"
                want_version=$2
                shift 2 ;;
            --scope)
                [[ $# -ge 2 ]] || usage "missing value for --scope"
                case $2 in
                    user | project) scope=$2 ;;
                    *) usage "malformed scope: $2 (want user or project)" ;;
                esac
                shift 2 ;;
            *) usage "unknown option: $1" ;;
        esac
    done
}

main() {
    parse_args "$@"
}

main "$@"
