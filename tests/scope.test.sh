#!/usr/bin/env bash
# Exercises scripts/scope.sh against scratch git repos with a seeded config: which suites a diff
# needs, the fail-safe for an unclassified path, rename and deletion handling, and the deploy flag.
#
#   scope.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
scope_sh="$plugin_root/scripts/scope.sh"

scratch_root=$(mktemp -d)
trap 'rm -rf "$scratch_root"' EXIT
export HOME="$scratch_root/home"
mkdir -p "$HOME"

fail() { echo "FAIL: $1" >&2; exit 1; }

base='"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"'
with_suites="{$base,"'"skipGlobs":["docs/**","*.md"],"suites":[{"name":"api","paths":["src/api/**"]},{"name":"web","paths":["web/**"]}],"resources":[{"name":"dev","paths":["deploy/**"]}],"environment":{"resource":"dev"}}'

# A scratch repo on main with one commit, then a branch "work"; prints its path.
# $1 = config.json content. Files "src/api/a.txt" and "old name.txt" exist on main.
make_repo() {
    local dir
    dir=$(mktemp -d "$scratch_root/repo.XXXXXX")
    git -C "$dir" init -q -b main
    git -C "$dir" config user.email t@t
    git -C "$dir" config user.name t
    mkdir -p "$dir/.codeo" "$dir/src/api"
    printf '%s\n' "$1" > "$dir/.codeo/config.json"
    echo a > "$dir/src/api/a.txt"
    echo b > "$dir/old name.txt"
    git -C "$dir" add -A
    git -C "$dir" commit -q -m seed
    git -C "$dir" checkout -q -b work
    echo "$dir"
}

# Commits whatever the repo holds as the change on "work".
commit_change() {
    git -C "$1" add -A
    git -C "$1" commit -q -m change
}

run_scope() { (cd "$1" && bash "$scope_sh" main work 2>"$scratch_root/stderr") || { cat "$scratch_root/stderr" >&2; return 1; }; }

docs_only_change_runs_no_suite() {
    local repo; repo=$(make_repo "$with_suites")
    mkdir -p "$repo/docs/deep"
    echo x > "$repo/docs/deep/guide.txt"
    echo x > "$repo/README.md"
    commit_change "$repo"
    local out; out=$(run_scope "$repo")
    [[ "$out" == $'suite.api=false\nsuite.web=false\ndeploy=false' ]] || fail "unexpected: $out"
}

path_in_one_suite_runs_only_that_suite() {
    local repo; repo=$(make_repo "$with_suites")
    echo more >> "$repo/src/api/a.txt"
    commit_change "$repo"
    local out; out=$(run_scope "$repo")
    [[ "$out" == $'suite.api=true\nsuite.web=false\ndeploy=false' ]] || fail "unexpected: $out"
    grep -q 'src/api/a.txt' "$scratch_root/stderr" || fail "stderr does not name the deciding path"
}

unknown_path_runs_every_suite() {
    local repo; repo=$(make_repo "$with_suites")
    echo x > "$repo/Makefile"
    commit_change "$repo"
    local out; out=$(run_scope "$repo")
    [[ "$out" == $'suite.api=true\nsuite.web=true\ndeploy=false' ]] || fail "unexpected: $out"
    grep -q 'Makefile' "$scratch_root/stderr" || fail "stderr does not name the unknown path"
}

rename_counts_old_and_new_path() {
    local repo; repo=$(make_repo "$with_suites")
    # Moving a file out of a suite's tree into a skipped one: the old path still decides.
    git -C "$repo" mv "src/api/a.txt" "docs-a.md"
    commit_change "$repo"
    local out; out=$(run_scope "$repo")
    [[ "$out" == $'suite.api=true\nsuite.web=false\ndeploy=false' ]] || fail "old path ignored: $out"
    # A rename of a path with a space, both ends unknown: both are listed.
    git -C "$repo" checkout -q main
    git -C "$repo" checkout -q -B work
    git -C "$repo" mv "old name.txt" "new name.txt"
    commit_change "$repo"
    out=$(run_scope "$repo")
    [[ "$out" == $'suite.api=true\nsuite.web=true\ndeploy=false' ]] || fail "unexpected: $out"
    grep -q 'old name.txt' "$scratch_root/stderr" || fail "old path not listed"
    grep -q 'new name.txt' "$scratch_root/stderr" || fail "new path not listed"
}

deploy_true_only_for_environment_paths() {
    local repo; repo=$(make_repo "$with_suites")
    mkdir -p "$repo/deploy/x" "$repo/web"
    echo x > "$repo/deploy/x/k.yaml"
    commit_change "$repo"
    local out; out=$(run_scope "$repo")
    [[ "$out" == *"deploy=true"* ]] || fail "deploy not true: $out"
    # A change outside the resource's paths leaves deploy false.
    repo=$(make_repo "$with_suites")
    mkdir -p "$repo/web"
    echo x > "$repo/web/index.txt"
    commit_change "$repo"
    out=$(run_scope "$repo")
    [[ "$out" == $'suite.api=false\nsuite.web=true\ndeploy=false' ]] || fail "unexpected: $out"
    # No environment configured: no deploy line at all.
    repo=$(make_repo "{$base,"'"suites":[{"name":"api","paths":["src/api/**"]}]}')
    echo more >> "$repo/src/api/a.txt"
    commit_change "$repo"
    out=$(run_scope "$repo")
    [[ "$out" == "suite.api=true" ]] || fail "unexpected without environment: $out"
}

glob_star_stays_inside_a_segment() {
    local repo; repo=$(make_repo "{$base,"'"suites":[{"name":"top","paths":["*.txt"]}]}')
    echo x > "$repo/a.txt"
    commit_change "$repo"
    [[ "$(run_scope "$repo")" == "suite.top=true" ]] || fail "*.txt missed a root file"
    repo=$(make_repo "{$base,"'"suites":[{"name":"top","paths":["*.txt"]},{"name":"other","paths":["x/**"]}]}')
    mkdir -p "$repo/sub"
    echo x > "$repo/sub/b.txt"
    commit_change "$repo"
    # sub/b.txt is matched by no glob, so the fail-safe turns everything on; if * crossed
    # segments, "top" alone would be true and "other" false.
    [[ "$(run_scope "$repo")" == $'suite.top=true\nsuite.other=true' ]] || fail "* crossed a segment"
}

no_suites_configured_prints_nothing_and_exits_0() {
    local repo; repo=$(make_repo "{$base}")
    echo x > "$repo/anything"
    commit_change "$repo"
    local out; out=$(run_scope "$repo") || fail "non-zero exit"
    [[ -z "$out" ]] || fail "printed: $out"
}

for case in docs_only_change_runs_no_suite path_in_one_suite_runs_only_that_suite \
    unknown_path_runs_every_suite rename_counts_old_and_new_path \
    deploy_true_only_for_environment_paths glob_star_stays_inside_a_segment \
    no_suites_configured_prints_nothing_and_exits_0; do
    "$case" || fail "$case"
    echo "ok $case" >&2
done
echo "all cases passed"
