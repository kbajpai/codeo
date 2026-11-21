#!/usr/bin/env bash
# Checks that every page that runs overlap.sh says a failed run is a stop to report, never "no
# overlap", and that the pair runs quote a skipped-workflow warning and carry on.
#
#   overlap-stop.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

failures=0
fail() {
    echo "FAIL: $1"
    failures=$((failures + 1))
}

STOP='A non-zero exit, with an `overlap: cannot diff …` or `overlap: cannot resolve …` line, is a stop to report, never "no overlap".'
WARN='An `overlap: skipping #<M>'\''s changed paths` warning with exit 0 is quoted to the engineer, and the step carries on with that workflow'\''s footprint alone.'

# Joins a file's lines with single spaces, so a sentence wrapped across lines still matches.
flat() { tr '\n' ' ' <"$1" | sed -E 's/ +/ /g'; }

# $1 file, $2 fixed string: how many times it occurs in the flattened file.
count() { { flat "$1" | grep -oF -- "$2" || true; } | wc -l | tr -d ' '; }

# file, then how many times STOP and WARN must occur.
while read -r file want_stop want_warn; do
    path="${OVERLAP_ROOT:-$plugin_root}/$file"
    got=$(count "$path" "$STOP")
    [[ "$got" == "$want_stop" ]] || fail "$file: STOP wanted $want_stop, found $got"
    got=$(count "$path" "$WARN")
    [[ "$got" == "$want_warn" ]] || fail "$file: WARN wanted $want_warn, found $got"
done <<'TABLE'
skills/plan/SKILL.md 2 1
skills/implement/SKILL.md 1 1
skills/qc/SKILL.md 2 1
skills/close/SKILL.md 1 1
docs/handoff.md 1 1
TABLE

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
