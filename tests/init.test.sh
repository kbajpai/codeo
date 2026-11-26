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
    # doctor looks for the suite's tool; a stub stands in for dotnet so the ruleset (the stub gh's) is the one failure.
    mkdir -p "$work/stubbin" && printf '#!/bin/sh\nexit 0\n' >"$work/stubbin/dotnet" && chmod +x "$work/stubbin/dotnet"
    (cd "$d" && PATH="$work/stubbin:$PATH" bash "$init" --yes --skip-install --codename acme --env containers --version v9.9.9 \
        --suite 'api:src/**,tests/**:dotnet build:dotnet test --no-build' >"$work/out" 2>&1) || true
    grep -q '^init: ok config' "$work/out" || fail "config step: $(cat "$work/out")"
    [[ $(jq -r '"\(.codename) \(.repo.owner)/\(.repo.name) \(.plugin.ref) \(.suites[0].name) \(.suites[0].test) \(.suites[0].paths|length)"' "$d/.codeo/config.json") == 'acme acme-co/shop v9.9.9 api dotnet test --no-build 2'* ]] || fail "config content: $(cat "$d/.codeo/config.json")"
    grep -q 'source=acme-gh' "$d/.devcontainer/devcontainer.json" || fail "containers not from the config"
    grep -rIq 'kbajpai' "$d/.devcontainer" "$d/.sbx" "$d/.codeo/overlays" && fail "codeo's repository named in the project's files" || true
    grep -rIEq 'codeo-([0-9]+|<N>|home)' "$d/.devcontainer" "$d/.sbx" "$d/.codeo/overlays" && fail "codeo's container names in the project's files: $(grep -rIEn 'codeo-([0-9]+|<N>|home)' "$d/.devcontainer" "$d/.sbx" "$d/.codeo/overlays" | head -3)"
    grep -q '^init: ok containers: [0-9][0-9]* written, 0 kept$' "$work/out" || fail "containers line: $(grep '^init: .*containers' "$work/out")"
    [[ $(grep -c '^fail ' "$work/out") == 1 ]] && grep -q '^fail ruleset' "$work/out" || fail "doctor's fail lines are not just ruleset: $(grep '^fail ' "$work/out")"
    ! grep -q '^init: fail' "$work/out" || fail "a wizard step failed: $(grep '^init: fail' "$work/out")"
    [[ $(jq -r .codename "$d/.codeo/config.json") == acme ]] || fail "the config lacks the project's codename"
}

a_rerun_keeps_the_config() {
    local d="$work/shop"
    jq '.touched = true' "$d/.codeo/config.json" >"$work/merged" && cp "$work/merged" "$d/.codeo/config.json"
    (cd "$d" && bash "$init" --yes --skip-install >"$work/out" 2>&1) || true
    grep -q '^init: skip config' "$work/out" || fail "did not keep the config"
    [[ $(jq -r .touched "$d/.codeo/config.json") == true ]] || fail "config was rewritten"
    grep -q "^init: skip codename: .codeo/config.json already names 'acme'; the answer 'shop' is ignored\$" "$work/out" || fail "no codename line: $(cat "$work/out")"
    [[ $(jq -r .codename "$d/.codeo/config.json") == acme ]] || fail "the codename changed"
    # A rerun with containers over a seed the project edited keeps the edit.
    (cd "$d" && bash "$init" --yes --skip-install --env containers >/dev/null 2>&1) || true
    echo '# project edit' >>"$d/.devcontainer/Dockerfile"; echo 'project overlay line' >>"$d/.codeo/overlays/plan.md"
    (cd "$d" && bash "$init" --yes --skip-install --env containers >"$work/out" 2>&1) || true
    grep -q '^# project edit$' "$d/.devcontainer/Dockerfile" || fail "the Dockerfile edit was overwritten"
    grep -q '^project overlay line$' "$d/.codeo/overlays/plan.md" || fail "the overlay edit was overwritten"
    grep -q '^init: skip containers: [0-9][0-9]* kept, none written$' "$work/out" || fail "containers line on a rerun: $(grep '^init: .*containers' "$work/out")"
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

# A local stand-in for the plugin's repository: this checkout's files (working tree), committed and tagged v9.9.9.
release_repo() { # <name> -> bare repository path
    local src="$work/$1-src" bare="$work/$1.git"
    mkdir -p "$src"
    (cd "$plugin_root" && git ls-files -z | tar --null -T - -cf -) | tar -xf - -C "$src"
    git -C "$src" init -q -b main
    git -C "$src" add -A
    git -C "$src" -c user.name=t -c user.email=t@t commit -q -m release
    git -C "$src" tag v9.9.9
    git init -q --bare "$bare"
    git -C "$src" push -q "$bare" main v9.9.9
    echo "$bare"
}

a_lone_script_fetches_its_release() {
    local bare lone d; bare=$(release_repo rel); lone="$work/lone"
    mkdir -p "$lone"; cp "$init" "$lone/codeo-init.sh"
    d=$(new_clone fetched git@github.com:acme-co/fetched.git)
    (cd "$d" && CODEO_PLUGIN_URL="$bare" bash "$lone/codeo-init.sh" --yes --skip-install >"$work/out" 2>&1) || true
    grep -q '^init: ok preflight' "$work/out" || fail "no preflight: $(cat "$work/out")"
    grep -q '^init: ok config' "$work/out" || fail "no config: $(cat "$work/out")"
}

a_lone_script_with_no_release_fails_in_one_line() {
    local empty="$work/empty.git" lone="$work/lone2" d
    git init -q --bare "$empty"
    mkdir -p "$lone"; cp "$init" "$lone/codeo-init.sh"
    d=$(new_clone norelease git@github.com:acme-co/norelease.git)
    if (cd "$d" && CODEO_PLUGIN_URL="$empty" bash "$lone/codeo-init.sh" --yes --skip-install >"$work/out" 2>&1); then fail "ran with no release"; fi
    [[ $(wc -l <"$work/out") == 1 ]] || fail "not one line: $(cat "$work/out")"
    grep -q '^init: fail fetch: ' "$work/out" || fail "wrong line: $(cat "$work/out")"
    [[ ! -e $d/.codeo ]] || fail "wrote into the project"
}

a_pipe_without_a_terminal_takes_the_defaults() {
    command -v setsid >/dev/null || { echo "SKIP a_pipe_without_a_terminal_takes_the_defaults: no setsid" >&2; return 0; }
    local bare d; bare=$(release_repo rel2)
    d=$(new_clone piped git@github.com:acme-co/piped.git)
    (cd "$d" && cat "$init" | CODEO_PLUGIN_URL="$bare" setsid bash -s -- --skip-install >"$work/out" 2>"$work/err") || true
    [[ ! -s $work/err ]] || fail "question text on a pipe: $(cat "$work/err")"
    grep -q '^init: ok config' "$work/out" || fail "no config: $(cat "$work/out")"
    [[ $(jq -r .codename "$d/.codeo/config.json") == piped ]] || fail "default codename is not the repo name"
}

a_closed_stdin_under_a_terminal_takes_the_defaults() {
    command -v script >/dev/null && script -qec true /dev/null >/dev/null 2>&1 || { echo "SKIP a_closed_stdin_under_a_terminal_takes_the_defaults: no util-linux script" >&2; return 0; }
    local d; d=$(new_clone devnull git@github.com:acme-co/devnull.git)
    (cd "$d" && timeout 20 script -qec "bash '$init' --skip-install </dev/null" /dev/null >"$work/out" 2>&1 </dev/null) || true
    grep -q '^init: ok config' "$work/out" || fail "hung or failed under a terminal: $(cat "$work/out")"
    ! grep -q 'Codename' "$work/out" || fail "asked on the terminal despite </dev/null"
    [[ $(jq -r .codename "$d/.codeo/config.json") == devnull ]] || fail "default codename is not the repo name"
}

a_suite_test_command_may_hold_colons() {
    local d; d=$(new_clone colontest git@github.com:acme-co/colontest.git)
    (cd "$d" && bash "$init" --yes --skip-install --suite 'api:src/**:true:echo a:b' >"$work/out" 2>&1) || true
    [[ $(jq -r '.suites[0].test' "$d/.codeo/config.json") == 'echo a:b' ]] || fail "test command with a colon not kept: $(cat "$d/.codeo/config.json")"
    [[ $(jq -r '.suites[0].build' "$d/.codeo/config.json") == true ]] || fail "build changed"
}

a_suite_build_command_cannot_hold_a_colon() {
    local d; d=$(new_clone colonbuild git@github.com:acme-co/colonbuild.git)
    (cd "$d" && bash "$init" --yes --skip-install --suite 'api:src/**:echo a:b:echo t' >"$work/out" 2>&1) || true
    [[ $(jq -r '.suites[0].build' "$d/.codeo/config.json") == 'echo a' ]] || fail "documented split changed: $(cat "$d/.codeo/config.json")"
    bash "$init" --bogus >"$work/usage" 2>&1 || true
    grep -q 'build command cannot contain a colon' "$work/usage" || fail "usage does not state the build limit"
    grep -q 'build command cannot contain a colon' "$plugin_root/README.md" || fail "README does not state the build limit"
    grep -q 'build command cannot contain a colon' "$init" || fail "header does not state the build limit"
}

a_mixed_case_repo_name_gets_a_derived_codename() {
    local d; d=$(new_clone mixed git@github.com:acme-co/Shop.Web_App.git)
    (cd "$d" && bash "$init" --yes --skip-install >"$work/out" 2>&1) || true
    grep -q '^init: ok config' "$work/out" || fail "config step: $(cat "$work/out")"
    [[ $(jq -r .codename "$d/.codeo/config.json") == shop-web-app ]] || fail "codename: $(cat "$d/.codeo/config.json")"
}

a_repo_name_that_cannot_yield_a_codename_fails_before_writing() {
    local d; d=$(new_clone nocodename git@github.com:acme-co/1.git)
    if (cd "$d" && bash "$init" --yes --skip-install >"$work/out" 2>&1); then fail "ran with no codename"; fi
    grep -qxF "init: fail answer: cannot derive a codename from '1'; pass --codename <name>" "$work/out" || fail "message: $(cat "$work/out")"
    [[ ! -e $d/.codeo ]] || fail "wrote files"
}

an_invalid_explicit_codename_states_the_rule() {
    local d; d=$(new_clone badname git@github.com:acme-co/badname.git)
    if (cd "$d" && bash "$init" --yes --skip-install --codename Bad_Name >"$work/out" 2>&1); then fail "accepted a bad codename"; fi
    grep -qxF "init: fail answer: codename 'Bad_Name' must be lower-case letters, digits and single hyphens, starting with a letter, 2-30 characters" "$work/out" || fail "message: $(cat "$work/out")"
    [[ ! -e $d/.codeo ]] || fail "wrote files"
}

a_flag_without_a_value_is_a_usage_error() {
    local d lone="$work/lone3" f rc; d=$(new_clone novalue git@github.com:acme-co/novalue.git)
    mkdir -p "$lone"; cp "$init" "$lone/codeo-init.sh"
    for f in --version --codename --scope --env --suite; do
        rc=0
        (cd "$d" && bash "$init" --yes --skip-install "$f" >"$work/out" 2>&1) || rc=$?
        [[ $rc == 2 ]] || fail "main parser: $f without a value exited $rc"
        rc=0
        (cd "$d" && CODEO_PLUGIN_URL="$work/none.git" bash "$lone/codeo-init.sh" --yes --skip-install "$f" >"$work/out" 2>&1) || rc=$?
        [[ $rc == 2 ]] || fail "lone script: $f without a value exited $rc: $(cat "$work/out")"
    done
}

a_setup_failure_names_its_reason() {
    local d; d=$(new_clone setupfail git@github.com:acme-co/setupfail.git)
    : >"$d/.codeo"   # a file where setup.sh needs a directory
    (cd "$d" && bash "$init" --yes --skip-install >"$work/out" 2>&1) || true
    grep -q '^init: fail config: scripts/setup.sh failed: .' "$work/out" || fail "no reason: $(cat "$work/out")"
}

a_clone_without_origin_head_does_not_say_ok_and_skips_the_containers() {
    local d; d=$(new_clone emptyrepo git@github.com:acme-co/emptyrepo.git)
    git -C "$d" symbolic-ref --delete refs/remotes/origin/HEAD
    (cd "$d" && bash "$init" --yes --skip-install --env containers --version v9.9.9 >"$work/out" 2>&1) || true
    grep -qxF 'init: fail config: baseBranch is TODO-set-me (the clone has no origin/HEAD: set baseBranch in .codeo/config.json)' "$work/out" || fail "config line: $(cat "$work/out")"
    ! grep -q '^init: ok config: .codeo/config.json written' "$work/out" || fail "config said ok"
    [[ ! -e $d/.devcontainer ]] || fail "containers rendered with baseBranch TODO-set-me"
}

a_kept_config_without_a_codename_gets_the_answer_written_into_it() {
    local d; d=$(new_clone plainsetup git@github.com:acme-co/plainsetup.git)
    mkdir "$d/.codeo"; echo '{"schema":1,"repo":{"owner":"acme-co","name":"plainsetup"},"baseBranch":"main","suites":[],"keep":1}' >"$d/.codeo/config.json"
    (cd "$d" && bash "$init" --yes --skip-install --env containers --version v9.9.9 >"$work/out" 2>&1) || true
    grep -qxF "init: ok config: wrote codename 'plainsetup' into the kept .codeo/config.json" "$work/out" || fail "no codename line: $(cat "$work/out")"
    [[ $(jq -r .codename "$d/.codeo/config.json") == plainsetup && $(jq -r .keep "$d/.codeo/config.json") == 1 ]] || fail "config not as expected"
    [[ ! -e $d/.codeo/config.json.new ]] || fail "temp file left"
    grep -q '^init: ok containers' "$work/out" || fail "containers step: $(cat "$work/out")"
    ! grep -q '^init: fail containers' "$work/out" || fail "containers failed"
    grep -qxF "init: note: the home checkout is a clone whose folder is named plainsetup-home; this folder is 'plainsetup'" "$work/out" || fail "home line: $(cat "$work/out")"
    grep -qxF 'init: note: rename or re-clone it as plainsetup-home to run /codeo:issue and /codeo:init here' "$work/out" || fail "rename line"
    # A clone already in its home folder gets the first line only.
    mkdir "$work/homes"; git init -q "$work/homes/goodname-home"; d=$work/homes/goodname-home
    git -C "$d" remote add origin git@github.com:acme-co/goodname.git; git -C "$d" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
    (cd "$d" && bash "$init" --yes --skip-install --env containers --version v9.9.9 >"$work/out" 2>&1) || true
    grep -qxF "init: note: the home checkout is a clone whose folder is named goodname-home; this folder is 'goodname-home'" "$work/out" || fail "home line (home folder): $(cat "$work/out")"
    ! grep -q 'rename or re-clone' "$work/out" || fail "rename line in the home folder"
}

a_kept_config_without_a_codename_and_an_underivable_name_fails_before_writing() {
    local d; d=$(new_clone plainnoname git@github.com:acme-co/1.git)
    mkdir "$d/.codeo"; echo '{"schema":1,"repo":{"owner":"acme-co","name":"1"},"baseBranch":"main"}' >"$d/.codeo/config.json"
    if (cd "$d" && bash "$init" --yes --skip-install --env containers >"$work/out" 2>&1); then fail "ran with no codename"; fi
    grep -qxF "init: fail answer: cannot derive a codename from '1'; pass --codename <name>" "$work/out" || fail "message: $(cat "$work/out")"
    ! jq -e 'has("codename")' "$d/.codeo/config.json" >/dev/null || fail "a codename was written"
    [[ ! -e $d/.devcontainer ]] || fail "containers written"
}

a_failed_suite_write_is_reported_and_the_next_suite_is_tried() {
    local d; d=$(new_clone suitefail git@github.com:acme-co/shop.git)
    mkdir "$d/.codeo"; echo '{"schema":1,"codename":"shop","repo":{"owner":"acme-co","name":"shop"},"baseBranch":"main","suites":[]}' >"$d/.codeo/config.json"
    mkdir -p "$work/mvbin"; printf '#!/bin/sh\nexit 1\n' >"$work/mvbin/mv"; chmod +x "$work/mvbin/mv"
    if (cd "$d" && PATH="$work/mvbin:$PATH" bash "$init" --yes --skip-install --env none --suite 'one:a:true:true' --suite 'two:b:true:true' >"$work/out" 2>&1); then fail "exit 0 after failed writes"; fi
    grep -qxF 'init: fail suite: one: could not write .codeo/config.json' "$work/out" || fail "no failure line: $(cat "$work/out")"
    grep -qxF 'init: fail suite: two: could not write .codeo/config.json' "$work/out" || fail "the next suite was not tried: $(cat "$work/out")"
    ! grep -q 'init: ok suite' "$work/out" || fail "an ok line after a failed write"
    [[ ! -e $d/.codeo/config.json.new ]] || fail "temp file left"
}

the_wizard_fills_only_the_missing_plugin_key() {
    local d; d=$(new_clone wizpin git@github.com:acme-co/shop.git)
    mkdir "$d/.codeo"; echo '{"schema":1,"codename":"shop","repo":{"owner":"acme-co","name":"shop"},"baseBranch":"main","plugin":{"ref":"v1.0.0"}}' >"$d/.codeo/config.json"
    (cd "$d" && bash "$init" --yes --skip-install --env containers --version v9.9.9 >"$work/out" 2>&1) || true
    [[ $(jq -c .plugin "$d/.codeo/config.json") == '{"ref":"v1.0.0","repo":"kbajpai/codeo"}' ]] || fail "ref-only: $(jq -c .plugin "$d/.codeo/config.json")"
    d=$(new_clone wizfork git@github.com:acme-co/shop.git)
    mkdir "$d/.codeo"; echo '{"schema":1,"codename":"shop","repo":{"owner":"acme-co","name":"shop"},"baseBranch":"main","plugin":{"repo":"fork/codeo","ref":""}}' >"$d/.codeo/config.json"
    (cd "$d" && bash "$init" --yes --skip-install --env containers --version v9.9.9 >"$work/out" 2>&1) || true
    [[ $(jq -c .plugin "$d/.codeo/config.json") == '{"repo":"fork/codeo","ref":"v9.9.9"}' ]] || fail "fork: $(jq -c .plugin "$d/.codeo/config.json")"
    (cd "$d" && bash "$init" --yes --skip-install --env containers --version v9.9.9 >"$work/out" 2>&1) || true
    ! grep -q 'plugin pin' "$work/out" || fail "a pin line for a complete pin"
}

the_wizard_notes_kept_seeds_once() {
    local d; d=$(new_clone wizseed git@github.com:acme-co/shop.git)
    (cd "$d" && bash "$init" --yes --skip-install --env containers --version v9.9.9 >"$work/out" 2>&1) || true
    ! grep -q 'kept files are yours' "$work/out" || fail "note on a fresh project"
    (cd "$d" && bash "$init" --yes --skip-install --env containers --version v9.9.9 >"$work/out" 2>&1) || true
    [[ $(grep -c 'kept files are yours' "$work/out") == 1 ]] || fail "note count: $(cat "$work/out")"
    grep -qxF 'init: note: kept files are yours and are not checked against the templates (a Dockerfile needs the dev user, gh and Claude Code; an overlay needs its role-guard and host-workflow sections): see docs/container-templates.md, Managed and seed files' "$work/out" || fail "note text"
}

the_wizard_takes_the_ref_from_the_forks_repository_and_refuses_invalid_json() {
    local nbad=0
    local b="$work/wbase" d
    mkdir -p "$b/fork"; git init -q --bare "$b/fork/codeo.git"
    git init -q "$work/wseed"; git -C "$work/wseed" -c user.name=t -c user.email=t@t commit -q --allow-empty -m s
    git -C "$work/wseed" tag v2.0.0; git -C "$work/wseed" push -q "$b/fork/codeo.git" v2.0.0
    d=$(new_clone wizfork2 git@github.com:acme-co/shop.git)
    mkdir "$d/.codeo"; echo '{"schema":1,"codename":"shop","repo":{"owner":"acme-co","name":"shop"},"baseBranch":"main","plugin":{"repo":"fork/codeo"}}' >"$d/.codeo/config.json"
    (cd "$d" && env -u CODEO_PLUGIN_URL CODEO_PLUGIN_BASE="$b" bash "$init" --yes --skip-install --env containers >"$work/out" 2>&1) || true
    [[ $(jq -c .plugin "$d/.codeo/config.json") == '{"repo":"fork/codeo","ref":"v2.0.0"}' ]] || fail "fork ref: $(jq -c .plugin "$d/.codeo/config.json")"
    local bad
    for bad in 'not json' 'null' '[]'; do
        nbad=$((nbad + 1)); d=$(new_clone "wizbad$nbad" git@github.com:acme-co/shop.git)
        mkdir "$d/.codeo"; printf '%s\n' "$bad" >"$d/.codeo/config.json"; cp "$d/.codeo/config.json" "$work/bad.orig"
        if (cd "$d" && bash "$init" --yes --skip-install --env containers --version v9.9.9 --suite 'x:a:true:true' >"$work/out" 2>&1); then fail "wizard accepted '$bad'"; fi
        [[ $(grep -c 'fail config' "$work/out") == 1 ]] || fail "'$bad': not exactly one fail config line: $(cat "$work/out")"
        grep -qxF 'init: fail config: .codeo/config.json is not valid JSON' "$work/out" || fail "'$bad' message: $(cat "$work/out")"
        ! grep -q 'jq:' "$work/out" || fail "'$bad': jq noise: $(cat "$work/out")"
        ! grep -q 'containers:' "$work/out" || fail "'$bad': containers ran"
        cmp -s "$work/bad.orig" "$d/.codeo/config.json" && [[ ! -e $d/.codeo/config.json.new && ! -e $d/.devcontainer ]] || fail "'$bad': something was written"
    done
    d=$(new_clone wizrepo git@github.com:acme-co/shop.git)
    mkdir "$d/.codeo"; echo '{"schema":1,"codename":"shop","repo":{"owner":"acme-co","name":"shop"},"baseBranch":"main","plugin":{"repo":"https://evil/x"}}' >"$d/.codeo/config.json"; cp "$d/.codeo/config.json" "$work/bad.orig"
    if (cd "$d" && bash "$init" --yes --skip-install --env containers --suite 'x:a:true:true' >"$work/out" 2>&1); then fail "wizard accepted a bad plugin.repo"; fi
    grep -qxF "init: fail config: config.json: plugin.repo 'https://evil/x' is not an owner/name" "$work/out" || fail "repo message: $(cat "$work/out")"
    cmp -s "$work/bad.orig" "$d/.codeo/config.json" && [[ ! -e $d/.devcontainer ]] || fail "wrote with a bad plugin.repo"
}

for c in refuses_without_an_origin refuses_a_repository_gh_cannot_see_and_creates_nothing \
    refuses_when_gh_is_not_logged_in an_unattended_run_adopts_another_project a_rerun_keeps_the_config \
    questions_are_asked_only_for_what_flags_left an_unattended_run_never_asks \
    a_lone_script_fetches_its_release a_lone_script_with_no_release_fails_in_one_line \
    a_pipe_without_a_terminal_takes_the_defaults a_closed_stdin_under_a_terminal_takes_the_defaults \
    a_suite_test_command_may_hold_colons a_suite_build_command_cannot_hold_a_colon \
    a_clone_without_origin_head_does_not_say_ok_and_skips_the_containers a_mixed_case_repo_name_gets_a_derived_codename a_repo_name_that_cannot_yield_a_codename_fails_before_writing \
    an_invalid_explicit_codename_states_the_rule a_flag_without_a_value_is_a_usage_error a_setup_failure_names_its_reason \
    a_kept_config_without_a_codename_gets_the_answer_written_into_it a_kept_config_without_a_codename_and_an_underivable_name_fails_before_writing \
    a_failed_suite_write_is_reported_and_the_next_suite_is_tried the_wizard_fills_only_the_missing_plugin_key the_wizard_notes_kept_seeds_once the_wizard_takes_the_ref_from_the_forks_repository_and_refuses_invalid_json; do
    "$c"
done
echo "all cases passed"
