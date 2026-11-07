#!/usr/bin/env bash
# Guards the development container (.devcontainer/) and the config that points at it. Each case is a
# function named in the final cases=( ... ) array; add a case by writing a function and listing it.
# Today it checks .codeo/config.json: the codename, the plugin pin, and that the shell suite's paths
# cover .devcontainer/**. It also checks .devcontainer/devcontainer.json: it is valid JSON that runs as
# the dev user and names the Dockerfile and start script, caps memory and cpus, mounts only the one
# named gh volume, and carries no bind mounts, secrets or localEnv. It also checks .devcontainer/Dockerfile
# (over its non-comment lines): Ubuntu 24.04 with the tools codeo needs, user dev at UID 1000 with the
# gh config directory, and none of the tools the image deliberately leaves out.
#
#   bash tests/devcontainer.test.sh
#
# Exits 0 and prints "all cases passed" when every case holds; prints one "FAIL <case>: <detail>"
# line per problem and exits 1 otherwise.
set -euo pipefail

repo_root() { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; }
repo=$(repo_root)

failures=0
current=""

# fail <message>: record one failure against the running case.
fail() {
    printf 'FAIL %s: %s\n' "$current" "$1"
    failures=$((failures + 1))
}

config_has_codename_pin_and_suite_path() {
    local cfg="$repo/.codeo/config.json"
    jq -e '.codename == "codeo"' "$cfg" >/dev/null || fail 'codename is not "codeo"'
    jq -e '.plugin.repo == "kbajpai/codeo"' "$cfg" >/dev/null || fail 'plugin.repo is not kbajpai/codeo'
    jq -e '.plugin.ref == "v1.0.3"' "$cfg" >/dev/null || fail 'plugin.ref is not v1.0.3'
    jq -e '.suites[] | select(.name == "shell") | .paths | index(".devcontainer/**")' "$cfg" >/dev/null \
        || fail 'shell suite paths lack .devcontainer/**'
}

dc_json() { printf '%s' "$repo/.devcontainer/devcontainer.json"; }

devcontainer_json_is_valid_and_runs_as_dev() {
    local f
    f=$(dc_json)
    jq -e . "$f" >/dev/null || fail 'devcontainer.json is missing or not valid JSON'
    jq -e '.remoteUser == "dev"' "$f" >/dev/null || fail 'remoteUser is not "dev"'
    jq -e '.build.dockerfile == "Dockerfile"' "$f" >/dev/null || fail 'build.dockerfile is not "Dockerfile"'
    jq -e '.postCreateCommand == "bash .devcontainer/scripts/devcontainer-start.sh"' "$f" >/dev/null \
        || fail 'postCreateCommand does not run devcontainer-start.sh'
}

run_args_cap_memory_and_cpus() {
    jq -e '.runArgs == ["--memory=4g","--cpus=2"]' "$(dc_json)" >/dev/null \
        || fail 'runArgs is not ["--memory=4g","--cpus=2"]'
}

gh_login_is_one_named_volume() {
    jq -e '.mounts == ["source=codeo-gh,target=/home/dev/.config/gh,type=volume"]' "$(dc_json)" >/dev/null \
        || fail 'mounts is not the single codeo-gh volume at /home/dev/.config/gh'
}

no_bind_mounts_or_secrets() {
    local f text word
    f=$(dc_json)
    text=$(cat "$f") || { fail 'devcontainer.json is unreadable'; return 0; }
    for word in type=bind secrets localEnv; do
        if grep -q -- "$word" <<<"$text"; then
            fail "devcontainer.json contains $word"
        fi
    done
}

# dockerfile_code: the Dockerfile with comment lines (first non-blank character #) removed.
dockerfile_code() {
    local f="$repo/.devcontainer/Dockerfile"
    [[ -r "$f" ]] || return 1
    grep -v '^[[:space:]]*#' "$f" || true
}

dockerfile_is_ubuntu_2404_with_the_tools() {
    local code first word
    code=$(dockerfile_code) || { fail 'Dockerfile is missing or unreadable'; return 0; }
    first=$(grep -m1 '^FROM ' <<<"$code" || true)
    [[ "$first" == 'FROM ubuntu:24.04' ]] || fail "first FROM is not ubuntu:24.04 (got: $first)"
    for word in jq shellcheck git gh 'https://claude.ai/install.sh'; do
        if ! grep -qw -- "$word" <<<"$code"; then
            fail "Dockerfile does not mention $word"
        fi
    done
}

dockerfile_creates_dev_uid_1000_and_the_gh_dir() {
    local code
    code=$(dockerfile_code) || { fail 'Dockerfile is missing or unreadable'; return 0; }
    grep -q '^ARG USER_UID=1000$' <<<"$code" || fail 'no ARG USER_UID=1000'
    grep -q '^ARG USERNAME=dev$' <<<"$code" || fail 'no ARG USERNAME=dev'
    grep -q 'userdel.* ubuntu' <<<"$code" || fail 'no userdel of the ubuntu user'
    grep -q 'install -d -o.*\.config/gh' <<<"$code" || fail 'no install -d -o for .config/gh'
}

dockerfile_has_none_of_the_excluded_tools() {
    local code hit
    code=$(dockerfile_code) || { fail 'Dockerfile is missing or unreadable'; return 0; }
    hit=$(grep -iE 'dotnet|nodejs|npm|terraform|google-cloud|gcloud|postgresql|kubectl|docker\.io|docker-ce' <<<"$code" || true)
    if [[ -n "$hit" ]]; then
        fail "Dockerfile names an excluded tool: $hit"
    fi
}

cases=(
    config_has_codename_pin_and_suite_path
    devcontainer_json_is_valid_and_runs_as_dev
    run_args_cap_memory_and_cpus
    gh_login_is_one_named_volume
    no_bind_mounts_or_secrets
    dockerfile_is_ubuntu_2404_with_the_tools
    dockerfile_creates_dev_uid_1000_and_the_gh_dir
    dockerfile_has_none_of_the_excluded_tools
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
