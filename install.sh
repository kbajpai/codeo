#!/usr/bin/env bash
# install.sh: installs the codeo and superpowers Claude Code plugins in one command.
# codeo counts as installed when the marketplace is pinned at the release and codeo has an entry at the
# asked scope; a pin at another ref or repo is replaced, writing only the asked scope (a user-scope run
# never touches a project's .claude/settings.json; a project-scope run also moves a user-scope copy).
# A replace drops every codeo install the machine holds, so it names each project or local install it
# dropped and does not reinstall, with the command that restores it.
#
#   install.sh [--version vX.Y.Z] [--scope user|project]
#
# Exit codes: 0 done; 1 a prerequisite is missing or another failure; 2 a usage error, before any
# command runs. Every output line starts with "install: ". It never installs a system package.

# The prerequisite check comes first and uses only syntax bash 3.2 can parse (no [[ -v, associative
# arrays, ${var,,}, mapfile, &>>), so an old bash reaches the message below instead of a syntax error.
# CODEO_TEST_BASH_VERSION (<digits>.<digits>) replaces BASH_VERSINFO, for the tests only; any other value is ignored.
test_bash=
case "${CODEO_TEST_BASH_VERSION:-}" in
    "" | *[!0-9.]* | .* | *. | *.*.*) ;;
    *.*) test_bash=1 ;;
esac
if [ -n "$test_bash" ]; then
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
            2) die "release $tag not found in kbajpai/codeo" ;;
            *) die "cannot read the releases: check the network and try again" ;;
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

# plugin_list_json <scope>: prints the JSON array from `claude plugin list --json` at the scope. Notice
# lines on stdout around the array are skipped: the text starts at the first line beginning with "[", and
# the first array jq reads from it is printed (compact), so a trailing notice is never parsed. Dies when
# the call fails or no array is found, with no jq message. Callers add || exit 1.
plugin_list_json() {
    local raw arr
    raw=$(claude_at "$1" plugin list --json) \
        || die "cannot read the installed plugins (claude plugin list failed)"
    arr=$(printf '%s\n' "$raw" | sed -n '/^\[/,$p' | jq -c 'select(type == "array")' 2>/dev/null | head -n 1 || true)
    [[ -n $arr ]] || die "cannot read the installed plugins (claude plugin list failed)"
    printf '%s\n' "$arr"
}

# installed_entry <id> <scope>: prints "<version> <enabled> <id>" of the entry installed at the scope,
# nothing when absent. An id ending in @* matches any marketplace. A failing plugin list dies inside the
# subshell, so callers add || exit 1. A project-scope entry counts only for this project's top level.
installed_entry() {
    local list top=""
    list=$(plugin_list_json "$2") || exit 1
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

# dropped_installs: prints one line per codeo@codeo entry installed at project or local scope, read from
# the installed list (so call it before the remove, which empties the list), minus this project's own
# entry when a project-scope run, which reinstalls it, unless skip_own is 0 (the failure path, where the
# project was not reinstalled yet). A failing plugin list dies inside the subshell, so
# callers add || exit 1. An entry whose projectPath no longer exists on disk is named like any other.
dropped_installs() {
    local skip_own=${1:-1}
    local list top=""
    list=$(plugin_list_json user) || exit 1
    if [[ $scope == project && $skip_own == 1 ]]; then
        top=$(project_root || true)
    fi
    # kept: codeo entries at project or local scope, except (on a project-scope run) the current project, which
    # the run reinstalls; user-scope entries are not dropped installs.
    printf '%s\n' "$list" | jq -r --arg top "$top" '
        .[] | select(.id == "codeo@codeo" and (.scope == "project" or .scope == "local")
            and (.scope != "project" or $top == "" or .projectPath != $top))
        | "codeo is no longer installed for \(.projectPath) (\(.scope) scope, v\(.version)); its .claude/settings\(if .scope == "local" then ".local" else "" end).json was not changed; "
          + (if .scope == "local" then "run claude plugin install codeo@codeo --scope local there to restore it"
             else "run claude plugin install codeo@codeo --scope project there to restore it" end)'
}

# replace_codeo <old-label> <user-entry>: removes the codeo marketplace (which uninstalls codeo at every
# scope on the machine) and adds it again at $tag, writing only the scope that was asked for. A user-scope
# run adds and installs at user scope; it never runs a project-scope call, so no project's
# .claude/settings.json changes. A project-scope run adds and installs at project scope, and moves a
# user-scope copy to $tag too, because one machine holds one codeo version. The list of installs is read
# before the remove (it empties the list), and every project or local install the remove dropped and this
# run did not reinstall is named afterwards, with the command that restores it. The user entry is a
# "<version> <enabled> <id>" line, empty when user scope had no codeo. The remove and user-scope calls run
# from $HOME, project-scope calls from the project's top level. A failure after the remove leaves codeo
# uninstalled, and says so.
replace_codeo() {
    local old=$1 user_e=$2 out restored= dropped lost line user_on=
    # The list is read first: the remove empties it.
    dropped=$(dropped_installs 1) || exit 1
    lost=$(dropped_installs 0) || exit 1
    # Always from $HOME: inside a git repository, remove rewrites its tracked .claude/settings.json.
    claude_step "cannot remove the codeo marketplace" user plugin marketplace remove codeo
    if [[ $scope == project ]]; then
        if [[ -n $user_e ]]; then
            out=$(claude_at user plugin marketplace add "kbajpai/codeo@$tag" 2>&1) || replace_failed "$out" "$user_e" "$restored" user "$lost"
        fi
        out=$(claude_at project plugin marketplace add "kbajpai/codeo@$tag" --scope project 2>&1) || replace_failed "$out" "$user_e" "$restored" project "$lost"
        out=$(claude_at project plugin install codeo@codeo --scope project 2>&1) || replace_failed "$out" "$user_e" "$restored" project "$lost"
        restored=project
        lost=$dropped # the project is back; only the others are still gone
        if [[ -n $user_e ]]; then
            out=$(claude_at user plugin install codeo@codeo --scope user 2>&1) || replace_failed "$out" "$user_e" "$restored" user "$lost"
        fi
    else
        out=$(claude_at user plugin marketplace add "kbajpai/codeo@$tag" 2>&1) || replace_failed "$out" "$user_e" "$restored" user "$lost"
        out=$(claude_at user plugin install codeo@codeo --scope user 2>&1) || replace_failed "$out" "$user_e" "$restored" user "$lost"
    fi
    changed=1
    [[ -z $user_e ]] || read -r _ user_on _ <<<"$user_e"
    if [[ $scope == user && $user_on == false ]]; then
        say "codeo $old -> $tag (user scope) (it was disabled; it is enabled now)"
    else
        say "codeo $old -> $tag ($scope scope)"
    fi
    if [[ $scope == project ]]; then
        if [[ -n $user_e ]]; then
            if [[ $user_on == false ]]; then
                say "your user-scope codeo moved to $tag too: one machine holds one codeo version (it was disabled; it is enabled now)"
            else
                say "your user-scope codeo moved to $tag too: one machine holds one codeo version"
            fi
        fi
    fi
    while IFS= read -r line; do
        [[ -z $line ]] || say "$line"
    done <<<"$dropped"
}

# replace_failed <claude output> <user entry> <restored scopes> <failing scope> <dropped lines>: a reinstall failed after
# the remove. With nothing reinstalled yet codeo is gone everywhere, and a project-scope run that wiped a
# user-scope copy says how to bring it back; with a scope already reinstalled, says which has it and which
# does not. The installs still gone are named first (stdout), so the error stays the last line.
replace_failed() {
    local line dropped_line
    line=$(last_line "$1")
    while IFS= read -r dropped_line; do
        [[ -z $dropped_line ]] || say "$dropped_line"
    done <<<"$5"
    if [[ -n $3 ]]; then
        die "codeo $tag is installed at $3 scope but not at $4 scope: $line; run this again with --scope $4"
    elif [[ $scope == project && -n $2 ]]; then
        die "codeo is no longer installed: $line; run this again with --scope project, then once without --scope to restore your user-scope copy"
    fi
    die "codeo is no longer installed: $line; run this again"
}

ensure_codeo() {
    local pin entry have_on user_e old
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
        if [[ ${pin%% *} == kbajpai/codeo && -n ${pin#* } ]]; then
            old=${pin#* }
        else
            old=$(pin_label "$pin")
        fi
        replace_codeo "$old" "$user_e"
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
