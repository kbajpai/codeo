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

repo_url="https://github.com/kbajpai/codeo"
tag=""

# remote_git <args...>: git against the network, never prompting, never reading the script from stdin.
remote_git() {
    if command -v timeout >/dev/null 2>&1; then
        GIT_TERMINAL_PROMPT=0 timeout 20 git "$@" </dev/null
    else
        GIT_TERMINAL_PROMPT=0 git "$@" </dev/null
    fi
}

# resolve_release: sets tag to the release to install: the given version, checked on the remote, or
# the highest vX.Y.Z tag. Tags that are not exactly vX.Y.Z are ignored. Changes nothing on failure.
resolve_release() {
    local rc=0 out
    if [[ -n $want_version ]]; then
        tag="v${want_version#v}"
        remote_git ls-remote --exit-code --tags "$repo_url" "refs/tags/$tag" >/dev/null 2>&1 || rc=$?
        case $rc in
            0) ;;
            128 | 124) die "cannot read the releases: check the network and try again" ;;
            *) die "release $tag not found in kbajpai/codeo" ;;
        esac
    else
        out=$(remote_git ls-remote --tags --refs "$repo_url" 'v*' 2>/dev/null) \
            || die "cannot read the latest release: check the network and try again"
        tag=$(printf '%s\n' "$out" \
            | sed -n 's|^[0-9a-f]*[[:space:]]refs/tags/\(v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)$|\1|p' \
            | sort -t. -k1.2,1n -k2,2n -k3,3n | tail -n 1)
        [[ -n $tag ]] || die "cannot read the latest release: check the network and try again"
    fi
    say "release $tag"
}

main() {
    parse_args "$@"
    resolve_release
}

main "$@"
