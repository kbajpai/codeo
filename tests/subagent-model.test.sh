#!/usr/bin/env bash
# Exercises hooks/subagent-model.sh by feeding it the PreToolUse JSON a session would, against
# scratch git repos. The hook must judge the project named by the JSON's cwd, never the process cwd.
#
#   subagent-model.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
hook="$plugin_root/hooks/subagent-model.sh"

scratch_root=$(mktemp -d)
trap 'rm -rf "$scratch_root"' EXIT
export HOME="$scratch_root/home"
mkdir -p "$HOME"

failures=0
case_desc=
assert_eq() {
    if [[ $2 != "$3" ]]; then
        echo "FAIL: $case_desc — $1: want [$2] got [$3]"
        failures=$((failures + 1))
    fi
}
assert_contains() {
    if [[ $3 != *"$2"* ]]; then
        echo "FAIL: $case_desc — $1: want substring [$2] in [$3]"
        failures=$((failures + 1))
    fi
}

# A scratch project; $2 non-empty seeds a config with that models block, $3 non-empty takes the lock.
project() {
    local dir="$scratch_root/$1"
    git init -q "$dir"
    mkdir -p "$dir/.codeo"
    if [[ -n ${2:-} ]]; then
        jq -n --argjson m "$2" '{schema: 1, repo: {owner: "o", name: "n"}, baseBranch: "main", models: $m}' \
            >"$dir/.codeo/config.json"
    fi
    if [[ -n ${3:-} ]]; then echo 1 >"$dir/.codeo/active"; fi
    printf '%s\n' "$dir"
}

# run_hook <project dir> <tool_input json>: prints the hook's stdout; always runs from elsewhere.
run_hook() {
    jq -n --arg cwd "$1" --argjson ti "$2" '{cwd: $cwd, tool_input: $ti}' |
        (cd "$scratch_root" && bash "$hook")
}
decision() { if [[ -z $1 ]]; then echo allow; else jq -r ".hookSpecificOutput.permissionDecision" <<<"$1"; fi; }

case_desc=hook_allows_everything_without_a_lock
p=$(project nolock '' '')
out=$(run_hook "$p" '{"subagent_type":"fork"}')
assert_eq "fork" allow "$(decision "$out")"
out=$(run_hook "$p" '{"model":"opus","description":"anything"}')
assert_eq "opus" allow "$(decision "$out")"
out=$(run_hook "$scratch_root" '{"subagent_type":"fork"}')
assert_eq "outside a repo" allow "$(decision "$out")"

case_desc=hook_denies_a_fork_while_locked
p=$(project forklock '' x)
out=$(run_hook "$p" '{"subagent_type":"fork","model":"sonnet"}')
assert_eq "fork" deny "$(decision "$out")"
assert_contains "reason" "forks inherit" "$out"
assert_contains "self-contained" "codeo" "$out"

case_desc=hook_allows_sonnet_while_locked
p=$(project sonnet '' x)
out=$(run_hook "$p" '{"model":"sonnet","subagent_type":"general-purpose"}')
assert_eq "sonnet" allow "$(decision "$out")"
out=$(run_hook "$p" '{"model":"claude-sonnet-5-5"}')
assert_eq "full id" allow "$(decision "$out")"
out=$(run_hook "$p" '{"subagent_type":"general-purpose"}')
assert_eq "no model" deny "$(decision "$out")"
assert_contains "no model reason" "inherit the skill model" "$out"

case_desc=hook_allows_opus_only_for_a_qc_review_description
out=$(run_hook "$p" '{"model":"opus","description":"QC review: diff"}')
assert_eq "qc review" allow "$(decision "$out")"
out=$(run_hook "$p" '{"model":"opus","description":"Explore the code"}')
assert_eq "other opus" deny "$(decision "$out")"
assert_contains "reason" 'got \"opus\"' "$out"
out=$(run_hook "$p" '{"model":"haiku","description":"QC review: diff"}')
assert_eq "haiku reviewer" deny "$(decision "$out")"
q=$(project badcfg '' x)
echo '{not json' >"$q/.codeo/config.json"
out=$(run_hook "$q" '{"model":"opus","description":"QC review: x"}' 2>/dev/null)
assert_eq "unusable config falls back to defaults" allow "$(decision "$out")"
out=$(run_hook "$q" '{"model":"sonnet"}' 2>/dev/null)
assert_eq "unusable config, sonnet" allow "$(decision "$out")"

case_desc=hook_honours_configured_models
p=$(project custom '{"subagent":"haiku","reviewer":"sonnet"}' x)
out=$(run_hook "$p" '{"model":"haiku"}')
assert_eq "configured subagent" allow "$(decision "$out")"
out=$(run_hook "$p" '{"model":"claude-haiku-4-5"}')
assert_eq "configured full id" allow "$(decision "$out")"
out=$(run_hook "$p" '{"model":"sonnet"}')
assert_eq "default no longer allowed" deny "$(decision "$out")"
out=$(run_hook "$p" '{"model":"sonnet","description":"QC review: x"}')
assert_eq "configured reviewer" allow "$(decision "$out")"
out=$(run_hook "$p" '{"model":"opus","description":"QC review: x"}')
assert_eq "default reviewer no longer allowed" deny "$(decision "$out")"
assert_contains "names configured model" 'must pass model \"haiku\"' "$out"

if [[ $failures -gt 0 ]]; then
    echo "$failures assertion(s) failed" >&2
    exit 1
fi
echo "all cases passed"
