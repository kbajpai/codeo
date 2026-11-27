#!/usr/bin/env bash
# Exercises scripts/lock.sh's take() against real scratch git repos: the hosts' shared logic
# (on-main, matching branch, already-locked, the done/ archive fallback) plus the web-only branch
# checkout and the guarantee that a container or a plain local checkout never attempts one, even
# when the checked-out branch does not match the dossier it finds. Touches no real git config (identity is
# exported, not written) and makes no network call — "origin" is a second scratch repo reached by
# a local path.
#
#   lock.test.sh
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

# A scratch repo with one commit on main — every case's starting point.
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
    # The config is committed so every clone of this repo carries it too.
    mkdir -p "$dir/.codeo"
    printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}\n' > "$dir/.codeo/config.json"
    git -C "$dir" add README.md .codeo/config.json
    git -C "$dir" commit -q -m init
    printf '%s' "$dir"
}

# A dossier's init.md, with the one line find_issue and lock.sh's checkout step both key on.
write_init() {
    local path=$1 branch=$2
    mkdir -p "$(dirname "$path")"
    printf '# Init\n\n| Field | Value |\n|---|---|\n| Branch | `%s` |\n' "$branch" > "$path"
}

# A fresh, empty checkout-marker file — present but empty means "no checkout ran"; non-empty means
# it did, with the exact `git checkout …` arguments logged.
fresh_marker() {
    mktemp "$scratch_root/marker.XXXXXX"
}

# A clone of an origin, checked out on a harness branch cut from origin's <branch> — the shape a
# web session has when it starts from the branch selector, and the only shape in which the
# checkout's fast-forward test is meaningful (two unrelated repos are the diverged case).
harness_clone() {
    local origin=$1 branch=$2 dir
    dir=$(mktemp -d "$scratch_root/clone.XXXXXX")
    git clone -q "$origin" "$dir"
    git -C "$dir" checkout -q -b claude/scratch "origin/$branch"
    printf '%s' "$dir"
}

run_lock() {
    local repo=$1 marker=$2
    shift 2
    # $LOCK_EXTRA_BIN, when a case sets it, goes ahead of the git stub so that one case can
    # shadow a tool (a failing awk) without touching $stub_bin for every other case.
    (cd "$repo" && PATH="${LOCK_EXTRA_BIN:+$LOCK_EXTRA_BIN:}$stub_bin:$PATH" GIT_CHECKOUT_LOG="$marker" GIT_STUB_FAIL="${GIT_STUB_FAIL:-}" bash "$script" take "$@" 2>&1) || true
}

checked_out() { [[ -s $1 ]] && echo yes || echo no; }
active_exists() { [[ -f $1/.codeo/active ]] && echo yes || echo no; }

# --- container, on main ------------------------------------------------------------------------
case_desc="container, on main"
repo=$(fresh_repo)
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" container)
assert_eq "active written" no "$(active_exists "$repo")"
assert_contains "message" "no workflow lock" "$out"

# --- container, matching branch -----------------------------------------------------------------
case_desc="container, matching branch"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b feat/x
write_init "$repo/.codeo/38/init.md" feat/x
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" container)
assert_contains "took the lock" "took the lock for #38 on feat/x" "$out"
assert_eq "active written" yes "$(active_exists "$repo")"
active=$(cat "$repo/.codeo/active")
assert_contains "issue" "issue:   38" "$active"
assert_contains "host" "host:    container" "$active"
assert_not_contains "no session line" "session:" "$active"
assert_contains "user" "user:    alice" "$active"

# --- container, sandbox lock ---------------------------------------------------------------------
case_desc="container, sandbox lock"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b feat/x
write_init "$repo/.codeo/38/init.md" feat/x
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" container --sandbox codeo-38)
active=$(cat "$repo/.codeo/active")
assert_contains "sandbox line" "sandbox: codeo-38" "$active"
assert_contains "host" "host:    container" "$active"
assert_not_contains "no volume line" "volume:" "$active"
assert_not_contains "no TODO" "TODO" "$out"

# --- container, sandbox name refused ---------------------------------------------------------------
case_desc="container, sandbox name refused"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b feat/x
write_init "$repo/.codeo/38/init.md" feat/x
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" container --sandbox 'a b')
active=$(cat "$repo/.codeo/active")
assert_contains "refusal" "--sandbox needs a name" "$out"
assert_contains "volume line" "volume:" "$active"
assert_not_contains "no sandbox line" "sandbox:" "$active"

# --- container, volume read ------------------------------------------------------------------------
case_desc="container, volume read"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b feat/x
write_init "$repo/.codeo/38/init.md" feat/x
marker=$(fresh_marker)
mountinfo="$scratch_root/mountinfo.read"
echo '100 1 0:50 /var/lib/docker/volumes/codeo-38/_data /workspaces rw - ext4 /dev/x rw' > "$mountinfo"
out=$(CODEO_MOUNTINFO="$mountinfo" run_lock "$repo" "$marker" container)
active=$(cat "$repo/.codeo/active")
assert_contains "volume" "volume:  codeo-38" "$active"
assert_not_contains "no TODO" "TODO" "$out"

# --- container, volume unreadable ------------------------------------------------------------------
case_desc="container, volume unreadable"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b feat/x
write_init "$repo/.codeo/38/init.md" feat/x
marker=$(fresh_marker)
mountinfo="$scratch_root/mountinfo.empty"
: > "$mountinfo"
out=$(CODEO_MOUNTINFO="$mountinfo" run_lock "$repo" "$marker" container)
active=$(cat "$repo/.codeo/active")
assert_contains "volume unknown" "volume:  unknown" "$active"
assert_contains "TODO" "could not read the workspace volume's name from /proc/self/mountinfo: fill the lock's volume line in by hand (docker volume ls on the host)" "$out"

# --- container, already locked -------------------------------------------------------------------
case_desc="container, already locked"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b feat/x
write_init "$repo/.codeo/38/init.md" feat/x
mkdir -p "$repo/.codeo"
printf 'issue:   38\nbranch:  feat/x\nstarted: 2020-01-01\nhost:    container\nvolume:  codeo-38\n' \
    > "$repo/.codeo/active"
before=$(cat "$repo/.codeo/active")
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" container)
assert_contains "message" "lock already taken" "$out"
assert_eq "file unchanged" "$before" "$(cat "$repo/.codeo/active")"

# --- container, archived fallback -----------------------------------------------------------------
case_desc="container, archived fallback"
origin=$(fresh_repo)
repo=$(fresh_repo)
git -C "$repo" remote add origin "$origin"
git -C "$repo" checkout -q -b feat/y
write_init "$repo/.codeo/done/40/init.md" feat/y
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" container)
assert_contains "took the lock" "took the lock for #40 on feat/y" "$out"
active=$(cat "$repo/.codeo/active")
assert_contains "issue" "issue:   40" "$active"

# --- container, run from a subdirectory ---------------------------------------------------------
case_desc="container, run from a subdirectory"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b feat/x
write_init "$repo/.codeo/38/init.md" feat/x
mkdir -p "$repo/sub/deep"
marker=$(fresh_marker)
out=$(run_lock "$repo/sub/deep" "$marker" container)
assert_contains "took the lock" "took the lock for #38 on feat/x" "$out"
assert_eq "active written at the root" yes "$(active_exists "$repo")"

# --- container, archived fallback with a develop base branch ---------------------------------------
case_desc="container, archived fallback reads the configured base branch (develop)"
origin=$(fresh_repo)
git -C "$origin" branch -m main develop
repo=$(fresh_repo)
git -C "$repo" branch -m main develop
sed -i 's/"baseBranch":"main"/"baseBranch":"develop"/' "$repo/.codeo/config.json"
git -C "$repo" commit -q -am "base develop"
git -C "$repo" remote add origin "$origin"
git -C "$repo" checkout -q -b feat/y
write_init "$repo/.codeo/done/41/init.md" feat/y
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" container)
assert_contains "took the lock" "took the lock for #41 on feat/y" "$out"
marker=$(fresh_marker)
git -C "$repo" checkout -q develop
rm -f "$repo/.codeo/active"
out=$(run_lock "$repo" "$marker" container)
assert_contains "on develop, no lock" "on develop: no workflow lock" "$out"

# --- web, branch already matches ------------------------------------------------------------------
case_desc="web, branch already matches"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b feat/x
write_init "$repo/.codeo/38/init.md" feat/x
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" web sess_1)
assert_eq "no checkout" no "$(checked_out "$marker")"
active=$(cat "$repo/.codeo/active")
assert_contains "issue" "issue:   38" "$active"
assert_contains "host" "host:    web" "$active"
assert_contains "session" "session: sess_1" "$active"

# An origin with feat/x and its dossier, and a harness clone one local commit ahead of it ($repo).
ahead_clone() {
    local origin
    origin=$(fresh_repo)
    git -C "$origin" checkout -q -b feat/x
    write_init "$origin/.codeo/38/init.md" feat/x
    git -C "$origin" add .codeo
    git -C "$origin" commit -q -m dossier
    repo=$(harness_clone "$origin" feat/x)
    echo work > "$repo/work.txt"
    git -C "$repo" add work.txt
    git -C "$repo" commit -q -m "session work"
}

# A local feat/x one commit past origin/feat/x, in $repo, without leaving the current branch.
stale_feat_x() {
    local here sha
    here=$(git -C "$repo" branch --show-current)
    git -C "$repo" checkout -q -b scratch/stale origin/feat/x
    echo stale > "$repo/stale.txt"
    git -C "$repo" add stale.txt
    git -C "$repo" commit -q -m "local only"
    sha=$(git -C "$repo" rev-parse HEAD)
    git -C "$repo" checkout -q "$here"
    git -C "$repo" branch -q -D scratch/stale
    git -C "$repo" branch -q -f feat/x "$sha"
}

# --- web, needs checkout: HEAD contained in origin's branch ----------------------------------------
case_desc="web, needs checkout"
origin=$(fresh_repo)
git -C "$origin" checkout -q -b feat/x
write_init "$origin/.codeo/38/init.md" feat/x
git -C "$origin" add .codeo
git -C "$origin" commit -q -m dossier
repo=$(harness_clone "$origin" feat/x)

marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" web sess_2)
assert_eq "checkout happened" yes "$(checked_out "$marker")"
assert_contains "checkout args" "checkout -q -B feat/x origin/feat/x" "$(cat "$marker")"
assert_contains "took the lock" "took the lock for #38 on feat/x" "$out"
assert_not_contains "nothing carried" "carrying" "$out"
assert_eq "final branch" feat/x "$(git -C "$repo" branch --show-current)"
active=$(cat "$repo/.codeo/active")
assert_contains "issue" "issue:   38" "$active"
assert_contains "host" "host:    web" "$active"
assert_contains "session" "session: sess_2" "$active"

# --- web, needs checkout: the harness branch is ahead — its commits are carried --------------------
case_desc="web, needs checkout, harness branch ahead"
origin=$(fresh_repo)
git -C "$origin" checkout -q -b feat/x
write_init "$origin/.codeo/38/init.md" feat/x
git -C "$origin" add .codeo
git -C "$origin" commit -q -m dossier
repo=$(harness_clone "$origin" feat/x)
echo work > "$repo/work.txt"
git -C "$repo" add work.txt
git -C "$repo" commit -q -m "session work"
tip=$(git -C "$repo" rev-parse HEAD)

marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" web sess_4)
assert_eq "checkout happened" yes "$(checked_out "$marker")"
assert_contains "checkout args" "checkout -q -B feat/x HEAD" "$(cat "$marker")"
assert_eq "final branch" feat/x "$(git -C "$repo" branch --show-current)"
assert_eq "tip kept" "$tip" "$(git -C "$repo" rev-parse HEAD)"
assert_eq "upstream set" origin/feat/x "$(git -C "$repo" rev-parse --abbrev-ref '@{u}')"
assert_contains "says how many" "carrying 1 unpushed commit" "$out"
assert_contains "took the lock" "took the lock for #38 on feat/x" "$out"

# --- web, needs checkout: diverged — refused, no lock ----------------------------------------------
case_desc="web, needs checkout, diverged"
origin=$(fresh_repo)
git -C "$origin" checkout -q -b feat/x
write_init "$origin/.codeo/38/init.md" feat/x
git -C "$origin" add .codeo
git -C "$origin" commit -q -m dossier
repo=$(harness_clone "$origin" feat/x)
echo work > "$repo/work.txt"
git -C "$repo" add work.txt
git -C "$repo" commit -q -m "session work"
echo other > "$origin/other.txt"
git -C "$origin" add other.txt
git -C "$origin" commit -q -m "pushed elsewhere"
tip=$(git -C "$repo" rev-parse HEAD)

marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" web sess_5)
assert_eq "no checkout" no "$(checked_out "$marker")"
assert_eq "still on the harness branch" claude/scratch "$(git -C "$repo" branch --show-current)"
assert_eq "tip kept" "$tip" "$(git -C "$repo" rev-parse HEAD)"
assert_eq "no active written" no "$(active_exists "$repo")"
assert_contains "todo says diverged" "claude/scratch and origin/feat/x have diverged" "$out"
assert_contains "todo names the command" "git log --oneline origin/feat/x..HEAD" "$out"
assert_not_contains "no init advice" "run init" "$out"

case_desc="web, ahead, set-upstream-to fails: lock taken, TODO names the upstream"
ahead_clone
out=$(GIT_STUB_FAIL='branch -q --set-upstream-to*' run_lock "$repo" "$(fresh_marker)" web sess_6)
assert_eq "final branch" feat/x "$(git -C "$repo" branch --show-current)"
assert_contains "lock taken" "took the lock for #38 on feat/x" "$out"
assert_contains "todo names the upstream" "could not set the upstream of feat/x to origin/feat/x" "$out"
assert_not_contains "not reported as a failed checkout" "could not check out" "$out"

case_desc="web, ahead, rev-list --count fails: still carried"
ahead_clone
out=$(GIT_STUB_FAIL='rev-list --count*' run_lock "$repo" "$(fresh_marker)" web sess_7)
assert_contains "lock taken" "took the lock for #38 on feat/x" "$out"
assert_contains "count unknown" "carrying an unknown number of unpushed commit(s)" "$out"

case_desc="web, ahead, a local branch holds other commits: refused"
ahead_clone
stale_feat_x
tip=$(git -C "$repo" rev-parse feat/x)
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" web sess_8)
assert_eq "no checkout" no "$(checked_out "$marker")"
assert_eq "local branch untouched" "$tip" "$(git -C "$repo" rev-parse feat/x)"
assert_eq "no active written" no "$(active_exists "$repo")"
assert_contains "todo names the commits" "git log --oneline HEAD..feat/x" "$out"
assert_not_contains "no init advice" "run init" "$out"

case_desc="web, contained, a local branch holds other commits: refused"
origin=$(fresh_repo)
git -C "$origin" checkout -q -b feat/x
write_init "$origin/.codeo/38/init.md" feat/x
git -C "$origin" add .codeo
git -C "$origin" commit -q -m dossier
repo=$(harness_clone "$origin" feat/x)
stale_feat_x
tip=$(git -C "$repo" rev-parse feat/x)
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" web sess_9)
assert_eq "no checkout" no "$(checked_out "$marker")"
assert_eq "local branch untouched" "$tip" "$(git -C "$repo" rev-parse feat/x)"
assert_eq "no active written" no "$(active_exists "$repo")"
assert_contains "todo names the commits" "git log --oneline origin/feat/x..feat/x" "$out"
assert_not_contains "no init advice" "run init" "$out"

# --- web, no dossier at all -----------------------------------------------------------------------
case_desc="web, no dossier at all"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b claude/idle
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" web sess_3)
assert_eq "no checkout" no "$(checked_out "$marker")"
assert_eq "no active written" no "$(active_exists "$repo")"
assert_contains "todo names the branch" "no single init.md names branch claude/idle" "$out"

# --- container, checkout never attempted even on mismatch ------------------------------------------
case_desc="container, checkout never attempted even on mismatch"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b feat/other
write_init "$repo/.codeo/38/init.md" feat/x
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" container)
assert_eq "no checkout" no "$(checked_out "$marker")"
assert_eq "no active written" no "$(active_exists "$repo")"
assert_contains "todo names the branch" "no single init.md names branch feat/other" "$out"

# --- local: a plain checkout, with no container volume and no session to identify ---------------
case_desc="local_host_writes_no_volume_line_and_no_todo"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b feat/x
write_init "$repo/.codeo/38/init.md" feat/x
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" local)
assert_contains "took the lock" "took the lock for #38 on feat/x" "$out"
active=$(cat "$repo/.codeo/active")
assert_contains "host" "host:    local" "$active"
assert_not_contains "no volume line" "volume:" "$active"
assert_not_contains "no session line" "session:" "$active"
assert_not_contains "no TODO" "TODO" "$out"

case_desc="local_host_never_attempts_a_branch_checkout"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b feat/other
write_init "$repo/.codeo/38/init.md" feat/x
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" local)
assert_eq "no checkout" no "$(checked_out "$marker")"
assert_eq "no active written" no "$(active_exists "$repo")"
assert_contains "todo names the branch" "no single init.md names branch feat/other" "$out"

case_desc="local_host_lock_matches_container_otherwise"
local_repo=$(fresh_repo)
container_repo=$(fresh_repo)
for r in "$local_repo" "$container_repo"; do
    git -C "$r" checkout -q -b feat/x
    write_init "$r/.codeo/38/init.md" feat/x
done
run_lock "$local_repo" "$(fresh_marker)" local >/dev/null
run_lock "$container_repo" "$(fresh_marker)" container >/dev/null
assert_eq "issue, branch and started lines" \
    "$(grep -E '^(issue|branch|started):' "$container_repo/.codeo/active")" \
    "$(grep -E '^(issue|branch|started):' "$local_repo/.codeo/active")"
assert_eq "dossier untouched" "$(cat "$container_repo/.codeo/38/init.md")" "$(cat "$local_repo/.codeo/38/init.md")"

# --- web, lock written while the session id was unset -----------------------------------------------
locked_repo() {
    local dir
    dir=$(fresh_repo)
    git -C "$dir" checkout -q -b feat/x
    write_init "$dir/.codeo/38/init.md" feat/x
    printf 'issue:   38\nbranch:  feat/x\nstarted: 2020-01-01\nhost:    %s\n%s\n' "$1" "$2" > "$dir/.codeo/active"
    printf '%s' "$dir"
}

case_desc="web, session: unknown is refreshed by a real id"
repo=$(locked_repo web "session: unknown")
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" web sess_2)
active=$(cat "$repo/.codeo/active")
assert_contains "session replaced" "session: sess_2" "$active"
assert_not_contains "unknown gone" "unknown" "$active"
assert_contains "other lines kept" "issue:   38" "$active"
assert_contains "host kept" "host:    web" "$active"
assert_contains "says so" "session" "$out"

case_desc="web, a real session id is left alone"
repo=$(locked_repo web "session: sess_1")
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" web sess_2)
assert_contains "kept" "session: sess_1" "$(cat "$repo/.codeo/active")"
assert_not_contains "not replaced" "sess_2" "$(cat "$repo/.codeo/active")"
assert_contains "message" "lock already taken" "$out"

case_desc="web, unknown stays when no real id is passed"
repo=$(locked_repo web "session: unknown")
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" web)
assert_contains "kept" "session: unknown" "$(cat "$repo/.codeo/active")"

case_desc="container, a lock with an unknown session line is never rewritten"
repo=$(locked_repo container "session: unknown")
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" container sess_2)
assert_contains "kept" "session: unknown" "$(cat "$repo/.codeo/active")"
assert_not_contains "not replaced" "sess_2" "$(cat "$repo/.codeo/active")"

case_desc="web, a failed refresh is a TODO, not a false 'refreshed'"
repo=$(locked_repo web "session: unknown")
awk_fail_bin="$scratch_root/awk-fail"
mkdir -p "$awk_fail_bin"
printf '#!/usr/bin/env bash\nexit 1\n' > "$awk_fail_bin/awk"
chmod +x "$awk_fail_bin/awk"
marker=$(fresh_marker)
out=$(LOCK_EXTRA_BIN="$awk_fail_bin" run_lock "$repo" "$marker" web sess_2)
assert_contains "lock still says unknown" "session: unknown" "$(cat "$repo/.codeo/active")"
assert_not_contains "no false refreshed" "refreshed" "$out"
assert_contains "todo names the refresh" "TODO — could not refresh" "$out"
assert_contains "still reports the lock" "lock already taken" "$out"
assert_eq "no temp file left" no "$([[ -e $repo/.codeo/active.tmp ]] && echo yes || echo no)"

# --- CODEO_LOCK_SKIP_PARKED: a stashed or abandoned dossier takes no lock -------------------------
parked_repo() {
    local dir
    dir=$(fresh_repo)
    git -C "$dir" checkout -q -b feat/x
    write_init "$dir/.codeo/38/init.md" feat/x
    printf '%b' "$1" > "$dir/.codeo/38/close.md"
    printf '%s' "$dir"
}
run_lock_skip() { CODEO_LOCK_SKIP_PARKED=1 run_lock "$@"; }

case_desc="take_skips_a_stashed_dossier_when_asked"
repo=$(parked_repo '# Close\n\n### Round 1 — stashed\n')
out=$(run_lock_skip "$repo" "$(fresh_marker)" web)
assert_eq "no lock" no "$(active_exists "$repo")"
assert_contains "todo" "lock: TODO — #38 is stashed or abandoned: no lock taken" "$out"

case_desc="take_skips_an_abandoned_dossier_when_asked"
repo=$(parked_repo '# Close\n\n### Round 2 — abandoned\n')
out=$(run_lock_skip "$repo" "$(fresh_marker)" web)
assert_eq "no lock" no "$(active_exists "$repo")"
assert_contains "todo" "lock: TODO — #38 is stashed or abandoned: no lock taken" "$out"

case_desc="take_takes_a_resumed_stash"
repo=$(parked_repo '# Close\n\n### Round 1 — stashed\n')
printf -- '\n## Log\n\n- 2026-11-21 — resumed: by alice after the stash of 2026-11-20 · cost: 0m\n' >> "$repo/.codeo/38/init.md"
out=$(run_lock_skip "$repo" "$(fresh_marker)" web)
assert_eq "lock taken" yes "$(active_exists "$repo")"

case_desc="take_skips_a_stash_with_a_later_close_round"
repo=$(parked_repo '### Round 1 — stashed\n\n### Round 2 — 2026-11-21\n')
out=$(run_lock_skip "$repo" "$(fresh_marker)" web)
assert_eq "no lock" no "$(active_exists "$repo")"
assert_contains "todo" "no lock taken" "$out"

case_desc="take_takes_a_resumed_abandon"
repo=$(parked_repo '### Round 1 — abandoned\n')
printf -- '- 2026-11-21 — resumed: by alice after the abandon of 2026-11-20 · cost: 0m\n' >> "$repo/.codeo/38/init.md"
out=$(run_lock_skip "$repo" "$(fresh_marker)" web)
assert_eq "lock taken" yes "$(active_exists "$repo")"

case_desc="web_take_with_skip_parked_does_not_check_out_a_stashed_dossier"
origin=$(fresh_repo)
git -C "$origin" checkout -q -b feat/x
write_init "$origin/.codeo/38/init.md" feat/x
printf '### Round 1 — stashed\n' > "$origin/.codeo/38/close.md"
git -C "$origin" add .codeo
git -C "$origin" commit -q -m dossier
repo=$(harness_clone "$origin" feat/x)
marker=$(fresh_marker)
out=$(run_lock_skip "$repo" "$marker" web sess_9)
assert_eq "no checkout" no "$(checked_out "$marker")"
assert_eq "head unchanged" claude/scratch "$(git -C "$repo" branch --show-current)"
assert_eq "no lock" no "$(active_exists "$repo")"
assert_contains "todo" "#38 is stashed or abandoned: no lock taken" "$out"
marker=$(fresh_marker)
out=$(run_lock "$repo" "$marker" web sess_9)
assert_eq "checkout without opt-in" yes "$(checked_out "$marker")"
assert_eq "on the dossier branch" feat/x "$(git -C "$repo" branch --show-current)"

case_desc="take_without_skip_parked_still_takes_a_stashed_dossier"
repo=$(parked_repo '### Round 1 — stashed\n')
out=$(run_lock "$repo" "$(fresh_marker)" web)
assert_eq "lock taken" yes "$(active_exists "$repo")"

# --- who is acting -------------------------------------------------------------------------------
# A clone of an origin whose branch feat/x carries an init.md with <owner_line> after the Branch row.
owned_clone() {
    local owner=$1 origin
    origin=$(fresh_repo)
    git -C "$origin" checkout -q -b feat/x
    write_init "$origin/.codeo/38/init.md" feat/x
    printf '| Owner | %s |\n' "$owner" >> "$origin/.codeo/38/init.md"
    git -C "$origin" add .codeo
    git -C "$origin" commit -q -m dossier
    git -C "$origin" checkout -q main
    local dir
    dir=$(mktemp -d "$scratch_root/clone.XXXXXX")
    git clone -q "$origin" "$dir"
    git -C "$dir" checkout -q -b feat/x origin/feat/x
    printf '%s' "$dir"
}

case_desc="take, unresolved login (GET /user fails, not web)"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b feat/x
write_init "$repo/.codeo/38/init.md" feat/x
out=$(GH_STUB_USER=FAIL CODEO_GITHUB_LOGIN=eve run_lock "$repo" "$(fresh_marker)" local)
assert_eq "no lock" no "$(active_exists "$repo")"
assert_contains "todo" "lock: TODO" "$out"
assert_contains "reason" "cannot tell who you are" "$out"

case_desc="take, Bot login"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b feat/x
write_init "$repo/.codeo/38/init.md" feat/x
out=$(GH_STUB_USER='{"login":"ci[bot]","type":"Bot"}' run_lock "$repo" "$(fresh_marker)" local)
assert_eq "no lock" no "$(active_exists "$repo")"
assert_contains "Bot" "Bot" "$out"

case_desc="take, web session, variable only"
repo=$(fresh_repo)
git -C "$repo" checkout -q -b feat/x
write_init "$repo/.codeo/38/init.md" feat/x
out=$(GH_STUB_USER=FAIL CLAUDE_CODE_REMOTE=true CODEO_GITHUB_LOGIN=carol run_lock "$repo" "$(fresh_marker)" local)
assert_eq "lock" yes "$(active_exists "$repo")"
assert_contains "user" "user:    carol" "$(cat "$repo/.codeo/active")"

case_desc="take, branch owned by someone else"
repo=$(owned_clone alice)
origin=$(git -C "$repo" remote get-url origin)
git -C "$origin" checkout -q feat/x
printf -- '- 2026-11-27 — resumed: by bob after the stash of 2026-11-26\n' >> "$origin/.codeo/38/init.md"
git -C "$origin" commit -q -am "resume by bob"
git -C "$origin" checkout -q main
out=$(run_lock "$repo" "$(fresh_marker)" local)
assert_eq "no lock" no "$(active_exists "$repo")"
assert_contains "todo" "lock: TODO" "$out"
assert_contains "owner" "belongs to bob" "$out"

case_desc="take, branch owned by the current user"
repo=$(owned_clone alice)
out=$(run_lock "$repo" "$(fresh_marker)" local)
assert_eq "lock" yes "$(active_exists "$repo")"

case_desc="take, web, pushed owner differs"
repo=$(owned_clone alice)
out=$(GH_STUB_USER=FAIL CLAUDE_CODE_REMOTE=true CODEO_GITHUB_LOGIN=mallory run_lock "$repo" "$(fresh_marker)" local)
assert_eq "no lock" no "$(active_exists "$repo")"
assert_contains "todo" "lock: TODO" "$out"
assert_contains "owner" "belongs to" "$out"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
