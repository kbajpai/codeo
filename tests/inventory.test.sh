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

for skill in issue init plan implement qc close triage cleanup; do
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
    [[ "$n" -gt 0 ]] || check_fail "$skill has no rules"
done

# Nothing was reworded, dropped or added: every rule text is pinned by a committed hash, one line per
# rule, so two branches that change different rules touch different lines and merge cleanly. The
# stream that is hashed has one line per rule in file order, "<skill>-NN<TAB><rule text>", with the
# "[ID] " prefix removed from the text and a wrapped bullet's continuation lines joined by single
# spaces. The pin is "<skill>-NN<TAB><sha256 of the rule text>", where the text is hashed exactly as
# the stream carries it, WITHOUT the line's trailing newline. Pinning the ID beside its text also
# catches a rule moved under another ID, and the pin lists every ID, so a dropped or added rule
# shows as a missing or extra line. Only --update writes the fixture.
fixture="$repo/tests/fixtures/skills-inventory.rules.sha256"

rules_stream() {
    awk '
        function flush() { if (id != "") printf "%s\t%s\n", id, txt; id = "" }
        /^## / { flush(); in_s = ($0 ~ /^## (issue|init|plan|implement|qc|close|triage|cleanup)$/); next }
        in_s && /^- \[[a-z]+-[0-9]+\] / {
            flush(); id = $2; gsub(/[\[\]]/, "", id)
            txt = $0; sub(/^- \[[a-z]+-[0-9]+\] /, "", txt); next
        }
        in_s && id != "" && /^[[:space:]]+[^[:space:]]/ { l = $0; sub(/^[[:space:]]+/, "", l); txt = txt " " l; next }
        { flush() }
        END { flush() }
    ' "$1"
}

rules_pin() {
    local id text
    rules_stream "$1" | while IFS=$'\t' read -r id text; do
        printf '%s\t%s\n' "$id" "$(printf '%s' "$text" | sha256sum | cut -d' ' -f1)"
    done
}

# unseparated <page>: one line per rule bullet that directly follows another rule's line.
unseparated() {
    awk '
        /^## / { in_s = ($0 ~ /^## (issue|init|plan|implement|qc|close|triage|cleanup)$/); prev = $0; next }
        in_s && /^- \[[a-z]+-[0-9]+\] / && prev != "" && prev !~ /^## / {
            id = $2; gsub(/[\[\]]/, "", id)
            printf "rule %s is not separated from the rule before it by a blank line\n", id
        }
        { prev = $0 }
    ' "$1"
}

# pin_diff <pinned> <current>: one line per differing rule, in the order the rules appear.
pin_diff() {
    awk -F'\t' '
        /^$/ { next }
        NR == FNR { p[$1] = $2; po[++n] = $1; next }
        { c[$1] = $2; co[++m] = $1 }
        END {
            for (i = 1; i <= m; i++) {
                id = co[i]
                if (!(id in p)) printf "rule %s is not pinned\n", id
                else if (p[id] != c[id]) printf "rule %s differs from the pin\n", id
            }
            for (i = 1; i <= n; i++) if (!(po[i] in c)) printf "pinned rule %s is gone\n", po[i]
        }
    ' "$1" "$2"
}

if [[ "${1:-}" == "--update" ]]; then
    mkdir -p "$(dirname "$fixture")"
    rules_pin "$inv" | sed G >"$fixture"
    echo "rewrote $fixture"
    exit 0
fi

# Cases proving the pin discriminates, run over scratch copies; they assert on the printed lines.
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
rules_pin "$inv" >"$scratch/base.pin"

expect_diff() { # <name> <want lines> <copy>
    local got
    rules_pin "$3" >"$scratch/got.pin"
    got=$(pin_diff "$scratch/base.pin" "$scratch/got.pin")
    [[ "$got" == "$2" ]] || check_fail "$1: expected '${2//$'\n'/ | }' but got '${got//$'\n'/ | }'"
}

sed 's/^\(- \[issue-01\] .*\)$/\1 extra/' "$inv" >"$scratch/reworded.md"
expect_diff "a reworded bullet" "rule issue-01 differs from the pin" "$scratch/reworded.md"
sed 's/^- \[issue-01\] /- [issue-02] /; t; s/^- \[issue-02\] /- [issue-01] /' "$inv" >"$scratch/swapped.md"
expect_diff "swapped IDs" $'rule issue-02 differs from the pin\nrule issue-01 differs from the pin' "$scratch/swapped.md"
sed '0,/^- \[qc-13\] .*/{//d}' "$inv" >"$scratch/dropped.md"
expect_diff "a dropped rule" "pinned rule qc-13 is gone" "$scratch/dropped.md"
cp "$inv" "$scratch/same.md"
expect_diff "an untouched copy" "" "$scratch/same.md"
rules_pin "$scratch/same.md" | cmp -s - "$scratch/base.pin" || check_fail "an untouched copy does not give an identical pin"

# Rule bullets are separated by one blank line, so edits to neighbouring rules merge; the pin reader
# ignores blank lines.
sed -z 's/\n\n- \[plan-02\] /\n- [plan-02] /' "$inv" >"$scratch/adjacent.md"
got=$(unseparated "$scratch/adjacent.md")
[[ "$got" == "rule plan-02 is not separated from the rule before it by a blank line" ]] || check_fail "adjacent bullets: expected the separation FAIL for plan-02 but got - ${got//$'\n'/ | }"
while IFS= read -r l; do [[ -z "$l" ]] || check_fail "$l"; done < <(unseparated "$inv")
sed -z 's/\n\n- \[issue-03\] /\n- [issue-03] /' "$inv" >"$scratch/wrapped.md"
got=$(unseparated "$scratch/wrapped.md")
[[ "$got" == "rule issue-03 is not separated from the rule before it by a blank line" ]] || check_fail "after a wrapped bullet: expected the separation FAIL for issue-03 but got - ${got//$'\n'/ | }"
sed G "$scratch/base.pin" >"$scratch/blanks.pin"
[[ -z "$(pin_diff "$scratch/base.pin" "$scratch/blanks.pin")" && -z "$(pin_diff "$scratch/blanks.pin" "$scratch/base.pin")" ]] || check_fail "a pin with blank lines does not read the same"
sed -z 's/\n\n## close/\n\n- [qc-99] x\n\n## close/' "$inv" >"$scratch/added.md"
expect_diff "an_added_rule_is_not_pinned" "rule qc-99 is not pinned" "$scratch/added.md"

if [[ ! -f "$fixture" ]]; then
    check_fail "tests/fixtures/skills-inventory.rules.sha256 is missing; run: bash tests/inventory.test.sh --update"
else
    rules_pin "$inv" >"$scratch/now.pin"
    diffs=$(pin_diff "$fixture" "$scratch/now.pin")
    if [[ -n "$diffs" ]]; then
        while IFS= read -r l; do check_fail "$l"; done <<<"$diffs"
        check_fail "the rule texts differ from the pin. If the change is deliberate, run: bash tests/inventory.test.sh --update, commit the fixture, and explain the rule change in the commit message"
    fi
fi

[[ "$fail" -eq 0 ]] || exit 1
echo "all cases passed"
