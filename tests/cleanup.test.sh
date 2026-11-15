#!/usr/bin/env bash
# Exercises scripts/cleanup.sh on a scratch bare origin plus clone and a stubbed `gh api`:
# each proof failing in turn, the overlay's name check, and that nothing is ever run.
# The overlay body arrives through CODEO_CLEANUP_REMOVAL, which the script reads before overlay.sh.
# Touches no real git config and makes no network call.
#
#   cleanup.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_src=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script=$plugin_src/scripts/cleanup.sh

export GIT_AUTHOR_NAME="Cleanup Test" GIT_AUTHOR_EMAIL="cleanup-test@example.com"
export GIT_COMMITTER_NAME="Cleanup Test" GIT_COMMITTER_EMAIL="cleanup-test@example.com"

scratch_root=$(mktemp -d)
trap 'rm -rf "$scratch_root"' EXIT
export HOME="$scratch_root/home"
mkdir -p "$HOME"
unset CODEO_CLEANUP_REMOVAL

# A stub `gh api`: the answer is $GH_STUB_DIR/GET_<path with / as _>.json, or a failed call.
stub_bin="$scratch_root/bin"
export GH_STUB_DIR="$scratch_root/canned"
mkdir -p "$stub_bin" "$GH_STUB_DIR"
cat > "$stub_bin/gh" <<'STUB'
#!/usr/bin/env bash
[[ ${1:-} == api ]] || exit 1
shift
path= filter=
while (($#)); do
    case $1 in
        -q) filter=$2; shift 2 ;;
        -X | -f | -F) shift 2 ;;
        -*) shift ;;
        *) path=$1; shift ;;
    esac
done
file="$GH_STUB_DIR/GET_${path//\//_}.json"
[[ -f $file ]] || { echo '{"message":"Not Found"}'; exit 1; }
if [[ -n $filter ]]; then jq -r -c "$filter" "$file"; else cat "$file"; fi
STUB
chmod +x "$stub_bin/gh"
# A container-engine stand-in that records any call: cleanup.sh must never make one.
export DOCKER_MARKER="$scratch_root/docker-called"
# shellcheck disable=SC2016
printf '#!/usr/bin/env bash\necho "$*" >> "$DOCKER_MARKER"\n' > "$stub_bin/docker"
chmod +x "$stub_bin/docker"

failures=0
case_desc=
assert_eq() {
    if [[ $2 != "$3" ]]; then
        echo "FAIL: $case_desc — $1: want [$2] got [$3]"
        failures=$((failures + 1))
    fi
}

tab=$'\t'
overlay=$'name: codeo-{N}\npattern: ^codeo-[0-9]+$\ncommand: docker rm -f {name}; docker volume rm {name}'
want_cmd='docker rm -f codeo-12; docker volume rm codeo-12'

# fixture <N> <issue state> <pr number|none> <merged_at|null> <head ref>
fixture() {
    local n=$1 state=$2 pr=$3 merged=$4 ref=$5
    printf '{"number":%s,"state":"%s","labels":[],"assignees":[]}' "$n" "$state" > "$GH_STUB_DIR/GET_repos_o_n_issues_$n.json"
    [[ $pr == none ]] && return 0
    local m=null
    [[ $merged == null ]] || m="\"$merged\""
    printf '{"state":"closed","merged_at":%s,"head":{"ref":"%s"}}' "$m" "$ref" > "$GH_STUB_DIR/GET_repos_o_n_pulls_$pr.json"
}

# A scratch origin whose main carries .codeo/done/<N>/close.md for each "N:body" argument; a clone of it.
setup_repo() {
    local origin work
    origin=$(mktemp -d "$scratch_root/origin.XXXXXX")
    git init -q --bare -b main "$origin"
    work=$(mktemp -d "$scratch_root/work.XXXXXX")
    git clone -q "$origin" "$work" 2>/dev/null
    git -C "$work" checkout -q -b main
    echo x > "$work/README.md"
    local spec n
    for spec in "$@"; do
        n=${spec%%:*}
        mkdir -p "$work/.codeo/done/$n"
        printf '%s\n' "${spec#*:}" > "$work/.codeo/done/$n/close.md"
    done
    git -C "$work" add -A
    git -C "$work" commit -q -m init
    git -C "$work" push -q origin main
    mkdir -p "$work/.codeo"
    printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}\n' > "$work/.codeo/config.json"
    REPO_WORK=$work
}

# A branch on origin, optionally carrying a .codeo/<N>/ dossier.
push_branch() {
    local name=$1 dossier=${2:-}
    git -C "$REPO_WORK" checkout -q -b "$name" main
    if [[ -n $dossier ]]; then
        mkdir -p "$REPO_WORK/.codeo/$dossier"
        echo d > "$REPO_WORK/.codeo/$dossier/plan.md"
        git -C "$REPO_WORK" add -f ".codeo/$dossier/plan.md"
    fi
    git -C "$REPO_WORK" commit -q --allow-empty -m "$name"
    git -C "$REPO_WORK" push -q origin "$name"
    git -C "$REPO_WORK" checkout -q main
    [[ -z $dossier ]] || rm -rf "$REPO_WORK/.codeo/$dossier"
}

run_cleanup() {
    (cd "$REPO_WORK" && PATH="$stub_bin:$PATH" bash "$script" 2>&1) || true
}

body='Opened.
#41 https://github.com/o/n/pull/41'

case_desc="all four proofs pass"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
CODEO_CLEANUP_REMOVAL=$overlay
export CODEO_CLEANUP_REMOVAL
assert_eq "line" "12${tab}proven${tab}$want_cmd" "$(run_cleanup)"

case_desc="issue still open"
setup_repo "12:$body"
fixture 12 open 41 2026-01-01T00:00:00Z feat/12
assert_eq "line" "12${tab}failed${tab}issue" "$(run_cleanup)"

case_desc="pull request not merged"
setup_repo "12:$body"
fixture 12 closed 41 null feat/12
assert_eq "line" "12${tab}failed${tab}pull-request" "$(run_cleanup)"

case_desc="close.md has no pull request line"
setup_repo "12:Nothing opened."
fixture 12 closed none null x
assert_eq "line" "12${tab}failed${tab}pull-request" "$(run_cleanup)"

case_desc="branch still on origin"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
push_branch feat/12
assert_eq "line" "12${tab}failed${tab}branch" "$(run_cleanup)"

case_desc="branch deleted on origin is pruned by the fetch and passes"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
push_branch feat/12
git -C "$REPO_WORK" fetch -q origin
git -C "$REPO_WORK" push -q origin --delete feat/12
assert_eq "line" "12${tab}proven${tab}$want_cmd" "$(run_cleanup)"

case_desc="a failing fetch exits non-zero with a cleanup: message and no proven line"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
git -C "$REPO_WORK" remote set-url origin "$scratch_root/does-not-exist"
rc=0
out=$(cd "$REPO_WORK" && PATH="$stub_bin:$PATH" bash "$script" 2>&1) || rc=$?
assert_eq "exit non-zero" "yes" "$([[ $rc -ne 0 ]] && echo yes || echo no)"
assert_eq "cleanup: message" "yes" "$([[ $out == *"cleanup: fetch failed"* ]] && echo yes || echo no)"
assert_eq "no proven line" "no" "$([[ $out == *"${tab}proven"* ]] && echo yes || echo no)"

case_desc="a single-branch clone proves nothing: exit non-zero, a cleanup: refspec message, no proven line"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
git -C "$REPO_WORK" config remote.origin.fetch '+refs/heads/main:refs/remotes/origin/main'
rc=0
out=$(cd "$REPO_WORK" && PATH="$stub_bin:$PATH" bash "$script" 2>&1) || rc=$?
assert_eq "exit non-zero" "yes" "$([[ $rc -ne 0 ]] && echo yes || echo no)"
assert_eq "cleanup: refspec message" "yes" "$([[ $out == "cleanup: "*refspec* ]] && echo yes || echo no)"
assert_eq "no proven line" "no" "$([[ $out == *"${tab}proven"* ]] && echo yes || echo no)"

case_desc="a name containing & is substituted literally"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
CODEO_CLEANUP_REMOVAL=$'name: a&b-{N}\npattern: ^a&b-[0-9]+$\ncommand: rm {name} {name}'
assert_eq "line" "12${tab}proven${tab}rm a&b-12 a&b-12" "$(run_cleanup)"
CODEO_CLEANUP_REMOVAL=$overlay

case_desc="dossier still on another branch"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
push_branch other/thing 12
assert_eq "line" "12${tab}failed${tab}dossier" "$(run_cleanup)"

case_desc="done/<N> alone is not a dossier"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
push_branch other/thing 13
assert_eq "line" "12${tab}proven${tab}$want_cmd" "$(run_cleanup)"

for bad in codeo-home codeo-gh codeo-git; do
    case_desc="name template expands to $bad"
    setup_repo "12:$body"
    fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
    CODEO_CLEANUP_REMOVAL=$'name: '"$bad"$'\npattern: ^codeo-[0-9]+$\ncommand: docker rm -f {name}'
    assert_eq "line" "12${tab}failed${tab}name" "$(run_cleanup)"
done

case_desc="overlay without a pattern"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
CODEO_CLEANUP_REMOVAL=$'name: codeo-{N}\ncommand: docker rm -f {name}'
assert_eq "line" "12${tab}failed${tab}name" "$(run_cleanup)"

case_desc="overlay without a command"
CODEO_CLEANUP_REMOVAL=$'name: codeo-{N}\npattern: ^codeo-[0-9]+$'
assert_eq "line" "12${tab}failed${tab}name" "$(run_cleanup)"

case_desc="no overlay at all"
unset CODEO_CLEANUP_REMOVAL
assert_eq "line" "12${tab}proven${tab}-" "$(run_cleanup)"

case_desc="ascending N, mixed outcomes"
setup_repo "30:$body" "7:$body" "12:$body"
fixture 30 closed 41 2026-01-01T00:00:00Z feat/30
fixture 7 open 41 2026-01-01T00:00:00Z feat/7
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
CODEO_CLEANUP_REMOVAL=$overlay
export CODEO_CLEANUP_REMOVAL
assert_eq "lines" "7${tab}failed${tab}issue
12${tab}proven${tab}$want_cmd
30${tab}proven${tab}${want_cmd//codeo-12/codeo-30}" "$(run_cleanup)"

case_desc="no container-engine command is ever run"
assert_eq "marker" "absent" "$([[ -e $DOCKER_MARKER ]] && echo present || echo absent)"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
