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
# config. On its own, with a config already present, it adds a missing codename (the repository name made to fit,
# or the --codename given; it refuses another one when the config already names one) and the plugin pin, and writes
# those files. It ends by saying the home checkout is the clone whose folder is named <codename>-home, and whether
# this folder is.
# The repository must already exist on GitHub with an origin remote: setup never creates one.
# Refuses (exit 1) when .codeo/config.json already exists, unless --containers is the only option besides --codename.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/codename.sh"

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

# run_containers: containers.sh, then one note when it kept a seed file (a Dockerfile, devcontainer.json, sandbox image
# or overlay a project already had), because the managed scripts rely on what the seeds provide.
run_containers() {
    local out
    out=$(bash "$CODEO_PLUGIN_ROOT/scripts/containers.sh") || { [[ -z $out ]] || printf '%s\n' "$out"; return 1; }
    printf '%s\n' "$out"
    (($(codeo_kept_seeds "$out") == 0)) || echo "codeo: note: $(codeo_kept_seeds_note)"
}
# --containers fills the codename and the plugin pin into the config where a key is absent or empty, so the config and
# the rendered files agree and the container can install codeo. Only the missing key is written: a fork's plugin.repo
# stays. The ref fails soft: no release, no pin, files still written.
write_pin() {
    local cfg="$CODEO_STATE_DIR/config.json" missing pin="" repo=${CODEO_PLUGIN_REPO:-kbajpai/codeo} r=""
    msg=$(codeo_config_shape_error "$cfg") || codeo_die "config.json $msg"
    msg=$(codeo_pin_repo_error "$cfg") || codeo_die "$msg"
    missing=$(codeo_pin_missing "$cfg")
    [[ -n $missing ]] || return 0
    if [[ $missing == *ref* ]]; then
        if ! pin=$(codeo_latest_release "$(codeo_pin_url "$cfg")"); then
            echo "codeo: no codeo release found to pin; set plugin.repo and plugin.ref in .codeo/config.json"
            return 0
        fi
    fi
    [[ $missing == *repo* ]] && r=$repo
    codeo_pin_fill "$cfg" "$r" "$pin" || codeo_die "cannot write the plugin pin into .codeo/config.json"
    if [[ -n $pin ]]; then
        echo "codeo: pinned the plugin to $pin in .codeo/config.json"
    else
        echo "codeo: wrote plugin.repo $r to .codeo/config.json"
    fi
}
[[ -z $codename || ($codename =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ && ${#codename} -ge 2 && ${#codename} -le 30) ]] ||
    codeo_die "codename '$codename' must be lower-case letters, digits and single hyphens, starting with a letter, 2-30 characters"
if [[ -e "$CODEO_STATE_DIR/config.json" && $containers == 1 && ${#stacks[@]} == 0 ]]; then
    msg=$(codeo_config_shape_error "$CODEO_STATE_DIR/config.json") || codeo_die "config.json $msg"
    msg=$(codeo_pin_repo_error "$CODEO_STATE_DIR/config.json") || codeo_die "$msg"
    msg=$(codeo_base_error "$CODEO_STATE_DIR/config.json") || codeo_die "$msg"
    existing_cn=$(jq -r '.codename // empty' "$CODEO_STATE_DIR/config.json" 2>/dev/null || true)
    if [[ -n $codename && -n $existing_cn && $codename != "$existing_cn" ]]; then
        codeo_die "$CODEO_STATE_DIR/config.json already names '$existing_cn'; setup does not overwrite it"
    fi
    if [[ -z $existing_cn ]]; then
        existing_name=$(codeo_cfg .repo.name || true)
        existing_owner=$(codeo_cfg .repo.owner || true)
        if [[ $existing_name == TODO-set-me || $existing_owner == TODO-set-me ]]; then
            codeo_die "repo.owner/repo.name is TODO-set-me in .codeo/config.json: set them, then run setup.sh --containers"
        fi
        cn=$codename
        if [[ -z $cn ]]; then
            cn=$(codeo_derive_codename "$existing_name") || codeo_die "cannot derive a codename from '$existing_name'; pass --codename <name>"
        fi
        if ! jq --arg c "$cn" '.codename = $c' "$CODEO_STATE_DIR/config.json" >"$CODEO_STATE_DIR/config.json.new" ||
            ! mv "$CODEO_STATE_DIR/config.json.new" "$CODEO_STATE_DIR/config.json"; then
            rm -f "$CODEO_STATE_DIR/config.json.new"
            codeo_die "cannot write the codename into .codeo/config.json"
        fi
        if [[ -n $codename ]]; then
            echo "codeo: wrote codename $cn to .codeo/config.json"
        else
            echo "codeo: wrote codename $cn to .codeo/config.json (the repository name)"
        fi
        existing_cn=$cn
    fi
    write_pin
    run_containers
    codeo_home_lines "$existing_cn" "$CODEO_PROJECT_ROOT" | sed 's/^/codeo: /'
    exit 0
fi
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

if ((containers)); then
    [[ $owner != TODO-set-me ]] || codeo_die "--containers needs the repository's owner and name: add the origin remote, then run setup.sh --containers"
    if [[ -z $codename ]]; then
        codename=$(codeo_derive_codename "$name") || codeo_die "cannot derive a codename from '$name'; pass --codename <name>"
    fi
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
    write_pin
    run_containers
    codeo_home_lines "$codename" "$CODEO_PROJECT_ROOT" | sed 's/^/codeo: /'
fi
