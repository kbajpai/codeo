#!/usr/bin/env bash
# Every codeo workflow in flight, derived from what is pushed rather than kept anywhere.
#
#   inflight.sh [--except <N>] [--tsv | --branches]
#       One block per workflow: the issue, its branch, its assignee, the last step whose dossier
#       has an `## Outcome`, the plan's `### Footprint` lines when there is one, and `changed:` — the files the branch
#       actually changes against origin/<base> (`git diff --name-only origin/<base>...<branch>`, dossiers left out,
#       comma-joined, `none` when empty). --except leaves the caller's own issue out.
#       --branches prints one `N<TAB>branch<TAB>dir` line per workflow (dir is <state>/N or
#       <state>/done/N, <state> being the .codeo directory) and nothing else — no assignee lookup, so no `gh` call, and nothing at
#       all when nothing is in flight. It cannot be combined with --tsv: they are different outputs.
#       --tsv prints one tab-separated line per workflow instead — issue, branch, state (working
#       or pr-open), last step (issue|init|plan|implement|qc|close|none), assignee logins joined
#       by `,` (empty when none) — with no footprint and no "nothing in flight" line. A failed
#       assignee lookup fails the whole listing instead: exit 1, the reason on stderr, nothing on
#       stdout, so a consumer never mistakes "unknown" for "none".
#       It exists for status reporters, which read it rather than scraping the human blocks. Lines come in origin's ref order, not sorted by issue.
#
# A workflow is a branch on origin, other than the base branch and codeo/intake, carrying a dossier:
# at <state>/<N>/ while it is being worked, or at <state>/done/<N>/ once close has opened its PR —
# the latter only when the base branch does not already have it, since every branch inherits the
# base branch's archive.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

steps=(issue init plan implement qc close)

except= tsv= branches=
while (($#)); do
    case $1 in
        --except) except=${2:?issue number}; shift 2 ;;
        --tsv) tsv=1; shift ;;
        --branches) branches=1; shift ;;
        *) echo "usage: inflight.sh [--except <N>] [--tsv | --branches]" >&2; exit 1 ;;
    esac
done
[[ -z $tsv || -z $branches ]] || { echo "usage: inflight.sh [--except <N>] [--tsv | --branches]" >&2; exit 1; }

cd "$(git rev-parse --show-toplevel)"
base=$(codeo_base_branch)
# The state directory as git sees it (relative to the repo root, where this runs).
state_rel=${CODEO_STATE_DIR#"$CODEO_PROJECT_ROOT"/}
git fetch -q --prune origin 2>/dev/null || echo "inflight: fetch failed; reading what is already here" >&2

# The last step, in pipeline order, whose dossier has an `## Outcome` that is not still pending.
last_step() {
    local ref=$1 dir=$2 step done=
    for step in "${steps[@]}"; do
        git show "$ref:$dir/$step.md" 2>/dev/null | awk '
            /^## Outcome/ { o = 1; next }
            /^## / { o = 0 }
            o && NF && !/_Pending/ { found = 1 }
            END { exit !found }' && done=$step
    done
    echo "${done:-none}"
}

base_sha=$(git rev-parse "origin/$base")
found=0 rows=
while IFS= read -r ref; do
    branch=${ref#origin/}
    [[ $branch == "$base" || $branch == codeo/intake || $branch == HEAD || $ref == origin ]] && continue
    # By sha: Git for Windows' shell rewrites an `origin/x:path` argument as if it were a path list.
    sha=$(git rev-parse "$ref")

    dossiers=$(git ls-tree --name-only "$sha" -- "$state_rel/" "$state_rel/done/" 2>/dev/null |
        grep -E "^${state_rel//./\\.}/(done/)?[0-9]+\$" || true)
    for dir in $dossiers; do
        n=${dir##*/}
        [[ $n == "$except" ]] && continue
        if [[ $dir == "$state_rel"/done/* ]]; then
            git cat-file -e "$base_sha:$dir" 2>/dev/null && continue
            state="PR open" state_token=pr-open
        else
            state=working state_token=working
        fi
        found=1
        if [[ -n $branches ]]; then
            rows+=$(printf '%s\t%s\t%s' "$n" "$branch" "$dir")$'\n'
            continue
        fi
        # </dev/null: gh reads stdin, and would swallow the rest of the branch list.
        assignee=$(bash "$CODEO_PLUGIN_ROOT/scripts/github.sh" issue view "$n" </dev/null 2>/dev/null \
            | jq -r '[.assignees[]?] // [] | join(",")' 2>/dev/null || echo '?')
        if [[ -n $tsv ]]; then
            # A failed lookup (the `?` above) fails the whole listing: a consumer would read an empty
            # field as "no assignee", and rows are held back so a failure prints nothing at all.
            if [[ $assignee == '?' ]]; then
                echo "inflight: assignee lookup for #$n failed" >&2
                exit 1
            fi
            rows+=$(printf '%s\t%s\t%s\t%s\t%s' "$n" "$branch" "$state_token" "$(last_step "$sha" "$dir")" "$assignee")$'\n'
            continue
        fi
        echo "#$n  $branch"
        echo "  assignee:  ${assignee:-none}"
        echo "  step:      $(last_step "$sha" "$dir") ($state)"
        { git show "$sha:$dir/plan.md" 2>/dev/null || true; } | awk '
            /^### Footprint/ { f = 1; next }
            /^##/ { f = 0 }
            f && /^ *(files|wiki|exclusive|sequenced):/ { sub(/^ */, ""); print "  " $0 }'
        changed=$(git diff --name-only "$base_sha...$sha" -- . ":!$state_rel" 2>/dev/null | paste -sd, - | sed 's/,/, /g')
        echo "  changed:    ${changed:-none}"
        echo
    done
done < <(git for-each-ref --format='%(refname:short)' refs/remotes/origin)

[[ -z $rows ]] || printf '%s' "$rows"
((found)) || [[ -n $tsv || -n $branches ]] || echo "inflight: no other workflow in flight"
