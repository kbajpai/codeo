#!/usr/bin/env bash
# Exercises scripts/codeo-init.sh and lib/prompt.sh in scratch clones with a stub gh: the prerequisites
# (repository exists, origin, gh login; never created), an unattended run for a project that is not
# codeo's, answers from prompts, flag answers that are not asked again, suites and the plugin pin, and a
# rerun that keeps the config. Makes no network call (--skip-install, an explicit --version).
#
#   init.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
init="$plugin_root/scripts/codeo-init.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export HOME="$work/home"
mkdir -p "$HOME" "$work/bin"
export GH_LOG="$work/gh.log"

# gh stub: auth status and api succeed unless GH_MODE says otherwise; every call is logged.
cat >"$work/bin/gh" <<'STUB'
#!/usr/bin/env bash
echo "$*" >>"$GH_LOG"
case ${GH_MODE:-ok}:$1 in
    noauth:auth) exit 1 ;;
    norepo:api) exit 1 ;;
esac
exit 0
STUB
chmod +x "$work/bin/gh"
export PATH="$work/bin:$PATH"

fail() { echo "FAIL: $1" >&2; exit 1; }

new_clone() { # <name> [origin]
    local d="$work/$1"
    git init -q "$d"
    [[ -z ${2:-} ]] || git -C "$d" remote add origin "$2"
    git -C "$d" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
    echo "$d"
}
run() { (cd "$1" && shift && "$@" ) ; }

refuses_without_an_origin() {
    local d; d=$(new_clone noorigin)
    if (cd "$d" && bash "$init" --yes --skip-install >"$work/out" 2>&1); then fail "ran without an origin"; fi
    grep -q 'init: fail preflight: this clone has no origin' "$work/out" || fail "reason not stated"
    [[ ! -e $d/.codeo ]] || fail "wrote files despite the failed prerequisite"
}

refuses_a_repository_gh_cannot_see_and_creates_nothing() {
    local d; d=$(new_clone norepo git@github.com:acme-co/shop.git)
    if (cd "$d" && GH_MODE=norepo bash "$init" --yes --skip-install >"$work/out" 2>&1); then fail "ran against a missing repository"; fi
    grep -q 'codeo does not create it' "$work/out" || fail "does not say it never creates"
    ! grep -Eq 'repo create|api -X POST|--method POST' "$GH_LOG" || fail "tried to create a repository"
    [[ ! -e $d/.codeo ]] || fail "wrote files"
}

refuses_when_gh_is_not_logged_in() {
    local d; d=$(new_clone noauth git@github.com:acme-co/shop.git)
    if (cd "$d" && GH_MODE=noauth bash "$init" --yes --skip-install >"$work/out" 2>&1); then fail "ran logged out"; fi
    grep -q 'gh auth login' "$work/out" || fail "no login hint"
}

an_unattended_run_adopts_another_project() {
    local d; d=$(new_clone shop git@github.com:acme-co/shop.git)
    (cd "$d" && bash "$init" --yes --skip-install --codename acme --env containers --version v9.9.9 \
        --suite 'api:src/**,tests/**:dotnet build:dotnet test --no-build' >"$work/out" 2>&1) || true
    grep -q '^init: ok config' "$work/out" || fail "config step: $(cat "$work/out")"
    [[ $(jq -r '"\(.codename) \(.repo.owner)/\(.repo.name) \(.plugin.ref) \(.suites[0].name) \(.suites[0].test) \(.suites[0].paths|length)"' "$d/.codeo/config.json") == 'acme acme-co/shop v9.9.9 api dotnet test --no-build 2'* ]] || fail "config content: $(cat "$d/.codeo/config.json")"
    grep -q 'source=acme-gh' "$d/.devcontainer/devcontainer.json" || fail "containers not from the config"
    grep -rIq 'kbajpai' "$d/.devcontainer" "$d/.sbx" && fail "codeo's repository named in the project's files" || true
}

a_rerun_keeps_the_config() {
    local d="$work/shop"
    jq '.touched = true' "$d/.codeo/config.json" >"$work/merged" && cp "$work/merged" "$d/.codeo/config.json"
    (cd "$d" && bash "$init" --yes --skip-install >"$work/out" 2>&1) || true
    grep -q '^init: skip config' "$work/out" || fail "did not keep the config"
    [[ $(jq -r .touched "$d/.codeo/config.json") == true ]] || fail "config was rewritten"
}

questions_are_asked_only_for_what_flags_left() {
    local d; d=$(new_clone asked git@github.com:acme-co/asked.git)
    (cd "$d" && CODEO_PROMPT_TTY=1 bash "$init" --skip-install --scope project <<<$'myproj\ncontainers\nn' >"$work/out" 2>"$work/err") || true
    grep -q 'Codename' "$work/err" || fail "codename not asked"
    ! grep -q 'user or just this project' "$work/err" || fail "asked scope that a flag answered"
    [[ $(jq -r .codename "$d/.codeo/config.json") == myproj ]] || fail "answer not used"
    [[ -f $d/.devcontainer/codeo-container.sh ]] || fail "env answer not used"
}

an_unattended_run_never_asks() {
    local d; d=$(new_clone quiet git@github.com:acme-co/quiet.git)
    (cd "$d" && bash "$init" --skip-install </dev/null >"$work/out" 2>"$work/err") || true
    [[ ! -s $work/err ]] || fail "prompted without a terminal: $(cat "$work/err")"
    [[ $(jq -r .codename "$d/.codeo/config.json") == quiet ]] || fail "default codename is not the repo name"
}

for c in refuses_without_an_origin refuses_a_repository_gh_cannot_see_and_creates_nothing \
    refuses_when_gh_is_not_logged_in an_unattended_run_adopts_another_project a_rerun_keeps_the_config \
    questions_are_asked_only_for_what_flags_left an_unattended_run_never_asks; do
    "$c"
done
echo "all cases passed"
