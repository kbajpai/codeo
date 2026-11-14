#!/usr/bin/env bash
# Every skill ends with the closing block docs/handoff.md defines, so each SKILL.md must cite it,
# and the section it cites must exist with the three labels the block is made of.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
status=0
fail() { echo "FAIL: $1" >&2; status=1; }

doc="$root/docs/handoff.md"
grep -q '^## Closing block$' "$doc" || fail "docs/handoff.md has no '## Closing block' section"
block=$(sed -n '/^## Closing block$/,/^## Spinning out subagents$/p' "$doc")
for label in '**Done:**' '**Next goal:**' '**Steps:**'; do
    grep -qF -- "$label" <<<"$block" || fail "the Closing block section lacks $label"
done

for skill in "$root"/skills/*/SKILL.md; do
    name=$(basename "$(dirname "$skill")")
    grep -qF 'docs/handoff.md → Closing block' "$skill" ||
        fail "skills/$name/SKILL.md does not cite docs/handoff.md → Closing block"
    grep -q '^- Hands off to nobody\. .*adds nothing\.$' "$root/docs/skills.md" &&
        fail "docs/skills.md still says $name adds nothing after its output"
done

[ "$status" -eq 0 ] && echo "all cases passed"
exit "$status"
