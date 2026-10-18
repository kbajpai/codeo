#!/usr/bin/env bash
# Creates the project's codeo state: .codeo/ (with a .gitignore for the per-checkout files), a
# starter config.json, and docs/plans/. Run from inside the project.
#
#   setup.sh [--stack <name>]…
#
# repo and owner come from `git remote get-url origin` (https or ssh form) and baseBranch from
# `git symbolic-ref refs/remotes/origin/HEAD`. When one does not resolve, the value is the marker
# TODO-set-me and one line on stderr says so, so a guessed value never passes for a real one.
# --stack names are recorded under the top-level `stacks` array and do nothing else.
# Refuses (exit 1) when .codeo/config.json already exists.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

stacks=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --stack)
            [[ -n "${2:-}" ]] || codeo_die "usage: setup.sh [--stack <name>]..."
            stacks+=("$2")
            shift 2
            ;;
        *) codeo_die "usage: setup.sh [--stack <name>]..." ;;
    esac
done

[[ -n "$CODEO_PROJECT_ROOT" ]] || codeo_die "not inside a git repository"
[[ ! -e "$CODEO_STATE_DIR/config.json" ]] || codeo_die "$CODEO_STATE_DIR/config.json already exists; setup does not overwrite it"

owner=TODO-set-me
name=TODO-set-me
if url=$(git -C "$CODEO_PROJECT_ROOT" remote get-url origin 2>/dev/null) && [[ -n "$url" ]]; then
    # https://host/owner/name(.git) and git@host:owner/name(.git) both end in owner/name.
    path=${url%.git}
    path=${path%/}
    name=${path##*[/:]}
    rest=${path%[/:]*}
    owner=${rest##*[/:]}
    if [[ -z "$owner" || -z "$name" || "$rest" == "$path" ]]; then
        owner=TODO-set-me
        name=TODO-set-me
    fi
fi
if [[ "$owner" == TODO-set-me ]]; then
    echo "codeo: could not read owner/name from the origin remote; set repo in .codeo/config.json" >&2
fi

base=TODO-set-me
if ref=$(git -C "$CODEO_PROJECT_ROOT" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null) && [[ -n "$ref" ]]; then
    base=${ref#refs/remotes/origin/}
else
    echo "codeo: could not read origin/HEAD; set baseBranch in .codeo/config.json" >&2
fi

mkdir -p "$CODEO_STATE_DIR" "$CODEO_PROJECT_ROOT/docs/plans"
printf 'active\nintake/\n' > "$CODEO_STATE_DIR/.gitignore"

stacks_json=$(printf '%s\n' ${stacks[@]+"${stacks[@]}"} | jq -R . | jq -s 'map(select(. != ""))')
jq -n --arg owner "$owner" --arg name "$name" --arg base "$base" --argjson stacks "$stacks_json" '
    {schema: 1, repo: {owner: $owner, name: $name}, baseBranch: $base, suites: [], resources: []}
    + (if ($stacks | length) > 0 then {stacks: $stacks} else {} end)' > "$CODEO_STATE_DIR/config.json"

echo "codeo: created .codeo/config.json for $owner/$name (base $base); run /codeo:doctor next"
