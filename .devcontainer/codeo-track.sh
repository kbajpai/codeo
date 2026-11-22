#!/usr/bin/env bash
# Records an issue's branch, containers, images, volumes and sandboxes, and their removal, in ONE
# comment on the issue (found by its hidden marker, created once, then edited). Bash 3.2 and
# macOS portable; needs only `gh` (api, --paginate, --jq, -F body=@file, -X PATCH), `hostname`,
# `date` and coreutils. Never needs jq.
#
#   codeo-track.sh add <N> <kind> <name>
#   codeo-track.sh mark <N> <kind> <name> removed|deleted
#   codeo-track.sh confirm <N> [--yes] [--local <text>]
#
# kinds: branch container image volume sandbox.   Exit: add/mark 0 recorded or nothing to do,
# 3 not recorded (one `track:` line printed), 2 usage. confirm: 0 go on, 1 refused.
# A failed record must never fail a creation: callers ignore the status.
# Seams: CODEO_REPO_URL, CODEO_TRACK_HOST, CODEO_TRACK_NOW, CODEO_TRACK_TTY=1 (read the answer
# of `confirm` from stdin instead of requiring a terminal).
set -uo pipefail

marker='<!-- codeo:tracking -->'
header='| Kind | Name | Host | Status | Created (UTC) | Removed (UTC) |'
separator='|---|---|---|---|---|---|'
nl=$'\n'

usage() {
    cat >&2 <<'USAGE'
usage: codeo-track.sh add <N> <kind> <name>
       codeo-track.sh mark <N> <kind> <name> removed|deleted
       codeo-track.sh confirm <N> [--yes] [--local <text>]
kinds: branch container image volume sandbox
USAGE
    exit 2
}

repo_slug() {
    local url=${CODEO_REPO_URL:-https://github.com/kbajpai/codeo.git} path
    case $url in
        https://*|http://*) path=${url#*://}; path=${path#*/} ;;
        git@*:*) path=${url#*:} ;;
        ssh://*) path=${url#*://}; path=${path#*/} ;;
        *) return 1 ;;
    esac
    path=${path%/}
    path=${path%.git}
    case $path in */*) printf '%s\n' "$path" ;; *) return 1 ;; esac
}

now() { if [[ -n ${CODEO_TRACK_NOW:-} ]]; then printf '%s\n' "$CODEO_TRACK_NOW"; else date -u +%Y-%m-%dT%H:%M:%SZ; fi; }
this_host() { if [[ -n ${CODEO_TRACK_HOST:-} ]]; then printf '%s\n' "$CODEO_TRACK_HOST"; else hostname 2>/dev/null || uname -n; fi; }

tmp_files=()
cleanup() { local f; for f in ${tmp_files[@]+"${tmp_files[@]}"}; do rm -f "$f"; done; }
trap cleanup EXIT
new_tmp() { local f; f=$(mktemp "${TMPDIR:-/tmp}/codeo-track.XXXXXX") || return 1; tmp_files+=("$f"); printf '%s\n' "$f"; }

trim() { local v=$1; v=${v#"${v%%[![:space:]]*}"}; v=${v%"${v##*[![:space:]]}"}; printf '%s' "$v"; }

# `find_comment <N>` sets cid (empty when none); returns 1 when gh cannot answer.
find_comment() {
    local ids
    command -v gh >/dev/null 2>&1 || return 1
    ids=$(gh api --paginate "repos/$slug/issues/$1/comments" \
        --jq ".[] | select(.body | contains(\"$marker\")) | .id" 2>/dev/null) || return 1
    cid=${ids%%$'\n'*}
}

read_body() { gh api "repos/$slug/issues/comments/$1" --jq .body 2>/dev/null; }

# parse_body <body>: sets head_text (through the separator), rows[] (kind|name|host|status|created|removed),
# tail_text (after the table). Returns 1 when there is no recognisable table.
rows=()
head_text=; tail_text=
parse_body() {
    local line l state=0 f1 f2 f3 f4 f5 f6
    rows=(); head_text=; tail_text=
    while IFS= read -r line || [[ -n $line ]]; do
        l=${line%$'\r'}
        case $state in
            0) head_text="$head_text$line$nl"; [[ $l == "$header" ]] && state=1 ;;
            1) if [[ $l == '|'*---* ]]; then head_text="$head_text$line$nl"; state=2; else return 1; fi ;;
            2) if [[ $l == '|'* ]]; then
                   IFS='|' read -r _ f1 f2 f3 f4 f5 f6 _ <<< "$l"
                   rows+=("$(trim "$f1")|$(trim "${f2//\`/}")|$(trim "$f3")|$(trim "$f4")|$(trim "$f5")|$(trim "$f6")")
               else tail_text="$tail_text$line$nl"; state=3; fi ;;
            3) tail_text="$tail_text$line$nl" ;;
        esac
    done <<< "$1"
    [[ $state -ge 1 ]] && [[ $state -ge 2 ]]
}

# fmt_row <kind|name|host|status|created|removed> -> markdown row
fmt_row() {
    local k n h s c r out f
    IFS='|' read -r k n h s c r <<< "$1"
    out='|'
    for f in "$k" "\`$n\`" "$h" "$s" "$c" "$r"; do
        if [[ -z $f ]]; then out="$out |"; else out="$out $f |"; fi
    done
    printf '%s\n' "$out"
}

build_table_text() { local r; for r in ${rows[@]+"${rows[@]}"}; do fmt_row "$r"; done; }

# fail_record <message>: one track: line, exit 3
fail_record() { printf 'track: %s\n' "$1"; exit 3; }

# load <N> <manual-hint>: sets slug, cid, rows, head_text, tail_text; exits 3 on trouble.
load() {
    local n=$1 hint=$2 body
    slug=$(repo_slug) || fail_record "cannot read owner/repo from CODEO_REPO_URL; $hint"
    find_comment "$n" || fail_record "could not read the comments of #$n; $hint"
    if [[ -z $cid ]]; then
        head_text="$marker${nl}Codeo tracking for #$n: branches, containers and their removal.$nl$nl$header$nl$separator$nl"
        tail_text="${nl}Edited by codeo; the table is rewritten, text outside it is kept.$nl"
        rows=()
        return 0
    fi
    body=$(read_body "$cid") || fail_record "could not read tracking comment $cid on #$n; $hint"
    parse_body "$body" || fail_record "tracking comment $cid on #$n has no recognisable table and was left untouched; $hint"
}

# save <N> <manual-hint>: POST (no comment yet) or PATCH the rebuilt body.
save() {
    local n=$1 hint=$2 f
    f=$(new_tmp) || fail_record "could not write a temporary file; $hint"
    { printf '%s' "$head_text"; build_table_text; printf '%s' "$tail_text"; } > "$f"
    if [[ -z $cid ]]; then
        gh api -X POST "repos/$slug/issues/$n/comments" -F "body=@$f" >/dev/null 2>&1 \
            || fail_record "could not create the tracking comment on #$n; $hint"
    else
        gh api -X PATCH "repos/$slug/issues/comments/$cid" -F "body=@$f" >/dev/null 2>&1 \
            || fail_record "could not update tracking comment $cid on #$n; $hint"
    fi
}

valid_kind() { case $1 in branch|container|image|volume|sandbox) return 0 ;; *) return 1 ;; esac; }
valid_text() { case $1 in ''|*'|'*|*'`'*|*$'\n'*) return 1 ;; esac; return 0; }
valid_num() { case $1 in ''|*[!0-9]*) return 1 ;; esac; return 0; }

cmd_add() {
    [[ $# -eq 3 ]] || usage
    local n=$1 kind=$2 name=$3 host= created row r k nm h s c rm hint
    valid_num "$n" && valid_kind "$kind" && valid_text "$name" || usage
    [[ $kind == branch ]] || host=$(this_host)
    created=$(now)
    row="| $kind | \`$name\` | $host | active | $created | |"
    [[ -n $host ]] || row="| $kind | \`$name\` | | active | $created | |"
    hint="add this row by hand: $row"
    load "$n" "$hint"
    for r in ${rows[@]+"${rows[@]}"}; do
        IFS='|' read -r k nm h s c rm <<< "$r"
        if [[ $k == "$kind" && $nm == "$name" && $h == "$host" && $s == active ]]; then return 0; fi
    done
    rows+=("$kind|$name|$host|active|$created|")
    save "$n" "$hint"
}

cmd_mark() {
    [[ $# -eq 4 ]] || usage
    local n=$1 kind=$2 name=$3 status=$4 host removed r k nm h s c rm changed=0 i=0 hint
    valid_num "$n" && valid_kind "$kind" && valid_text "$name" || usage
    case $status in
        removed) ;;
        deleted) [[ $kind == branch ]] || usage ;;
        *) usage ;;
    esac
    host=$(this_host)
    removed=$(now)
    hint="set $kind \`$name\` to $status ($removed) in the tracking comment by hand"
    load "$n" "$hint"
    [[ -n $cid ]] || return 0
    for r in ${rows[@]+"${rows[@]}"}; do
        IFS='|' read -r k nm h s c rm <<< "$r"
        if [[ $k == "$kind" && $nm == "$name" && $s == active ]] && { [[ $kind == branch ]] || [[ $h == "$host" ]]; }; then
            rows[$i]="$k|$nm|$h|$status|$c|$removed"
            changed=1
        fi
        i=$((i + 1))
    done
    [[ $changed -eq 1 ]] || return 0
    save "$n" "$hint"
}

cmd_confirm() {
    [[ $# -ge 1 ]] || usage
    local n=$1 yes=0 local_text= lines= r k nm h s c rm ans
    shift
    valid_num "$n" || usage
    while [[ $# -gt 0 ]]; do
        case $1 in
            --yes) yes=1; shift ;;
            --local) [[ $# -ge 2 ]] || usage; local_text=$2; shift 2 ;;
            *) usage ;;
        esac
    done
    slug=; cid=
    if slug=$(repo_slug) && find_comment "$n" && { [[ -z $cid ]] || { body=$(read_body "$cid") && parse_body "$body"; }; }; then
        for r in ${rows[@]+"${rows[@]}"}; do
            IFS='|' read -r k nm h s c rm <<< "$r"
            [[ $s == active && ( $k == container || $k == sandbox ) ]] || continue
            lines="$lines  - $k \`$nm\` on host ${h:-unknown}, created $c, status $s$nl"
        done
    else
        printf 'track: could not read the tracking comment for #%s\n' "$n"
    fi
    [[ -n $lines || -n $local_text ]] || return 0
    printf 'Issue #%s already has containers on record:\n' "$n"
    [[ -z $lines ]] || printf '%s' "$lines"
    [[ -z $local_text ]] || printf '  - %s\n' "$local_text"
    printf 'A row on another host is not proof the container still exists.\n'
    [[ $yes -eq 1 ]] && return 0
    if [[ -t 0 || ${CODEO_TRACK_TTY:-} == 1 ]]; then
        printf 'Create another? [y/N] '
        ans=
        read -r ans || true
        printf '\n'
        case $ans in y|Y) return 0 ;; *) return 1 ;; esac
    fi
    printf 'track: not a terminal; pass --yes to go on\n'
    return 1
}

[[ $# -ge 1 ]] || usage
cmd=$1; shift
case $cmd in
    add) cmd_add "$@" ;;
    mark) cmd_mark "$@" ;;
    confirm) cmd_confirm "$@" ;;
    *) usage ;;
esac
