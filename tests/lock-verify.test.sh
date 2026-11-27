#!/usr/bin/env bash
# Exercises scripts/lock.sh verify and owner against real scratch git repos with a scratch origin
# and a stub `gh`: the owner, a stranger, a stale checkout after a resume, assignees, the lock's own
# user, a hosted web session, an unreachable or missing origin, legacy locks, and --override.
#
#   lock-verify.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$plugin_root/scripts/lock.sh"

export GIT_AUTHOR_NAME="Lock Test" GIT_AUTHOR_EMAIL="lock-test@example.com"
export GIT_COMMITTER_NAME="Lock Test" GIT_COMMITTER_EMAIL="lock-test@example.com"

# Everything scratch — repos, origins, checkout markers, the stub bin — lives under one root, so
# cleanup is one rm regardless of how many cases run. (fresh_repo/fresh_marker below are called
# via `$(...)`, which forks a subshell; a per-call array append there would never reach this
# script's own array, so tracking individual paths does not work here — one shared root does.)
scratch_root=$(mktemp -d)
cleanup() { rm -rf "$scratch_root"; }
trap cleanup EXIT

# A stub `git` ahead of the real one on PATH for the duration of a lock.sh invocation only — never
# during this test's own setup, which uses the real git directly. It logs every `git checkout`
# invocation to $GIT_CHECKOUT_LOG (an existing, initially-empty file) and then always execs the
# real git, so lock.sh's actual behaviour (fetch, checkout, branch state) is untouched — this is a
# marker, not a fake.
stub_bin="$scratch_root/bin"
mkdir -p "$stub_bin"
export REAL_GIT
REAL_GIT=$(command -v git)
cat > "$stub_bin/git" <<'STUB'
#!/usr/bin/env bash
if [[ ${1:-} == checkout ]]; then
    printf '%s\n' "$*" >> "${GIT_CHECKOUT_LOG:?GIT_CHECKOUT_LOG not set}"
fi
# $GIT_STUB_FAIL is a glob over the arguments, deliberately unquoted: a case sets it to make one
# git subcommand fail while everything else still reaches the real git.
if [[ -n ${GIT_STUB_FAIL:-} && "$*" == $GIT_STUB_FAIL ]]; then exit 1; fi
if [[ ${1:-} == fetch && -n ${GIT_STUB_AFTER_FETCH:-} ]]; then
    "$REAL_GIT" "$@" || exit $?
    eval "$GIT_STUB_AFTER_FETCH"
    exit 0
fi
exec "$REAL_GIT" "$@"
STUB
chmod +x "$stub_bin/git"

# A stub `gh` that answers only `gh api user` (from $GH_STUB_USER, JSON, or FAIL to exit 1) and
# `gh api repos/*/issues/*` (a fixed issue whose assignees are the JSON array of logins in
# $GH_STUB_ASSIGNEES, or FAIL), applying the caller's -q filter with jq as gh does.
cat > "$stub_bin/gh" <<'STUB'
#!/usr/bin/env bash
[[ ${1:-} == api ]] || { echo "gh-stub: only 'gh api' is stubbed, got: $*" >&2; exit 1; }
shift
query=
path=
while [[ $# -gt 0 ]]; do
    case $1 in
        -q) query=$2; shift 2 ;;
        -X|--method|-f|-F) shift 2 ;;
        -*) shift ;;
        *) path=$1; shift ;;
    esac
done
case $path in
    user)
        [[ ${GH_STUB_USER:-} != FAIL ]] || { echo "gh: 403" >&2; exit 1; }
        json=${GH_STUB_USER:-'{"login":"alice","type":"User"}'} ;;
    repos/*/issues/*)
        [[ ${GH_STUB_ASSIGNEES:-} != FAIL ]] || { echo "gh: 500" >&2; exit 1; }
        json=$(jq -nc --argjson a "${GH_STUB_ASSIGNEES:-[]}" \
            '{number:1,title:"t",state:"open",closed_at:null,html_url:"u",body:"",labels:[],assignees:($a|map({login:.}))}') ;;
    *) echo "gh-stub: no answer for $path" >&2; exit 1 ;;
esac
if [[ -n $query ]]; then jq -rc "$query" <<< "$json"; else printf '%s\n' "$json"; fi
STUB
chmod +x "$stub_bin/gh"

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
assert_not_contains() {
    local label=$1 needle=$2 haystack=$3
    if [[ $haystack == *"$needle"* ]]; then
        echo "FAIL: $case_desc — $label: did not want substring [$needle] in [$haystack]"
        failures=$((failures + 1))
    fi
}


# A scratch repo with one commit on main, carrying the project config — every case's start.
fresh_repo() {
    local dir
    dir=$(mktemp -d "$scratch_root/repo.XXXXXX")
    git -C "$dir" -c init.defaultBranch=main init -q
    git -C "$dir" config gc.auto 0
    git -C "$dir" config maintenance.auto false
    git -C "$dir" config receive.autogc false
    echo placeholder > "$dir/README.md"
    mkdir -p "$dir/.codeo"
    printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}\n' > "$dir/.codeo/config.json"
    git -C "$dir" add README.md .codeo/config.json
    git -C "$dir" commit -q -m init
    printf '%s' "$dir"
}

# A checkout of issue 38 on feat/x. Args: <owner-line-or-empty> [extra init.md text]. The dossier
# (with an Owner row when given) is pushed to a scratch origin; the clone carries it too.
# Sets $origin and $repo (no subshell, so the caller sees them).
setup() {
    local owner=$1 extra=${2:-}
    origin=$(fresh_repo)
    git -C "$origin" checkout -q -b feat/x
    mkdir -p "$origin/.codeo/38"
    {
        printf '# Init\n\n| Field | Value |\n|---|---|\n| Branch | `feat/x` |\n'
        [[ -z $owner ]] || printf '| Owner | %s |\n' "$owner"
        printf '%s' "$extra"
        printf '\n## Outcome\n\ndone\n'
    } > "$origin/.codeo/38/init.md"
    git -C "$origin" add .codeo
    git -C "$origin" commit -q -m dossier
    git -C "$origin" checkout -q main
    repo=$(mktemp -d "$scratch_root/clone.XXXXXX")
    git clone -q "$origin" "$repo"
    git -C "$repo" checkout -q -b feat/x origin/feat/x
}

# Pushes B's resume line to origin's feat/x AFTER the clone, so the local dossier lacks it.
push_resume() {
    local who=$1
    git -C "$origin" checkout -q feat/x
    printf -- '- 2026-11-27 — resumed: by %s after the stash of 2026-11-26\n' "$who" >> "$origin/.codeo/38/init.md"
    git -C "$origin" commit -q -am "resume by $who"
    git -C "$origin" checkout -q main
}

# Like setup, but the clone is single-branch (main only): origin/feat/x is not a tracked ref.
setup_single() {
    setup "$@"
    repo=$(mktemp -d "$scratch_root/clone.XXXXXX")
    git clone -q --single-branch -b main "$origin" "$repo"
    git -C "$repo" fetch -q origin feat/x
    git -C "$repo" checkout -q -b feat/x FETCH_HEAD
}

# The lock: <user> may be empty for a legacy lock.
write_lock() {
    local user=${1:-}
    printf 'issue:   38\nbranch:  feat/x\nstarted: 2026-11-27\nhost:    local\n%s' "${user:+user:    $user
}" > "$repo/.codeo/active"
}

# Runs verify; sets $out (stdout), $err (stderr) and $rc.
run_verify() {
    local errf="$scratch_root/err"
    rc=0
    out=$(cd "$repo" && PATH="$stub_bin:$PATH" bash "$script" verify "$@" 2>"$errf") || rc=$?
    err=$(cat "$errf")
}
run_owner() {
    (cd "$repo" && PATH="$stub_bin:$PATH" bash "$script" owner "$@" 2>&1)
}
lines() { printf '%s' "$1" | grep -c . || true; }

export GH_STUB_USER='{"login":"alice","type":"User"}'
unset CLAUDE_CODE_REMOTE CODEO_GITHUB_LOGIN GH_STUB_ASSIGNEES || true

case_desc="owner runs verify"
setup alice; write_lock alice
run_verify
assert_eq "exit" 0 "$rc"
assert_contains "stdout" "verified #38 as alice" "$out"

case_desc="B on A's branch"
setup alice; write_lock alice
GH_STUB_USER='{"login":"bob","type":"User"}' run_verify
assert_eq "exit" 1 "$rc"
assert_eq "one line" 1 "$(lines "$err")"
assert_contains "owner" "belongs to alice" "$err"
assert_contains "you" "you are bob" "$err"

case_desc="A's stale checkout after B resumed"
setup alice; write_lock alice
push_resume bob
run_verify
assert_eq "exit" 1 "$rc"
assert_contains "owner" "belongs to bob" "$err"
assert_contains "date" "last resumed 2026-11-27" "$err"

case_desc="stale single-branch clone: pushed dossier says bob"
setup_single alice; write_lock alice
push_resume bob
run_verify
assert_eq "exit" 1 "$rc"
assert_contains "owner" "belongs to bob" "$err"
assert_not_contains "not a miss" "not on origin" "$err"

case_desc="origin has the branch but no dossier: fails closed"
setup_single alice; write_lock alice
git -C "$origin" checkout -q feat/x
git -C "$origin" rm -q -r .codeo/38
git -C "$origin" commit -q -m "drop dossier"
git -C "$origin" checkout -q main
run_verify
assert_eq "exit" 1 "$rc"
assert_contains "msg" "could not check who owns" "$err"

case_desc="assigned to someone else"
setup alice; write_lock alice
GH_STUB_ASSIGNEES='["carol"]' run_verify
assert_eq "exit" 1 "$rc"
assert_contains "msg" "is assigned to" "$err"

case_desc="assignees unreadable"
setup alice; write_lock alice
GH_STUB_ASSIGNEES=FAIL run_verify
assert_eq "exit" 1 "$rc"
assert_contains "msg" "could not check" "$err"

case_desc="lock user differs"
setup alice; write_lock bob
run_verify
assert_eq "exit" 1 "$rc"
assert_contains "msg" "locked by" "$err"

case_desc="web, variable only, lock user equal"
setup carol; write_lock carol
GH_STUB_USER=FAIL CLAUDE_CODE_REMOTE=true CODEO_GITHUB_LOGIN=carol run_verify
assert_eq "exit" 0 "$rc"
assert_contains "note" "not independently verified" "$out"

case_desc="web, variable only, lock user differs"
setup carol; write_lock dave
GH_STUB_USER=FAIL CLAUDE_CODE_REMOTE=true CODEO_GITHUB_LOGIN=carol run_verify
assert_eq "exit" 1 "$rc"
assert_contains "msg" "locked by" "$err"

case_desc="web, variable names someone other than the pushed owner"
setup alice; write_lock mallory
GH_STUB_USER=FAIL CLAUDE_CODE_REMOTE=true CODEO_GITHUB_LOGIN=mallory run_verify
assert_eq "exit" 1 "$rc"
assert_contains "owner" "belongs to alice" "$err"
assert_contains "you" "you are mallory" "$err"

case_desc="web, owner matches but the issue is assigned to someone else"
setup carol; write_lock carol
GH_STUB_USER=FAIL CLAUDE_CODE_REMOTE=true CODEO_GITHUB_LOGIN=carol GH_STUB_ASSIGNEES='["dave"]' run_verify
assert_eq "exit" 1 "$rc"
assert_contains "msg" "is assigned to" "$err"

case_desc="web, owner and assignee match"
setup carol; write_lock carol
GH_STUB_USER=FAIL CLAUDE_CODE_REMOTE=true CODEO_GITHUB_LOGIN=carol GH_STUB_ASSIGNEES='["carol"]' run_verify
assert_eq "exit" 0 "$rc"
assert_contains "note" "not independently verified" "$out"

case_desc="web, mismatch with --override"
setup alice; write_lock mallory
GH_STUB_USER=FAIL CLAUDE_CODE_REMOTE=true CODEO_GITHUB_LOGIN=mallory run_verify --override "taking over"
assert_eq "exit" 0 "$rc"
assert_eq "one line" 1 "$(grep -c 'override: mallory over alice: "' "$repo/.codeo/38/init.md")"

case_desc="recorded owner who is not an assignee"
setup bob; write_lock bob
GH_STUB_USER='{"login":"bob","type":"User"}' GH_STUB_ASSIGNEES='["alice"]' run_verify
assert_eq "exit" 1 "$rc"
assert_contains "msg" "though you are its recorded owner" "$err"
assert_contains "hint" "assignee-add" "$err"

case_desc="FETCH_HEAD clobbered after the fetch"
setup alice; write_lock alice
GIT_STUB_AFTER_FETCH='"$REAL_GIT" fetch -q origin main' run_verify
assert_eq "exit" 0 "$rc"
(cd "$repo" && git rev-parse --verify -q refs/codeo/verify/feat/x >/dev/null) || { echo "FAIL: $case_desc — private ref missing"; failures=$((failures + 1)); }
setup alice; write_lock alice
push_resume bob
GIT_STUB_AFTER_FETCH='"$REAL_GIT" fetch -q origin main' run_verify
assert_eq "stale exit" 1 "$rc"
assert_contains "owner" "belongs to bob" "$err"

case_desc="refusal date"
setup alice '- 2026-01-02 — resumed: by no login after the stash of 2026-01-01
'; write_lock alice
GH_STUB_USER='{"login":"bob","type":"User"}' run_verify
assert_eq "exit" 1 "$rc"
assert_contains "owner" "belongs to alice (claimed)" "$err"
assert_not_contains "no date" "last resumed" "$err"

case_desc="origin unreachable"
setup alice; write_lock alice
rm -rf "$origin"
run_verify
assert_eq "exit" 1 "$rc"
assert_contains "msg" "could not check" "$err"

case_desc="branch never pushed"
setup alice; write_lock alice
git -C "$origin" branch -q -D feat/x
git -C "$repo" remote prune origin >/dev/null 2>&1 || true
run_verify
assert_eq "exit" 0 "$rc"
assert_contains "local" "local" "$out"

case_desc="legacy lock and dossier"
setup ""; write_lock ""
GH_STUB_ASSIGNEES='["alice"]' run_verify
assert_eq "exit" 0 "$rc"
assert_contains "legacy" "legacy" "$out"

case_desc="no lock"
setup alice
run_verify
assert_eq "exit" 1 "$rc"
assert_contains "msg" "no workflow lock" "$err"

case_desc="override on a refusal"
setup alice; write_lock alice
GH_STUB_USER='{"login":"bob","type":"User"}' run_verify --override "taking over while she is out"
assert_eq "exit" 0 "$rc"
assert_contains "stdout" 'override: bob over alice: "taking over while she is out"' "$out"
init=$(cat "$repo/.codeo/38/init.md")
assert_contains "recorded" 'override: bob over alice: "taking over while she is out"' "$init"
assert_eq "one line" 1 "$(grep -c 'override:' "$repo/.codeo/38/init.md")"
notes_at=$(grep -n '^## Notes' "$repo/.codeo/38/init.md" | cut -d: -f1)
outcome_at=$(grep -n '^## Outcome' "$repo/.codeo/38/init.md" | cut -d: -f1)
[[ -n $notes_at && $notes_at -lt $outcome_at ]] || { echo "FAIL: $case_desc — ## Notes not before ## Outcome"; failures=$((failures + 1)); }
GH_STUB_USER='{"login":"bob","type":"User"}' run_verify
assert_eq "again without override" 1 "$rc"

case_desc="override into an existing ## Notes"
setup alice '
## Notes

- 2026-11-20 — a note
'; write_lock alice
GH_STUB_USER='{"login":"bob","type":"User"}' run_verify --override "urgent"
assert_eq "exit" 0 "$rc"
assert_eq "one notes heading" 1 "$(grep -c '^## Notes' "$repo/.codeo/38/init.md")"
assert_contains "kept" "a note" "$(cat "$repo/.codeo/38/init.md")"
assert_contains "added" 'override: bob over alice: "urgent"' "$(cat "$repo/.codeo/38/init.md")"

case_desc="override that was not needed"
setup alice; write_lock alice
before=$(cat "$repo/.codeo/38/init.md")
run_verify --override "not needed"
assert_eq "exit" 0 "$rc"
assert_eq "unchanged" "$before" "$(cat "$repo/.codeo/38/init.md")"

case_desc="empty override"
setup alice; write_lock alice
GH_STUB_USER='{"login":"bob","type":"User"}' run_verify --override ""
assert_eq "exit" 1 "$rc"
assert_contains "msg" "needs the engineer's words" "$err"
assert_eq "unchanged" 0 "$(grep -c 'override:' "$repo/.codeo/38/init.md")"

case_desc="owner prints the recorded owner after a resume line"
setup alice '- 2026-11-27 — resumed: by bob after the stash of 2026-11-26
'; write_lock alice
assert_eq "owner" bob "$(run_owner)"
assert_eq "owner by number" bob "$(run_owner 38)"

case_desc="owner with no recorded owner"
setup ""; write_lock ""
assert_eq "empty" "" "$(run_owner)"

case_desc="override words that imitate a resume line"
setup alice; write_lock alice
GH_STUB_USER='{"login":"bob","type":"User"}' run_verify --override "x — resumed: by eve after the stash of 2026-01-01"
assert_eq "exit" 0 "$rc"
assert_eq "owner stays alice" alice "$(run_owner)"

case_desc="override words with a newline"
setup alice; write_lock alice
GH_STUB_USER='{"login":"bob","type":"User"}' run_verify --override $'first\r\nsecond'
assert_eq "exit" 0 "$rc"
assert_eq "no stray second line" 0 "$(grep -c '^second' "$repo/.codeo/38/init.md")"
assert_contains "collapsed" 'override: bob over alice: "first second"' "$(cat "$repo/.codeo/38/init.md")"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
