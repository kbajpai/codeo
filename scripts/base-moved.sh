#!/usr/bin/env bash
# Names the files this branch changed that the base branch has changed since QC graded it, so
# close merges a moved base only when that merge can touch what was graded. The base branch is the
# config's baseBranch; the graded commit is the last "Graded base: <sha>" line of the dossier's qc.md.
#
#   base-moved.sh <N>
#       Run from the repo root. Reads the last line of .codeo/<N>/qc.md (else .codeo/done/<N>/qc.md)
#       that is "Graded base: <sha>", as a bare line, a list item ("- Graded base: <sha>") or with the sha in
#       backticks. The comparison starts at <from> = git merge-base <sha> HEAD (<sha> itself when there is
#       none), the base commit the graded tree contains, so a <sha> newer than what was graded hides nothing.
#       Prints, one per line, every path origin/<base> changed since <from>
#       that this branch also changed (git diff --no-renames --name-only <from> origin/<base>, intersected with
#       git diff --no-renames --name-only origin/<base>...HEAD), sorted bytewise.
#       Exit 0: nothing printed. Exit 3: paths printed. Exit 4: qc.md has no "Graded base:" line (a
#       round written before this script); prints "base-moved: no Graded base line in <file>" to stderr.
#       Exit 1: anything else it cannot judge (usage, no qc.md, <sha> is not a commit, the fetch
#       failed): one "base-moved: ..." line to stderr.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

if (($# != 1)) || [[ ! $1 =~ ^[0-9]+$ ]]; then
    echo "usage: base-moved.sh <N>" >&2
    exit 1
fi
n=$1

fail() { echo "base-moved: $*" >&2; exit 1; }

base=$(codeo_base_branch)

file=$CODEO_STATE_DIR/$n/qc.md
[[ -f $file ]] || file=$CODEO_STATE_DIR/done/$n/qc.md
[[ -f $file ]] || fail "no qc.md for issue $n"

sha=$(grep -E '^[[:space:]]*(- )?Graded base:' "$file" | tail -n 1 | sed -n 's/^[^:]*:[[:space:]]*\([^[:space:]]*\).*$/\1/p' | tr -d '`' || true)
if [[ -z $sha ]]; then
    echo "base-moved: no Graded base line in $file" >&2
    exit 4
fi

git fetch -q origin "$base" 2> /dev/null || fail "could not fetch origin/$base"
[[ $sha != -* ]] && git rev-parse --verify --quiet "${sha}^{commit}" > /dev/null 2>&1 || fail "$sha is not a commit"

from=$(git merge-base "$sha" HEAD 2> /dev/null) || from=$sha
moved=$(git diff --no-renames --name-only "$from" "origin/$base" 2> /dev/null | LC_ALL=C sort) || fail "cannot diff $sha against origin/$base"
ours=$(git diff --no-renames --name-only "origin/$base...HEAD" 2> /dev/null | LC_ALL=C sort) || fail "cannot diff origin/$base against HEAD"

# Byte order on both sides: sort follows the locale, and some comm (uutils) always compares bytes.
both=$(LC_ALL=C comm -12 <(printf '%s\n' "$moved") <(printf '%s\n' "$ours") | sed '/^$/d')
if [[ -n $both ]]; then
    printf '%s\n' "$both"
    exit 3
fi
exit 0
