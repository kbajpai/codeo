#!/usr/bin/env bash
# Exercises scripts/overlap.sh against real scratch git repos: "origin" is a scratch repo
# reached by a local path, and no case touches the network or a real git config.
#
#   overlap.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_src=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

export GIT_AUTHOR_NAME="Overlap Test" GIT_AUTHOR_EMAIL="overlap-test@example.com"
export GIT_COMMITTER_NAME="Overlap Test" GIT_COMMITTER_EMAIL="overlap-test@example.com"

scratch_root=$(mktemp -d)
trap 'rm -rf "$scratch_root"' EXIT
export HOME="$scratch_root/home"
mkdir -p "$HOME"

# The plugin as installed, so lib/env.sh resolves CODEO_PLUGIN_ROOT to a directory this test owns.
# overlap.sh asks inflight.sh (beside it) which workflows are in flight; inflight.sh in turn asks
# github.sh for assignees only when it is not given --branches, which overlap.sh always passes —
# so github.sh is stubbed as a script that must never be reached.
plugin="$scratch_root/plugin"
mkdir -p "$plugin"
cp -R "$plugin_src/scripts" "$plugin/scripts"
cp -R "$plugin_src/lib" "$plugin/lib"
printf '#!/usr/bin/env bash\necho "github.sh stub reached" >&2\nexit 1\n' > "$plugin/scripts/github.sh"

failures=0
case_desc=
assert_eq() {
    local label=$1 want=$2 got=$3
    if [[ $want != "$got" ]]; then
        echo "FAIL: $case_desc — $label: want [$want] got [$got]"
        failures=$((failures + 1))
    fi
}

tab=$'\t'

# commit_file <repo> <path> — a one-line file, committed.
commit_file() {
    mkdir -p "$(dirname "$1/$2")"
    echo "$2" > "$1/$2"
    git -C "$1" add "$2"
    git -C "$1" commit -q -m "$2"
}

# plan <repo> <issue> <files> <exclusive> [extra] [wiki] — .codeo/<issue>/plan.md with a footprint block.
plan() {
    mkdir -p "$1/.codeo/$2"
    printf '# Plan\n\n## Footprint\n\n### Footprint\n\n```\nfiles:      %s\nwiki:       %s\nexclusive:  %s\n```\n\n## Questions\n%s\n' \
        "$3" "${6:-none}" "$4" "${5:-}" > "$1/.codeo/$2/plan.md"
    git -C "$1" add .codeo
    git -C "$1" commit -q -m "plan $2"
}

# write_config <clone> — .codeo/config.json, untracked; modules come from SC_MODULES (default: wiki on).
write_config() {
    mkdir -p "$1/.codeo"
    printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"%s","modules":%s}\n' \
        "${SC_BASE:-main}" "${SC_MODULES:-[\"wiki\"]}" > "$1/.codeo/config.json"
}

# scenario <b_files> [a_extra_file] [a_question] — prints the clone, on feat/a (issue 7), with feat/b
# (issue 9) pushed to origin. b changes Clips/Endpoints/Health.cs and Docs/x.md; a changes
# Clips/Endpoints/Health.cs and Terraform/a.tf. Optional environment, unset in every older case:
# SC_A_FILES (a's footprint files, default Terraform/**), SC_A_WIKI and SC_B_WIKI (their wiki: lines),
# SC_BASE=<name> (the origin's base branch and the config's baseBranch, default main), SC_BULK=<n> (n extra files under Clips/Zbulk/ on main), SC_APART=1 (the diffs share nothing:
# Health.cs is already on main and neither branch changes it).
scenario() {
    local origin clone
    origin=$(mktemp -d "$scratch_root/origin.XXXXXX")
    git -C "$origin" -c init.defaultBranch="${SC_BASE:-main}" init -q
    # No background maintenance after a push or a commit: it would race a later clone — see
    # claim.test.sh's fresh_origin.
    git -C "$origin" config gc.auto 0
    git -C "$origin" config maintenance.auto false
    git -C "$origin" config receive.autogc false
    commit_file "$origin" README.md
    [[ -z ${SC_APART:-} ]] || commit_file "$origin" Clips/Endpoints/Health.cs
    if ((${SC_BULK:-0})); then
        mkdir -p "$origin/Clips/Zbulk"
        for ((i = 0; i < SC_BULK; i++)); do echo "$i" > "$origin/Clips/Zbulk/f$i.cs"; done
        git -C "$origin" add Clips/Zbulk
        git -C "$origin" commit -q -m bulk
    fi
    git -C "$origin" checkout -q -b feat/b
    [[ -n ${SC_APART:-} ]] || commit_file "$origin" Clips/Endpoints/Health.cs
    commit_file "$origin" Docs/x.md
    plan "$origin" 9 "$1" terraform '' "${SC_B_WIKI:-none}"
    git -C "$origin" checkout -q "${SC_BASE:-main}"
    git -C "$origin" checkout -q -b feat/a
    clone=$(mktemp -d "$scratch_root/clone.XXXXXX")
    git clone -q "$origin" "$clone"
    git -C "$clone" checkout -q feat/a
    git -C "$clone" checkout -q -b work "origin/${SC_BASE:-main}"
    [[ -n ${SC_APART:-} ]] || commit_file "$clone" Clips/Endpoints/Health.cs
    commit_file "$clone" Terraform/a.tf
    [[ -z ${2:-} ]] || commit_file "$clone" "$2"
    plan "$clone" 7 "${SC_A_FILES:-Terraform/**}" terraform "${3:-}" "${SC_A_WIKI:-none}"
    write_config "$clone"
    printf '%s' "$clone"
}

run() {
    local clone=$1
    shift
    (cd "$clone" && bash "$plugin/scripts/overlap.sh" "$@" 2>/dev/null)
}

case_desc="pairs from both diffs, the glob, and the exclusive"
clone=$(scenario 'Clips/Endpoints/**')
want="9${tab}Clips/Endpoints/Health.cs
9${tab}exclusive:terraform"
assert_eq "lines" "$want" "$(run "$clone" 7)"

case_desc="pair from their glob"
clone=$(scenario 'Clips/Endpoints/**' Clips/Endpoints/Other.cs)
want="9${tab}Clips/Endpoints/Health.cs
9${tab}Clips/Endpoints/Other.cs
9${tab}exclusive:terraform"
assert_eq "lines" "$want" "$(run "$clone" 7)"

case_desc="pair from my glob"
origin_of() { git -C "$1" remote get-url origin; }
clone=$(scenario 'Clips/Endpoints/**')
git -C "$(origin_of "$clone")" checkout -q feat/b
commit_file "$(origin_of "$clone")" Terraform/b.tf
want="9${tab}Clips/Endpoints/Health.cs
9${tab}Terraform/b.tf
9${tab}exclusive:terraform"
assert_eq "lines" "$want" "$(run "$clone" 7)"

case_desc="globstar matches a path below the glob's directory"
clone=$(scenario 'Clips/**' Clips/Endpoints/Deep/Other.cs)
assert_eq "deep path" 1 "$(run "$clone" 7 | grep -c "Clips/Endpoints/Deep/Other.cs" || true)"

case_desc="none footprint leaves only the diff pair"
clone=$(scenario none Clips/Endpoints/Other.cs)
want="9${tab}Clips/Endpoints/Health.cs
9${tab}exclusive:terraform"
assert_eq "lines" "$want" "$(run "$clone" 7)"

case_desc="already raised pairs are dropped"
clone=$(scenario 'Clips/Endpoints/**' '' $'\n### Q3 — Overlap\n\nIssue #9 also changes Clips/Endpoints/Health.cs.\n')
assert_eq "lines" "9${tab}exclusive:terraform" "$(run "$clone" 7)"

case_desc="a question naming #90 and a longer path does not suppress the #9 pair"
clone=$(scenario 'Clips/Endpoints/**' '' $'\n### Q3 — Overlap\n\nIssue #90 also changes Clips/Endpoints/Health.cs.bak.\n')
want="9${tab}Clips/Endpoints/Health.cs
9${tab}exclusive:terraform"
assert_eq "lines" "$want" "$(run "$clone" 7)"

case_desc="dossiers never pair"
clone=$(scenario '.codeo/**' )
assert_eq "no dossier line" 0 "$(run "$clone" 7 | grep -c '\.codeo' || true)"

case_desc="--outside lists changes outside the branch's own footprint"
clone=$(scenario 'Clips/Endpoints/**' Clips/Endpoints/Other.cs)
mkdir -p "$clone/docs/plans"
echo p > "$clone/docs/plans/p.md"
git -C "$clone" add docs/plans
git -C "$clone" commit -q -m "plan doc"
want="Clips/Endpoints/Health.cs
Clips/Endpoints/Other.cs"
assert_eq "lines" "$want" "$(run "$clone" --outside 7)"

# wiki_plan <clone> <wiki> — rewrites issue 7's footprint `wiki:` line and commits it.
wiki_plan() {
    sed -i "s/^wiki:.*/wiki:       $2/" "$1/.codeo/7/plan.md"
    git -C "$1" add .codeo
    git -C "$1" commit -q -m "wiki footprint"
}

case_desc="--outside treats a page named under wiki: as inside the footprint"
clone=$(scenario none wiki/Foo.md)
wiki_plan "$clone" Foo
assert_eq "lines" "Clips/Endpoints/Health.cs" "$(run "$clone" --outside 7)"

case_desc="--outside reports a wiki page the footprint does not name"
clone=$(scenario none wiki/Foo.md)
wiki_plan "$clone" Bar
want="Clips/Endpoints/Health.cs
wiki/Foo.md"
assert_eq "lines" "$want" "$(run "$clone" --outside 7)"

case_desc="--outside does not let wiki: cover wiki/images"
clone=$(scenario none wiki/images/Foo.png)
wiki_plan "$clone" Foo
want="Clips/Endpoints/Health.cs
wiki/images/Foo.png"
assert_eq "lines" "$want" "$(run "$clone" --outside 7)"

# footprint against footprint: two plans that name the same files, before either has written them.
case_desc="footprint vs footprint: a their-glob sharing a path with mine pairs once"
clone=$(SC_APART=1 SC_A_FILES='Clips/**' scenario 'Clips/Endpoints/**')
assert_eq "lines" "9${tab}exclusive:terraform
9${tab}glob:Clips/Endpoints/**" "$(run "$clone" 7)"

case_desc="identical globs give one glob line"
clone=$(SC_APART=1 SC_A_FILES='Docs/**' scenario 'Docs/**')
assert_eq "lines" "9${tab}Docs/x.md
9${tab}exclusive:terraform
9${tab}glob:Docs/**" "$(run "$clone" 7)"

case_desc="a their-glob resolving to many paths still pairs when the shared path comes first"
clone=$(SC_BULK=300 SC_APART=1 SC_A_FILES='Clips/Endpoints/Health.cs' scenario 'Clips/**')
assert_eq "lines" "9${tab}exclusive:terraform
9${tab}glob:Clips/**" "$(run "$clone" 7)"

case_desc="a glob that resolves to nothing pairs with nothing"
clone=$(SC_APART=1 SC_A_FILES='Clips/**' scenario 'Nowhere/**')
assert_eq "lines" "9${tab}exclusive:terraform" "$(run "$clone" 7)"

case_desc="a shared wiki page pairs"
clone=$(SC_APART=1 SC_A_WIKI=Deployment SC_B_WIKI=Deployment scenario none)
assert_eq "lines" "9${tab}exclusive:terraform
9${tab}wiki:Deployment" "$(run "$clone" 7)"

case_desc="overlap_ignores_wiki_pairing_when_the_module_is_off"
clone=$(SC_MODULES='[]' SC_APART=1 SC_A_WIKI=Deployment SC_B_WIKI=Deployment scenario none)
assert_eq "no wiki line" "9${tab}exclusive:terraform" "$(run "$clone" 7)"
clone=$(SC_MODULES='[]' scenario none wiki/Foo.md)
wiki_plan "$clone" Foo
want="Clips/Endpoints/Health.cs
wiki/Foo.md"
assert_eq "--outside no longer treats a page as covered" "$want" "$(run "$clone" --outside 7)"

case_desc="overlap_follows_a_non_main_base_branch"
clone=$(SC_BASE=trunk scenario 'Clips/Endpoints/**')
assert_eq "no main branch anywhere" "" "$(git -C "$clone" branch -a --list '*main')"
want="9${tab}Clips/Endpoints/Health.cs
9${tab}exclusive:terraform"
assert_eq "lines" "$want" "$(run "$clone" 7)"

case_desc="a raised glob pair is dropped"
clone=$(SC_APART=1 SC_A_FILES='Clips/**' scenario 'Clips/Endpoints/**' '' $'\n### Q3 — Overlap\n\nIssue #9 also names glob:Clips/Endpoints/**.\n')
assert_eq "lines" "9${tab}exclusive:terraform" "$(run "$clone" 7)"

case_desc="--outside is unchanged by footprints"
clone=$(SC_APART=1 SC_A_FILES='Clips/**' scenario 'Clips/Endpoints/**')
assert_eq "lines" "Terraform/a.tf" "$(run "$clone" --outside 7)"

case_desc="two plans naming a literal path neither branch has written pair"
clone=$(SC_APART=1 SC_A_FILES='Clips/New/Thing.cs' scenario 'Clips/New/Thing.cs')
assert_eq "lines" "9${tab}exclusive:terraform
9${tab}glob:Clips/New/Thing.cs" "$(run "$clone" 7)"

case_desc="my literal pairs with their glob before either has written it"
clone=$(SC_APART=1 SC_A_FILES='Clips/New/Thing.cs' scenario 'Clips/New/**')
assert_eq "lines" "9${tab}exclusive:terraform
9${tab}glob:Clips/New/**" "$(run "$clone" 7)"

case_desc="a dossier literal never pairs"
clone=$(SC_APART=1 SC_A_FILES='.codeo/42/plan.md' scenario '.codeo/42/plan.md')
assert_eq "lines" "9${tab}exclusive:terraform" "$(run "$clone" 7)"

case_desc="a literal already on main pairs once"
clone=$(SC_APART=1 SC_A_FILES='Clips/Endpoints/Health.cs' scenario 'Clips/Endpoints/Health.cs')
assert_eq "lines" "9${tab}exclusive:terraform
9${tab}glob:Clips/Endpoints/Health.cs" "$(run "$clone" 7)"

case_desc="a none footprint against a literal pairs nothing"
clone=$(SC_APART=1 SC_A_FILES='none' scenario 'Clips/New/Thing.cs')
assert_eq "lines" "9${tab}exclusive:terraform" "$(run "$clone" 7)"

case_desc="nothing in flight"
origin=$(mktemp -d "$scratch_root/origin.XXXXXX")
git -C "$origin" -c init.defaultBranch=main init -q
# No background maintenance after a push or a commit: it would race a later clone — see
# claim.test.sh's fresh_origin.
git -C "$origin" config gc.auto 0
git -C "$origin" config maintenance.auto false
git -C "$origin" config receive.autogc false
commit_file "$origin" README.md
clone=$(mktemp -d "$scratch_root/clone.XXXXXX")
git clone -q "$origin" "$clone"
git -C "$clone" checkout -q -b feat/a
plan "$clone" 7 'Terraform/**' terraform
write_config "$clone"
rc=0
out=$(cd "$clone" && bash "$plugin/scripts/overlap.sh" 7 2>/dev/null) || rc=$?
assert_eq "stdout" "" "$out"
assert_eq "exit" 0 "$rc"

case_desc="no issue number is a usage error"
rc=0
(cd "$clone" && bash "$plugin/scripts/overlap.sh" >/dev/null 2>&1) || rc=$?
assert_eq "exit" 1 "$rc"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
