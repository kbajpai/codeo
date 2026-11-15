#!/usr/bin/env bash
# Guards .devcontainer/scripts/codeo-root.sh, which prints the root of the installed codeo plugin.
# Each case runs the real script with a scratch HOME / CLAUDE_CONFIG_DIR and a fake plugin root that
# holds scripts/lock.sh: the CODEO_ROOT override, a bad override that must not fall through to the
# registry, the registry installPath, a registry path without lock.sh, and no registry at all.
# The script runs from a scratch git clone, so its root is known: an entry whose projectPath is that clone
# wins over one with no projectPath, and an entry for another project is never taken.
#
#   bash tests/codeo-root.test.sh
#
# Exits 0 and prints "all cases passed" when every case holds; prints one "FAIL <case>: <detail>"
# line per problem and exits 1 otherwise.
set -euo pipefail

repo_root() { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; }
repo=$(repo_root)
script="$repo/.devcontainer/scripts/codeo-root.sh"

failures=0
current=""
root=""
cr_rc=0
cr_out=""
cr_err=""
cr_clone=""

# fail <message>: record one failure against the running case.
fail() {
    printf 'FAIL %s: %s\n' "$current" "$1"
    failures=$((failures + 1))
}

# plugin <name> [with_lock]: a fake plugin root under the scratch dir; prints its path.
plugin() {
    local dir="$root/$1"
    mkdir -p "$dir/scripts"
    [[ ${2:-lock} == nolock ]] || : > "$dir/scripts/lock.sh"
    printf '%s' "$dir"
}

# registry <entry>...: writes a plugin registry into the scratch config dir, one entry per argument in order;
# each is "installPath" (no projectPath) or "installPath|projectPath"; an empty installPath is JSON null.
registry() {
    mkdir -p "$root/cfg/plugins"
    printf '%s\n' "$@" | jq -R -s '{plugins: {"codeo@codeo": (split("\n") | map(select(. != "") | split("|")
        | {installPath: (if .[0] == "" then null else .[0] end)}
            + (if length > 1 then {projectPath: .[1]} else {} end)))}}' \
        > "$root/cfg/plugins/installed_plugins.json"
}

# cr_run [CODEO_ROOT]: runs the script with the scratch config dir. Sets cr_rc, cr_out, cr_err.
cr_run() {
    local errf
    errf=$(mktemp -p "$root")
    cr_rc=0
    cr_out=$(env -u CODEO_ROOT ${1:+CODEO_ROOT="$1"} HOME="$root/home" CLAUDE_CONFIG_DIR="$root/cfg" \
        bash "$cr_clone/.devcontainer/scripts/codeo-root.sh" 2>"$errf") || cr_rc=$?
    cr_err=$(cat "$errf")
}

# fails_cleanly: exit 1, no stdout, one "codeo-root:" stderr line.
fails_cleanly() {
    ((cr_rc == 1)) || fail "wanted exit 1, got $cr_rc"
    [[ -z $cr_out ]] || fail "wanted no stdout, got '$cr_out'"
    [[ $cr_err == codeo-root:* && $cr_err != *$'\n'* ]] || fail "wanted one 'codeo-root: ...' line, got '$cr_err'"
}

# setup: a scratch dir and a scratch git clone holding a copy of the script; cr_clone is its physical path.
setup() {
    root=$(mktemp -d)
    mkdir -p "$root/clone/.devcontainer/scripts"
    git -C "$root/clone" init -q
    cp "$script" "$root/clone/.devcontainer/scripts/codeo-root.sh"
    cr_clone=$(cd "$root/clone" && pwd -P)
}
teardown() { rm -rf "$root"; root=""; }

override_wins() {
    setup
    local want other
    want=$(plugin override)
    other=$(plugin installed)
    registry "$other"
    cr_run "$want"
    ((cr_rc == 0)) || fail "exit $cr_rc: $cr_err"
    [[ $cr_out == "$want" ]] || fail "wanted '$want', got '$cr_out'"
    teardown
}

bad_override_fails_without_falling_through() {
    setup
    registry "$(plugin installed)"
    cr_run "$(plugin empty nolock)"
    fails_cleanly
    teardown
}

registry_install_path() {
    setup
    local want
    want=$(plugin installed)
    registry "$want"
    cr_run
    ((cr_rc == 0)) || fail "exit $cr_rc: $cr_err"
    [[ $cr_out == "$want" ]] || fail "wanted '$want', got '$cr_out'"
    teardown
}

registry_path_without_lock_sh_fails() {
    setup
    registry "$(plugin installed nolock)"
    cr_run
    fails_cleanly
    teardown
}

other_projects_entry_first_is_skipped() {
    setup
    local first want
    first=$(plugin first); want=$(plugin second)
    registry "$first|/somewhere/else" "$want"
    cr_run
    ((cr_rc == 0)) || fail "exit $cr_rc: $cr_err"
    [[ $cr_out == "$want" ]] || fail "wanted '$want', got '$cr_out'"
    teardown
}

this_projects_entry_wins_over_a_user_entry() {
    setup
    local user want
    user=$(plugin user); want=$(plugin mine)
    registry "$user" "$want|$cr_clone"
    cr_run
    ((cr_rc == 0)) || fail "exit $cr_rc: $cr_err"
    [[ $cr_out == "$want" ]] || fail "wanted '$want', got '$cr_out'"
    teardown
}

only_another_projects_entry_fails() {
    setup
    registry "$(plugin other)|/somewhere/else"
    cr_run
    fails_cleanly
    teardown
}

outside_a_git_clone_only_user_entries_qualify() {
    setup
    local want
    want=$(plugin user)
    registry "$(plugin other)|/somewhere/else" "$want"
    rm -rf "$root/clone/.git"
    GIT_CEILING_DIRECTORIES="$root" cr_run
    ((cr_rc == 0)) || fail "exit $cr_rc: $cr_err"
    [[ $cr_out == "$want" ]] || fail "wanted '$want', got '$cr_out'"
    registry "$(plugin other2)|/somewhere/else"
    GIT_CEILING_DIRECTORIES="$root" cr_run
    fails_cleanly
    teardown
}

# registry_expect <want>: runs the script and expects <want> on stdout, exit 0.
registry_expect() {
    cr_run
    ((cr_rc == 0)) || fail "exit $cr_rc: $cr_err"
    [[ $cr_out == "$1" ]] || fail "wanted '$1', got '$cr_out'"
}

registry_matches_a_project_path_with_a_trailing_slash() {
    setup
    local want
    want=$(plugin mine)
    registry "$(plugin user)" "$want|$cr_clone/"
    registry_expect "$want"
    teardown
}

registry_matches_a_symlinked_project_path() {
    setup
    local want
    want=$(plugin mine)
    ln -s "$cr_clone" "$root/link"
    registry "$(plugin user)" "$want|$root/link"
    registry_expect "$want"
    teardown
}

registry_skips_a_null_install_path_for_this_clone() {
    setup
    local want
    want=$(plugin mine)
    registry "|$cr_clone" "$(plugin user)" "$want|$cr_clone"
    registry_expect "$want"
    teardown
}

registry_survives_a_project_path_that_no_longer_exists() {
    setup
    local want
    want=$(plugin user)
    registry "$(plugin gone)|$root/missing" "$want"
    registry_expect "$want"
    teardown
}

no_registry_fails() {
    setup
    cr_run
    fails_cleanly
    teardown
}

cases=(
    override_wins
    bad_override_fails_without_falling_through
    registry_install_path
    registry_path_without_lock_sh_fails
    other_projects_entry_first_is_skipped
    this_projects_entry_wins_over_a_user_entry
    only_another_projects_entry_fails
    registry_matches_a_project_path_with_a_trailing_slash
    registry_matches_a_symlinked_project_path
    registry_skips_a_null_install_path_for_this_clone
    registry_survives_a_project_path_that_no_longer_exists
    outside_a_git_clone_only_user_entries_qualify
    no_registry_fails
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
