#!/usr/bin/env bash
# Exercises .devcontainer/codeo-track.sh against a stateful stub `gh` (answers only `gh api`, no
# jq, no network): comments live as files in a scratch dir, POST/PATCH rewrite them, every call is
# logged. Never touches the real gh.
#
#   track.test.sh
#       Exits non-zero naming the first failing case; prints "all cases passed" otherwise.
set -uo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$root/.devcontainer/codeo-track.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
stub_bin=$work/bin
state=$work/state
mkdir -p "$stub_bin"

# State layout: $state/list_<N> (comment ids carrying the marker, as the --jq would print them),
# $state/body_<id>, $state/calls (log), $state/fail (any call fails), $state/failread (GETs fail).
cat > "$stub_bin/gh" <<'STUB'
#!/usr/bin/env bash
[[ ${1:-} == api ]] || { echo "gh-stub: only api" >&2; exit 1; }
shift
method= path= bodyfile=
while [[ $# -gt 0 ]]; do
    case $1 in
        -X) method=$2; shift 2 ;;
        -F) case $2 in body=@*) bodyfile=${2#body=@} ;; esac; shift 2 ;;
        --jq|--paginate) [[ $1 == --jq ]] && shift; shift ;;
        -*) shift ;;
        *) path=$1; shift ;;
    esac
done
[[ -n $method ]] || { [[ -n $bodyfile ]] && method=POST || method=GET; }
echo "$method $path" >> "$GH_STATE/calls"
[[ -f $GH_STATE/fail ]] && exit 1
case $method in
    GET)
        [[ -f $GH_STATE/failread ]] && exit 1
        case $path in
            repos/acme/widgets/issues/*/comments)
                n=${path#repos/acme/widgets/issues/}; n=${n%/comments}
                [[ -f $GH_STATE/list_$n ]] && cat "$GH_STATE/list_$n"; exit 0 ;;
            repos/acme/widgets/issues/comments/*)
                cat "$GH_STATE/body_${path##*/}" 2>/dev/null || exit 1; exit 0 ;;
        esac
        case $path in repos/*/issues/*/comments) exit 0 ;; esac
        exit 1 ;;
    POST)
        n=${path#repos/acme/widgets/issues/}; n=${n%/comments}
        echo 99 > "$GH_STATE/list_$n"; cp "$bodyfile" "$GH_STATE/body_99"; cp "$bodyfile" "$GH_STATE/posted"; exit 0 ;;
    PATCH)
        cp "$bodyfile" "$GH_STATE/body_${path##*/}"; exit 0 ;;
esac
exit 1
STUB
chmod +x "$stub_bin/gh"
export GH_STATE=$state
export CODEO_REPO_URL=https://github.com/acme/widgets.git
export CODEO_TRACK_HOST=box1 CODEO_TRACK_NOW=2026-11-22T10:00:00Z
unset CODEO_TRACK_TTY

failures=0
case_desc=
fail() { echo "FAIL: $case_desc - $*"; failures=$((failures + 1)); }
assert_eq() { [[ $2 == "$3" ]] || fail "$1: want [$2] got [$3]"; }
assert_has() { [[ $3 == *"$2"* ]] || fail "$1: want [$2] in [$3]"; }
assert_not() { [[ $3 != *"$2"* ]] || fail "$1: did not want [$2] in [$3]"; }
calls() { cat "$state/calls" 2>/dev/null; }
body() { cat "$state/body_${1:-99}" 2>/dev/null; }
reset() { rm -rf "$state"; mkdir -p "$state"; : > "$state/calls"; }
# run <args...>: sets out (stdout+stderr) and rc, with the stub gh first on PATH.
run() { out=$(PATH="$stub_bin:$PATH" bash "$script" "$@" 2>&1 < /dev/null); rc=$?; }
run_in() { local input=$1; shift; out=$(printf '%s' "$input" | PATH="$stub_bin:$PATH" CODEO_TRACK_TTY=1 bash "$script" "$@" 2>&1); rc=$?; }

hdr='| Kind | Name | Host | Status | Created (UTC) | Removed (UTC) |'
fixture() { # fixture <id> <rows...>: a tracking comment 77-style with a hand-written line
    local id=$1; shift
    echo "$id" > "$state/list_152"
    { printf '<!-- codeo:tracking -->\nMy own note above the table.\n\n%s\n|---|---|---|---|---|---|\n' "$hdr"
      for r in "$@"; do printf '%s\n' "$r"; done
      printf '\nfooter kept\n'; } > "$state/body_$id"
}

case_desc=add_creates_once
reset
run add 152 container codeo-152
assert_eq rc 0 "$rc"; assert_eq out "" "$out"
assert_eq calls "GET repos/acme/widgets/issues/152/comments
POST repos/acme/widgets/issues/152/comments" "$(calls)"
posted=$(cat "$state/posted")
assert_eq first-line '<!-- codeo:tracking -->' "$(head -n1 "$state/posted")"
assert_has header "$hdr" "$posted"
assert_has row '| container | `codeo-152` | box1 | active | 2026-11-22T10:00:00Z | |' "$posted"
: > "$state/calls"
run add 152 container codeo-152
assert_eq rc2 0 "$rc"
assert_not post "POST" "$(calls)"; assert_not patch "PATCH" "$(calls)"

case_desc=add_edits_existing
reset; fixture 77 '| image | `x` | box1 | active | 2026-11-01T00:00:00Z | |'
run add 152 container codeo-152
assert_eq rc 0 "$rc"
assert_has patch "PATCH repos/acme/widgets/issues/comments/77" "$(calls)"
assert_not post "POST" "$(calls)"
b=$(body 77)
assert_has note "My own note above the table." "$b"
assert_has footer "footer kept" "$b"
assert_has old '| image | `x` | box1 | active | 2026-11-01T00:00:00Z | |' "$b"
assert_has new '| container | `codeo-152` | box1 | active | 2026-11-22T10:00:00Z | |' "$b"

case_desc=host_and_times
reset
run add 152 container codeo-152; run add 152 branch feat/x
b=$(body 99)
assert_has row '| container | `codeo-152` | box1 | active | 2026-11-22T10:00:00Z | |' "$b"
assert_has branch '| branch | `feat/x` | | active | 2026-11-22T10:00:00Z | |' "$b"

case_desc=mark_removed
reset
fixture 77 '| container | `c1` | box1 | active | 2026-11-01T00:00:00Z | |' \
    '| image | `i1` | box1 | active | 2026-11-01T00:00:00Z | |' \
    '| volume | `v1` | box1 | active | 2026-11-01T00:00:00Z | |' \
    '| container | `c1` | box2 | active | 2026-11-01T00:00:00Z | |' \
    '| branch | `b1` | | active | 2026-11-01T00:00:00Z | |'
export CODEO_TRACK_NOW=2026-11-22T11:00:00Z
for k in "container c1" "image i1" "volume v1"; do run mark 152 $k removed; assert_eq "rc $k" 0 "$rc"; done
run mark 152 branch b1 deleted; assert_eq rc-branch 0 "$rc"
run mark 152 container nothere removed; assert_eq rc-none 0 "$rc"
b=$(body 77)
assert_has c1 '| container | `c1` | box1 | removed | 2026-11-01T00:00:00Z | 2026-11-22T11:00:00Z |' "$b"
assert_has i1 '| image | `i1` | box1 | removed | 2026-11-01T00:00:00Z | 2026-11-22T11:00:00Z |' "$b"
assert_has v1 '| volume | `v1` | box1 | removed | 2026-11-01T00:00:00Z | 2026-11-22T11:00:00Z |' "$b"
assert_has other-host '| container | `c1` | box2 | active | 2026-11-01T00:00:00Z | |' "$b"
assert_has branch '| branch | `b1` | | deleted | 2026-11-01T00:00:00Z | 2026-11-22T11:00:00Z |' "$b"
run mark 152 container nothere removed
: > "$state/calls"; run mark 152 container c1 removed
assert_not patch-noop "PATCH" "$(calls)"
run mark 152 container c1 deleted; assert_eq rc-deleted-usage 2 "$rc"
run add 152 container c1
assert_has history '| container | `c1` | box1 | removed |' "$(body 77)"
assert_has again '| container | `c1` | box1 | active | 2026-11-22T11:00:00Z | |' "$(body 77)"
export CODEO_TRACK_NOW=2026-11-22T10:00:00Z

case_desc=gh_missing_and_failing
reset
empty_bin=$work/empty; mkdir -p "$empty_bin"
out=$(PATH="$empty_bin" "$BASH" "$script" add 152 container codeo-152 2>&1 < /dev/null); rc=$?
assert_eq rc 3 "$rc"
assert_eq out '| container | `codeo-152` | box1 | active | 2026-11-22T10:00:00Z | |' "${out#track: *add this row by hand: }"
assert_eq lines 1 "$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
assert_eq prefix "track:" "${out%% *}"
out=$(PATH="$empty_bin" "$BASH" "$script" mark 152 container codeo-152 removed 2>&1 < /dev/null); rc=$?
assert_eq mark-rc 3 "$rc"; assert_eq mark-lines 1 "$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
assert_eq mark-prefix "track:" "${out%% *}"
touch "$state/fail"
run add 152 container codeo-152
assert_eq fail-rc 3 "$rc"; assert_has fail-row '| container | `codeo-152` | box1 | active | 2026-11-22T10:00:00Z | |' "$out"
assert_eq fail-lines 1 "$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
run mark 152 container codeo-152 removed
assert_eq failmark-rc 3 "$rc"; assert_eq failmark-prefix "track:" "${out%% *}"

case_desc=malformed_table
reset
echo 77 > "$state/list_152"; printf '<!-- codeo:tracking -->\nno table here\n' > "$state/body_77"
run add 152 container codeo-152
assert_eq rc 3 "$rc"; assert_has names "77" "$out"; assert_has untouched "untouched" "$out"
assert_not patch PATCH "$(calls)"
run mark 152 container codeo-152 removed
assert_eq mark-rc 3 "$rc"; assert_not patch PATCH "$(calls)"

case_desc=confirm_no_rows
reset
run confirm 152; assert_eq rc 0 "$rc"; assert_eq out "" "$out"
fixture 77 '| container | `c1` | box2 | removed | 2026-11-01T00:00:00Z | 2026-11-02T00:00:00Z |'
run confirm 152; assert_eq rc-removed 0 "$rc"; assert_eq out-removed "" "$out"

case_desc=confirm_yes
reset; fixture 77 '| container | `c1` | box2 | active | 2026-11-01T00:00:00Z | |'
run confirm 152 --yes
assert_eq rc 0 "$rc"; assert_has host box2 "$out"; assert_has time 2026-11-01T00:00:00Z "$out"
assert_has status active "$out"; assert_has proof "not proof" "$out"

case_desc=confirm_no_tty
run confirm 152
assert_eq rc 1 "$rc"; assert_has hint "pass --yes" "$out"

case_desc=confirm_local_only
reset
run confirm 152 --local "a container codeo-152 exists here"
assert_eq rc 1 "$rc"; assert_has local "a container codeo-152 exists here" "$out"; assert_has proof "not proof" "$out"
run confirm 152 --yes --local "a container codeo-152 exists here"; assert_eq rc-yes 0 "$rc"

case_desc=confirm_prompt
reset; fixture 77 '| sandbox | `s1` | box2 | active | 2026-11-01T00:00:00Z | |'
run_in 'y
' confirm 152; assert_eq rc-y 0 "$rc"; assert_has prompt "Create another? [y/N]" "$out"
run_in 'n
' confirm 152; assert_eq rc-n 1 "$rc"
run_in '' confirm 152; assert_eq rc-empty 1 "$rc"

case_desc=confirm_unreadable
reset; touch "$state/failread"
run confirm 152
assert_eq rc 0 "$rc"; assert_has msg "track: could not read the tracking comment for #152" "$out"

case_desc=values_with_pipe_refused
reset
run add 152 container 'a|b'; assert_eq rc 2 "$rc"
run add 152 bogus x; assert_eq rc-kind 2 "$rc"
run mark 152 container 'a|b' removed; assert_eq rc-mark 2 "$rc"
assert_eq calls "" "$(calls)"

# --- round 2: repository choice, malformed rows, mark misses ---
repo=$work/repo; mkdir -p "$repo"; git -C "$repo" init -q; git -C "$repo" remote add origin git@github.com:someone/fork.git
nogit=$work/nogit; mkdir -p "$nogit"
run_cwd() { local d=$1; shift; out=$(cd "$d" && env -u CODEO_REPO_URL PATH="$stub_bin:$PATH" bash "$script" "$@" 2>&1 < /dev/null); rc=$?; }
nlines() { printf '%s\n' "$1" | wc -l | tr -d ' '; }

case_desc=slug_from_origin
reset; run_cwd "$repo" add 152 container c1
assert_has get "GET repos/someone/fork/issues/152/comments" "$(calls)"

case_desc=slug_url_wins_over_origin
reset; out=$(cd "$repo" && PATH="$stub_bin:$PATH" bash "$script" add 152 container c1 2>&1 < /dev/null)
assert_has get "GET repos/acme/widgets/issues/152/comments" "$(calls)"; assert_not fork "someone/fork" "$(calls)"

case_desc=slug_default_outside_checkout
reset; GIT_CEILING_DIRECTORIES=$work run_cwd "$nogit" add 152 container c1
assert_has get "GET repos/kbajpai/codeo/issues/152/comments" "$(calls)"

bad_case() { # bad_case <name> <row>
    case_desc=$1; reset; fixture 77 '| image | `ok` | box1 | active | 2026-11-01T00:00:00Z | |' "$2"
    run add 152 container c1
    assert_eq rc 3 "$rc"; assert_eq lines 1 "$(nlines "$out")"; assert_has prefix "track:" "$out"
    assert_has lineno "line 7" "$out"
    assert_not patch PATCH "$(calls)"; assert_not post POST "$(calls)"
}
bad_case row_five_cells '| image | `x` | box1 | active | 2026-11-01T00:00:00Z |'
bad_case row_eight_cells '| image | `x` | box1 | active | 2026-11-01T00:00:00Z | | extra |'
bad_case row_unknown_kind '| widget | `x` | box1 | active | 2026-11-01T00:00:00Z | |'
bad_case row_unknown_status '| image | `x` | box1 | zombie | 2026-11-01T00:00:00Z | |'

case_desc=confirm_reads_good_rows_before_a_bad_one
reset; fixture 77 '| container | `c1` | box2 | active | 2026-11-01T00:00:00Z | |' '| image | `x` | box1 | zombie | t | |'
run confirm 152 --yes
assert_eq rc 0 "$rc"; assert_has good 'container `c1` on host box2' "$out"; assert_not unreadable "could not read" "$out"

case_desc=mark_miss_prints_a_note
reset; fixture 77 '| container | `c1` | box1 | active | 2026-11-01T00:00:00Z | |'
: > "$state/calls"; run mark 152 container nothere removed
assert_eq rc 0 "$rc"
assert_eq out "track: no active container nothere row on box1 in #152's tracking comment; nothing changed" "$out"
assert_not patch PATCH "$(calls)"

case_desc=mark_without_comment_prints_a_note
reset; run mark 152 container c1 removed
assert_eq rc 0 "$rc"
assert_eq out "track: no active container c1 row on box1 in #152's tracking comment; nothing changed" "$out"
assert_not post POST "$(calls)"

if ((failures)); then echo "$failures failure(s)"; exit 1; fi
echo "all cases passed"
