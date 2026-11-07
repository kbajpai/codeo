#!/usr/bin/env bash
# Guards the development container (.devcontainer/) and the config that points at it. Each case is a
# function named in the final cases=( ... ) array; add a case by writing a function and listing it.
# Today it checks .codeo/config.json: the codename, the plugin pin, and that the shell suite's paths
# cover .devcontainer/**. It also checks .devcontainer/devcontainer.json: it is valid JSON that runs as
# the dev user and names the Dockerfile and start script, caps memory and cpus, mounts only the one
# named gh volume, and carries no bind mounts, secrets or localEnv. It also checks .devcontainer/Dockerfile
# (over its non-comment lines): Ubuntu 24.04 with the tools codeo needs, user dev at UID 1000 with the
# gh config directory, and none of the tools the image deliberately leaves out. Finally it runs
# .devcontainer/scripts/plugins.sh in a scratch repo against stub claude and git executables: a fresh
# machine gets both plugins, a re-run changes nothing, a new pin reinstalls codeo, an unreachable pin
# leaves the installed codeo alone, a missing pin fails, and a very long plugin list is read whole.
# Last it runs .devcontainer/scripts/devcontainer-start.sh in a scratch repo against stub gh, claude,
# sudo and stat executables and a stub plugins.sh: it always exits 0, lists each login still to do in
# order, says "ready" when nothing is left, and takes ownership of a clone owned by someone else.
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
    local code first tool
    code=$(dockerfile_code) || { fail 'Dockerfile is missing or unreadable'; return 0; }
    first=$(grep -m1 '^FROM ' <<<"$code" || true)
    [[ "$first" == 'FROM ubuntu:24.04' ]] || fail "first FROM is not ubuntu:24.04 (got: $first)"
    # git, jq and shellcheck must sit in the apt package list: a bare word, not part of a path or URL.
    for tool in git jq shellcheck; do
        if ! grep -qE "^[[:space:]]+[a-z0-9. -]*[[:space:]]$tool([[:space:]]|\\\\|$)" <<<"$code"; then
            fail "apt package list does not install $tool"
        fi
    done
    grep -q 'apt-get install .*[[:space:]]gh[[:space:]]*\\*$' <<<"$code" || fail 'no apt-get install of gh'
    grep -q 'https://cli.github.com/packages stable main' <<<"$code" || fail "gh's apt repository is not configured"
    grep -q 'curl -fsSL https://claude.ai/install.sh | bash -s latest' <<<"$code" || fail 'no Claude Code installer line'
    grep -q '&& claude --version$' <<<"$code" || fail 'no claude --version check after the install'
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

pl_root=""
cleanup() { [[ -z $pl_root ]] || rm -rf "$pl_root"; }
trap cleanup EXIT

# pl_setup <name> <config-plugin-json|none>: a scratch git repo holding plugins.sh and a config, with stub
# claude and git first on PATH. Sets pl_dir. State lives in $pl_dir/stub: `installed` (one name per line),
# `calls` (one line per claude call) and the marketplace file under $pl_dir/claude/plugins.
pl_setup() {
    local name=$1 plugin=$2 real_git
    [[ -n $pl_root ]] || pl_root=$(mktemp -d)
    pl_dir="$pl_root/$name"
    mkdir -p "$pl_dir/repo/.devcontainer/scripts" "$pl_dir/repo/.codeo" "$pl_dir/bin" "$pl_dir/stub" \
        "$pl_dir/claude/plugins" "$pl_dir/home"
    real_git=$(command -v git)
    git -C "$pl_dir/repo" init -q || { fail 'git init failed'; return 1; }
    cp "$repo/.devcontainer/scripts/plugins.sh" "$pl_dir/repo/.devcontainer/scripts/plugins.sh" \
        || { fail 'plugins.sh is missing'; return 1; }
    if [[ $plugin == none ]]; then
        echo '{"codename":"x"}' > "$pl_dir/repo/.codeo/config.json"
    else
        printf '{"codename":"x","plugin":%s}\n' "$plugin" > "$pl_dir/repo/.codeo/config.json"
    fi
    : > "$pl_dir/stub/installed"
    : > "$pl_dir/stub/calls"
    : > "$pl_dir/stub/pwds"
    mkdir -p "$pl_dir/repo/.claude"
    echo '{"enabledPlugins": {"codeo@codeo": true}}' > "$pl_dir/repo/.claude/settings.json"
    git -C "$pl_dir/repo" add -A
    git -C "$pl_dir/repo" -c user.name=Dev -c user.email=dev@example.com commit -q -m fixture \
        || { fail 'git commit failed'; return 1; }
    cat > "$pl_dir/bin/claude" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "$STUB_DIR/calls"
echo "$PWD" >> "$STUB_DIR/pwds"
market="$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json"
case "$1 $2 ${3:-}" in
    "plugin list "*)
        cat "$STUB_DIR/installed"
        if [[ -n ${STUB_BIG_LIST:-} ]]; then
            awk 'BEGIN { for (i = 1; i <= 20000; i++) printf "filler-plugin-%05d@some-marketplace-with-a-long-name\n", i }'
        fi ;;
    "plugin marketplace add")
        if [[ $4 == *@* ]]; then
            jq -n --arg r "${4#*@}" '{codeo: {source: {ref: $r}}}' > "$market"
        fi ;;
    "plugin marketplace remove")
        # The real CLI rewrites the project's settings when run inside a repository.
        if top=$(git rev-parse --show-toplevel 2>/dev/null) && [[ -f $top/.claude/settings.json ]]; then
            echo '{"enabledPlugins": {}}' > "$top/.claude/settings.json"
        fi
        rm -f "$market"
        grep -v "@$4\$" "$STUB_DIR/installed" > "$STUB_DIR/installed.new" || true
        mv "$STUB_DIR/installed.new" "$STUB_DIR/installed" ;;
    "plugin install "*) echo "$3" >> "$STUB_DIR/installed" ;;
    *) echo "stub claude: unexpected: $*" >&2; exit 1 ;;
esac
STUB
    cat > "$pl_dir/bin/git" <<STUB
#!/usr/bin/env bash
if [[ \${1:-} == ls-remote ]]; then exit "\${STUB_LS_REMOTE_RC:-0}"; fi
exec "$real_git" "\$@"
STUB
    chmod +x "$pl_dir/bin/claude" "$pl_dir/bin/git"
}

# pl_run: run the scratch plugins.sh; sets pl_err and pl_rc. STUB_* variables pass through.
pl_run() {
    pl_rc=0
    env PATH="$pl_dir/bin:$PATH" HOME="$pl_dir/home" CLAUDE_CONFIG_DIR="$pl_dir/claude" STUB_DIR="$pl_dir/stub" \
        bash "$pl_dir/repo/.devcontainer/scripts/plugins.sh" > "$pl_dir/out" 2> "$pl_dir/err" || pl_rc=$?
    pl_err=$(cat "$pl_dir/err")
}

# pl_calls_have <line>: a claude call equal to the whole line was made.
pl_calls_have() { grep -qxF -- "$1" "$pl_dir/stub/calls"; }

# pl_installed_codeo_at <ref>: codeo is installed with its marketplace pinned to the ref.
pl_installed_codeo_at() {
    echo 'codeo@codeo' >> "$pl_dir/stub/installed"
    jq -n --arg r "$1" '{codeo: {source: {ref: $r}}}' > "$pl_dir/claude/plugins/known_marketplaces.json"
}

pl_pin='{"repo":"kbajpai/codeo","ref":"v1.0.3"}'

plugins_fresh_machine_installs_both() {
    pl_setup fresh "$pl_pin" || return 0
    pl_run
    ((pl_rc == 0)) || fail "exit $pl_rc, stderr: $pl_err"
    pl_calls_have 'plugin marketplace add obra/superpowers-marketplace' || fail 'no marketplace add for superpowers'
    pl_calls_have 'plugin install superpowers@superpowers-marketplace --scope user' || fail 'no install of superpowers'
    pl_calls_have 'plugin marketplace add kbajpai/codeo@v1.0.3' || fail 'no marketplace add for codeo at the pin'
    pl_calls_have 'plugin install codeo@codeo --scope user' || fail 'no install of codeo'
}

plugins_rerun_changes_nothing() {
    local extra
    pl_setup rerun "$pl_pin" || return 0
    pl_run
    ((pl_rc == 0)) || fail "first run exit $pl_rc, stderr: $pl_err"
    : > "$pl_dir/stub/calls"
    pl_run
    ((pl_rc == 0)) || fail "second run exit $pl_rc, stderr: $pl_err"
    extra=$(grep -vxF 'plugin list' "$pl_dir/stub/calls" || true)
    [[ -z $extra ]] || fail "second run made calls other than plugin list: $extra"
    grep -q 'plugin list' "$pl_dir/stub/calls" || fail 'second run never asked what is installed'
}

plugins_ref_change_reinstalls_codeo() {
    local removed added
    pl_setup refchange "$pl_pin" || return 0
    echo 'superpowers@superpowers-marketplace' >> "$pl_dir/stub/installed"
    pl_installed_codeo_at v1.0.2
    pl_run
    ((pl_rc == 0)) || fail "exit $pl_rc, stderr: $pl_err"
    removed=$(grep -nxF 'plugin marketplace remove codeo' "$pl_dir/stub/calls" | head -n1 | cut -d: -f1 || true)
    added=$(grep -nxF 'plugin marketplace add kbajpai/codeo@v1.0.3' "$pl_dir/stub/calls" | head -n1 | cut -d: -f1 || true)
    [[ -n $removed ]] || fail 'no marketplace remove codeo'
    [[ -n $added ]] || fail 'no marketplace add at the new ref'
    if [[ -n $removed && -n $added ]] && ((removed >= added)); then
        fail 'marketplace remove did not come before the add'
    fi
    pl_calls_have 'plugin install codeo@codeo --scope user' || fail 'codeo was not reinstalled'
    ! pl_calls_have 'plugin install superpowers@superpowers-marketplace --scope user' || fail 'superpowers was reinstalled'
}

plugins_pin_change_leaves_tracked_files_alone() {
    local dirty inside
    pl_setup tracked "$pl_pin" || return 0
    echo 'superpowers@superpowers-marketplace' >> "$pl_dir/stub/installed"
    pl_installed_codeo_at v1.0.2
    pl_run
    ((pl_rc == 0)) || fail "exit $pl_rc, stderr: $pl_err"
    pl_calls_have 'plugin marketplace remove codeo' || fail 'no marketplace remove codeo'
    dirty=$(git -C "$pl_dir/repo" status --porcelain)
    [[ -z $dirty ]] || fail "a tracked file changed: $dirty"
    inside=$(grep -E "^$pl_dir/repo(/|\$)" "$pl_dir/stub/pwds" || true)
    [[ -z $inside ]] || fail "claude ran inside the repository: $inside"
}

plugins_matches_whole_plugin_names() {
    pl_setup wholenames "$pl_pin" || return 0
    printf '%s\n' 'xcodeo@codeo-fork' 'superpowers-extra@superpowers-marketplace-x' > "$pl_dir/stub/installed"
    # The marketplace is already at the pin, so only the installed-plugin check decides.
    jq -n '{codeo: {source: {ref: "v1.0.3"}}}' > "$pl_dir/claude/plugins/known_marketplaces.json"
    pl_run
    pl_calls_have 'plugin install codeo@codeo --scope user' || fail 'codeo@codeo-fork counted as codeo@codeo'
    pl_calls_have 'plugin install superpowers@superpowers-marketplace --scope user' \
        || fail 'a longer plugin name counted as superpowers'
}

plugins_offline_keeps_codeo() {
    pl_setup offline "$pl_pin" || return 0
    echo 'superpowers@superpowers-marketplace' >> "$pl_dir/stub/installed"
    pl_installed_codeo_at v1.0.2
    STUB_LS_REMOTE_RC=2 pl_run
    ((pl_rc == 1)) || fail "exit $pl_rc, wanted 1"
    grep -q 'v1.0.2' <<<"$pl_err" || fail "stderr does not name v1.0.2: $pl_err"
    grep -q 'stays' <<<"$pl_err" || fail "stderr does not say codeo stays: $pl_err"
    if grep -q 'marketplace remove' "$pl_dir/stub/calls"; then
        fail 'marketplace remove ran while offline'
    fi
    grep -qxF 'codeo@codeo' "$pl_dir/stub/installed" || fail 'codeo is no longer installed'
}

plugins_no_pin_fails() {
    pl_setup nopin none || return 0
    pl_run
    ((pl_rc == 1)) || fail "exit $pl_rc, wanted 1"
    grep -qF '.codeo/config.json has no plugin.repo and plugin.ref' <<<"$pl_err" \
        || fail "stderr does not explain the missing pin: $pl_err"
}

plugins_large_plugin_list_does_not_break_the_pipe() {
    pl_setup big "$pl_pin" || return 0
    printf '%s\n' 'superpowers@superpowers-marketplace' 'codeo@codeo' > "$pl_dir/stub/installed"
    jq -n '{codeo: {source: {ref: "v1.0.3"}}}' > "$pl_dir/claude/plugins/known_marketplaces.json"
    STUB_BIG_LIST=1 pl_run
    ((pl_rc == 0)) || fail "exit $pl_rc, stderr: $pl_err"
    if grep -q 'marketplace add' "$pl_dir/stub/calls"; then
        fail 'a plugin that was in the list was installed again'
    fi
}

# ds_setup <name>: a scratch git repo holding devcontainer-start.sh and a stub plugins.sh, with stub gh,
# claude, sudo and stat first on PATH and an empty global git config. Sets ds_dir. `calls` logs every
# stubbed gh setup-git and sudo call. A case sets STUB_* variables before ds_run: STUB_GH_RC, STUB_GH_OUT,
# STUB_CLAUDE_RC, STUB_PLUGINS_RC, STUB_STAT_UID (default: the real uid).
ds_setup() {
    local name=$1
    [[ -n $pl_root ]] || pl_root=$(mktemp -d)
    ds_dir="$pl_root/ds-$name"
    mkdir -p "$ds_dir/repo/.devcontainer/scripts" "$ds_dir/bin" "$ds_dir/home"
    git -C "$ds_dir/repo" init -q || { fail 'git init failed'; return 1; }
    cp "$repo/.devcontainer/scripts/devcontainer-start.sh" "$ds_dir/repo/.devcontainer/scripts/devcontainer-start.sh" \
        || { fail 'devcontainer-start.sh is missing'; return 1; }
    cat > "$ds_dir/repo/.devcontainer/scripts/plugins.sh" <<'STUB'
#!/usr/bin/env bash
exit "${STUB_PLUGINS_RC:-0}"
STUB
    : > "$ds_dir/calls"
    : > "$ds_dir/gitconfig"
    cat > "$ds_dir/bin/gh" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
    "auth status") printf '%s\n' "${STUB_GH_OUT:-}"; exit "${STUB_GH_RC:-1}" ;;
    "auth setup-git") echo "gh auth setup-git" >> "$STUB_DIR/calls" ;;
    *) echo "stub gh: unexpected: $*" >&2; exit 1 ;;
esac
STUB
    cat > "$ds_dir/bin/claude" <<'STUB'
#!/usr/bin/env bash
if [[ "$1 $2" == "auth status" ]]; then exit "${STUB_CLAUDE_RC:-1}"; fi
echo "stub claude: unexpected: $*" >&2; exit 1
STUB
    cat > "$ds_dir/bin/sudo" <<'STUB'
#!/usr/bin/env bash
echo "sudo $*" >> "$STUB_DIR/calls"
STUB
    cat > "$ds_dir/bin/stat" <<'STUB'
#!/usr/bin/env bash
echo "${STUB_STAT_UID:?}"
STUB
    chmod +x "$ds_dir/bin/gh" "$ds_dir/bin/claude" "$ds_dir/bin/sudo" "$ds_dir/bin/stat"
}

# ds_identity: give the scratch global git config a name and email.
ds_identity() { git config --file "$ds_dir/gitconfig" user.name Dev && git config --file "$ds_dir/gitconfig" user.email dev@example.com; }

# ds_run: run the scratch start script; sets ds_rc, ds_out and ds_err.
ds_run() {
    ds_rc=0
    env PATH="$ds_dir/bin:$PATH" HOME="$ds_dir/home" GIT_CONFIG_GLOBAL="$ds_dir/gitconfig" GIT_CONFIG_NOSYSTEM=1 \
        STUB_DIR="$ds_dir" STUB_STAT_UID="${STUB_STAT_UID:-$(id -u)}" \
        bash "$ds_dir/repo/.devcontainer/scripts/devcontainer-start.sh" > "$ds_dir/out" 2> "$ds_dir/err" || ds_rc=$?
    ds_out=$(cat "$ds_dir/out")
    ds_err=$(cat "$ds_dir/err")
}

# ds_todos <pattern>: how many TODO lines on stderr match the pattern.
ds_todos() { local n; n=$(grep -c "devcontainer-start: TODO.*$1" <<<"$ds_err" || true); echo "$n"; }

start_todo_when_nothing_is_set_up() {
    local n list want got
    ds_setup nothing || return 0
    STUB_PLUGINS_RC=1 ds_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    n=$(ds_todos 'gh auth login'); ((n == 1)) || fail "wanted one TODO for gh auth login, got $n: $ds_err"
    n=$(ds_todos 'git identity'); ((n == 1)) || fail "wanted one TODO for git identity, got $n: $ds_err"
    n=$(ds_todos 'claude auth login'); ((n == 1)) || fail "wanted one TODO for claude auth login, got $n: $ds_err"
    n=$(ds_todos 'plugins.sh'); ((n == 1)) || fail "wanted one TODO for plugins.sh, got $n: $ds_err"
    grep -qF 'devcontainer-start: what is left to do, in this order:' <<<"$ds_err" || fail "no numbered list heading: $ds_err"
    list=$(sed -n '/what is left to do, in this order:/,$p' <<<"$ds_err" | tail -n +2)
    got=$(sed -E 's/^[[:space:]]*[0-9]+\.[[:space:]]*//' <<<"$list" | paste -sd'|')
    want='gh auth login|gh auth refresh -s project|claude auth login|bash .devcontainer/scripts/devcontainer-start.sh'
    [[ $got == "$want" ]] || fail "numbered list is not in order: $got"
    if grep -qiE 'git (config|identity)|user\.(name|email)' <<<"$list"; then fail "git identity is in the numbered list: $list"; fi
}

start_ready_when_everything_is_set_up() {
    ds_setup ready || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    STUB_GH_RC=0 STUB_GH_OUT="Token scopes: 'repo', 'project'" STUB_CLAUDE_RC=0 ds_run
    ((ds_rc == 0)) || fail "exit $ds_rc, stderr: $ds_err"
    [[ $(tail -n1 <<<"$ds_out") == 'devcontainer-start: ready' ]] || fail "stdout does not end with ready: $ds_out"
    [[ -z $ds_err ]] || fail "stderr is not empty: $ds_err"
    grep -qxF 'gh auth setup-git' "$ds_dir/calls" || fail 'gh auth setup-git was not run'
    if grep -q '^sudo' "$ds_dir/calls"; then fail 'sudo ran for a clone we own'; fi
}

start_project_scope_missing_is_a_todo() {
    local n
    ds_setup scope || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    STUB_GH_RC=0 STUB_GH_OUT="Token scopes: 'repo'" STUB_CLAUDE_RC=0 ds_run
    ((ds_rc == 0)) || fail "exit $ds_rc, stderr: $ds_err"
    n=$(ds_todos 'gh auth refresh -s project'); ((n == 1)) || fail "wanted one TODO for the project scope, got $n: $ds_err"
    n=$(ds_todos 'gh auth login'); ((n == 0)) || fail "asked to log in again although logged in: $ds_err"
    grep -qxF 'gh auth setup-git' "$ds_dir/calls" || fail 'gh auth setup-git was not run'
    if grep -qF 'devcontainer-start: ready' <<<"$ds_out"; then fail 'said ready with the project scope missing'; fi
}

start_plugins_failure_is_a_todo_not_a_failure() {
    local n
    ds_setup plugins || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    STUB_PLUGINS_RC=1 STUB_GH_RC=0 STUB_GH_OUT="'project'" STUB_CLAUDE_RC=0 ds_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    n=$(ds_todos 'plugins.sh'); ((n == 1)) || fail "wanted one TODO naming plugins.sh, got $n: $ds_err"
    grep -qxF 'gh auth setup-git' "$ds_dir/calls" || fail 'later steps did not run after plugins.sh failed'
    if grep -qF 'devcontainer-start: ready' <<<"$ds_out"; then fail 'said ready with plugins.sh failed'; fi
}

start_takes_ownership_of_a_root_owned_clone() {
    local mine other parent line
    ds_setup owner || return 0
    mine=$(id -u)
    other=$((mine + 1))
    parent="$ds_dir"
    STUB_STAT_UID=$other ds_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    line=$(grep '^sudo chown -R ' "$ds_dir/calls" || true)
    [[ -n $line ]] || fail 'no sudo chown -R for a clone owned by another uid'
    [[ $line == *" $parent" ]] || fail "chown was not on the clone's parent directory $parent: $line"
    : > "$ds_dir/calls"
    STUB_STAT_UID=$mine ds_run
    if grep -q '^sudo' "$ds_dir/calls"; then fail 'sudo ran although the clone is ours'; fi
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
    plugins_fresh_machine_installs_both
    plugins_rerun_changes_nothing
    plugins_ref_change_reinstalls_codeo
    plugins_pin_change_leaves_tracked_files_alone
    plugins_matches_whole_plugin_names
    plugins_offline_keeps_codeo
    plugins_no_pin_fails
    plugins_large_plugin_list_does_not_break_the_pipe
    start_todo_when_nothing_is_set_up
    start_ready_when_everything_is_set_up
    start_project_scope_missing_is_a_todo
    start_plugins_failure_is_a_todo_not_a_failure
    start_takes_ownership_of_a_root_owned_clone
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
