#!/usr/bin/env bash
# One command to adopt codeo in a project: checks the prerequisites, asks a few questions, installs the
# plugins, writes .codeo/config.json and (optionally) the dev container and sbx sandbox files, then runs
# /codeo:doctor's checks. Run from inside the project's clone.
#
#   codeo-init.sh [--yes] [--codename <name>] [--scope user|project] [--version vX.Y.Z]
#                 [--env none|containers] [--suite <name>:<paths,comma-separated>:<build>:<test>]…
#                 [--skip-install]
#
# Prerequisite, never created here: the GitHub repository must already exist, the clone must have an `origin`
# remote pointing at it, and gh must be logged in with access to it. codeo-init creates no repository.
# Run alone (curl | bash), it clones its own release (--version, else the newest vX.Y.Z tag of CODEO_PLUGIN_URL,
# default https://github.com/kbajpai/codeo.git) and runs again from the clone; a failed fetch is one
# "init: fail fetch: <reason>" line, exit 1, nothing written. Questions are asked only at a terminal (when piped,
# read from /dev/tty) and only for what a flag did not answer; without a terminal (or with
# --yes) every question takes its default, so CI and scripts run it unattended. Defaults: codename = the
# repository name, scope = user, version = newest release, env = none, no suites (add them to
# .codeo/config.json later).
# --skip-install leaves the plugin install to you (it is the one step that touches Claude's own settings).
# Output: one "init: ok|skip|fail <step>" line per step, doctor's lines after them. Exit 0 when every step and
# doctor passed, 1 otherwise, 2 on a usage error. Rerunning is safe: an existing config is kept.
set -uo pipefail

# Run alone (curl | bash, or the file copied out of the plugin), the script has none of the files it calls: fetch
# the release, then run the same command again from the clone. CODEO_INIT_FETCHED stops a second fetch.
src=${BASH_SOURCE[0]:-}
here=""
[[ -f $src && -r $src ]] && here=$(cd "$(dirname "$src")/.." 2>/dev/null && pwd)
if [[ -z $here || ! -f $here/lib/prompt.sh ]]; then
    fetch_fail() { printf 'init: fail fetch: %s\n' "$1"; exit 1; }
    [[ ${CODEO_INIT_FETCHED:-0} != 1 ]] || fetch_fail "the fetched release has no lib/prompt.sh"
    command -v git >/dev/null || fetch_fail "git is required"
    plugin_url=${CODEO_PLUGIN_URL:-https://github.com/${CODEO_PLUGIN_REPO:-kbajpai/codeo}.git}
    tag=""
    args=("$@")
    for ((i = 0; i < ${#args[@]}; i++)); do
        [[ ${args[i]} != --version ]] || tag=${args[i + 1]:-}
    done
    if [[ -z $tag ]]; then
        tag=$(git ls-remote --tags --refs "$plugin_url" 'v*' 2>/dev/null | sed 's|.*refs/tags/||' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1)
        [[ -n $tag ]] || fetch_fail "no release (vX.Y.Z tag) found at $plugin_url"
    fi
    tmp=$(mktemp -d 2>/dev/null) || fetch_fail "cannot create a temporary directory"
    git clone -q --depth 1 --branch "$tag" "$plugin_url" "$tmp" >/dev/null 2>&1 || { rm -rf "$tmp"; fetch_fail "cannot clone $tag from $plugin_url"; }
    [[ -f $tmp/scripts/codeo-init.sh ]] || { rm -rf "$tmp"; fetch_fail "$tag has no scripts/codeo-init.sh"; }
    # The clone in $tmp is left in place on purpose: the script runs from it, and the OS cleans the temp directory.
    export CODEO_INIT_FETCHED=1
    exec bash "$tmp/scripts/codeo-init.sh" "$@"
fi
source "$here/lib/prompt.sh"

usage() {
    echo "usage: codeo-init.sh [--yes] [--codename <name>] [--scope user|project] [--version vX.Y.Z] [--env none|containers] [--suite name:paths:build:test]... [--skip-install]" >&2
    exit 2
}

codename="" scope="" version="" env="" skip_install=0
suites=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --yes) export CODEO_ASSUME_YES=1 ;;
        --skip-install) skip_install=1 ;;
        --codename | --scope | --version | --env | --suite)
            [[ -n ${2:-} ]] || usage
            case $1 in
                --codename) codename=$2 ;;
                --scope) scope=$2 ;;
                --version) version=$2 ;;
                --env) env=$2 ;;
                --suite) suites+=("$2") ;;
            esac
            shift
            ;;
        *) usage ;;
    esac
    shift
done
[[ -z $scope || $scope == user || $scope == project ]] || usage
[[ -z $env || $env == none || $env == containers ]] || usage

failed=0
say() { printf 'init: %s %s\n' "$1" "$2"; [[ $1 != fail ]] || failed=1; }
stop() { say fail "$1"; exit 1; }

# 1. The prerequisites: a clone of an existing GitHub repository.
root=$(git rev-parse --show-toplevel 2>/dev/null) || stop "preflight: not inside a git clone; clone your GitHub repository first (codeo does not create it)"
cd "$root" || exit 1
url=$(git remote get-url origin 2>/dev/null) || stop "preflight: this clone has no origin remote; the repository must exist on GitHub first (codeo does not create it)"
path=${url%.git}; path=${path%/}
repo=${path##*[/:]}; rest=${path%[/:]*}; owner=${rest##*[/:]}
[[ -n $owner && -n $repo && $rest != "$path" ]] || stop "preflight: cannot read owner/name from origin '$url'"
command -v jq >/dev/null || stop "preflight: jq is required"
command -v gh >/dev/null || stop "preflight: gh is required (https://cli.github.com)"
gh auth status >/dev/null 2>&1 || stop "preflight: gh is not logged in; run gh auth login"
gh api "repos/$owner/$repo" --jq .full_name >/dev/null 2>&1 || stop "preflight: gh cannot see $owner/$repo; it must already exist and you need access (codeo does not create it)"
say ok "preflight: $owner/$repo exists and gh can see it"

# 2. Questions.
codeo_ask codename "Codename (names containers, images and volumes)" "$repo"
codeo_ask scope "Install the plugins for the user or just this project (user|project)" user
codeo_ask env "Dev container and sbx sandbox files (none|containers)" none
[[ $scope == user || $scope == project ]] || stop "answer: scope must be user or project"
[[ $env == none || $env == containers ]] || stop "answer: env must be none or containers"
if [[ ${#suites[@]} == 0 ]] && codeo_interactive; then
    while codeo_confirm "Add a test suite" n; do
        s_name="" s_paths="" s_build="" s_test=""
        codeo_ask s_name "  name" ""; codeo_ask s_paths "  paths that trigger it (comma-separated globs)" "**"
        codeo_ask s_build "  build command" "true"; codeo_ask s_test "  test command" ""
        [[ -n $s_name && -n $s_test ]] && suites+=("$s_name:$s_paths:$s_build:$s_test") || echo "init: a suite needs a name and a test command; skipped" >&2
    done
fi

# 3. Install the plugins.
if ((skip_install)); then
    say skip "install: --skip-install"
else
    args=(--scope "$scope"); [[ -z $version ]] || args+=(--version "$version")
    if bash "$here/install.sh" "${args[@]}" >/dev/null 2>"${TMPDIR:-/tmp}/codeo-init.err.$$"; then
        say ok "install: plugins ($scope)"
    else
        say fail "install: $(tail -n 1 "${TMPDIR:-/tmp}/codeo-init.err.$$")"
    fi
    rm -f "${TMPDIR:-/tmp}/codeo-init.err.$$"
fi

# 4. The config.
if [[ -e .codeo/config.json ]]; then
    say skip "config: .codeo/config.json exists and is kept"
elif bash "$here/scripts/setup.sh" --codename "$codename" >/dev/null 2>&1; then
    say ok "config: .codeo/config.json written"
else
    say fail "config: scripts/setup.sh failed; run it directly to see why"
fi

# 5. Suites and the plugin pin, into the config. A suite is name:paths:build:test (the build and test commands
#    may hold colons; only the first three colons split).
if [[ -f .codeo/config.json ]]; then
    for s in ${suites[@]+"${suites[@]}"}; do
        IFS=: read -r n p b t <<<"$s"
        if [[ -z $n || -z $t ]]; then say fail "suite: '$s' is not name:paths:build:test"; continue; fi
        if jq -e --arg n "$n" '.suites | any(.name == $n)' .codeo/config.json >/dev/null; then say skip "suite: $n exists"; continue; fi
        jq --arg n "$n" --arg p "$p" --arg b "${b:-true}" --arg t "$t" \
            '.suites += [{name:$n, paths:($p | split(",")), build:$b, test:$t, parallel:false}]' .codeo/config.json >.codeo/config.json.new \
            && mv .codeo/config.json.new .codeo/config.json && say ok "suite: $n"
    done
    if [[ $env == containers ]] && ! jq -e '.plugin.ref' .codeo/config.json >/dev/null 2>&1; then
        pin=$version
        [[ -n $pin ]] || pin=$(git ls-remote --tags --refs "https://github.com/${CODEO_PLUGIN_REPO:-kbajpai/codeo}.git" 'v*' 2>/dev/null | sed 's|.*refs/tags/||' | sort -V | tail -n 1)
        if [[ -n $pin ]]; then
            jq --arg r "$pin" --arg pr "${CODEO_PLUGIN_REPO:-kbajpai/codeo}" '.plugin = {repo: $pr, ref: $r}' .codeo/config.json >.codeo/config.json.new \
                && mv .codeo/config.json.new .codeo/config.json && say ok "config: plugin pin $pin (the container installs it)"
        else
            say fail "config: no codeo release found to pin; set plugin.repo and plugin.ref in .codeo/config.json"
        fi
    fi
fi

# 6. Containers.
if [[ $env == containers && -f .codeo/config.json ]]; then
    if bash "$here/scripts/containers.sh" >/dev/null; then say ok "containers: .devcontainer/ and .sbx/ written"; else say fail "containers: scripts/containers.sh failed"; fi
else
    say skip "containers: env is none"
fi

# 7. Doctor.
if [[ -f .codeo/config.json ]]; then
    bash "$here/scripts/doctor.sh" || failed=1
fi
exit "$failed"
