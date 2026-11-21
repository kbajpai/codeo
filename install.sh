#!/usr/bin/env bash
# install.sh: installs the codeo and superpowers Claude Code plugins in one command.
# codeo counts as installed when the marketplace is pinned at the release and codeo has an entry at the
# asked scope; a pin at another ref or repo is replaced, writing only the asked scope (a user-scope run
# never touches a project's .claude/settings.json; a project-scope run also moves a user-scope copy).
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

# project_root: the project's git top level; fails outside a git repository.
project_root() { git rev-parse --show-toplevel </dev/null 2>/dev/null; }

# enter_project: project scope needs the project's git repository.
enter_project() {
    [[ $scope == project ]] || return 0
    project_root >/dev/null || die "project scope must run inside the project's git repository"
}

changed=0

# claude_at <scope> <args...>: claude, never reading the script from stdin. User scope runs from $HOME,
# so no project's settings are involved; project scope always runs from the project's top level,
# wherever the installer was started.
claude_at() {
    local s=$1 top
    shift
    if [[ $s == user ]]; then
        (cd "$HOME" && claude "$@" </dev/null)
    else
        top=$(project_root) || die "project scope must run inside the project's git repository"
        (cd "$top" && claude "$@" </dev/null)
    fi
}

# last_line <text>: the last non-blank line, "claude failed" when there is none.
last_line() {
    local l
    l=$(printf '%s\n' "$1" | sed '/^[[:space:]]*$/d' | tail -n 1)
    printf '%s' "${l:-claude failed}"
}

# claude_step <what> <scope> <args...>: claude_at, its own output passed through when it succeeds; a
# failure dies with "<what>: <claude's last line>" (stderr's when it printed any, else stdout's).
claude_step() {
    local what=$1 so se rc=0 line
    shift
    so=$(mktemp) se=$(mktemp)
    claude_at "$@" >"$so" 2>"$se" || rc=$?
    if [[ $rc -eq 0 ]]; then
        cat "$so"
        cat "$se" >&2
        rm -f "$so" "$se"
        return 0
    fi
    line=$(last_line "$(cat "$se")")
    [[ -s $se ]] || line=$(last_line "$(cat "$so")")
    rm -f "$so" "$se"
    die "$what: $line"
}

# installed_entry <id> <scope>: prints "<version> <enabled> <id>" of the entry installed at the scope,
# nothing when absent. An id ending in @* matches any marketplace. A failing plugin list dies inside the
# subshell, so callers add || exit 1. A project-scope entry counts only for this project's top level.
installed_entry() {
    local list top=""
    list=$(claude_at "$2" plugin list --json) \
        || die "cannot read the installed plugins (claude plugin list failed)"
    if [[ $2 == project ]]; then
        top=$(project_root || true)
    fi
    printf '%s\n' "$list" | jq -r --arg id "$1" --arg s "$2" --arg top "$top" '
        [.[] | select(
            (if ($id | endswith("@*")) then (.id | startswith($id[:-1])) else .id == $id end)
            and .scope == $s
            and ($s != "project" or .projectPath == $top))]
        | (.[0] | if . == null then empty else "\(.version) \(.enabled) \(.id)" end)'
}

# installed_version <id> <scope>: prints the version installed at the scope, nothing when absent.
installed_version() {
    local entry
    entry=$(installed_entry "$@") || exit 1
    printf '%s\n' "${entry%% *}"
}

# marketplace_pin: prints "<repo> <ref>" of the codeo marketplace, nothing when it is not added. A
# missing known_marketplaces.json is a fresh machine.
marketplace_pin() {
    local file="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/known_marketplaces.json"
    [[ -f $file ]] || return 0
    jq -r 'select(.codeo) | "\(.codeo.source.repo // "") \(.codeo.source.ref // "")"' "$file" 2>/dev/null \
        || die "cannot read the marketplaces ($file is not valid JSON)"
}

# pin_label <"repo ref">: how a marketplace pin reads in the output; a pin with no repo (a git or url
# source) is "unknown source".
pin_label() {
    local r=${1%% *} f=${1#* }
    if [[ -z $r ]]; then
        printf 'unknown source'
    elif [[ -n $f ]]; then
        printf '%s@%s' "$r" "$f"
    else
        printf '%s' "$r"
    fi
}

ensure_superpowers() {
    local entry have on id
    entry=$(installed_entry 'superpowers@*' "$scope") || exit 1
    read -r have on id <<<"$entry"
    if [[ -n $have ]]; then
        if [[ $on == false ]]; then
            claude_step "cannot enable superpowers" "$scope" plugin enable "$id" --scope "$scope"
            changed=1
            say "superpowers enabled ($scope scope)"
            return 0
        fi
        say "superpowers already installed ($scope scope), left alone"
        return 0
    fi
    if [[ $scope == project ]]; then
        claude_step "superpowers is not installed" "$scope" plugin marketplace add obra/superpowers-marketplace --scope project
    else
        claude_step "superpowers is not installed" "$scope" plugin marketplace add obra/superpowers-marketplace
    fi
    claude_step "superpowers is not installed" "$scope" plugin install superpowers@superpowers-marketplace --scope "$scope"
    changed=1
    say "superpowers installed ($scope scope)"
}

# replace_codeo <old-label> <user-entry> <project-entry>: removes the codeo marketplace (which uninstalls
# codeo at every scope on the machine) and adds it again at $tag, writing only the scope that was asked
# for. A user-scope run adds and installs at user scope; it never runs a project-scope call, so no
# project's .claude/settings.json changes, and it says so when this project's own install is gone. A
# project-scope run adds and installs at project scope, and moves a user-scope copy to $tag too, because
# one machine holds one codeo version. The entries are "<version> <enabled> <id>" lines, empty when the
# scope had no codeo. The remove and user-scope calls run from $HOME, project-scope calls from the
# project's top level. A failure after the remove leaves codeo uninstalled, and says so.
replace_codeo() {
    local old=$1 user_e=$2 proj_e=$3 out proj_v
    # Always from $HOME: inside a git repository, remove rewrites its tracked .claude/settings.json.
    claude_step "cannot remove the codeo marketplace" user plugin marketplace remove codeo
    if [[ $scope == project ]]; then
        if [[ -n $user_e ]]; then
            out=$(claude_at user plugin marketplace add "kbajpai/codeo@$tag" 2>&1) || replace_failed "$out"
        fi
        out=$(claude_at project plugin marketplace add "kbajpai/codeo@$tag" --scope project 2>&1) || replace_failed "$out"
        out=$(claude_at project plugin install codeo@codeo --scope project 2>&1) || replace_failed "$out"
        if [[ -n $user_e ]]; then
            out=$(claude_at user plugin install codeo@codeo --scope user 2>&1) || replace_failed "$out"
        fi
    else
        out=$(claude_at user plugin marketplace add "kbajpai/codeo@$tag" 2>&1) || replace_failed "$out"
        out=$(claude_at user plugin install codeo@codeo --scope user 2>&1) || replace_failed "$out"
    fi
    changed=1
    say "codeo $old -> $tag ($scope scope)"
    if [[ $scope == project ]]; then
        [[ -z $user_e ]] || say "your user-scope codeo moved to $tag too: one machine holds one codeo version"
    elif [[ -n $proj_e ]]; then
        proj_v=${proj_e%% *}
        say "this project's own codeo (project scope, v$proj_v) is no longer installed on this machine; its .claude/settings.json was not changed"
    fi
}

# replace_failed <claude output>: codeo was removed and not put back.
replace_failed() {
    die "codeo is no longer installed: $(last_line "$1"); run this again"
}

ensure_codeo() {
    local pin entry have_on user_e proj_e="" old
    pin=$(marketplace_pin) || exit 1
    entry=$(installed_entry codeo@codeo "$scope") || exit 1
    read -r _ have_on _ <<<"$entry"
    # Installed means: the marketplace is pinned at $tag and codeo has an entry at the asked scope.
    # The entry's version string is not compared; a tag whose plugin.json was not bumped is still $tag.
    if [[ $pin == "kbajpai/codeo $tag" && -n $entry ]]; then
        if [[ $have_on == false ]]; then
            claude_step "cannot enable codeo" "$scope" plugin enable codeo@codeo --scope "$scope"
            changed=1
            say "codeo $tag enabled ($scope scope)"
            return 0
        fi
        say "codeo $tag already installed ($scope scope)"
        return 0
    fi
    # A pin at another ref or another repo is the only reason to replace.
    if [[ -n $pin && $pin != "kbajpai/codeo $tag" ]]; then
        user_e=$(installed_entry codeo@codeo user) || exit 1
        if [[ $scope == user ]] && project_root >/dev/null; then
            proj_e=$(installed_entry codeo@codeo project) || exit 1
        fi
        if [[ ${pin%% *} == kbajpai/codeo && -n ${pin#* } ]]; then
            old=${pin#* }
        else
            old=$(pin_label "$pin")
        fi
        replace_codeo "$old" "$user_e" "$proj_e"
        return 0
    fi
    # Declares the marketplace at the asked scope, even when it is already known (a no-op then).
    if [[ $scope == project ]]; then
        claude_step "codeo is not installed" "$scope" plugin marketplace add "kbajpai/codeo@$tag" --scope project
    else
        claude_step "codeo is not installed" "$scope" plugin marketplace add "kbajpai/codeo@$tag"
    fi
    claude_step "codeo is not installed" "$scope" plugin install codeo@codeo --scope "$scope"
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
    enter_project
    resolve_release
    ensure_superpowers
    ensure_codeo
    summary
}

main "$@"
