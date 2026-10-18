#!/usr/bin/env bash
# PreToolUse guard that keeps a codeo workflow's subagents on the configured models. Outside a
# workflow (no .codeo/active) it allows everything: the rule is the workflow's, not the repo's.
# The lock is looked up from the session's cwd, so each issue's container is judged by its own
# lock, and a checkout that holds none is never restricted.
set -euo pipefail

input=$(cat)
cwd=$(jq -r '.cwd // empty' <<<"$input")
root=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null) || exit 0
[[ -f "$root/.codeo/active" ]] || exit 0

# lib/env.sh resolves the project from the process cwd, but this hook runs wherever the session's
# host started it, so cd to the project the JSON named before sourcing.
cd "$root"
# shellcheck source=../lib/env.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

# A missing or unusable config must never break the session's tool calls: fall back to defaults.
# The lookup runs in a subshell, so codeo_cfg's exit on a bad config only ends that subshell.
allowed=$(codeo_cfg .models.subagent 2>/dev/null) || allowed=sonnet
reviewer=$(codeo_cfg .models.reviewer 2>/dev/null) || reviewer=opus

model=$(jq -r '.tool_input.model // empty' <<<"$input")
type=$(jq -r '.tool_input.subagent_type // empty' <<<"$input")
desc=$(jq -r '.tool_input.description // empty' <<<"$input")

deny() {
    jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse",
        permissionDecision: "deny", permissionDecisionReason: $r}}'
    exit 0
}

# A fork ignores `model` and always inherits the caller's, so no fork can be held to the model.
[[ $type == fork ]] && deny "A codeo workflow is active: forks inherit the skill's model. Dispatch a named subagent type with model \"$allowed\" instead."

case $model in
    "$allowed" | "claude-$allowed"-*) exit 0 ;;
    "$reviewer" | "claude-$reviewer"-*) [[ $desc == "QC review:"* ]] && exit 0 ;;
    '') model='nothing, so it would inherit the skill model' ;;
esac

deny "A codeo workflow is active: every subagent must pass model \"$allowed\" (got \"$model\"). The one exception is the QC code reviewer: model \"$reviewer\" with a description starting \"QC review:\"."
