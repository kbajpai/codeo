#!/usr/bin/env bash
# Exercises lib/env.sh and scripts/config.sh against scratch git repos: root resolution from the
# caller's cwd, and every refusal path naming the file or key at fault. HOME is pointed at a
# scratch directory so nothing real is read or written.
#
#   env.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config_sh="$plugin_root/scripts/config.sh"

scratch_root=$(mktemp -d)
trap 'chmod -R u+w "$scratch_root" 2>/dev/null || true; rm -rf "$scratch_root"' EXIT
export HOME="$scratch_root/home"
mkdir -p "$HOME"

fail() { echo "FAIL: $1" >&2; exit 1; }

# A scratch repo; prints its path. $1 = config.json content ("" for none).
make_repo() {
    local dir
    dir=$(mktemp -d "$scratch_root/repo.XXXXXX")
    git -C "$dir" init -q
    if [[ -n "${1:-}" ]]; then
        mkdir -p "$dir/.codeo"
        printf '%s\n' "$1" > "$dir/.codeo/config.json"
    fi
    echo "$dir"
}

good='{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}'

resolves_project_root_from_a_subdirectory() {
    local repo; repo=$(make_repo "$good")
    mkdir -p "$repo/a/b"
    local out
    out=$(cd "$repo/a/b" && bash -c "source '$plugin_root/lib/env.sh'; echo \"\$CODEO_PROJECT_ROOT|\$CODEO_STATE_DIR|\$CODEO_PLUGIN_ROOT|\$CODEO_SCHEMA|\$(codeo_base_branch)\"")
    local real; real=$(cd "$repo" && pwd -P)
    [[ "$out" == "$real|$real/.codeo|$plugin_root|1|main" ]] || fail "unexpected: $out"
}

missing_config_names_the_file() {
    local repo; repo=$(make_repo "")
    local err
    if err=$(cd "$repo" && bash "$config_sh" validate 2>&1); then fail "expected refusal"; fi
    [[ "$err" == *"config.json"* ]] || fail "no file named: $err"
}

invalid_json_names_the_file() {
    local repo; repo=$(make_repo "{not json")
    local err
    if err=$(cd "$repo" && bash "$config_sh" get .baseBranch 2>&1); then fail "expected refusal"; fi
    [[ "$err" == *"config.json"*"invalid JSON"* ]] || fail "unexpected: $err"
}

newer_schema_is_refused_naming_both_numbers() {
    local repo; repo=$(make_repo '{"schema":7,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}')
    local err
    if err=$(cd "$repo" && bash "$config_sh" validate 2>&1); then fail "expected refusal"; fi
    [[ "$err" == "codeo: config.json: schema 7 is newer than this plugin supports (1); update the plugin" ]] || fail "unexpected: $err"
}

missing_base_branch_names_the_key() {
    local repo; repo=$(make_repo '{"schema":1,"repo":{"owner":"o","name":"n"}}')
    local err
    if err=$(cd "$repo" && bash "$config_sh" validate 2>&1); then fail "expected refusal"; fi
    [[ "$err" == *"baseBranch"* ]] || fail "key not named: $err"
    if err=$(cd "$repo" && bash -c "source '$plugin_root/lib/env.sh'; codeo_base_branch" 2>&1); then fail "expected die"; fi
    [[ "$err" == *"config.json: missing .baseBranch"* ]] || fail "unexpected: $err"
}

optional_key_is_empty_with_exit_1_and_get_works() {
    local repo; repo=$(make_repo "$good")
    local out rc=0
    out=$(cd "$repo" && bash -c "source '$plugin_root/lib/env.sh'; codeo_cfg .board.owner") || rc=$?
    [[ "$rc" -eq 1 && -z "$out" ]] || fail "absent key: rc=$rc out=$out"
    out=$(cd "$repo" && bash "$config_sh" get .repo.name)
    [[ "$out" == "n" ]] || fail "get: $out"
}

no_write_outside_project_or_secrets_dir() {
    local repo; repo=$(make_repo "$good")
    local ro="$scratch_root/ro-home"
    mkdir -p "$ro"; chmod a-w "$ro"
    (cd "$repo" && HOME="$ro" bash "$config_sh" validate >/dev/null) || fail "validate failed under read-only HOME"
    [[ -z "$(ls -A "$ro")" ]] || fail "wrote into HOME"
    [[ -z "$(git -C "$repo" status --porcelain --ignored | grep -v '.codeo/config.json\|?? .codeo/' || true)" ]] || fail "wrote into repo"
    chmod u+w "$ro"
}

# Each failure path must print exactly one "codeo:" line, naming the file, with no jq text leaking.
one_line_failures() {
    local label="$1" dir="$2" needle="$3" cmd err
    for cmd in "get .schema" "validate"; do
        if err=$(cd "$dir" && bash "$config_sh" $cmd 2>&1); then fail "$label/$cmd: expected refusal"; fi
        [[ "$(printf '%s\n' "$err" | wc -l)" -eq 1 ]] || fail "$label/$cmd: not one line: $err"
        [[ "$err" == codeo:* && "$err" != *jq:* && "$err" == *"$needle"* ]] || fail "$label/$cmd: unexpected: $err"
    done
}

failures_print_exactly_one_line() {
    one_line_failures missing "$(make_repo "")" "config.json not found"
    one_line_failures invalid "$(make_repo "{not json")" "invalid JSON"
    local nogit; nogit=$(mktemp -d "$scratch_root/nogit.XXXXXX")
    one_line_failures nogit "$nogit" "not inside a git repository"
}

for c in failures_print_exactly_one_line resolves_project_root_from_a_subdirectory missing_config_names_the_file \
    invalid_json_names_the_file newer_schema_is_refused_naming_both_numbers \
    missing_base_branch_names_the_key optional_key_is_empty_with_exit_1_and_get_works \
    no_write_outside_project_or_secrets_dir; do
    "$c"
done
echo "all cases passed"
