#!/usr/bin/env bash
# Exercises tools/changelog.sh in scratch directories (a copy of the script beside a CHANGELOG.md and
# a changelog.d/ built from tests/fixtures/changelog/) and one scratch git repository for the merge.
#
#   changelog.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fx="$plugin_root/tests/fixtures/changelog"

export GIT_AUTHOR_NAME="Changelog Test" GIT_AUTHOR_EMAIL="changelog-test@example.com"
export GIT_COMMITTER_NAME="Changelog Test" GIT_COMMITTER_EMAIL="changelog-test@example.com"

scratch_root=$(mktemp -d)
cleanup() { rm -rf "$scratch_root"; }
trap cleanup EXIT
export HOME="$scratch_root/home"
mkdir -p "$HOME"

failures=0
case_desc=
assert_eq() {
    local label=$1 want=$2 got=$3
    if [[ $want != "$got" ]]; then
        echo "FAIL: $case_desc — $label: want [$want] got [$got]"
        failures=$((failures + 1))
    fi
}
assert_contains() {
    local label=$1 needle=$2 haystack=$3
    if [[ $haystack != *"$needle"* ]]; then
        echo "FAIL: $case_desc — $label: want substring [$needle] in [$haystack]"
        failures=$((failures + 1))
    fi
}

# A scratch directory holding tools/changelog.sh, base.md as CHANGELOG.md and an empty changelog.d/;
# sets $work.
new_work() {
    work=$(mktemp -d "$scratch_root/work.XXXXXX")
    mkdir -p "$work/tools" "$work/changelog.d"
    cp "$plugin_root/tools/changelog.sh" "$work/tools/changelog.sh" 2>/dev/null || true
    cp "$fx/base.md" "$work/CHANGELOG.md"
}

# Runs the scratch copy with the given arguments from $work; sets $out (stdout and stderr) and $status.
run_cl() {
    status=0
    out=$(cd "$work" && bash tools/changelog.sh "$@" 2>&1) || status=$?
}

# Lists the fragment files left in $work/changelog.d, one name per line.
fragments_left() { (cd "$work/changelog.d" && ls | grep -E '^[0-9]+\.md$' || true); }

case_desc=assemble_matches_the_hand_written_section
new_work
# Created out of order on purpose: 31, 12, 30.
cp "$fx/frag-31.md" "$work/changelog.d/31.md"
cp "$fx/frag-12.md" "$work/changelog.d/12.md"
cp "$fx/frag-30.md" "$work/changelog.d/30.md"
run_cl assemble v9.9.9 2026-12-01
assert_eq "exit" 0 "$status"
assert_eq "CHANGELOG.md" "$(cat "$fx/expected.md")" "$(cat "$work/CHANGELOG.md")"
assert_eq "fragments left" "" "$(fragments_left)"

case_desc=shared_state_joins_and_none_is_dropped
new_work
printf 'Shared state: adds `a`\n\n- A (#1).\n' > "$work/changelog.d/1.md"
printf 'Shared state: none\n\n- B (#2).\n' > "$work/changelog.d/2.md"
printf 'Shared state: adds `c`\n\n- C (#3).\n' > "$work/changelog.d/3.md"
run_cl assemble v9.9.9 2026-12-01
assert_eq "exit" 0 "$status"
assert_contains "joined" 'Shared state: adds `a`; adds `c`' "$(cat "$work/CHANGELOG.md")"
assert_eq "first bullet is fragment 1" "- A (#1)." "$(grep -m1 '^- ' "$work/CHANGELOG.md")"

case_desc=numeric_order_beats_lexical
new_work
printf -- '- Ten (#10).\n' > "$work/changelog.d/10.md"
printf -- '- Nine (#9).\n' > "$work/changelog.d/9.md"
printf -- '- Two (#2).\n' > "$work/changelog.d/2.md"
run_cl assemble v9.9.9 2026-12-01
assert_eq "exit" 0 "$status"
assert_eq "bullets in numeric order" "- Two (#2).
- Nine (#9).
- Ten (#10)." "$(grep '^- \(Two\|Nine\|Ten\)' "$work/CHANGELOG.md")"

case_desc=header_ends_at_the_first_blank_line
new_work
printf 'Shared state: adds `a`\n\nShared state: not a header\n- A (#1).\n' > "$work/changelog.d/1.md"
run_cl assemble v9.9.9 2026-12-01
assert_eq "exit" 0 "$status"
assert_contains "header line kept" 'Shared state: adds `a`
' "$(cat "$work/CHANGELOG.md")"
assert_eq "late line stays in the body" "Shared state: not a header
- A (#1)." "$(grep -B1 '^- A (#1)' "$work/CHANGELOG.md")"
assert_eq "late line not in the header" 'Shared state: adds `a`' "$(grep -m1 '^Shared state: adds' "$work/CHANGELOG.md")"

case_desc=no_fragments
new_work
run_cl assemble v9.9.9 2026-12-01
assert_eq "exit" 1 "$status"
assert_contains "message" "changelog: no fragments in changelog.d" "$out"

case_desc=usage
new_work
run_cl bogus
assert_eq "exit" 2 "$status"
assert_contains "usage" "usage:" "$out"

case_desc=two_branches_merge_without_a_conflict
new_work
repo="$work"
git -C "$repo" -c init.defaultBranch=main init -q
git -C "$repo" config gc.auto 0
touch "$repo/changelog.d/.gitkeep"
git -C "$repo" add CHANGELOG.md changelog.d/.gitkeep
git -C "$repo" commit -q -m init
git -C "$repo" checkout -q -b a
printf -- '- Forty (#40).\n' > "$repo/changelog.d/40.md"
git -C "$repo" add changelog.d/40.md
git -C "$repo" commit -q -m a
git -C "$repo" checkout -q main
git -C "$repo" checkout -q -b b
printf -- '- Forty-one (#41).\n' > "$repo/changelog.d/41.md"
git -C "$repo" add changelog.d/41.md
git -C "$repo" commit -q -m b
mstatus=0
git -C "$repo" merge -q --no-edit a >/dev/null 2>&1 || mstatus=$?
assert_eq "merge exit" 0 "$mstatus"
run_cl assemble v9.9.9 2026-12-01
assert_eq "assemble exit" 0 "$status"
assert_contains "bullet 40" "- Forty (#40)." "$(cat "$work/CHANGELOG.md")"
assert_contains "bullet 41" "- Forty-one (#41)." "$(cat "$work/CHANGELOG.md")"

case_desc=cat_reads_the_file_and_the_fragments
new_work
cp "$fx/frag-12.md" "$work/changelog.d/12.md"
run_cl cat
assert_eq "exit" 0 "$status"
assert_contains "from CHANGELOG.md" "- The first release (#1)." "$out"
assert_contains "from a fragment" "- Twelve changes one thing (#12)." "$out"

case_desc=the_documents_name_the_fragment_flow
contributing=$(cat "$plugin_root/CONTRIBUTING.md")
checklist=$(cat "$plugin_root/docs/release-checklist.md")
assert_contains "contributing fragment path" 'changelog.d/<issue>.md' "$contributing"
assert_contains "contributing tool" 'tools/changelog.sh' "$contributing"
assert_contains "checklist assemble" 'tools/changelog.sh assemble' "$checklist"
if [[ $checklist == *'retitle `CHANGELOG.md`'* ]]; then
    echo "FAIL: $case_desc — checklist still retitles ## Unreleased"
    failures=$((failures + 1))
fi

assert_contains "contributing plan task" 'never `CHANGELOG.md`' "$contributing"
assert_contains "contributing footprint" '`changelog.d/**`' "$contributing"

case_desc=this_repositorys_207_fragment_parses_and_assembles
frag207="$plugin_root/changelog.d/207.md"
if [[ ! -f $frag207 ]]; then
    echo "note: $case_desc — changelog.d/207.md is gone (assembled into a release); skipped"
else
    first_blank=$(grep -n -m1 '^$' "$frag207" | cut -d: -f1)
    header_bad=$(head -n "$((first_blank - 1))" "$frag207" | grep -vE '^(Config schema|Shared state|Safe to bump mid-workflow): ' || true)
    assert_eq "header lines only before the first blank line" "" "$header_bad"
    bullets=$(tail -n +"$first_blank" "$frag207" | grep -cE '^- .*\(#207\)\.?$' || true)
    if ((bullets < 1)); then
        echo "FAIL: $case_desc — no bullet ends (#207)"
        failures=$((failures + 1))
    fi
    new_work
    cp "$frag207" "$work/changelog.d/207.md"
    run_cl assemble v9.9.9 2026-12-01
    assert_eq "assemble exit" 0 "$status"
    assert_contains "section heading" "## v9.9.9 — 2026-12-01" "$(cat "$work/CHANGELOG.md")"
fi

case_desc=safe_to_bump_no_wins_and_reasons_join
new_work
printf 'Safe to bump mid-workflow: no — a\n\n- A (#1).\n' > "$work/changelog.d/1.md"
printf 'Safe to bump mid-workflow: no — b\n\n- B (#2).\n' > "$work/changelog.d/2.md"
run_cl assemble v9.9.9 2026-12-01
assert_eq "two no: exit" 0 "$status"
assert_eq "two no: line" "Safe to bump mid-workflow: no — a; b" "$(grep -m1 '^Safe to bump' "$work/CHANGELOG.md")"
new_work
printf 'Safe to bump mid-workflow: yes\n\n- A (#1).\n' > "$work/changelog.d/1.md"
printf 'Safe to bump mid-workflow: no — a\n\n- B (#2).\n' > "$work/changelog.d/2.md"
run_cl assemble v9.9.9 2026-12-01
assert_eq "yes then no: exit" 0 "$status"
assert_eq "yes then no: line" "Safe to bump mid-workflow: no — a" "$(grep -m1 '^Safe to bump' "$work/CHANGELOG.md")"
new_work
printf 'Safe to bump mid-workflow: no\n\n- A (#1).\n' > "$work/changelog.d/1.md"
printf 'Safe to bump mid-workflow: no — b\n\n- B (#2).\n' > "$work/changelog.d/2.md"
run_cl assemble v9.9.9 2026-12-01
assert_eq "bare no: exit" 0 "$status"
assert_eq "bare no: line" "Safe to bump mid-workflow: no — b" "$(grep -m1 '^Safe to bump' "$work/CHANGELOG.md")"
new_work
printf 'Safe to bump mid-workflow: yes\n\n- A (#1).\n' > "$work/changelog.d/1.md"
printf 'Safe to bump mid-workflow: yes\n\n- B (#2).\n' > "$work/changelog.d/2.md"
run_cl assemble v9.9.9 2026-12-01
assert_eq "two yes: line" "Safe to bump mid-workflow: yes" "$(grep -m1 '^Safe to bump' "$work/CHANGELOG.md")"
new_work
printf -- '- A (#1).\n' > "$work/changelog.d/1.md"
run_cl assemble v9.9.9 2026-12-01
assert_eq "none: line" "Safe to bump mid-workflow: yes" "$(grep -m1 '^Safe to bump' "$work/CHANGELOG.md")"

case_desc=config_schema_disagreement_still_stops
new_work
printf 'Config schema: 1\n\n- A (#5).\n' > "$work/changelog.d/5.md"
printf 'Config schema: 2\n\n- B (#6).\n' > "$work/changelog.d/6.md"
before=$(cat "$work/CHANGELOG.md")
run_cl assemble v9.9.9 2026-12-01
assert_eq "exit" 1 "$status"
assert_contains "message" "changelog: fragments disagree on Config schema: #5 says 1, #6 says 2" "$out"
assert_eq "CHANGELOG.md unchanged" "$before" "$(cat "$work/CHANGELOG.md")"
assert_eq "fragments kept" "5.md
6.md" "$(fragments_left)"

case_desc=a_stale_heading_is_refused
new_work
printf -- '- A (#1).\n' > "$work/changelog.d/1.md"
printf '\n## v9.9.9 — 2026-11-30\n\n- Old.\n' >> "$work/CHANGELOG.md"
before=$(cat "$work/CHANGELOG.md")
run_cl assemble v9.9.9 2026-12-01
assert_eq "exit" 1 "$status"
assert_contains "message" "changelog: CHANGELOG.md already has a section for v9.9.9" "$out"
assert_eq "CHANGELOG.md unchanged" "$before" "$(cat "$work/CHANGELOG.md")"
assert_eq "fragments kept" "1.md" "$(fragments_left)"
new_work
printf -- '- A (#1).\n' > "$work/changelog.d/1.md"
printf '\n## Unreleased\n\n- Pending.\n' >> "$work/CHANGELOG.md"
before=$(cat "$work/CHANGELOG.md")
run_cl assemble v9.9.9 2026-12-01
assert_eq "unreleased exit" 1 "$status"
assert_contains "unreleased message" "changelog: CHANGELOG.md has an ## Unreleased heading; fold it into a fragment first" "$out"
assert_eq "unreleased unchanged" "$before" "$(cat "$work/CHANGELOG.md")"
assert_eq "unreleased fragments kept" "1.md" "$(fragments_left)"

case_desc=a_crlf_fragment_leaves_no_carriage_return
new_work
printf 'Shared state: adds `a`\r\nSafe to bump mid-workflow: yes\r\n\r\n- A (#1).\r\n' > "$work/changelog.d/1.md"
run_cl assemble v9.9.9 2026-12-01
assert_eq "exit" 0 "$status"
cr=$(grep -c $'\r' "$work/CHANGELOG.md" || true)
assert_eq "carriage returns" 0 "$cr"
assert_contains "header parsed" 'Shared state: adds `a`' "$(cat "$work/CHANGELOG.md")"

case_desc=trailing_blank_lines_do_not_separate_bullets
new_work
printf -- '- A (#1).\n\n\n' > "$work/changelog.d/1.md"
printf -- '- B (#2).\n\n' > "$work/changelog.d/2.md"
run_cl assemble v9.9.9 2026-12-01
assert_eq "exit" 0 "$status"
assert_eq "bullets adjacent" "- A (#1).
- B (#2)." "$(grep -A1 '^- A (#1)' "$work/CHANGELOG.md")"

case_desc=any_caution_beats_yes
safe_of() { # <value in fragment 1> <value in fragment 2>: the assembled line
    new_work
    printf 'Safe to bump mid-workflow: %s\n\n- A (#1).\n' "$1" > "$work/changelog.d/1.md"
    printf 'Safe to bump mid-workflow: %s\n\n- B (#2).\n' "$2" > "$work/changelog.d/2.md"
    run_cl assemble v9.9.9 2026-12-01
    assert_eq "exit ($1 / $2)" 0 "$status"
    grep -m1 '^Safe to bump' "$work/CHANGELOG.md"
}
assert_eq "hyphen no beats yes" "Safe to bump mid-workflow: no — x" "$(safe_of 'no - x' yes)"
assert_eq "capital No beats yes" "Safe to bump mid-workflow: no" "$(safe_of No yes)"
assert_eq "not safe beats yes verbatim" "Safe to bump mid-workflow: not safe" "$(safe_of 'not safe' yes)"
assert_eq "maybe with no: no reasons first, then others" "Safe to bump mid-workflow: no — b; maybe" "$(safe_of maybe 'no — b')"
assert_eq "trailing space no beats yes" "Safe to bump mid-workflow: no" "$(safe_of 'no ' yes)"
assert_eq "comma no keeps reason" "Safe to bump mid-workflow: no — because x" "$(safe_of 'no, because x' yes)"
assert_eq "Yes with a note is a yes" "Safe to bump mid-workflow: yes" "$(safe_of 'yes' 'Yes')"

case_desc=unreleased_prefix_is_not_the_heading
new_work
printf -- '- A (#1).\n' > "$work/changelog.d/1.md"
printf '\n## UnreleasedFoo\n\n- x.\n' >> "$work/CHANGELOG.md"
run_cl assemble v9.9.9 2026-12-01
assert_eq "exit" 0 "$status"

case_desc=whitespace_only_trailing_lines_are_trimmed
new_work
printf -- '- A (#1).\n  \n\t\n' > "$work/changelog.d/1.md"
printf -- '- B (#2).\n' > "$work/changelog.d/2.md"
run_cl assemble v9.9.9 2026-12-01
assert_eq "exit" 0 "$status"
assert_eq "bullets adjacent" "- A (#1).
- B (#2)." "$(grep -A1 '^- A (#1)' "$work/CHANGELOG.md")"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
