#!/usr/bin/env bash
# What this Claude Code session has spent since a codeo skill was last invoked in it — wall
# time plus tokens per model, subagents included — as one line for that skill's dossier `## Log`.
#
#   usage.sh <skill> [--since <ISO-8601 UTC>]
#       <skill> is the bare name (qc, not /codeo:qc). The start is the latest invocation of
#       /codeo:<skill> in this session's transcript; --since overrides it when there is none,
#       e.g. after the session was resumed from another one.
set -euo pipefail

die() { echo "usage.sh: $*" >&2; exit 1; }

skill=${1:-}
[[ -n $skill ]] || die "name the skill: usage.sh <skill> [--since <ISO-8601>]"
since=
[[ ${2:-} == --since ]] && since=${3:?--since needs a timestamp}

sid=${CLAUDE_CODE_SESSION_ID:-}
[[ -n $sid ]] || die "CLAUDE_CODE_SESSION_ID is unset — run this from inside Claude Code"
transcript=$(find "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects" -maxdepth 2 -name "$sid.jsonl" -print -quit)
[[ -n $transcript ]] || die "no transcript found for session $sid"

if [[ -z $since ]]; then
    since=$(jq -rs --arg cmd "<command-name>/codeo:$skill</command-name>" \
        --arg skill "codeo:$skill" '
        [ .[] | select(
            (.type == "user" and ((.message.content | tostring) | contains($cmd))) or
            (.type == "assistant" and any(.message.content[]?;
                .type == "tool_use" and .name == "Skill" and .input.skill == $skill)))
          | .timestamp ] | max // empty' "$transcript")
    [[ -n $since ]] || die "/codeo:$skill was not invoked in this session; pass --since"
fi

shopt -s nullglob
files=("$transcript" "${transcript%.jsonl}"/subagents/*.jsonl)

cat "${files[@]}" | jq -rs --arg since "$since" '
    def n: if . >= 1e6 then "\(. / 1e5 | round / 10)M"
           elif . >= 1e3 then "\(. / 1e3 | round)k" else tostring end;
    def epoch: sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601;
    [ .[] | select(.type == "assistant" and .timestamp >= $since and .message.usage != null
                   and (.message.model // "<synthetic>") != "<synthetic>") ]
    | unique_by(.message.id)
    | (map(.timestamp) | min) as $start
    | group_by(.message.model)
    | map({ model: (.[0].message.model | sub("^claude-"; "")),
            fresh: (map(.message.usage | (.input_tokens // 0) + (.cache_creation_input_tokens // 0)) | add),
            cached: (map(.message.usage.cache_read_input_tokens // 0) | add),
            out: (map(.message.usage.output_tokens // 0) | add) })
    | map("\(.model) \(.fresh | n) in + \(.cached | n) cached / \(.out | n) out")
    | if $start == null then "nothing recorded since \($since)"
      else ["\((now - ($start | epoch)) / 60 | round)m"] + . | join(" · ") end'
