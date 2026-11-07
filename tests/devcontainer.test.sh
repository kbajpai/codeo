#!/usr/bin/env bash
# Guards the development container (.devcontainer/) and the config that points at it. Each case is a
# function named in the final cases=( ... ) array; add a case by writing a function and listing it.
# Today it checks .codeo/config.json: the codename, the plugin pin, and that the shell suite's paths
# cover .devcontainer/**.
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

cases=(
    config_has_codename_pin_and_suite_path
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
