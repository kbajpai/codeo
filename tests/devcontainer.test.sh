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
# The devcontainer.json checks also cover the postStartCommand that re-runs window-title.sh (the
# window title) on every start; the start script's login checks are the ones listed just above.
# It also runs .devcontainer/scripts/session-title.sh against hook fixtures on stdin (home and lock titles,
# the prompt hook, an existing title kept, silent outside a dev container and on every failure) and
# checks that .claude/settings.json registers it. It also checks the scripts are committed executable, the
# settings-merge cases (not an object, symlink, mode, no temp file), the credential-variable advice, the
# core.fileMode probe, the prompt hook's retitling, the guarded hook command and the codeo-git volume.
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
    jq -e '.plugin.ref | type == "string" and length > 0 and test("^\\S+$")' "$cfg" >/dev/null \
        || fail 'plugin.ref is not a non-empty string without whitespace'
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

post_start_command_reruns_the_title() {
    jq -e '.postStartCommand == "bash .devcontainer/scripts/window-title.sh || true"' "$(dc_json)" >/dev/null \
        || fail 'postStartCommand is not "bash .devcontainer/scripts/window-title.sh || true"'
}

volumes_hold_the_gh_login_and_the_git_config() {
    jq -e '.mounts == ["source=codeo-gh,target=/home/dev/.config/gh,type=volume","source=codeo-git,target=/home/dev/.config/git,type=volume"]' "$(dc_json)" >/dev/null \
        || fail 'mounts is not the codeo-gh volume at /home/dev/.config/gh then the codeo-git volume at /home/dev/.config/git'
}

git_config_global_points_into_the_git_volume() {
    jq -e '.containerEnv == {"GIT_CONFIG_GLOBAL":"/home/dev/.config/git/config"}' "$(dc_json)" >/dev/null \
        || fail 'containerEnv is not {"GIT_CONFIG_GLOBAL":"/home/dev/.config/git/config"}'
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

dockerfile_creates_the_git_config_dir() {
    local code
    code=$(dockerfile_code) || { fail 'Dockerfile is missing or unreadable'; return 0; }
    grep -q 'install -d -o.*\.config/git' <<<"$code" || fail 'no install -d -o for .config/git'
}

# With GIT_CONFIG_GLOBAL set, git --global writes there and leaves an existing ~/.gitconfig alone.
git_global_writes_land_in_the_volume_file() {
    local h
    h=$(mktemp -d) || { fail 'mktemp failed'; return 0; }
    mkdir -p "$h/.config/git"
    : > "$h/.gitconfig"
    HOME="$h" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$h/.config/git/config" git config --global user.name X \
        || fail 'git config --global failed'
    [[ $(git config --file "$h/.config/git/config" user.name 2>/dev/null || true) == X ]] || fail 'user.name did not land in the volume file'
    [[ ! -s "$h/.gitconfig" ]] || fail 'the home .gitconfig was written to'
    rm -rf "$h"
}

dockerfile_has_none_of_the_excluded_tools() {
    local code hit
    code=$(dockerfile_code) || { fail 'Dockerfile is missing or unreadable'; return 0; }
    hit=$(grep -iE 'dotnet|nodejs|npm|terraform|google-cloud|gcloud|postgresql|kubectl|docker\.io|docker-ce' <<<"$code" || true)
    if [[ -n "$hit" ]]; then
        fail "Dockerfile names an excluded tool: $hit"
    fi
}

# dockerfile_env_lines: every ENV instruction in the Dockerfile with its continuation lines, comments dropped.
dockerfile_env_lines() {
    dockerfile_code | awk '/^[[:space:]]*ENV[[:space:]]/ {on=1} on {print} on && !/\\[[:space:]]*$/ {on=0}'
}

dockerfile_env_uses_the_username_arg() {
    local env
    dockerfile_code >/dev/null || { fail 'Dockerfile is missing or unreadable'; return 0; }
    env=$(dockerfile_env_lines)
    if grep -q '/home/dev' <<<"$env"; then
        fail 'an ENV line hard-codes /home/dev'
    fi
    # shellcheck disable=SC2016  # the literal ${USERNAME} text is what is being matched
    grep -q 'CLAUDE_CONFIG_DIR=/home/${USERNAME}/\.claude' <<<"$env" || fail 'CLAUDE_CONFIG_DIR is not /home/${USERNAME}/.claude'
}

dockerfile_does_not_create_workspaces() {
    local hit
    hit=$(dockerfile_code | grep '/workspaces' || true)
    if [[ -n "$hit" ]]; then
        fail "Dockerfile mentions /workspaces: $hit"
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
# STUB_CLAUDE_RC, STUB_CLAUDE_OUT, STUB_PLUGINS_RC, STUB_SETUP_GIT_RC, STUB_STAT_UID (default: the real uid), CODEO_MOUNTINFO.
ds_setup() {
    local name=$1
    [[ -n $pl_root ]] || pl_root=$(mktemp -d)
    ds_dir="$pl_root/ds-$name"
    mkdir -p "$ds_dir/repo/.devcontainer/scripts" "$ds_dir/bin" "$ds_dir/home"
    git -C "$ds_dir/repo" init -q || { fail 'git init failed'; return 1; }
    cp "$repo/.devcontainer/scripts/devcontainer-start.sh" "$ds_dir/repo/.devcontainer/scripts/devcontainer-start.sh" \
        || { fail 'devcontainer-start.sh is missing'; return 1; }
    cp "$repo/.devcontainer/scripts/window-title.sh" "$ds_dir/repo/.devcontainer/scripts/window-title.sh" \
        || { fail 'window-title.sh is missing'; return 1; }
    mkdir -p "$ds_dir/repo/.codeo"
    echo '{"codename":"codeo"}' > "$ds_dir/repo/.codeo/config.json"
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
    "auth setup-git") echo "gh auth setup-git" >> "$STUB_DIR/calls"; exit "${STUB_SETUP_GIT_RC:-0}" ;;
    *) echo "stub gh: unexpected: $*" >&2; exit 1 ;;
esac
STUB
    cat > "$ds_dir/bin/claude" <<'STUB'
#!/usr/bin/env bash
if [[ "$1 $2" == "auth status" ]]; then
    printf '%s' "${STUB_CLAUDE_OUT:-}"
    exit "${STUB_CLAUDE_RC:-1}"
fi
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

# ds_run: run the scratch start script (through $DS_REPO when set, else the repo itself); sets ds_rc, ds_out and ds_err.
ds_run() {
    ds_rc=0
    env -u CLAUDE_CODE_OAUTH_TOKEN -u ANTHROPIC_API_KEY -u ANTHROPIC_BASE_URL \
        ${DS_SET:+"$DS_SET"} \
        PATH="$ds_dir/bin:$PATH" HOME="$ds_dir/home" CLAUDE_CONFIG_DIR="$ds_dir/claude" GIT_CONFIG_GLOBAL="${DS_GITCONFIG:-$ds_dir/gitconfig}" GIT_CONFIG_NOSYSTEM=1 \
        STUB_DIR="$ds_dir" STUB_STAT_UID="${STUB_STAT_UID:-$(id -u)}" \
        ${CODEO_MOUNTINFO:+CODEO_MOUNTINFO="$CODEO_MOUNTINFO"} \
        bash "${DS_REPO:-$ds_dir/repo}/.devcontainer/scripts/devcontainer-start.sh" > "$ds_dir/out" 2> "$ds_dir/err" || ds_rc=$?
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
    want='gh auth login -s project|claude auth login|bash .devcontainer/scripts/devcontainer-start.sh'
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

# ds_mountinfo <root> <mountpoint>...: write a stub mountinfo file with one line per (root, mountpoint) pair
# and set CODEO_MOUNTINFO to it.
ds_mountinfo() {
    local f="$ds_dir/mountinfo" id=100
    : > "$f"
    while (($# >= 2)); do
        echo "$id 90 0:50 $1 $2 rw,relatime - ext4 /dev/sda1 rw" >> "$f"
        id=$((id + 1))
        shift 2
    done
    CODEO_MOUNTINFO=$f
}

ds_sudo_calls() { grep -c '^sudo' "$ds_dir/calls" || true; }
ds_safe_dir_set() { git config --file "$ds_dir/gitconfig" --get-all safe.directory | grep -qxF -- "$1"; }

start_chowns_the_clone_on_a_named_volume() {
    local mine other clone
    ds_setup volume || return 0
    mine=$(id -u); other=$((mine + 1)); clone="$ds_dir/repo"
    ds_mountinfo /var/lib/docker/volumes/v1/_data "$clone"
    STUB_STAT_UID=$other ds_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    grep -qxF "sudo chown -R $mine:$(id -g) $clone" "$ds_dir/calls" || fail "no chown of the clone: $(cat "$ds_dir/calls")"
    if grep -qxF "sudo chown -R $mine:$(id -g) $ds_dir" "$ds_dir/calls"; then fail "sudo named the clone's parent: $(cat "$ds_dir/calls")"; fi
    ds_safe_dir_set "$clone" || fail 'safe.directory was not set'
}

start_never_chowns_a_bind_mount() {
    local mine other n
    ds_setup bind || return 0
    mine=$(id -u); other=$((mine + 1))
    ds_mountinfo /home/u/src/codeo "$ds_dir/repo"
    STUB_STAT_UID=$other ds_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    n=$(ds_sudo_calls); ((n == 0)) || fail "sudo ran for a bind mount: $(cat "$ds_dir/calls")"
    n=$(ds_todos 'not on a Docker volume'); ((n == 1)) || fail "wanted one bind-mount TODO, got $n: $ds_err"
    ds_safe_dir_set "$ds_dir/repo" || fail 'safe.directory was not set'
}

start_longest_mount_wins() {
    local mine other n
    ds_setup longest || return 0
    mine=$(id -u); other=$((mine + 1))
    ds_mountinfo /home/u/src "$(dirname "$ds_dir")" /var/lib/docker/volumes/v1/_data "$ds_dir/repo"
    STUB_STAT_UID=$other ds_run
    n=$(ds_sudo_calls); ((n == 1)) || fail "volume under a bind mount: wanted one chown, got $n: $(cat "$ds_dir/calls")"
    ds_mountinfo /var/lib/docker/volumes/v1/_data "$(dirname "$ds_dir")" /home/u/src/codeo "$ds_dir/repo"
    : > "$ds_dir/calls"
    STUB_STAT_UID=$other ds_run
    n=$(ds_sudo_calls); ((n == 0)) || fail "bind mount under a volume: wanted no chown, got $n: $(cat "$ds_dir/calls")"
}

start_own_clone_runs_nothing_privileged() {
    local n
    ds_setup own || return 0
    ds_mountinfo /var/lib/docker/volumes/v1/_data "$ds_dir/repo"
    STUB_STAT_UID=$(id -u) ds_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    n=$(ds_sudo_calls); ((n == 0)) || fail "sudo ran for a clone we own: $(cat "$ds_dir/calls")"
    ds_safe_dir_set "$ds_dir/repo" || fail 'safe.directory was not set'
}

start_last_mount_at_the_same_point_wins() {
    local mine other n
    ds_setup lastwins || return 0
    mine=$(id -u); other=$((mine + 1))
    ds_mountinfo /var/lib/docker/volumes/v1/_data "$ds_dir/repo" /home/u/src/codeo "$ds_dir/repo"
    STUB_STAT_UID=$other ds_run
    n=$(ds_sudo_calls); ((n == 0)) || fail "bind mount last: wanted no chown, got $n: $(cat "$ds_dir/calls")"
    n=$(ds_todos 'not on a Docker volume'); ((n == 1)) || fail "bind mount last: wanted one bind-mount TODO, got $n: $ds_err"
    ds_mountinfo /home/u/src/codeo "$ds_dir/repo" /var/lib/docker/volumes/v1/_data "$ds_dir/repo"
    : > "$ds_dir/calls"
    STUB_STAT_UID=$other ds_run
    n=$(ds_sudo_calls); ((n == 1)) || fail "volume last: wanted one chown, got $n: $(cat "$ds_dir/calls")"
}

start_mount_prefix_needs_a_path_boundary() {
    local mine other n
    ds_setup boundary || return 0
    mine=$(id -u); other=$((mine + 1))
    ds_mountinfo /var/lib/docker/volumes/v1/_data "$ds_dir/repo2"
    STUB_STAT_UID=$other ds_run
    n=$(ds_sudo_calls); ((n == 0)) || fail "a volume at <clone>2 counted: $(cat "$ds_dir/calls")"
    ds_mountinfo /var/lib/docker/volumes/v1/_data "$ds_dir/rep"
    : > "$ds_dir/calls"
    STUB_STAT_UID=$other ds_run
    n=$(ds_sudo_calls); ((n == 0)) || fail "a volume at a string prefix of the clone counted: $(cat "$ds_dir/calls")"
}

start_resolves_symlinks_before_matching() {
    local mine other n
    ds_setup symlink || return 0
    mine=$(id -u); other=$((mine + 1))
    ln -s "$ds_dir/repo" "$ds_dir/link" || { fail 'could not make the symlink'; return 0; }
    # The logical path $ds_dir/link sits under the volume; the physical path $ds_dir/repo is a bind mount.
    ds_mountinfo /var/lib/docker/volumes/v1/_data "$ds_dir" /home/u/src/codeo "$ds_dir/repo"
    DS_REPO="$ds_dir/link" STUB_STAT_UID=$other ds_run
    n=$(ds_sudo_calls); ((n == 0)) || fail "matched the logical path: $(cat "$ds_dir/calls")"
}

start_identity_todo_when_only_one_is_set() {
    local n
    ds_setup ident || return 0
    git config --file "$ds_dir/gitconfig" user.name Dev
    ds_run
    n=$(ds_todos 'git identity'); ((n == 1)) || fail "only user.name set: wanted a TODO, got $n: $ds_err"
    : > "$ds_dir/gitconfig"
    git config --file "$ds_dir/gitconfig" user.email dev@example.com
    ds_run
    n=$(ds_todos 'git identity'); ((n == 1)) || fail "only user.email set: wanted a TODO, got $n: $ds_err"
}

start_setup_git_failure_is_a_todo() {
    local n
    ds_setup setupgit || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    STUB_SETUP_GIT_RC=1 STUB_GH_RC=0 STUB_GH_OUT="'project'" STUB_CLAUDE_RC=0 ds_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    n=$(ds_todos 'gh auth setup-git'); ((n == 1)) || fail "wanted one TODO naming gh auth setup-git, got $n: $ds_err"
}

# ds_ready_run: a run with every login configured (the "ready" baseline); extra STUB_* come from the caller.
ds_ready_run() { STUB_GH_RC=0 STUB_GH_OUT="'project'" STUB_CLAUDE_RC=0 ds_run; }

start_finds_the_identity_in_the_git_volume_file() {
    local n last
    ds_setup volfile || return 0
    mkdir -p "$ds_dir/home/.config/git"
    git config --file "$ds_dir/home/.config/git/config" user.name Dev
    git config --file "$ds_dir/home/.config/git/config" user.email dev@example.com
    DS_GITCONFIG="$ds_dir/home/.config/git/config" ds_ready_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    n=$(ds_todos 'git identity'); ((n == 0)) || fail "wanted no git identity TODO, got $n: $ds_err"
    last=$(tail -n1 <<<"$ds_out")
    [[ "$last" == 'devcontainer-start: ready' ]] || fail "last stdout line is not ready: $last"
}

start_enables_remote_control() {
    ds_setup rc || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    ds_ready_run
    ((ds_rc == 0)) || fail "exit $ds_rc: $ds_err"
    jq -e '.remoteControlAtStartup == true' "$ds_dir/claude/settings.json" >/dev/null \
        || fail "remoteControlAtStartup is not true: $(cat "$ds_dir/claude/settings.json" 2>&1)"
}

start_keeps_other_settings() {
    ds_setup keep || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    mkdir -p "$ds_dir/claude"
    echo '{"enabledPlugins":{"a@b":true},"autoUpdatesChannel":"stable"}' > "$ds_dir/claude/settings.json"
    ds_ready_run
    ds_ready_run
    jq -e '.remoteControlAtStartup == true and .enabledPlugins["a@b"] == true and .autoUpdatesChannel == "stable"' \
        "$ds_dir/claude/settings.json" >/dev/null || fail "keys lost: $(cat "$ds_dir/claude/settings.json")"
}

start_malformed_settings_is_a_todo() {
    local n
    ds_setup badjson || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    mkdir -p "$ds_dir/claude"
    printf '{not json' > "$ds_dir/claude/settings.json"
    ds_ready_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    [[ $(cat "$ds_dir/claude/settings.json") == '{not json' ]] || fail 'malformed settings.json was changed'
    n=$(ds_todos 'settings.json'); ((n == 1)) || fail "wanted one TODO naming settings.json, got $n: $ds_err"
}

start_fills_an_empty_settings_file() {
    ds_setup emptyjson || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    mkdir -p "$ds_dir/claude"
    : > "$ds_dir/claude/settings.json"
    ds_ready_run
    ((ds_rc == 0)) || fail "exit $ds_rc: $ds_err"
    jq -e '.remoteControlAtStartup == true' "$ds_dir/claude/settings.json" >/dev/null \
        || fail "an empty settings.json was not filled: '$(cat "$ds_dir/claude/settings.json" 2>&1)'"
    [[ $(ds_todos 'settings.json') == 0 ]] || fail "unexpected TODO naming settings.json: $ds_err"
}

start_settings_that_are_not_an_object_are_a_todo() {
    local n
    ds_setup notobj || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    mkdir -p "$ds_dir/claude"
    printf '[]' > "$ds_dir/claude/settings.json"
    ds_ready_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    [[ $(cat "$ds_dir/claude/settings.json") == '[]' ]] || fail 'a non-object settings.json was changed'
    n=$(ds_todos 'settings.json.*not a JSON object'); ((n == 1)) || fail "wanted one 'not a JSON object' TODO, got $n: $ds_err"
}

start_settings_symlink_is_kept() {
    ds_setup symlink || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    mkdir -p "$ds_dir/claude"
    echo '{"autoUpdatesChannel":"stable"}' > "$ds_dir/real-claude-settings.json"
    ln -sf "$ds_dir/real-claude-settings.json" "$ds_dir/claude/settings.json"
    ds_ready_run
    ((ds_rc == 0)) || fail "exit $ds_rc: $ds_err"
    [[ -L $ds_dir/claude/settings.json ]] || fail 'settings.json is no longer a symlink'
    jq -e '.remoteControlAtStartup == true and .autoUpdatesChannel == "stable"' "$ds_dir/real-claude-settings.json" >/dev/null \
        || fail "the link target was not merged: $(cat "$ds_dir/real-claude-settings.json")"
}

start_settings_keep_their_mode() {
    local mode
    ds_setup mode || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    for mode in 644 600; do
        mkdir -p "$ds_dir/claude"
        echo '{"autoUpdatesChannel":"stable"}' > "$ds_dir/claude/settings.json"
        chmod "$mode" "$ds_dir/claude/settings.json"
        ds_ready_run
        ((ds_rc == 0)) || fail "exit $ds_rc: $ds_err"
        [[ $(stat -c %a "$ds_dir/claude/settings.json") == "$mode" ]] \
            || fail "$mode became $(stat -c %a "$ds_dir/claude/settings.json")"
    done
}

start_leaves_no_temp_file_when_mv_fails() {
    local n
    ds_setup mvfail || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    mkdir -p "$ds_dir/claude"
    echo '{"autoUpdatesChannel":"stable"}' > "$ds_dir/claude/settings.json"
    printf '#!/bin/sh\nexit 1\n' > "$ds_dir/bin/mv"
    chmod +x "$ds_dir/bin/mv"
    ds_ready_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    n=$(ds_todos 'could not write'); ((n == 1)) || fail "wanted one 'could not write' TODO, got $n: $ds_err"
    [[ $(ls -A "$ds_dir/claude") == settings.json ]] || fail "leftover files: $(ls -A "$ds_dir/claude")"
}

start_writes_the_title() {
    local n
    ds_setup title || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    ds_ready_run
    [[ $(jq -r '.["window.title"]' "$ds_dir/repo/.vscode/settings.json" 2>&1) == 'codeo [home]' ]] \
        || fail "no home title: $(cat "$ds_dir/repo/.vscode/settings.json" 2>&1)"
    printf '#!/usr/bin/env bash\nexit 1\n' > "$ds_dir/repo/.devcontainer/scripts/window-title.sh"
    ds_ready_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    n=$(ds_todos 'window-title.sh'); ((n == 1)) || fail "wanted one TODO naming window-title.sh, got $n: $ds_err"
}

start_env_vars_are_todos() {
    local n v
    ds_setup envvars || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    ds_ready_run
    [[ $(tail -n1 <<<"$ds_out") == 'devcontainer-start: ready' && -z $ds_err ]] || fail "baseline not ready: $ds_out / $ds_err"
    for v in CLAUDE_CODE_OAUTH_TOKEN ANTHROPIC_API_KEY ANTHROPIC_BASE_URL; do
        ds_setup "env-$v" || return 0
        ds_identity || { fail 'could not set the scratch git identity'; return 0; }
        DS_SET="$v=x" STUB_GH_RC=0 STUB_GH_OUT="'project'" STUB_CLAUDE_RC=0 ds_run
        ((ds_rc == 0)) || fail "$v: exit $ds_rc"
        n=$(ds_todos "$v.*Remote Control"); ((n == 1)) || fail "$v: wanted one TODO, got $n: $ds_err"
    done
}

start_credential_variables_hide_the_login_advice() {
    local v method rc n
    for v in ANTHROPIC_API_KEY CLAUDE_CODE_OAUTH_TOKEN; do
        method=api_key; [[ $v == CLAUDE_CODE_OAUTH_TOKEN ]] && method=oauth_token
        for rc in 0 1; do
            ds_setup "cred-$v-$rc" || return 0
            ds_identity || { fail 'could not set the scratch git identity'; return 0; }
            DS_SET="$v=x" STUB_GH_RC=0 STUB_GH_OUT="'project'" STUB_CLAUDE_RC=$rc \
                STUB_CLAUDE_OUT="{\"loggedIn\":true,\"authMethod\":\"$method\"}" ds_run
            ((ds_rc == 0)) || fail "$v/$rc: exit $ds_rc"
            n=$(grep -c 'claude auth login' <<<"$ds_err" || true)
            ((n == 0)) || fail "$v/$rc: claude auth login is advised: $ds_err"
            n=$(ds_todos "$v.*unset"); ((n == 1)) || fail "$v/$rc: wanted one unset TODO, got $n: $ds_err"
            if grep -q 'what is left to do' <<<"$ds_out$ds_err"; then fail "$v/$rc: a what-is-left list is printed: $ds_err"; fi
        done
    done
}

start_non_claude_ai_login_is_a_todo() {
    local n
    ds_setup authmethod || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    STUB_CLAUDE_OUT='{"loggedIn":true,"authMethod":"api_key"}' ds_ready_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    n=$(ds_todos 'claude auth login'); ((n == 1)) || fail "api_key: wanted one TODO, got $n: $ds_err"
    STUB_CLAUDE_OUT='{"loggedIn":true,"authMethod":"claude.ai"}' ds_ready_run
    n=$(ds_todos 'claude auth login'); ((n == 0)) || fail "claude.ai: wanted none, got $n: $ds_err"
}

start_sets_file_mode_so_new_scripts_are_executable() {
    ds_setup filemode || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    git -C "$ds_dir/repo" config core.fileMode false
    ds_ready_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    [[ $(git -C "$ds_dir/repo" config --type=bool core.fileMode) == true ]] || fail 'core.fileMode is not true after the start script'
    grep -q 'core.fileMode' <<<"$ds_out" || fail "stdout does not mention core.fileMode: $ds_out"
    ! ls "$ds_dir/repo/.git" | grep -q '^filemode\.' || fail 'a filemode probe file was left in the git dir'
    printf '#!/bin/sh\n' > "$ds_dir/repo/new.sh" && chmod +x "$ds_dir/repo/new.sh" && git -C "$ds_dir/repo" add new.sh
    [[ $(git -C "$ds_dir/repo" ls-files -s new.sh) == 100755* ]] || fail "new.sh was not staged as 100755: $(git -C "$ds_dir/repo" ls-files -s new.sh)"
}

start_leaves_file_mode_alone_when_it_is_fine() {
    local before
    ds_setup filemode-fine || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    before=$(git -C "$ds_dir/repo" config --list --local)
    ds_ready_run
    [[ $(git -C "$ds_dir/repo" config --list --local) == "$before" ]] || fail 'the local git config changed although core.fileMode was fine'
    ! grep -q 'core.fileMode' <<<"$ds_out$ds_err" || fail "output mentions core.fileMode: $ds_out $ds_err"
    git -C "$ds_dir/repo" config --unset core.filemode
    before=$(git -C "$ds_dir/repo" config --list --local)
    ds_ready_run
    [[ $(git -C "$ds_dir/repo" config --list --local) == "$before" ]] || fail 'the local git config changed with core.fileMode unset'
    ! grep -q 'core.fileMode' <<<"$ds_out$ds_err" || fail "unset: output mentions core.fileMode: $ds_out $ds_err"
}

start_file_mode_that_cannot_stick_is_a_todo() {
    local n
    ds_setup filemode-stuck || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    git -C "$ds_dir/repo" config core.fileMode false
    printf '#!/usr/bin/env bash\nexit 0\n' > "$ds_dir/bin/chmod"
    chmod +x "$ds_dir/bin/chmod"
    ds_ready_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    [[ $(git -C "$ds_dir/repo" config --type=bool core.fileMode) == false ]] || fail 'core.fileMode was changed although the executable bit cannot stick'
    n=$(ds_todos 'update-index --chmod'); ((n == 1)) || fail "wanted one TODO naming update-index --chmod, got $n: $ds_err"
    ! ls "$ds_dir/repo/.git" | grep -q '^filemode\.' || fail 'a filemode probe file was left in the git dir'
}

start_file_mode_that_cannot_clear_is_a_todo() {
    local n
    ds_setup filemode-sticky || return 0
    ds_identity || { fail 'could not set the scratch git identity'; return 0; }
    git -C "$ds_dir/repo" config core.fileMode false
    printf '#!/usr/bin/env bash\nexec /usr/bin/chmod u+x -- "${@: -1}"\n' > "$ds_dir/bin/chmod"
    chmod +x "$ds_dir/bin/chmod"
    ds_ready_run
    ((ds_rc == 0)) || fail "exit $ds_rc, wanted 0"
    [[ $(git -C "$ds_dir/repo" config --type=bool core.fileMode) == false ]] || fail 'core.fileMode was changed although the executable bit cannot be cleared'
    n=$(ds_todos 'update-index --chmod'); ((n == 1)) || fail "wanted one TODO naming update-index --chmod, got $n: $ds_err"
    ! ls "$ds_dir/repo/.git" | grep -q '^filemode\.' || fail 'a filemode probe file was left in the git dir'
}

# wt_setup <name>: a scratch git repo (committed) holding the real window-title.sh and a config naming the
# codename "codeo". Sets wt_dir, the clone's root.
wt_setup() {
    local name=$1
    [[ -n $pl_root ]] || pl_root=$(mktemp -d)
    wt_dir="$pl_root/wt-$name"
    mkdir -p "$wt_dir/.devcontainer/scripts" "$wt_dir/.codeo"
    git -C "$wt_dir" init -q || { fail 'git init failed'; return 1; }
    cp "$repo/.devcontainer/scripts/window-title.sh" "$wt_dir/.devcontainer/scripts/window-title.sh" \
        || { fail 'window-title.sh is missing'; return 1; }
    echo '{"codename":"codeo"}' > "$wt_dir/.codeo/config.json"
    git -C "$wt_dir" add -A
    git -C "$wt_dir" -c user.name=Dev -c user.email=dev@example.com commit -q -m fixture \
        || { fail 'git commit failed'; return 1; }
}

# wt_run [args]: runs window-title.sh from $wt_dir (or $wt_clone when set). Sets wt_rc, wt_out, wt_err.
wt_run() {
    local root=${wt_clone:-$wt_dir} errf
    errf=$(mktemp -p "$pl_root")
    wt_rc=0
    wt_out=$(PATH="${wt_path:+$wt_path:}$PATH" bash "$root/.devcontainer/scripts/window-title.sh" "$@" 2>"$errf") || wt_rc=$?
    wt_err=$(<"$errf")
}

wt_title() { jq -r '.["window.title"]' "$1/.vscode/settings.json"; }

title_is_home_without_a_lock() {
    wt_setup home || return 0
    wt_run --print
    [[ $wt_out == 'codeo [home]' ]] || fail "--print gave '$wt_out'"
    wt_run
    ((wt_rc == 0)) || fail "exit $wt_rc: $wt_err"
    [[ $wt_out == 'window-title: codeo [home]' ]] || fail "a plain run printed '$wt_out'"
    [[ $(wt_title "$wt_dir") == 'codeo [home]' ]] || fail 'settings.json lacks window.title "codeo [home]"'
}

title_names_the_issue_with_a_lock() {
    wt_setup lock || return 0
    printf 'issue:   44\nbranch: feat/x\nstarted: now\n' > "$wt_dir/.codeo/active"
    wt_run --print
    [[ $wt_out == 'codeo [#44]' ]] || fail "--print gave '$wt_out'"
}

title_falls_back_to_the_clone_name() {
    wt_setup fallback || return 0
    echo '{}' > "$wt_dir/.codeo/config.json"
    wt_run --print
    [[ $wt_out == 'wt-fallback [home]' ]] || fail "--print gave '$wt_out'"
}

title_keeps_other_keys() {
    wt_setup keys || return 0
    mkdir -p "$wt_dir/.vscode"
    echo '{"editor.tabSize": 2}' > "$wt_dir/.vscode/settings.json"
    wt_run
    ((wt_rc == 0)) || fail "exit $wt_rc: $wt_err"
    jq -e '.["editor.tabSize"] == 2 and .["window.title"] == "codeo [home]"' "$wt_dir/.vscode/settings.json" >/dev/null \
        || fail 'the seeded key was lost or the title is missing'
}

title_rerun_and_worktree() {
    local n wtree
    wt_setup rerun || return 0
    wt_run; wt_run
    ((wt_rc == 0)) || fail "exit $wt_rc: $wt_err"
    n=$(grep -cxF '.vscode/settings.json' "$(git -C "$wt_dir" rev-parse --path-format=absolute --git-path info/exclude)" || true)
    ((n == 1)) || fail "exclude has the entry $n times"
    [[ -z $(git -C "$wt_dir" status --porcelain) ]] || fail 'git status is not clean'
    wtree="$pl_root/wt-rerun-tree"
    git -C "$wt_dir" worktree add -q "$wtree" -b other || { fail 'git worktree add failed'; return 0; }
    wt_clone=$wtree wt_run
    ((wt_rc == 0)) || fail "worktree: exit $wt_rc: $wt_err"
    [[ -f $wtree/.vscode/settings.json ]] || fail 'worktree: settings.json was not written'
    [[ -z $(git -C "$wtree" status --porcelain) ]] || fail 'worktree: git status is not clean'
    n=$(grep -cxF '.vscode/settings.json' "$(git -C "$wtree" rev-parse --path-format=absolute --git-path info/exclude)" || true)
    ((n == 1)) || fail "worktree: exclude has the entry $n times"
}

title_follows_the_lock_on_a_rerun() {
    wt_setup follow || return 0
    wt_run
    printf 'issue:   44\n' > "$wt_dir/.codeo/active"
    wt_run
    [[ $(wt_title "$wt_dir") == 'codeo [#44]' ]] || fail "title is '$(wt_title "$wt_dir")'"
}

title_rejects_settings_that_are_not_an_object() {
    local leg body want
    for leg in array broken jsonc; do
        case $leg in
            array)  body='[]';                want='not a JSON object' ;;
            broken) body='{not json';         want='not valid JSON' ;;
            jsonc)  body=$'{ // c\n"a": 1 }'; want='not valid JSON' ;;
        esac
        wt_setup "bad-$leg" || return 0
        mkdir -p "$wt_dir/.vscode"
        printf '%s' "$body" > "$wt_dir/.vscode/settings.json"
        wt_run
        ((wt_rc == 1)) || fail "$leg: exit $wt_rc, wanted 1"
        [[ $(<"$wt_dir/.vscode/settings.json") == "$body" ]] || fail "$leg: the file was changed"
        [[ $wt_err == window-title:* && $wt_err != *$'\n'* ]] || fail "$leg: stderr was: $wt_err"
        [[ $wt_err == *"$want"* ]] || fail "$leg: stderr lacks '$want': $wt_err"
    done
}

title_writes_through_a_symlink() {
    wt_setup link || return 0
    mkdir -p "$wt_dir/.vscode"
    echo '{"a":1}' > "$pl_root/real-settings.json"
    ln -s "$pl_root/real-settings.json" "$wt_dir/.vscode/settings.json"
    wt_run
    ((wt_rc == 0)) || fail "exit $wt_rc: $wt_err"
    [[ -L $wt_dir/.vscode/settings.json ]] || fail 'the symlink was replaced'
    jq -e '.a == 1 and .["window.title"] == "codeo [home]"' "$pl_root/real-settings.json" >/dev/null \
        || fail 'the target lacks a or the title'
    wt_setup dangling || return 0
    mkdir -p "$wt_dir/.vscode"
    ln -s "$pl_root/dangling-target.json" "$wt_dir/.vscode/settings.json"
    wt_run
    ((wt_rc == 0)) || fail "dangling: exit $wt_rc: $wt_err"
    [[ -L $wt_dir/.vscode/settings.json ]] || fail 'dangling: the symlink was replaced'
    [[ $(jq -r '.["window.title"]' "$pl_root/dangling-target.json") == 'codeo [home]' ]] \
        || fail 'dangling: the target was not created with the title'
}

title_keeps_the_settings_mode() {
    local mode
    for mode in 644 600; do
        wt_setup "mode$mode" || return 0
        mkdir -p "$wt_dir/.vscode"
        echo '{"a":1}' > "$wt_dir/.vscode/settings.json"
        chmod "$mode" "$wt_dir/.vscode/settings.json"
        wt_run
        ((wt_rc == 0)) || fail "$mode: exit $wt_rc: $wt_err"
        [[ $(stat -c %a "$wt_dir/.vscode/settings.json") == "$mode" ]] \
            || fail "$mode became $(stat -c %a "$wt_dir/.vscode/settings.json")"
    done
}

title_leaves_no_temp_file_when_mv_fails() {
    local stubs
    wt_setup mvfail || return 0
    mkdir -p "$wt_dir/.vscode"
    echo '{"a":1}' > "$wt_dir/.vscode/settings.json"
    stubs="$pl_root/mv-stub"
    mkdir -p "$stubs"
    printf '#!/bin/sh\nexit 1\n' > "$stubs/mv"
    chmod +x "$stubs/mv"
    wt_path=$stubs wt_run
    ((wt_rc == 1)) || fail "exit $wt_rc, wanted 1"
    [[ $wt_err == window-title:* && $wt_err != *$'\n'* ]] || fail "stderr was: $wt_err"
    [[ $(ls -A "$wt_dir/.vscode") == settings.json ]] || fail ".vscode holds: $(ls -A "$wt_dir/.vscode")"
}

title_does_not_rewrite_a_current_title() {
    local before after
    wt_setup current || return 0
    wt_run
    before=$(stat -c %i "$wt_dir/.vscode/settings.json")
    wt_run
    after=$(stat -c %i "$wt_dir/.vscode/settings.json")
    [[ $before == "$after" ]] || fail "inode changed $before -> $after"
    [[ $wt_out == 'window-title: codeo [home]' ]] || fail "second run printed '$wt_out'"
}

title_follows_a_released_lock() {
    wt_setup release || return 0
    wt_run
    [[ $(wt_title "$wt_dir") == 'codeo [home]' ]] || fail "first title is '$(wt_title "$wt_dir")'"
    printf 'issue:   47\n' > "$wt_dir/.codeo/active"
    wt_run
    [[ $(wt_title "$wt_dir") == 'codeo [#47]' ]] || fail "locked title is '$(wt_title "$wt_dir")'"
    rm -f "$wt_dir/.codeo/active"
    wt_run
    [[ $(wt_title "$wt_dir") == 'codeo [home]' ]] || fail "released title is '$(wt_title "$wt_dir")'"
}

title_fills_an_empty_settings_file() {
    wt_setup empty || return 0
    mkdir -p "$wt_dir/.vscode"
    : > "$wt_dir/.vscode/settings.json"
    wt_run
    ((wt_rc == 0)) || fail "exit $wt_rc: $wt_err"
    jq -e '.["window.title"] == "codeo [home]"' "$wt_dir/.vscode/settings.json" >/dev/null \
        || fail "an empty settings.json was not filled: '$(cat "$wt_dir/.vscode/settings.json")'"
}

title_strips_a_hash_from_the_lock_line() {
    wt_setup hash || return 0
    printf 'issue: #44\nbranch: feat/x\n' > "$wt_dir/.codeo/active"
    wt_run --print
    [[ $wt_out == 'codeo [#44]' ]] || fail "--print gave '$wt_out'"
    wt_run
    ((wt_rc == 0)) || fail "exit $wt_rc: $wt_err"
    [[ $(wt_title "$wt_dir") == 'codeo [#44]' ]] || fail "title is '$(wt_title "$wt_dir")'"
}

title_reports_an_unwritable_exclude() {
    local exclude
    wt_setup noexcl || return 0
    exclude=$(git -C "$wt_dir" rev-parse --path-format=absolute --git-path info/exclude)
    rm -f "$exclude"
    mkdir "$exclude"
    wt_run
    ((wt_rc == 1)) || fail "exit $wt_rc, wanted 1"
    [[ $wt_err == window-title:* && $wt_err != *$'\n'* ]] || fail "stderr was: $wt_err"
    [[ ! -e $wt_dir/.vscode/settings.json ]] || fail 'settings.json was written before the exclude entry'
}

title_outside_a_repository_says_so() {
    local d
    wt_setup norepo || return 0
    d="$pl_root/not-a-repo"
    mkdir -p "$d/.devcontainer/scripts"
    cp "$wt_dir/.devcontainer/scripts/window-title.sh" "$d/.devcontainer/scripts/"
    wt_clone=$d wt_run
    ((wt_rc == 1)) || fail "exit $wt_rc, wanted 1"
    [[ $wt_err == window-title:* && $wt_err != *$'\n'* ]] || fail "stderr was: $wt_err"
}

# st_setup <name>: like wt_setup, plus the real session-title.sh. Sets st_dir, the clone's root.
st_setup() {
    local name=$1
    wt_setup "st-$name" || return 1
    st_dir=$wt_dir
    cp "$repo/.devcontainer/scripts/session-title.sh" "$st_dir/.devcontainer/scripts/session-title.sh" \
        || { fail 'session-title.sh is missing'; return 1; }
    git -C "$st_dir" add -A
    git -C "$st_dir" -c user.name=Dev -c user.email=dev@example.com commit -q -m fixture-st \
        || { fail 'git commit failed'; return 1; }
}

# st_json <event> <session_id> [session_title]: the hook's stdin fixture.
st_json() {
    local event=$1 sid=$2
    jq -cn --arg e "$event" --arg s "$sid" --arg d "$st_dir" --arg t "${3:-}" --argjson has "$(($# >= 3 ? 1 : 0))" \
        '{hook_event_name: $e, session_id: $s, transcript_path: "/x.jsonl", cwd: $d}
         + (if $e == "SessionStart" then {source: "startup"} else {} end)
         + (if $has == 1 then {session_title: $t} else {} end)'
}

# st_run <stdin> [remote]: runs session-title.sh with REMOTE_CONTAINERS=<remote> (default true; "unset"
# leaves it out) from /. Sets st_rc, st_out, st_err.
st_run() {
    local input=$1 remote=${2:-true} errf envs=()
    [[ $remote == unset ]] || envs=("REMOTE_CONTAINERS=$remote")
    errf=$(mktemp -p "$pl_root")
    st_rc=0
    st_out=$(cd / && env -u REMOTE_CONTAINERS "${envs[@]}" bash "$st_dir/.devcontainer/scripts/session-title.sh" <<<"$input" 2>"$errf") || st_rc=$?
    st_err=$(<"$errf")
}

st_title() { jq -r '.hookSpecificOutput.sessionTitle' <<<"$st_out"; }
st_event() { jq -r '.hookSpecificOutput.hookEventName' <<<"$st_out"; }

# st_silent <label>: the last st_run printed nothing and exited 0.
st_silent() {
    ((st_rc == 0)) || fail "$1: exit $st_rc"
    [[ -z $st_out ]] || fail "$1: stdout '$st_out'"
    [[ -z $st_err ]] || fail "$1: stderr '$st_err'"
}

st_sid=a21b9973-0000-4000-8000-000000000000

session_title_names_home_and_the_id() {
    st_setup home || return 0
    st_run "$(st_json SessionStart $st_sid)"
    ((st_rc == 0)) || fail "exit $st_rc"
    [[ -z $st_err ]] || fail "stderr '$st_err'"
    [[ -n $st_out && $st_out != *$'\n'* ]] || fail "not one line: '$st_out'"
    [[ $(st_event) == SessionStart ]] || fail "event '$(st_event)'"
    [[ $(st_title) == 'codeo [home] · a21b9973' ]] || fail "title '$(st_title)'"
}

session_title_names_the_issue_with_a_lock() {
    st_setup lock || return 0
    printf 'issue:   45\nbranch: feat/x\nstarted: now\n' > "$st_dir/.codeo/active"
    st_run "$(st_json SessionStart $st_sid)"
    [[ $(st_title) == 'codeo [#45] · a21b9973' ]] || fail "title '$(st_title)'"
}

session_title_on_a_prompt_after_clear() {
    st_setup prompt || return 0
    st_run "$(st_json UserPromptSubmit $st_sid)"
    [[ $(st_event) == UserPromptSubmit ]] || fail "event '$(st_event)'"
    [[ $(st_title) == 'codeo [home] · a21b9973' ]] || fail "title '$(st_title)'"
}

session_title_keeps_an_existing_title() {
    st_setup keep || return 0
    st_run "$(st_json SessionStart $st_sid 'my name')"
    st_silent SessionStart
    st_run "$(st_json UserPromptSubmit $st_sid 'my name')"
    st_silent UserPromptSubmit
}

session_title_is_silent_outside_a_dev_container() {
    st_setup outside || return 0
    local remote
    for remote in unset false 1; do
        st_run "$(st_json SessionStart $st_sid)" "$remote"
        st_silent "REMOTE_CONTAINERS=$remote"
    done
}

session_title_is_silent_on_bad_input() {
    st_setup bad || return 0
    st_run ''; st_silent 'empty stdin'
    st_run '{not json'; st_silent 'invalid json'
    st_run '{"hook_event_name":"SessionStart"}'; st_silent 'no id'
    st_run "$(st_json SessionStart abc)"; st_silent 'short id'
    st_run "$(st_json PreToolUse $st_sid)"; st_silent 'other event'
}

session_title_is_silent_when_the_title_script_fails() {
    st_setup fails || return 0
    local script=$st_dir/.devcontainer/scripts/window-title.sh
    rm -f "$script"
    st_run "$(st_json SessionStart $st_sid)"; st_silent 'missing'
    printf '#!/usr/bin/env bash\necho boom >&2\nexit 1\n' > "$script"
    st_run "$(st_json SessionStart $st_sid)"; st_silent 'failing'
    printf '#!/usr/bin/env bash\nexit 0\n' > "$script"
    st_run "$(st_json SessionStart $st_sid)"; st_silent 'empty'
}

session_title_escapes_the_codename() {
    st_setup escape || return 0
    jq -n '{codename: "co\"de\\o"}' > "$st_dir/.codeo/config.json"
    st_run "$(st_json SessionStart $st_sid)"
    jq -e . <<<"$st_out" >/dev/null || fail "not valid JSON: '$st_out'"
    [[ $(st_title) == 'co"de\o [home]'* ]] || fail "title '$(st_title)'"
}

session_title_treats_a_leading_newline_as_a_title() {
    st_setup newline || return 0
    st_run "$(st_json UserPromptSubmit $st_sid $'\nmy name')"
    st_silent 'leading newline'
}

session_title_replaces_its_own_title_when_the_lock_changes() {
    st_setup own || return 0
    printf 'issue:   47\nbranch: feat/x\nstarted: now\n' > "$st_dir/.codeo/active"
    st_run "$(st_json UserPromptSubmit $st_sid 'codeo [home] · a21b9973')"
    [[ $(st_title) == 'codeo [#47] · a21b9973' ]] || fail "title '$(st_title)'"
    rm -f "$st_dir/.codeo/active"
    st_run "$(st_json UserPromptSubmit $st_sid 'codeo [#47] · a21b9973')"
    [[ $(st_title) == 'codeo [home] · a21b9973' ]] || fail "title '$(st_title)'"
    st_run "$(st_json UserPromptSubmit $st_sid 'codeo [home] · a21b9973')"
    st_silent 'current title'
}

session_title_keeps_a_renamed_title() {
    st_setup renamed || return 0
    printf 'issue:   47\nbranch: feat/x\nstarted: now\n' > "$st_dir/.codeo/active"
    st_run "$(st_json UserPromptSubmit $st_sid 'my name')"
    st_silent 'renamed'
    st_run "$(st_json UserPromptSubmit $st_sid 'codeo [home] · ffffffff')"
    st_silent "another session's id"
}

session_title_refreshes_the_window_title() {
    st_setup window || return 0
    local f=$st_dir/.vscode/settings.json
    st_run "$(st_json UserPromptSubmit $st_sid)"
    [[ $(jq -r '."window.title"' "$f") == 'codeo [home]' ]] || fail "no lock: $(jq -r '."window.title"' "$f")"
    printf 'issue:   47\nbranch: feat/x\nstarted: now\n' > "$st_dir/.codeo/active"
    st_run "$(st_json UserPromptSubmit $st_sid 'my name')"
    [[ $(jq -r '."window.title"' "$f") == 'codeo [#47]' ]] || fail "lock: $(jq -r '."window.title"' "$f")"
    rm -f "$st_dir/.codeo/active"
    st_run "$(st_json UserPromptSubmit $st_sid 'my name')"
    st_silent 'renamed'
    [[ $(jq -r '."window.title"' "$f") == 'codeo [home]' ]] || fail "released: $(jq -r '."window.title"' "$f")"
}

session_title_hooks_are_registered() {
    local f=$repo/.claude/settings.json
    local cmd='f="${CLAUDE_PROJECT_DIR}/.devcontainer/scripts/session-title.sh"; [ -f "$f" ] && bash "$f" || true' hook
    hook="$(jq -cn --arg c "$cmd" '{type:"command",command:$c,timeout:10}')"
    jq -e '.enabledPlugins["codeo@codeo"] == true' "$f" >/dev/null || fail "codeo plugin not enabled"
    jq -e '.hooks | has("SessionStart") and has("UserPromptSubmit") and length == 2' "$f" >/dev/null || fail "hook events differ"
    jq -e --argjson hook "$hook" '.hooks.SessionStart == [{matcher:"startup|resume|fork", hooks:[$hook]}]' "$f" >/dev/null \
        || fail "SessionStart hook differs"
    jq -e --argjson hook "$hook" '.hooks.UserPromptSubmit == [{hooks:[$hook]}]' "$f" >/dev/null \
        || fail "UserPromptSubmit hook differs"
}

# The registered command runs the script when it is there and is silent, exit 0, when it is not.
session_title_hook_command_survives_a_missing_script() {
    local cmd rc out err errf
    st_setup missing-script || return 0
    cmd=$(jq -r '.hooks.UserPromptSubmit[0].hooks[0].command' "$repo/.claude/settings.json")
    errf=$(mktemp -p "$pl_root")
    rc=0
    out=$(cd / && env -u REMOTE_CONTAINERS REMOTE_CONTAINERS=true CLAUDE_PROJECT_DIR="$st_dir" bash -c "$cmd" \
        <<<"$(st_json SessionStart $st_sid)" 2>"$errf") || rc=$?
    err=$(<"$errf")
    ((rc == 0)) || fail "with the script present: exit $rc"
    [[ -z $err ]] || fail "with the script present: stderr '$err'"
    [[ $(jq -r '.hookSpecificOutput.sessionTitle' <<<"$out") == 'codeo [home] · a21b9973' ]] \
        || fail "with the script present: stdout '$out'"
    rm "$st_dir/.devcontainer/scripts/session-title.sh"
    rc=0
    out=$(cd / && env -u REMOTE_CONTAINERS REMOTE_CONTAINERS=true CLAUDE_PROJECT_DIR="$st_dir" bash -c "$cmd" \
        </dev/null 2>"$errf") || rc=$?
    err=$(<"$errf")
    ((rc == 0)) || fail "with the script removed: exit $rc"
    [[ -z $out ]] || fail "with the script removed: stdout '$out'"
    [[ -z $err ]] || fail "with the script removed: stderr '$err'"
}

# Every dev container script is committed 100755 (a file git does not track yet needs the bit on disk).
scripts_are_committed_executable() {
    local f rel mode
    for f in "$repo"/.devcontainer/scripts/*.sh; do
        rel=${f#"$repo"/}
        mode=$(git -C "$repo" ls-files -s -- "$rel" | cut -d' ' -f1)
        if [[ -z $mode ]]; then
            [[ -x $f ]] || fail "$rel is untracked and not executable"
        else
            [[ $mode == 100755 ]] || fail "$rel is committed with mode $mode, not 100755"
        fi
    done
}

cases=(
    config_has_codename_pin_and_suite_path
    devcontainer_json_is_valid_and_runs_as_dev
    run_args_cap_memory_and_cpus
    post_start_command_reruns_the_title
    volumes_hold_the_gh_login_and_the_git_config
    git_config_global_points_into_the_git_volume
    no_bind_mounts_or_secrets
    dockerfile_is_ubuntu_2404_with_the_tools
    dockerfile_creates_dev_uid_1000_and_the_gh_dir
    dockerfile_creates_the_git_config_dir
    git_global_writes_land_in_the_volume_file
    dockerfile_has_none_of_the_excluded_tools
    dockerfile_env_uses_the_username_arg
    dockerfile_does_not_create_workspaces
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
    start_chowns_the_clone_on_a_named_volume
    start_never_chowns_a_bind_mount
    start_longest_mount_wins
    start_own_clone_runs_nothing_privileged
    start_last_mount_at_the_same_point_wins
    start_mount_prefix_needs_a_path_boundary
    start_resolves_symlinks_before_matching
    start_identity_todo_when_only_one_is_set
    start_setup_git_failure_is_a_todo
    start_finds_the_identity_in_the_git_volume_file
    start_enables_remote_control
    start_keeps_other_settings
    start_malformed_settings_is_a_todo
    start_fills_an_empty_settings_file
    start_settings_that_are_not_an_object_are_a_todo
    start_settings_symlink_is_kept
    start_settings_keep_their_mode
    start_leaves_no_temp_file_when_mv_fails
    start_writes_the_title
    start_env_vars_are_todos
    start_credential_variables_hide_the_login_advice
    start_non_claude_ai_login_is_a_todo
    start_sets_file_mode_so_new_scripts_are_executable
    start_leaves_file_mode_alone_when_it_is_fine
    start_file_mode_that_cannot_stick_is_a_todo
    start_file_mode_that_cannot_clear_is_a_todo
    title_is_home_without_a_lock
    title_names_the_issue_with_a_lock
    title_falls_back_to_the_clone_name
    title_keeps_other_keys
    title_rerun_and_worktree
    title_follows_the_lock_on_a_rerun
    title_rejects_settings_that_are_not_an_object
    title_writes_through_a_symlink
    title_keeps_the_settings_mode
    title_leaves_no_temp_file_when_mv_fails
    title_does_not_rewrite_a_current_title
    title_follows_a_released_lock
    title_fills_an_empty_settings_file
    title_strips_a_hash_from_the_lock_line
    title_reports_an_unwritable_exclude
    title_outside_a_repository_says_so
    session_title_names_home_and_the_id
    session_title_names_the_issue_with_a_lock
    session_title_on_a_prompt_after_clear
    session_title_keeps_an_existing_title
    session_title_is_silent_outside_a_dev_container
    session_title_is_silent_on_bad_input
    session_title_is_silent_when_the_title_script_fails
    session_title_escapes_the_codename
    session_title_treats_a_leading_newline_as_a_title
    session_title_replaces_its_own_title_when_the_lock_changes
    session_title_keeps_a_renamed_title
    session_title_refreshes_the_window_title
    session_title_hooks_are_registered
    session_title_hook_command_survives_a_missing_script
    scripts_are_committed_executable
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
