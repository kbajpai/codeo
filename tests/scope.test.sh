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

unusable_config_fails_loudly_and_prints_nothing() {
    local repo out rc
    repo=$(make_repo "{not json")
    rc=0; out=$(cd "$repo" && bash "$scope_sh" main work 2>/dev/null) || rc=$?
    [[ $rc -ne 0 ]] || fail "invalid JSON exited 0"
    [[ -z "$out" ]] || fail "invalid JSON printed: $out"
    repo=$(make_repo "{$base}")
    rm "$repo/.codeo/config.json"
    git -C "$repo" add -A; git -C "$repo" commit -q -m rm
    rc=0; out=$(cd "$repo" && bash "$scope_sh" main work 2>/dev/null) || rc=$?
    [[ $rc -ne 0 ]] || fail "missing config exited 0"
    [[ -z "$out" ]] || fail "missing config printed: $out"
}

metacharacters_and_spaces_in_paths_match_literally() {
    local repo; repo=$(make_repo "{$base,"'"skipGlobs":["**/*.md"],"suites":[{"name":"a","paths":["a b/**"]},{"name":"z","paths":["z/**"]}]}')
    mkdir -p "$repo/a b" "$repo/sub"
    echo x > "$repo/a b/[x].cs"
    echo x > "$repo/sub/weird*name.md"
    commit_change "$repo"
    local out; out=$(run_scope "$repo")
    [[ "$out" == $'suite.a=true\nsuite.z=false' ]] || fail "unexpected: $out"
}

a_400_file_diff_with_three_suites_is_fast() {
    local repo; repo=$(make_repo "{$base,"'"suites":[{"name":"api","paths":["src/api/**"]},{"name":"web","paths":["web/**"]},{"name":"x","paths":["x/**"]}]}')
    local i
    for i in $(seq 1 400); do echo "$i" > "$repo/src/api/f$i.txt"; done
    commit_change "$repo"
    local start=$SECONDS out; out=$(run_scope "$repo")
    [[ "$out" == $'suite.api=true\nsuite.web=false\nsuite.x=false' ]] || fail "unexpected: $out"
    (( SECONDS - start < 5 )) || fail "took $((SECONDS - start))s"
}

an_unresolvable_revision_is_an_error_not_nothing_changed() {
    local repo; repo=$(make_repo "$with_suites")
    echo more >> "$repo/src/api/a.txt"
    commit_change "$repo"
    local args out err
    for args in "no-such-tag HEAD" "HEAD no-such-tag"; do
        # shellcheck disable=SC2086
        if out=$(cd "$repo" && bash "$scope_sh" $args 2>"$scratch_root/stderr"); then fail "exited 0 for: $args"; fi
        [[ -z $out ]] || fail "stdout for '$args': $out"
        err=$(cat "$scratch_root/stderr")
        [[ $err == scope:*no-such-tag* && $err != *$'\n'* ]] || fail "stderr for '$args': $err"
    done
}

# Puts a deployed revision on "work": the branch's own change, committed and tagged R. Prints nothing.
deploy_at_r() {
    echo more >> "$1/src/api/a.txt"
    commit_change "$1"
    git -C "$1" tag R
}

# Commits a file on main and merges main back into "work", as a branch does to catch up.
merge_main_change() { # repo path content
    git -C "$1" checkout -q main
    mkdir -p "$(dirname "$1/$2")"
    printf '%s\n' "$3" > "$1/$2"
    git -C "$1" add -A
    git -C "$1" commit -q -m "main: $2"
    git -C "$1" checkout -q work
    git -C "$1" merge -q --no-edit main
}

run_delivered() { (cd "$1" && bash "$scope_sh" --delivered-since main R HEAD 2>"$scratch_root/stderr") || { cat "$scratch_root/stderr" >&2; return 1; }; }
run_since() { (cd "$1" && bash "$scope_sh" R HEAD 2>"$scratch_root/stderr") || { cat "$scratch_root/stderr" >&2; return 1; }; }

delivered_since_ignores_a_base_branch_merge_after_the_deploy() {
    local repo; repo=$(make_repo "$with_suites")
    deploy_at_r "$repo"
    merge_main_change "$repo" deploy/x/k.yaml x
    local out; out=$(run_since "$repo")
    [[ "$out" == *"deploy=true"* ]] || fail "old form should read deploy=true: $out"
    out=$(run_delivered "$repo")
    [[ "$out" == $'suite.api=false\nsuite.web=false\ndeploy=false' ]] || fail "unexpected: $out"
}

delivered_since_counts_a_deployed_path_the_branch_changed_after_the_deploy() {
    local repo; repo=$(make_repo "$with_suites")
    deploy_at_r "$repo"
    merge_main_change "$repo" web/index.txt y
    mkdir -p "$repo/deploy/x"
    echo x > "$repo/deploy/x/k.yaml"
    commit_change "$repo"
    local out; out=$(run_delivered "$repo")
    [[ "$out" == *"deploy=true"* ]] || fail "deploy not true: $out"
    # The merged-in web path is not the branch's: it must not be what decided.
    [[ "$(cd "$repo" && bash "$scope_sh" --delivered-since main R HEAD 2>&1 >/dev/null)" != *web/index.txt* ]] || fail "merged-in path decided: $out"
}

delivered_since_keeps_a_path_both_sides_changed() {
    local repo; repo=$(make_repo "$with_suites")
    mkdir -p "$repo/deploy"
    seq 1 10 > "$repo/deploy/shared.yaml"
    git -C "$repo" checkout -q main
    git -C "$repo" merge -q --no-edit work 2>/dev/null || true
    mkdir -p "$repo/deploy"
    seq 1 10 > "$repo/deploy/shared.yaml"
    git -C "$repo" add -A
    git -C "$repo" commit -q -m "main: shared"
    git -C "$repo" checkout -q work
    git -C "$repo" merge -q --no-edit main
    # The branch edits the first line and deploys; main edits the last line afterwards.
    sed -i '1s/.*/branch/' "$repo/deploy/shared.yaml"
    commit_change "$repo"
    git -C "$repo" tag R
    git -C "$repo" checkout -q main
    sed -i '10s/.*/main/' "$repo/deploy/shared.yaml"
    git -C "$repo" add -A
    git -C "$repo" commit -q -m "main: last line"
    git -C "$repo" checkout -q work
    git -C "$repo" merge -q --no-edit main
    local out; out=$(run_delivered "$repo")
    [[ "$out" == *"deploy=true"* ]] || fail "shared path should stay in scope: $out"
}

delivered_since_without_the_flag_and_with_a_bad_argument() {
    local repo; repo=$(make_repo "$with_suites")
    deploy_at_r "$repo"
    local err
    if (cd "$repo" && bash "$scope_sh" --delivered-since main R 2>"$scratch_root/stderr"); then fail "exited 0 for a missing head"; fi
    err=$(cat "$scratch_root/stderr")
    [[ $err == *"usage: scope.sh --delivered-since"* ]] || fail "usage: $err"
    if (cd "$repo" && bash "$scope_sh" --delivered-since no-such-base R HEAD 2>"$scratch_root/stderr"); then fail "exited 0 for an unresolvable base"; fi
    err=$(cat "$scratch_root/stderr")
    [[ $err == scope:*no-such-base* && $err != *$'\n'* ]] || fail "stderr: $err"
}

for case in docs_only_change_runs_no_suite path_in_one_suite_runs_only_that_suite \
    unknown_path_runs_every_suite rename_counts_old_and_new_path \
    deploy_true_only_for_environment_paths glob_star_stays_inside_a_segment \
    no_suites_configured_prints_nothing_and_exits_0 unusable_config_fails_loudly_and_prints_nothing \
    metacharacters_and_spaces_in_paths_match_literally a_400_file_diff_with_three_suites_is_fast \
    an_unresolvable_revision_is_an_error_not_nothing_changed \
    delivered_since_ignores_a_base_branch_merge_after_the_deploy \
    delivered_since_counts_a_deployed_path_the_branch_changed_after_the_deploy \
    delivered_since_keeps_a_path_both_sides_changed \
    delivered_since_without_the_flag_and_with_a_bad_argument; do
    "$case" || fail "$case"
    echo "ok $case" >&2
done
echo "all cases passed"
