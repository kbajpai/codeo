#!/usr/bin/env bash
# Checks that skills/init/SKILL.md carries the wording its dossier depends on: step 7 drafts
# init.md in the shape docs/dossier.md gives, ## Questions included, so dossier-check.sh's
# sections check finds every section in order.
#
#   init-skill.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# INIT_SKILL points the checks at another copy (an older revision, to see a case fail).
skill=${INIT_SKILL:-"$plugin_root/skills/init/SKILL.md"}

failures=0
fail() {
    echo "FAIL: $1"
    failures=$((failures + 1))
}

# Prints step $1's text: from its "<n>. **" line up to the next step, section heading or comment.
step() {
    awk -v n="$1" '
        $0 ~ "^" n "\\. \\*\\*" { f = 1; print; next }
        f && (/^[0-9]+\. \*\*/ || /^## / || /^<!-- [a-z]/) { exit }
        f { print }' "$skill"
}

# $1 case, $2 step number, $3 fixed string the step must contain.
step_contains() {
    local text
    text=$(step "$2")
    [[ -n $text ]] || { fail "$1 — no step $2 in the skill"; return; }
    grep -qF -- "$3" <<<"$text" || fail "$1 — step $2 has no [$3]"
}

# Step 7: the draft carries every section, in dossier-check's order, Questions included.
step_contains "the draft names the section order" 7 '`## Where this stands`, `## Questions`, `## Outcome`, `## Log`'
step_contains "an empty Questions section says None." 7 '`None.`'
step_contains "Notes is optional" 7 '`## Notes` only when there is something to keep'

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
