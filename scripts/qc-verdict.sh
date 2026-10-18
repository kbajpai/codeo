#!/usr/bin/env bash
# Reads a pull request's qc verdict from the archived dossiers its diff adds or changes, and fails
# closed on a live dossier the head still carries. This is the qc-verdict required check; its
# verdict-line pattern is transcribed here, not re-derived.
#
#   qc-verdict.sh <base> <head>
#       Run from the repo root; <base>/<head> are any commit-ish (the merge base of the two is
#       used, so a required check can pass the PR's head and its target branch tip directly).
#       Prints one "qc-verdict: ..." line per judged dossier on stdout, one per archived
#       done/<N>/ the diff touches without adding or changing its qc.md ("not judged"), or
#       "qc-verdict: no archived dossier in this PR" when the diff adds, modifies or renames
#       nothing under a numeric done/<N>/ -- a PR that only deletes there reports the same -- and
#       exits 0.
#       Every failure reason goes to stderr, naming the file; every file is checked and every
#       failure reported before the non-zero exit.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"
# state_rel is a git pathspec relative to the repo root; from a subdirectory it would match nothing.
[[ -n $CODEO_PROJECT_ROOT ]] || codeo_die "not inside a git repository"
cd "$CODEO_PROJECT_ROOT"

# The state directory as git sees it, and as a regex: dossier paths are read from git, never from
# the filesystem.
state_rel=${CODEO_STATE_DIR#"$CODEO_PROJECT_ROOT"/}
state_re=${state_rel//./\\.}

if [[ $# -ne 2 ]]; then
    echo "usage: qc-verdict.sh <base> <head>" >&2
    exit 1
fi

base_ref=$1
head_ref=$2
base=$(git merge-base "$base_ref" "$head_ref")

failures=0
fail() {
    echo "qc-verdict: $*" >&2
    failures=$((failures + 1))
}

# A live dossier means close has not archived it yet, or a review send-back moved it
# back out of done/ — the base branch never carries one, so its mere presence on the head fails closed,
# whether or not anything inside it changed in this diff.
while IFS= read -r path; do
    [[ -n $path ]] || continue
    fail "live dossier $path: close has not archived it, or review rework is in flight"
done < <(git ls-tree -d --name-only "$head_ref" "$state_rel/" 2>/dev/null | grep -E "^$state_re/[0-9]+\$" || true)

# Only dossiers this diff adds or changes are judged: an archive already on the base is history,
# and some predate the round-heading convention entirely.
# ':(glob)' stops '*' at '/' — git's default pathspec would also match done/50/sub/qc.md — and
# the grep keeps the numeric rule the live-dossier check above applies.
judged=$(git diff --name-only --diff-filter=AMR "$base" "$head_ref" -- ":(glob)$state_rel/done/*/qc.md" \
    | grep -E "^$state_re/done/[0-9]+/qc\.md\$" || true)

while IFS= read -r path; do
    [[ -n $path ]] || continue
    content=$(git show "$head_ref:$path")

    # The '## Outcome' section, up to (not including) the next top-level '## ' heading. A line
    # starting '### ' (three '#') does not match '^## ' (two '#' then a space), so the round
    # headings inside stay in scope.
    outcome=$(awk '
        /^## Outcome/ { in_outcome = 1; next }
        in_outcome && /^## / { exit }
        in_outcome { print }
    ' <<<"$content")

    round_headings=$(grep -nE '^### Round [0-9]+' <<<"$outcome" || true)
    if [[ -z $round_headings ]]; then
        fail "$path: no ### Round in ## Outcome"
        continue
    fi

    # Only the last round is judged; everything from its heading to the end of '## Outcome'
    # (already bounded above) belongs to it.
    last_heading=$(tail -n1 <<<"$round_headings")
    last_line=${last_heading%%:*}
    round_num=$(sed -E 's/^### Round ([0-9]+).*/\1/' <<<"${last_heading#*:}")
    round=$(tail -n +"$last_line" <<<"$outcome")

    # The round's decision is the bold span qc writes it in — "**Verdict: …**" or
    # "**Routing: …**", at a line's start or mid-line. The label must sit inside the bold: text
    # like "The verdict is **clear**" or "**Verdict:** clear" is not a decision span (the latter
    # reads as the empty span "**Verdict:**", which fails closed as not clear). Matched on the
    # raw text, so an unbolded mention ("Round 1's verdict: clear") is not a decision. The last
    # span in the round decides. Lines are joined first, so a span wrapped over two lines is
    # still one span.
    spans=$(tr '\n' ' ' <<<"$round" \
        | grep -o -i -E '\*\*(verdict|routing)( then)?:[^*]*\*\*' \
        || true)
    if [[ -z $spans ]]; then
        fail "$path: no bold Verdict/Routing span in round $round_num"
        continue
    fi
    decision=$(tail -n1 <<<"$spans")
    # The span's text after the label, with backticks and underscores gone. "clear" must close
    # it — the word, then the end of the span or "." "," ";" ":" "—" "–" — so "clearly", "clear
    # once …", "not clear" and "back to …" all fail.
    text=$(sed -E 's/\*\*//g; s/[`_]//g; s/^[[:space:]]*(verdict|routing)( then)?:[[:space:]]*//I' <<<"$decision")
    if ! grep -q -i -E '^clear[[:space:]]*(\.|,|;|:|—|–|$)' <<<"$text"; then
        fail "$path: round $round_num is not clear: $decision"
        continue
    fi

    echo "qc-verdict: $path: round $round_num clear"
done <<<"$judged"

# Every numeric archive the diff adds, modifies or renames a file under — same filter as
# `judged`, so a PR that only deletes under done/ reports nothing here either. An archive that is
# touched but whose qc.md is not in the diff is named, not judged: reporting "no archived
# dossier" for it read as if nothing were touched at all. Not failing
# here is by design.
touched=$(git diff --name-only --diff-filter=AMR "$base" "$head_ref" -- "$state_rel/done/" \
    | sed -nE "s#^$state_re/done/([0-9]+)/.*#\\1#p" | sort -un)
for n in $touched; do
    grep -qxF "$state_rel/done/$n/qc.md" <<<"$judged" && continue
    if git cat-file -e "$head_ref:$state_rel/done/$n/qc.md" 2>/dev/null; then
        echo "qc-verdict: $state_rel/done/$n touched, qc.md unchanged by this PR: not judged"
    else
        echo "qc-verdict: $state_rel/done/$n touched, qc.md absent at head: not judged"
    fi
done

if [[ -z $touched ]] && ((!failures)); then
    echo "qc-verdict: no archived dossier in this PR"
fi

if ((failures)); then
    exit 1
fi
