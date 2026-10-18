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

# Nothing was reworded or dropped: the rule texts are pinned by a committed hash. The stream that is
# hashed has one line per rule in file order, "<skill>-NN<TAB><rule text>", with the "[ID] " prefix
# removed from the text and a wrapped bullet's continuation lines joined by single spaces. Pinning
# the ID beside its text also catches a rule moved under another ID.
fixture="$repo/tests/fixtures/skills-inventory.rules.sha256"

rules_stream() {
    awk '
        function flush() { if (id != "") printf "%s\t%s\n", id, txt; id = "" }
        /^## / { flush(); in_s = ($0 ~ /^## (issue|init|plan|implement|qc|close|triage)$/); next }
        in_s && /^- \[[a-z]+-[0-9]+\] / {
            flush(); id = $2; gsub(/[\[\]]/, "", id)
            txt = $0; sub(/^- \[[a-z]+-[0-9]+\] /, "", txt); next
        }
        in_s && id != "" && /^[[:space:]]+[^[:space:]]/ { l = $0; sub(/^[[:space:]]+/, "", l); txt = txt " " l; next }
        { flush() }
        END { flush() }
    ' "$1"
}
rules_hash() { rules_stream "$1" | sha256sum | cut -d' ' -f1; }

if [[ "${1:-}" == "--update" ]]; then
    mkdir -p "$(dirname "$fixture")"
    echo "$(rules_hash "$inv")" >"$fixture"
    echo "rewrote $fixture"
    exit 0
fi

# Cases proving the pin discriminates, run over scratch copies.
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
base=$(rules_hash "$inv")
[[ "$base" == "$(rules_hash "$inv")" ]] || check_fail "hash of an untouched file is not stable"
sed 's/^\(- \[issue-01\] .*\)$/\1 extra/' "$inv" >"$scratch/reworded.md"
[[ "$(rules_hash "$scratch/reworded.md")" != "$base" ]] || check_fail "a reworded bullet does not change the hash"
sed 's/^- \[issue-01\] /- [issue-02] /; t; s/^- \[issue-02\] /- [issue-01] /' "$inv" >"$scratch/swapped.md"
[[ "$(rules_hash "$scratch/swapped.md")" != "$base" ]] || check_fail "a swapped ID does not change the hash"
sed '0,/^- \[qc-13\] .*/{//d}' "$inv" >"$scratch/dropped.md"
[[ "$(rules_hash "$scratch/dropped.md")" != "$base" ]] || check_fail "a dropped rule does not change the hash"
cp "$inv" "$scratch/same.md"
[[ "$(rules_hash "$scratch/same.md")" == "$base" ]] || check_fail "an untouched copy does not match"

if [[ ! -f "$fixture" ]]; then
    check_fail "tests/fixtures/skills-inventory.rules.sha256 is missing; run: bash tests/inventory.test.sh --update"
elif [[ "$(tr -d '[:space:]' <"$fixture")" != "$base" ]]; then
    check_fail "the rule texts differ from the pinned hash. If the change is deliberate, run: bash tests/inventory.test.sh --update, commit the fixture, and explain the rule change in the commit message"
fi

[[ "$fail" -eq 0 ]] || exit 1
echo "all cases passed"
