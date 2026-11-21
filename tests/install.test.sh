#!/usr/bin/env bash
# Guards install.sh, the one-command installer for the codeo and superpowers Claude Code plugins.
# Each case is a function named in the final cases=( ... ) array; add a case by writing a function
# and listing it. install.sh runs with PATH holding only a scratch bin/ (stubs for claude, git, gh
# and the system package managers, plus symlinks to the real basic utilities), so no real tool is
# ever called. A stub git ls-remote exits with the number in $STUB_DIR/ls-fail when that file exists,
# and exits 2 under --exit-code when the tag is not in $STUB_DIR/tags. Every stub claude call is logged, space-joined, to $STUB_DIR/calls; every stub git
# call to $STUB_DIR/git-calls; any package-manager or sudo call to $STUB_DIR/pkg-calls. This file
# covers the usage errors (exit 2 before any claude or git call) and the prerequisite check (exit 1,
# every missing tool named in one run, nothing installed).
#
#   bash tests/install.test.sh
#
# Exits 0 and prints "all cases passed" when every case holds; prints one "FAIL <case>: <detail>"
# line per problem and exits 1 otherwise.
set -euo pipefail

repo_root() { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; }
repo=$(repo_root)
script="$repo/install.sh"
bash_abs=$(command -v bash)
real_git=$(command -v git)

failures=0
current=""

# fail <message>: record one failure against the running case.
fail() {
    printf 'FAIL %s: %s\n' "$current" "$1"
    failures=$((failures + 1))
}

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

usage_line='install: usage: install.sh [--version vX.Y.Z] [--scope user|project]'
closing='install: nothing was installed. Install the tools above with your system'"'"'s package manager, then run this again.'

# in_setup <name>: a scratch directory in_dir whose bin/ is the whole PATH: stubs for claude, git
# (ls-remote answered from $STUB_DIR/tags, lines "<sha><TAB>refs/tags/<tag>"; everything else goes to
# the real git), gh, apt-get, brew, dnf, pacman and sudo, plus symlinks to the real utilities the
# script and the stubs use. Sets STUB_DIR (calls, git-calls, pkg-calls, tags, list.json) and
# CLAUDE_CONFIG_DIR. The stub claude keeps list.json (`plugin list --json`) and
# $CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json as the real CLI would: `plugin marketplace add
# <repo>[@<ref>] [--scope s]` records the marketplace (codeo for kbajpai/codeo, superpowers-marketplace
# for obra/superpowers-marketplace); `plugin install <id> --scope s` appends an entry (version 1.0.7 for
# codeo@codeo or the tag the marketplace was added at without its v, 7.0.2 for superpowers);
# `plugin install` of an installed id prints "already installed" and changes nothing; a file
# $STUB_DIR/list-fail makes `plugin list` exit 1; a file $STUB_DIR/drain makes every call read stdin
# to the end. `plugin marketplace add ... --scope project` of a marketplace already known is a no-op
# ("already on disk"); every call's $PWD is logged to $STUB_DIR/pwds. `plugin marketplace remove codeo` drops the marketplace and every codeo@codeo entry. The stub also models settings files: marketplace add writes extraKnownMarketplaces and install writes enabledPlugins into $PWD/.claude/settings.json (--scope project) or $CLAUDE_CONFIG_DIR/settings.json; remove strips codeo from the user file and from $PWD/.claude/settings.json when present; a path in $STUB_DIR/watch-settings is copied to $STUB_DIR/settings-at-remove after each remove.
in_setup() {
    in_dir="$scratch/$1"
    rm -rf "$in_dir"
    STUB_DIR="$in_dir/stub"
    CLAUDE_CONFIG_DIR="$in_dir/claude"
    mkdir -p "$in_dir/bin" "$in_dir/work" "$in_dir/home" "$STUB_DIR" "$CLAUDE_CONFIG_DIR/plugins"
    local n p
    for n in bash env cat grep sed awk sort mkdir rm cp mv date tr head tail cut dirname basename \
        mktemp jq ls wc printf uname timeout; do
        p=$(command -v "$n" 2>/dev/null || true)
        [[ -z $p || $p != /* ]] || ln -s "$p" "$in_dir/bin/$n"
    done
    : >"$STUB_DIR/calls"
    : >"$STUB_DIR/git-calls"
    : >"$STUB_DIR/pkg-calls"
    : >"$STUB_DIR/tags"
    echo '[]' >"$STUB_DIR/list.json"
    echo '{}' >"$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json"
    for n in apt-get brew dnf pacman sudo; do
        cat >"$in_dir/bin/$n" <<'STUB'
#!/usr/bin/env bash
echo "${0##*/} $*" >>"$STUB_DIR/pkg-calls"
STUB
    done
    cat >"$in_dir/bin/gh" <<'STUB'
#!/usr/bin/env bash
echo "gh $*" >>"$STUB_DIR/gh-calls"
STUB
    cat >"$in_dir/bin/git" <<STUB
#!/usr/bin/env bash
[[ ! -f "\$STUB_DIR/drain" ]] || cat >/dev/null
echo "\$*" >>"\$STUB_DIR/git-calls"
if [[ \${1:-} == ls-remote ]]; then
    [[ ! -f "\$STUB_DIR/ls-fail" ]] || exit "\$(cat "\$STUB_DIR/ls-fail")"
    if [[ " \$* " == *" --exit-code "* ]]; then
        grep -q "\${*: -1}\$" "\$STUB_DIR/tags" || exit 2
    fi
    cat "\$STUB_DIR/tags"
    exit 0
fi
exec "$real_git" "\$@"
STUB
    cat >"$in_dir/bin/claude" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"$STUB_DIR/calls"
echo "$PWD" >>"$STUB_DIR/pwds"
[[ ! -f $STUB_DIR/drain ]] || cat >/dev/null
list="$STUB_DIR/list.json"
market="$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json"
[[ -f $market ]] || echo '{}' >"$market"
scope=user
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
    [[ ${args[i]} != --scope ]] || scope=${args[i + 1]:-user}
done
# settings_file: the settings file the asked scope writes (project: $PWD/.claude, user: the config dir).
settings_file() {
    if [[ $scope == project ]]; then echo "$PWD/.claude/settings.json"; else echo "$CLAUDE_CONFIG_DIR/settings.json"; fi
}
# edit_settings <file> <jq args...>: apply a jq filter to a settings file, creating it when missing.
edit_settings() {
    local file=$1
    shift
    mkdir -p "$(dirname "$file")"
    [[ -f $file ]] || echo '{}' >"$file"
    jq "$@" "$file" >"$file.new"
    mv "$file.new" "$file"
}
# declare_marketplace <name> <repo> <ref>: extraKnownMarketplaces.<name>, replacing any entry (no ref key without a ref).
declare_marketplace() {
    edit_settings "$(settings_file)" --arg n "$1" --arg r "$2" --arg f "$3" \
        '.extraKnownMarketplaces[$n] = {source: ({source: "github", repo: $r} + (if $f == "" then {} else {ref: $f} end))}'
}
case "${1:-} ${2:-} ${3:-}" in
    "plugin list "*)
        if [[ -f $STUB_DIR/list-fail ]]; then echo "stub claude: plugin list failed" >&2; exit 1; fi
        [[ ! -f $STUB_DIR/list-pre ]] || cat "$STUB_DIR/list-pre"
        if [[ -f $STUB_DIR/list-nojson ]]; then exit 0; fi
        if [[ -f $STUB_DIR/list-compact ]]; then jq -c . "$list"; else cat "$list"; fi
        [[ ! -f $STUB_DIR/list-post ]] || cat "$STUB_DIR/list-post" ;;
    "plugin marketplace add")
        spec=$4 repo=${4%@*} ref=""
        [[ $spec != *@* ]] || ref=${spec#*@}
        if [[ $repo == kbajpai/codeo && -f $STUB_DIR/add-fail ]]; then echo "stub claude: add failed" >&2; exit 1; fi
        if [[ $repo == obra/superpowers-marketplace && -f $STUB_DIR/add-fail-superpowers ]]; then echo "stub claude: superpowers add failed" >&2; exit 1; fi
        case $repo in
            kbajpai/codeo) name=codeo ;;
            obra/superpowers-marketplace) name=superpowers-marketplace ;;
            *) echo "stub claude: unknown marketplace $repo" >&2; exit 1 ;;
        esac
        old=$(jq -r --arg n "$name" '.[$n].source.ref // ""' "$market")
        if [[ $scope == project && $(jq --arg n "$name" 'has($n)' "$market") == true ]]; then
            declare_marketplace "$name" "$repo" "$ref"
            echo "$name already on disk - declared in project settings"
            exit 0
        fi
        if [[ -n $old && $old != "$ref" ]]; then
            echo "its source doesn't match its extraKnownMarketplaces entry" >&2
            exit 1
        fi
        jq --arg n "$name" --arg r "$repo" --arg f "$ref" \
            '.[$n] = {source: ({source: "github", repo: $r} + (if $f == "" then {} else {ref: $f} end))}' \
            "$market" >"$market.new"
        mv "$market.new" "$market"
        declare_marketplace "$name" "$repo" "$ref" ;;
    "plugin marketplace remove")
        if [[ -f $STUB_DIR/remove-fail ]]; then echo "stub claude: remove failed" >&2; exit 1; fi
        for file in "$CLAUDE_CONFIG_DIR/settings.json" "$PWD/.claude/settings.json"; do
            [[ ! -f $file ]] || edit_settings "$file" --arg n "$4" 'del(.extraKnownMarketplaces[$n]) | (if $n == "codeo" then del(.enabledPlugins["codeo@codeo"]) else . end)'
        done
        # the real CLI also strips a project file in the directory it runs in. A test names the project file
        # it watches in $STUB_DIR/watch-settings; the stub keeps what that file holds once the remove is done.
        [[ ! -f $STUB_DIR/watch-settings || ! -f $(cat "$STUB_DIR/watch-settings") ]] \
            || cp "$(cat "$STUB_DIR/watch-settings")" "$STUB_DIR/settings-at-remove"
        jq --arg n "$4" 'del(.[$n])' "$market" >"$market.new"
        mv "$market.new" "$market"
        if [[ $4 == codeo ]]; then
            jq 'map(select(.id != "codeo@codeo"))' "$list" >"$list.new"
            mv "$list.new" "$list"
        fi ;;
    "plugin install "*)
        id=$3
        if [[ -f $STUB_DIR/install-fail-${id%@*} ]]; then echo "stub claude: install failed" >&2; exit 1; fi
        if [[ -f $STUB_DIR/install-fail-${id%@*}-$scope ]]; then echo "stub claude: install failed" >&2; exit 1; fi
        if [[ $(jq --arg id "$id" --arg s "$scope" '[.[] | select(.id == $id and .scope == $s and ($s != "project" or .projectPath == $p))] | length' "$list" --arg p "$PWD") -gt 0 ]]; then
            echo "$id is already installed"
            exit 0
        fi
        case $id in
            codeo@codeo)
                ref=$(jq -r '.codeo.source.ref // ""' "$market")
                version=${ref#v}
                [[ -n $version ]] || version=1.0.7 ;;
            *) version=7.0.2 ;;
        esac
        jq --arg id "$id" --arg v "$version" --arg s "$scope" --arg p "$PWD" \
            '. + [{id: $id, version: $v, scope: $s, enabled: true, projectPath: $p}]' \
            "$list" >"$list.new"
        mv "$list.new" "$list"
        edit_settings "$(settings_file)" --arg id "$id" '.enabledPlugins[$id] = true' ;;
    "plugin enable "*)
        jq --arg id "$3" --arg s "$scope" 'map(if .id == $id and .scope == $s then .enabled = true else . end)' "$list" >"$list.new"
        mv "$list.new" "$list" ;;
    *) echo "stub claude: unexpected: $*" >&2; exit 1 ;;
esac
STUB
    chmod +x "$in_dir/bin/"{apt-get,brew,dnf,pacman,sudo,gh,git,claude}
}

# in_hide <name>...: remove those tools from the scratch PATH, so `command -v` fails for them.
in_hide() {
    local n
    for n in "$@"; do rm -f "$in_dir/bin/$n"; done
}

# in_run [args...]: run install.sh with only the scratch bin/ on PATH, from the scratch work directory.
# Sets in_rc, in_out and in_err. CODEO_TEST_BASH_VERSION passes through when set by the caller.
in_run() {
    in_rc=0
    (cd "${in_cwd:-$in_dir/work}" && env -i PATH="$in_dir/bin" HOME="$in_dir/home" STUB_DIR="$STUB_DIR" \
        CLAUDE_CONFIG_DIR="$CLAUDE_CONFIG_DIR" ${CODEO_TEST_BASH_VERSION:+CODEO_TEST_BASH_VERSION="$CODEO_TEST_BASH_VERSION"} \
        "$bash_abs" "$script" "$@") >"$in_dir/out" 2>"$in_dir/err" || in_rc=$?
    in_out=$(cat "$in_dir/out")
    in_err=$(cat "$in_dir/err")
}

# expect_usage_error: the last run exited 2, printed the usage line on stderr and made no claude or git call.
expect_usage_error() {
    [[ $in_rc -eq 2 ]] || fail "exit $in_rc, want 2 (stderr: $in_err)"
    [[ $in_err == *"$usage_line"* ]] || fail "stderr lacks the usage line: $in_err"
    [[ $in_err == install:*$'\n'* ]] || fail "stderr should start with a one-line reason: $in_err"
    [[ -z $in_out ]] || fail "stdout should be empty: $in_out"
    [[ ! -s $STUB_DIR/calls ]] || fail "claude was called: $(cat "$STUB_DIR/calls")"
    [[ ! -s $STUB_DIR/git-calls ]] || fail "git was called: $(cat "$STUB_DIR/git-calls")"
}

# expect_no_pkg_calls: no package manager and no sudo was called.
expect_no_pkg_calls() {
    [[ ! -s $STUB_DIR/pkg-calls ]] || fail "a package manager was called: $(cat "$STUB_DIR/pkg-calls")"
}

t_latest_is_highest_release() {
    in_setup latest
    printf 'a\trefs/tags/v1.0.9\nb\trefs/tags/v1.0.10\nc\trefs/tags/v1.0.7\nd\trefs/tags/v2.0.0-rc1\ne\trefs/tags/nightly\n' >"$STUB_DIR/tags"
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $in_out == 'install: release v1.0.10'* ]] || fail "stdout: $in_out"
    grep -q 'ls-remote --tags --refs https://github.com/kbajpai/codeo v\*' "$STUB_DIR/git-calls" \
        || fail "ls-remote call: $(cat "$STUB_DIR/git-calls")"
}

t_given_tag_checked() {
    in_setup given
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    in_run --version v1.0.7
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    grep -q 'ls-remote --exit-code --tags https://github.com/kbajpai/codeo refs/tags/v1.0.7$' "$STUB_DIR/git-calls" \
        || fail "ls-remote call: $(cat "$STUB_DIR/git-calls")"
}

t_bare_version_gets_v() {
    in_setup bare
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    in_run --version 1.0.7
    [[ $in_out == 'install: release v1.0.7'* ]] || fail "stdout: $in_out"
    grep -q 'refs/tags/v1.0.7$' "$STUB_DIR/git-calls" || fail "call: $(cat "$STUB_DIR/git-calls")"
}

t_missing_tag_stops() {
    in_setup missing_tag
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    in_run --version v9.9.9
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    [[ $in_err == 'install: release v9.9.9 not found in kbajpai/codeo' ]] || fail "stderr: $in_err"
    [[ ! -s $STUB_DIR/calls ]] || fail "claude was called"
}

t_offline_stops() {
    in_setup offline
    echo 128 >"$STUB_DIR/ls-fail"
    in_run
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    [[ $in_err == 'install: cannot read the latest release: check the network and try again' ]] || fail "stderr: $in_err"
    [[ ! -s $STUB_DIR/calls ]] || fail "claude was called"
    in_run --version v1.0.7
    [[ $in_rc -eq 1 ]] || fail "given tag offline: exit $in_rc, want 1"
    [[ $in_err == 'install: cannot read the releases: check the network and try again' ]] || fail "stderr: $in_err"
}

t_no_tags_stops() {
    in_setup no_tags
    in_run
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    [[ $in_err == 'install: cannot read the latest release: check the network and try again' ]] || fail "stderr: $in_err"
    [[ ! -s $STUB_DIR/calls ]] || fail "claude was called"
}

t_no_args_ok_up_to_prereqs() {
    in_setup no_args
    printf 'a1\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc, want 0 (stderr: $in_err)"
    [[ $in_out == 'install: release v1.0.7'* && -z $in_err ]] || fail "out=$in_out err=$in_err"
    "$real_git" -C "$in_dir/work" init -q
    in_run --version v1.0.7 --scope project
    [[ $in_rc -eq 0 ]] || fail "valid args: exit $in_rc, want 0 (stderr: $in_err)"
    in_run --version 1.0.7
    [[ $in_rc -eq 0 ]] || fail "bare version: exit $in_rc, want 0 (stderr: $in_err)"
    expect_no_pkg_calls
}

t_help_prints_usage() {
    local flag
    for flag in -h --help; do
        in_setup help
        in_run "$flag"
        [[ $in_rc -eq 0 ]] || fail "$flag: exit $in_rc, want 0"
        [[ $in_out == "$usage_line" ]] || fail "$flag: stdout is: $in_out"
        [[ -z $in_err ]] || fail "$flag: stderr is: $in_err"
    done
}

t_unknown_option_usage() {
    in_setup unknown
    in_run --frobnicate
    expect_usage_error
    [[ $in_err == *'install: unknown option: --frobnicate'* ]] || fail "reason missing: $in_err"
    in_run stray
    expect_usage_error
}

t_version_without_value_usage() {
    in_setup version_no_value
    in_run --version
    expect_usage_error
    in_run --scope
    expect_usage_error
}

t_bad_version_usage() {
    local v
    in_setup bad_version
    for v in 'v1.0.7;x' latest 'v1.0' 'v1.0.7.1' ''; do
        in_run --version "$v"
        expect_usage_error
    done
}

t_bad_scope_usage() {
    in_setup bad_scope
    in_run --scope team
    expect_usage_error
}

t_old_bash() {
    in_setup old_bash
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    CODEO_TEST_BASH_VERSION=3.2 in_run
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    [[ $in_err == *'install: bash 4.3 or later is required (found 3.2)'* ]] || fail "stderr: $in_err"
    [[ $in_err == *"$closing"* ]] || fail "closing line missing: $in_err"
    [[ ! -s $STUB_DIR/calls ]] || fail "claude was called"
    CODEO_TEST_BASH_VERSION=4.2 in_run
    [[ $in_rc -eq 1 ]] || fail "4.2: exit $in_rc, want 1"
    CODEO_TEST_BASH_VERSION=4.3 in_run
    [[ $in_rc -eq 0 ]] || fail "4.3: exit $in_rc, want 0 (stderr: $in_err)"
    expect_no_pkg_calls
}

t_missing_each() {
    local tool want others o
    for tool in jq git gh claude; do
        in_setup "missing_$tool"
        in_hide "$tool"
        in_run
        [[ $in_rc -eq 1 ]] || fail "$tool: exit $in_rc, want 1"
        case $tool in
            claude) want='install: claude (Claude Code) is not installed' ;;
            *) want="install: $tool is not installed" ;;
        esac
        [[ $in_err == *"$want"* ]] || fail "$tool: stderr lacks '$want': $in_err"
        [[ $in_err == *"$closing"* ]] || fail "$tool: closing line missing: $in_err"
        for o in jq git gh claude; do
            [[ $o == "$tool" ]] && continue
            [[ $in_err != *"install: $o is not installed"* && $in_err != *"install: $o (Claude"* ]] \
                || fail "$tool: also reported $o: $in_err"
        done
        [[ $(grep -c '^install: ' <<<"$in_err") -eq 2 ]] || fail "$tool: want 2 lines: $in_err"
        expect_no_pkg_calls
    done
}

t_all_missing_named_together() {
    local expected
    in_setup all_missing
    in_hide jq git gh claude
    CODEO_TEST_BASH_VERSION=3.2 in_run
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    expected="install: bash 4.3 or later is required (found 3.2)
install: jq is not installed
install: git is not installed
install: gh is not installed
install: claude (Claude Code) is not installed
$closing"
    [[ $in_err == "$expected" ]] || fail "stderr was: $in_err"
    [[ -z $in_out ]] || fail "stdout should be empty: $in_out"
}

t_no_system_package_installed() {
    in_setup no_pkg
    in_hide jq git gh claude
    CODEO_TEST_BASH_VERSION=3.2 in_run
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    expect_no_pkg_calls
    in_run --scope project
    expect_no_pkg_calls
}

t_script_is_executable_with_bash_shebang() {
    [[ -x $script ]] || fail "install.sh is not executable"
    [[ $(head -1 "$script") == '#!/usr/bin/env bash' ]] || fail "shebang is: $(head -1 "$script")"
}

# seed_codeo <version> [<scope>]: codeo@codeo installed at the scope (user) and the marketplace pinned
# at v<version>; seed_superpowers [<id>]: superpowers installed at user scope.
seed_codeo() {
    local v=$1 s=${2:-user}
    jq --arg v "$v" --arg s "$s" '. + [{id: "codeo@codeo", version: $v, scope: $s, enabled: true, projectPath: "/x"}]' \
        "$STUB_DIR/list.json" >"$STUB_DIR/list.new" && mv "$STUB_DIR/list.new" "$STUB_DIR/list.json"
    jq --arg r "v$v" '.codeo = {source: {source: "github", repo: "kbajpai/codeo", ref: $r}}' \
        "$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json" >"$STUB_DIR/m.new" \
        && mv "$STUB_DIR/m.new" "$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json"
}
seed_superpowers() {
    local id=${1:-superpowers@superpowers-marketplace}
    jq --arg id "$id" '. + [{id: $id, version: "7.0.2", scope: "user", enabled: true, projectPath: "/x"}]' \
        "$STUB_DIR/list.json" >"$STUB_DIR/list.new" && mv "$STUB_DIR/list.new" "$STUB_DIR/list.json"
}

# expect_calls <line>...: the claude calls that are not `plugin list` are exactly these lines, in order.
expect_calls() {
    local got want
    got=$(grep -v '^plugin list' "$STUB_DIR/calls" || true)
    want=$(printf '%s\n' "$@")
    [[ $got == "$want" ]] || fail "claude calls were: $got"
}

# call_pwds <call>: the directory of every logged claude call that is exactly <call>, one per line.
call_pwds() {
    paste -d '\t' "$STUB_DIR/calls" "$STUB_DIR/pwds" | awk -F '\t' -v c="$1" '$1 == c { print $2 }'
}

t_fresh_user_install() {
    in_setup fresh
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $(sort -u "$STUB_DIR/pwds") == "$in_dir/home" ]] || fail "user scope ran in: $(sort -u "$STUB_DIR/pwds")"
    expect_calls 'plugin marketplace add obra/superpowers-marketplace' \
        'plugin install superpowers@superpowers-marketplace --scope user' \
        'plugin marketplace add kbajpai/codeo@v1.0.7' \
        'plugin install codeo@codeo --scope user'
    [[ $in_out == *'install: superpowers installed (user scope)'* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: codeo v1.0.7 installed (user scope)'* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: done - codeo v1.0.7, user scope, superpowers 7.0.2'* ]] || fail "stdout: $in_out"
}

t_rerun_changes_nothing() {
    in_setup rerun
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.7
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ -s $STUB_DIR/calls ]] || fail "claude was never asked"
    [[ -z $(grep -v '^plugin list' "$STUB_DIR/calls") ]] || fail "calls: $(cat "$STUB_DIR/calls")"
    [[ $in_out == *'install: superpowers already installed (user scope), left alone'* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: codeo v1.0.7 already installed (user scope)'* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: nothing changed - codeo v1.0.7, user scope, superpowers 7.0.2' ]] || fail "stdout: $in_out"
}

t_default_scope_is_user() {
    in_setup default_scope
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    in_run
    [[ $in_out == *'user scope'* ]] || fail "stdout: $in_out"
    [[ $(jq -r '.[].scope' "$STUB_DIR/list.json" | sort -u) == user ]] || fail "list: $(cat "$STUB_DIR/list.json")"
}

t_given_tag_installed() {
    in_setup given_installed
    printf 'a\trefs/tags/v1.0.7\nb\trefs/tags/v1.0.6\n' >"$STUB_DIR/tags"
    in_run --version v1.0.6
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    grep -qx 'plugin marketplace add kbajpai/codeo@v1.0.6' "$STUB_DIR/calls" || fail "calls: $(cat "$STUB_DIR/calls")"
    [[ $in_out == *'install: done - codeo v1.0.6, user scope, superpowers 7.0.2'* ]] || fail "stdout: $in_out"
}

t_latest_installed_without_version() {
    in_setup latest_installed
    printf 'a\trefs/tags/v1.0.7\nb\trefs/tags/v1.0.9\n' >"$STUB_DIR/tags"
    in_run
    grep -qx 'plugin marketplace add kbajpai/codeo@v1.0.9' "$STUB_DIR/calls" || fail "calls: $(cat "$STUB_DIR/calls")"
    [[ $in_out == *'install: done - codeo v1.0.9, user scope, superpowers 7.0.2'* ]] || fail "stdout: $in_out"
}

t_superpowers_from_other_marketplace_left_alone() {
    in_setup sp_other
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers superpowers@elsewhere
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls 'plugin marketplace add kbajpai/codeo@v1.0.7' 'plugin install codeo@codeo --scope user'
    [[ $in_out == *'install: superpowers already installed (user scope), left alone'* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: done - codeo v1.0.7, user scope, superpowers 7.0.2'* ]] || fail "stdout: $in_out"
}

t_missing_known_marketplaces_file_is_fresh() {
    in_setup no_market_file
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    rm -f "$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json"
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    grep -qx 'plugin marketplace add kbajpai/codeo@v1.0.7' "$STUB_DIR/calls" || fail "calls: $(cat "$STUB_DIR/calls")"
}

t_plugin_list_failure_stops() {
    in_setup list_fail
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    : >"$STUB_DIR/list-fail"
    in_run
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    [[ $in_err == *'install: cannot read the installed plugins (claude plugin list failed)'* ]] || fail "stderr: $in_err"
    [[ -z $(grep -v '^plugin list' "$STUB_DIR/calls") ]] || fail "calls: $(cat "$STUB_DIR/calls")"
}

# The stub prints $STUB_DIR/list-pre and list-post (notice lines) around the list; list-compact prints the
# array on one line; list-nojson prints no JSON at all.
t_list_with_a_notice_before_the_json() {
    in_setup list_notice_before
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.7
    echo 'Notice: a new claude version is available' >"$STUB_DIR/list-pre"
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $in_out == *'install: nothing changed - codeo v1.0.7, user scope, superpowers 7.0.2' ]] || fail "stdout: $in_out"
}

t_list_with_a_notice_after_the_json() {
    in_setup list_notice_after
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.7
    echo 'Notice: update available [x]' >"$STUB_DIR/list-post"
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $in_out == *'install: nothing changed - codeo v1.0.7, user scope, superpowers 7.0.2' ]] || fail "stdout: $in_out"
}

t_list_compact_json_with_a_notice() {
    in_setup list_notice_compact
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.7
    echo 'Notice: before' >"$STUB_DIR/list-pre"
    echo 'Notice: after' >"$STUB_DIR/list-post"
    : >"$STUB_DIR/list-compact"
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $in_out == *'install: nothing changed - codeo v1.0.7, user scope, superpowers 7.0.2' ]] || fail "stdout: $in_out"
}

t_list_notice_does_not_hide_dropped_installs() {
    in_setup list_notice_dropped
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.6
    seed_local 1.0.6 /some/local
    echo 'Notice: before' >"$STUB_DIR/list-pre"
    echo 'Notice: after' >"$STUB_DIR/list-post"
    : >"$STUB_DIR/list-compact"
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $in_out == *"$(dropped_line /some/local local 1.0.6)"* ]] || fail "stdout: $in_out"
}

t_list_with_no_json_dies_cleanly() {
    in_setup list_no_json
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    echo 'Notice: nothing to see' >"$STUB_DIR/list-pre"
    : >"$STUB_DIR/list-nojson"
    in_run
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    [[ $in_err == *'install: cannot read the installed plugins (claude plugin list failed)'* ]] || fail "stderr: $in_err"
    [[ $in_err != *jq* && $in_err != *parse* ]] || fail "jq text leaked: $in_err"
}

t_runs_from_a_pipe() {
    in_setup pipe
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    : >"$STUB_DIR/drain"
    in_rc=0
    # A line after the script: bash would run it once the script is done, unless a call ate the pipe.
    (cd "$in_dir/work" && { cat "$script"; echo 'echo pipe-intact'; } | env -i PATH="$in_dir/bin" HOME="$in_dir/home" STUB_DIR="$STUB_DIR" \
        CLAUDE_CONFIG_DIR="$CLAUDE_CONFIG_DIR" "$bash_abs" -s --) >"$in_dir/out" 2>"$in_dir/err" || in_rc=$?
    in_out=$(cat "$in_dir/out")
    in_err=$(cat "$in_dir/err")
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls 'plugin marketplace add obra/superpowers-marketplace' \
        'plugin install superpowers@superpowers-marketplace --scope user' \
        'plugin marketplace add kbajpai/codeo@v1.0.7' \
        'plugin install codeo@codeo --scope user'
    [[ $in_out == *'install: done - codeo v1.0.7, user scope, superpowers 7.0.2'* ]] || fail "stdout: $in_out"
    [[ $in_out == *pipe-intact ]] || fail "a call read the script from the pipe: $in_out"
}

t_restart_hint_only_when_changed() {
    in_setup restart
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    in_run
    [[ $in_out == *'install: done'*$'\n'*'restart'* ]] || fail "no restart line after a change: $in_out"
    in_run
    [[ $in_out == *'install: nothing changed'* ]] || fail "second run: $in_out"
    [[ $in_out != *restart* ]] || fail "restart line on a no-op: $in_out"
}

# seed_pin <repo> <ref>: the codeo marketplace declared at that repo and ref.
seed_pin() {
    jq --arg p "$1" --arg r "$2" '.codeo = {source: {source: "github", repo: $p, ref: $r}}' \
        "$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json" >"$STUB_DIR/m.new" \
        && mv "$STUB_DIR/m.new" "$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json"
}

t_replace_older() {
    in_setup replace_older
    printf 'a\trefs/tags/v1.0.7\nb\trefs/tags/v1.0.6\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.6
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls 'plugin marketplace remove codeo' \
        'plugin marketplace add kbajpai/codeo@v1.0.7' \
        'plugin install codeo@codeo --scope user'
    [[ $in_out == *'install: codeo v1.0.6 -> v1.0.7 (user scope)'* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: done - codeo v1.0.7, user scope, superpowers 7.0.2'* ]] || fail "stdout: $in_out"
    [[ $in_out == *restart* ]] || fail "no restart line: $in_out"
    [[ $(call_pwds 'plugin marketplace remove codeo') == "$in_dir/home" ]] || fail "remove ran in: $(call_pwds 'plugin marketplace remove codeo')"
}

t_replace_checks_tag_first() {
    in_setup replace_tag_first
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_codeo 1.0.6
    in_run --version v9.9.9
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    ! grep -q 'marketplace remove' "$STUB_DIR/calls" || fail "removed before the tag check: $(cat "$STUB_DIR/calls")"
    [[ -z $(grep -v '^plugin list' "$STUB_DIR/calls") ]] || fail "calls: $(cat "$STUB_DIR/calls")"
}

# project_json <ref>: a project's committed .claude/settings.json pinning codeo at that ref.
project_json() {
    printf '{"enabledPlugins":{"codeo@codeo":true},"extraKnownMarketplaces":{"codeo":{"source":{"source":"github","repo":"kbajpai/codeo","ref":"%s"}}}}\n' "$1"
}

t_user_replace_leaves_the_project_file() {
    local top
    in_setup user_replace_project
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    mkdir -p "$in_dir/work/a/b" "$top/.claude"
    seed_superpowers
    seed_codeo 1.0.6
    seed_project codeo@codeo 1.0.6 "$top"
    project_json v1.0.6 >"$top/.claude/settings.json"
    cp "$top/.claude/settings.json" "$in_dir/before"
    in_cwd="$in_dir/work/a/b" in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls 'plugin marketplace remove codeo' \
        'plugin marketplace add kbajpai/codeo@v1.0.7' \
        'plugin install codeo@codeo --scope user'
    ! grep -q -- '--scope project' "$STUB_DIR/calls" || fail "a project-scope call ran: $(cat "$STUB_DIR/calls")"
    cmp -s "$in_dir/before" "$top/.claude/settings.json" || fail "the project file changed: $(cat "$top/.claude/settings.json")"
    [[ $in_out == *"$(dropped_line "$top" project 1.0.6)"* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: codeo v1.0.6 -> v1.0.7 (user scope)'* ]] || fail "stdout: $in_out"
    [[ $(jq -r '[.[] | select(.id == "codeo@codeo" and .scope == "user")] | .[0].version' "$STUB_DIR/list.json") == 1.0.7 ]] \
        || fail "list: $(cat "$STUB_DIR/list.json")"
}

t_user_replace_names_another_project_only() {
    local top
    in_setup user_replace_alone
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    seed_superpowers
    seed_codeo 1.0.6
    seed_project codeo@codeo 1.0.6 /somewhere/else
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $in_out == *'install: codeo v1.0.6 -> v1.0.7 (user scope)'* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: codeo is no longer installed for /somewhere/else (project scope, v1.0.6)'* ]] || fail "stdout: $in_out"
    [[ $in_out != *"for $top "* ]] || fail "stdout: $in_out"
    [[ $in_out != *"moved to"* ]] || fail "stdout: $in_out"
}

# dropped_line <path> <scope> <version>: the line a replace prints for a project or local install it dropped.
dropped_line() {
    local sfx="" tail="run install.sh --scope project there to restore it"
    [[ $2 != local ]] || { sfx=.local; tail="run claude plugin install codeo@codeo --scope local there to restore it"; }
    printf 'install: codeo is no longer installed for %s (%s scope, v%s); its .claude/settings%s.json was not changed; %s' "$1" "$2" "$3" "$sfx" "$tail"
}

# seed_local <version> <projectPath>: a local-scope codeo entry.
seed_local() {
    jq --arg v "$1" --arg p "$2" '. + [{id: "codeo@codeo", version: $v, scope: "local", enabled: true, projectPath: $p}]' \
        "$STUB_DIR/list.json" >"$STUB_DIR/list.new" && mv "$STUB_DIR/list.new" "$STUB_DIR/list.json"
}

# two_projects: a user copy plus project installs A and B at v1.0.6, each with a committed settings file.
# Sets the caller's locals pa and pb (pa is kept when the caller preset it).
two_projects() {
    pa=${pa:-$in_dir/pa}
    pb="$in_dir/pb"
    mkdir -p "$pa/.claude" "$pb/.claude"
    seed_superpowers
    seed_codeo 1.0.6
    seed_project codeo@codeo 1.0.6 "$pa"
    seed_project codeo@codeo 1.0.6 "$pb"
    project_json v1.0.6 >"$pa/.claude/settings.json"
    project_json v1.0.6 >"$pb/.claude/settings.json"
    cp "$pa/.claude/settings.json" "$in_dir/before-a"
    cp "$pb/.claude/settings.json" "$in_dir/before-b"
}

t_user_replace_names_every_dropped_project() {
    local pa="" pb want
    in_setup dropped_every
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    two_projects
    in_cwd="$in_dir/home" in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    want=$(printf '%s\n%s' "$(dropped_line "$pa" project 1.0.6)" "$(dropped_line "$pb" project 1.0.6)")
    [[ $in_out == *'install: codeo v1.0.6 -> v1.0.7 (user scope)'$'\n'"$want"* ]] || fail "stdout: $in_out"
    [[ $(grep -c 'no longer installed for' <<<"$in_out") -eq 2 ]] || fail "want exactly 2 dropped lines, the two projects (the user entry is not named): $in_out"
    ! grep -q -- '--scope project' "$STUB_DIR/calls" || fail "a project-scope call ran: $(cat "$STUB_DIR/calls")"
    cmp -s "$in_dir/before-a" "$pa/.claude/settings.json" || fail "A's file changed"
    cmp -s "$in_dir/before-b" "$pb/.claude/settings.json" || fail "B's file changed"
}

t_user_replace_names_the_current_project_too() {
    local pa="" pb
    in_setup dropped_current
    pa="$in_dir/pa"
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    mkdir -p "$pa"
    "$real_git" -C "$pa" init -q
    pa=$("$real_git" -C "$pa" rev-parse --show-toplevel)
    two_projects
    in_cwd="$pa" in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $in_out == *"$(dropped_line "$pa" project 1.0.6)"* ]] || fail "A not named: $in_out"
    [[ $in_out == *"$(dropped_line "$pb" project 1.0.6)"* ]] || fail "B not named: $in_out"
}

t_project_replace_names_the_other_projects() {
    local pa pb top
    in_setup dropped_project_run
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    pa=$top
    two_projects
    seed_project superpowers@superpowers-marketplace 7.0.2 "$top"
    in_run --scope project
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $in_out == *'your user-scope codeo moved to v1.0.7 too: one machine holds one codeo version'$'\n'"$(dropped_line "$pb" project 1.0.6)"* ]] \
        || fail "stdout: $in_out"
    [[ $in_out != *"for $pa "* ]] || fail "own project named: $in_out"
}

t_dropped_local_entry_is_named_with_its_command() {
    in_setup dropped_local
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.6
    seed_local 1.0.6 /some/local
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $in_out == *"$(dropped_line /some/local local 1.0.6)"* ]] || fail "stdout: $in_out"
}

t_dropped_project_that_no_longer_exists_is_named() {
    in_setup dropped_gone
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.6
    seed_project codeo@codeo 1.0.6 /no/such/dir
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $in_out == *"$(dropped_line /no/such/dir project 1.0.6)"* ]] || fail "stdout: $in_out"
}

t_no_replace_no_dropped_lines() {
    in_setup dropped_none
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    in_run
    [[ $in_out != *"no longer installed for"* ]] || fail "fresh install: $in_out"
    in_run
    [[ $in_out != *"no longer installed for"* ]] || fail "re-run: $in_out"
}

t_project_replace_says_the_disabled_user_copy_is_enabled() {
    local top
    in_setup project_replace_user_on
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    seed_superpowers
    seed_codeo 1.0.6
    seed_project codeo@codeo 1.0.6 "$top"
    in_run --scope project
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $in_out == *'one machine holds one codeo version'* ]] || fail "stdout: $in_out"
    [[ $in_out != *'it was disabled'* ]] || fail "enabled copy called disabled: $in_out"
    in_setup project_replace_user_off
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    seed_superpowers
    seed_codeo 1.0.6
    jq 'map(if .id == "codeo@codeo" then .enabled = false else . end)' "$STUB_DIR/list.json" >"$STUB_DIR/list.new" \
        && mv "$STUB_DIR/list.new" "$STUB_DIR/list.json"
    seed_project codeo@codeo 1.0.6 "$top"
    in_run --scope project
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $in_out == *"install: your user-scope codeo moved to v1.0.7 too: one machine holds one codeo version (it was disabled; it is enabled now)"* ]] \
        || fail "stdout: $in_out"
}

t_nonnumeric_test_bash_version_is_ignored() {
    local v
    for v in abc 4.x x.3 4.3.1 .3 4. " 4.3" " 4.2" ""; do
        in_setup nonnumeric_bash
        printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
        CODEO_TEST_BASH_VERSION=$v in_run
        [[ $in_rc -eq 0 ]] || fail "'$v': exit $in_rc (stderr: $in_err)"
        [[ -z $in_err ]] || fail "'$v': stderr: $in_err"
    done
}

# The head of install.sh (code before `set -euo pipefail`, comments dropped) must parse in bash 3.2.
t_head_uses_no_bash4_syntax() {
    local head p
    head=$(sed '/^set -euo pipefail$/,$d' "$script" | grep -v '^[[:space:]]*#')
    [[ -n $head ]] || fail "no head found"
    for p in '\[\[ -v' 'declare -A' 'local -A' ',,}' '\^\^}' 'mapfile' 'readarray' '&>>' '|&' 'coproc' '\[\[.*=~'; do
        ! grep -q -e "$p" <<<"$head" || fail "head of install.sh uses bash-4 syntax: $p"
    done
}

t_project_replace_moves_the_user_copy() {
    local top
    in_setup project_replace_user
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    seed_project superpowers@superpowers-marketplace 7.0.2 "$top"
    seed_codeo 1.0.6
    seed_project codeo@codeo 1.0.6 "$top"
    in_run --scope project
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls 'plugin marketplace remove codeo' \
        'plugin marketplace add kbajpai/codeo@v1.0.7' \
        'plugin marketplace add kbajpai/codeo@v1.0.7 --scope project' \
        'plugin install codeo@codeo --scope project' \
        'plugin install codeo@codeo --scope user'
    [[ $(call_pwds 'plugin marketplace remove codeo') == "$in_dir/home" ]] || fail "remove ran in: $(call_pwds 'plugin marketplace remove codeo')"
    [[ $(call_pwds 'plugin marketplace add kbajpai/codeo@v1.0.7') == "$in_dir/home" ]] || fail "user add ran in: $(call_pwds 'plugin marketplace add kbajpai/codeo@v1.0.7')"
    [[ $(call_pwds 'plugin marketplace add kbajpai/codeo@v1.0.7 --scope project') == "$top" ]] || fail "project add ran in: $(call_pwds 'plugin marketplace add kbajpai/codeo@v1.0.7 --scope project')"
    [[ $(call_pwds 'plugin install codeo@codeo --scope project') == "$top" ]] || fail "project install ran in: $(call_pwds 'plugin install codeo@codeo --scope project')"
    [[ $(call_pwds 'plugin install codeo@codeo --scope user') == "$in_dir/home" ]] || fail "user install ran in: $(call_pwds 'plugin install codeo@codeo --scope user')"
    [[ $in_out == *'install: codeo v1.0.6 -> v1.0.7 (project scope)'$'\n'*'install: your user-scope codeo moved to v1.0.7 too: one machine holds one codeo version'* ]] \
        || fail "stdout: $in_out"
    [[ $(jq -r '.extraKnownMarketplaces.codeo.source.ref' "$CLAUDE_CONFIG_DIR/settings.json") == v1.0.7 ]] \
        || fail "user settings: $(cat "$CLAUDE_CONFIG_DIR/settings.json" 2>&1)"
}

t_project_replace_without_user_copy() {
    local top
    in_setup project_replace_alone
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    seed_project superpowers@superpowers-marketplace 7.0.2 "$top"
    seed_pin kbajpai/codeo v1.0.6
    seed_project codeo@codeo 1.0.6 "$top"
    in_run --scope project
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls 'plugin marketplace remove codeo' \
        'plugin marketplace add kbajpai/codeo@v1.0.7 --scope project' \
        'plugin install codeo@codeo --scope project'
    [[ $in_out != *"moved to"* ]] || fail "stdout: $in_out"
    [[ ! -f $CLAUDE_CONFIG_DIR/settings.json ]] || fail "user settings were written: $(cat "$CLAUDE_CONFIG_DIR/settings.json")"
}

t_project_replace_from_subdirectory() {
    local top p
    in_setup project_replace_subdir
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    mkdir -p "$in_dir/work/a/b"
    seed_project superpowers@superpowers-marketplace 7.0.2 "$top"
    seed_pin kbajpai/codeo v1.0.6
    seed_project codeo@codeo 1.0.6 "$top"
    in_cwd="$in_dir/work/a/b" in_run --scope project
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls 'plugin marketplace remove codeo' \
        'plugin marketplace add kbajpai/codeo@v1.0.7 --scope project' \
        'plugin install codeo@codeo --scope project'
    for p in 'plugin marketplace add kbajpai/codeo@v1.0.7 --scope project' 'plugin install codeo@codeo --scope project'; do
        [[ $(call_pwds "$p") == "$top" ]] || fail "'$p' ran in: $(call_pwds "$p"), want $top"
    done
    [[ $(call_pwds 'plugin marketplace remove codeo') == "$in_dir/home" ]] || fail "remove ran in: $(call_pwds 'plugin marketplace remove codeo')"
}

t_installed_check_goes_by_the_pin() {
    in_setup pin_check
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.0
    seed_pin kbajpai/codeo v1.0.7
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ -s $STUB_DIR/calls ]] || fail "claude was never asked"
    [[ -z $(grep -v '^plugin list' "$STUB_DIR/calls") ]] || fail "calls: $(cat "$STUB_DIR/calls")"
    [[ $in_out == *'install: codeo v1.0.7 already installed (user scope)'* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: nothing changed'* ]] || fail "stdout: $in_out"
}

t_user_install_declares_the_marketplace_when_only_a_project_declared_it() {
    local top
    in_setup user_declares
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    seed_superpowers
    seed_pin kbajpai/codeo v1.0.7
    seed_project codeo@codeo 1.0.7 "$top"
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls 'plugin marketplace add kbajpai/codeo@v1.0.7' 'plugin install codeo@codeo --scope user'
    [[ $(jq -r '.extraKnownMarketplaces.codeo.source.ref' "$CLAUDE_CONFIG_DIR/settings.json") == v1.0.7 ]] \
        || fail "user settings: $(cat "$CLAUDE_CONFIG_DIR/settings.json" 2>&1)"
}

t_replace_project_scope() {
    local top
    in_setup replace_project
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    seed_project superpowers@superpowers-marketplace 7.0.2 "$top"
    seed_pin kbajpai/codeo v1.0.6
    seed_project codeo@codeo 1.0.6 "$top"
    in_run --scope project
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls 'plugin marketplace remove codeo' \
        'plugin marketplace add kbajpai/codeo@v1.0.7 --scope project' \
        'plugin install codeo@codeo --scope project'
    [[ $in_out == *'install: codeo v1.0.6 -> v1.0.7 (project scope)'* ]] || fail "stdout: $in_out"
    [[ $(call_pwds 'plugin marketplace remove codeo') == "$in_dir/home" ]] || fail "remove ran in: $(call_pwds 'plugin marketplace remove codeo')"
    [[ $(call_pwds 'plugin install codeo@codeo --scope project') == "$top" ]] || fail "install ran in: $(call_pwds 'plugin install codeo@codeo --scope project')"
}

t_replace_fork_marketplace() {
    in_setup replace_fork
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.7
    seed_pin someone/codeo v1.0.7
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls 'plugin marketplace remove codeo' \
        'plugin marketplace add kbajpai/codeo@v1.0.7' \
        'plugin install codeo@codeo --scope user'
    [[ $(jq -r '.codeo.source.repo' "$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json") == kbajpai/codeo ]] \
        || fail "marketplace: $(cat "$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json")"
    [[ $in_out == *'install: codeo someone/codeo@v1.0.7 -> v1.0.7 (user scope)'* ]] || fail "stdout: $in_out"
}

t_replace_source_without_repo() {
    in_setup replace_norepo
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    jq '.codeo = {source: {source: "url", url: "https://example.com/codeo.git"}}' \
        "$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json" >"$STUB_DIR/m.new" \
        && mv "$STUB_DIR/m.new" "$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json"
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $in_out == *'install: codeo unknown source -> v1.0.7 (user scope)'* ]] || fail "stdout: $in_out"
    [[ $in_out != *'@ '* ]] || fail "stdout: $in_out"
}

t_replace_failure_reported() {
    in_setup replace_failure
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.6
    : >"$STUB_DIR/add-fail"
    in_run
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    [[ $in_err == 'install: codeo is no longer installed: stub claude: add failed; run this again' ]] || fail "stderr: $in_err"
    grep -qx 'plugin marketplace remove codeo' "$STUB_DIR/calls" || fail "calls: $(cat "$STUB_DIR/calls")"
}

t_replace_install_failure_after_add() {
    in_setup replace_install_failure
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.6
    : >"$STUB_DIR/install-fail-codeo"
    in_run
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    [[ $in_err == 'install: codeo is no longer installed: stub claude: install failed; run this again' ]] || fail "stderr: $in_err"
    grep -qx 'plugin marketplace add kbajpai/codeo@v1.0.7' "$STUB_DIR/calls" || fail "calls: $(cat "$STUB_DIR/calls")"
}

t_replace_second_scope_failure_names_both() {
    local top
    in_setup replace_second_scope
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    seed_superpowers
    seed_project superpowers@superpowers-marketplace 7.0.2 "$top"
    seed_codeo 1.0.6
    seed_project codeo@codeo 1.0.6 "$top"
    : >"$STUB_DIR/install-fail-codeo-user"
    in_run --scope project
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    [[ $in_err == 'install: codeo v1.0.7 is installed at project scope but not at user scope: stub claude: install failed; run this again with --scope user' ]] || fail "stderr: $in_err"
    [[ $in_err != *'no longer installed'* ]] || fail "stderr: $in_err"
}

t_replace_first_failure_keeps_no_longer_installed() {
    in_setup replace_first_failure
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.6
    : >"$STUB_DIR/install-fail-codeo"
    in_run
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    [[ $in_err == 'install: codeo is no longer installed: stub claude: install failed; run this again' ]] || fail "stderr: $in_err"
    grep -qx 'plugin marketplace add kbajpai/codeo@v1.0.7' "$STUB_DIR/calls" || fail "calls: $(cat "$STUB_DIR/calls")"
}

t_replace_project_failure_names_the_wiped_user_copy() {
    local top sw
    for sw in add-fail install-fail-codeo-project; do
        in_setup "replace_project_failure_$sw"
        printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
        project_repo
        seed_superpowers
        seed_project superpowers@superpowers-marketplace 7.0.2 "$top"
        seed_codeo 1.0.6
        seed_project codeo@codeo 1.0.6 "$top"
        : >"$STUB_DIR/$sw"
        in_run --scope project
        [[ $in_rc -eq 1 ]] || fail "$sw: exit $in_rc, want 1"
        [[ $in_err == 'install: codeo is no longer installed: stub claude: '*'; run this again with --scope project, then once without --scope to restore your user-scope copy' ]] || fail "$sw: stderr: $in_err"
    done
}

t_given_tag_other_git_failure_is_cannot_read() {
    in_setup given_tag_git_failure
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    echo 1 >"$STUB_DIR/ls-fail"
    in_run --version v1.0.7
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    [[ $in_err == 'install: cannot read the releases: check the network and try again' ]] || fail "stderr: $in_err"
    echo 2 >"$STUB_DIR/ls-fail"
    in_run --version v1.0.7
    [[ $in_rc -eq 1 ]] || fail "exit 2: exit $in_rc, want 1"
    [[ $in_err == 'install: release v1.0.7 not found in kbajpai/codeo' ]] || fail "exit 2: stderr: $in_err"
}

t_remove_failure_reported() {
    in_setup remove_failure
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.6
    : >"$STUB_DIR/remove-fail"
    in_run
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    [[ $in_err == 'install: cannot remove the codeo marketplace: stub claude: remove failed' ]] || fail "stderr: $in_err"
    expect_calls 'plugin marketplace remove codeo'
}

t_corrupt_marketplaces_file() {
    in_setup corrupt_market
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    echo 'not json {' >"$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json"
    in_run
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    [[ $in_err == "install: cannot read the marketplaces ($CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json is not valid JSON)" ]] || fail "stderr: $in_err"
}

t_superpowers_failures_reported() {
    local sw
    for sw in add-fail-superpowers install-fail-superpowers; do
        in_setup "sp_fail_$sw"
        printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
        : >"$STUB_DIR/$sw"
        in_run
        [[ $in_rc -eq 1 ]] || fail "$sw: exit $in_rc, want 1"
        [[ $in_err == 'install: superpowers is not installed: stub claude: '* ]] || fail "$sw: stderr: $in_err"
        [[ $in_err != *'no longer'* ]] || fail "$sw: stderr: $in_err"
    done
}

t_codeo_failures_reported() {
    local sw
    for sw in add-fail install-fail-codeo; do
        in_setup "codeo_fail_$sw"
        printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
        seed_superpowers
        : >"$STUB_DIR/$sw"
        in_run
        [[ $in_rc -eq 1 ]] || fail "$sw: exit $in_rc, want 1"
        [[ $in_err == 'install: codeo is not installed: stub claude: '* ]] || fail "$sw: stderr: $in_err"
    done
}

t_disabled_superpowers_is_enabled() {
    in_setup disabled_sp
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.7
    jq 'map(if .id | startswith("superpowers@") then .enabled = false else . end)' "$STUB_DIR/list.json" >"$STUB_DIR/list.new" \
        && mv "$STUB_DIR/list.new" "$STUB_DIR/list.json"
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls 'plugin enable superpowers@superpowers-marketplace --scope user'
    [[ $in_out == *'install: superpowers enabled (user scope)'* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: done - codeo v1.0.7, user scope, superpowers 7.0.2'* ]] || fail "stdout: $in_out"
    [[ $(jq '[.[] | select(.enabled == false)] | length' "$STUB_DIR/list.json") -eq 0 ]] || fail "list: $(cat "$STUB_DIR/list.json")"
}

t_disabled_codeo_is_enabled() {
    in_setup disabled_codeo
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.7
    jq 'map(if .id == "codeo@codeo" then .enabled = false else . end)' "$STUB_DIR/list.json" >"$STUB_DIR/list.new" \
        && mv "$STUB_DIR/list.new" "$STUB_DIR/list.json"
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls 'plugin enable codeo@codeo --scope user'
    [[ $in_out == *'install: codeo v1.0.7 enabled (user scope)'* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: done - codeo v1.0.7, user scope, superpowers 7.0.2'* ]] || fail "stdout: $in_out"
    [[ $in_out == *restart* ]] || fail "no restart line: $in_out"
    [[ $(jq '[.[] | select(.enabled == false)] | length' "$STUB_DIR/list.json") -eq 0 ]] || fail "list: $(cat "$STUB_DIR/list.json")"
}

t_downgrade_with_given_tag() {
    in_setup downgrade
    printf 'a\trefs/tags/v1.0.7\nb\trefs/tags/v1.0.6\n' >"$STUB_DIR/tags"
    seed_superpowers
    seed_codeo 1.0.7
    in_run --version v1.0.6
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls 'plugin marketplace remove codeo' \
        'plugin marketplace add kbajpai/codeo@v1.0.6' \
        'plugin install codeo@codeo --scope user'
    [[ $in_out == *'install: codeo v1.0.7 -> v1.0.6 (user scope)'* ]] || fail "stdout: $in_out"
}

# project_repo: the work directory becomes a git repository; sets top (the caller's local) to its top level.
project_repo() {
    "$real_git" -C "$in_dir/work" init -q
    top=$("$real_git" -C "$in_dir/work" rev-parse --show-toplevel)
}

# seed_project <id> <version> <projectPath>: a project-scope entry.
seed_project() {
    jq --arg id "$1" --arg v "$2" --arg p "$3" '. + [{id: $id, version: $v, scope: "project", enabled: true, projectPath: $p}]' \
        "$STUB_DIR/list.json" >"$STUB_DIR/list.new" && mv "$STUB_DIR/list.new" "$STUB_DIR/list.json"
}

project_calls=(
    'plugin marketplace add obra/superpowers-marketplace --scope project'
    'plugin install superpowers@superpowers-marketplace --scope project'
    'plugin marketplace add kbajpai/codeo@v1.0.7 --scope project'
    'plugin install codeo@codeo --scope project'
)

t_project_scope_installs_both() {
    local top
    in_setup project_both
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    in_run --scope project
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls "${project_calls[@]}"
    [[ $in_out == *'install: superpowers installed (project scope)'* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: codeo v1.0.7 installed (project scope)'* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: done - codeo v1.0.7, project scope, superpowers 7.0.2'* ]] || fail "stdout: $in_out"
    [[ $(jq -r '.[].projectPath' "$STUB_DIR/list.json" | sort -u) == "$top" ]] || fail "list: $(cat "$STUB_DIR/list.json")"
}

t_project_scope_outside_repo() {
    in_setup project_outside
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    in_run --scope project
    [[ $in_rc -eq 1 ]] || fail "exit $in_rc, want 1"
    [[ $in_err == "install: project scope must run inside the project's git repository" ]] || fail "stderr: $in_err"
    [[ ! -s $STUB_DIR/calls ]] || fail "claude was called: $(cat "$STUB_DIR/calls")"
}

t_project_scope_from_subdirectory() {
    local top
    in_setup project_subdir
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    mkdir -p "$in_dir/work/a/b"
    in_rc=0
    (cd "$in_dir/work/a/b" && env -i PATH="$in_dir/bin" HOME="$in_dir/home" STUB_DIR="$STUB_DIR" \
        CLAUDE_CONFIG_DIR="$CLAUDE_CONFIG_DIR" "$bash_abs" "$script" --scope project) >"$in_dir/out" 2>"$in_dir/err" || in_rc=$?
    in_out=$(cat "$in_dir/out")
    in_err=$(cat "$in_dir/err")
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $in_out == *'install: done - codeo v1.0.7, project scope, superpowers 7.0.2'* ]] || fail "stdout: $in_out"
    [[ $(sort -u "$STUB_DIR/pwds") == "$top" ]] || fail "claude ran in: $(sort -u "$STUB_DIR/pwds")"
    [[ $(jq -r '.[].projectPath' "$STUB_DIR/list.json" | sort -u) == "$top" ]] || fail "list: $(cat "$STUB_DIR/list.json")"
}

t_project_rerun_changes_nothing() {
    local top
    in_setup project_rerun
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    in_run --scope project
    [[ $in_rc -eq 0 ]] || fail "first run: exit $in_rc (stderr: $in_err)"
    : >"$STUB_DIR/calls"
    in_run --scope project
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ -s $STUB_DIR/calls ]] || fail "claude was never asked"
    [[ -z $(grep -v '^plugin list' "$STUB_DIR/calls") ]] || fail "calls: $(cat "$STUB_DIR/calls")"
    [[ $in_out == *'install: superpowers already installed (project scope), left alone'* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: codeo v1.0.7 already installed (project scope)'* ]] || fail "stdout: $in_out"
    [[ $in_out == *'install: nothing changed - codeo v1.0.7, project scope, superpowers 7.0.2' ]] || fail "stdout: $in_out"
}

t_project_after_user_install() {
    local top
    in_setup project_after_user
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    seed_superpowers
    seed_codeo 1.0.7
    in_run --scope project
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls "${project_calls[@]}"
    [[ $in_out == *"codeo already on disk"* ]] || fail "claude output was hidden: $in_out"
    [[ $in_out == *'install: done - codeo v1.0.7, project scope, superpowers 7.0.2'* ]] || fail "stdout: $in_out"
    [[ $(jq '[.[] | select(.scope == "user")] | length' "$STUB_DIR/list.json") -eq 2 ]] || fail "user entries changed: $(cat "$STUB_DIR/list.json")"
    [[ $(jq --arg t "$top" '[.[] | select(.scope == "project" and .projectPath == $t)] | length' "$STUB_DIR/list.json") -eq 2 ]] \
        || fail "list: $(cat "$STUB_DIR/list.json")"
}

t_other_projects_install_not_counted() {
    local top
    in_setup project_other
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    seed_project superpowers@superpowers-marketplace 7.0.2 /somewhere/else
    seed_project codeo@codeo 1.0.7 /somewhere/else
    seed_pin kbajpai/codeo v1.0.7
    in_run --scope project
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    expect_calls "${project_calls[@]}"
    [[ $(jq --arg t "$top" '[.[] | select(.projectPath == $t)] | length' "$STUB_DIR/list.json") -eq 2 ]] || fail "list: $(cat "$STUB_DIR/list.json")"
}

# readme_headings <file> <level-prefix>: the headings of that level, outside code fences.
readme_headings() {
    awk -v p="$2 " '/^```/{f=!f} !f && index($0, p) == 1 {print}' "$1"
}

# readme_snippet: the README's project snippet, its first ```json fenced block.
readme_snippet() {
    awk '/^```json$/ { on = 1; next } /^```$/ && on { exit } on' "$repo/README.md"
}

t_project_scope_writes_the_readme_snippet() {
    local top
    in_setup project_snippet
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    in_run --scope project
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ -n $(readme_snippet) ]] || fail "the README has no json snippet"
    [[ $(jq -S . "$top/.claude/settings.json") == "$(readme_snippet | jq -S .)" ]] \
        || fail "project settings differ from the README snippet: $(cat "$top/.claude/settings.json" 2>&1)"
}

t_user_scope_declares_in_user_settings() {
    in_setup user_settings
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    in_run
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ $(jq -r '.extraKnownMarketplaces.codeo.source.ref' "$CLAUDE_CONFIG_DIR/settings.json") == v1.0.7 ]] \
        || fail "user settings: $(cat "$CLAUDE_CONFIG_DIR/settings.json" 2>&1)"
    [[ $(jq -r '.enabledPlugins["codeo@codeo"]' "$CLAUDE_CONFIG_DIR/settings.json") == true ]] \
        || fail "user settings: $(cat "$CLAUDE_CONFIG_DIR/settings.json")"
    [[ $(jq -r '.enabledPlugins["superpowers@superpowers-marketplace"]' "$CLAUDE_CONFIG_DIR/settings.json") == true ]] \
        || fail "user settings: $(cat "$CLAUDE_CONFIG_DIR/settings.json")"
}

t_remove_from_home_leaves_project_settings() {
    local top
    in_setup remove_home
    printf 'a\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
    project_repo
    seed_project superpowers@superpowers-marketplace 7.0.2 "$top"
    seed_pin kbajpai/codeo v1.0.6
    seed_project codeo@codeo 1.0.6 "$top"
    mkdir -p "$top/.claude"
    printf '%s\n' '{"enabledPlugins":{"codeo@codeo":true},"extraKnownMarketplaces":{"codeo":{"source":{"source":"github","repo":"kbajpai/codeo","ref":"v1.0.6"}}}}' \
        >"$top/.claude/settings.json"
    cp "$top/.claude/settings.json" "$in_dir/before"
    printf '%s' "$top/.claude/settings.json" >"$STUB_DIR/watch-settings"
    in_run --scope project
    [[ $in_rc -eq 0 ]] || fail "exit $in_rc (stderr: $in_err)"
    [[ -f $STUB_DIR/settings-at-remove ]] || fail "the stub saw no remove call with a project file"
    cmp -s "$in_dir/before" "$STUB_DIR/settings-at-remove" || fail "the remove changed the project file: $(cat "$STUB_DIR/settings-at-remove")"
    [[ $(call_pwds 'plugin marketplace remove codeo') == "$in_dir/home" ]] || fail "remove ran in: $(call_pwds 'plugin marketplace remove codeo')"
    [[ $(jq -r '.extraKnownMarketplaces.codeo.source.ref' "$top/.claude/settings.json") == v1.0.7 ]] \
        || fail "project settings: $(cat "$top/.claude/settings.json")"
}

t_readme_sections() {
    local want got h
    want=$'## Requirements\n## Installing\n## Setting a project up\n## Your first workflow\n## The skills\n## Updating\n## Uninstalling\n## Troubleshooting\n## Contributing'
    got=$(readme_headings "$repo/README.md" '##')
    [[ $got == "$want" ]] || fail "README ## headings are not the nine in order: $got"
    for h in 'Tests' 'Checking a dossier' 'Replaying finished dossiers' 'Dev container'; do
        ! grep -qxF "## $h" "$repo/README.md" || fail "README still has ## $h"
    done
}

t_contributing_sections() {
    local h
    [[ -f $repo/CONTRIBUTING.md ]] || { fail "CONTRIBUTING.md does not exist"; return 0; }
    grep -qxF '# Contributing' "$repo/CONTRIBUTING.md" || fail "no # Contributing heading"
    for h in 'Dev container' 'Tests' 'Checking a dossier' 'Replaying finished dossiers'; do
        grep -qxF "## $h" "$repo/CONTRIBUTING.md" || fail "CONTRIBUTING.md lacks ## $h"
    done
}

t_readme_links_resolve() {
    local f target
    for f in README.md CONTRIBUTING.md; do
        [[ -f $repo/$f ]] || { fail "$f does not exist"; continue; }
        while IFS= read -r target; do
            target=${target%%#*}
            [[ -n $target ]] || continue
            [[ -e $repo/$target ]] || fail "$f links to $target, which does not exist"
        done < <(grep -o ']([^)]*)' "$repo/$f" | sed 's/^](//; s/)$//' | grep -v -E '^[a-z]+:' || true)
    done
}

# readme_install_lines: every README line that runs the installer through curl.
readme_install_lines() {
    grep -E '^curl -fsSL .*install\.sh' "$repo/README.md" || true
}

t_readme_install_command_runs() {
    local line n=0 plain=0 ver=0 proj=0
    while IFS= read -r line; do
        n=$((n + 1))
        in_setup "readme_$n"
        printf 'a\trefs/tags/v1.0.6\nb\trefs/tags/v1.0.7\n' >"$STUB_DIR/tags"
        cat >"$in_dir/bin/curl" <<STUB
#!/usr/bin/env bash
for a in "\$@"; do
    if [[ \$a == https://raw.githubusercontent.com/kbajpai/codeo/main/install.sh ]]; then
        cat "$script"
        exit 0
    fi
done
echo "stub curl: unexpected URL: \$*" >&2
exit 22
STUB
        chmod +x "$in_dir/bin/curl"
        [[ $line != *'--scope project'* ]] || "$real_git" -C "$in_dir/work" init -q
        in_rc=0
        (cd "$in_dir/work" && env -i PATH="$in_dir/bin" HOME="$in_dir/home" STUB_DIR="$STUB_DIR" \
            CLAUDE_CONFIG_DIR="$CLAUDE_CONFIG_DIR" "$bash_abs" -c "$line") >"$in_dir/out" 2>"$in_dir/err" || in_rc=$?
        in_out=$(cat "$in_dir/out")
        in_err=$(cat "$in_dir/err")
        [[ $in_rc -eq 0 ]] || fail "'$line' exit $in_rc (stderr: $in_err)"
        [[ $in_out == *'install: done - '* || $in_out == *'install: nothing changed - '* ]] || fail "'$line' stdout: $in_out"
        if [[ $line == *--version* ]]; then ver=1
        elif [[ $line == *'--scope project'* ]]; then proj=1
        else plain=1; fi
    done < <(readme_install_lines)
    ((n >= 3)) || fail "README has $n curl install lines, want at least 3"
    ((plain && ver && proj)) || fail "README lacks a plain, a --version and a --scope project install line"
}

t_readme_names_only_real_options() {
    local help line opt
    help=$(bash "$script" --help)
    while IFS= read -r line; do
        for opt in $(printf '%s\n' "${line#*install.sh}" | grep -oE -- '--[A-Za-z][A-Za-z-]*' || true); do
            case $opt in --help) continue ;; esac
            [[ $help == *"$opt"* ]] || fail "README shows $opt after install.sh; --help does not list it"
        done
    done < <(grep -F 'install.sh' "$repo/README.md" || true)
}

# readme_install_blocks: each fenced block of the README that has a line starting "install: release",
# reduced to its "install:" lines; every block is followed by a line holding only "--".
readme_install_blocks() {
    awk '
        /^```/ { if (on) { if (has) { printf "%s--\n", buf } on = 0; has = 0; buf = "" } else { on = 1 } next }
        on && /^install: / { buf = buf $0 "\n"; if ($0 ~ /^install: release/) has = 1 }
    ' "$repo/README.md"
}

# readme_install_prose: every README line outside fenced blocks that starts "install: ", and every
# inline code span there that starts "install: " (backticks stripped), one per line.
readme_install_prose() {
    awk '/^```/ { f = !f; next } !f' "$repo/README.md" | {
        grep -E '^install: ' || true
        grep -oE '`install: [^`]*`' | tr -d '`' || true
    }
}

# scenario_lines <name>: the "install:" lines (stdout, then stderr) of a stubbed run.
scenario_lines() {
    local top n=$1
    in_setup "scenario_$n"
    printf 'a\trefs/tags/v1.0.7\nb\trefs/tags/v1.0.6\n' >"$STUB_DIR/tags"
    case $n in
        fresh-user) in_run ;;
        rerun-user) seed_superpowers; seed_codeo 1.0.7; in_run ;;
        user-replace-down) seed_superpowers; seed_codeo 1.0.7; in_run --version v1.0.6 ;;
        user-replace-up) seed_superpowers; seed_codeo 1.0.6; in_run ;;
        fresh-project) project_repo; in_run --scope project ;;
        rerun-project)
            project_repo
            seed_project superpowers@superpowers-marketplace 7.0.2 "$top"
            seed_pin kbajpai/codeo v1.0.7
            seed_project codeo@codeo 1.0.7 "$top"
            in_run --scope project ;;
        user-replace-in-pinned-project)
            project_repo
            seed_superpowers
            seed_codeo 1.0.6
            seed_project codeo@codeo 1.0.6 "$top"
            in_run ;;
        project-replace-with-user-copy | project-replace-user-install-fails | project-replace-project-install-fails)
            project_repo
            seed_project superpowers@superpowers-marketplace 7.0.2 "$top"
            seed_codeo 1.0.6
            seed_project codeo@codeo 1.0.6 "$top"
            [[ $n != project-replace-user-install-fails ]] || : >"$STUB_DIR/install-fail-codeo-user"
            [[ $n != project-replace-project-install-fails ]] || : >"$STUB_DIR/install-fail-codeo-project"
            in_run --scope project ;;
        user-replace-two-projects | user-replace-local)
            local pa pb
            two_projects
            [[ $n != user-replace-local ]] || seed_local 1.0.6 "$in_dir/pc"
            in_cwd="$in_dir/home" in_run ;;
        restore-project)
            project_repo
            seed_project superpowers@superpowers-marketplace 7.0.2 "$top"
            in_run --scope project ;;
        project-replace-other-project)
            local pa pb
            project_repo
            pa=$top
            two_projects
            seed_project superpowers@superpowers-marketplace 7.0.2 "$top"
            in_run --scope project ;;
        replace-add-fails)
            seed_superpowers
            seed_codeo 1.0.6
            : >"$STUB_DIR/add-fail"
            in_run ;;
        *) fail "unknown scenario $n" ;;
    esac
    { printf '%s\n' "$in_out"; printf '%s\n' "$in_err"; } | grep -E '^install: ' || true
}

# t_readme_install_blocks_match_the_script: every README output block that has an "install: release" line
# equals the install lines of a stubbed run, and every other install line the README quotes in prose is a
# line some stubbed run or stubbed failure prints; a "<...>" in the README stands for any text.
t_readme_install_blocks_match_the_script() {
    local s all="" block="" line nblocks=0 found pat
    local -a ok_names=(fresh-user rerun-user user-replace-down user-replace-up fresh-project rerun-project
        user-replace-in-pinned-project project-replace-with-user-copy user-replace-two-projects
        project-replace-other-project user-replace-local restore-project)
    local -a fail_names=(replace-add-fails project-replace-user-install-fails project-replace-project-install-fails)
    local -a got_blocks=()
    for s in "${ok_names[@]}"; do
        got_blocks+=("$(scenario_lines "$s")")
        all+="${got_blocks[-1]}"$'\n'
    done
    for s in "${fail_names[@]}"; do
        all+="$(scenario_lines "$s")"$'\n'
    done
    while IFS= read -r line; do
        if [[ $line == -- ]]; then
            nblocks=$((nblocks + 1))
            block=${block%$'\n'}
            found=0
            block=$(printf '%s' "$block" | sed -E 's/ for [^ ]+ \(/ for <path> (/')
            for s in "${got_blocks[@]}"; do
                [[ $(printf '%s' "$s" | sed -E 's/ for [^ ]+ \(/ for <path> (/') != "$block" ]] || found=1
            done
            ((found)) || fail "README block matches no scenario:"$'\n'"$block"
            block=""
        else
            block+="$line"$'\n'
        fi
    done < <(readme_install_blocks)
    ((nblocks >= 8)) || fail "README has $nblocks install output blocks, want at least 8"
    while IFS= read -r line; do
        [[ -n $line ]] || continue
        pat=$(printf '%s' "$line" | sed -E 's/<[^>]*>/\x01/g')
        pat=${pat//$'\x01'/*}
        found=0
        while IFS= read -r s; do
            # shellcheck disable=SC2053
            if [[ $s == $pat ]]; then found=1; break; fi
        done <<<"$all"
        ((found)) || fail "README quotes a line no scenario prints: $line"
    done < <(readme_install_prose)
}

# t_readme_has_no_offered_again_claim: neither the README nor the CHANGELOG says another project's install
# is offered again.
t_readme_has_no_offered_again_claim() {
    local f
    for f in README.md CHANGELOG.md; do
        ! grep -qE 'offered again|offered them again|are offered' "$repo/$f" || fail "$f still says an install is offered again"
    done
}

# t_readme_names_the_restore_command: the README quotes the restore line the script prints for a dropped
# project install and for a dropped local one (the path and version in each stand for the project's own).
t_readme_names_the_restore_command() {
    local s line norm
    for s in user-replace-two-projects user-replace-local; do
        line=$(scenario_lines "$s" | grep -F 'restore it' | tail -n 1)
        [[ -n $line ]] || fail "scenario $s prints no restore line"
        norm=$(printf '%s' "$line" | sed -E 's/ for [^ ]+ \(/ for <path> (/; s/, v[0-9.]+\)/, vX)/')
        grep -E '^install: codeo is no longer installed for ' "$repo/README.md" \
            | sed -E 's/ for [^ ]+ \(/ for <path> (/; s/, v[0-9.]+\)/, vX)/' | grep -qxF "$norm" \
            || fail "README does not quote: $line"
    done
}

cases=(
    t_list_with_a_notice_before_the_json
    t_list_with_a_notice_after_the_json
    t_list_compact_json_with_a_notice
    t_list_notice_does_not_hide_dropped_installs
    t_list_with_no_json_dies_cleanly
    t_replace_second_scope_failure_names_both
    t_replace_first_failure_keeps_no_longer_installed
    t_replace_project_failure_names_the_wiped_user_copy
    t_given_tag_other_git_failure_is_cannot_read
    t_latest_is_highest_release
    t_given_tag_checked
    t_bare_version_gets_v
    t_missing_tag_stops
    t_offline_stops
    t_no_tags_stops
    t_no_args_ok_up_to_prereqs
    t_help_prints_usage
    t_unknown_option_usage
    t_version_without_value_usage
    t_bad_version_usage
    t_bad_scope_usage
    t_old_bash
    t_missing_each
    t_all_missing_named_together
    t_no_system_package_installed
    t_script_is_executable_with_bash_shebang
    t_fresh_user_install
    t_rerun_changes_nothing
    t_default_scope_is_user
    t_given_tag_installed
    t_latest_installed_without_version
    t_superpowers_from_other_marketplace_left_alone
    t_missing_known_marketplaces_file_is_fresh
    t_plugin_list_failure_stops
    t_runs_from_a_pipe
    t_restart_hint_only_when_changed
    t_replace_older
    t_replace_checks_tag_first
    t_replace_fork_marketplace
    t_replace_failure_reported
    t_user_replace_leaves_the_project_file
    t_user_replace_names_another_project_only
    t_user_replace_names_every_dropped_project
    t_user_replace_names_the_current_project_too
    t_project_replace_names_the_other_projects
    t_dropped_local_entry_is_named_with_its_command
    t_dropped_project_that_no_longer_exists_is_named
    t_no_replace_no_dropped_lines
    t_project_replace_says_the_disabled_user_copy_is_enabled
    t_nonnumeric_test_bash_version_is_ignored
    t_head_uses_no_bash4_syntax
    t_project_replace_moves_the_user_copy
    t_project_replace_without_user_copy
    t_project_replace_from_subdirectory
    t_installed_check_goes_by_the_pin
    t_user_install_declares_the_marketplace_when_only_a_project_declared_it
    t_replace_project_scope
    t_replace_source_without_repo
    t_replace_install_failure_after_add
    t_remove_failure_reported
    t_corrupt_marketplaces_file
    t_superpowers_failures_reported
    t_codeo_failures_reported
    t_disabled_superpowers_is_enabled
    t_disabled_codeo_is_enabled
    t_downgrade_with_given_tag
    t_project_scope_installs_both
    t_project_scope_outside_repo
    t_project_scope_from_subdirectory
    t_project_rerun_changes_nothing
    t_project_after_user_install
    t_other_projects_install_not_counted
    t_project_scope_writes_the_readme_snippet
    t_user_scope_declares_in_user_settings
    t_remove_from_home_leaves_project_settings
    t_readme_sections
    t_contributing_sections
    t_readme_links_resolve
    t_readme_install_command_runs
    t_readme_names_only_real_options
    t_readme_install_blocks_match_the_script
    t_readme_has_no_offered_again_claim
    t_readme_names_the_restore_command
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
