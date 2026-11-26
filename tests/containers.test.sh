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
    local d hits; d="$work/acme"
    hits=$(grep -rInE 'kbajpai|codeo-(home|gh|git|dev|live|[0-9]|<N>)|codeo-\$(\{?[1nN]|num|target)' "$d" --exclude-dir=.git || true)
    [[ -z $hits ]] || fail "codeo's names remain: $hits"
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

for c in setup_writes_codename_and_containers_in_one_go doctor_reports_a_drifted_container_script codeos_own_files_match_their_templates another_project_gets_its_own_names \
    no_shipped_file_names_codeo_where_the_project_belongs the_toolchain_section_is_the_one_place_to_extend \
    a_second_run_skips_and_never_overwrites_seeds check_reports_a_drifted_script \
    the_codename_defaults_to_the_repo_name a_bad_codename_is_refused; do
    "$c"
done
echo "all cases passed"
