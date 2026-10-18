#!/usr/bin/env bash
# Merges origin/<base branch> into the current branch, so every implement and qc round starts from
# what the base branch holds now and a conflict surfaces in the round that can fix it, not at close.
# The base branch is the config's baseBranch.
#
# A merge, never a rebase: a branch with an open PR is already pushed, and close never
# force-pushes, so history here is only ever added to. Callers: every implement round and every qc
# round (with --abort-on-conflict, since qc resolves nothing). close keeps its own merge-tree
# check as the last line.
#
#   sync-main.sh [--abort-on-conflict]
#       Run from the repo root. Exit 0: already contains origin/<base>, or merged cleanly (the
#       paths changed on both sides since the merge base are listed, to re-check). Exit 1: the
#       tree has tracked changes. Exit 2: conflict — one stderr line per file; with the flag the
#       merge is aborted and the tree is as before, without it the merge is left for resolution.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

abort=0
case ${1:-} in
    "") ;;
    --abort-on-conflict) abort=1 ;;
    *) echo "usage: sync-main.sh [--abort-on-conflict]" >&2; exit 1 ;;
esac
(($# <= 1)) || { echo "usage: sync-main.sh [--abort-on-conflict]" >&2; exit 1; }

# A bare assignment, so a failing config read (which already printed its one line) ends this script.
base=$(codeo_base_branch)

# Tracked changes only: git merge itself refuses just when they would be overwritten, and an
# untracked scratch file must not block a round.
if [[ -n $(git status --porcelain --untracked-files=no) ]]; then
    echo "sync-main: the tree is not clean — commit or stash first" >&2
    exit 1
fi

git fetch -q origin "$base"

if git merge-base --is-ancestor "origin/$base" HEAD; then
    echo "sync-main: the branch already contains origin/$base"
    exit 0
fi

before=$(git rev-parse HEAD)
merge_base=$(git merge-base HEAD "origin/$base")
count=$(git rev-list --count "$before..origin/$base")

if git merge --no-edit "origin/$base" > /dev/null 2>&1; then
    echo "sync-main: merged origin/$base ($count commit(s))"
    comm -12 <(git diff --name-only "$merge_base" "$before" | sort) <(git diff --name-only "$merge_base" "origin/$base" | sort) |
        while IFS= read -r path; do echo "sync-main: also changed on $base: $path"; done
    exit 0
fi

# A merge that fails without conflicts (say, an untracked file in the way) has nothing to resolve.
conflicts=$(git diff --name-only --diff-filter=U)
if [[ -z $conflicts ]]; then
    git merge --abort 2> /dev/null || true
    echo "sync-main: the merge failed without a conflict; the tree is as before" >&2
    exit 1
fi
while IFS= read -r path; do echo "sync-main: conflict: $path" >&2; done <<< "$conflicts"
if ((abort)); then
    git merge --abort
else
    echo "sync-main: resolve each file against both changes' intent, then git commit" >&2
fi
exit 2
