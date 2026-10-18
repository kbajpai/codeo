#!/usr/bin/env bash
# The Kanban board's Status column, read and written for the pipeline — triage moves a workable
# issue to Ready or Backlog, init starts only a Ready issue and moves it to In progress, and close
# moves it to In review, back to In progress on a send-back, to Ready on a stash, to Backlog on an
# abandon, and to Done once the merge is verified. One script, so no skill hand-rolls the GraphQL
# and they all agree on which board and which field. The board comes from `board` in the
# project's .codeo/config.json (owner, projects[], gateProject, statuses{}); without one every
# verb prints `board: not configured` and exits 3, so a caller can skip the gate.
#
#   board.sh status <N>
#       Prints issue N's Status on the gate project: the option's name, `unset` when the issue is
#       on it with no Status, or `none` when it is not on it at all. When the issue is on several
#       synced boards and their Status differs, one line on stderr says so; the answer is still
#       the gate project's.
#   board.sh set <N> <status>
#       Sets issue N's Status to the option named <status> ("Ready", "In progress"), or to the name
#       configured under board.statuses when <status> is one of that map's keys, on every project
#       the issue is on whose Status has that option, one line per project written; a project
#       without the option is skipped with a line on stderr. The issue is first added to each synced
#       project it is missing from, so `status` finds it where init gates. Exits non-zero in two
#       cases. When an add, a field lookup or a write failed on some project, that project is
#       skipped with one stderr line naming it and the reason, the others are still written, and
#       the exit is non-zero at the end even though something was written. When nothing failed but
#       nothing was written either, no project the issue is on has the option, and the stderr line
#       names the options that exist.
#
# Needs a gh login with the `project` scope; without it, says `gh auth refresh -s project`.
set -euo pipefail

# The boards are kept in step: `status` reads the gate project, which init gates on; `set` adds the
# issue to every project in board.projects it is missing from, then writes those and every other
# project it is on. A board with no projects list is just its gate project.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"
# Read in the top-level shell (not inside $(...)) so an unusable config ends the script.
repo_owner=$(codeo_cfg_required .repo.owner) || exit 1
repo_name=$(codeo_cfg_required .repo.name) || exit 1
repo=$repo_owner/$repo_name
if ! codeo_cfg .board >/dev/null; then
    echo "board: not configured"
    exit 3
fi
owner=$(codeo_cfg_required .board.owner) || exit 1
project=$(codeo_cfg_required .board.gateProject) || exit 1
if projects=$(codeo_cfg '.board.projects[]'); then
    projects=${projects//$'\n'/ }
else
    projects=$project
fi

usage() {
    echo "usage: board.sh status <N> | board.sh set <N> <status>" >&2
    exit 1
}

# Runs gh, and turns a missing token scope into the one command that fixes it — gh's own message
# names the scope but not the remedy, and every caller of this script would otherwise have to.
run_gh() {
    local err
    err=$(mktemp)
    if gh "$@" 2>"$err"; then
        rm -f "$err"
        return 0
    fi
    if grep -qiE 'scope|INSUFFICIENT_SCOPES' "$err"; then
        echo "board.sh: the gh token lacks the 'project' scope: run 'gh auth refresh -s project'" >&2
    else
        cat "$err" >&2
    fi
    rm -f "$err"
    return 1
}

# Prints one row per project item the issue has under $owner, "<issue url>\t<item id>\t<status>\t
# <project number>\t<project title>"; an issue on no project prints one row, the url and four empty
# fields.
lookup() {
    local n=$1
    # $owner is spliced into the jq program because gh's --jq takes no --arg; it comes from the
    # project's own config, never from the caller.
    run_gh api graphql -F o="${repo%/*}" -F r="${repo#*/}" -F n="$n" -f query='
        query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){issue(number:$n){
          url projectItems(first:50){nodes{id
            project{number title owner{... on User{login} ... on Organization{login}}}
            fieldValueByName(name:"Status"){... on ProjectV2ItemFieldSingleSelectValue{name}}}}}}}' \
        --jq '.data.repository.issue as $i
              | [$i.projectItems.nodes[]
                  | select(.project.owner.login == "'"$owner"'")] as $its
              | if ($its | length) == 0 then [$i.url, "", "", "", ""] | @tsv
                else $its[] | [$i.url, .id, (.fieldValueByName.name // ""), (.project.number | tostring), .project.title] | @tsv end'
}

# Splits a lookup row into url/item/status/pnum/ptitle. The tabs become \x1f first: tab is IFS
# whitespace, so `read` would collapse the empty fields (an unset Status, an issue on no project)
# and shift every later one left.
split_row() {
    local row=${1//$'\t'/$'\x1f'}
    IFS=$'\x1f' read -r url item status pnum ptitle <<<"$row"
}

[[ $# -ge 2 ]] || usage
cmd=$1
n=${2#\#}
[[ $n =~ ^[0-9]+$ ]] || usage
# Checked before the host check below, so a wrong count prints usage on both hosts rather than
# the web branch reading a $3 that is not there.
case $cmd in
    status) [[ $# -eq 2 ]] || usage ;;
    set) [[ $# -eq 3 ]] || usage ;;
    *) usage ;;
esac
# A logical name in board.statuses ("inProgress") becomes the project's own option name; any other
# string is already an option name and passes through.
# Only a plain word is looked up, so the argument can never reshape the jq filter.
want_arg=${3:-}
if [[ $cmd == set && $want_arg =~ ^[A-Za-z0-9_]+$ ]] && mapped=$(codeo_cfg ".board.statuses.$want_arg"); then
    set -- "$1" "$2" "$mapped"
fi

# Projects v2 is GraphQL-only, and a web session's proxy refuses GraphQL outright — the same
# reason triage's review-thread scan is skipped there. Degrade before ever calling gh, rather than
# letting run_gh's failure look like any other script error to callers.
if [[ ${CLAUDE_CODE_REMOTE:-} == true ]]; then
    case $cmd in
        status) echo unavailable; exit 0 ;;
        set) echo "board.sh: unavailable in a web session (Projects v2 is GraphQL-only, refused by the proxy); move #$n to $3 by hand" >&2; exit 1 ;;
    esac
fi

rows=$(lookup "$n")
split_row "${rows%%$'\n'*}"
if [[ -z ${url:-} ]]; then
    echo "board.sh: no issue #$n in $repo" >&2
    exit 1
fi

case $cmd in
    status)
        found=none
        while IFS= read -r row; do
            split_row "$row"
            if [[ ${pnum:-} == "$project" ]]; then
                found=${status:-unset}
            fi
        done <<<"$rows"
        echo "$found"
        # Drift is only worth a word when the issue is on the gate project and another board: one
        # missing from a board is not a disagreement. The answer above stays the gate project's,
        # which is what init gates on.
        declare -A seen=()
        while IFS= read -r row; do
            split_row "$row"
            [[ -n ${pnum:-} ]] && seen[$pnum]=${status:-unset}
        done <<<"$rows"
        differs= listing=
        if [[ -n ${seen[$project]:-} ]]; then
            for p in $projects; do
                [[ -n ${seen[$p]:-} ]] || continue
                listing+="${listing:+, }#$p ${seen[$p]}"
                [[ ${seen[$p]} == "${seen[$project]}" ]] || differs=1
            done
        fi
        if [[ -n $differs ]]; then
            echo "board.sh: #$n differs across boards — $listing" >&2
        fi
        ;;
    set)
        want=$3
        # Every synced project gets the issue, so the boards never disagree about whether it exists:
        # one on neither, or only on one, is added to the rest, and the loop below sets it on all
        # of them along with any other project it was already on. The title is read here because
        # the row has none.
        added=() failed=
        for p in $projects; do
            on=
            while IFS= read -r row; do
                split_row "$row"
                [[ ${pnum:-} == "$p" ]] && on=1
            done <<<"$rows"
            [[ -z $on ]] || continue
            split_row "${rows%%$'\n'*}"
            # One project refusing the add must not stop the others: under set -e it would abort
            # before the gate project, which init gates on, was added to or written. Skipped with a line
            # naming it; `failed` makes the exit status non-zero at the end.
            add_err=$(mktemp)
            if ! new=$(run_gh project item-add "$p" --owner "$owner" --url "$url" --format json --jq .id 2>"$add_err") ||
                ! ptitle=$(run_gh project view "$p" --owner "$owner" --format json --jq .title 2>>"$add_err"); then
                echo "board.sh: could not add #$n to project #$p — skipped: $(head -n 1 "$add_err")" >&2
                rm -f "$add_err"
                failed=1
                continue
            fi
            rm -f "$add_err"
            added+=("$p")
            # An issue on no project has one empty row, which the new row replaces.
            if [[ -z ${item:-} ]]; then rows=; fi
            rows+="${rows:+$'\n'}$url"$'\t'"$new"$'\t\t'"$p"$'\t'"$ptitle"
        done

        written=0 skipped_names=()
        declare -A field_of option_of names_of
        while IFS= read -r row; do
            split_row "$row"
            # The empty row of an issue on no project survives when every add failed: nothing to write.
            [[ -n ${item:-} ]] || continue
            # The option ids come from each project itself rather than being pinned here, so
            # renaming or reordering columns on GitHub cannot leave this script writing a stale id.
            if [[ -z ${names_of[$pnum]+x} ]]; then
                # Like a failed add or write: reported, skipped, never allowed to abort before the
                # other boards (the gate project, which init gates on) are written; `failed` carries it to the exit.
                field_err=$(mktemp)
                if ! options=$(run_gh project field-list "$pnum" --owner "$owner" --format json \
                    --jq '.fields[] | select(.name == "Status") | .id as $f | .options[] | [$f, .id, .name] | @tsv' 2>"$field_err"); then
                    echo "board.sh: could not read the Status options of project #$pnum $ptitle — skipped: $(head -n 1 "$field_err")" >&2
                    rm -f "$field_err"
                    failed=1
                    names_of[$pnum]=
                    continue
                fi
                rm -f "$field_err"
                names_of[$pnum]=
                while IFS=$'\t' read -r f o name; do
                    [[ -n $name ]] || continue
                    names_of[$pnum]+="${names_of[$pnum]:+, }$name"
                    if [[ $name == "$want" ]]; then
                        field_of[$pnum]=$f option_of[$pnum]=$o
                    fi
                done <<<"$options"
            fi
            if [[ -z ${option_of[$pnum]:-} ]]; then
                echo "board.sh: project #$pnum $ptitle has no option '$want' — skipped" >&2
                skipped_names+=("${names_of[$pnum]:-none}")
                continue
            fi
            # Like a failed add: one project refusing the write is reported and skipped, never
            # allowed to abort before the others (the gate project, which init gates on) are written.
            write_err=$(mktemp)
            if ! project_id=$(run_gh project view "$pnum" --owner "$owner" --format json --jq .id 2>"$write_err") ||
                ! run_gh project item-edit --id "$item" --project-id "$project_id" \
                    --field-id "${field_of[$pnum]}" --single-select-option-id "${option_of[$pnum]}" >/dev/null 2>>"$write_err"; then
                echo "board.sh: could not write '$want' on project #$pnum $ptitle — skipped: $(head -n 1 "$write_err")" >&2
                rm -f "$write_err"
                failed=1
                continue
            fi
            rm -f "$write_err"
            if [[ " ${added[*]:-} " == *" $pnum "* ]]; then old="(not on the board)"; else old=${status:-(unset)}; fi
            echo "board.sh: #$n $old → $want on #$pnum $ptitle"
            written=$((written + 1))
        done <<<"$rows"

        if [[ $written -eq 0 && -z $failed ]]; then
            echo "board.sh: no project #$n is on has the option '$want' (it has: ${skipped_names[*]:-none})" >&2
            exit 1
        fi
        # A skipped add is a failure the skills must see, though the other boards were written.
        [[ -z $failed ]] || exit 1
        ;;
esac
