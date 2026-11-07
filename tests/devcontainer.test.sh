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
    cat > "$pl_dir/bin/claude" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "$STUB_DIR/calls"
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
    plugins_offline_keeps_codeo
    plugins_no_pin_fails
    plugins_large_plugin_list_does_not_break_the_pipe
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
