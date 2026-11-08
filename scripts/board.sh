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
#       Sets issue N's Status to the option named <status> ("Ready", "In progress"), or, when
#       <status> is one of the keys ready, backlog, inProgress, inReview, done, to the name
#       configured under board.statuses for it, else its conventional default (Ready, Backlog,
#       In progress, In review, Done), on each synced
#       project (board.projects plus the gate project) that has that option, one line per project
#       written; a synced project without the option is skipped with a line on stderr. Every
#       project is probed for the option first, and the issue is added only to a synced project
#       that has it and is missing it, so `status` finds it where init gates. A card this run
#       added whose Status write then fails is removed again (one more stderr line asks for a hand
#       removal if that fails too); a card that was already there is never removed. A card the issue has on any other project is left exactly as it is, without a
#       line: a project retired from board.projects is not stamped. Exits non-zero in two
#       cases. When an add, a field lookup or a write failed on some project, that project is
#       skipped with one stderr line naming it and the reason, the others are still written, and
#       the exit is non-zero at the end even though something was written. When nothing failed but
#       nothing was written either, no project the issue is on has the option, and the stderr line
#       names the options that exist.
#
# Needs a gh login with the `project` scope; without it, says `gh auth refresh -s project`.
set -euo pipefail

# The boards are kept in step: `status` reads the gate project, which init gates on; `set` adds the
# issue only to a synced project whose Status has the option (probed before adding), then writes
# those and no others. The synced set is board.projects plus the gate project, so a project
# retired from the list stops being written even while old cards remain on it. A board with no
# projects list is just its gate project.
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
if projects=$(codeo_cfg '.board.projects[]?'); then
    projects=${projects//$'\n'/ }
else
    projects=$project
fi
# `projects` stays the listed set, which is what `status`'s drift line compares; `synced` is what
# `set` adds to and writes, and the gate project is in it even when the list leaves it out.
synced=$projects
[[ " $projects " == *" $project "* ]] || synced+=" $project"

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
# The five logical keys have conventional option names, so a project that follows them needs no
# board.statuses entry; prints the name for a key and returns 1 for any other word.
default_status() {
    case $1 in
        ready) echo "Ready" ;;
        backlog) echo "Backlog" ;;
        inProgress) echo "In progress" ;;
        inReview) echo "In review" ;;
        done) echo "Done" ;;
        *) return 1 ;;
    esac
}
# A logical name resolves to its entry under board.statuses when one is configured, else to its
# conventional default; any other string is already an option name and passes through.
# Only a plain word is looked up, so the argument can never reshape the jq filter.
want_arg=${3:-}
if [[ $cmd == set && $want_arg =~ ^[A-Za-z0-9_]+$ ]]; then
    if mapped=$(codeo_cfg ".board.statuses.$want_arg") || mapped=$(default_status "$want_arg"); then
        set -- "$1" "$2" "$mapped"
    fi
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
        issue_url=$url
        # Two passes over the synced set. The probe reads, for each project, where the issue's card
        # is and whether the project has the option; nothing is created yet, so a project that
        # cannot take the Status never gets a card. The write pass then adds the issue where it is
        # missing and sets the Status. The title is read from the project when the row has none.
        declare -A item_of status_of title_of field_of option_of names_of
        probed=() skipped_names=()
        failed=
        for p in $synced; do
            item_of[$p]='' status_of[$p]='' title_of[$p]=''
            while IFS= read -r row; do
                split_row "$row"
                if [[ ${pnum:-} == "$p" && -n ${item:-} ]]; then
                    item_of[$p]=$item status_of[$p]=${status:-} title_of[$p]=${ptitle:-}
                fi
            done <<<"$rows"
            probe_err=$(mktemp)
            # Like a failed add or write: one project failing is reported and skipped, never allowed
            # to abort before the others (the gate project, which init gates on); `failed` carries
            # it to the exit.
            if [[ -z ${item_of[$p]} ]] &&
                ! title_of[$p]=$(run_gh project view "$p" --owner "$owner" --format json --jq .title 2>"$probe_err"); then
                echo "board.sh: could not add #$n to project #$p — skipped: $(head -n 1 "$probe_err")" >&2
                rm -f "$probe_err"
                failed=1
                continue
            fi
            # The option ids come from each project itself rather than being pinned here, so
            # renaming or reordering columns on GitHub cannot leave this script writing a stale id.
            if ! options=$(run_gh project field-list "$p" --owner "$owner" --format json \
                --jq '.fields[] | select(.name == "Status") | .id as $f | .options[] | [$f, .id, .name] | @tsv' 2>"$probe_err"); then
                echo "board.sh: could not read the Status options of project #$p ${title_of[$p]} — skipped: $(head -n 1 "$probe_err")" >&2
                rm -f "$probe_err"
                failed=1
                continue
            fi
            rm -f "$probe_err"
            names_of[$p]=
            while IFS=$'\t' read -r f o name; do
                [[ -n $name ]] || continue
                names_of[$p]+="${names_of[$p]:+, }$name"
                if [[ $name == "$want" ]]; then
                    field_of[$p]=$f option_of[$p]=$o
                fi
            done <<<"$options"
            if [[ -z ${option_of[$p]:-} ]]; then
                echo "board.sh: project #$p ${title_of[$p]} has no option '$want' — skipped" >&2
                skipped_names+=("${names_of[$p]:-none}")
                continue
            fi
            probed+=("$p")
        done

        written=0
        for p in ${probed[@]+"${probed[@]}"}; do
            item=${item_of[$p]} fresh=
            if [[ -z $item ]]; then
                add_err=$(mktemp)
                if ! item=$(run_gh project item-add "$p" --owner "$owner" --url "$issue_url" --format json --jq .id 2>"$add_err"); then
                    echo "board.sh: could not add #$n to project #$p — skipped: $(head -n 1 "$add_err")" >&2
                    rm -f "$add_err"
                    failed=1
                    continue
                fi
                rm -f "$add_err"
                fresh=1
            fi
            write_err=$(mktemp)
            if ! project_id=$(run_gh project view "$p" --owner "$owner" --format json --jq .id 2>"$write_err") ||
                ! run_gh project item-edit --id "$item" --project-id "$project_id" \
                    --field-id "${field_of[$p]}" --single-select-option-id "${option_of[$p]}" >/dev/null 2>>"$write_err"; then
                echo "board.sh: could not write '$want' on project #$p ${title_of[$p]} — skipped: $(head -n 1 "$write_err")" >&2
                rm -f "$write_err"
                failed=1
                # A card this run created and could not stamp is taken off again, so the board is
                # as it was; a card that was already there is never touched.
                if [[ -n $fresh ]] && ! run_gh project item-delete "$p" --owner "$owner" --id "$item" >/dev/null 2>&1; then
                    echo "board.sh: could not remove the card it added to project #$p — remove item $item by hand" >&2
                fi
                continue
            fi
            rm -f "$write_err"
            if [[ -n $fresh ]]; then old="(not on the board)"; else old=${status_of[$p]:-(unset)}; fi
            echo "board.sh: #$n $old → $want on #$p ${title_of[$p]}"
            written=$((written + 1))
        done

        if [[ $written -eq 0 && -z $failed ]]; then
            echo "board.sh: no project #$n is on has the option '$want' (it has: ${skipped_names[*]:-none})" >&2
            exit 1
        fi
        # A skipped add is a failure the skills must see, though the other boards were written.
        [[ -z $failed ]] || exit 1
        ;;
esac
