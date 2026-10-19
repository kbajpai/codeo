#!/usr/bin/env bash
# Exercises scripts/dossier-check.sh against the invented dossiers under tests/fixtures/dossiers/:
# every good-* fixture prints nothing, every bad-* fixture prints exactly its expected lines (and
# exits 1 when one is a FAIL), every check id in the script's header comment has a bad-<id>/
# fixture whose lines carry that id at that severity, and every usage error exits 2 with one
# "dossier-check:" stderr line. Makes no network call and touches no git state.
#
#   dossier-check.test.sh
#       Exits non-zero and reports how many cases failed; prints "all cases passed" otherwise.
set -euo pipefail

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$plugin_root/scripts/dossier-check.sh"
fixtures="$plugin_root/tests/fixtures/dossiers"

failures=0
case_desc=
assert_eq() {
    local label=$1 want=$2 got=$3
    if [[ $want != "$got" ]]; then
        echo "FAIL: $case_desc — $label: want [$want] got [$got]"
        failures=$((failures + 1))
    fi
}

# run_check <dir>: sets out (stdout), err (stderr) and rc.
run_check() {
    out=$(bash "$script" "$@" 2>"$scratch/stderr") && rc=0 || rc=$?
    err=$(cat "$scratch/stderr")
}

# The expected stdout of every fixture, one finding per line; an empty string is a clean dossier.
declare -A want
want[good-basic]=
want[good-unheaded-first-round]=
want[good-park]=
want[good-open-pending]=
want[bad-title]='FAIL implement.md [title] first line is not "# Issue #<n> — implement"'
want[bad-header-table]='drift init.md [header-table] no "| | |" header table after the title'
want[bad-sections]='drift implement.md [sections] missing: ## Questions
drift close.md [sections] out of order: Where this stands, Outcome, Questions, Log'
want[bad-round-numbering]='FAIL implement.md [round-numbering] round headings run 3; expected 2
FAIL qc.md [round-numbering] ## Outcome has content before its first ### Round heading
FAIL qc.md [round-numbering] round headings run 2; expected 1'
want[bad-log-format]='FAIL init.md [log-format] line 28: does not start "- YYYY-MM-DD — "'
want[bad-log-cost]='FAIL plan.md [log-cost] line 46: no " · cost: "'
want[bad-footprint]='FAIL plan.md [footprint] ### Footprint at line 35 lacks: sequenced
FAIL plan.md [footprint] ### Footprint at line 35 has no value for: wiki'
want[bad-footprint-absent]='FAIL plan.md [footprint] no ### Footprint in ## Outcome'
want[bad-footprint-single]='drift plan.md [footprint-single] 2 ### Footprint blocks (lines 35, 44); expected one'
want[bad-open-question]='FAIL implement.md [open-question] Q2 is open but ## Outcome is written'

# --- every fixture: exact output, exit 1 exactly when a FAIL printed, nothing on stderr ----------
for dir in "$fixtures"/*/; do
    name=$(basename "$dir")
    case_desc="fixture $name"
    if [[ ! -v "want[$name]" ]]; then
        echo "FAIL: $case_desc — has no expected output in this test"
        failures=$((failures + 1))
        continue
    fi
    run_check "$dir"
    assert_eq "stdout" "${want[$name]}" "$out"
    assert_eq "stderr" "" "$err"
    if grep -q '^FAIL ' <<<"${want[$name]}"; then want_rc=1; else want_rc=0; fi
    assert_eq "exit code" "$want_rc" "$rc"
done
for name in "${!want[@]}"; do
    [[ -d $fixtures/$name ]] || { echo "FAIL: fixture $name is expected but missing"; failures=$((failures + 1)); }
done

# --- every documented check id has a bad-<id>/ fixture that prints it at its severity -----------
case_desc="check ids in the header comment"
ids=$(sed -nE 's/^#   ([a-z][a-z-]*) +(FAIL|drift) .*/\1 \2/p' "$script")
assert_eq "at least one id documented" 1 "$([[ -n $ids ]] && echo 1 || echo 0)"
while read -r id severity; do
    [[ -n $id ]] || continue
    case_desc="check id $id"
    if [[ ! -v "want[bad-$id]" ]]; then
        echo "FAIL: $case_desc — no bad-$id fixture"
        failures=$((failures + 1))
        continue
    fi
    # Every line of the fixture carries this id at the documented severity, and there is one.
    lines=$(grep -c " \[$id\] " <<<"${want[bad-$id]}" || true)
    others=$(grep -vc "^$severity [^ ]* \[$id\] " <<<"${want[bad-$id]}" || true)
    assert_eq "lines naming the id" 1 "$((lines > 0))"
    assert_eq "lines of another id or severity" 0 "$others"
done <<<"$ids"

# --- the checker reads CRLF files as it reads LF ones --------------------------------------------
case_desc="CRLF line endings"
mkdir "$scratch/crlf"
for f in "$fixtures"/good-basic/*.md; do
    sed 's/$/\r/' "$f" >"$scratch/crlf/$(basename "$f")"
done
run_check "$scratch/crlf"
assert_eq "stdout" "" "$out"
assert_eq "exit code" 0 "$rc"

# --- a file with none of the shape is classified, not a crash -----------------------------------
case_desc="shapeless file"
mkdir "$scratch/shapeless"
printf 'hello\n' >"$scratch/shapeless/plan.md"
run_check "$scratch/shapeless"
assert_eq "stdout" 'FAIL plan.md [title] first line is not "# Issue #<n> — plan"
drift plan.md [header-table] no "| | |" header table after the title
drift plan.md [sections] missing: ## Where this stands, ## Questions, ## Outcome, ## Log' "$out"
assert_eq "stderr" "" "$err"
assert_eq "exit code" 1 "$rc"

# --- usage errors: exit 2, one "dossier-check:" line on stderr, nothing on stdout --------------
mkdir "$scratch/empty" "$scratch/unrelated"
printf 'notes\n' >"$scratch/unrelated/notes.md"
printf 'x\n' >"$scratch/a-file"
usage_case() {
    case_desc=$1
    shift
    run_check "$@"
    assert_eq "exit code" 2 "$rc"
    assert_eq "stdout" "" "$out"
    assert_eq "stderr line count" 1 "$(wc -l <<<"$err")"
    assert_eq "stderr prefix" "dossier-check:" "${err%% *}"
}
usage_case "no argument"
usage_case "two arguments" "$fixtures/good-basic" "$fixtures/good-park"
usage_case "not a directory" "$scratch/a-file"
usage_case "missing path" "$scratch/nowhere"
usage_case "empty directory" "$scratch/empty"
usage_case "no dossier files" "$scratch/unrelated"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
