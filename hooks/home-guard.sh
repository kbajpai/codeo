#!/usr/bin/env bash
# PreToolUse guard that keeps project changes out of a checkout whose role is home, stale:? or stray
# (as .devcontainer/scripts/role.sh prints it): Edit, Write and NotebookEdit are refused there, and so are
# git writes run through Bash (bash_guard). The role comes from the checkout's own role.sh, never a copy of its rules. Every other role, a path
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

# common_dir_of <dir>: prints the physical, absolute git common directory of the repository holding <dir>.
common_dir_of() {
    local c
    c=$(git -C "$1" rev-parse --git-common-dir 2>/dev/null) || return 1
    [[ $c == /* ]] || c="$1/$c"
    (cd "$c" 2>/dev/null && pwd -P)
}

# in_project_p <root> <project dir>: succeeds when the repository at <root> is the repository holding
# <project dir> or one of its worktrees (the same git common directory). Only those are judged.
in_project_p() {
    local a b
    a=$(common_dir_of "$1") || return 1
    b=$(common_dir_of "$2") || return 1
    [[ -n $a && $a == "$b" ]]
}

# deny <role>: prints the one-line deny object.
deny() {
    jq -n --arg r "codeo: this checkout's role is $1, so project changes are not made here. File the issue with /codeo:issue, start it with 'codeo issue <N>', and work in its checkout. To allow it for this session, start Claude Code with CODEO_HOME_EDITS=allow." \
        '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny",
        permissionDecisionReason: $r}}'
}

# redirection_p <word>: succeeds when the word is a redirection (>, >>, <, N>, >file, 2>file, <file, and
# what normalize_cmd leaves of N>&M and &>). redirection_op_p: it is the bare operator, so the next
# word is its target.
redirection_p() { local re='^[0-9]*[<>]'; [[ $1 =~ $re ]]; }
redirection_op_p() { local re='^[0-9]*[<>]+$'; [[ $1 =~ $re ]]; }

# under_codeo_p <path> <dir> <root>: succeeds when the path, resolved lexically against <dir>, is
# <root>/.codeo or lies under it. A path with a ".." segment never does.
under_codeo_p() {
    local p=$1
    [[ "/$p/" != */../* ]] || return 1
    [[ $p == /* ]] || p="$2/$p"
    while [[ $p == *//* ]]; do p=${p//\/\//\/}; done
    while [[ $p == */./* ]]; do p=${p//\/.\//\/}; done
    while [[ $p == */. || $p == */ ]]; do p=${p%/.}; p=${p%/}; done
    [[ $p == "$3/.codeo" || $p == "$3/.codeo/"* ]]
}

# git_write_p <subcommand> <dir> <args…>: succeeds when that git invocation is a write that the
# .codeo/ exemptions do not cover.
git_write_p() {
    local sub=$1 dir=$2 a path all_codeo=1 n=0 changed cluster_a=0 root skip=0 o
    shift 2
    case $sub in
        push | merge | rebase | cherry-pick | revert | am | apply | reset | stash | tag) return 0 ;;
        checkout)
            for a in "$@"; do
                [[ $a == --orphan || $a =~ ^-[A-Za-z]*[bB][A-Za-z]*$ ]] && return 0
            done
            return 1 ;;
        switch)
            for a in "$@"; do
                [[ $a == --create || $a == --force-create || $a == --orphan || $a =~ ^-[A-Za-z]*[cC][A-Za-z]*$ ]] && return 0
            done
            return 1 ;;
        add | rm | mv | restore)
            root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || return 0
            for a in "$@"; do
                if [[ $skip == 1 ]]; then skip=0; continue; fi
                if redirection_p "$a"; then redirection_op_p "$a" && skip=1; continue; fi
                [[ $a == -- ]] && continue
                [[ $a == -* ]] && continue
                n=$((n + 1))
                under_codeo_p "$a" "$dir" "$root" || all_codeo=0
            done
            [[ $n -gt 0 && $all_codeo == 1 ]] && return 1
            return 0 ;;
        commit)
            root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || return 0
            for a in "$@"; do
                if [[ $skip == 1 ]]; then skip=0; continue; fi
                if redirection_p "$a"; then redirection_op_p "$a" && skip=1; continue; fi
                case $a in
                    --amend | --only | -o | -i | --include | --) return 0 ;;
                    --all) cluster_a=1 ;;
                    --message | --file | --author | --reuse-message | --reedit-message) skip=1 ;;
                    --*)
                        o=${a#--}
                        if [[ ${#o} -ge 3 ]] && [[ amend == "$o"* || include == "$o"* || only == "$o"* ]]; then return 0; fi ;;
                    -?*)
                        [[ $a == *a* ]] && cluster_a=1
                        [[ $a =~ [mFCc]$ ]] && skip=1 ;;
                    *) under_codeo_p "$a" "$dir" "$root" || return 0 ;;
                esac
            done
            changed=$(git -C "$dir" diff --cached --name-only 2>/dev/null)
            [[ $cluster_a == 1 ]] && changed+=$'\n'$(git -C "$dir" diff --name-only 2>/dev/null)
            while IFS= read -r path; do
                [[ -n $path ]] || continue
                under_codeo_p "$path" "$root" "$root" || return 0
            done <<<"$changed"
            return 1 ;;
    esac
    return 1
}

# normalize_cmd <command>: sets NORM to the command with every quoted span replaced by Q, except a
# quoted word right after "cd " or "-C ", which keeps its content and loses its quotes, and with
# every segment break (&&, ||, ;, |, &) turned into a newline, except that a redirection N>&M or &>
# loses its "&" and stays one word. Plain bash, no sed -z: a stock macOS has bash 3.2 and the BSD tools.
normalize_cmd() {
    local LC_ALL=C   # byte-wise, so indexing a long command is cheap
    local s=$1 n=${#1} tail i=0 c j q rest pre next prev out= keep
    local ctx_cd='(^|[[:space:];&|(])cd[[:space:]]+$' ctx_c='-C[[:space:]]+$'
    while [[ $i -lt $n ]]; do
        c=${s:i:1}
        case $c in
            '"' | "'")
                keep=0
                tail=$out; [[ ${#out} -le 256 ]] || tail=${out: -256}
                if [[ $tail =~ $ctx_cd || $tail =~ $ctx_c ]]; then keep=1; fi
                rest=${s:i+1}
                if [[ $c == "'" || $keep == 1 ]]; then
                    pre=${rest%%"$c"*}
                    if [[ $pre == "$rest" ]]; then out+=$c; i=$((i + 1)); continue; fi
                    j=$((i + 1 + ${#pre}))
                else
                    j=$((i + 1))
                    while [[ $j -lt $n ]]; do
                        q=${s:j:1}
                        if [[ $q == '\' ]]; then j=$((j + 2)); continue; fi
                        [[ $q == '"' ]] && break
                        j=$((j + 1))
                    done
                    if [[ $j -ge $n ]]; then out+=$c; i=$((i + 1)); continue; fi
                    pre=${s:i+1:j-i-1}
                fi
                if [[ $keep == 1 ]]; then out+=$pre; else out+=Q; fi
                i=$((j + 1)) ;;
            ';') out+=$'\n'; i=$((i + 1)) ;;
            '|')
                [[ ${s:i+1:1} == '|' ]] && i=$((i + 1))
                out+=$'\n'; i=$((i + 1)) ;;
            '&')
                next=${s:i+1:1}
                prev=; [[ $i -gt 0 ]] && prev=${s:i-1:1}
                if [[ $next == '&' ]]; then out+=$'\n'; i=$((i + 2))
                elif [[ $prev == '>' || $prev == '<' || $next == '>' ]]; then i=$((i + 1))
                else out+=$'\n'; i=$((i + 1)); fi ;;
            *) out+=$c; i=$((i + 1)) ;;
        esac
    done
    NORM=$out
}

# bash_guard <cwd> <command> <project dir>: prints the deny object for the first refused git write and returns 0;
# prints nothing and returns 1 otherwise. Quoted text is blanked first, so it is never read as a
# command; each segment is judged by the checkout it addresses. Scripts are not looked into.
bash_guard() {
    local cur=${1:-.} cmd=$2 proj=${3:-.} seg w i d sub root role
    local -a words args
    case $cmd in *git*) ;; *) return 1 ;; esac
    [[ $(LC_ALL=C; echo ${#cmd}) -le 16384 ]] || return 1
    normalize_cmd "$cmd"
    cmd=$NORM
    while IFS= read -r seg; do
        read -ra words <<<"$seg"
        while [[ ${#words[@]} -gt 0 && ${words[0]} =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do words=("${words[@]:1}"); done
        [[ ${#words[@]} -gt 0 ]] || continue
        words[0]=${words[0]#"${words[0]%%[!(]*}"}
        case ${words[0]} in
            cd)
                d=${words[1]:-}
                [[ -n $d && $d != - ]] || continue
                [[ $d == /* ]] || d="$cur/$d"
                d=$(cd "$d" 2>/dev/null && pwd -P) && cur=$d
                continue ;;
            git) ;;
            *) continue ;;
        esac
        d=$cur
        i=1
        while [[ $i -lt ${#words[@]} && ${words[i]} == -* ]]; do
            case ${words[i]} in
                -C)
                    w=${words[i + 1]:-}
                    [[ $w == /* ]] || w="$d/$w"
                    d=$(cd "$w" 2>/dev/null && pwd -P) || d=
                    i=$((i + 2)) ;;
                -c) i=$((i + 2)) ;;
                *) i=$((i + 1)) ;;
            esac
        done
        [[ -n $d && $i -lt ${#words[@]} ]] || continue
        sub=${words[i]}
        args=("${words[@]:i+1}")
        git_write_p "$sub" "$d" "${args[@]}" || continue
        root=$(git -C "$d" rev-parse --show-toplevel 2>/dev/null) || continue
        in_project_p "$root" "$proj" || continue
        role=$(guarded_role "$root") || continue
        deny "$role"
        return 0
    done <<<"$cmd"
    return 1
}

main() {
    [[ ${CODEO_HOME_EDITS:-} == allow ]] && return 0
    command -v jq >/dev/null 2>&1 || return 0
    local input tool cwd path key=file_path proj
    input=$(cat) || return 0
    tool=$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null) || return 0
    cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null) || return 0
    proj=${CLAUDE_PROJECT_DIR:-}
    [[ -d $proj ]] || proj=${cwd:-.}
    case $tool in
        Bash)
            path=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null) || return 0
            [[ -n $path ]] || return 0
            bash_guard "${cwd:-.}" "$path" "$proj"
            return 0 ;;
        Edit | Write) ;;
        NotebookEdit) key=notebook_path ;;
        *) return 0 ;;
    esac
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
    in_project_p "$root" "$proj" || return 0
    role=$(guarded_role "$root") || return 0
    deny "$role"
}

# Sourced for guarded_role and deny by the tests; run as the hook otherwise.
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main 2>/dev/null
    exit 0
fi
