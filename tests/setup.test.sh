#!/usr/bin/env bash
# Exercises scripts/setup.sh in scratch git repos: the state dir and config it creates, the
# refusal when a config exists, repo/owner/base derivation from origin (https and ssh), the marked
# fallback when nothing resolves, and --stack recording. Makes no network call.
#
#   setup.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$plugin_root/scripts/setup.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export HOME="$work/home"
mkdir -p "$HOME"

fail() { echo "FAIL: $1" >&2; exit 1; }

# A scratch repo; $2 is an origin URL (empty for none), $3 a base branch to set as origin/HEAD.
new_repo() {
    local dir="$work/$1"
    git init -q "$dir"
    [[ -z "${2:-}" ]] || git -C "$dir" remote add origin "$2"
    if [[ -n "${3:-}" ]]; then
        # symbolic-ref accepts a ref that does not exist yet, so no commit (and no identity) is needed.
        git -C "$dir" symbolic-ref refs/remotes/origin/HEAD "refs/remotes/origin/$3"
    fi
    echo "$dir"
}

setup_creates_state_dir_and_config() {
    local d; d=$(new_repo creates https://github.com/acme/widgets.git trunk)
    (cd "$d" && bash "$script" >/dev/null 2>&1) || fail "setup failed"
    [[ -d $d/docs/plans ]] || fail "docs/plans missing"
    [[ $(cat "$d/.codeo/.gitignore") == $'active\nintake/' ]] || fail ".gitignore content"
    jq -e '.schema == 1 and .suites == [] and .resources == [] and (has("stacks") | not) and (has("board") | not)' "$d/.codeo/config.json" >/dev/null || fail "config shape"
}

setup_refuses_an_existing_config() {
    local d; d=$(new_repo refuses https://github.com/acme/widgets.git trunk)
    mkdir "$d/.codeo"; echo '{"keep":1}' > "$d/.codeo/config.json"
    if (cd "$d" && bash "$script" >/dev/null 2>"$work/err"); then fail "setup overwrote a config"; fi
    [[ $(jq -r .keep "$d/.codeo/config.json") == 1 ]] || fail "config was touched"
    [[ $(wc -l < "$work/err") -eq 1 ]] || fail "refusal is not one line"
}

setup_derives_repo_and_base_branch_from_origin() {
    local d
    d=$(new_repo https https://github.com/acme/widgets.git trunk)
    (cd "$d" && bash "$script" >/dev/null 2>&1)
    [[ $(jq -r '"\(.repo.owner)/\(.repo.name)/\(.baseBranch)"' "$d/.codeo/config.json") == acme/widgets/trunk ]] || fail "https form"
    d=$(new_repo ssh git@github.com:acme/gadgets.git main)
    (cd "$d" && bash "$script" >/dev/null 2>&1)
    [[ $(jq -r '"\(.repo.owner)/\(.repo.name)/\(.baseBranch)"' "$d/.codeo/config.json") == acme/gadgets/main ]] || fail "ssh form"
}

setup_marks_unresolved_values_and_says_so() {
    local d; d=$(new_repo bare "" "")
    (cd "$d" && bash "$script" >/dev/null 2>"$work/err")
    [[ $(jq -r '"\(.repo.owner)/\(.repo.name)/\(.baseBranch)"' "$d/.codeo/config.json") == TODO-set-me/TODO-set-me/TODO-set-me ]] || fail "marker values"
    grep -q 'origin remote' "$work/err" && grep -q 'origin/HEAD' "$work/err" || fail "stderr notes"
}

setup_records_stacks() {
    local d; d=$(new_repo stacks https://github.com/acme/widgets.git main)
    (cd "$d" && bash "$script" --stack dotnet --stack angular >/dev/null 2>&1)
    [[ $(jq -c .stacks "$d/.codeo/config.json") == '["dotnet","angular"]' ]] || fail "stacks array"
}

for c in setup_creates_state_dir_and_config setup_refuses_an_existing_config \
    setup_derives_repo_and_base_branch_from_origin setup_marks_unresolved_values_and_says_so setup_records_stacks; do
    "$c"
done
echo "all cases passed"
