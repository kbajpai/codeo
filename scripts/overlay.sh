#!/usr/bin/env bash
# Prints one section of a project's skill overlay, $CODEO_STATE_DIR/overlays/<skill>.md.
#
#   overlay.sh <skill> <point>
#       0  the section body on stdout (lines after the "## <point>" heading up to the next "## "
#          heading or end of file, surrounding blank lines trimmed, CRLF normalised)
#       3  the file or the section is absent or empty; nothing printed, the skill uses its default
#       2  <skill>/<point> is not a row of lib/extension-points.tsv; one "codeo:" line, so a typo
#          in a skill fails at the call instead of silently falling back to the default
#       4  the section appears twice; one "codeo:" line naming the line numbers
#
# CODEO_EXTENSION_POINTS overrides the registry path. It exists for the tests only.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

if [[ $# -ne 2 ]]; then
    echo "codeo: usage: overlay.sh <skill> <point>" >&2
    exit 2
fi
skill=$1
point=$2
registry=${CODEO_EXTENSION_POINTS:-$CODEO_PLUGIN_ROOT/lib/extension-points.tsv}

# An unreadable registry is an environment fault, not an unknown point: exit 2 is reserved for the
# latter, and no awk text may leak.
[[ -f "$registry" && -r "$registry" ]] || codeo_die "extension-point registry not readable: $registry"

# Both comparisons go through ENVIRON, not awk -v: -v interprets backslash escapes, so a point
# containing one would not match itself. Equality, not a regex, so "a.b*c" means exactly that.
if ! SKILL=$skill POINT=$point awk -F'\t' '$1 == ENVIRON["SKILL"] && $2 == ENVIRON["POINT"] { found = 1 } END { exit !found }' "$registry"; then
    echo "codeo: unknown extension point $skill/$point (see lib/extension-points.tsv)" >&2
    exit 2
fi

[[ -n "$CODEO_PROJECT_ROOT" ]] || codeo_die "not inside a git repository"
file="$CODEO_STATE_DIR/overlays/$skill.md"
[[ -e "$file" ]] || exit 3
# Exit 2 belongs to the registry check, so a file that exists but cannot be read must not reach awk.
[[ -f "$file" && -r "$file" ]] || codeo_die "$file is not readable"

# Sections are delimited by "## " headings only, so a "## " line inside a fenced code block ends the
# section too; an overlay that needs one in a code sample must indent it.
# One pass: record where each matching heading is, keep only the first section's lines, and decide
# at the end so a duplicate prints nothing.
rc=0
POINT=$point FILE=$file awk '
    BEGIN { want = "## " ENVIRON["POINT"]; inside = 0; n = 0 }
    {
        sub(/\r$/, "")
        head = $0
        sub(/[ \t]+$/, "", head)
        if (head == want) {
            hits++
            lines[hits] = NR
            inside = (hits == 1)
            next
        }
        if (substr($0, 1, 3) == "## ") { inside = 0; next }
        if (inside) body[++n] = $0
    }
    END {
        if (hits > 1) {
            printf "codeo: %s: duplicate section \"%s\" at lines %s\n", ENVIRON["FILE"], want, lines[1] " and " lines[2] > "/dev/stderr"
            exit 4
        }
        first = 1
        while (first <= n && body[first] ~ /^[ \t]*$/) first++
        last = n
        while (last >= first && body[last] ~ /^[ \t]*$/) last--
        if (first > last) exit 3
        for (i = first; i <= last; i++) print body[i]
    }
' "$file" || rc=$?
exit "$rc"
