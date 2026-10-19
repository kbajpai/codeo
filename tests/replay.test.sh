#!/usr/bin/env bash
# The golden replay: runs scripts/dossier-check.sh on every finished dossier in a golden directory
# and compares what it prints with the findings that directory records as expected, so a change to
# the checker or to the skills' forms shows up against real, finished dossiers. The golden data is
# a project's own and stays in that project's repository; codeo carries only the synthetic
# directory tests/fixtures/golden/, which proves the harness.
#
#   CODEO_GOLDEN_DIR=<dir> replay.test.sh
#       Replays <dir>. Prints "replay: <n> dossiers, <m> recorded drifts, all as expected" and exits
#       0 when the findings match; otherwise prints every mismatch and exits 1.
#   replay.test.sh
#       With CODEO_GOLDEN_DIR unset (how tests/run.sh runs it): prints "replay: skipped,
#       CODEO_GOLDEN_DIR is not set" for the real data, then replays tests/fixtures/golden/ and
#       drives the harness's failure modes against scratch copies of it. Exits non-zero and reports
#       how many cases failed; prints "all cases passed" otherwise.
#
# The golden directory:
#
#   <dir>/<dossier>/         one directory per dossier (an issue's dossier files, e.g. a copy of
#                            done/<N>/); the dossier list is exactly the subdirectories of <dir>,
#                            and the subdirectory's name is the <dossier> column below
#   <dir>/expected.tsv       the findings expected, one per row, tab-separated:
#                                <dossier>	<severity>	<file>	<check-id>
#                            <severity> is FAIL or drift, <file> a dossier file's name (qc.md),
#                            <check-id> a checker id without its brackets (log-cost). Lines whose
#                            first character is "#" and blank lines are ignored. An absent file
#                            means no finding is expected.
#
# Each checker line "<FAIL|drift> <file> [<check-id>] <text>" is reduced to its row; the free text is
# ignored, so rewording a finding never breaks a replay, while a new finding, a finding that moved
# file or changed severity, or a recorded finding that no longer occurs does. Rows are compared as
# multisets: a row recorded twice must occur twice. Both severities are compared: a drift the
# checker would not fail on still fails the replay when it is not recorded. Each unexpected row
# prints as "replay: unexpected <row>" and each recorded row that did not occur as
# "replay: missing <row>" (rows tab-separated, as in expected.tsv).
#
# Exit codes of a replay: 0 every finding as expected; 1 one or more unexpected or missing rows;
# 2 the replay could not be judged, with one "replay: FAIL, …" line — CODEO_GOLDEN_DIR set but empty,
# not a directory, or holding no dossier subdirectory; a dossier the checker refuses (its exit 2,
# e.g. a subdirectory holding none of the six dossier files) or a line it prints outside its
# grammar; a malformed expected.tsv row. None of these is ever a pass.
#
# Makes no network call and touches no git state; its only writes are under a mktemp -d scratch
# directory. _CODEO_REPLAY_NESTED is internal: the self-test sets it when it re-runs this script
# with CODEO_GOLDEN_DIR unset, so that run replays the synthetic directory without recursing.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
checker="$plugin_root/scripts/dossier-check.sh"
synthetic="$plugin_root/tests/fixtures/golden"
self="$plugin_root/tests/replay.test.sh"
export LC_ALL=C

# replay <dir>: replays one golden directory as the header describes; prints its lines and returns
# its exit code.
replay() {
    local dir=$1 work line name rc out unexpected missing n m
    if [[ -z $dir ]]; then
        echo "replay: FAIL, CODEO_GOLDEN_DIR is set but empty"
        return 2
    fi
    if [[ ! -d $dir ]]; then
        echo "replay: FAIL, CODEO_GOLDEN_DIR $dir is not a directory"
        return 2
    fi
    local dossiers=()
    for line in "$dir"/*/; do
        [[ -d $line ]] && dossiers+=("$(basename "$line")")
    done
    if ((${#dossiers[@]} == 0)); then
        echo "replay: FAIL, CODEO_GOLDEN_DIR $dir has no dossier subdirectories"
        return 2
    fi

    work=$(mktemp -d)
    : >"$work/actual"
    : >"$work/expected"
    for name in "${dossiers[@]}"; do
        # The checker exits 1 whenever it prints a FAIL, which a recorded finding may be; only its
        # usage error (2, or anything else) means the dossier could not be checked at all.
        out=$(bash "$checker" "$dir/$name" 2>"$work/stderr") && rc=0 || rc=$?
        if ((rc != 0 && rc != 1)); then
            echo "replay: FAIL, dossier-check exited $rc on $name: $(head -n 1 "$work/stderr")"
            rm -rf "$work"
            return 2
        fi
        while IFS= read -r line; do
            [[ -n $line ]] || continue
            if [[ $line =~ ^(FAIL|drift)\ ([^ ]+)\ \[([a-z-]+)\]( |$) ]]; then
                printf '%s\t%s\t%s\t%s\n' "$name" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" \
                    "${BASH_REMATCH[3]}" >>"$work/actual"
            else
                echo "replay: FAIL, dossier-check printed a line outside its grammar on $name: $line"
                rm -rf "$work"
                return 2
            fi
        done <<<"$out"
    done

    if [[ -f $dir/expected.tsv ]]; then
        local lineno=0
        while IFS= read -r line || [[ -n $line ]]; do
            lineno=$((lineno + 1))
            line=${line%$'\r'}
            [[ -z ${line//[[:space:]]/} || $line == \#* ]] && continue
            if [[ ! $line =~ ^[^$'\t']+$'\t'(FAIL|drift)$'\t'[^$'\t']+$'\t'[a-z-]+$ ]]; then
                echo "replay: FAIL, expected.tsv line $lineno is not <dossier>	<FAIL|drift>	<file>	<check-id>: $line"
                rm -rf "$work"
                return 2
            fi
            printf '%s\n' "$line" >>"$work/expected"
        done <"$dir/expected.tsv"
    fi

    # comm pairs equal lines one for one, so sorted inputs compare as multisets.
    sort -o "$work/actual" "$work/actual"
    sort -o "$work/expected" "$work/expected"
    unexpected=$(comm -23 "$work/actual" "$work/expected")
    missing=$(comm -13 "$work/actual" "$work/expected")
    m=$(wc -l <"$work/expected")
    m=$((m + 0))
    rm -rf "$work"
    n=${#dossiers[@]}

    if [[ -n $unexpected || -n $missing ]]; then
        [[ -z $unexpected ]] || sed 's/^/replay: unexpected /' <<<"$unexpected"
        [[ -z $missing ]] || sed 's/^/replay: missing /' <<<"$missing"
        return 1
    fi
    echo "replay: $n dossiers, $m recorded drifts, all as expected"
}

if [[ -n ${CODEO_GOLDEN_DIR+set} ]]; then
    replay "$CODEO_GOLDEN_DIR"
    exit
fi

echo "replay: skipped, CODEO_GOLDEN_DIR is not set"
if [[ -n ${_CODEO_REPLAY_NESTED:-} ]]; then
    replay "$synthetic"
    exit
fi

# --- The self-test: the synthetic directory, then each failure mode on a scratch copy of it. ---

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

failures=0
case_desc=
assert_eq() {
    local label=$1 want=$2 got=$3
    if [[ $want != "$got" ]]; then
        echo "FAIL: $case_desc — $label: want [$want] got [$got]"
        failures=$((failures + 1))
    fi
}

# run_replay <dir>: replays <dir> through this script as a project would; sets out and rc.
run_replay() {
    out=$(CODEO_GOLDEN_DIR=$1 bash "$self" 2>&1) && rc=0 || rc=$?
}

# fresh <name>: a scratch copy of the synthetic directory at $scratch/<name>, printed.
fresh() {
    cp -r "$synthetic" "$scratch/$1"
    echo "$scratch/$1"
}

tab=$'\t'

case_desc="the synthetic directory replays clean"
run_replay "$synthetic"
assert_eq rc 0 "$rc"
assert_eq out "replay: 2 dossiers, 2 recorded drifts, all as expected" "$out"

case_desc="an unset CODEO_GOLDEN_DIR prints the skip line, then replays the synthetic directory"
out=$(env -u CODEO_GOLDEN_DIR _CODEO_REPLAY_NESTED=1 bash "$self" 2>&1) && rc=0 || rc=$?
assert_eq rc 0 "$rc"
assert_eq out "replay: skipped, CODEO_GOLDEN_DIR is not set
replay: 2 dossiers, 2 recorded drifts, all as expected" "$out"

case_desc="an extra finding nobody recorded fails"
dir=$(fresh extra)
sed -i 's/ · cost: 2m · sonnet-5 40k in + 200k cached \/ 3k out//' "$dir/case-a/close.md"
run_replay "$dir"
assert_eq rc 1 "$rc"
assert_eq out "replay: unexpected case-a${tab}FAIL${tab}close.md${tab}log-cost" "$out"

case_desc="a drift nobody recorded fails too"
dir=$(fresh extra-drift)
sed -i '3,8d' "$dir/case-a/qc.md"
run_replay "$dir"
assert_eq rc 1 "$rc"
assert_eq out "replay: unexpected case-a${tab}drift${tab}qc.md${tab}header-table" "$out"

case_desc="a recorded finding that does not occur fails"
dir=$(fresh missing)
printf 'case-a\tdrift\tqc.md\tcriteria-count\n' >>"$dir/expected.tsv"
run_replay "$dir"
assert_eq rc 1 "$rc"
assert_eq out "replay: missing case-a${tab}drift${tab}qc.md${tab}criteria-count" "$out"

case_desc="a finding that changed severity is both unexpected and missing"
dir=$(fresh severity)
sed -i 's/^case-b\tdrift\tinit.md/case-b\tFAIL\tinit.md/' "$dir/expected.tsv"
run_replay "$dir"
assert_eq rc 1 "$rc"
assert_eq out "replay: unexpected case-b${tab}drift${tab}init.md${tab}header-table
replay: missing case-b${tab}FAIL${tab}init.md${tab}header-table" "$out"

case_desc="an absent expected.tsv expects nothing, so the recorded findings are unexpected"
dir=$(fresh no-expected)
rm "$dir/expected.tsv"
run_replay "$dir"
assert_eq rc 1 "$rc"
assert_eq out "replay: unexpected case-b${tab}FAIL${tab}plan.md${tab}log-cost
replay: unexpected case-b${tab}drift${tab}init.md${tab}header-table" "$out"

case_desc="an absent expected.tsv over clean dossiers passes with no recorded drifts"
dir=$(fresh clean-only)
rm -r "$dir/case-b" "$dir/expected.tsv"
run_replay "$dir"
assert_eq rc 0 "$rc"
assert_eq out "replay: 1 dossiers, 0 recorded drifts, all as expected" "$out"

case_desc="a row recorded twice must occur twice"
dir=$(fresh duplicate)
printf 'case-b\tFAIL\tplan.md\tlog-cost\n' >>"$dir/expected.tsv"
run_replay "$dir"
assert_eq rc 1 "$rc"
assert_eq out "replay: missing case-b${tab}FAIL${tab}plan.md${tab}log-cost" "$out"

case_desc="a finding occurring twice and recorded twice passes"
dir=$(fresh duplicate-both)
printf -- '- 2026-04-02 — plan re-read\n' >>"$dir/case-b/plan.md"
printf 'case-b\tFAIL\tplan.md\tlog-cost\n' >>"$dir/expected.tsv"
run_replay "$dir"
assert_eq rc 0 "$rc"
assert_eq out "replay: 2 dossiers, 3 recorded drifts, all as expected" "$out"

case_desc="a finding occurring twice but recorded once fails once"
dir=$(fresh duplicate-once)
printf -- '- 2026-04-02 — plan re-read\n' >>"$dir/case-b/plan.md"
run_replay "$dir"
assert_eq rc 1 "$rc"
assert_eq out "replay: unexpected case-b${tab}FAIL${tab}plan.md${tab}log-cost" "$out"

case_desc="comments, blank lines and CRLF in expected.tsv are read as nothing"
dir=$(fresh comments)
printf '\n# a comment\r\n\r\n   \ncase-b\tdrift\tinit.md\theader-table\r\n' >"$dir/expected.tsv"
printf 'case-b\tFAIL\tplan.md\tlog-cost' >>"$dir/expected.tsv"
run_replay "$dir"
assert_eq rc 0 "$rc"
assert_eq out "replay: 2 dossiers, 2 recorded drifts, all as expected" "$out"

case_desc="a malformed expected.tsv row fails the harness"
dir=$(fresh malformed)
printf 'case-b drift init.md header-table\n' >>"$dir/expected.tsv"
run_replay "$dir"
assert_eq rc 2 "$rc"
assert_eq out "replay: FAIL, expected.tsv line 5 is not <dossier>${tab}<FAIL|drift>${tab}<file>${tab}<check-id>: case-b drift init.md header-table" "$out"

case_desc="a directory with no dossier subdirectories fails"
mkdir "$scratch/empty"
run_replay "$scratch/empty"
assert_eq rc 2 "$rc"
assert_eq out "replay: FAIL, CODEO_GOLDEN_DIR $scratch/empty has no dossier subdirectories" "$out"

case_desc="an expected.tsv with no dossier subdirectories beside it still fails"
mkdir "$scratch/only-expected"
cp "$synthetic/expected.tsv" "$scratch/only-expected/"
run_replay "$scratch/only-expected"
assert_eq rc 2 "$rc"
assert_eq out "replay: FAIL, CODEO_GOLDEN_DIR $scratch/only-expected has no dossier subdirectories" "$out"

case_desc="a nonexistent CODEO_GOLDEN_DIR fails"
run_replay "$scratch/nowhere"
assert_eq rc 2 "$rc"
assert_eq out "replay: FAIL, CODEO_GOLDEN_DIR $scratch/nowhere is not a directory" "$out"

case_desc="a CODEO_GOLDEN_DIR set but empty fails"
run_replay ""
assert_eq rc 2 "$rc"
assert_eq out "replay: FAIL, CODEO_GOLDEN_DIR is set but empty" "$out"

case_desc="a dossier the checker refuses fails the harness, naming it"
dir=$(fresh refused)
mkdir "$dir/case-c"
printf 'notes\n' >"$dir/case-c/notes.md"
run_replay "$dir"
assert_eq rc 2 "$rc"
assert_eq "out prefix" "replay: FAIL, dossier-check exited 2 on case-c: dossier-check:" "${out%% dossier-check: *} dossier-check:"

if ((failures > 0)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
