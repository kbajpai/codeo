#!/usr/bin/env bash
# Exercises scripts/inflight.sh against real scratch git repos and a stubbed `gh`: the
# machine-readable --tsv rows (order, --except, empty), and that the human output keeps its shape.
# Touches no real git config and makes no network call — "origin" is a scratch repo reached by a
# local path, and every GitHub call lands on the `gh` stub below.
#
#   inflight.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_src=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

export GIT_AUTHOR_NAME="Inflight Test" GIT_AUTHOR_EMAIL="inflight-test@example.com"
export GIT_COMMITTER_NAME="Inflight Test" GIT_COMMITTER_EMAIL="inflight-test@example.com"

scratch_root=$(mktemp -d)
cleanup() { rm -rf "$scratch_root"; }
trap cleanup EXIT

# No ~/.codeo-secrets here, and no real git config read.
export HOME="$scratch_root/home"
mkdir -p "$HOME"

# A stub `gh` for the whole run. It logs "$*" to $GH_STUB_LOG; for `gh api <path>` the method is -X,
# else POST when any -f/-F is present, else GET; --paginate is ignored; the answer is
# $GH_STUB_DIR/<METHOD>_<path with / as _>.json, piped through `jq -r -c <filter>` when the call
# carries -q (as real gh does). A missing file is `{"message":"Not Found"}` on stdout, exit 1 —
# which is also what real gh does for a failed call.
stub_bin="$scratch_root/bin"
stub_dir="$scratch_root/canned"
mkdir -p "$stub_bin" "$stub_dir"
export GH_STUB_DIR="$stub_dir" GH_STUB_LOG="$scratch_root/gh.log"
: > "$GH_STUB_LOG"
cat > "$stub_bin/gh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${GH_STUB_LOG:?}"
[[ ${1:-} == api ]] || { echo '{"message":"Not Found"}'; exit 1; }
shift
method= path= filter= has_field=
while (($#)); do
    case $1 in
        -X) method=$2; shift 2 ;;
        -q) filter=$2; shift 2 ;;
        -f | -F) has_field=1; shift 2 ;;
        --paginate) shift ;;
        *) [[ -z $path ]] && path=$1; shift ;;
    esac
done
[[ -n $method ]] || { [[ -n $has_field ]] && method=POST || method=GET; }
file="$GH_STUB_DIR/${method}_${path//\//_}.json"
if [[ ! -f $file ]]; then echo '{"message":"Not Found"}'; exit 1; fi
if [[ -n $filter ]]; then jq -r -c "$filter" "$file"; else cat "$file"; fi
STUB
chmod +x "$stub_bin/gh"

# The plugin as installed, with github.sh stubbed: `github.sh issue view <N>` answers by calling the
# `gh` stub above for the issue's JSON, so the canned files below stand in for the GitHub API.
plugin="$scratch_root/plugin"
mkdir -p "$plugin"
cp -R "$plugin_src/scripts" "$plugin/scripts"
cp -R "$plugin_src/lib" "$plugin/lib"
cat > "$plugin/scripts/github.sh" <<'GHSTUB'
#!/usr/bin/env bash
set -o pipefail
[[ ${1:-} == issue && ${2:-} == view ]] || { echo "github.sh stub: unsupported: $*" >&2; exit 1; }
gh api "repos/o/n/issues/$3" | jq -c '.assignees |= map(.login)'
GHSTUB

failures=0
case_desc=
assert_eq() {
    local label=$1 want=$2 got=$3
    if [[ $want != "$got" ]]; then
        echo "FAIL: $case_desc — $label: want [$want] got [$got]"
        failures=$((failures + 1))
    fi
}
assert_contains() {
    local label=$1 needle=$2 haystack=$3
    if [[ $haystack != *"$needle"* ]]; then
        echo "FAIL: $case_desc — $label: want substring [$needle] in [$haystack]"
        failures=$((failures + 1))
    fi
}

fresh_repo() {
    local dir
    dir=$(mktemp -d "$scratch_root/repo.XXXXXX")
    git -C "$dir" -c init.defaultBranch=main init -q
    # No background maintenance after a push or a commit: it would race a later clone — see
    # claim.test.sh's fresh_origin.
    git -C "$dir" config gc.auto 0
    git -C "$dir" config maintenance.auto false
    git -C "$dir" config receive.autogc false
    echo placeholder > "$dir/README.md"
    git -C "$dir" add README.md
    git -C "$dir" commit -q -m init
    printf '%s' "$dir"
}

# .codeo/<dir>/<step>.md with the given outcome, committed on the origin's current branch.
write_dossier() {
    local origin=$1 dir=$2 step=$3 outcome=$4
    mkdir -p "$origin/.codeo/$dir"
    printf '# %s\n\n## Outcome\n\n%s\n' "$step" "$outcome" > "$origin/.codeo/$dir/$step.md"
    git -C "$origin" add .codeo
    git -C "$origin" commit -q -m "$step $dir"
}

pending='_Pending — written at the hand-off._'

# A clone of the origin with a config (untracked): inflight.sh runs from the clone's top level.
clone_of() {
    local dir
    dir=$(mktemp -d "$scratch_root/clone.XXXXXX")
    git clone -q "$1" "$dir"
    mkdir -p "$dir/.codeo"
    printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}\n' > "$dir/.codeo/config.json"
    printf '%s' "$dir"
}

run_inflight() {
    local clone=$1
    shift
    (cd "$clone" && PATH="$stub_bin:$PATH" bash "$plugin/scripts/inflight.sh" "$@" 2>&1)
}

printf '{"number":7,"labels":[],"assignees":[{"login":"alice"}]}' > "$stub_dir/GET_repos_o_n_issues_7.json"
printf '{"number":9,"labels":[],"assignees":[]}' > "$stub_dir/GET_repos_o_n_issues_9.json"
printf '{"number":5,"labels":[],"assignees":[]}' > "$stub_dir/GET_repos_o_n_issues_5.json"

origin=$(fresh_repo)
for b in a b c; do git -C "$origin" branch "feat/$b"; done
git -C "$origin" checkout -q feat/a
write_dossier "$origin" 7 init "Started."
write_dossier "$origin" 7 plan "Planned."
mkdir -p "$origin/src"
echo x > "$origin/src/x.txt"
git -C "$origin" add src
git -C "$origin" commit -q -m "change src"
git -C "$origin" checkout -q feat/b
write_dossier "$origin" done/9 qc "Passed."
write_dossier "$origin" done/9 close "$pending"
git -C "$origin" checkout -q feat/c
write_dossier "$origin" 5 init "$pending"
git -C "$origin" checkout -q main
write_dossier "$origin" done/3 qc "Passed."
git -C "$origin" checkout -q -b feat/d
clone=$(clone_of "$origin")

tab=$'\t'

case_desc="tsv rows"
out=$(run_inflight "$clone" --tsv)
want="7${tab}feat/a${tab}working${tab}plan${tab}alice
9${tab}feat/b${tab}pr-open${tab}qc${tab}
5${tab}feat/c${tab}working${tab}none${tab}"
assert_eq "rows" "$want" "$out"

case_desc="tsv except"
out=$(run_inflight "$clone" --tsv --except 7)
assert_eq "line count" 2 "$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
assert_eq "no issue 7" 0 "$(printf '%s\n' "$out" | grep -c "^7${tab}" || true)"

case_desc="human output unchanged"
out=$(run_inflight "$clone")
assert_contains "block header" "#7  feat/a" "$out"
assert_contains "assignee" "  assignee:  alice" "$out"
assert_contains "working step" "  step:      plan (working)" "$out"
assert_contains "pr step" "  step:      qc (PR open)" "$out"
assert_contains "no assignee" "  assignee:  none" "$out"

case_desc="human block lists changed files"
out=$(run_inflight "$clone")
assert_contains "changed under #7" "#7  feat/a
  assignee:  alice
  step:      plan (working)
  changed:    src/x.txt" "$out"

case_desc="changed: none for a dossier-only branch"
assert_contains "pr-open branch" "  step:      qc (PR open)
  changed:    none" "$out"

case_desc="--branches rows"
out=$(run_inflight "$clone" --branches)
want="7${tab}feat/a${tab}.codeo/7
9${tab}feat/b${tab}.codeo/done/9
5${tab}feat/c${tab}.codeo/5"
assert_eq "rows" "$want" "$out"
out=$(run_inflight "$clone" --branches --except 7)
assert_eq "except 7" "$(printf '%s\n' "$want" | tail -n 2)" "$out"

case_desc="--branches makes no gh call"
: > "$GH_STUB_LOG"
run_inflight "$clone" --branches > /dev/null
assert_eq "gh log" "" "$(cat "$GH_STUB_LOG")"

case_desc="--branches prints nothing when nothing is in flight"
assert_eq "stdout" "" "$(run_inflight "$(clone_of "$(fresh_repo)")" --branches)"

case_desc="--branches with --tsv is rejected"
rc=0
(cd "$clone" && PATH="$stub_bin:$PATH" bash "$plugin/scripts/inflight.sh" --branches --tsv >/dev/null 2>"$scratch_root/err") || rc=$?
assert_eq "exit" 1 "$rc"
assert_contains "usage" "usage: inflight.sh" "$(cat "$scratch_root/err")"

empty_clone=$(clone_of "$(fresh_repo)")

case_desc="tsv empty"
out=$(run_inflight "$empty_clone" --tsv)
assert_eq "stdout" "" "$out"

case_desc="human empty"
out=$(run_inflight "$empty_clone")
assert_eq "stdout" "inflight: no other workflow in flight" "$out"

case_desc="tsv failed assignee lookup fails the whole listing"
origin2=$(fresh_repo)
git -C "$origin2" checkout -q -b feat/z
write_dossier "$origin2" 11 init "Started."
clone2=$(clone_of "$origin2")
tsv_rc=0
tsv_out=$(cd "$clone2" && PATH="$stub_bin:$PATH" bash "$plugin/scripts/inflight.sh" --tsv 2>"$scratch_root/err") || tsv_rc=$?
assert_eq "exit" 1 "$tsv_rc"
assert_eq "stdout" "" "$tsv_out"
assert_contains "stderr" "inflight: assignee lookup for #11 failed" "$(cat "$scratch_root/err")"
out=$(run_inflight "$clone2")
assert_contains "human keeps the fallback" "  assignee:  ?" "$out"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
