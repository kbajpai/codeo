#!/usr/bin/env bash
# Exercises `intake.sh lease` against real scratch git repos, a seeded config and a stubbed `gh`:
# take, wait, release, release-all, check and list; the queue, its grace and right of way; a push
# origin refused, which is never reported as done and leaves nothing on the clone's own branch;
# the configured resource list; the environment hooks (start, preflight, activate, revoke) and the
# order they run in; and the best-effort hooks.onLeaseChange command. Touches no real git config,
# secrets, network or CODEO_GITHUB_LOGIN — "origin" is a scratch repo reached by a local path, HOME
# is a scratch directory, and every GitHub call lands on the stub.
#
#   intake-lease.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
intake="$plugin_root/scripts/intake.sh"

export GIT_AUTHOR_NAME="Lease Test" GIT_AUTHOR_EMAIL="lease-test@example.com"
export GIT_COMMITTER_NAME="Lease Test" GIT_COMMITTER_EMAIL="lease-test@example.com"
# `github.sh user login` answers from this when GET /user is refused; the suite expects the
# `git config user.email` fallback each clone sets.
unset CODEO_GITHUB_LOGIN

scratch_root=$(mktemp -d)
cleanup() { rm -rf "$scratch_root"; }
trap cleanup EXIT

export HOME="$scratch_root/home"
mkdir -p "$HOME"

# A `gh` that answers every call "Not Found" (exit 1): github.sh's `user login` then falls back to
# `git config user.email`, which each clone sets below.
stub_bin="$scratch_root/bin"
mkdir -p "$stub_bin"
cat > "$stub_bin/gh" <<'STUB'
#!/usr/bin/env bash
echo '{"message":"Not Found"}'
exit 1
STUB
chmod +x "$stub_bin/gh"

# The environment hooks: one script, named by its first argument. It logs
# "<hook> #<CODEO_ISSUE> <CODEO_RESOURCE> <published|unpublished> override=<CODEO_OVERRIDE>" to
# $HOOK_LOG, where published says whether origin's intake branch already carries the resource's
# lease. HOOK_FAIL=<hook> makes that hook exit 4 with a reason on stderr; HOOK_STEAL_AT=<hook> has
# another issue (HOOK_STEAL_ISSUE, default 8) take dev on origin while it runs; HOOK_KILL_AT=<hook>
# sends $HOOK_KILL to the take's own shell.
hook_sh="$scratch_root/hook.sh"
cat > "$hook_sh" <<'HOOK'
#!/usr/bin/env bash
name=$1
if [[ -n ${HOOK_LOG:-} ]]; then
    state=unpublished
    if [[ -n ${HOOK_ORIGIN:-} ]] &&
        git -C "$HOOK_ORIGIN" cat-file -e "codeo/intake:.codeo/intake/leases/${CODEO_RESOURCE//:/_}.md" 2>/dev/null; then
        state=published
    fi
    echo "$name #${CODEO_ISSUE:-} ${CODEO_RESOURCE:-} $state override=${CODEO_OVERRIDE:-}" >> "$HOOK_LOG"
fi
if [[ ${HOOK_STEAL_AT:-} == "$name" ]]; then
    t=$(mktemp -d)
    git clone -q -b codeo/intake "$HOOK_ORIGIN" "$t"
    if [[ ! -f $t/.codeo/intake/leases/dev.md ]]; then
        mkdir -p "$t/.codeo/intake/leases"
        printf 'issue:   #%s\nbranch:  feat/other\nby:      other@example.com\nsince:   2026-01-01T00:00:00Z\npurpose: p\n' "${HOOK_STEAL_ISSUE:-8}" > "$t/.codeo/intake/leases/dev.md"
        git -C "$t" add -A
        git -C "$t" commit -q -m steal
        git -C "$t" push -q origin codeo/intake
    fi
    rm -rf "$t"
fi
if [[ ${HOOK_KILL_AT:-} == "$name" ]]; then
    # The signal goes to the take's own shell: the topmost process still running intake.sh.
    pid=$PPID
    while grep -q 'scripts/intake\.sh' "/proc/$(awk '{print $4}' "/proc/$pid/stat")/cmdline" 2>/dev/null; do
        pid=$(awk '{print $4}' "/proc/$pid/stat")
    done
    kill -"$HOOK_KILL" "$pid"
    sleep 0.3
fi
if [[ ${HOOK_FAIL:-} == "$name" ]]; then
    echo "$name: the environment did not answer" >&2
    exit 4
fi
exit 0
HOOK
chmod +x "$hook_sh"

# hooks.onLeaseChange: logs "change #<CODEO_ISSUE> <CODEO_RESOURCE>" to $CHANGE_LOG, prints on
# stdout (which must never reach the caller), and fails under CHANGE_FAILS=1.
change_sh="$scratch_root/change.sh"
cat > "$change_sh" <<'CHANGE'
#!/usr/bin/env bash
echo "change #${CODEO_ISSUE:-} ${CODEO_RESOURCE:-}" >> "$CHANGE_LOG"
echo "this stdout is not the caller's"
if [[ ${CHANGE_FAILS:-0} == 1 ]]; then echo "change: Resource not accessible by integration" >&2; exit 1; fi
exit 0
CHANGE
chmod +x "$change_sh"

export HOOK_LOG="$scratch_root/hook.log" CHANGE_LOG="$scratch_root/change.log"
: > "$HOOK_LOG"
: > "$CHANGE_LOG"

# Configs. $1 for fresh_repo/origin_with is the config.json content.
resources='[{"name":"dev"},{"name":"terraform"},{"name":"postman"},{"name":"slnx"},{"name":"k8s-base"},{"name":"migrations","parameterised":true}]'
config_with() { # <environment JSON or "null"> [onLeaseChange command]
    jq -n --argjson res "$resources" --argjson env "$1" --arg change "${2:-bash '$change_sh'}" '
        {schema: 1, repo: {owner: "o", name: "n"}, baseBranch: "main", resources: $res,
         hooks: {onLeaseChange: $change}}
        + (if $env == null then {} else {environment: $env} end)'
}
env_hooks_json=$(jq -n --arg h "bash '$hook_sh'" \
    '{start: "\($h) start", preflight: "\($h) preflight", activate: "\($h) activate", revoke: "\($h) revoke"}')
default_config=$(config_with "$(jq -n --argjson hooks "$env_hooks_json" '{resource: "dev", hooks: $hooks}')")
no_env_config=$(config_with null)
no_resource_config=$(config_with "$(jq -n --argjson hooks "$env_hooks_json" '{hooks: $hooks}')")

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
assert_matches() {
    local label=$1 pattern=$2 got=$3
    if [[ ! $got =~ $pattern ]]; then
        echo "FAIL: $case_desc — $label: want match for [$pattern] got [$got]"
        failures=$((failures + 1))
    fi
}

# A scratch repo with the config (and the state directory's ignore file) committed on main.
fresh_repo() {
    local dir
    dir=$(mktemp -d "$scratch_root/repo.XXXXXX")
    git -C "$dir" -c init.defaultBranch=main init -q
    # No background maintenance after a push or a commit: it would race a later clone.
    git -C "$dir" config gc.auto 0
    git -C "$dir" config maintenance.auto false
    git -C "$dir" config receive.autogc false
    echo placeholder > "$dir/README.md"
    mkdir -p "$dir/.codeo"
    printf '%s\n' "${1:-$default_config}" > "$dir/.codeo/config.json"
    printf 'active\nintake/\n' > "$dir/.codeo/.gitignore"
    git -C "$dir" add README.md .codeo
    git -C "$dir" commit -q -m init
    printf '%s' "$dir"
}

# An origin whose codeo/intake branch holds one commit, left back on main.
origin_with() {
    local o
    o=$(fresh_repo "${1:-}")
    git -C "$o" checkout -q --orphan codeo/intake
    git -C "$o" rm -rq --cached .
    mkdir -p "$o/.codeo/intake"
    : > "$o/.codeo/intake/.keep"
    git -C "$o" add -f .codeo/intake/.keep
    git -C "$o" commit -q -m intake
    git -C "$o" checkout -q -f main
    printf '%s' "$o"
}

# A clone of the origin, on main.
clone_of() {
    local dir
    dir=$(mktemp -d "$scratch_root/clone.XXXXXX")
    git clone -q "$1" "$dir"
    git -C "$dir" config user.email tester@example.com
    printf '%s' "$dir"
}

# Runs intake.sh in <clone>; sets out, err and status, with both logs reset first.
run_full() {
    local clone=$1
    shift
    status=0
    : > "$HOOK_LOG"
    : > "$CHANGE_LOG"
    err_file=$scratch_root/stderr
    out=$(cd "$clone" && PATH="$stub_bin:$PATH" bash "$intake" "$@" 2>"$err_file") || status=$?
    err=$(cat "$err_file")
}
changes() { grep -c '^change' "$CHANGE_LOG" || true; }
hooks_run() { cut -d' ' -f1 "$HOOK_LOG" | paste -sd' ' -; }

# The lease files origin's intake branch holds.
leases_on() { git -C "$1" ls-tree -r --name-only codeo/intake -- .codeo/intake/leases; }
lease_text() { git -C "$o" show "codeo/intake:.codeo/intake/leases/dev.md" 2>/dev/null || true; }

tab=$'\t'
since='[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z'

# --- list -----------------------------------------------------------------------------------------

o=$(origin_with)
c=$(clone_of "$o")

case_desc="tsv empty"
run_full "$c" lease list --tsv
assert_eq "stdout" "" "$out"

case_desc="human empty"
run_full "$c" lease list
assert_eq "stdout" "intake: no leases" "$out"

run_full "$c" lease take dev 7 "deploy #7"
run_full "$c" lease wait dev 9

case_desc="tsv held then waiting"
run_full "$c" lease list --tsv
assert_eq "line count" 2 "$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
assert_matches "held row" "^held${tab}dev${tab}7${tab}tester@example.com${tab}${since}\$" "$(printf '%s\n' "$out" | sed -n 1p)"
assert_matches "waiting row" "^waiting${tab}dev${tab}9${tab}tester@example.com${tab}${since}\$" "$(printf '%s\n' "$out" | sed -n 2p)"

case_desc="human unchanged"
run_full "$c" lease list
assert_contains "held header" "== dev — held" "$out"
assert_contains "held issue" "issue:   #7" "$out"
assert_contains "waiting header" "== dev-9 — waiting" "$out"
assert_contains "waiting issue" "issue:   #9" "$out"

case_desc="no intake branch"
bare_clone=$(clone_of "$(fresh_repo)")
run_full "$bare_clone" lease list --tsv
assert_eq "stdout" "" "$out"

case_desc="unknown list argument"
run_full "$c" lease list --bogus
assert_eq "exit" 1 "$status"
assert_contains "usage on stderr" "usage: intake.sh lease list [--tsv]" "$err"

case_desc="list --tsv with an extra argument"
run_full "$c" lease list --tsv extra
assert_eq "exit" 1 "$status"
assert_contains "usage on stderr" "usage: intake.sh lease list [--tsv]" "$err"

# --- hooks.onLeaseChange after a lease change -----------------------------------------------------

o=$(origin_with)
c=$(clone_of "$o")
for step in "7:take dev 7 deploy" "9:wait dev 9" "7:release dev 7"; do
    case_desc="onLeaseChange runs once after lease ${step#*:}"
    # shellcheck disable=SC2086
    run_full "$c" lease ${step#*:}
    assert_eq "exit" 0 "$status"
    assert_eq "one change" 1 "$(changes)"
    assert_eq "its environment" "change #${step%%:*} dev" "$(cat "$CHANGE_LOG")"
    assert_not_contains "its stdout is not ours" "not the caller's" "$out"
done

case_desc="release-all runs onLeaseChange exactly once"
run_full "$c" lease take dev 5 deploy
run_full "$c" lease wait dev 5            # holds and waits: two removals, one change
run_full "$c" lease release-all 5
assert_eq "exit" 0 "$status"
assert_eq "one change" 1 "$(changes)"
assert_eq "names the issue" "change #5 " "$(cat "$CHANGE_LOG")"

case_desc="release-all with nothing to remove runs no onLeaseChange"
run_full "$c" lease release-all 5
assert_eq "exit" 0 "$status"
assert_contains "says so" "holds and waits for nothing" "$out"
assert_eq "changes" 0 "$(changes)"

case_desc="a no-op release runs no onLeaseChange"
run_full "$c" lease release dev 7
assert_contains "no-op says so" "not leased" "$out"
assert_eq "changes" 0 "$(changes)"

case_desc="a refused take runs no onLeaseChange"
run_full "$c" lease take dev 7 deploy
run_full "$c" lease take dev 8 other
assert_eq "exit" 1 "$status"
assert_eq "changes" 0 "$(changes)"

# A failing onLeaseChange changes nothing the caller sees.
o=$(origin_with)
c=$(clone_of "$o")
run_full "$c" lease take dev 7 deploy
good_out=$out
o2=$(origin_with)
c2=$(clone_of "$o2")
case_desc="a failing onLeaseChange is not fatal"
export CHANGE_FAILS=1
run_full "$c2" lease take dev 7 deploy
unset CHANGE_FAILS
assert_eq "exit" 0 "$status"
assert_eq "stdout byte-identical" "$good_out" "$out"
assert_eq "one could-not line" 1 "$(printf '%s\n' "$err" | grep -c 'hooks.onLeaseChange failed' || true)"
assert_contains "its reason" "Resource not accessible by integration" "$err"

case_desc="no onLeaseChange configured runs nothing and says nothing"
o=$(origin_with "$(jq 'del(.hooks)' <<<"$default_config")")
c=$(clone_of "$o")
run_full "$c" lease take dev 7 deploy
assert_eq "exit" 0 "$status"
assert_eq "changes" 0 "$(changes)"
assert_not_contains "silent" "onLeaseChange" "$err"

# --- decisions read origin, not an unpushed local row ---------------------------------------------

# Makes origin refuse every push to the intake branch.
refuse_intake() {
    cat > "$1/.git/hooks/pre-receive" <<'HOOK'
#!/bin/sh
while read old new ref; do [ "$ref" = refs/heads/codeo/intake ] && exit 1; done
exit 0
HOOK
    chmod +x "$1/.git/hooks/pre-receive"
}

o=$(origin_with)
c=$(clone_of "$o")
refuse_intake "$o"
case_desc="a refused push is never reported as already waiting"
run_full "$c" lease wait dev 9
assert_eq "exit" 3 "$status"
assert_contains "push failed" "PUSH FAILED" "$err"
assert_contains "refused by the hook" "declined" "$err"
run_full "$c" lease wait dev 9
assert_eq "retry exit" 3 "$status"
assert_eq "no already" 0 "$(grep -c 'already waiting' <<<"$out" || true)"
assert_eq "origin has no lease" "" "$(leases_on "$o")"
assert_eq "changes" 0 "$(changes)"
rm "$o/.git/hooks/pre-receive"
run_full "$c" lease wait dev 9
assert_eq "lands once the hook is gone" 0 "$status"
assert_contains "waiting" "is waiting for dev" "$out"
assert_eq "one change" 1 "$(changes)"

case_desc="an honest already-waiting still short-circuits"
run_full "$c" lease wait dev 9
assert_eq "exit" 0 "$status"
assert_contains "already" "already waiting" "$out"
assert_eq "changes" 0 "$(changes)"

o=$(origin_with)
c=$(clone_of "$o")
refuse_intake "$o"
case_desc="a refused push is never reported as already holds"
run_full "$c" lease take dev 7 deploy
assert_eq "exit" 3 "$status"
assert_contains "push failed" "PUSH FAILED" "$err"
assert_contains "refused by the hook" "declined" "$err"
run_full "$c" lease take dev 7 deploy
assert_eq "retry exit" 3 "$status"
assert_eq "no already" 0 "$(grep -c 'already holds' <<<"$out" || true)"
assert_eq "origin has no lease" "" "$(leases_on "$o")"
assert_eq "changes" 0 "$(changes)"
rm "$o/.git/hooks/pre-receive"
run_full "$c" lease take dev 7 deploy
assert_eq "lands once the hook is gone" 0 "$status"
assert_contains "took" "took dev" "$out"
assert_eq "one change" 1 "$(changes)"
assert_eq "origin has the lease" ".codeo/intake/leases/dev.md" "$(leases_on "$o")"

o=$(fresh_repo)
c=$(clone_of "$o")
case_desc="the first lease ever creates the intake branch"
run_full "$c" lease take dev 7 deploy
assert_eq "exit" 0 "$status"
assert_contains "took" "took dev" "$out"
assert_eq "origin has the lease" ".codeo/intake/leases/dev.md" "$(leases_on "$o")"

case_desc="offline: every lease verb fails naming origin, list warns and answers"
git -C "$c" remote set-url origin "$scratch_root/nowhere"
for verb in "take dev 7 deploy" "take terraform 7 tf" "wait dev 9" "release dev 7" "release-all 7"; do
    # shellcheck disable=SC2086
    run_full "$c" lease $verb
    assert_matches "$verb fails" '^[1-9]' "$status"
    assert_contains "$verb names origin" "origin is unreachable" "$err"
    # take dev dies earlier, fetching the base branch; every other verb reaches tip()'s strict branch.
    [[ $verb == "take dev 7 deploy" ]] ||
        assert_contains "$verb is strict" "no lease decision is made from a stale ref" "$err"
done
run_full "$c" lease list
assert_eq "list exit" 0 "$status"
assert_contains "stale warning" "which may be stale" "$err"
assert_contains "still lists" "== dev — held" "$out"
run_full "$c" lease list --tsv
assert_eq "tsv exit" 0 "$status"
assert_eq "tsv stdout is rows only" "held	dev	7" "$(cut -f1-3 <<<"$out")"
assert_contains "tsv warns on stderr" "which may be stale" "$err"

case_desc="two clones: a release decided offline is refused, and origin keeps the lease"
o=$(origin_with)
c1=$(clone_of "$o")
c2=$(clone_of "$o")
run_full "$c1" lease take dev 7 deploy
run_full "$c1" lease release dev 7
# c2's ref now says dev is free; c1 retakes it, so that ref is stale in the misleading direction.
run_full "$c2" lease list
assert_contains "c2 sees dev free" "no leases" "$out$err"
run_full "$c1" lease take dev 7 deploy
git -C "$c2" remote set-url origin "$scratch_root/nowhere"
run_full "$c2" lease release dev 7
assert_matches "release fails" '^[1-9]' "$status"
assert_contains "release is strict" "no lease decision is made from a stale ref" "$out$err"
assert_eq "never not-leased" 0 "$(grep -c 'not leased' <<<"$out$err" || true)"
run_full "$c2" lease release-all 7
assert_matches "release-all fails" '^[1-9]' "$status"
assert_contains "release-all is strict" "no lease decision is made from a stale ref" "$out$err"
assert_eq "never nothing" 0 "$(grep -c 'holds and waits for nothing' <<<"$out$err" || true)"
assert_contains "origin still holds" ".codeo/intake/leases/dev.md" "$(leases_on "$o")"

case_desc="a reachable origin with no intake branch is not unreachable: the first take still lands"
o=$(fresh_repo)
c=$(clone_of "$o")
run_full "$c" lease take terraform 7 x
assert_eq "exit" 0 "$status"
assert_contains "took" "took terraform" "$out"

o=$(origin_with)
c=$(clone_of "$o")
run_full "$c" lease take dev 7 deploy
refuse_intake "$o"
case_desc="a refused release is never reported as not leased"
run_full "$c" lease release dev 7
assert_eq "exit" 3 "$status"
assert_contains "push failed" "PUSH FAILED" "$err"
run_full "$c" lease release dev 7
assert_eq "retry exit" 3 "$status"
assert_eq "no not-leased" 0 "$(grep -c 'not leased' <<<"$out" || true)"
assert_contains "origin still holds" ".codeo/intake/leases/dev.md" "$(leases_on "$o")"
rm "$o/.git/hooks/pre-receive"
run_full "$c" lease release dev 7
assert_eq "lands" 0 "$status"
assert_contains "released" "released dev" "$out"
assert_eq "origin freed" "" "$(leases_on "$o")"

o=$(origin_with)
c=$(clone_of "$o")
run_full "$c" lease take dev 7 deploy
case_desc="a release by the wrong issue dies naming the holder"
run_full "$c" lease release dev 8
assert_eq "exit" 1 "$status"
assert_contains "names the holder" "leased to #7, not #8" "$err"
assert_eq "changes" 0 "$(changes)"
assert_not_contains "no revoke" "revoke" "$(cat "$HOOK_LOG")"

o=$(origin_with)
c=$(clone_of "$o")
run_full "$c" lease take dev 7 deploy
run_full "$c" lease wait dev 7
refuse_intake "$o"
case_desc="a refused release-all is never reported as done"
for round in first second; do
    run_full "$c" lease release-all 7
    assert_eq "$round exit" 3 "$status"
    assert_eq "$round no done line" 0 "$(grep -c 'holds and waits for nothing' <<<"$out" || true)"
done
assert_contains "origin still holds" ".codeo/intake/leases/dev.md" "$(leases_on "$o")"
assert_contains "origin still waits" ".codeo/intake/leases/waiting/dev-7.md" "$(leases_on "$o")"
rm "$o/.git/hooks/pre-receive"
run_full "$c" lease release-all 7
assert_eq "lands" 0 "$status"
assert_contains "done" "holds and waits for nothing" "$out"
assert_eq "origin freed" "" "$(leases_on "$o")"

o=$(origin_with)
c=$(clone_of "$o")
run_full "$c" lease wait dev 7
assert_eq "wait lands" 0 "$status"
refuse_intake "$o"
case_desc="a refused waiting-row removal in release-all is never reported as done"
for round in first second; do
    run_full "$c" lease release-all 7
    assert_eq "$round exit" 3 "$status"
    assert_contains "$round push failed" "PUSH FAILED" "$err"
    assert_eq "$round no done line" 0 "$(grep -c 'holds and waits for nothing' <<<"$out" || true)"
done
assert_contains "origin still waits" ".codeo/intake/leases/waiting/dev-7.md" "$(leases_on "$o")"
assert_eq "no changes" 0 "$(changes)"
rm "$o/.git/hooks/pre-receive"
run_full "$c" lease release-all 7
assert_eq "lands" 0 "$status"
assert_contains "done" "holds and waits for nothing" "$out"
assert_eq "origin freed" "" "$(leases_on "$o")"
assert_eq "one change" 1 "$(changes)"

# --- a refused lease push leaves nothing behind ---------------------------------------------------

# The lease files this clone's own intake branch holds; nothing when it has no such branch.
local_leases() { git -C "$1" ls-tree -r --name-only refs/heads/codeo/intake -- .codeo/intake/leases 2>/dev/null || true; }

o=$(origin_with)
c=$(clone_of "$o")
refuse_intake "$o"
case_desc="a refused take leaves the local branch where origin is"
run_full "$c" lease take dev 7 deploy
assert_eq "exit" 3 "$status"
assert_contains "says nothing was kept" "none was kept locally" "$err"
assert_eq "local holds no lease" "" "$(local_leases "$c")"
case_desc="refused take, release, then wait: the abandoned take never lands"
run_full "$c" lease release dev 7
assert_eq "release exit" 0 "$status"
assert_contains "not leased" "not leased" "$out"
rm "$o/.git/hooks/pre-receive"
run_full "$c" lease wait dev 9
assert_eq "wait exit" 0 "$status"
assert_eq "origin has only the wait" ".codeo/intake/leases/waiting/dev-9.md" "$(leases_on "$o")"

o=$(origin_with)
c=$(clone_of "$o")
run_full "$c" lease take dev 7 deploy
refuse_intake "$o"
case_desc="refused release-all, take, then wait: the abandoned removal never lands"
run_full "$c" lease release-all 7
assert_eq "release-all exit" 3 "$status"
assert_eq "local still holds" ".codeo/intake/leases/dev.md" "$(local_leases "$c")"
run_full "$c" lease take dev 7 deploy
assert_eq "take exit" 0 "$status"
assert_contains "already holds" "already holds" "$out"
rm "$o/.git/hooks/pre-receive"
run_full "$c" lease wait dev 9
assert_eq "wait exit" 0 "$status"
assert_eq "origin holds and waits" $'.codeo/intake/leases/dev.md\n.codeo/intake/leases/waiting/dev-9.md' "$(leases_on "$o")"

o=$(origin_with)
c=$(clone_of "$o")
refuse_intake "$o"
case_desc="refused take, release-all, then wait: only the wait lands"
run_full "$c" lease take dev 7 deploy
rm "$o/.git/hooks/pre-receive"
run_full "$c" lease release-all 7
assert_eq "release-all exit" 0 "$status"
assert_contains "nothing to release" "holds and waits for nothing" "$out"
run_full "$c" lease wait dev 7
assert_eq "origin has only the wait" ".codeo/intake/leases/waiting/dev-7.md" "$(leases_on "$o")"

o=$(origin_with)
c=$(clone_of "$o")
refuse_intake "$o"
case_desc="refused wait, release-all, then take: only the lease lands"
run_full "$c" lease wait dev 9
rm "$o/.git/hooks/pre-receive"
run_full "$c" lease release-all 9
assert_eq "release-all exit" 0 "$status"
run_full "$c" lease take dev 7 deploy
assert_eq "origin has only the lease" ".codeo/intake/leases/dev.md" "$(leases_on "$o")"

# --- the configured resources ---------------------------------------------------------------------

o=$(origin_with)
c=$(clone_of "$o")
# origin's main moves on; this clone's branch is now one commit behind it.
echo more > "$o/more.txt"
git -C "$o" add more.txt
git -C "$o" commit -q -m "main moves on"

case_desc="a resource other than the environment's needs neither the base branch nor a hook"
run_full "$c" lease take terraform 120 "build.tf"
assert_eq "exit" 0 "$status"
assert_contains "took" "intake: #120 took terraform" "$out"
assert_eq "origin has the lease" ".codeo/intake/leases/terraform.md" "$(leases_on "$o")"
assert_eq "no hook" "" "$(cat "$HOOK_LOG")"
run_full "$c" lease take slnx 120 "x"
assert_eq "slnx exit" 0 "$status"
run_full "$c" lease release terraform 120
assert_eq "release ran no hook" "" "$(cat "$HOOK_LOG")"
run_full "$c" lease release slnx 120
assert_eq "released" "" "$(leases_on "$o")"

case_desc="the environment resource still requires the base branch"
run_full "$c" lease take dev 7 deploy
assert_eq "exit" 1 "$status"
assert_contains "the message" "this branch does not contain origin/main — merge it in first, then take dev" "$err"
assert_eq "no lease" "" "$(leases_on "$o")"
assert_eq "no hook ran" "" "$(cat "$HOOK_LOG")"

o=$(origin_with)
c=$(clone_of "$o")
case_desc="parameterised_resource_accepts_a_suffix"
run_full "$c" lease take migrations:Clips 7 "schema"
assert_eq "take exit" 0 "$status"
assert_contains "took" "took migrations:Clips" "$out"
run_full "$c" lease wait migrations:Clips 9
assert_eq "wait exit" 0 "$status"
assert_eq "origin files" $'.codeo/intake/leases/migrations_Clips.md\n.codeo/intake/leases/waiting/migrations_Clips-9.md' "$(leases_on "$o")"
run_full "$c" lease list --tsv
assert_matches "held row" "^held${tab}migrations:Clips${tab}7${tab}tester@example.com${tab}${since}"$'\n' "$out"$'\n'
assert_matches "waiting row" "waiting${tab}migrations:Clips${tab}9${tab}tester@example.com${tab}${since}" "$out"
run_full "$c" lease list
assert_contains "held header" "== migrations:Clips — held" "$out"
assert_contains "waiting header" "== migrations:Clips-9 — waiting" "$out"
for r in migrations migrations: "migrations:a/b"; do
    run_full "$c" lease take "$r" 7 x
    assert_eq "[$r] is refused" 1 "$status"
    assert_contains "[$r] message" "unknown resource $r; configured:" "$err"
done

case_desc="a second take is refused naming the holder"
run_full "$c" lease take migrations:Clips 8 other
assert_eq "exit" 1 "$status"
assert_contains "holder" "migrations:Clips is leased to #7" "$err"

case_desc="a hyphenated resource lists whole, waiting row included"
run_full "$c" lease wait k8s-base 9
run_full "$c" lease list --tsv
assert_contains "k8s-base kept" "waiting${tab}k8s-base${tab}9" "$out"

case_desc="unknown_resource_lists_the_configured_ones"
for r in postgres terraform:x; do
    for verb in "take $r 7 x" "wait $r 7" "release $r 7" "check $r 7"; do
        # shellcheck disable=SC2086
        run_full "$c" lease $verb
        assert_eq "[$verb] exit" 1 "$status"
        assert_contains "[$verb] message" "unknown resource $r; configured: dev, terraform, postman, slnx, k8s-base, migrations:<name>" "$err"
    done
done
o_none=$(origin_with "$(jq 'del(.resources)' <<<"$no_env_config")")
c_none=$(clone_of "$o_none")
run_full "$c_none" lease take dev 7 x
assert_eq "no resources: exit" 1 "$status"
assert_contains "no resources: message" "unknown resource dev; configured: none" "$err"

case_desc="release-all frees every resource"
run_full "$c" lease take terraform 7 build
run_full "$c" lease take dev 7 deploy
run_full "$c" lease wait terraform 7
run_full "$c" lease release-all 7
assert_eq "exit" 0 "$status"
assert_eq "one change" 1 "$(changes)"
assert_contains "the environment's release revoked" "revoke #7 dev" "$(cat "$HOOK_LOG")"
assert_eq "only the other issue's waits remain" $'.codeo/intake/leases/waiting/k8s-base-9.md\n.codeo/intake/leases/waiting/migrations_Clips-9.md' "$(leases_on "$o")"

# --- the environment hooks ------------------------------------------------------------------------

export HOOK_ORIGIN
fresh_env() { o=$(origin_with "${1:-}"); c=$(clone_of "$o"); HOOK_ORIGIN=$o; }

case_desc="activate_runs_after_preflight_and_before_publish"
fresh_env
run_full "$c" lease take dev 7 deploy
assert_eq "exit" 0 "$status"
assert_eq "order and state" $'start #7 dev unpublished override=\npreflight #7 dev unpublished override=\nactivate #7 dev unpublished override=' "$(cat "$HOOK_LOG")"
assert_contains "took" "intake: #7 took dev" "$out"
assert_eq "published after" ".codeo/intake/leases/dev.md" "$(leases_on "$o")"
assert_eq "one change" 1 "$(changes)"
fresh_env
HOOK_FAIL=preflight run_full "$c" lease take dev 7 deploy
assert_eq "a failed preflight: exit" 1 "$status"
assert_eq "a failed preflight: no activate" "start preflight revoke" "$(hooks_run)"
assert_eq "a failed preflight: nothing published" "" "$(leases_on "$o")"
fresh_env
HOOK_FAIL=start run_full "$c" lease take dev 7 deploy
assert_eq "a failed start: exit" 1 "$status"
assert_eq "a failed start: no preflight" "start revoke" "$(hooks_run)"
assert_contains "a failed start: says which" "the start hook exited 4" "$err"
assert_eq "a failed start: nothing published" "" "$(leases_on "$o")"
fresh_env
HOOK_FAIL=activate run_full "$c" lease take dev 7 deploy
assert_eq "a failed activate: exit" 1 "$status"
assert_eq "a failed activate: revoked" "start preflight activate revoke" "$(hooks_run)"
assert_eq "a failed activate: nothing published" "" "$(leases_on "$o")"

case_desc="preflight_failure_refuses_even_under_override"
fresh_env
HOOK_FAIL=preflight run_full "$c" lease take dev 7 deploy --override "the check is wrong"
assert_eq "exit" 1 "$status"
assert_contains "the hook's reason" "preflight: the environment did not answer" "$err"
assert_contains "the refusal" "dev refused — the preflight hook exited 4" "$err"
assert_contains "the override does not cover it" "--override does not cover a failing hook" "$err"
assert_eq "nothing published" "" "$(leases_on "$o")"
assert_eq "the hook saw the override" "preflight #7 dev unpublished override=the check is wrong" "$(sed -n 2p "$HOOK_LOG")"
assert_eq "changes" 0 "$(changes)"

case_desc="revoke_runs_when_the_take_does_not_end_holding"
fresh_env
HOOK_STEAL_AT=activate run_full "$c" lease take dev 7 deploy
assert_eq "lost to another issue: exit" 1 "$status"
assert_contains "lost to another issue: names the holder" "dev is leased to #8" "$err"
assert_eq "lost to another issue: revoked once" "start preflight activate revoke" "$(hooks_run)"
fresh_env
refuse_intake "$o"
run_full "$c" lease take dev 7 deploy
assert_eq "push refused: exit" 3 "$status"
assert_eq "push refused: revoked" "start preflight activate revoke" "$(hooks_run)"
fresh_env
run_full "$c" lease take dev 7 deploy
assert_eq "granted: exit" 0 "$status"
assert_not_contains "granted: no revoke" "revoke" "$(cat "$HOOK_LOG")"
fresh_env
HOOK_STEAL_AT=activate HOOK_STEAL_ISSUE=7 run_full "$c" lease take dev 7 deploy
assert_eq "lost to the same issue: exit" 0 "$status"
assert_contains "lost to the same issue: reads itself as holder" "#7 already holds dev" "$out"
assert_not_contains "lost to the same issue: no revoke" "revoke" "$(cat "$HOOK_LOG")"
fresh_env
run_full "$c" lease take dev 7 deploy
run_full "$c" lease take dev 8 other
assert_eq "refused before any hook: exit" 1 "$status"
assert_eq "refused before any hook: no hook" "" "$(cat "$HOOK_LOG")"
run_full "$c" lease release dev 7
assert_eq "a release revokes" "revoke #7 dev unpublished override=" "$(cat "$HOOK_LOG")"
HOOK_FAIL=revoke run_full "$c" lease release dev 7
assert_eq "a failing revoke on a no-op release: exit" 0 "$status"
assert_contains "a failing revoke says so" "the revoke hook exited 4" "$err"

# The kill walks /proc to find the take's own shell, so the signal cases run only where it exists.
proc_only() {
    [[ $(uname -s) == Linux && -r /proc/self/stat ]] && return 0
    echo "SKIP: $case_desc — the hook walks /proc, Linux only"
    return 1
}
for sig in TERM:143 INT:130; do
    case_desc="a take interrupted by ${sig%:*} during activate revokes and publishes nothing"
    if proc_only; then
        fresh_env
        HOOK_KILL_AT=activate HOOK_KILL=${sig%:*} run_full "$c" lease take dev 7 deploy
        assert_eq "exit" "${sig#*:}" "$status"
        assert_eq "revoked" "start preflight activate revoke" "$(hooks_run)"
        assert_eq "no lease" "" "$(leases_on "$o")"
    fi
done
case_desc="a holder's re-take interrupted during activate keeps its activation"
if proc_only; then
    fresh_env
    run_full "$c" lease take dev 7 deploy
    HOOK_KILL_AT=activate HOOK_KILL=TERM run_full "$c" lease take dev 7 deploy
    assert_eq "exit" 143 "$status"
    assert_not_contains "no revoke" "revoke" "$(cat "$HOOK_LOG")"
    assert_eq "lease untouched" ".codeo/intake/leases/dev.md" "$(leases_on "$o")"
fi

case_desc="a re-take by the holder runs the hooks, and a failure leaves the lease"
fresh_env
run_full "$c" lease take dev 7 deploy
run_full "$c" lease take dev 7 deploy
assert_eq "exit" 0 "$status"
assert_eq "the hooks ran again" "start preflight activate" "$(hooks_run)"
HOOK_FAIL=preflight run_full "$c" lease take dev 7 deploy
assert_eq "refused: exit" 1 "$status"
assert_contains "unchanged" "#7 still holds dev — the lease is unchanged" "$err"
assert_eq "no revoke" "start preflight" "$(hooks_run)"
assert_eq "lease still on origin" ".codeo/intake/leases/dev.md" "$(leases_on "$o")"

case_desc="no_environment_configured_runs_no_hook"
for cfg in "$no_env_config" "$no_resource_config"; do
    fresh_env "$cfg"
    # Behind the base branch: with no environment there is nothing to check it against.
    echo more > "$o/more.txt"
    git -C "$o" add more.txt
    git -C "$o" commit -q -m "main moves on"
    run_full "$c" lease take dev 7 deploy
    assert_eq "take exit" 0 "$status"
    assert_contains "took" "#7 took dev" "$out"
    assert_eq "take ran no hook" "" "$(cat "$HOOK_LOG")"
    assert_eq "onLeaseChange still runs" 1 "$(changes)"
    run_full "$c" lease release dev 7
    assert_eq "release exit" 0 "$status"
    assert_eq "release ran no hook" "" "$(cat "$HOOK_LOG")"
    run_full "$c" lease take dev 7 deploy --override "x"
    assert_eq "--override is refused" 1 "$status"
    assert_contains "--override says why" "--override applies only to the environment resource" "$err"
done

case_desc="override publishes with an override line"
fresh_env
run_full "$c" lease take dev 7 deploy --override "the image predates the mode"
assert_eq "exit" 0 "$status"
assert_eq "last line" "override: the image predates the mode" "$(lease_text | tail -n 1)"
assert_contains "announced" "intake: #7 took dev WITH OVERRIDE: the image predates the mode" "$out"
assert_eq "one change" 1 "$(changes)"

case_desc="--override needs a reason"
fresh_env
run_full "$c" lease take dev 7 deploy --override
assert_eq "exit" 1 "$status"
assert_eq "no lease" "" "$(leases_on "$o")"

case_desc="a resource other than the environment's rejects --override and runs no hook"
fresh_env
HOOK_FAIL=preflight run_full "$c" lease take terraform 7 deploy
assert_eq "no hook: exit" 0 "$status"
assert_eq "no hook ran" "" "$(cat "$HOOK_LOG")"
run_full "$c" lease take postman 7 deploy --override "x"
assert_eq "override exit" 1 "$status"
assert_contains "says why" "--override applies only to the environment resource (dev): postman has no preflight" "$err"
assert_eq "no postman lease" ".codeo/intake/leases/terraform.md" "$(leases_on "$o")"

case_desc="a holder re-take with the override records it on the lease"
fresh_env
run_full "$c" lease take dev 7 deploy
run_full "$c" lease take dev 7 deploy --override "the image predates the mode"
assert_eq "exit" 0 "$status"
assert_contains "already holds" "intake: #7 already holds dev" "$out"
assert_contains "announced" "WITH OVERRIDE: the image predates the mode" "$out"
assert_eq "last line" "override: the image predates the mode" "$(lease_text | tail -n 1)"
assert_contains "issue kept" "issue:   #7" "$(lease_text)"
assert_contains "purpose kept" "purpose: deploy" "$(lease_text)"
run_full "$c" lease take dev 7 deploy --override "second reason"
assert_eq "one override line" 1 "$(lease_text | grep -c '^override:')"
assert_eq "replaced" "override: second reason" "$(lease_text | tail -n 1)"

case_desc="a holder re-take without the override drops the lease's stale override line"
fresh_env
run_full "$c" lease take dev 7 deploy --override "the image predates the mode"
assert_eq "override recorded" 1 "$(lease_text | grep -c '^override:')"
run_full "$c" lease take dev 7 deploy
assert_eq "exit" 0 "$status"
assert_contains "says so" "intake: the hooks pass without --override — dropped the lease's override line" "$out"
assert_eq "override gone" 0 "$(lease_text | grep -c '^override:')"
assert_contains "issue kept" "issue:   #7" "$(lease_text)"
assert_contains "purpose kept" "purpose: deploy" "$(lease_text)"
tip_before=$(git -C "$o" rev-parse codeo/intake)
run_full "$c" lease take dev 7 deploy
assert_eq "no override line, no republish" "$tip_before" "$(git -C "$o" rev-parse codeo/intake)"
assert_not_contains "nothing dropped" "dropped" "$out"

# --- a take is refused while an earlier wait has right of way -------------------------------------

# Rewrites a waiting row's since: line on origin's intake branch, to age it.
wait_since() {
    local origin=$1 resource=$2 n=$3 iso=$4 t
    t=$(mktemp -d "$scratch_root/ws.XXXXXX")
    git clone -q -b codeo/intake "$origin" "$t"
    sed -i "s/^since:.*/since:   $iso/" "$t/.codeo/intake/leases/waiting/$resource-$n.md"
    git -C "$t" add -A
    if ! git -C "$t" diff --cached --quiet; then
        git -C "$t" commit -q -m "age $resource-$n"
        git -C "$t" push -q origin codeo/intake
    fi
    rm -rf "$t"
}

o=$(origin_with)
c=$(clone_of "$o")
case_desc="a take is refused while an earlier wait has right of way"
run_full "$c" lease take dev 7 deploy
run_full "$c" lease wait dev 9
run_full "$c" lease release dev 7
run_full "$c" lease take dev 5 deploy
assert_eq "exit" 1 "$status"
assert_contains "names the head" "#9's turn" "$err"
assert_contains "says until when" "keeps right of way until" "$err"
assert_eq "origin holds nothing" ".codeo/intake/leases/waiting/dev-9.md" "$(leases_on "$o")"
run_full "$c" lease take dev 9 deploy
assert_eq "the head takes it" 0 "$status"

o=$(origin_with)
c=$(clone_of "$o")
case_desc="a later waiter is refused behind an earlier one"
run_full "$c" lease take dev 7 deploy
run_full "$c" lease wait dev 9
run_full "$c" lease wait dev 5
wait_since "$o" dev 9 "$(date -u -d '1 minute ago' +%Y-%m-%dT%H:%M:%SZ)"
run_full "$c" lease release dev 7
run_full "$c" lease take dev 5 deploy
assert_eq "exit" 1 "$status"
assert_contains "names the head" "#9's turn" "$err"
run_full "$c" lease take dev 9 deploy
assert_eq "the head takes it" 0 "$status"

o=$(origin_with)
c=$(clone_of "$o")
case_desc="a wait recorded with the same instant is ordered by issue number"
run_full "$c" lease wait dev 9
run_full "$c" lease wait dev 5
same=$(date -u +%Y-%m-%dT%H:%M:%SZ)
wait_since "$o" dev 9 "$same"
wait_since "$o" dev 5 "$same"
run_full "$c" lease take dev 9 deploy
assert_eq "exit" 1 "$status"
assert_contains "names the lower number" "#5's turn" "$err"

o=$(origin_with)
c=$(clone_of "$o")
case_desc="a holder's re-take ignores the queue"
run_full "$c" lease take dev 7 deploy
run_full "$c" lease wait dev 9
run_full "$c" lease take dev 7 deploy
assert_eq "exit" 0 "$status"
assert_contains "already holds" "already holds" "$out"

o=$(origin_with)
c=$(clone_of "$o")
case_desc="the queue binds a resource other than the environment's too"
run_full "$c" lease take postman 7 run
run_full "$c" lease wait postman 9
run_full "$c" lease release postman 7
run_full "$c" lease take postman 5 run
assert_eq "exit" 1 "$status"
assert_contains "names the head" "#9's turn" "$err"

# A `date` whose `-u +%s` reads the real now plus <seconds>, so a queue's hours can pass without
# waiting; every other call goes to the real date, so commit times and ISO formatting stay real.
real_date=$(command -v date)
clock_bin="$scratch_root/clock-bin"
clock_saved_path=$PATH
clock_ahead() {
    mkdir -p "$clock_bin"
    cat > "$clock_bin/date" <<STUB
#!/usr/bin/env bash
if [[ "\$*" == "-u +%s" ]]; then echo \$((\$($real_date -u +%s) + $1)); else exec $real_date "\$@"; fi
STUB
    chmod +x "$clock_bin/date"
    PATH="$clock_bin:$clock_saved_path"
}
clock_reset() { PATH=$clock_saved_path; }

# Three issues in the queue: #7 held dev and released it, #9 has waited 2 minutes and #5 1 minute.
queue_of_two() {
    o=$(origin_with)
    c=$(clone_of "$o")
    run_full "$c" lease take dev 7 deploy
    run_full "$c" lease wait dev 9
    run_full "$c" lease wait dev 5
    wait_since "$o" dev 9 "$(date -u -d '2 minutes ago' +%Y-%m-%dT%H:%M:%SZ)"
    wait_since "$o" dev 5 "$(date -u -d '1 minute ago' +%Y-%m-%dT%H:%M:%SZ)"
    run_full "$c" lease release dev 7
}

queue_of_two
case_desc="the second waiter's hour starts when the first's ends"
clock_ahead $((3600 + 60))
run_full "$c" lease take dev 8 deploy
assert_eq "exit" 1 "$status"
assert_contains "names the second waiter" "#5's turn" "$err"
run_full "$c" lease take dev 5 deploy
clock_reset
assert_eq "exit" 0 "$status"
assert_contains "dropped the lapsed first wait" "dropped #9's wait for dev" "$out"

queue_of_two
case_desc="every waiter is served in order before anyone else"
clock_ahead $((2 * 3600 + 60))
run_full "$c" lease take dev 8 deploy
clock_reset
assert_eq "exit" 0 "$status"
assert_contains "dropped the first wait" "dropped #9's wait for dev" "$out"
assert_contains "dropped the second wait" "dropped #5's wait for dev" "$out"
assert_eq "origin holds only the lease" ".codeo/intake/leases/dev.md" "$(leases_on "$o")"

queue_of_two
case_desc="a waiter whose own hour has passed is refused behind the next live waiter"
clock_ahead $((3600 + 60))
run_full "$c" lease take dev 9 deploy
assert_eq "exit" 1 "$status"
assert_contains "names the next waiter" "#5's turn" "$err"
run_full "$c" lease take dev 5 deploy
clock_reset
assert_eq "exit" 0 "$status"
assert_contains "dropped the lapsed wait" "dropped #9's wait for dev" "$out"

# A date that reads 00:30 UTC today for `date -u +%s`: an empty row once parsed as today's midnight
# and looked live for the first hour of the UTC day.
midnight_bin="$scratch_root/midnight-bin"
mkdir -p "$midnight_bin"
cat > "$midnight_bin/date" <<STUB
#!/usr/bin/env bash
if [[ "\$*" == "-u +%s" ]]; then echo \$((\$($real_date -u -d 'today 00:00' +%s) + 1800)); else exec $real_date "\$@"; fi
STUB
chmod +x "$midnight_bin/date"

o=$(origin_with)
c=$(clone_of "$o")
case_desc="a take with no waiters succeeds even just after midnight UTC"
saved_path=$PATH
PATH="$midnight_bin:$PATH"
run_full "$c" lease take postman 5 run
PATH=$saved_path
assert_eq "exit" 0 "$status"
assert_contains "took it" "#5 took postman" "$out"

o=$(origin_with)
c=$(clone_of "$o")
case_desc="a waiting row with a malformed since is ignored"
run_full "$c" lease wait postman 9
wait_since "$o" postman 9 "not-a-date"
run_full "$c" lease take postman 5 run
assert_eq "exit" 0 "$status"

o=$(origin_with)
c=$(clone_of "$o")
case_desc="a wait recorded while the lease was held is not aged by the holder's time"
run_full "$c" lease take dev 7 deploy
run_full "$c" lease wait dev 9
wait_since "$o" dev 9 "2026-01-01T00:00:00Z"
run_full "$c" lease release dev 7
run_full "$c" lease take dev 5 deploy
assert_eq "exit" 1 "$status"
assert_contains "names the head" "#9's turn" "$err"

o=$(origin_with)
c=$(clone_of "$o")
case_desc="a take is allowed once the head's right of way has ended"
run_full "$c" lease take dev 7 deploy
run_full "$c" lease wait dev 9
wait_since "$o" dev 9 "2026-01-01T00:00:00Z"
run_full "$c" lease release dev 7
CODEO_LEASE_GRACE_SECONDS=0 run_full "$c" lease take dev 5 deploy
assert_eq "exit" 0 "$status"
assert_contains "reports the drop" "dropped #9's wait for dev" "$out$err"
assert_eq "origin holds only the lease" ".codeo/intake/leases/dev.md" "$(leases_on "$o")"

case_desc="an expired wait is dropped in the take's own commit"
assert_eq "one commit" "docs(codeo): lease dev for #5" "$(git -C "$o" log -1 --format=%s codeo/intake)"

o=$(origin_with)
c=$(clone_of "$o")
case_desc="a resource never held starts the clock at the wait itself"
run_full "$c" lease wait postman 9
wait_since "$o" postman 9 "2026-01-01T00:00:00Z"
run_full "$c" lease take postman 5 run
assert_eq "exit" 0 "$status"
assert_contains "reports the drop" "dropped #9's wait for postman" "$out$err"
assert_eq "origin holds only the lease" ".codeo/intake/leases/postman.md" "$(leases_on "$o")"

row_since() { git -C "$1" show "codeo/intake:.codeo/intake/leases/waiting/$2.md" | sed -n 's/^since: *//p'; }

o=$(origin_with)
c=$(clone_of "$o")
case_desc="a lapsed wait on a free lease is renewed, not reported as already waiting"
run_full "$c" lease wait dev 9
wait_since "$o" dev 9 "$(date -u -d '2 hours ago' +%Y-%m-%dT%H:%M:%SZ)"
before=$(row_since "$o" dev-9)
clock_ahead $((3600 + 60))
run_full "$c" lease wait dev 9
clock_reset
assert_eq "exit" 0 "$status"
assert_contains "says renewed" "renewed" "$out"
assert_not_contains "not already waiting" "already waiting" "$out"
if [[ $(row_since "$o" dev-9) == "$before" ]]; then
    echo "FAIL: $case_desc — since: still [$before]"
    failures=$((failures + 1))
fi

o=$(origin_with)
c=$(clone_of "$o")
case_desc="a wait on a held lease is never renewed"
run_full "$c" lease take dev 7 deploy
run_full "$c" lease wait dev 9
before=$(row_since "$o" dev-9)
clock_ahead $((3600 + 60))
run_full "$c" lease wait dev 9
clock_reset
assert_eq "exit" 0 "$status"
assert_contains "already waiting" "already waiting" "$out"
assert_eq "since unchanged" "$before" "$(row_since "$o" dev-9)"

o=$(origin_with)
c=$(clone_of "$o")
case_desc="a live wait is still already waiting"
run_full "$c" lease wait dev 9
before=$(row_since "$o" dev-9)
run_full "$c" lease wait dev 9
assert_eq "exit" 0 "$status"
assert_contains "already waiting" "already waiting" "$out"
assert_eq "since unchanged" "$before" "$(row_since "$o" dev-9)"

# --- lease check: exit 0 holds, 1 does not, 2 origin cannot be asked -----------------------------
o=$(origin_with)
c=$(clone_of "$o")
case_desc="check: the holder holds"
run_full "$c" lease take dev 7 deploy
run_full "$c" lease check dev 7
assert_eq "exit" 0 "$status"

case_desc="check: another issue is told who holds"
run_full "$c" lease check dev 8
assert_eq "exit" 1 "$status"
assert_contains "names the holder" "#8 does not hold dev (held by #7)" "$err"

case_desc="check: a released lease is not held"
run_full "$c" lease release dev 7
run_full "$c" lease check dev 7
assert_eq "exit" 1 "$status"
assert_contains "says not held" "#7 does not hold dev (not held)" "$err"

case_desc="check: no argument and no lock is refused"
run_full "$c" lease check dev
assert_eq "exit" 1 "$status"
assert_contains "says so" "no workflow here" "$err"

case_desc="check: no argument reads the issue from .codeo/active"
run_full "$c" lease take dev 7 deploy
printf 'issue:   7\nbranch:  feat/x\n' > "$c/.codeo/active"
run_full "$c" lease check dev
assert_eq "exit" 0 "$status"
rm -f "$c/.codeo/active"

case_desc="check: an unreachable origin is exit 2"
git -C "$c" remote set-url origin "$scratch_root/nowhere"
run_full "$c" lease check dev 7
assert_eq "exit" 2 "$status"
assert_contains "says so" "origin is unreachable" "$err"

# A `git` that fails every fetch and otherwise runs the real one: origin still answers, but the ref
# cannot be refreshed.
real_git=$(command -v git)
fail_fetch_bin="$scratch_root/fail-fetch-bin"
mkdir -p "$fail_fetch_bin"
cat > "$fail_fetch_bin/git" <<STUB
#!/usr/bin/env bash
if [[ "\${1:-}" == fetch ]]; then exit 1; fi
exec $real_git "\$@"
STUB
chmod +x "$fail_fetch_bin/git"

o=$(origin_with)
c=$(clone_of "$o")
case_desc="check: a branch deleted on origin is not held, not the last holder"
run_full "$c" lease take dev 7 deploy
git -C "$o" branch -q -D codeo/intake
run_full "$c" lease check dev 7
assert_eq "exit" 1 "$status"
assert_contains "says not held" "#7 does not hold dev (not held)" "$err"

o=$(origin_with)
c=$(clone_of "$o")
case_desc="check: a fetch that fails while origin answers is exit 2, not the stale ref"
run_full "$c" lease take dev 7 deploy
saved_path=$PATH
PATH="$fail_fetch_bin:$PATH"
run_full "$c" lease check dev 7
PATH=$saved_path
assert_eq "exit" 2 "$status"
assert_contains "says so" "could not refresh" "$err"

case_desc="lease verbs refuse an unusable config in one line"
o=$(origin_with)
c=$(clone_of "$o")
echo '{not json' > "$c/.codeo/config.json"
run_full "$c" lease take dev 7 deploy
assert_eq "exit" 1 "$status"
assert_eq "one line" 1 "$(printf '%s\n' "$err" | wc -l | tr -d ' ')"
assert_contains "names it" "config.json: invalid JSON" "$err"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
