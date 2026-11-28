#!/usr/bin/env bash
# Exercises base-moved.sh against real scratch git repos: "origin" is a scratch repo reached by a
# local path, HOME is a scratch directory, and nothing touches the network or real git config.
#
#   base-moved.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

export GIT_AUTHOR_NAME="Moved Test" GIT_AUTHOR_EMAIL="moved-test@example.com"
export GIT_COMMITTER_NAME="Moved Test" GIT_COMMITTER_EMAIL="moved-test@example.com"

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

# An origin on main holding a.txt and b.txt, and a clone on feat/x whose branch changes a.txt and
# holds .codeo/7/qc.md ending in "Graded base: <origin/main now>". Sets $graded.
setup() {
    origin=$(mktemp -d "$scratch_root/origin.XXXXXX")
    git -C "$origin" -c init.defaultBranch=main init -q
    git -C "$origin" config gc.auto 0
    git -C "$origin" config maintenance.auto false
    git -C "$origin" config receive.autogc false
    local f
    for f in a b; do printf 'one\ntwo\nthree\n' > "$origin/$f.txt"; done
    git -C "$origin" add .
    git -C "$origin" commit -q -m init
    clone=$(mktemp -d "$scratch_root/clone.XXXXXX")
    git clone -q "$origin" "$clone"
    mkdir -p "$clone/.codeo/7"
    printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}\n' > "$clone/.codeo/config.json"
    git -C "$clone" checkout -q -b feat/x
    graded=$(git -C "$clone" rev-parse origin/main)
    commit_in "$clone" a.txt feat-a "feat a"
    printf '## Round 1\n\nGraded base: %s\n' "$graded" > "$clone/.codeo/7/qc.md"
}
commit_in() {
    sed -i "1s/.*/$3/" "$1/$2"
    git -C "$1" add "$2"
    git -C "$1" commit -q -m "$4"
}
run_moved() {
    status=0
    out=$(cd "$clone" && bash "$plugin_root/scripts/base-moved.sh" "$@" 2>"$scratch_root/stderr") || status=$?
    err=$(cat "$scratch_root/stderr")
}

setup
case_desc="main changed only a file the branch did not"
commit_in "$origin" b.txt main-b "main b"
run_moved 7
assert_eq "exit" 0 "$status"
assert_eq "stdout" "" "$out"

setup
case_desc="main changed a file the branch also changed"
sed -i '1s/.*/main-a/' "$origin/a.txt"
sed -i '1s/.*/main-b/' "$origin/b.txt"
git -C "$origin" commit -q -am "main a and b"
run_moved 7
assert_eq "exit" 3 "$status"
assert_eq "stdout" "a.txt" "$out"

setup
case_desc="an earlier Graded base line is ignored when a later one exists"
first=$graded
sed -i "3s/.*/main-three/" "$origin/a.txt"; git -C "$origin" commit -q -am "main a3"
git -C "$clone" fetch -q origin main
git -C "$clone" merge -q --no-edit origin/main
later=$(git -C "$clone" rev-parse origin/main)
printf 'Graded base: %s\n\nGraded base: %s\n' "$first" "$later" > "$clone/.codeo/7/qc.md"
run_moved 7
assert_eq "exit" 0 "$status"
assert_eq "stdout" "" "$out"
printf 'Graded base: %s\n' "$first" > "$clone/.codeo/7/qc.md"
run_moved 7
assert_eq "control (earlier alone): exit" 3 "$status"
assert_eq "control (earlier alone): stdout" "a.txt" "$out"

setup
case_desc="no Graded base line"
printf '## Round 1\n\nnothing here\n' > "$clone/.codeo/7/qc.md"
run_moved 7
assert_eq "exit" 4 "$status"
assert_eq "stdout" "" "$out"
assert_eq "stderr" "base-moved: no Graded base line in $clone/.codeo/7/qc.md" "$err"

setup
case_desc="a sha that is not a commit"
printf 'Graded base: %s\n' "0123456789abcdef0123456789abcdef01234567" > "$clone/.codeo/7/qc.md"
run_moved 7
assert_eq "exit" 1 "$status"
assert_eq "stdout" "" "$out"
assert_eq "stderr" "base-moved: 0123456789abcdef0123456789abcdef01234567 is not a commit" "$err"

setup
case_desc="no qc.md at all"
rm "$clone/.codeo/7/qc.md"
run_moved 7
assert_eq "exit" 1 "$status"
assert_eq "stdout" "" "$out"
assert_eq "stderr" "base-moved: no qc.md for issue 7" "$err"

setup
case_desc="the dossier under done/ is read when the live one is absent"
mkdir -p "$clone/.codeo/done/7"
mv "$clone/.codeo/7/qc.md" "$clone/.codeo/done/7/qc.md"
sed -i '1s/.*/main-a/' "$origin/a.txt"
git -C "$origin" commit -q -am "main a"
run_moved 7
assert_eq "exit" 3 "$status"
assert_eq "stdout" "a.txt" "$out"

setup
case_desc="main has not moved since the graded sha"
run_moved 7
assert_eq "exit" 0 "$status"
assert_eq "stdout" "" "$out"

setup
case_desc="the base renames a file the branch changed"
git -C "$origin" mv a.txt c.txt
git -C "$origin" commit -q -m "main renames a to c"
run_moved 7
assert_eq "exit" 3 "$status"
assert_eq "stdout" "a.txt" "$out"
assert_eq "stderr" "" "$err"

setup
case_desc="origin unreachable"
git -C "$clone" remote set-url origin "$scratch_root/no-such-origin"
run_moved 7
assert_eq "exit" 1 "$status"
assert_eq "stdout" "" "$out"
assert_eq "stderr" "base-moved: could not fetch origin/main" "$err"

setup
case_desc="the graded sha is not an ancestor of the base (a rebased base)"
commit_in "$origin" b.txt main-b "main b"
git -C "$clone" fetch -q origin main
graded=$(git -C "$clone" rev-parse origin/main)
printf "Graded base: %s\n" "$graded" > "$clone/.codeo/7/qc.md"
git -C "$origin" reset -q --hard HEAD~1
sed -i "1s/.*/rebased-a/" "$origin/a.txt"
sed -i "1s/.*/rebased-b/" "$origin/b.txt"
git -C "$origin" commit -q -am "rebased main"
run_moved 7
assert_eq "exit" 3 "$status"
assert_eq "stdout" "a.txt" "$out"
assert_eq "stderr" "" "$err"

setup
case_desc="a CRLF Graded base line and one with trailing text"
commit_in "$origin" a.txt main-a "main a"
printf 'Graded base: %s\r\n' "$graded" > "$clone/.codeo/7/qc.md"
run_moved 7
assert_eq "CRLF: exit" 3 "$status"
assert_eq "CRLF: stdout" "a.txt" "$out"
printf 'Graded base: %s (round 2)\n' "$graded" > "$clone/.codeo/7/qc.md"
run_moved 7
assert_eq "trailing text: exit" 3 "$status"
assert_eq "trailing text: stdout" "a.txt" "$out"

setup
case_desc="a sha that starts with a dash"
printf 'Graded base: -abc\n' > "$clone/.codeo/7/qc.md"
run_moved 7
assert_eq "exit" 1 "$status"
assert_eq "stdout" "" "$out"
assert_eq "stderr" "base-moved: -abc is not a commit" "$err"

setup
case_desc="a list item and backticks around the sha are read"
commit_in "$origin" a.txt main-a "main a"
for form in "- Graded base: $graded" "Graded base: \`$graded\`" "- Graded base: \`$graded\`"; do
    printf '## Round 1\n\n%s\n' "$form" > "$clone/.codeo/7/qc.md"
    run_moved 7
    assert_eq "$form: exit" 3 "$status"
    assert_eq "$form: stdout" "a.txt" "$out"
done

setup
case_desc="a sha newer than the graded tree cannot hide changes"
commit_in "$origin" b.txt main-b1 "main b1"
git -C "$clone" fetch -q origin main
git -C "$clone" merge -q --no-edit origin/main
commit_in "$origin" a.txt main-b2 "main b2"
git -C "$clone" fetch -q origin main
printf '## Round 1\n\nGraded base: %s\n' "$(git -C "$clone" rev-parse origin/main)" > "$clone/.codeo/7/qc.md"
run_moved 7
assert_eq "exit" 3 "$status"
assert_eq "stdout" "a.txt" "$out"

setup
case_desc="update branch state: HEAD already contains the new base"
sed -i "3s/.*/main-three/" "$origin/a.txt"; git -C "$origin" commit -q -am "main a3"
git -C "$clone" fetch -q origin main
git -C "$clone" merge -q --no-edit origin/main
run_moved 7
assert_eq "same file: exit" 3 "$status"
assert_eq "same file: stdout" "a.txt" "$out"

setup
commit_in "$origin" b.txt main-b "main b"
git -C "$clone" fetch -q origin main
git -C "$clone" merge -q --no-edit origin/main
run_moved 7
assert_eq "other file: exit" 0 "$status"
assert_eq "other file: stdout" "" "$out"

setup
case_desc="usage errors"
run_moved
assert_eq "no args: exit" 1 "$status"
assert_contains "no args: usage" "usage: base-moved.sh <N>" "$err"
run_moved abc
assert_eq "non-number: exit" 1 "$status"
run_moved 7 8
assert_eq "extra arg: exit" 1 "$status"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
