#!/usr/bin/env bash
# PreToolUse guard that keeps project changes out of a checkout whose role is home, stale:? or stray
# (as .devcontainer/scripts/role.sh prints it): Edit, Write and NotebookEdit are refused there. The
# role comes from the checkout's own role.sh, never a copy of its rules. Every other role, a path
# under <root>/.codeo/, a path outside any repository and every failure to find out allows the call:
# the guard fails open. CODEO_HOME_EDITS=allow in the hook's own environment switches it off.
# No set -e: every failure is swallowed, and the exit status is always 0.

# guarded_role <dir>: prints the role and returns 0 when the checkout holding <dir> is guarded.
guarded_role() {
    local root=$1 role
    [[ -x $root/.devcontainer/scripts/role.sh ]] || return 1
    role=$("$root/.devcontainer/scripts/role.sh" "$root" 2>/dev/null) || return 1
    case $role in
        home | 'stale:?' | stray) printf '%s\n' "$role"; return 0 ;;
    esac
    return 1
}

# deny <role>: prints the one-line deny object.
deny() {
    jq -n --arg r "codeo: this checkout's role is $1, so project changes are not made here. File the issue with /codeo:issue, start it with 'codeo issue <N>', and work in its checkout. To allow it for this session, start Claude Code with CODEO_HOME_EDITS=allow." \
        '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny",
        permissionDecisionReason: $r}}'
}

main() {
    [[ ${CODEO_HOME_EDITS:-} == allow ]] && return 0
    command -v jq >/dev/null 2>&1 || return 0
    local input tool cwd path key=file_path
    input=$(cat) || return 0
    tool=$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null) || return 0
    case $tool in
        Edit | Write) ;;
        NotebookEdit) key=notebook_path ;;
        *) return 0 ;;
    esac
    cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null) || return 0
    path=$(jq -r --arg k "$key" '.tool_input[$k] // empty' <<<"$input" 2>/dev/null) || return 0
    [[ -n $path ]] || return 0
    [[ $path == /* ]] || path="${cwd:-.}/$path"

    # The nearest existing ancestor decides: the file, or its directories, may not exist yet.
    local dir=$path rest= base real root role
    while [[ ! -d $dir ]]; do
        base=${dir##*/}
        rest="/$base$rest"
        dir=${dir%/*}
        [[ -n $dir ]] || dir=/
        [[ $dir == / ]] && break
    done
    real=$(cd "$dir" 2>/dev/null && pwd -P) || return 0
    root=$(git -C "$real" rev-parse --show-toplevel 2>/dev/null) || return 0
    [[ -n $root ]] || return 0
    # Known limit: a symlink inside .codeo/ pointing at a project file is exempt. A ".." in the tail
    # that does not exist yet could climb out of .codeo/, so it is never exempt.
    [[ "/$rest/" != */../* && "${real%/}$rest" == "$root"/.codeo/* ]] && return 0
    role=$(guarded_role "$root") || return 0
    deny "$role"
}

# Sourced for guarded_role and deny by the tests; run as the hook otherwise.
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main 2>/dev/null
    exit 0
fi
