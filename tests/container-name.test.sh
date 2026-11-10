#!/usr/bin/env bash
# Guards .devcontainer/scripts/container-name.sh, the one script that names a clone: "<codename> [home]"
# / "<codename>-home" with no workflow lock, "<codename> [#<N>]" / "<codename>-<N>" while .codeo/active
# holds issue N. Each case runs the real script copied into a scratch git repo whose .codeo/config.json
# names the codename "codeo": the home and lock names in both forms, a lock with a "#" or tabs, the
# first issue line winning, an unparsable lock reading as home, the codename falling back to the
# directory name, a subdirectory as the starting point, --codename, and the failure outside a repository.
#
#   bash tests/container-name.test.sh
#
# Exits 0 and prints "all cases passed" when every case holds; prints one "FAIL <case>: <detail>"
# line per problem and exits 1 otherwise.
set -euo pipefail

repo_root() { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; }
repo=$(repo_root)

failures=0
current=""
root=""
cn_dir=""
cn_rc=0
cn_out=""
cn_err=""

# fail <message>: record one failure against the running case.
fail() {
    printf 'FAIL %s: %s\n' "$current" "$1"
    failures=$((failures + 1))
}

# cn_setup <name> [config]: a scratch git repo holding the real script; config is the config.json text
# ("none" writes no config; default {"codename":"codeo"}). Sets cn_dir, the clone's root.
cn_setup() {
    local name=$1 config=${2-'{"codename":"codeo"}'}
    [[ -n $root ]] || root=$(mktemp -d)
    cn_dir="$root/$name"
    mkdir -p "$cn_dir/.devcontainer/scripts" "$cn_dir/.codeo" "$cn_dir/sub"
    git -C "$cn_dir" init -q || { fail 'git init failed'; return 1; }
    cp "$repo/.devcontainer/scripts/container-name.sh" "$cn_dir/.devcontainer/scripts/container-name.sh" \
        || { fail 'container-name.sh is missing'; return 1; }
    [[ $config == none ]] || printf '%s\n' "$config" > "$cn_dir/.codeo/config.json"
}

# cn_run [args]: runs the scratch copy of the script. Sets cn_rc, cn_out, cn_err.
cn_run() {
    local errf
    errf=$(mktemp -p "$root")
    cn_rc=0
    cn_out=$(bash "$cn_dir/.devcontainer/scripts/container-name.sh" "$@" 2>"$errf") || cn_rc=$?
    cn_err=$(cat "$errf")
}

# expect <got> <want> <what>
expect() { [[ $1 == "$2" ]] || fail "$3: wanted '$2', got '$1'"; }

# both <title> <docker>: the default and --docker output of the clone at $cn_dir.
both() {
    cn_run "$cn_dir"; expect "$cn_out" "$1" 'title'
    ((cn_rc == 0)) || fail "title exit $cn_rc: $cn_err"
    cn_run --docker "$cn_dir"; expect "$cn_out" "$2" 'docker name'
}

home_without_a_lock() {
    cn_setup home || return 0
    both 'codeo [home]' 'codeo-home'
}

lock_names_the_issue() {
    cn_setup lock || return 0
    printf 'issue:   55\nbranch: x\n' > "$cn_dir/.codeo/active"
    both 'codeo [#55]' 'codeo-55'
}

lock_tolerates_hash_and_tabs() {
    cn_setup hash || return 0
    printf 'issue:\t#7\n' > "$cn_dir/.codeo/active"
    both 'codeo [#7]' 'codeo-7'
}

first_issue_line_wins() {
    cn_setup first || return 0
    printf 'issue: 3\nissue: 9\n' > "$cn_dir/.codeo/active"
    both 'codeo [#3]' 'codeo-3'
}

unparsable_lock_is_home() {
    cn_setup bad || return 0
    printf 'issue: abc\n' > "$cn_dir/.codeo/active"
    both 'codeo [home]' 'codeo-home'
    printf 'branch: x\n' > "$cn_dir/.codeo/active"
    both 'codeo [home]' 'codeo-home'
}

codename_falls_back_to_the_directory() {
    cn_setup nocfg none || return 0
    both 'nocfg [home]' 'nocfg-home'
    cn_setup emptycfg '{}' || return 0
    both 'emptycfg [home]' 'emptycfg-home'
}

works_from_a_subdirectory() {
    cn_setup sub || return 0
    printf 'issue: 12\n' > "$cn_dir/.codeo/active"
    cn_run "$cn_dir/sub"; expect "$cn_out" 'codeo [#12]' 'title from sub'
    cn_run --docker "$cn_dir/sub"; expect "$cn_out" 'codeo-12' 'docker name from sub'
}

codename_flag_prints_the_codename() {
    cn_setup cflag || return 0
    printf 'issue: 4\n' > "$cn_dir/.codeo/active"
    cn_run --codename "$cn_dir"; expect "$cn_out" 'codeo' 'codename'
    cn_setup cflag2 none || return 0
    cn_run --codename "$cn_dir"; expect "$cn_out" 'cflag2' 'codename without config'
}

outside_a_repository_fails() {
    cn_setup outside || return 0
    local plain
    plain=$(mktemp -d -p "$root")
    cn_run "$plain"
    ((cn_rc == 1)) || fail "wanted exit 1, got $cn_rc"
    [[ -z $cn_out ]] || fail "wanted no stdout, got '$cn_out'"
    [[ $cn_err == container-name:* && $cn_err != *$'\n'* ]] || fail "wanted one 'container-name: ...' line, got '$cn_err'"
}

cases=(
    home_without_a_lock
    lock_names_the_issue
    lock_tolerates_hash_and_tabs
    first_issue_line_wins
    unparsable_lock_is_home
    codename_falls_back_to_the_directory
    works_from_a_subdirectory
    codename_flag_prints_the_codename
    outside_a_repository_fails
)

for current in "${cases[@]}"; do
    "$current"
done

[[ -z $root ]] || rm -rf "$root"

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
