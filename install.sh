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

changed=0

# claude_at <scope> <args...>: claude, never reading the script from stdin. User scope runs from $HOME,
# so no project's settings are involved; project scope runs in the current directory.
claude_at() {
    local s=$1
    shift
    if [[ $s == user ]]; then
        (cd "$HOME" && claude "$@" </dev/null)
    else
        claude "$@" </dev/null
    fi
}

# run_claude <args...>: claude_at the requested scope.
run_claude() { claude_at "$scope" "$@"; }

# installed_version <id> <scope>: prints the version installed at the scope, nothing when absent. An id
# ending in @* matches any marketplace. A failing plugin list dies inside the subshell, so callers
# add || exit 1. A project-scope entry counts only for this project's top level.
installed_version() {
    local list top=""
    list=$(run_claude plugin list --json) \
        || die "cannot read the installed plugins (claude plugin list failed)"
    if [[ $2 == project ]]; then
        top=$(git rev-parse --show-toplevel 2>/dev/null || true)
    fi
    printf '%s\n' "$list" | jq -r --arg id "$1" --arg s "$2" --arg top "$top" '
        [.[] | select(
            (if ($id | endswith("@*")) then (.id | startswith($id[:-1])) else .id == $id end)
            and .scope == $s
            and ($s != "project" or .projectPath == $top))]
        | (.[0].version // empty)'
}

# marketplace_pin: prints "<repo> <ref>" of the codeo marketplace, nothing when it is not added. A
# missing known_marketplaces.json is a fresh machine.
marketplace_pin() {
    local file="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/known_marketplaces.json"
    [[ -f $file ]] || return 0
    jq -r 'select(.codeo) | "\(.codeo.source.repo // "") \(.codeo.source.ref // "")"' "$file"
}

ensure_superpowers() {
    local have
    have=$(installed_version 'superpowers@*' "$scope") || exit 1
    if [[ -n $have ]]; then
        say "superpowers already installed ($scope scope), left alone"
        return 0
    fi
    run_claude plugin marketplace add obra/superpowers-marketplace
    run_claude plugin install superpowers@superpowers-marketplace --scope "$scope"
    changed=1
    say "superpowers installed ($scope scope)"
}

# replace_codeo <old-label>: removes the codeo marketplace (which uninstalls codeo at every scope on
# the machine), adds it again at $tag, and reinstalls codeo at every scope it was at plus the requested
# one. Project-scope calls run in the current directory, user-scope calls from $HOME. A failure after
# the remove leaves codeo uninstalled, and says so.
replace_codeo() {
    local old=$1 out s add_scope=user
    local -a scopes=()
    [[ -z $user_v ]] || scopes+=(user)
    [[ -z $proj_v ]] || scopes+=(project)
    case " ${scopes[*]:-} " in *" $scope "*) ;; *) scopes+=("$scope") ;; esac
    case " ${scopes[*]} " in *" project "*) add_scope=project ;; esac
    run_claude plugin marketplace remove codeo
    if [[ $add_scope == project ]]; then
        out=$(claude_at project plugin marketplace add "kbajpai/codeo@$tag" --scope project 2>&1) || replace_failed "$out"
    else
        out=$(claude_at user plugin marketplace add "kbajpai/codeo@$tag" 2>&1) || replace_failed "$out"
    fi
    for s in "${scopes[@]}"; do
        out=$(claude_at "$s" plugin install codeo@codeo --scope "$s" 2>&1) || replace_failed "$out"
    done
    changed=1
    say "codeo $old -> $tag ($scope scope)"
}

# replace_failed <claude output>: codeo was removed and not put back.
replace_failed() {
    local line
    line=$(printf '%s\n' "$1" | sed '/^[[:space:]]*$/d' | tail -n 1)
    die "codeo is no longer installed: ${line:-claude failed}; run this again"
}

ensure_codeo() {
    local pin have user_v proj_v old
    pin=$(marketplace_pin)
    have=$(installed_version codeo@codeo "$scope") || exit 1
    user_v=$(installed_version codeo@codeo user) || exit 1
    proj_v=$(installed_version codeo@codeo project) || exit 1
    if [[ $pin == "kbajpai/codeo $tag" && $have == "${tag#v}" ]]; then
        say "codeo $tag already installed ($scope scope)"
        return 0
    fi
    # Another repo or ref, or any recorded install at another version, is replaced.
    if { [[ -n $pin && $pin != "kbajpai/codeo $tag" ]]; } \
        || { [[ -n $have && $have != "${tag#v}" ]]; } \
        || { [[ -n $user_v && $user_v != "${tag#v}" ]]; } \
        || { [[ -n $proj_v && $proj_v != "${tag#v}" ]]; }; then
        old=${have:-${user_v:-$proj_v}}
        if [[ ${pin%% *} != kbajpai/codeo && -n $pin ]]; then
            old=${pin% *}@${pin#* }
        elif [[ -n $old ]]; then
            old=v$old
        else
            old=${pin% *}@${pin#* }
        fi
        replace_codeo "$old"
        return 0
    fi
    [[ -n $pin ]] || run_claude plugin marketplace add "kbajpai/codeo@$tag"
    run_claude plugin install codeo@codeo --scope "$scope"
    changed=1
    say "codeo $tag installed ($scope scope)"
}

summary() {
    local codeo_v sp_v
    codeo_v=$(installed_version codeo@codeo "$scope") || exit 1
    sp_v=$(installed_version 'superpowers@*' "$scope") || exit 1
    if [[ $changed -eq 1 ]]; then
        say "done - codeo v$codeo_v, $scope scope, superpowers $sp_v"
        say "restart any Claude Code sessions already open to load the plugins"
    else
        say "nothing changed - codeo v$codeo_v, $scope scope, superpowers $sp_v"
    fi
}

main() {
    parse_args "$@"
    resolve_release
    ensure_superpowers
    ensure_codeo
    summary
}

main "$@"
