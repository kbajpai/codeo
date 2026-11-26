#!/usr/bin/env bash
# Exercises scripts/containers.sh in scratch projects: codeo's own checked-in container files are
# exactly what its templates render to, a project with another owner and codename gets its own names
# and none of codeo's, seed files are never overwritten, --force refreshes the managed scripts,
# --check reports a drifted one, and a bad codename is refused. Makes no network call.
#
#   containers.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$plugin_root/scripts/containers.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export HOME="$work/home"
mkdir -p "$HOME"

fail() { echo "FAIL: $1" >&2; exit 1; }

# A scratch project with the given config JSON.
new_project() {
    local dir="$work/$1"
    git init -q "$dir"
    mkdir "$dir/.codeo"
    printf '%s\n' "$2" >"$dir/.codeo/config.json"
    echo "$dir"
}

acme='{"schema":1,"codename":"acme","repo":{"owner":"acme-co","name":"shop"},"baseBranch":"main"}'

# A local stand-in for the codeo repository: one with a v9.9.9 release, one with none. No test reaches the network.
mkdir -p "$work/rel"
git init -q --bare "$work/rel/released.git"
git init -q --bare "$work/rel/empty.git"
git init -q "$work/rel/seed"
git -C "$work/rel/seed" -c user.name=t -c user.email=t@t commit -q --allow-empty -m seed
git -C "$work/rel/seed" tag v9.9.9
git -C "$work/rel/seed" push -q "$work/rel/released.git" HEAD:refs/heads/main v9.9.9
export CODEO_PLUGIN_URL="$work/rel/released.git"

codeos_own_files_match_their_templates() {
    (cd "$plugin_root" && bash "$script" --check >"$work/out") || { cat "$work/out" >&2; fail "codeo's checked-in files drifted from the templates"; }
}

another_project_gets_its_own_names() {
    local d; d=$(new_project acme "$acme")
    (cd "$d" && bash "$script" >/dev/null) || fail "render failed"
    grep -q 'source=acme-gh' "$d/.devcontainer/devcontainer.json" || fail "volume name not the codename's"
    grep -q 'acme-co/shop' "$d/.devcontainer/codeo-container.sh" || fail "repository not the project's"
    [[ -x $d/.devcontainer/codeo && -x $d/.sbx/codeo-sandbox.sh ]] || fail "scripts not executable"
}

no_shipped_file_names_codeo_where_the_project_belongs() {
    # Renders its own project, so the scan does not depend on which cases ran before it.
    local d hits files
    d=$(new_project leakscan '{"schema":1,"codename":"shop","repo":{"owner":"acme-co","name":"shop"},"baseBranch":"main"}')
    (cd "$d" && bash "$script" >/dev/null) || fail "render failed"
    files=$(find "$d" -type f -not -path '*/.git/*' -not -name config.json)
    [[ $(printf '%s\n' "$files" | grep -c .) -ge 10 ]] || fail "the scan found too few files to mean anything: $files"
    [[ -d $d/.codeo/overlays && -d $d/.devcontainer && -d $d/.sbx ]] || fail "the render lacks overlays, .devcontainer or .sbx"
    # The `codeo` command name and the codeo-track.sh style file names are codeo's on purpose; what must not leak
    # is the repository, the container, volume and sandbox names, a ~/codeo home directory and the window titles.
    # One allowed exception: the header comment of .devcontainer/scripts/session-title.sh, a script codeo ships as it is,
    # quotes the window titles of codeo's own window-title.sh. It is a comment, not a name the project sees run.
    hits=$(grep -rInE 'kbajpai|codeo-(home|gh|git|dev|live|[0-9]|<N>)|codeo-\$(\{?[1nN]|num|target)|~/codeo([^-.a-zA-Z]|$)|codeo \[(home|#)' "$d" --exclude-dir=.git --exclude=config.json || true)
    hits=$(grep -v "/[.]devcontainer/scripts/session-title[.]sh:[0-9]*:#" <<<"$hits" || true)
    [[ -z $hits ]] || fail "codeo's names remain: $hits"
}

a_base_branch_other_than_main_is_followed() {
    local d; d=$(new_project dev '{"schema":1,"codename":"shop","repo":{"owner":"acme-co","name":"shop"},"baseBranch":"develop"}')
    (cd "$d" && bash "$script" >/dev/null) || fail "render failed"
    grep -q 'raw.githubusercontent.com/acme-co/shop/develop' "$d/.devcontainer/codeo" || fail "raw URL not on the base branch"
    grep -q '^base_ref=develop$' "$d/.devcontainer/codeo-container.sh" || fail "base_ref not the base branch"
    ! grep -q '/main' "$d/.devcontainer/codeo" "$d/.devcontainer/codeo-container.sh" || fail "main remains"
    ! grep -rq '@BASE_BRANCH@' "$d/.devcontainer" "$d/.sbx" || fail "placeholder left unfilled"
}

overlays_name_the_base_branch() {
    local d; d=$(new_project ovdev '{"schema":1,"codename":"shop","repo":{"owner":"acme-co","name":"shop"},"baseBranch":"develop"}')
    (cd "$d" && bash "$script" >/dev/null) || fail "render failed"
    grep -q 'the clone on `develop`' "$d/.codeo/overlays/init.md" || fail "the init overlay does not name the base branch"
    ! grep -rwn 'main' "$d/.codeo/overlays" >"$work/mainhits" || fail "an overlay names main as a branch: $(cat "$work/mainhits")"
}

a_bad_base_branch_is_refused() {
    local d; d=$(new_project badbase '{"schema":1,"codename":"acme","repo":{"owner":"o","name":"r"},"baseBranch":"x;rm -rf"}')
    if (cd "$d" && bash "$script" >/dev/null 2>"$work/err"); then fail "bad base branch accepted"; fi
    [[ ! -e $d/.devcontainer ]] || fail "files written despite refusal"
    grep -q baseBranch "$work/err" || fail "refusal does not name baseBranch"
}

a_prefix_codename_does_not_leak() {
    local d; d=$(new_project prefix '{"schema":1,"codename":"shop","repo":{"owner":"acme-co","name":"shop-api"},"baseBranch":"main"}')
    (cd "$d" && bash "$script" >/dev/null) || fail "render failed"
    grep -q 'acme-co/shop-api' "$d/.devcontainer/codeo-container.sh" || fail "slug not intact"
    ! grep -rq 'shop-api-api' "$d/.devcontainer" "$d/.sbx" || fail "codename leaked into the repo name"
}

dots_in_owner_and_repo_survive() {
    local d; d=$(new_project dots '{"schema":1,"codename":"cd","repo":{"owner":"a.b","name":"c_d"},"baseBranch":"main"}')
    (cd "$d" && bash "$script" >/dev/null) || fail "render failed"
    grep -q 'a\.b/c_d' "$d/.devcontainer/codeo-container.sh" || fail "owner/repo mangled"
}

the_toolchain_section_is_the_one_place_to_extend() {
    grep -q 'Project toolchain' "$work/acme/.devcontainer/Dockerfile" || fail "no toolchain section"
    ! grep -q shellcheck "$work/acme/.devcontainer/Dockerfile" || fail "codeo's own tools leaked into the base image"
}

a_second_run_skips_and_never_overwrites_seeds() {
    local d="$work/acme"
    echo '# mine' >>"$d/.devcontainer/Dockerfile"
    (cd "$d" && bash "$script" --force >"$work/out")
    grep -q '^# mine' "$d/.devcontainer/Dockerfile" || fail "a seed was overwritten"
    grep -q 'skip .devcontainer/Dockerfile' "$work/out" || fail "seed not reported as skipped"
    (cd "$d" && bash "$script" >"$work/out")
    ! grep -q wrote "$work/out" || fail "a plain rerun wrote files"
}

check_reports_a_drifted_script() {
    local d="$work/acme"
    (cd "$d" && bash "$script" --check >/dev/null) || fail "clean project failed --check"
    echo '# edit' >>"$d/.devcontainer/codeo-track.sh"
    if (cd "$d" && bash "$script" --check >"$work/out"); then fail "drift not reported"; fi
    grep -q 'differs .devcontainer/codeo-track.sh' "$work/out" || fail "drifted file not named"
    (cd "$d" && bash "$script" --force >/dev/null)
    (cd "$d" && bash "$script" --check >/dev/null) || fail "--force did not refresh"
}

the_codename_is_required() {
    local d; d=$(new_project plain '{"schema":1,"repo":{"owner":"o","name":"widgets"},"baseBranch":"main"}')
    if (cd "$d" && bash "$script" >/dev/null 2>"$work/err"); then fail "rendered without a codename"; fi
    grep -qxF 'codeo: config.json has no codename: run /codeo:setup --containers (it adds one), or set codename in .codeo/config.json' "$work/err" || fail "hint: $(cat "$work/err")"
    [[ ! -e $d/.devcontainer ]] || fail "files written despite refusal"
}

a_todo_marker_is_refused() {
    local d k
    d=$(new_project todobase '{"schema":1,"codename":"acme","repo":{"owner":"o","name":"r"},"baseBranch":"TODO-set-me"}')
    if (cd "$d" && bash "$script" >/dev/null 2>"$work/err"); then fail "rendered with baseBranch TODO-set-me"; fi
    grep -q 'baseBranch' "$work/err" || fail "refusal does not name baseBranch: $(cat "$work/err")"
    [[ ! -e $d/.devcontainer ]] || fail "files written despite refusal"
    d=$(new_project todorepo '{"schema":1,"codename":"acme","repo":{"owner":"TODO-set-me","name":"TODO-set-me"},"baseBranch":"main"}')
    if (cd "$d" && bash "$script" >/dev/null 2>"$work/err"); then fail "rendered with repo TODO-set-me"; fi
    grep -q 'repo.owner' "$work/err" || fail "refusal does not name repo.owner"
}

# A clone of owner/<repo> with origin/HEAD set.
new_clone() {
    local d="$work/$1"
    git init -q "$d"; git -C "$d" remote add origin "git@github.com:acme-co/$2.git"
    git -C "$d" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
}

setup_containers_writes_the_normalised_codename() {
    new_clone normname My_Shop.App >/dev/null; local d="$work/normname"
    (cd "$d" && bash "$plugin_root/scripts/setup.sh" --containers >/dev/null 2>&1) || fail "setup --containers failed"
    [[ $(jq -r .codename "$d/.codeo/config.json") == my-shop-app ]] || fail "codename not the normalised repository name"
    grep -q 'source=my-shop-app-gh' "$d/.devcontainer/devcontainer.json" || fail "files not rendered with the config's codename"
    [[ $(cd "$d" && bash .devcontainer/scripts/container-name.sh --docker 2>/dev/null) == my-shop-app-home ]] || fail "container-name.sh disagrees with the config"
}

setup_containers_alone_adds_the_codename_to_an_existing_config() {
    local d; d=$(new_project nocn '{"schema":1,"repo":{"owner":"acme-co","name":"Shop"},"baseBranch":"main","suites":[]}')
    (cd "$d" && bash "$plugin_root/scripts/setup.sh" --containers >"$work/out" 2>&1) || fail "setup --containers failed"
    [[ $(jq -r .codename "$d/.codeo/config.json") == shop ]] || fail "codename not written into the existing config"
    grep -q 'wrote codename shop' "$work/out" || fail "no line saying the codename was written"
    [[ $(jq -c .suites "$d/.codeo/config.json") == '[]' ]] || fail "config changed beyond the codename and the pin"
    [[ ! -e $d/.codeo/config.json.new ]] || fail "temp file left behind"
}

an_underivable_repo_name_fails_before_any_write() {
    new_clone nocodename __ >/dev/null; local d="$work/nocodename"
    if (cd "$d" && bash "$plugin_root/scripts/setup.sh" --containers >/dev/null 2>"$work/err"); then fail "setup derived a codename from '__'"; fi
    grep -qx "codeo: cannot derive a codename from '__'; pass --codename <name>" "$work/err" || fail "unexpected message: $(cat "$work/err")"
    [[ ! -e $d/.codeo && ! -e $d/.devcontainer ]] || fail "something was written before the failure"
}

setup_containers_writes_the_plugin_pin() {
    new_clone pinned shop >/dev/null; local d="$work/pinned"
    (cd "$d" && bash "$plugin_root/scripts/setup.sh" --containers >/dev/null 2>&1) || fail "setup --containers failed"
    [[ $(jq -r .plugin.ref "$d/.codeo/config.json") == v9.9.9 && $(jq -r .plugin.repo "$d/.codeo/config.json") == kbajpai/codeo ]] || fail "pin not written"
    local doc; doc=$(cd "$d" && bash "$plugin_root/scripts/doctor.sh" 2>/dev/null || true)
    grep -q '^ok containers' <<<"$doc" || fail "doctor does not pass a project with the pin: $doc"
}

the_plugin_pin_fails_soft_without_a_release() {
    new_clone nopin shop >/dev/null; local d="$work/nopin"
    (cd "$d" && CODEO_PLUGIN_URL="$work/rel/empty.git" bash "$plugin_root/scripts/setup.sh" --containers >"$work/out" 2>&1) || fail "setup --containers failed without a release"
    grep -qx 'codeo: no codeo release found to pin; set plugin.repo and plugin.ref in .codeo/config.json' "$work/out" || fail "soft failure line missing: $(cat "$work/out")"
    [[ -f $d/.devcontainer/codeo-container.sh ]] || fail "files not written after the soft failure"
    jq -e '.plugin' "$d/.codeo/config.json" >/dev/null 2>&1 && fail "a pin was written"
    local doc; doc=$(cd "$d" && bash "$plugin_root/scripts/doctor.sh" 2>/dev/null || true)
    grep -q '^fail containers: .*plugin.repo and plugin.ref' <<<"$doc" || fail "doctor does not report the missing pin"
}

pin_project() { # <name> <plugin json>: a clone with a codename config and the given .plugin
    new_clone "$1" shop >/dev/null; local d="$work/$1"; mkdir -p "$d/.codeo"
    jq -n --argjson p "${2:-null}" '{schema:1,codename:"shop",repo:{owner:"acme-co",name:"shop"},baseBranch:"main"} + (if $p == null then {} else {plugin:$p} end)' >"$d/.codeo/config.json"
}
run_setup() { (cd "$work/$1" && bash "$plugin_root/scripts/setup.sh" --containers >"$work/out" 2>&1); }
plugin_of() { jq -c .plugin "$work/$1/.codeo/config.json"; }

setup_fills_only_the_missing_plugin_key() {
    pin_project pinref '{"ref":"v1.0.0"}'; run_setup pinref || fail "setup failed"
    [[ $(plugin_of pinref) == '{"ref":"v1.0.0","repo":"kbajpai/codeo"}' ]] || fail "ref-only: $(plugin_of pinref)"
    pin_project pinrepo '{"repo":"fork/codeo"}'; run_setup pinrepo || fail "setup failed"
    [[ $(plugin_of pinrepo) == '{"repo":"fork/codeo","ref":"v9.9.9"}' ]] || fail "repo-only: $(plugin_of pinrepo)"
    pin_project pinfull '{"repo":"fork/codeo","ref":"v1.2.3"}'; run_setup pinfull || fail "setup failed"
    [[ $(plugin_of pinfull) == '{"repo":"fork/codeo","ref":"v1.2.3"}' ]] || fail "complete pin changed"
    ! grep -q 'pinned the plugin\|wrote plugin.repo' "$work/out" || fail "a pin line for a complete pin: $(cat "$work/out")"
    pin_project pinempty '{"repo":"","ref":""}'; run_setup pinempty || fail "setup failed"
    [[ $(plugin_of pinempty) == '{"repo":"kbajpai/codeo","ref":"v9.9.9"}' ]] || fail "empty strings: $(plugin_of pinempty)"
    local doc; doc=$(cd "$work/pinempty" && bash "$plugin_root/scripts/doctor.sh" 2>/dev/null || true)
    grep -q '^ok containers' <<<"$doc" || fail "doctor disagrees: $doc"
}

setup_reports_a_failed_pin_write() {
    pin_project pinfail '{"repo":"fork/codeo"}'
    mkdir -p "$work/mvbin"; printf '#!/bin/sh\nexit 1\n' >"$work/mvbin/mv"; chmod +x "$work/mvbin/mv"
    if (cd "$work/pinfail" && PATH="$work/mvbin:$PATH" bash "$plugin_root/scripts/setup.sh" --containers >"$work/out" 2>&1); then fail "setup succeeded with a failing write"; fi
    ! grep -q 'pinned the plugin' "$work/out" || fail "success line after a failed write"
    [[ ! -e $work/pinfail/.codeo/config.json.new ]] || fail "temp file left"
    [[ $(plugin_of pinfail) == '{"repo":"fork/codeo"}' ]] || fail "config changed"
}

setup_notes_kept_seeds_once() {
    local note='codeo: note: kept files are yours and are not checked against the templates (a Dockerfile needs the dev user, gh and Claude Code; an overlay needs the sections its template has (role-guard in every overlay; host-workflow in init and close; removal-command in cleanup)): see the codeo plugin'"'"'s docs/container-templates.md, Managed and seed files'
    pin_project seedfresh '{"repo":"a/b","ref":"v1"}'; run_setup seedfresh || fail "setup failed"
    ! grep -q 'kept files are yours' "$work/out" || fail "note on a fresh project"
    run_setup seedfresh || fail "rerun failed"
    [[ $(grep -c 'kept files are yours' "$work/out") == 1 ]] || fail "note count: $(cat "$work/out")"
    grep -qxF "$note" "$work/out" || fail "note text: $(cat "$work/out")"
    pin_project seedmgd '{"repo":"a/b","ref":"v1"}'; mkdir -p "$work/seedmgd/.devcontainer"; echo x >"$work/seedmgd/.devcontainer/codeo-container.sh"
    run_setup seedmgd || fail "setup failed"
    ! grep -q 'kept files are yours' "$work/out" || fail "note for a kept managed script"
}

the_ref_comes_from_the_repository_the_config_names() {
    local b="$work/base"
    mkdir -p "$b/fork" "$b/kbajpai"
    local r t
    for r in fork/codeo:v2.0.0 kbajpai/codeo:v9.0.0; do
        git init -q --bare "$b/${r%%:*}.git"
        git -C "$work/rel/seed" tag -f "${r##*:}" >/dev/null
        git -C "$work/rel/seed" push -q "$b/${r%%:*}.git" "${r##*:}"
    done
    pin_project forkref '{"repo":"fork/codeo"}'
    (cd "$work/forkref" && env -u CODEO_PLUGIN_URL CODEO_PLUGIN_BASE="$b" bash "$plugin_root/scripts/setup.sh" --containers >"$work/out" 2>&1) || fail "setup failed: $(cat "$work/out")"
    [[ $(plugin_of forkref) == '{"repo":"fork/codeo","ref":"v2.0.0"}' ]] || fail "ref not from the fork: $(plugin_of forkref)"
    pin_project noforkref '{}'
    (cd "$work/noforkref" && env -u CODEO_PLUGIN_URL CODEO_PLUGIN_BASE="$b" bash "$plugin_root/scripts/setup.sh" --containers >"$work/out" 2>&1) || fail "setup failed"
    [[ $(plugin_of noforkref) == '{"repo":"kbajpai/codeo","ref":"v9.0.0"}' ]] || fail "default lookup: $(plugin_of noforkref)"
    git -C "$work/rel/seed" tag -d v2.0.0 v9.0.0 >/dev/null
}

setup_refuses_an_invalid_config_before_the_pin() {
    local d
    for c in 'not json' '[]' '"str"' null; do
        local want='is not a JSON object'; [[ $c != "not json" ]] || want='is not valid JSON'
        pin_project badcfg '{}'; d="$work/badcfg"; printf '%s\n' "$c" >"$d/.codeo/config.json"
        if run_setup badcfg; then fail "setup accepted '$c'"; fi
        [[ $(grep -c . "$work/out") == 1 ]] && grep -qxF "codeo: config.json $want" "$work/out" || fail "message for '$c': $(cat "$work/out")"
        [[ $(cat "$d/.codeo/config.json") == "$c" && ! -e $d/.codeo/config.json.new && ! -e $d/.devcontainer ]] || fail "wrote something for '$c'"
        rm -rf "$d"
    done
}

setup_refuses_a_todo_base_branch_before_any_write() {
    local d
    pin_project todobase null; d="$work/todobase"
    jq 'del(.codename) | .baseBranch = "TODO-set-me"' "$d/.codeo/config.json" >"$d/c.new" && mv "$d/c.new" "$d/.codeo/config.json"
    cp "$d/.codeo/config.json" "$work/orig.json"
    if run_setup todobase; then fail "setup accepted a TODO baseBranch"; fi
    [[ $(cat "$work/out") == "codeo: config.json: baseBranch is TODO-set-me; set baseBranch in .codeo/config.json to the repository's base branch" ]] || fail "message: $(cat "$work/out")"
    cmp -s "$work/orig.json" "$d/.codeo/config.json" && [[ ! -e $d/.devcontainer ]] || fail "something was written"
}

pin_fill_says_when_it_replaces_a_plugin_that_is_not_an_object() {
    local d
    pin_project pinstr '"x"'; d="$work/pinstr"
    (source "$plugin_root/lib/codename.sh"; codeo_pin_fill "$d/.codeo/config.json" a/b v1.0.0) 2>"$work/err" || fail "fill failed"
    [[ $(cat "$work/err") == 'codeo: .codeo/config.json plugin was not an object; replaced' ]] || fail "stderr: $(cat "$work/err")"
    [[ $(plugin_of pinstr) == '{"repo":"a/b","ref":"v1.0.0"}' ]] || fail "not replaced: $(plugin_of pinstr)"
    pin_project pinabs null
    (source "$plugin_root/lib/codename.sh"; codeo_pin_fill "$work/pinabs/.codeo/config.json" a/b v1.0.0) 2>"$work/err" || fail "fill failed"
    [[ ! -s $work/err ]] || fail "said something for an absent plugin: $(cat "$work/err")"
}

setup_refuses_a_plugin_repo_that_is_not_an_owner_and_name() {
    local r d
    for r in 'https://evil/x' 'a/b/c' '../x' 'noslash' '-a/b'; do
        pin_project badrepo "$(jq -n --arg r "$r" '{repo:$r}')"; d="$work/badrepo"; cp "$d/.codeo/config.json" "$work/orig"
        if run_setup badrepo; then fail "setup accepted plugin.repo '$r'"; fi
        [[ $(grep -c . "$work/out") == 1 ]] && grep -qF "config.json: plugin.repo '$r' is not an owner/name" "$work/out" || fail "message for '$r': $(cat "$work/out")"
        cmp -s "$work/orig" "$d/.codeo/config.json" && [[ ! -e $d/.devcontainer ]] || fail "wrote for '$r'"
        rm -rf "$d"
    done
}

a_bad_codename_is_refused() {
    local d; d=$(new_project bad '{"schema":1,"codename":"Bad Name;","repo":{"owner":"o","name":"r"},"baseBranch":"main"}')
    if (cd "$d" && bash "$script" >/dev/null 2>"$work/err"); then fail "bad codename accepted"; fi
    [[ ! -e $d/.devcontainer ]] || fail "files written despite refusal"
    grep -q codename "$work/err" || fail "refusal does not name codename"
}

setup_writes_codename_and_containers_in_one_go() {
    local d="$work/viasetup" doc
    git init -q "$d"; git -C "$d" remote add origin git@github.com:acme-co/shop.git
    git -C "$d" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
    (cd "$d" && bash "$plugin_root/scripts/setup.sh" --codename acme --containers >/dev/null) || fail "setup --containers failed"
    [[ $(jq -r .codename "$d/.codeo/config.json") == acme ]] || fail "codename not written"
    grep -q acme-gh "$d/.devcontainer/devcontainer.json" || fail "containers not written from config"
    (cd "$d" && bash "$plugin_root/scripts/setup.sh" --codename "Bad Name" >/dev/null 2>&1) && fail "bad codename accepted" || true
}

doctor_reports_a_drifted_container_script() {
    local d="$work/viasetup" doc
    doc=$(cd "$d" && bash "$plugin_root/scripts/doctor.sh" 2>/dev/null || true)
    grep -q "^ok containers" <<<"$doc" || fail "clean project not ok"
    echo "# x" >>"$d/.devcontainer/codeo"
    doc=$(cd "$d" && bash "$plugin_root/scripts/doctor.sh" 2>/dev/null || true)
    grep -q "^fail containers: differ.*[.]devcontainer/codeo" <<<"$doc" || fail "drift not reported"
    local p="$work/nocontainers"; git init -q "$p"; mkdir "$p/.codeo"; echo '{"schema":1,"repo":{"owner":"o","name":"r"},"baseBranch":"main"}' >"$p/.codeo/config.json"
    doc=$(cd "$p" && bash "$plugin_root/scripts/doctor.sh" 2>/dev/null || true)
    ! grep -q containers <<<"$doc" || fail "doctor checked containers in a project without them"
}

overlays_are_written_with_the_projects_names() {
    local d f; d=$(new_project acmeov "$acme")
    (cd "$d" && bash "$script" >/dev/null) || fail "render failed"
    for f in issue init triage cleanup plan implement qc close; do
        [[ -f $d/.codeo/overlays/$f.md ]] || fail "overlay $f.md not written"
    done
    grep -q 'acme-<N>' "$d/.codeo/overlays/init.md" || fail "init.md lacks acme-<N>"
    grep -q 'https://github.com/acme-co/shop/tree/<branch>' "$d/.codeo/overlays/init.md" || fail "init.md lacks the project's repository"
    grep -q 'acme-home' "$d/.codeo/overlays/init.md" || fail "init.md lacks acme-home"
    grep -q 'name: acme-{N}' "$d/.codeo/overlays/cleanup.md" || fail "cleanup.md name"
    grep -qF 'pattern: ^acme-[0-9]+$' "$d/.codeo/overlays/cleanup.md" || fail "cleanup.md pattern"
    grep -q 'acme-dev:{name}' "$d/.codeo/overlays/cleanup.md" || fail "cleanup.md image"
}

codeos_own_overlays_equal_the_render() {
    local f
    for f in issue init triage cleanup plan implement qc close; do
        perl -pe 's/\@CODENAME\@/codeo/g; s/\@REPO_SLUG\@/kbajpai\/codeo/g; s/\@BASE_BRANCH\@/main/g' "$plugin_root/templates/containers/.codeo/overlays/$f.md" |
            cmp -s - "$plugin_root/.codeo/overlays/$f.md" || fail "codeo's overlay $f.md differs from its template"
    done
}

codeos_dockerfile_equals_the_template_outside_the_toolchain_section() {
    local strip='/^# ---- Project toolchain/,/^# ---- End project toolchain/d'
    diff <(sed "$strip" "$plugin_root/templates/containers/.devcontainer/Dockerfile") <(sed "$strip" "$plugin_root/.devcontainer/Dockerfile") >"$work/dfdiff" ||
        fail "codeo's Dockerfile differs from the template outside the toolchain section: $(cat "$work/dfdiff")"
}

codeos_devcontainer_json_equals_the_template_but_the_extensions() {
    local t="$plugin_root/templates/containers/.devcontainer/devcontainer.json" o="$plugin_root/.devcontainer/devcontainer.json"
    local tj oj
    tj=$(perl -pe 's/\@CODENAME\@/codeo/g' "$t" | jq -S 'del(.customizations.vscode.extensions)')
    oj=$(jq -S 'del(.customizations.vscode.extensions)' "$o")
    [ "$tj" = "$oj" ] || fail "codeo's devcontainer.json differs from the template beyond its extensions"
    [ "$(perl -pe 's/\@CODENAME\@/codeo/g' "$t" | jq -c '(.customizations.vscode.extensions + ["timonwong.shellcheck"]) | sort')" = \
        "$(jq -c '.customizations.vscode.extensions | sort' "$o")" ] || fail "codeo's extensions are not the template's plus timonwong.shellcheck"
}

a_seed_overlay_is_never_overwritten() {
    local d="$work/acmeov"
    echo '# mine' >>"$d/.codeo/overlays/plan.md"
    (cd "$d" && bash "$script" --force >"$work/out")
    grep -q '^# mine' "$d/.codeo/overlays/plan.md" || fail "a seed overlay was overwritten"
    grep -q 'skip .codeo/overlays/plan.md' "$work/out" || fail "seed overlay not reported as skipped"
}

setup_codename_with_containers_writes_it_into_a_codenameless_config() {
    local d; d=$(new_project cnless '{"schema":1,"repo":{"owner":"acme-co","name":"Shop"},"baseBranch":"main","suites":[]}')
    (cd "$d" && bash "$plugin_root/scripts/setup.sh" --codename foo --containers >"$work/out" 2>&1) || fail "setup --codename --containers failed: $(cat "$work/out")"
    [[ $(jq -r .codename "$d/.codeo/config.json") == foo ]] || fail "the given codename was not written"
    grep -q 'wrote codename foo' "$work/out" || fail "no line saying so: $(cat "$work/out")"
    grep -q 'foo-gh' "$d/.devcontainer/devcontainer.json" || fail "files not rendered with foo"
    d=$(new_project cnbad '{"schema":1,"repo":{"owner":"acme-co","name":"Shop"},"baseBranch":"main"}')
    if (cd "$d" && bash "$plugin_root/scripts/setup.sh" --codename 'Bad Name' --containers >/dev/null 2>&1); then fail "bad codename accepted on an existing config"; fi
    ! jq -e 'has("codename")' "$d/.codeo/config.json" >/dev/null || fail "a bad codename was written"
}

setup_refuses_another_codename_on_a_config_that_has_one() {
    local d; d=$(new_project cnhas "$acme")
    if (cd "$d" && bash "$plugin_root/scripts/setup.sh" --codename other --containers >/dev/null 2>"$work/err"); then fail "overrode the config's codename"; fi
    grep -q "config.json already names 'acme'" "$work/err" || fail "message: $(cat "$work/err")"
    [[ $(jq -r .codename "$d/.codeo/config.json") == acme ]] || fail "the codename changed"
    [[ ! -e $d/.devcontainer ]] || fail "files written despite the refusal"
}

setup_refuses_a_todo_repository_before_deriving_a_codename() {
    local d; d=$(new_project todocn '{"schema":1,"repo":{"owner":"TODO-set-me","name":"TODO-set-me"},"baseBranch":"main"}')
    if (cd "$d" && bash "$plugin_root/scripts/setup.sh" --containers >/dev/null 2>"$work/err"); then fail "accepted a TODO repository"; fi
    grep -qxF 'codeo: repo.owner/repo.name is TODO-set-me in .codeo/config.json: set them, then run setup.sh --containers' "$work/err" || fail "message: $(cat "$work/err")"
    ! jq -e 'has("codename")' "$d/.codeo/config.json" >/dev/null || fail "a codename was written"
    [[ ! -e $d/.devcontainer && ! -e $d/.codeo/config.json.new ]] || fail "something was written"
}

setup_says_where_the_home_checkout_lives() {
    local d="$work/homechk" out
    mkdir -p "$d"; git init -q "$d/shop"; d=$d/shop
    git -C "$d" remote add origin git@github.com:acme-co/shop.git; git -C "$d" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
    (cd "$d" && bash "$plugin_root/scripts/setup.sh" --containers >"$work/out" 2>&1) || fail "setup --containers failed"
    grep -qxF "codeo: the home checkout is a clone whose folder is named shop-home; this folder is 'shop'" "$work/out" || fail "home line: $(cat "$work/out")"
    grep -qxF 'codeo: rename or re-clone it as shop-home to run /codeo:issue and /codeo:init here' "$work/out" || fail "rename line missing"
    mkdir -p "$work/homeok"; git init -q "$work/homeok/shop-home"; d=$work/homeok/shop-home
    git -C "$d" remote add origin git@github.com:acme-co/shop.git; git -C "$d" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
    (cd "$d" && bash "$plugin_root/scripts/setup.sh" --containers >"$work/out" 2>&1) || fail "setup --containers failed"
    grep -qxF "codeo: the home checkout is a clone whose folder is named shop-home; this folder is 'shop-home'" "$work/out" || fail "home line: $(cat "$work/out")"
    ! grep -q 'rename or re-clone' "$work/out" || fail "rename line on the home folder"
    (cd "$d" && bash "$plugin_root/scripts/setup.sh" --containers >"$work/out" 2>&1) || fail "rerun failed"
    grep -q 'the home checkout is' "$work/out" || fail "no home line on a rerun over an existing config"
}

doctor_passes_overlays_in_the_rendered_project() {
    local d="$work/acmeov" doc
    doc=$(cd "$d" && bash "$plugin_root/scripts/doctor.sh" 2>/dev/null || true)
    grep -q "^ok overlays" <<<"$doc" || fail "overlays not ok: $(grep overlays <<<"$doc")"
}

for c in codeos_dockerfile_equals_the_template_outside_the_toolchain_section codeos_devcontainer_json_equals_the_template_but_the_extensions overlays_are_written_with_the_projects_names codeos_own_overlays_equal_the_render a_seed_overlay_is_never_overwritten doctor_passes_overlays_in_the_rendered_project \
    setup_writes_codename_and_containers_in_one_go doctor_reports_a_drifted_container_script codeos_own_files_match_their_templates another_project_gets_its_own_names \
    no_shipped_file_names_codeo_where_the_project_belongs the_toolchain_section_is_the_one_place_to_extend \
    a_second_run_skips_and_never_overwrites_seeds check_reports_a_drifted_script \
    the_codename_is_required a_todo_marker_is_refused a_bad_codename_is_refused \
    setup_containers_writes_the_normalised_codename setup_containers_alone_adds_the_codename_to_an_existing_config \
    setup_codename_with_containers_writes_it_into_a_codenameless_config setup_refuses_another_codename_on_a_config_that_has_one setup_refuses_a_todo_repository_before_deriving_a_codename setup_says_where_the_home_checkout_lives \
    an_underivable_repo_name_fails_before_any_write setup_containers_writes_the_plugin_pin the_plugin_pin_fails_soft_without_a_release \
    a_base_branch_other_than_main_is_followed overlays_name_the_base_branch a_bad_base_branch_is_refused a_prefix_codename_does_not_leak dots_in_owner_and_repo_survive \
    setup_fills_only_the_missing_plugin_key setup_reports_a_failed_pin_write setup_notes_kept_seeds_once the_ref_comes_from_the_repository_the_config_names setup_refuses_an_invalid_config_before_the_pin setup_refuses_a_plugin_repo_that_is_not_an_owner_and_name setup_refuses_a_todo_base_branch_before_any_write pin_fill_says_when_it_replaces_a_plugin_that_is_not_an_object; do
    "$c"
done
echo "all cases passed"
