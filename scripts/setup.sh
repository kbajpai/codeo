#!/usr/bin/env bash
# Creates the project's codeo state: .codeo/ (with a .gitignore for the per-checkout files), a
# starter config.json, and docs/plans/. Run from inside the project.
#
#   setup.sh [--stack <name>]… [--codename <name>] [--containers]
#
# repo and owner come from `git remote get-url origin` (https or ssh form) and baseBranch from
# `git symbolic-ref refs/remotes/origin/HEAD`. When one does not resolve, the value is the marker
# TODO-set-me and one line on stderr says so, so a guessed value never passes for a real one.
# --stack names are recorded under the top-level `stacks` array and do nothing else.
# --codename <name> writes `codename` into the starter config (it names the project's containers, sandboxes,
# images and volumes; /codeo:doctor holds it to lower-case letters, digits and hyphens).
# --containers then writes the dev container and sbx sandbox files (scripts/containers.sh), named from the
# config. On its own, with a config already present, it writes only those files.
# The repository must already exist on GitHub with an origin remote: setup never creates one.
# Refuses (exit 1) when .codeo/config.json already exists, unless --containers is the only option.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

stacks=()
codename=""
containers=0
usage="usage: setup.sh [--stack <name>]... [--codename <name>] [--containers]"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --stack)
            [[ -n "${2:-}" ]] || codeo_die "$usage"
            stacks+=("$2")
            shift 2
            ;;
        --codename)
            [[ -n "${2:-}" ]] || codeo_die "$usage"
            codename=$2
            shift 2
            ;;
        --containers)
            containers=1
            shift
            ;;
        *) codeo_die "$usage" ;;
    esac
done

[[ -n "$CODEO_PROJECT_ROOT" ]] || codeo_die "not inside a git repository"
if [[ -e "$CODEO_STATE_DIR/config.json" && $containers == 1 && ${#stacks[@]} == 0 && -z $codename ]]; then
    exec bash "$CODEO_PLUGIN_ROOT/scripts/containers.sh"
fi
[[ -z $codename || ($codename =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ && ${#codename} -ge 2 && ${#codename} -le 30) ]] ||
    codeo_die "codename '$codename' must be lower-case letters, digits and single hyphens, starting with a letter, 2-30 characters"
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
jq -n --arg owner "$owner" --arg name "$name" --arg base "$base" --argjson stacks "$stacks_json" --arg codename "$codename" '
    {schema: 1, repo: {owner: $owner, name: $name}, baseBranch: $base, suites: [], resources: []}
    + (if $codename != "" then {codename: $codename} else {} end)
    + (if ($stacks | length) > 0 then {stacks: $stacks} else {} end)' > "$CODEO_STATE_DIR/config.json"

echo "codeo: created .codeo/config.json for $owner/$name (base $base); run /codeo:doctor next"

if ((containers)); then
    [[ $owner != TODO-set-me ]] || codeo_die "--containers needs the repository's owner and name: add the origin remote, then run setup.sh --containers"
    bash "$CODEO_PLUGIN_ROOT/scripts/containers.sh"
fi
