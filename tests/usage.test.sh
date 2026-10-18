#!/usr/bin/env bash
# Exercises usage.sh against a fabricated Claude Code transcript under a scratch CLAUDE_CONFIG_DIR.
#
#   usage.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
usage="$plugin_root/scripts/usage.sh"

scratch_root=$(mktemp -d)
trap 'rm -rf "$scratch_root"' EXIT
export HOME="$scratch_root/home"
export CLAUDE_CONFIG_DIR="$scratch_root/claude"
export CLAUDE_CODE_SESSION_ID=sess-1
mkdir -p "$HOME" "$CLAUDE_CONFIG_DIR/projects/p/sess-1/subagents"

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

t_old=2026-01-01T00:00:00Z
t_codeo=2026-01-01T01:00:00Z
t_after=2026-01-01T02:00:00Z
t_rm=2026-01-01T03:00:00Z

main="$CLAUDE_CONFIG_DIR/projects/p/sess-1.jsonl"
asst() { # timestamp id model in out
    jq -nc --arg t "$1" --arg id "$2" --arg m "$3" --argjson i "$4" --argjson o "$5" \
        '{type:"assistant",timestamp:$t,message:{id:$id,model:$m,usage:{input_tokens:$i,output_tokens:$o}}}'
}
{
    asst "$t_old" m0 claude-sonnet-5-5 100000 1000
    jq -nc --arg t "$t_codeo" '{type:"user",timestamp:$t,message:{content:"<command-name>/codeo:qc</command-name>"}}'
    asst "$t_after" m1 claude-sonnet-5-5 2000 500
    # A roadmaster invocation later in the transcript must not move the start.
    jq -nc --arg t "$t_rm" '{type:"user",timestamp:$t,message:{content:"<command-name>/roadmaster:plan</command-name>"}}'
} >"$main"
asst "$t_after" s1 claude-opus-4-7 3000 700 >"$CLAUDE_CONFIG_DIR/projects/p/sess-1/subagents/a.jsonl"

case_desc=usage_matches_codeo_invocations_and_ignores_roadmaster_ones
out=$("$usage" qc)
assert_contains "sonnet counted since /codeo:qc" "sonnet-5-5 2k in" "$out"
assert_contains "subagent counted" "opus-4-7 3k in" "$out"
if [[ $out == *"100k"* ]]; then
    echo "FAIL: $case_desc — usage before the invocation was counted: $out"
    failures=$((failures + 1))
fi
err=$("$usage" plan 2>&1 >/dev/null) && rc=0 || rc=$?
assert_eq "roadmaster invocation is not matched" 1 "$rc"
assert_contains "says it was not invoked" "/codeo:plan was not invoked" "$err"
out=$("$usage" plan --since "$t_after")
assert_contains "--since overrides" "sonnet-5-5 2k in" "$out"

if [[ $failures -gt 0 ]]; then
    echo "$failures assertion(s) failed" >&2
    exit 1
fi
echo "all cases passed"
