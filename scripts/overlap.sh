#!/usr/bin/env bash
# Where this branch collides with another workflow in flight, judged from actual diffs as well as
# declared footprints, so it can run at every step.
#
# Three things are compared, each closing a gap a plan-time check alone leaves:
#   1. Every step runs this, not only planning, and the diff side
#      (`git diff --name-only origin/<base>...`) is what each branch has really changed.
#   2. A footprint is compared with diffs as well as with footprints. A path is paired when it is in
#      both branches' changes, or in one's changes and inside the other's `files` globs, so work that
#      has outgrown its plan still shows up — and two footprints are compared with each other, through
#      the paths their globs resolve to on `origin/<base>` and in both diffs, so two plans that name
#      the same files are told before either has written them (`glob:<their glob>`, and
#      `wiki:<Page>` for a page both name, when the wiki module is on). A literal `files:` entry is in
#      that universe whether or not anything has written it yet.
#   3. The same overlap would otherwise be asked again at every step. A pair already named in a
#      `### Q` block of any of this issue's dossiers (the other issue's `#M` and the path or
#      `exclusive:<name>` together) is dropped.
#
#   overlap.sh <N>
#       Prints `M<TAB>what` for each other workflow M that overlaps issue N's branch and has not
#       been raised yet, sorted; `what` is a path, `exclusive:<name>`,
#       `glob:<glob>` or `wiki:<Page>`. Prints nothing when there
#       is no new overlap. Exit 0 always — a usage error is the only exit 1.
#   overlap.sh --outside <N>
#       Prints this branch's changed paths that match none of its own `files` globs, one per line.
#
# Globs: `**` is read as `*`, matched with bash `==`; `none` is no glob. `$CODEO_STATE_DIR/**` never
# pairs, and `--outside` also leaves out the configured plansDir. This branch's footprint is read from the
# working tree's $CODEO_STATE_DIR/<N>/plan.md (or done/<N>/); another workflow's from its pushed
# branch. The base branch is the configured baseBranch; `wiki:` applies only when the project's
# `modules` include "wiki", and names the page file wiki/<Page>.md.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

usage() { echo "usage: overlap.sh [--outside] <N>" >&2; exit 1; }

outside=
[[ ${1:-} == --outside ]] && { outside=1; shift; }
(($# == 1)) && [[ $1 =~ ^[0-9]+$ ]] || usage
n=$1

cd "$(git rev-parse --show-toplevel)"
export LC_ALL=C

base=$(codeo_base_branch)
# The plan doc lives here, not in the footprint, so `--outside` must not report it.
plans_dir=$(codeo_plans_dir)
plans_dir=${plans_dir%/}
# The state directory as git sees it (relative to the repo root, where this runs): dossier paths
# are compared against branch contents, which are never absolute.
state_rel=${CODEO_STATE_DIR#"$CODEO_PROJECT_ROOT"/}

# The wiki pairing needs the wiki module: without it `wiki:` lines in a plan are inert.
wiki_on=
modules=$(codeo_cfg '.modules[]?' || true)
[[ $'\n'$modules$'\n' == *$'\nwiki\n'* ]] && wiki_on=1

# Footprint values for one key (files|wiki|exclusive) from plan text on stdin, one per line, `none` dropped.
footprint() {
    awk -v key="$1" '
        /^### Footprint/ { f = 1; next }
        /^##/ { f = 0 }
        f && $0 ~ "^ *" key ":" {
            sub(/^ *[a-z]+: */, "")
            n = split($0, parts, ",")
            for (i = 1; i <= n; i++) { gsub(/^ +| +$/, "", parts[i]); if (parts[i] != "" && parts[i] != "none") print parts[i] }
        }'
}

# literals <entry...>: the entries that name one path outright (no wildcard, not a dossier). Such a
# path is in the universe before any branch creates it, so two plans for a file neither has created
# still pair.
literals() {
    local e
    for e in "$@"; do
        [[ $e == *[*?[]* || $e == "$state_rel"/* ]] && continue
        printf '%s\n' "$e"
    done
    return 0
}

# Changed paths against origin/<base> for a ref, dossiers left out.
changes() { git diff --name-only "origin/$base...$1" -- . ":!$state_rel" 2>/dev/null || true; }

# matches <path> <glob...>: true when the path matches any glob.
matches() {
    local p=$1 g
    shift
    for g in "$@"; do
        g=${g//\*\*/*}
        # shellcheck disable=SC2053
        [[ $p == $g ]] && return 0
    done
    return 1
}

# resolve <glob...>: the members of $universe (origin/<base>'s tree plus both diffs) any glob matches.
resolve() {
    local p
    while IFS= read -r p; do
        [[ -n $p ]] && matches "$p" "$@" && printf '%s\n' "$p"
    done <<<"$universe"
    return 0
}

mydir=$state_rel/$n
[[ -d $mydir ]] || mydir=$state_rel/done/$n
myplan=
[[ -f $mydir/plan.md ]] && myplan=$(cat "$mydir/plan.md")
mapfile -t my_globs < <(footprint files <<<"$myplan")
my_wiki=()
[[ -z $wiki_on ]] || mapfile -t my_wiki < <(footprint wiki <<<"$myplan")
mapfile -t mine < <(changes HEAD)

if [[ -n $outside ]]; then
    for p in "${mine[@]}"; do
        [[ $p == "$plans_dir"/* ]] && continue
        # `wiki:` lists page names, each the file wiki/<Page>.md — and only that file: the images
        # and diagram sources a page brings are listed under `files:`.
        if [[ -n $wiki_on && $p == wiki/*.md && $p != wiki/*/* ]]; then
            page=${p#wiki/}
            page=${page%.md}
            [[ " ${my_wiki[*]:-} " == *" $page "* ]] && continue
        fi
        matches "$p" "${my_globs[@]}" || echo "$p"
    done
    exit 0
fi

mapfile -t my_excl < <(footprint exclusive <<<"$myplan")

# raised <M> <what>: a `### Q` block in this issue's dossiers names both.
raised() {
    local f
    for f in "$state_rel/$n"/*.md "$state_rel/done/$n"/*.md; do
        [[ -f $f ]] || continue
        awk -v m="#$1" -v w="$2" '
            # A token counts only when it stands alone: `#9` is not `#90`, `Foo.cs` is not `Foo.cs.bak`.
            # A sentence'"'"'s closing period after a path is not part of it.
            function has(text, tok, digits,    i, rest, before, after, nxt) {
                rest = text
                while ((i = index(rest, tok)) > 0) {
                    before = (i > 1) ? substr(rest, i - 1, 1) : ""
                    after = substr(rest, i + length(tok), 1)
                    nxt = substr(rest, i + length(tok) + 1, 1)
                    if (digits) {
                        if (after !~ /[0-9]/) return 1
                    } else if (before !~ /[A-Za-z0-9._\/-]/ &&
                               (after !~ /[A-Za-z0-9._\/-]/ || (after == "." && nxt !~ /[A-Za-z0-9._\/-]/))) return 1
                    rest = substr(rest, i + 1)
                }
                return 0
            }
            function both(b) { return b != "" && has(b, m, 1) && has(b, w, 0) }
            /^### Q[0-9]/ { if (both(blk)) found = 1; blk = $0 "\n"; next }
            /^##/ { if (both(blk)) found = 1; blk = ""; next }
            blk { blk = blk $0 "\n" }
            END { if (both(blk)) found = 1; exit !found }' "$f" && return 0
    done
    return 1
}

mapfile -t tree < <(git ls-tree -r --name-only "origin/$base" 2>/dev/null | grep -v "^${state_rel//./\\.}/" || true)

pairs=
while IFS=$'\t' read -r m branch dir; do
    [[ -n $m ]] || continue
    sha=$(git rev-parse "origin/$branch" 2>/dev/null) || continue
    theirplan=$(git show "$sha:$dir/plan.md" 2>/dev/null || true)
    mapfile -t their_globs < <(footprint files <<<"$theirplan")
    mapfile -t their_excl < <(footprint exclusive <<<"$theirplan")
    their_wiki=()
    [[ -z $wiki_on ]] || mapfile -t their_wiki < <(footprint wiki <<<"$theirplan")
    mapfile -t theirs < <(changes "$sha")
    universe=$(printf '%s\n' "${tree[@]}" "${mine[@]}" "${theirs[@]}" \
        "$(literals "${my_globs[@]}")" "$(literals "${their_globs[@]}")" | sort -u)
    # Membership by associative array: a quiet-grep pipe quits at its first match and a writer still
    # producing takes SIGPIPE, which `pipefail` would turn into "no pair".
    unset in_theirs in_mine in_their_excl in_my_resolved
    declare -A in_theirs in_mine in_their_excl in_my_resolved
    for p in "${theirs[@]}"; do in_theirs[$p]=1; done
    for p in "${mine[@]}"; do in_mine[$p]=1; done
    for p in "${their_excl[@]}"; do in_their_excl[$p]=1; done
    whats=()
    for p in "${mine[@]}"; do
        if [[ -n ${in_theirs[$p]:-} ]] || matches "$p" "${their_globs[@]}"; then
            whats+=("$p")
        fi
    done
    for p in "${theirs[@]}"; do
        [[ -n ${in_mine[$p]:-} ]] && continue
        matches "$p" "${my_globs[@]}" && whats+=("$p")
    done
    for x in "${my_excl[@]}"; do
        [[ -n ${in_their_excl[$x]:-} ]] && whats+=("exclusive:$x")
    done
    # One line per their-glob whose resolution shares a path with the resolution of mine.
    my_resolved=$(resolve "${my_globs[@]}")
    if [[ -n $my_resolved ]]; then
        while IFS= read -r p; do in_my_resolved[$p]=1; done <<<"$my_resolved"
        for g in "${their_globs[@]}"; do
            their_resolved=$(resolve "$g")
            while IFS= read -r p; do
                if [[ -n $p && -n ${in_my_resolved[$p]:-} ]]; then
                    whats+=("glob:$g")
                    break
                fi
            done <<<"$their_resolved"
        done
    fi
    for w in "${my_wiki[@]}"; do
        [[ " ${their_wiki[*]:-} " == *" $w "* ]] && whats+=("wiki:$w")
    done
    for w in "${whats[@]}"; do
        raised "$m" "$w" || pairs+="$m"$'\t'"$w"$'\n'
    done
done < <(bash "$CODEO_PLUGIN_ROOT/scripts/inflight.sh" --branches --except "$n" 2>/dev/null || true)

[[ -z $pairs ]] || printf '%s' "$pairs" | sort -u
exit 0
