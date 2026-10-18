#!/usr/bin/env bash
# Exercises scripts/overlay.sh against scratch repos: section fetch and trimming, the exit codes a
# skill branches on (0 present, 3 absent or empty, 2 unknown skill/point pair, 4 duplicate), and
# that a point name is matched literally. HOME is pointed at a scratch directory.
#
#   overlay.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
overlay_sh="$plugin_root/scripts/overlay.sh"

scratch_root=$(mktemp -d)
trap 'rm -rf "$scratch_root"' EXIT
export HOME="$scratch_root/home"
mkdir -p "$HOME"

fail() { echo "FAIL: $1" >&2; exit 1; }

# A scratch repo; prints its path.
make_repo() {
    local dir
    dir=$(mktemp -d "$scratch_root/repo.XXXXXX")
    git -C "$dir" init -q
    echo "$dir"
}

# Writes an overlay file. $1 = repo, $2 = skill, $3 = content (printf %b escapes honoured).
write_overlay() {
    mkdir -p "$1/.codeo/overlays"
    printf '%b' "$3" > "$1/.codeo/overlays/$2.md"
}

# Runs overlay.sh in a repo, capturing stdout, stderr and the exit code in $out, $err, $rc.
run_overlay() {
    local repo=$1; shift
    rc=0
    out=$(cd "$repo" && bash "$overlay_sh" "$@" 2>"$scratch_root/err") || rc=$?
    err=$(cat "$scratch_root/err")
}

present_section_is_printed_trimmed() {
    local repo; repo=$(make_repo)
    write_overlay "$repo" plan '# Plan overlay\n\n## plan-shape  \n\n\nUse the long form.\n\nSecond paragraph.\n\n\n## wiki-rules\nother\n'
    run_overlay "$repo" plan plan-shape
    [[ "$rc" -eq 0 ]] || fail "rc=$rc err=$err"
    [[ "$out" == $'Use the long form.\n\nSecond paragraph.' ]] || fail "unexpected: $out"
}

absent_file_exits_3_silently() {
    local repo; repo=$(make_repo)
    run_overlay "$repo" plan plan-shape
    [[ "$rc" -eq 3 && -z "$out" && -z "$err" ]] || fail "rc=$rc out=$out err=$err"
}

empty_section_exits_3() {
    local repo; repo=$(make_repo)
    write_overlay "$repo" plan '## plan-shape\n\n   \n## wiki-rules\ntext\n'
    run_overlay "$repo" plan plan-shape
    [[ "$rc" -eq 3 && -z "$out" && -z "$err" ]] || fail "rc=$rc out=$out err=$err"
    write_overlay "$repo" plan '## plan-shape\n'
    run_overlay "$repo" plan plan-shape
    [[ "$rc" -eq 3 && -z "$out" ]] || fail "at EOF: rc=$rc out=$out"
}

missing_section_exits_3() {
    local repo; repo=$(make_repo)
    write_overlay "$repo" plan '## wiki-rules\ntext\n'
    run_overlay "$repo" plan plan-shape
    [[ "$rc" -eq 3 && -z "$out" && -z "$err" ]] || fail "rc=$rc out=$out err=$err"
}

unknown_pair_exits_2_one_line() {
    local repo; repo=$(make_repo)
    write_overlay "$repo" plan '## plan-shape\ntext\n'
    run_overlay "$repo" plna plan-shape
    [[ "$rc" -eq 2 && -z "$out" && "$err" == codeo:* && "$(printf '%s\n' "$err" | wc -l)" -eq 1 ]] || fail "skill: rc=$rc out=$out err=$err"
    run_overlay "$repo" plan nonsense
    [[ "$rc" -eq 2 && -z "$out" && "$err" == codeo:* && "$(printf '%s\n' "$err" | wc -l)" -eq 1 ]] || fail "point: rc=$rc out=$out err=$err"
    run_overlay "$repo" plan
    [[ "$rc" -eq 2 && "$err" == codeo:* ]] || fail "arity: rc=$rc err=$err"
}

regex_characters_in_a_point_are_literal() {
    local repo; repo=$(make_repo)
    printf 'plan\ta.b*c\tnone\nplan\taXbbbc\tnone\n' > "$scratch_root/points.tsv"
    write_overlay "$repo" plan '## aXbbbc\nwrong\n## a.b*c\nright\n'
    rc=0
    out=$(cd "$repo" && CODEO_EXTENSION_POINTS="$scratch_root/points.tsv" bash "$overlay_sh" plan 'a.b*c' 2>&1) || rc=$?
    [[ "$rc" -eq 0 && "$out" == "right" ]] || fail "rc=$rc out=$out"
    # A backslash in the point must not be read as an escape either.
    printf 'plan\ta\\tb\tnone\n' > "$scratch_root/points.tsv"
    write_overlay "$repo" plan '## a\\tb\nliteral\n'
    out=$(cd "$repo" && CODEO_EXTENSION_POINTS="$scratch_root/points.tsv" bash "$overlay_sh" plan 'a\tb' 2>&1) || rc=$?
    [[ "$out" == "literal" ]] || fail "backslash: $out"
}

crlf_file_is_normalised() {
    local repo; repo=$(make_repo)
    write_overlay "$repo" plan '## plan-shape\r\n\r\nline one\r\nline two\r\n\r\n## wiki-rules\r\nx\r\n'
    run_overlay "$repo" plan plan-shape
    [[ "$rc" -eq 0 && "$out" == $'line one\nline two' ]] || fail "rc=$rc out=$(printf '%q' "$out")"
}

duplicate_section_exits_4_naming_lines() {
    local repo; repo=$(make_repo)
    write_overlay "$repo" plan '## plan-shape\na\n\n## wiki-rules\nb\n## plan-shape\nc\n'
    run_overlay "$repo" plan plan-shape
    [[ "$rc" -eq 4 && -z "$out" ]] || fail "rc=$rc out=$out"
    [[ "$err" == codeo:* && "$(printf '%s\n' "$err" | wc -l)" -eq 1 && "$err" == *"lines 1 and 6"* ]] || fail "unexpected: $err"
}

section_ends_at_next_heading() {
    local repo; repo=$(make_repo)
    write_overlay "$repo" plan '## wiki-rules\nfirst\n### sub heading stays\n## plan-shape\nbody\n## proof-of-done\nlater\n'
    run_overlay "$repo" plan wiki-rules
    [[ "$rc" -eq 0 && "$out" == $'first\n### sub heading stays' ]] || fail "wiki: rc=$rc out=$out"
    run_overlay "$repo" plan plan-shape
    [[ "$rc" -eq 0 && "$out" == "body" ]] || fail "shape: rc=$rc out=$out"
}

unreadable_overlay_exits_1_one_line() {
    if [[ "$(id -u)" -eq 0 ]]; then echo "note: running as root, skipping unreadable_overlay_exits_1_one_line"; return 0; fi
    local repo; repo=$(make_repo)
    write_overlay "$repo" plan '## plan-shape\ntext\n'
    chmod 000 "$repo/.codeo/overlays/plan.md"
    run_overlay "$repo" plan plan-shape
    chmod 644 "$repo/.codeo/overlays/plan.md"
    [[ "$rc" -eq 1 && -z "$out" && "$err" == codeo:*"not readable" && "$(printf '%s\n' "$err" | wc -l)" -eq 1 && "$err" != *awk* ]] || fail "rc=$rc out=$out err=$err"
}

unreadable_registry_exits_1_one_line() {
    local repo; repo=$(make_repo)
    rc=0
    err=$(cd "$repo" && CODEO_EXTENSION_POINTS="$scratch_root/nope.tsv" bash "$overlay_sh" plan plan-shape 2>&1 >/dev/null) || rc=$?
    [[ "$rc" -eq 1 && "$err" == "codeo: extension-point registry not readable: $scratch_root/nope.tsv" ]] || fail "rc=$rc err=$err"
}

heading_at_eof_without_newline_is_found() {
    local repo; repo=$(make_repo)
    write_overlay "$repo" plan '## plan-shape\nlast line'
    run_overlay "$repo" plan plan-shape
    [[ "$rc" -eq 0 && "$out" == "last line" ]] || fail "rc=$rc out=$out"
}

heading_with_extra_words_does_not_match() {
    local repo; repo=$(make_repo)
    write_overlay "$repo" plan '## plan-shape extra\ntext\n'
    run_overlay "$repo" plan plan-shape
    [[ "$rc" -eq 3 && -z "$out" ]] || fail "rc=$rc out=$out"
}

heading_inside_a_code_fence_ends_the_section() {
    local repo; repo=$(make_repo)
    write_overlay "$repo" plan '## plan-shape\nbefore\n```\n## not a point\nafter\n```\n'
    run_overlay "$repo" plan plan-shape
    [[ "$rc" -eq 0 && "$out" == $'before\n```' ]] || fail "rc=$rc out=$out"
}

implement_points_are_registered_and_absent() {
    local repo; repo=$(make_repo)
    local p
    for p in environment-lease-notes wiki-rules; do
        run_overlay "$repo" implement "$p"
        [[ "$rc" -eq 3 ]] || fail "implement $p rc=$rc err=$err"
    done
    run_overlay "$repo" implement no-such-point
    [[ "$rc" -eq 2 ]] || fail "implement no-such-point rc=$rc"
}

env_header_documents_parallel_and_deploy() {
    local header; header=$(grep '^#' "$plugin_root/lib/env.sh")
    [[ "$header" == *parallel* && "$header" == *deploy* ]] || fail "env.sh header lacks parallel or deploy"
}

for c in implement_points_are_registered_and_absent env_header_documents_parallel_and_deploy unreadable_overlay_exits_1_one_line unreadable_registry_exits_1_one_line heading_at_eof_without_newline_is_found heading_with_extra_words_does_not_match heading_inside_a_code_fence_ends_the_section \
    present_section_is_printed_trimmed absent_file_exits_3_silently empty_section_exits_3 \
    missing_section_exits_3 unknown_pair_exits_2_one_line regex_characters_in_a_point_are_literal \
    crlf_file_is_normalised duplicate_section_exits_4_naming_lines section_ends_at_next_heading; do
    "$c"
done
echo "all cases passed"
