#!/usr/bin/env bash
# Exercises scripts/live.sh against scratch git repos: the signal it publishes as a parentless
# commit under refs/codeo/live/, how it is throttled, replaced, cleared, fetched and listed, and
# that it never fails its caller. Touches no real git config, makes no network call and calls no
# real `gh`: "origin" is a bare scratch repo reached by a local path, and github.sh is a stub that
# logs its `ref put|delete` calls to $scratch/gh.log.
#
#   live.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_src=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

export GIT_AUTHOR_NAME="Live Test" GIT_AUTHOR_EMAIL="live-test@example.com"
export GIT_COMMITTER_NAME="Live Test" GIT_COMMITTER_EMAIL="live-test@example.com"
unset CODEO_MACHINE CODEO_LIVE_REFRESH_SECONDS CODEO_LIVE_TTL_SECONDS CODEO_LIVE_PUSH_TIMEOUT
# Generous, so a push on a loaded machine is never cut short; the cases that need a short bound set
# their own.
export CODEO_LIVE_PUSH_TIMEOUT=60

scratch_root=$(mktemp -d)
cleanup() { rm -rf "$scratch_root"; }
trap cleanup EXIT

export HOME="$scratch_root/home"
mkdir -p "$HOME"
export GIT_CONFIG_NOSYSTEM=1

# The plugin as installed, with github.sh stubbed: `user login` answers alice (or fails when
# STUB_USER_FAIL is set); `ref put|delete` log their arguments and FAIL, unless the case opts in with
# STUB_PUT_OK / STUB_DELETE_OK, so a silent fallback to REST cannot mask a failed push.
plugin="$scratch_root/plugin"
mkdir -p "$plugin"
cp -R "$plugin_src/scripts" "$plugin/scripts"
cp -R "$plugin_src/lib" "$plugin/lib"
export STUB_LOG="$scratch_root/gh.log"
: > "$STUB_LOG"
cat > "$plugin/scripts/github.sh" <<'GHSTUB'
#!/usr/bin/env bash
case "$1 $2" in
    "user login")
        [[ -z ${STUB_USER_FAIL:-} ]] || exit 1
        [[ -z ${STUB_USER_HANG:-} ]] || exec sleep 5
        echo alice ;;
    "ref put")
        echo "ref put $3" >> "$STUB_LOG"
        [[ -n ${STUB_PUT_OK:-} ]] || { echo "github: ref put refused" >&2; exit 1; }
        echo 0123456789abcdef0123456789abcdef01234567 ;;
    "ref delete")
        echo "ref delete $3" >> "$STUB_LOG"
        [[ -n ${STUB_DELETE_OK:-} ]] || { echo "github: ref delete refused" >&2; exit 1; }
        ;;
    *) echo "github.sh stub: unsupported: $*" >&2; exit 1 ;;
esac
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
assert_not_contains() {
    local label=$1 needle=$2 haystack=$3
    if [[ $haystack == *"$needle"* ]]; then
        echo "FAIL: $case_desc — $label: unwanted substring [$needle] in [$haystack]"
        failures=$((failures + 1))
    fi
}

# A bare origin with main and feat/x, and a clone of it on feat/x with a config; sets $origin and
# $clone.
new_world() {
    local seed
    origin=$(mktemp -d "$scratch_root/origin.XXXXXX")
    : > "$STUB_LOG"
    seed=$(mktemp -d "$scratch_root/seed.XXXXXX")
    git init -q --bare -b main "$origin"
    # Every push into this origin makes receive-pack start a detached `git maintenance run --auto`
    # that can race the next git operation. It is the origin's own config that counts: receive-pack
    # drops the caller's GIT_CONFIG_* environment.
    git -C "$origin" config gc.auto 0
    git -C "$origin" config maintenance.auto false
    git -C "$origin" config receive.autogc false
    git -C "$seed" init -q -b main
    git -C "$seed" config gc.auto 0
    echo placeholder > "$seed/README.md"
    git -C "$seed" add README.md
    git -C "$seed" commit -q -m init
    git -C "$seed" branch feat/x
    git -C "$seed" push -q "$origin" main feat/x
    clone=$(clone_of "$origin")
    git -C "$clone" checkout -q feat/x
}

clone_of() {
    local dir
    dir=$(mktemp -d "$scratch_root/clone.XXXXXX")
    git clone -q "$1" "$dir" 2>/dev/null
    git -C "$dir" config gc.auto 0
    mkdir -p "$dir/.codeo"
    printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}\n' > "$dir/.codeo/config.json"
    printf '%s' "$dir"
}

# clone_with_lock <issue> <host> [volume|session]: the lock lock.sh writes, in the current $clone.
clone_with_lock() {
    local issue=$1 host=$2 extra=${3:-}
    {
        printf 'issue:   %s\nbranch:  feat/x\nstarted: 2026-11-15\nhost:    %s\n' "$issue" "$host"
        case $host in
            container) printf 'volume:  %s\n' "$extra" ;;
            web) printf 'session: %s\n' "$extra" ;;
        esac
    } > "$clone/.codeo/active"
}

# Every invocation gets its own commit dates (a counter file, so it survives the $(...) subshells), so two
# beats never write byte-identical commits whatever the wall clock does; the wall clock is not monotonic
# on every host.
live() {
    local where=$1 n
    shift
    n=$(( $(cat "$scratch_root/seq" 2> /dev/null || echo 0) + 1 ))
    echo "$n" > "$scratch_root/seq"
    (cd "$where" && GIT_AUTHOR_DATE="@$((1700000000 + n)) +0000" GIT_COMMITTER_DATE="@$((1700000000 + n)) +0000" bash "$plugin/scripts/live.sh" "$@")
}

# Run live in $clone with stdout in $out, stderr in $err, status in $rc.
out= err= rc=0
run() {
    live "$clone" "$@" > "$scratch_root/out" 2> "$scratch_root/err" && rc=0 || rc=$?
    out=$(cat "$scratch_root/out")
    err=$(cat "$scratch_root/err")
}

# The last run published by git push alone: nothing on stderr, no REST fallback logged.
assert_pushed_quietly() {
    assert_eq "$1: stderr" "" "$err"
    assert_eq "$1: no REST call" "" "$(cat "$STUB_LOG")"
}

refs() { git -C "$origin" for-each-ref --format='%(refname)' refs/codeo/live/; }
ref_sha() { git -C "$origin" rev-parse -q --verify "$1" 2>/dev/null || true; }

# A signal planted straight in origin: plant <ref> <message>.
plant() {
    local tree
    tree=$(git -C "$origin" hash-object -t tree -w /dev/null)
    git -C "$origin" update-ref "$1" "$(git -C "$origin" commit-tree "$tree" -m "$2")"
}
signal() { # signal <issue> <user> <machine> <host> <beat>
    printf 'codeo live signal\n\nissue: %s\nuser: %s\nmachine: %s\nhost: %s\nbeat: %s' "$1" "$2" "$3" "$4" "$5"
}

# --- publish -----------------------------------------------------------------------------------

case_desc=beat_publishes_one_parentless_commit_naming_issue_user_machine
new_world; clone_with_lock 104 container codeo-104
run beat --force
ref=refs/codeo/live/104/codeo-104
msg=$(git -C "$origin" log -1 --format=%B "$ref" 2>/dev/null || true)
assert_eq "exit" 0 "$rc"
assert_pushed_quietly publish
assert_contains "issue" "issue: 104" "$msg"
assert_contains "user" "user: alice" "$msg"
assert_contains "machine" "machine: codeo-104" "$msg"
assert_contains "host" "host: container" "$msg"
beat=$(sed -n 's/^beat: //p' <<< "$msg")
delta=$(( $(date +%s) - ${beat:-0} ))
assert_eq "beat within 5s" 1 "$(( delta >= -1 && delta <= 5 ? 1 : 0 ))"
parents=$(git -C "$origin" rev-list --parents -1 "$ref" 2>/dev/null || true)
assert_eq "parentless" 1 "$(wc -w <<< "$parents" | tr -d ' ')"
assert_eq "author email" codeo-live@invalid "$(git -C "$origin" log -1 --format=%ae "$ref" 2>/dev/null || true)"

case_desc=beat_adds_nothing_to_the_branch_or_the_pull_request
new_world; clone_with_lock 104 container codeo-104
heads_before=$(git -C "$origin" for-each-ref refs/heads)
head_before=$(git -C "$clone" rev-parse HEAD)
status_before=$(git -C "$clone" status --porcelain)
run beat --force
assert_eq "heads" "$heads_before" "$(git -C "$origin" for-each-ref refs/heads)"
assert_eq "HEAD" "$head_before" "$(git -C "$clone" rev-parse HEAD)"
assert_eq "status" "$status_before" "$(git -C "$clone" status --porcelain)"
assert_eq "commits off every branch" 1 "$(git -C "$origin" rev-list --all --not --branches | wc -l | tr -d ' ')"

case_desc=beat_is_throttled_and_force_is_not
new_world; clone_with_lock 104 container codeo-104
run beat
first=$(ref_sha refs/codeo/live/104/codeo-104)
assert_eq "first beat published" 1 "$([[ -n $first ]] && echo 1 || echo 0)"
assert_pushed_quietly first
run beat
assert_eq "second beat throttled" "$first" "$(ref_sha refs/codeo/live/104/codeo-104)"
assert_pushed_quietly second
run beat --force
second=$(ref_sha refs/codeo/live/104/codeo-104)
assert_eq "force republishes" 1 "$([[ $second != "$first" ]] && echo 1 || echo 0)"
assert_pushed_quietly force
CODEO_LIVE_REFRESH_SECONDS=-100 run beat # negative: a small clock step back must not throttle
third=$(ref_sha refs/codeo/live/104/codeo-104)
assert_eq "a non-positive refresh interval never throttles" 1 \
    "$([[ $third != "$second" ]] && echo 1 || echo 0)"
assert_pushed_quietly nonpositive

case_desc=beat_replaces_the_signal_it_does_not_accumulate
new_world; clone_with_lock 104 container codeo-104
run beat --force; assert_pushed_quietly one
run beat --force; assert_pushed_quietly two
run beat --force; assert_pushed_quietly three
assert_eq "history length" 1 "$(git -C "$origin" rev-list --count refs/codeo/live/104/codeo-104 2>/dev/null || true)"

case_desc=beat_without_a_lock_or_on_the_base_branch_does_nothing
new_world
run beat --force
assert_eq "no lock: exit" 0 "$rc"
assert_eq "no lock: refs" "" "$(refs)"
assert_eq "no lock: stderr" "" "$err"
assert_eq "no lock: stamp" no "$([[ -e $(git -C "$clone" rev-parse --git-path codeo-live-beat) ]] && echo yes || echo no)"
clone_with_lock 104 local
git -C "$clone" checkout -q main
run beat --force
assert_eq "base: exit" 0 "$rc"
assert_eq "base: refs" "" "$(refs)"
assert_eq "base: stderr" "" "$err"
assert_eq "base: stamp" no "$([[ -e $(git -C "$clone" rev-parse --git-path codeo-live-beat) ]] && echo yes || echo no)"

case_desc=beat_publishes_nothing_for_a_lock_issue_list_would_drop
for bad_issue in 0 0104 1234567890; do
    new_world; clone_with_lock "$bad_issue" container codeo-x
    run beat --force
    assert_eq "$bad_issue: exit" 0 "$rc"
    assert_eq "$bad_issue: refs" "" "$(refs)"
    assert_eq "$bad_issue: stderr" "" "$err"
done

# --- identity ----------------------------------------------------------------------------------

case_desc=machine_by_host
new_world; clone_with_lock 104 container codeo-104
CODEO_MACHINE=laptop run beat --force
assert_eq "CODEO_MACHINE wins" refs/codeo/live/104/laptop "$(refs)"
new_world; clone_with_lock 104 web abcdef0123456789
run beat --force
assert_eq "web" refs/codeo/live/104/web-abcdef01 "$(refs)"
host_label=$(hostname | sed 's/[^A-Za-z0-9._-]/-/g')
new_world; clone_with_lock 104 local
run beat --force
assert_eq "local" "refs/codeo/live/104/$host_label" "$(refs)"
new_world; clone_with_lock 104 container unknown
run beat --force
assert_eq "container, volume unknown" "refs/codeo/live/104/$host_label" "$(refs)"

case_desc=user_falls_back_to_git_user_name_and_never_an_email
new_world; clone_with_lock 104 container codeo-104
git -C "$clone" config user.name "Bob Builder"
STUB_USER_FAIL=1 run beat --force
msg=$(git -C "$origin" log -1 --format=%B refs/codeo/live/104/codeo-104 2>/dev/null || true)
assert_contains "user.name" "user: Bob Builder" "$msg"
assert_not_contains "no @" "@" "$msg"
new_world; clone_with_lock 104 container codeo-104
(cd "$clone" && GIT_CONFIG_GLOBAL=/dev/null git config --unset user.name) 2>/dev/null || true
STUB_USER_FAIL=1 GIT_CONFIG_GLOBAL=/dev/null run beat --force
msg=$(git -C "$origin" log -1 --format=%B refs/codeo/live/104/codeo-104 2>/dev/null || true)
assert_contains "unknown" "user: unknown" "$msg"
assert_not_contains "no @" "@" "$msg"

case_desc=fields_are_cut_and_the_machine_stays_in_its_namespace
new_world; clone_with_lock 104 container codeo-104
git -C "$clone" config user.name "$(printf 'Al\nmachine: evil/../x%0200d' 0)"
STUB_USER_FAIL=1 run beat --force
msg=$(git -C "$origin" log -1 --format=%B refs/codeo/live/104/codeo-104 2>/dev/null || true)
user_lines=$(grep -c '^user:' <<< "$msg" || true)
user_value=$(sed -n 's/^user: //p' <<< "$msg")
assert_eq "one user line" 1 "$user_lines"
assert_eq "user at most 64 chars" 1 "$(( ${#user_value} <= 64 && ${#user_value} > 0 ? 1 : 0 ))"
assert_eq "user printable" "" "$(tr -d '[:print:]' <<< "$user_value")"
assert_eq "one machine line" 1 "$(grep -c '^machine:' <<< "$msg" || true)"
new_world; clone_with_lock 104 container codeo-104
CODEO_MACHINE='a/b/../c' run beat --force
# git refuses ".." in a ref name, so the label is collapsed (and each dot run replaced) to a name it accepts.
assert_eq "machine slashes" refs/codeo/live/104/a-b---c "$(refs)"

case_desc=machine_label_never_forms_an_unsafe_ref_name
for label in .. .hidden x.lock; do
    new_world; clone_with_lock 104 container codeo-104
    CODEO_MACHINE=$label run beat --force
    assert_eq "label $label: exit" 0 "$rc"
    assert_eq "label $label: stderr" "" "$err"
    published=$(refs)
    assert_eq "label $label: one ref" 1 "$(grep -c . <<< "$published" || true)"
    assert_eq "label $label: valid ref" 0 "$(git check-ref-format "$published" >/dev/null 2>&1; echo $?)"
done

case_desc=machine_label_with_a_dot_at_the_64th_character_is_a_valid_ref
new_world; clone_with_lock 104 container codeo-104
long=$(printf 'a%.0s' $(seq 1 63))
CODEO_MACHINE="$long.x" run beat --force
assert_eq "exit" 0 "$rc"
assert_eq "stderr" "" "$err"
published=$(refs)
assert_eq "one ref" 1 "$(grep -c . <<< "$published" || true)"
assert_eq "valid ref" 0 "$(git check-ref-format "$published" >/dev/null 2>&1; echo $?)"

# --- failure handling --------------------------------------------------------------------------

case_desc=beat_falls_back_to_rest_when_the_push_is_refused
new_world; clone_with_lock 104 container codeo-104
printf '#!/bin/sh\nwhile read old new ref; do case "$ref" in refs/codeo/*) echo refused >&2; exit 1;; esac; done\n' > "$origin/hooks/pre-receive"
chmod +x "$origin/hooks/pre-receive"
: > "$STUB_LOG"
STUB_PUT_OK=1 run beat --force
assert_eq "exit" 0 "$rc"
assert_contains "REST put" "ref put refs/codeo/live/104/codeo-104" "$(cat "$STUB_LOG")"
assert_eq "stderr" "" "$err"
: > "$STUB_LOG"
run beat --force
assert_eq "exit when both fail" 0 "$rc"
assert_eq "one stderr line" 1 "$(grep -c . <<< "$err" || true)"
assert_eq "line prefix" "live: could not publish" "${err:0:23}"

case_desc=beat_with_an_unreachable_origin_exits_0_once
new_world; clone_with_lock 104 container codeo-104
git -C "$clone" remote set-url origin /nonexistent
start=$(date +%s)
CODEO_LIVE_PUSH_TIMEOUT=2 run beat --force
elapsed=$(( $(date +%s) - start ))
assert_eq "exit" 0 "$rc"
assert_eq "one stderr line" 1 "$(grep -c . <<< "$err" || true)"
assert_eq "within timeout + 1s" 1 "$(( elapsed <= 3 ? 1 : 0 ))"

case_desc=beat_does_not_stall_on_a_hung_login_lookup
new_world; clone_with_lock 104 container codeo-104
git -C "$clone" config user.name "Bob Builder"
start=$(date +%s)
STUB_USER_HANG=1 CODEO_LIVE_PUSH_TIMEOUT=1 run beat --force
elapsed=$(( $(date +%s) - start ))
assert_eq "exit" 0 "$rc"
assert_eq "within 3s" 1 "$(( elapsed <= 3 ? 1 : 0 ))"
assert_contains "published with the fallback user" "user: Bob Builder" "$(git -C "$origin" log -1 --format=%B refs/codeo/live/104/codeo-104 2>/dev/null || true)"

case_desc=beat_and_clear_skip_the_pre_push_hook
new_world; clone_with_lock 104 container codeo-104
printf '#!/bin/sh\ntouch "%s/pre-push-ran"\nexit 1\n' "$scratch_root" > "$clone/.git/hooks/pre-push"
chmod +x "$clone/.git/hooks/pre-push"
rm -f "$scratch_root/pre-push-ran"
: > "$STUB_LOG"
run beat --force
assert_eq "ref published by push" 1 "$([[ -n $(ref_sha refs/codeo/live/104/codeo-104) ]] && echo 1 || echo 0)"
assert_eq "no REST fallback" "" "$(cat "$STUB_LOG")"
run clear
assert_eq "ref cleared by push" "" "$(refs)"
assert_eq "hook never ran" no "$([[ -e $scratch_root/pre-push-ran ]] && echo yes || echo no)"

# --- clear -------------------------------------------------------------------------------------

case_desc=clear_deletes_the_ref_and_the_stamp
new_world; clone_with_lock 104 container codeo-104
run beat --force
stamp=$(git -C "$clone" rev-parse --git-path codeo-live-beat)
assert_eq "stamp written" yes "$([[ -e $clone/$stamp || -e $stamp ]] && echo yes || echo no)"
run clear
assert_eq "exit" 0 "$rc"
assert_eq "ref gone" "" "$(refs)"
assert_eq "stamp gone" no "$([[ -e $clone/$stamp || -e $stamp ]] && echo yes || echo no)"

case_desc=clear_of_a_missing_ref_exits_0
new_world; clone_with_lock 104 container codeo-104
STUB_DELETE_OK=1 run clear
assert_eq "exit" 0 "$rc"
assert_eq "silent" "" "$err"
printf '#!/bin/sh\nwhile read old new ref; do case "$ref" in refs/codeo/*) exit 1;; esac; done\n' > "$origin/hooks/pre-receive"
chmod +x "$origin/hooks/pre-receive"
run clear
assert_eq "exit when the fallback fails too" 0 "$rc"
assert_eq "one stderr line" 1 "$(grep -c . <<< "$err" || true)"

# --- fetch and list ----------------------------------------------------------------------------

case_desc=fetch_then_list_shows_a_live_session_from_another_clone
new_world; clone_with_lock 104 container codeo-104
run beat --force
other=$(clone_of "$origin")
live "$other" fetch
tsv=$(live "$other" list --tsv)
assert_contains "row" "$(printf '104\talice\tcodeo-104\tcontainer\t')" "$tsv"
age=${tsv##*$'\t'}
assert_eq "age <= 5" 1 "$(( age >= 0 && age <= 5 ? 1 : 0 ))"
assert_contains "human" "#104  alice on codeo-104 (container), " "$(live "$other" list)"

case_desc=list_hides_an_expired_signal_and_shows_it_again_inside_the_ttl
new_world
other=$(clone_of "$origin")
now=$(date +%s)
plant refs/codeo/live/1/old "$(signal 1 alice old container $((now - 1000)))"
plant refs/codeo/live/2/young "$(signal 2 alice young container $((now - 800)))"
live "$other" fetch
tsv=$(live "$other" list --tsv)
assert_not_contains "1000 s hidden" "1"$'\t'alice "$tsv"
assert_contains "800 s shown" "2"$'\t'alice$'\t'young "$tsv"
plant refs/codeo/live/3/short "$(signal 3 alice short container $((now - 70)))"
plant refs/codeo/live/4/fresh "$(signal 4 alice fresh container $((now - 50)))"
live "$other" fetch
tsv=$(CODEO_LIVE_TTL_SECONDS=60 live "$other" list --tsv)
assert_not_contains "ttl 60 hides 70 s" "3"$'\t'alice "$tsv"
assert_contains "ttl 60 shows 50 s" "4"$'\t'alice$'\t'fresh "$tsv"

case_desc=list_treats_a_future_beat_as_age_0
new_world
other=$(clone_of "$origin")
plant refs/codeo/live/5/ahead "$(signal 5 alice ahead local $(( $(date +%s) + 120 )))"
live "$other" fetch
assert_eq "age" "$(printf '5\talice\tahead\tlocal\t0')" "$(live "$other" list --tsv)"

case_desc=list_skips_a_beat_further_ahead_than_the_ttl
new_world
other=$(clone_of "$origin")
now=$(date +%s)
plant refs/codeo/live/5/far "$(signal 5 alice far local $((now + 1000)))"
plant refs/codeo/live/6/near "$(signal 6 alice near local $((now + 120)))"
live "$other" fetch
assert_eq "only the near one, age 0" "$(printf '6\talice\tnear\tlocal\t0')" "$(live "$other" list --tsv)"
plant refs/codeo/live/7/over "$(signal 7 alice over local $((now + 70)))"
plant refs/codeo/live/8/under "$(signal 8 alice under local $((now + 50)))"
live "$other" fetch
tsv=$(CODEO_LIVE_TTL_SECONDS=60 live "$other" list --tsv)
assert_not_contains "ttl 60 hides +70 s" "7"$'\t'alice "$tsv"
assert_contains "ttl 60 shows +50 s" "8"$'\t'alice$'\t'under "$tsv"

case_desc=list_cleans_hostile_fields_and_skips_unknown_hosts
new_world
other=$(clone_of "$origin")
now=$(date +%s)
plant refs/codeo/live/8/tabby "$(signal 8 "$(printf 'ev\til\033[31m@x')" "$(printf 'm\tach')" local "$now")"
plant refs/codeo/live/9/evil "$(signal 9 alice evil evil "$now")"
plant refs/codeo/live/10/bad "$(signal 12x alice bad local "$now")"
plant refs/codeo/live/11/good "$(signal 11 alice good web "$now")"
live "$other" fetch
tsv=$(live "$other" list --tsv)
assert_eq "two signals survive" 1 "$(( $(grep -c . <<< "$tsv") == 2 ? 1 : 0 ))"
assert_eq "every line has 5 columns" "" "$(awk -F'\t' 'NF != 5' <<< "$tsv")"
assert_eq "no ESC byte" 0 "$(printf '%s' "$tsv" | grep -c $'\033' || true)"
assert_not_contains "evil host omitted" "evil"$'\t'evil "$tsv"
assert_not_contains "bad issue omitted" "12x" "$tsv"
assert_contains "hostile signal kept, cleaned" "8"$'\t'"ev il [31m-x"$'\t'"m ach"$'\t'local "$tsv"
assert_contains "good signal kept" "11"$'\t'alice$'\t'good$'\t'web "$tsv"

case_desc=list_skips_a_malformed_signal
new_world
other=$(clone_of "$origin")
plant refs/codeo/live/6/nobeat "$(printf 'codeo live signal\n\nissue: 6\nuser: alice\nmachine: nobeat\nhost: local')"
plant refs/codeo/live/7/soon "$(signal 7 alice soon local soon)"
live "$other" fetch
assert_eq "nothing listed" "" "$(live "$other" list --tsv)"
live "$other" list > /dev/null
assert_eq "human exit" 0 "$?"

case_desc=list_skips_zero_padded_beat_and_issue_and_keeps_the_rest
new_world
other=$(clone_of "$origin")
now=$(date +%s)
plant refs/codeo/live/1/first "$(signal 1 alice first local "$now")"
plant refs/codeo/live/2/badbeat "$(signal 2 alice badbeat local "0$now")"
plant refs/codeo/live/2/badissue "$(signal 0104 alice badissue local "$now")"
plant refs/codeo/live/3/last "$(signal 3 alice last local "$now")"
live "$other" fetch
rc=0
tsv=$(live "$other" list --tsv) || rc=$?
assert_eq "list exit" 0 "$rc"
assert_eq "only issues 1 and 3" "$(printf '1\talice\tfirst\tlocal\n3\talice\tlast\tlocal')" "$(cut -f1-4 <<< "$tsv")"
assert_eq "ages are small" "" "$(cut -f5 <<< "$tsv" | grep -vE '^[0-5]$' || true)"

case_desc=concurrent_forced_beats_do_not_share_a_message_file
new_world; clone_with_lock 104 container codeo-104
for round in 1 2 3 4 5 6 7 8 9 10; do
    CODEO_MACHINE=m1 live "$clone" beat --force 2> "$scratch_root/err1" > /dev/null & pid1=$!
    CODEO_MACHINE=m2 live "$clone" beat --force 2> "$scratch_root/err2" > /dev/null & pid2=$!
    rc1=0 rc2=0
    wait "$pid1" || rc1=$?
    wait "$pid2" || rc2=$?
    assert_eq "round $round exits" "0 0" "$rc1 $rc2"
    assert_eq "round $round stderr" "" "$(cat "$scratch_root/err1" "$scratch_root/err2")"
done
assert_eq "both refs exist" 2 "$(refs | grep -c .)"
assert_eq "no message file left" "" "$(ls "$clone/.git" | grep '^codeo-live-message' || true)"

case_desc=fetch_prunes_a_cleared_signal
new_world; clone_with_lock 104 container codeo-104
run beat --force
other=$(clone_of "$origin")
live "$other" fetch
assert_contains "visible before" "104" "$(live "$other" list --tsv)"
run clear
live "$other" fetch
assert_eq "empty after" "" "$(live "$other" list --tsv)"

if ((failures)); then
    echo "$failures assertion(s) failed"
    exit 1
fi
echo "all cases passed"
