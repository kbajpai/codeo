#!/usr/bin/env bash
# Checks the shape of docs/skills-inventory.md: every rule bullet under the seven skill headings
# carries a "[<skill>-NN]" ID that the skills lint (tests/skills.test.sh, check 5) can track, and
# giving the IDs reworded nothing. It lives apart from the lint because the lint checks skills
# against the inventory, while this checks the inventory itself.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
inv="$repo/docs/skills-inventory.md"
fail=0

check_fail() { printf 'FAIL %s\n' "$1"; fail=1; }

declare -A want=([issue]=7 [init]=9 [plan]=8 [implement]=9 [qc]=13 [close]=13 [triage]=9)

for skill in issue init plan implement qc close triage; do
    # The bullets of one "## <skill>" section: a section ends at the next "## " heading.
    bullets=$(awk -v s="$skill" '/^## /{in_s = ($0 == "## " s); next} in_s && /^- /{print}' "$inv")
    n=0
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        n=$((n + 1))
        expected=$(printf '%s-%02d' "$skill" "$n")
        # Consecutive from 01 in file order also makes the IDs unique.
        case "$line" in
            "- [$expected] "*) ;;
            *) check_fail "$skill bullet $n should start with '- [$expected] ': ${line:0:60}" ;;
        esac
    done <<<"$bullets"
    [[ "$n" -eq "${want[$skill]}" ]] || check_fail "$skill has $n rules, expected ${want[$skill]}"
done

# Nothing was reworded: with the ID prefixes stripped, the file equals the committed one. Where
# the file is untracked there is nothing to compare against.
strip_ids() { sed -E 's/^- \[[a-z]+-[0-9]+\] /- /'; }
if git -C "$repo" ls-files --error-unmatch docs/skills-inventory.md >/dev/null 2>&1 &&
    head_copy=$(git -C "$repo" show HEAD:docs/skills-inventory.md 2>/dev/null); then
    if ! diff <(strip_ids <<<"$head_copy") <(strip_ids <"$inv") >/dev/null; then
        check_fail "rule text differs from HEAD once the IDs are stripped"
    fi
else
    echo "skipped text comparison (docs/skills-inventory.md is not tracked at HEAD)"
fi

[[ "$fail" -eq 0 ]] || exit 1
echo "all cases passed"
