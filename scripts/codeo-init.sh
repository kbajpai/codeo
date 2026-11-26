#!/usr/bin/env bash
# One command to adopt codeo in a project: checks the prerequisites, asks a few questions, installs the
# plugins, writes .codeo/config.json and (optionally) the dev container and sbx sandbox files, then runs
# /codeo:doctor's checks. Run from inside the project's clone.
#
#   codeo-init.sh [--yes] [--codename <name>] [--scope user|project] [--version vX.Y.Z]
#                 [--env none|containers] [--suite <name>:<paths,comma-separated>:<build>:<test>]…
#                 [--skip-install]
#   A suite is name:paths:build:test: name, paths and the build command are one colon-separated field each, so the
#   build command cannot contain a colon; only the test command (the remainder) may hold colons.
#
# Prerequisite, never created here: the GitHub repository must already exist, the clone must have an `origin`
# remote pointing at it, and gh must be logged in with access to it. codeo-init creates no repository.
# Run alone (curl | bash), it clones its own release (--version, else the newest vX.Y.Z tag of CODEO_PLUGIN_URL,
# default https://github.com/kbajpai/codeo.git) and runs again from the clone; a failed fetch is one
# "init: fail fetch: <reason>" line, exit 1, nothing written. Questions are asked only at a terminal (when piped,
# read from /dev/tty) and only for what a flag did not answer; without a terminal (or with
# --yes) every question takes its default, so CI and scripts run it unattended. Defaults: codename = the
# repository name lower-cased with . _ and spaces as hyphens (pass --codename when nothing valid is left),
# scope = user, version = newest release, env = none, no suites (add them to .codeo/config.json later).
# --skip-install leaves the plugin install to you (it is the one step that touches Claude's own settings).
# Output: one "init: ok|skip|fail <step>" line per step, doctor's lines after them. Exit 0 when every step and
# doctor passed, 1 otherwise, 2 on a usage error. Rerunning is safe: an existing config is kept, apart from
# the --suite entries and the plugin pin the flags add to it (a codename that differs from the config's is ignored
# and said so; a kept config with no codename gets the answer written into it); the container files are written only where absent.
set -uo pipefail
plugin_url=${CODEO_PLUGIN_URL:-https://github.com/${CODEO_PLUGIN_REPO:-kbajpai/codeo}.git}

# Run alone (curl | bash, or the file copied out of the plugin), the script has none of the files it calls: fetch
# the release, then run the same command again from the clone. CODEO_INIT_FETCHED stops a second fetch.
src=${BASH_SOURCE[0]:-}
here=""
[[ -f $src && -r $src ]] && here=$(cd "$(dirname "$src")/.." 2>/dev/null && pwd)
if [[ -z $here || ! -f $here/lib/prompt.sh ]]; then
    fetch_fail() { printf 'init: fail fetch: %s\n' "$1"; exit 1; }
    [[ ${CODEO_INIT_FETCHED:-0} != 1 ]] || fetch_fail "the fetched release has no lib/prompt.sh"
    command -v git >/dev/null || fetch_fail "git is required"
    tag=""
    args=("$@")
    for ((i = 0; i < ${#args[@]}; i++)); do
        case ${args[i]} in
            --codename | --scope | --version | --env | --suite)
                [[ -n ${args[i + 1]:-} ]] || { echo "usage: codeo-init.sh [--yes] [--codename <name>] [--scope user|project] [--version vX.Y.Z] [--env none|containers] [--suite name:paths:build:test]... [--skip-install]" >&2; exit 2; }
                [[ ${args[i]} != --version ]] || { tag=${args[i + 1]}; [[ $tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "init: --version must look like v1.2.3" >&2; exit 2; }; }
                i=$((i + 1))
                ;;
        esac
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
source "$here/lib/codename.sh"

usage() {
    echo "usage: codeo-init.sh [--yes] [--codename <name>] [--scope user|project] [--version vX.Y.Z] [--env none|containers] [--suite name:paths:build:test]... [--skip-install]" >&2
    echo "a suite is name:paths:build:test; the build command cannot contain a colon (only the test command may)" >&2
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
                --version) [[ $2 =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "init: --version must look like v1.2.3" >&2; exit 2; }; version=$2 ;;
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
base_unset=0
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
repo_info=$(gh api "repos/$owner/$repo" --jq '"\(.private) \(.visibility // "")"' 2>/dev/null) || stop "preflight: gh cannot see $owner/$repo; it must already exist and you need access (codeo does not create it)"
say ok "preflight: $owner/$repo exists and gh can see it"
if [[ $repo_info == true* || $repo_info == *" private" ]]; then
    echo "init: note: $owner/$repo is private; the container route and the codeo command fetch GitHub URLs without credentials and fail for a private repository (docs/container-templates.md in the codeo plugin, Adopting the templates)"
fi
if [[ -e .codeo/config.json ]]; then
    cfg_err=$(codeo_config_shape_error .codeo/config.json) || stop "config: .codeo/config.json $cfg_err"
    cfg_err=$(codeo_pin_repo_error .codeo/config.json) || stop "config: $cfg_err"
fi

# 2. Questions.
# The default codename is the repository name made to fit the codename rule (lower case, . _ and spaces as
# hyphens, no repeated or edge hyphens, a letter first, at most 30 characters); empty when nothing valid is left.
default_codename=$(codeo_derive_codename "$repo" || true)
codename_word=answer
[[ -n $codename ]] || codeo_interactive || codename_word=derived
codeo_ask codename "Codename (names containers, images and volumes)" "$default_codename"
codeo_ask scope "Install the plugins for the user or just this project (user|project)" user
codeo_ask env "Dev container and sbx sandbox files (none|containers)" none
[[ $scope == user || $scope == project ]] || stop "answer: scope must be user or project"
[[ $env == none || $env == containers ]] || stop "answer: env must be none or containers"
if [[ $env == containers && -e .codeo/config.json ]]; then
    cfg_err=$(codeo_base_error .codeo/config.json) || stop "config: $cfg_err"
fi
[[ -n $codename ]] || stop "answer: cannot derive a codename from '$repo'; pass --codename <name>"
[[ $codename =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ && ${#codename} -ge 2 && ${#codename} -le 30 ]] ||
    stop "answer: codename '$codename' must be lower-case letters, digits and single hyphens, starting with a letter, 2-30 characters"
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
    install_err=$(mktemp "${TMPDIR:-/tmp}/codeo-init.err.XXXXXX") || stop "install: cannot create a temporary file"
    if bash "$here/install.sh" "${args[@]}" >/dev/null 2>"$install_err"; then
        say ok "install: plugins ($scope)"
    else
        say fail "install: $(tail -n 1 "$install_err")"
    fi
    rm -f "$install_err"
fi

# 4. The config.
if [[ -e .codeo/config.json ]]; then
    say skip "config: .codeo/config.json exists and is kept"
    kept_codename=$(jq -r '.codename // empty' .codeo/config.json 2>/dev/null || true)
    if [[ -n $kept_codename && $kept_codename != "$codename" ]]; then
        say skip "codename: .codeo/config.json already names '$kept_codename'; $([[ $codename_word == derived ]] && echo "the derived codename" || echo "the answer") '$codename' is ignored"
    fi
    if [[ -z $kept_codename ]]; then
        if jq --arg c "$codename" '.codename = $c' .codeo/config.json >.codeo/config.json.new && mv .codeo/config.json.new .codeo/config.json; then
            say ok "config: wrote codename '$codename' into the kept .codeo/config.json"
        else
            rm -f .codeo/config.json.new
            say fail "config: cannot write codename '$codename' into the kept .codeo/config.json"
        fi
    fi
elif setup_err=$(bash "$here/scripts/setup.sh" --codename "$codename" 2>&1 >/dev/null); then
    if [[ $(jq -r .baseBranch .codeo/config.json 2>/dev/null) == TODO-set-me ]]; then
        say fail "config: baseBranch is TODO-set-me (the clone has no origin/HEAD: set baseBranch in .codeo/config.json)"
        base_unset=1
    else
        say ok "config: .codeo/config.json written"
    fi
else
    say fail "config: scripts/setup.sh failed: $(printf '%s' "$setup_err" | tail -n 1); run it directly to see more"
fi

# 5. Suites and the plugin pin, into the config. A suite is name:paths:build:test (the build command
#    cannot hold a colon, the test command may: name, paths and build are one colon-separated field each and the
#    test command is the remainder).
if [[ -f .codeo/config.json ]]; then
    for s in ${suites[@]+"${suites[@]}"}; do
        IFS=: read -r n p b t <<<"$s"
        if [[ -z $n || -z $t ]]; then say fail "suite: '$s' is not name:paths:build:test"; continue; fi
        if jq -e --arg n "$n" '.suites | any(.name == $n)' .codeo/config.json >/dev/null; then say skip "suite: $n exists"; continue; fi
        if jq --arg n "$n" --arg p "$p" --arg b "${b:-true}" --arg t "$t" \
            '.suites += [{name:$n, paths:($p | split(",")), build:$b, test:$t, parallel:false}]' .codeo/config.json >.codeo/config.json.new \
            && mv .codeo/config.json.new .codeo/config.json; then
            say ok "suite: $n"
        else
            rm -f .codeo/config.json.new
            say fail "suite: $n: could not write .codeo/config.json"
        fi
    done
    pin_missing=
    [[ $env != containers ]] || pin_missing=$(codeo_pin_missing .codeo/config.json)
    if [[ -n $pin_missing ]]; then
        pin=
        if [[ $pin_missing == *ref* ]]; then
            pin=$version
            [[ -n $pin ]] || pin=$(codeo_latest_release "$(codeo_pin_url .codeo/config.json)" || true)
        fi
        if [[ $pin_missing == *ref* && -z $pin ]]; then
            say fail "config: no codeo release found to pin; set plugin.repo and plugin.ref in .codeo/config.json"
        else
            pin_repo=
            [[ $pin_missing != *repo* ]] || pin_repo=${CODEO_PLUGIN_REPO:-kbajpai/codeo}
            if codeo_pin_fill .codeo/config.json "$pin_repo" "$pin"; then
                if [[ -n $pin ]]; then
                    say ok "config: plugin pin $pin (the container installs it)"
                else
                    say ok "config: plugin.repo $pin_repo (the container installs it)"
                fi
            else
                say fail "config: cannot write the plugin pin into .codeo/config.json"
            fi
        fi
    fi
fi

# 6. Containers.
if [[ $env == containers && -f .codeo/config.json && $base_unset == 0 ]]; then
    if cont_out=$(bash "$here/scripts/containers.sh"); then
        n_wrote=$(printf '%s\n' "$cont_out" | grep -c '^containers: wrote ' || true)
        n_kept=$(printf '%s\n' "$cont_out" | grep -c '^containers: skip ' || true)
        if ((n_wrote == 0)); then
            say skip "containers: $n_kept kept, none written"
        else
            say ok "containers: $n_wrote written, $n_kept kept"
        fi
        (( $(codeo_kept_seeds "$cont_out") == 0 )) || echo "init: note: $(codeo_kept_seeds_note)"
        home_cn=$(jq -r '.codename // empty' .codeo/config.json 2>/dev/null || true)
        [[ -z $home_cn ]] || codeo_home_lines "$home_cn" "$root" | sed 's/^/init: note: /'
    else
        say fail "containers: scripts/containers.sh failed"
    fi
elif [[ $base_unset == 1 ]]; then
    say skip "containers: baseBranch is not set"
else
    say skip "containers: env is none"
fi

# 7. Doctor.
if [[ -f .codeo/config.json ]]; then
    bash "$here/scripts/doctor.sh" || failed=1
fi
exit "$failed"
