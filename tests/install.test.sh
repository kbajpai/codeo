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
# `plugin marketplace remove codeo` drops the marketplace and every codeo@codeo entry.
in_setup() {
    in_dir="$scratch/$1"
    rm -rf "$in_dir"
    STUB_DIR="$in_dir/stub"
    CLAUDE_CONFIG_DIR="$in_dir/claude"
    mkdir -p "$in_dir/bin" "$in_dir/work" "$STUB_DIR" "$CLAUDE_CONFIG_DIR/plugins"
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
list="$STUB_DIR/list.json"
market="$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json"
[[ -f $market ]] || echo '{}' >"$market"
scope=user
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
    [[ ${args[i]} != --scope ]] || scope=${args[i + 1]:-user}
done
case "${1:-} ${2:-} ${3:-}" in
    "plugin list "*) cat "$list" ;;
    "plugin marketplace add")
        spec=$4 repo=${4%@*} ref=""
        [[ $spec != *@* ]] || ref=${spec#*@}
        case $repo in
            kbajpai/codeo) name=codeo ;;
            obra/superpowers-marketplace) name=superpowers-marketplace ;;
            *) echo "stub claude: unknown marketplace $repo" >&2; exit 1 ;;
        esac
        jq --arg n "$name" --arg r "$repo" --arg f "$ref" \
            '.[$n] = {source: ({source: "github", repo: $r} + (if $f == "" then {} else {ref: $f} end))}' \
            "$market" >"$market.new"
        mv "$market.new" "$market" ;;
    "plugin marketplace remove")
        jq --arg n "$4" 'del(.[$n])' "$market" >"$market.new"
        mv "$market.new" "$market"
        if [[ $4 == codeo ]]; then
            jq 'map(select(.id != "codeo@codeo"))' "$list" >"$list.new"
            mv "$list.new" "$list"
        fi ;;
    "plugin install "*)
        id=$3
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
    (cd "$in_dir/work" && env -i PATH="$in_dir/bin" HOME="$in_dir/home" STUB_DIR="$STUB_DIR" \
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
    [[ $in_out == 'install: release v1.0.10' ]] || fail "stdout: $in_out"
    grep -q 'ls-remote --tags --refs https://github.com/kbajpai/codeo v\*' "$STUB_DIR/git-calls" \
        || fail "ls-remote call: $(cat "$STUB_DIR/git-calls")"
    [[ ! -s $STUB_DIR/calls ]] || fail "claude was called"
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
    [[ $in_out == 'install: release v1.0.7' ]] || fail "stdout: $in_out"
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
    [[ $in_out == 'install: release v1.0.7' && -z $in_err ]] || fail "out=$in_out err=$in_err"
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

cases=(
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
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
