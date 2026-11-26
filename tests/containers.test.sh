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
    local d hits
    for d in "$work"/*/; do
        [[ -d $d/.devcontainer ]] || continue
        hits=$(grep -rInE 'kbajpai|codeo-(home|gh|git|dev|live|[0-9]|<N>)|codeo-\$(\{?[1nN]|num|target)' "$d" --exclude-dir=.git || true)
        [[ -z $hits ]] || fail "codeo's names remain: $hits"
    done
}

a_base_branch_other_than_main_is_followed() {
    local d; d=$(new_project dev '{"schema":1,"codename":"shop","repo":{"owner":"acme-co","name":"shop"},"baseBranch":"develop"}')
    (cd "$d" && bash "$script" >/dev/null) || fail "render failed"
    grep -q 'raw.githubusercontent.com/acme-co/shop/develop' "$d/.devcontainer/codeo" || fail "raw URL not on the base branch"
    grep -q '^base_ref=develop$' "$d/.devcontainer/codeo-container.sh" || fail "base_ref not the base branch"
    ! grep -q '/main' "$d/.devcontainer/codeo" "$d/.devcontainer/codeo-container.sh" || fail "main remains"
    ! grep -rq '@BASE_BRANCH@' "$d/.devcontainer" "$d/.sbx" || fail "placeholder left unfilled"
}

a_bad_base_branch_is_refused() {
    local d; d=$(new_project badbase '{"schema":1,"repo":{"owner":"o","name":"r"},"baseBranch":"x;rm -rf"}')
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

the_codename_defaults_to_the_repo_name() {
    local d; d=$(new_project plain '{"schema":1,"repo":{"owner":"o","name":"widgets"},"baseBranch":"main"}')
    (cd "$d" && bash "$script" >/dev/null)
    grep -q 'source=widgets-gh' "$d/.devcontainer/devcontainer.json" || fail "default codename"
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

doctor_passes_overlays_in_the_rendered_project() {
    local d="$work/acmeov" doc
    doc=$(cd "$d" && bash "$plugin_root/scripts/doctor.sh" 2>/dev/null || true)
    grep -q "^ok overlays" <<<"$doc" || fail "overlays not ok: $(grep overlays <<<"$doc")"
}

for c in codeos_dockerfile_equals_the_template_outside_the_toolchain_section codeos_devcontainer_json_equals_the_template_but_the_extensions overlays_are_written_with_the_projects_names codeos_own_overlays_equal_the_render a_seed_overlay_is_never_overwritten doctor_passes_overlays_in_the_rendered_project \
    setup_writes_codename_and_containers_in_one_go doctor_reports_a_drifted_container_script codeos_own_files_match_their_templates another_project_gets_its_own_names \
    no_shipped_file_names_codeo_where_the_project_belongs the_toolchain_section_is_the_one_place_to_extend \
    a_second_run_skips_and_never_overwrites_seeds check_reports_a_drifted_script \
    the_codename_defaults_to_the_repo_name a_bad_codename_is_refused \
    a_base_branch_other_than_main_is_followed a_bad_base_branch_is_refused a_prefix_codename_does_not_leak dots_in_owner_and_repo_survive \
    no_shipped_file_names_codeo_where_the_project_belongs; do
    "$c"
done
echo "all cases passed"
