#!/usr/bin/env bash
# init's atomic claim: the branch push itself, made create-only so that of two inits on one issue
# exactly one succeeds. "<base>" below is the config's baseBranch, and ".codeo" the state
# directory as git sees it (the dossiers live in the repo, so the path is relative).
#
#   claim.sh <issue> <branch> <worktree>
#       Pushes <branch> from <worktree> with --force-with-lease=refs/heads/<branch>: — an empty
#       expected value, so origin refuses the push whenever the branch already exists there, even
#       when a plain push would fast-forward. Nothing is written on origin by a refused push.
#         0  pushed: "claim: #N claimed <branch>"
#         2  refused because the branch exists: one stderr line naming who pushed it and what it
#            carries (this issue's init.md, another issue's dossier, or no dossier)
#         1  any other push failure, with git's own stderr
#       Re-running it from the SAME worktree with an identical tip exits 0: git answers "Everything
#       up-to-date" for an unchanged ref before it evaluates --force-with-lease. The create-only
#       invariant still holds across checkouts, because a second init makes a different commit and
#       is refused.
#
#   claim.sh --carries <issue> <branch> <repo>
#       Reads origin/<branch> in <repo> (the caller fetches first) and says what the branch adds
#       beyond origin/<base> under .codeo/: this issue's init.md, another issue's dossier (any
#       .codeo/<M>/ or done/<M>/, the first by path), or none. `init` runs it when origin
#       already has the derived branch name, to tell a resume from a collision.
#         0  "claim: <branch> carries #N's init.md (| Issue | …)": this issue's branch, a resume
#         2  one stdout line "claim: <branch> already exists on origin — pushed by <author, date>;
#            it carries #M's dossier (| Issue | …)" (or "it carries no dossier"), then one line
#            saying what to do: retitle #N or wait for #M, or rename or delete a branch that is
#            not a pipeline one. When the branch carries only #N's OWN archived dossier
#            (.codeo/done/<N>/…) the second line says so: "claim: <branch> carries only #N's
#            own archived dossier — #N has already been through close; finish or verify it with
#            close in its container, and retitle #N only for an issue reopened after
#            its merge". A fourth reading: the branch added nothing under
#            .codeo/ because it is already an ancestor of origin/<base> (merged with a merge
#            commit, then left on origin) and <base> holds .codeo/done/<N>: the first line ends
#            "; it was merged into <base> and left behind", the second says "claim: #N has already
#            been through close — delete <branch> on origin (close normally does), and retitle #N
#            only for an issue reopened after its merge". A fifth reading: the same, but the branch
#            tip is on origin/<base>'s first-parent chain — a branch cut from <base> with nothing added
#            (or once <base> itself): the first line ends "; it is bare — cut from <base> with nothing
#            of its own, and <base> holds #N's archive", the second is the same. Known limit: a
#            fast-forwarded branch reads bare too (the remedy is the same). A merged-and-left branch of
#            *another* issue M whose title derives N's name still reads `no dossier` — it adds
#            nothing beyond <base>, so nothing names M; deleting it or retitling is the right remedy
#            there too.
#         1  the branch or ref is missing
#
#   claim.sh --stash-live <issue> <branch> <repo>
#       Reads origin/<branch> in <repo> (the caller fetches first). It counts what two dossier files
#       say at the tip, not when they were committed: parks = lines "### Round <n> — stashed" or
#       "### Round <n> — abandoned" in .codeo/<issue>/close.md (a park is a stash or an abandon
#       heading), resumes = lines "- … — resumed: by … after the stash of " or "… after the abandon
#       of " in .codeo/<issue>/init.md. The workflow is parked while parks > resumes, and the
#       LAST park heading says which kind. Lines are trimmed of trailing whitespace (CR included)
#       first, and a heading may carry a note before or after `stashed` / `abandoned`. A file absent
#       at its path counts 0; renames, archive moves and later close rounds change neither count.
#         0  live: "claim: #N's stash is live"
#         3  not live, one stdout line: "claim: #N has no stash" (parks == 0), or "claim: #N's stash
#            was already resumed — <the last resume line, without its leading "- ">" ("abandon" in
#            place of "stash" when the last park was an abandon)
#         4  the last park is an abandon and is unresumed: one stdout line "claim: #N was abandoned
#            on <date> (close.md round <n>)"; the date is the committer date (%cs) of the commit that
#            added that heading, and <n> is the heading's round number
#         1  the branch or ref is missing
#
#   claim.sh --resume-line <issue> <branch> <repo> [<login>]
#       Reads origin/<branch> in <repo> (the caller fetches first), with the same two counts as
#       --stash-live, and prints the one line `init` appends to init.md's ## Log (before its
#       " · cost: …"): "- <today> — resumed: by <login> after the stash of <date>" or "… after the
#       abandon of <date>" (by the last park's kind) while parks > resumes, else "- <today> —
#       resumed: by <login> after a lost container". <today> is `date -u +%F`; <login> is "no
#       login" when absent or empty; <date> is the committer date (%cs) of the newest commit on
#       origin/<branch> that added a heading of that kind to .codeo/<issue>/close.md (the
#       newest touching it, when none did). The writer and the reader of the line are this one
#       file, so they cannot disagree.
#         0  printed
#         1  the branch or ref is missing
#
#   claim.sh --resume <issue> <branch> <worktree> <seen-sha>
#       Pushes <branch> from <worktree> with --force-with-lease=refs/heads/<branch>:<seen-sha>, so
#       origin refuses the push unless the tip is still the commit this resume read.
#         0  pushed: "claim: #N resumed <branch>"
#         2  refused: one stderr line, "was resumed since <seen> — <the last resume line>" when
#            init.md has more resume lines at the tip than at <seen>, else "moved since <seen> —
#            pushed by <author, date>"
#         1  any other push failure, with git's own stderr
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

die() { echo "claim: $*" >&2; exit 1; }

# The markers the park predicate counts (the dashes are em dashes, U+2014). Lines are trimmed
# of trailing whitespace (CR included) first. A stash heading has "stashed" right after an "— ",
# with an optional note before it ("— 2026-10-01 — stashed") or after it ("— stashed (2026-10-01)"),
# but "not stashed", "unstashed" and "(was stashed)" do not match. An abandon heading is the same
# with "abandoned"; a park is either, and a resume spends one of either kind.
stash_re='^### Round [0-9]+ — (.+ — )?stashed([^[:alnum:]].*)?$'
abandon_re='^### Round [0-9]+ — (.+ — )?abandoned([^[:alnum:]].*)?$'
park_re='^### Round [0-9]+ — (.+ — )?(stashed|abandoned)([^[:alnum:]].*)?$'
resume_re='^- .* — resumed: by .* after the (stash|abandon) of '

# [[:space:]] includes CR, so one POSIX expression trims both.
trim='s/[[:space:]]*$//'

# count_lines <dir> <ref> <path> <regex>: matching lines of the file at that ref in the repo at <dir>;
# 0 when it is absent.
count_lines() { git -C "$1" show "$2:$3" 2>/dev/null | sed "$trim" | grep -cE "$4" || true; }

# last_resume <dir> <ref> <path>: the last resume line, without its leading "- ".
last_resume() { git -C "$1" show "$2:$3" 2>/dev/null | sed "$trim" | grep -E "$resume_re" | tail -n1 | sed 's/^- //' || true; }

# last_park <dir> <ref> <path>: the last park heading of the file at that ref, trimmed; empty when none.
last_park() { git -C "$1" show "$2:$3" 2>/dev/null | sed "$trim" | grep -E "$park_re" | tail -n1 || true; }

# park_kind <dir> <ref> <path>: sets park_last (the last park heading, as last_park prints it), kind
# (abandon when it matches abandon_re, else stash) and kind_re (that kind's regex), so the callers
# select the kind in one place.
park_kind() {
    park_last=$(last_park "$1" "$2" "$3")
    if [[ $park_last =~ $abandon_re ]]; then kind=abandon kind_re=$abandon_re; else kind=stash kind_re=$stash_re; fi
}

# park_date <dir> <ref> <path> <re>: %cs of the newest commit on <ref> that ADDED a heading matching <re> to
# <path> — not of the newest commit touching it, which a later close.md edit (a log line) would
# make the wrong day. When no commit's added lines match (a heading that arrived by a rename or
# merge, say), the newest commit touching the path is the best answer left.
park_date() {
    local dir=$1 ref=$2 path=$3 re=$4 sha added
    while read -r sha; do
        # Captured, not piped into grep -q: -q quits at the first match and an upstream stage still
        # writing would take SIGPIPE, which pipefail reads as "no match".
        added=$(git -C "$dir" show --format= -p "$sha" -- "$path" | grep -E '^\+' | grep -Ev '^\+\+\+' |
            sed 's/^+//' | sed "$trim" || true)
        if grep -qE "$re" <<<"$added"; then
            git -C "$dir" log -1 --format=%cs "$sha"
            return 0
        fi
    done < <(git -C "$dir" log --format=%H "$ref" -- "$path")
    git -C "$dir" log -1 --format=%cs "$ref" -- "$path"
}

# carries <dir> <ref>: what <ref> (in the repo at <dir>) adds beyond origin/<base> under the dossier
# directories, for issue $n. Sets what ("#N's init.md (| Issue | …)", "#M's dossier" or "no dossier"),
# other (M, the first other issue's number by path, from .codeo/<M>/ or .codeo/done/<M>/)
# and other_line (that dossier's "| Issue |" row, when its init.md is at <ref>).
carries() {
    local dir=$1 ref=$2 added issue_line other_path
    added=$(git -C "$dir" diff --name-only --diff-filter=A "origin/$base...$ref" -- .codeo/ || true)
    what="no dossier" other="" other_line=""
    if grep -qx ".codeo/$n/init.md" <<<"$added"; then
        issue_line=$(git -C "$dir" show "$ref:.codeo/$n/init.md" | grep -m1 '^| Issue |' || true)
        what="#$n's init.md"
        [[ -z $issue_line ]] || what="$what ($issue_line)"
    else
        other_path=$(grep -E '^\.codeo/(done/)?[0-9]+/' <<<"$added" | head -n1 || true)
        other=$(sed -nE 's#^\.codeo/(done/)?([0-9]+)/.*#\2#p' <<<"$other_path")
        [[ -z $other ]] || what="#$other's dossier"
        if [[ -n $other ]]; then
            other_line=$(git -C "$dir" show "$ref:${other_path%/*}/init.md" 2>/dev/null | grep -m1 '^| Issue |' || true)
        fi
    fi
}

# merged_and_left <dir> <ref>: <ref> is already an ancestor of origin/<base> (a merge commit put it
# there) and <base> holds .codeo/done/$n. A merged branch makes origin/<base>...<ref> empty, so
# carries() cannot see its dossier and would call it "no dossier"; this reads <base> instead.
merged_and_left() {
    git -C "$1" merge-base --is-ancestor "$2" "origin/$base" &&
        git -C "$1" cat-file -e "origin/$base:.codeo/done/$n" 2>/dev/null
}

# bare_branch <repo> <ref>: <ref>'s commit is on origin/<base>'s first-parent chain. A merge commit's
# branch tip is a second parent, so a merged branch is off that line; a branch cut from <base> with
# nothing added (or once <base> itself) is on it. Limit: a fast-forwarded branch reads bare too — the
# remedy is the same. Called only once merged_and_left holds. The list is captured, not piped into
# grep -q: -q quits at the first match, and a rev-list still writing (a few hundred KB of history)
# would take SIGPIPE, which pipefail reads as "not on the chain".
bare_branch() {
    local list sha
    list=$(git -C "$1" rev-list --first-parent "origin/$base")
    sha=$(git -C "$1" rev-parse "$2")
    grep -qx "$sha" <<<"$list"
}

mode=claim
case ${1:-} in
    --carries | --stash-live | --resume-line | --resume) mode=${1#--}; shift ;;
esac

# A bare assignment, so a failing config read (which already printed its one line) ends the script.
base=$(codeo_base_branch)

if [[ $mode == carries ]]; then
    n=${1:?usage: claim.sh --carries <issue> <branch> <repo>}
    branch=${2:?usage: claim.sh --carries <issue> <branch> <repo>}
    repo=${3:?usage: claim.sh --carries <issue> <branch> <repo>}
    ref="origin/$branch"
    git -C "$repo" rev-parse -q --verify "$ref^{commit}" >/dev/null || die "$ref does not exist in $repo"
    carries "$repo" "$ref"
    if [[ $what == "#$n's init.md"* ]]; then
        echo "claim: $branch carries $what"
        exit 0
    fi
    pusher=$(git -C "$repo" log -1 --format='%an <%ae>, %cs' "$ref")
    if [[ $other == "$n" ]]; then
        echo "claim: $branch already exists on origin — pushed by $pusher; it carries $what${other_line:+ ($other_line)}"
        echo "claim: $branch carries only #$n's own archived dossier — #$n has already been through close; finish or verify it with close in its container, and retitle #$n only for an issue reopened after its merge"
    elif [[ -n $other ]]; then
        echo "claim: $branch already exists on origin — pushed by $pusher; it carries $what${other_line:+ ($other_line)}"
        echo "claim: #$n's title derives the same branch name as #$other's — retitle #$n (the first five words after a leading [tag] and the stop words are the name: branch-name.sh), or wait for #$other to close"
    elif merged_and_left "$repo" "$ref"; then
        if bare_branch "$repo" "$ref"; then
            echo "claim: $branch already exists on origin — pushed by $pusher; it is bare — cut from $base with nothing of its own, and $base holds #$n's archive"
        else
            echo "claim: $branch already exists on origin — pushed by $pusher; it was merged into $base and left behind"
        fi
        echo "claim: #$n has already been through close — delete $branch on origin (close normally does), and retitle #$n only for an issue reopened after its merge"
    else
        echo "claim: $branch already exists on origin — pushed by $pusher; it carries no dossier"
        echo "claim: $branch is not a pipeline branch — rename or delete it on origin, or retitle #$n"
    fi
    exit 2
fi

if [[ $mode == stash-live ]]; then
    n=${1:?usage: claim.sh --stash-live <issue> <branch> <repo>}
    branch=${2:?usage: claim.sh --stash-live <issue> <branch> <repo>}
    repo=${3:?usage: claim.sh --stash-live <issue> <branch> <repo>}
    ref="origin/$branch"
    git -C "$repo" rev-parse -q --verify "$ref^{commit}" >/dev/null || die "$ref does not exist in $repo"
    parks=$(count_lines "$repo" "$ref" ".codeo/$n/close.md" "$park_re")
    resumes=$(count_lines "$repo" "$ref" ".codeo/$n/init.md" "$resume_re")
    if ((parks == 0)); then
        echo "claim: #$n has no stash"
        exit 3
    fi
    park_kind "$repo" "$ref" ".codeo/$n/close.md"
    if ((parks > resumes)); then
        if [[ $kind == abandon ]]; then
            round=$(sed -E 's/^### Round ([0-9]+) .*/\1/' <<<"$park_last")
            echo "claim: #$n was abandoned on $(park_date "$repo" "$ref" ".codeo/$n/close.md" "$abandon_re") (close.md round $round)"
            exit 4
        fi
        echo "claim: #$n's stash is live"
        exit 0
    fi
    echo "claim: #$n's $kind was already resumed — $(last_resume "$repo" "$ref" ".codeo/$n/init.md")"
    exit 3
fi

if [[ $mode == resume-line ]]; then
    n=${1:?usage: claim.sh --resume-line <issue> <branch> <repo> [<login>]}
    branch=${2:?usage: claim.sh --resume-line <issue> <branch> <repo> [<login>]}
    repo=${3:?usage: claim.sh --resume-line <issue> <branch> <repo> [<login>]}
    login=${4:-}
    ref="origin/$branch"
    git -C "$repo" rev-parse -q --verify "$ref^{commit}" >/dev/null || die "$ref does not exist in $repo"
    parks=$(count_lines "$repo" "$ref" ".codeo/$n/close.md" "$park_re")
    resumes=$(count_lines "$repo" "$ref" ".codeo/$n/init.md" "$resume_re")
    if ((parks > resumes)); then
        park_kind "$repo" "$ref" ".codeo/$n/close.md"
        after="the $kind of $(park_date "$repo" "$ref" ".codeo/$n/close.md" "$kind_re")"
    else
        after="a lost container"
    fi
    echo "- $(date -u +%F) — resumed: by ${login:-no login} after $after"
    exit 0
fi

if [[ $mode == resume ]]; then
    n=${1:?usage: claim.sh --resume <issue> <branch> <worktree> <seen-sha>}
    branch=${2:?usage: claim.sh --resume <issue> <branch> <worktree> <seen-sha>}
    worktree=${3:?usage: claim.sh --resume <issue> <branch> <worktree> <seen-sha>}
    seen=${4:?usage: claim.sh --resume <issue> <branch> <worktree> <seen-sha>}
    expect=$seen
else
    n=${1:?usage: claim.sh <issue> <branch> <worktree>}
    branch=${2:?usage: claim.sh <issue> <branch> <worktree>}
    worktree=${3:?usage: claim.sh <issue> <branch> <worktree>}
    expect=
fi

errfile=$(mktemp)
trap 'rm -f "$errfile"' EXIT

# Create-only expects nothing at the ref; a resume expects the tip it read.
if git -C "$worktree" push -q --force-with-lease="refs/heads/$branch:$expect" -u origin "$branch" 2>"$errfile"; then
    if [[ $mode == resume ]]; then echo "claim: #$n resumed $branch"; else echo "claim: #$n claimed $branch"; fi
    exit 0
fi

# Only git's own wording tells a refusal because the ref exists from a push that never got there.
if ! grep -Eq '\[rejected\]|stale info|fetch first' "$errfile"; then
    cat "$errfile" >&2
    exit 1
fi

git -C "$worktree" fetch -q origin \
    "+refs/heads/$branch:refs/remotes/origin/$branch" "+refs/heads/$base:refs/remotes/origin/$base" 2>/dev/null ||
    die "$branch already exists on origin, and fetching it to say who pushed it failed"
pusher=$(git -C "$worktree" log -1 --format='%an <%ae>, %cs' "origin/$branch")

if [[ $mode == resume ]]; then
    short=$(git -C "$worktree" rev-parse --short "$seen")
    init_path=".codeo/$n/init.md"
    if (($(count_lines "$worktree" "origin/$branch" "$init_path" "$resume_re") > $(count_lines "$worktree" "$seen" "$init_path" "$resume_re"))); then
        echo "claim: $branch was resumed since $short — $(last_resume "$worktree" "origin/$branch" "$init_path")" >&2
    else
        echo "claim: $branch moved since $short — pushed by $pusher" >&2
    fi
    exit 2
fi

carries "$worktree" "origin/$branch"
echo "claim: $branch already exists on origin — pushed by $pusher; it carries $what" >&2
exit 2
