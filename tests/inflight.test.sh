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
    git -C "$dir" -c init.defaultBranch="${FR_BASE:-main}" init -q
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
    printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"%s"}\n' "${FR_BASE:-main}" > "$dir/.codeo/config.json"
    printf '%s' "$dir"
}

run_inflight() {
    local clone=$1
    shift
    (cd "$clone" && PATH="$stub_bin:$PATH" bash "$plugin/scripts/inflight.sh" "$@" 2>/dev/null)
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

case_desc="inflight_follows_a_non_main_base_branch"
FR_BASE=trunk
tr_origin=$(fresh_repo)
git -C "$tr_origin" checkout -q -b feat/t
write_dossier "$tr_origin" 7 plan "Planned."
git -C "$tr_origin" checkout -q trunk
tr_clone=$(clone_of "$tr_origin")
FR_BASE=
assert_eq "no main branch anywhere" "" "$(git -C "$tr_clone" branch -a --list '*main')"
out=$(run_inflight "$tr_clone" --tsv)
assert_eq "rows" "7${tab}feat/t${tab}working${tab}plan${tab}alice" "$out"
out=$(run_inflight "$tr_clone" --branches)
assert_eq "branches" "7${tab}feat/t${tab}.codeo/7" "$out"

empty_clone=$(clone_of "$(fresh_repo)")

# A live signal in the origin, in live.sh's message format: a parentless commit on the empty tree.
plant_signal() {
    local origin=$1 issue=$2 machine=$3 user=$4 age=$5 tree sha
    tree=$(git -C "$origin" hash-object -t tree -w /dev/null)
    sha=$(printf 'codeo live signal\n\nissue: %s\nuser: %s\nmachine: %s\nhost: container\nbeat: %s\n' \
        "$issue" "$user" "$machine" "$(($(date +%s) - age))" | git -C "$origin" commit-tree "$tree" -F -)
    git -C "$origin" update-ref "refs/codeo/live/$issue/$machine" "$sha"
}
clear_signals() {
    local ref
    while IFS= read -r ref; do git -C "$1" update-ref -d "$ref"; done \
        < <(git -C "$1" for-each-ref --format='%(refname)' refs/codeo/live/)
}

case_desc="human_block_shows_a_live_session"
plant_signal "$origin" 7 codeo-7 bob 35
out=$(run_inflight "$clone")
block7=$(printf '%s\n' "$out" | awk '/^#/ { p = ($1 == "#7") } p')
assert_contains "live line after changed" "  changed:    src/x.txt
  touched:" "$block7"
assert_contains "live line" "  live:      bob on codeo-7 (container), 3" "$block7"
assert_contains "age unit" "s ago" "$block7"
assert_eq "one live line overall" 1 "$(printf '%s\n' "$out" | grep -c '^  live: ')"

case_desc="two_machines_are_two_live_lines"
plant_signal "$origin" 7 laptop carol 150
plant_signal "$origin" 7 codeo-7 bob 40
out=$(run_inflight "$clone")
assert_eq "two lines" 2 "$(printf '%s\n' "$out" | grep -c '^  live: ')"
assert_contains "laptop" "  live:      carol on laptop (container), 2m ago" "$out"

case_desc="an_expired_signal_prints_nothing"
clear_signals "$origin"
plant_signal "$origin" 7 codeo-7 bob 1000
out=$(run_inflight "$clone")
assert_eq "no live line" 0 "$(printf '%s\n' "$out" | grep -c 'live:' || true)"

case_desc="a_failed_fetch_prints_unknown_not_stale_refs"
clear_signals "$origin"
plant_signal "$origin" 7 codeo-7 bob 35
run_inflight "$clone" > /dev/null
cp "$plugin/scripts/live.sh" "$scratch_root/live.sh.real"
cat > "$plugin/scripts/live.sh" <<'LIVESTUB'
#!/usr/bin/env bash
case ${1:-} in
    fetch) echo "live: could not fetch — stub" >&2; exit 1 ;;
    list) printf '7\tbob\tcodeo-7\tcontainer\t30\n' ;;
esac
LIVESTUB
out=$(run_inflight "$clone")
assert_eq "unknown once per block" 3 "$(printf '%s\n' "$out" | grep -c "^  live:      unknown (could not fetch the signals)\$")"
assert_eq "no stale signal" 0 "$(printf '%s\n' "$out" | grep -c 'bob on' || true)"
live_rc=0
live_out=$(cd "$clone" && PATH="$stub_bin:$PATH" bash "$plugin/scripts/inflight.sh" --live 2>"$scratch_root/err") || live_rc=$?
assert_eq "--live exit" 1 "$live_rc"
assert_eq "--live stdout" "" "$live_out"
assert_contains "--live reason" "could not fetch" "$(cat "$scratch_root/err")"
cp "$scratch_root/live.sh.real" "$plugin/scripts/live.sh"

case_desc="a_malformed_signal_does_not_hide_the_ones_after_it"
clear_signals "$origin"
plant_raw_signal() { # plant_raw_signal <ref> <issue> <beat>
    local tree sha
    tree=$(git -C "$origin" hash-object -t tree -w /dev/null)
    sha=$(printf 'codeo live signal\n\nissue: %s\nuser: eve\nmachine: bad\nhost: container\nbeat: %s\n' "$2" "$3" |
        git -C "$origin" commit-tree "$tree" -F -)
    git -C "$origin" update-ref "$1" "$sha"
}
plant_signal "$origin" 5 laptop carol 30
plant_raw_signal refs/codeo/live/6/badbeat 6 "0$(date +%s)"
plant_raw_signal refs/codeo/live/6/badissue 0104 "$(date +%s)"
plant_signal "$origin" 7 codeo-7 bob 35
live_rc=0
out=$(run_inflight "$clone" --live) || live_rc=$?
assert_eq "--live exit" 0 "$live_rc"
assert_eq "both valid lines" 2 "$(printf '%s\n' "$out" | grep -c .)"
assert_contains "issue 5" "5${tab}carol${tab}laptop" "$out"
assert_contains "issue 7" "7${tab}bob${tab}codeo-7" "$out"
assert_eq "none for the bad ones" 0 "$(printf '%s\n' "$out" | grep -c "eve" || true)"
out=$(run_inflight "$clone")
block7=$(printf '%s\n' "$out" | awk '/^#/ { p = ($1 == "#7") } p')
assert_contains "later block keeps its live line" "  live:      bob on codeo-7 (container)" "$block7"

case_desc="live_listing"
clear_signals "$origin"
assert_eq "nothing live" "" "$(run_inflight "$clone" --live)"
plant_signal "$origin" 7 codeo-7 bob 35
plant_signal "$origin" 5 laptop carol 30
out=$(run_inflight "$clone" --live)
assert_eq "line count" 2 "$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
assert_contains "issue 5 first" "5${tab}carol${tab}laptop${tab}container${tab}" "$(printf '%s\n' "$out" | head -n 1)"
out=$(run_inflight "$clone" --live --except 7)
assert_eq "except 7" 0 "$(printf '%s\n' "$out" | grep -c "^7${tab}" || true)"
assert_eq "issue 5 stays" 1 "$(printf '%s\n' "$out" | grep -c "^5${tab}")"
assert_eq "nothing in flight, nothing live" "" "$(run_inflight "$empty_clone" --live)"

case_desc="live_cannot_be_combined"
for flag in --tsv --branches; do
    rc=0
    (cd "$clone" && PATH="$stub_bin:$PATH" bash "$plugin/scripts/inflight.sh" --live "$flag" >/dev/null 2>"$scratch_root/err") || rc=$?
    assert_eq "exit with $flag" 1 "$rc"
    assert_contains "usage with $flag" "usage: inflight.sh" "$(cat "$scratch_root/err")"
done

case_desc="tsv_and_branches_ignore_the_signals"
out=$(run_inflight "$clone" --tsv)
assert_eq "tsv rows" "7${tab}feat/a${tab}working${tab}plan${tab}alice
9${tab}feat/b${tab}pr-open${tab}qc${tab}
5${tab}feat/c${tab}working${tab}none${tab}" "$out"
out=$(run_inflight "$clone" --branches)
assert_eq "branches rows" "7${tab}feat/a${tab}.codeo/7
9${tab}feat/b${tab}.codeo/done/9
5${tab}feat/c${tab}.codeo/5" "$out"
: > "$GH_STUB_LOG"
run_inflight "$clone" --branches > /dev/null
assert_eq "gh log" "" "$(cat "$GH_STUB_LOG")"
clear_signals "$origin"


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

# touched: — a workflow's last-touched date and what it came from. An origin of its own, commits at
# fixed committer dates, and today pinned to 2026-11-17.
raw_dossier() {
    local origin=$1 dir=$2 step=$3 commit_date=$4 body=$5
    mkdir -p "$origin/.codeo/$dir"
    printf '%s\n' "$body" > "$origin/.codeo/$dir/$step.md"
    git -C "$origin" add .codeo
    GIT_COMMITTER_DATE="$commit_date 12:00:00 +0000" git -C "$origin" commit -q -m "$step $dir"
}
touched_branch() { git -C "$1" checkout -q main; git -C "$1" checkout -q -b "$2"; }

for n in 21 22 23 24 25 26; do
    printf '{"number":%s,"labels":[],"assignees":[]}' "$n" > "$stub_dir/GET_repos_o_n_issues_$n.json"
done
t_origin=$(fresh_repo)
touched_branch "$t_origin" feat/t21
raw_dossier "$t_origin" 21 init 2026-11-10 "# init

| Updated | 2026-11-11 |

## Log

- 2026-11-11 — started
- 2026-11-14 — planned"
touched_branch "$t_origin" feat/t22
raw_dossier "$t_origin" done/22 qc 2026-11-10 "# qc

## Log

- 2026-11-13 — checked"
touched_branch "$t_origin" feat/t23
raw_dossier "$t_origin" 23 init 2026-11-16 "# init

| Updated | 2026-11-12 |

## Log

- 2026-11-12 — started"
touched_branch "$t_origin" feat/t24
raw_dossier "$t_origin" 24 plan 2026-11-15 "# plan

| Updated | 2026-11-15 |"
touched_branch "$t_origin" feat/t25
raw_dossier "$t_origin" 25 init 2026-11-09 "# init

| Updated | 2026-13-45 |

## Log

- someday — x"
touched_branch "$t_origin" feat/t26
raw_dossier "$t_origin" 26 init 2026-11-10 "# init

## Log

- 2026-11-20 — from the future"
git -C "$t_origin" checkout -q main
t_clone=$(clone_of "$t_origin")
run_today() { local c=$1; shift; (cd "$c" && CODEO_TODAY=2026-11-17 PATH="$stub_bin:$PATH" bash "$plugin/scripts/inflight.sh" "$@" 2>/dev/null); }
t_out=$(run_today "$t_clone")
t_block() { printf '%s\n' "$t_out" | awk -v h="#$1" '/^#/ { p = ($1 == h) } p'; }

case_desc="touched_takes_the_newest_log_date"
assert_contains "line" "  touched:   2026-11-14 (init.md log), 3 days ago" "$(t_block 21)"

case_desc="touched_prefers_the_tip_when_newer"
assert_contains "line" "  touched:   2026-11-16 (branch tip), 1 days ago" "$(t_block 23)"

case_desc="touched_tie_names_the_dossier"
assert_contains "line" "  touched:   2026-11-15 (plan.md Updated), 2 days ago" "$(t_block 24)"

case_desc="touched_falls_back_to_the_tip"
assert_contains "line" "  touched:   2026-11-09 (branch tip), 8 days ago" "$(t_block 25)"

case_desc="touched_never_negative"
assert_contains "line" "  touched:   2026-11-20 (init.md log), 0 days ago" "$(t_block 26)"

case_desc="touched_reads_an_archived_dossier"
assert_contains "line" "  touched:   2026-11-13 (qc.md log), 4 days ago" "$(t_block 22)"

case_desc="touched_sits_between_changed_and_live"
plant_signal "$t_origin" 21 codeo-21 bob 35
t_out=$(run_today "$t_clone")
assert_eq "order" "changed: touched: live:" "$(t_block 21 | grep -oE '^  (changed|touched|live):' | tr -d ' ' | paste -sd' ' -)"
clear_signals "$t_origin"

case_desc="tsv_and_branches_are_unchanged"
out=$(run_today "$t_clone" --tsv)
assert_eq "tsv has no touched" 0 "$(printf '%s\n' "$out" | grep -c touched || true)"
assert_eq "tsv columns" "5" "$(printf '%s\n' "$out" | head -1 | awk -F'\t' '{print NF}')"
assert_contains "tsv row" "21${tab}feat/t21${tab}working${tab}none${tab}" "$out"
out=$(run_today "$t_clone" --branches)
assert_eq "branches has no touched" 0 "$(printf '%s\n' "$out" | grep -c touched || true)"
assert_eq "branches columns" "3" "$(printf '%s\n' "$out" | head -1 | awk -F'\t' '{print NF}')"
assert_contains "branches row" "22${tab}feat/t22${tab}.codeo/done/22" "$out"

# waits: and verdict: — what a workflow waits on, and qc's last verdict.
for n in 31 32 33 34 35 36 37 38 39 40; do
    printf '{"number":%s,"labels":[],"assignees":[]}' "$n" > "$stub_dir/GET_repos_o_n_issues_$n.json"
done
w_origin=$(fresh_repo)
w_dossier() { # w_dossier <n> <step> <body> — a new branch per workflow
    touched_branch "$w_origin" "feat/w${1##*/}"
    raw_dossier "$w_origin" "$1" "$2" 2026-11-10 "$3"
}
w_dossier 31 plan '# plan

## Notes

```
### Q8 fenced
**Answer:**
```

## Questions

### Q1 first
**Answer:** yes

### Q2 second
**Answer:**

### Q3 third
**Answer:**   

## Outcome

Done.'
raw_dossier "$w_origin" 31 qc 2026-11-10 "# qc

## Questions

### Q1 gate
**Answer:**

## Outcome

Done."
w_dossier 32 plan "# plan

## Questions

### Q1 pay
**Answer:** Paid only.

## Outcome

Done."
w_dossier 33 plan '# plan

## Questions

```
### Q9 fenced
**Answer:**
```

### Q1 real
**Answer:** ok

## Outcome

Done.'
w_dossier 34 init "# init

## Outcome

Done."
raw_dossier "$w_origin" 34 close 2026-11-10 "# close

## Outcome

### Round 1 — stashed"
w_dossier 35 init "# init

## Outcome

Done."
raw_dossier "$w_origin" 35 close 2026-11-10 "# close

## Outcome

### Round 2 — abandoned"
w_dossier done/36 qc "# qc

## Outcome

Done."
w_dossier 37 qc '# qc

## Outcome

**Verdict: back to `/codeo:implement`.**'
w_dossier 38 qc '# qc

## Outcome

### Round 1

**Verdict: back to `/codeo:plan`.**

### Round 2

**Verdict: clear — forward to `/codeo:close`.**'
w_dossier 39 qc '# qc

## Outcome

**Verdict: back to `/codeo:implement`.**'
raw_dossier "$w_origin" 39 implement 2026-11-10 "# implement

## Questions

### Q1 which
**Answer:**

## Outcome

Done."
w_dossier 40 init "# init

## Outcome

$pending"
git -C "$w_origin" checkout -q main
w_clone=$(clone_of "$w_origin")
w_out=$(run_today "$w_clone")
w_block() { printf '%s\n' "$w_out" | awk -v h="#$1" '/^#/ { p = ($1 == h) } p'; }

case_desc="waits_on_the_engineer"
assert_contains "line" "  waits:     engineer — plan.md Q2, Q3; qc.md Q1" "$(w_block 31)"

case_desc="waits_answer_on_the_same_line_is_answered"
assert_contains "next step, not engineer" "  waits:     /codeo:implement" "$(w_block 32)"

case_desc="waits_ignores_a_fenced_question"
assert_contains "next step, not engineer" "  waits:     /codeo:implement" "$(w_block 33)"

case_desc="waits_on_a_stash"
assert_contains "line" "  waits:     resume — #34's stash is live" "$(w_block 34)"

case_desc="waits_on_an_abandon"
assert_contains "line" "  waits:     resume — #35 was abandoned on" "$(w_block 35)"

case_desc="waits_on_review"
assert_contains "line" "  waits:     review — dossier archived" "$(w_block 36)"

case_desc="waits_after_a_send_back"
assert_contains "waits" "  waits:     /codeo:implement" "$(w_block 37)"
assert_contains "verdict" "  verdict:   round 1 — back to /codeo:implement." "$(w_block 37)"

case_desc="verdict_reads_the_last_round"
assert_contains "waits" "  waits:     /codeo:close" "$(w_block 38)"
assert_contains "verdict" "  verdict:   round 2 — clear — forward to /codeo:close." "$(w_block 38)"

case_desc="verdict_shown_under_an_open_question"
assert_contains "waits" "  waits:     engineer — implement.md Q1" "$(w_block 39)"
assert_contains "verdict" "  verdict:   round 1 — back to /codeo:implement." "$(w_block 39)"

case_desc="waits_nothing_known"
assert_contains "line" "  waits:     nothing known" "$(w_block 40)"
assert_eq "no verdict" 0 "$(w_block 40 | grep -c 'verdict:' || true)"

case_desc="waits_and_verdict_sit_between_touched_and_live"
plant_signal "$w_origin" 38 codeo-38 bob 35
w_out=$(run_today "$w_clone")
assert_eq "order" "changed: touched: waits: verdict: live:" "$(w_block 38 | grep -oE '^  (changed|touched|waits|verdict|live):' | tr -d ' ' | paste -sd' ' -)"
clear_signals "$w_origin"

case_desc="tsv_and_branches_carry_no_waits"
out=$(run_today "$w_clone" --tsv)
assert_eq "tsv" 0 "$(printf '%s\n' "$out" | grep -c -e waits -e verdict || true)"

# Fix round: fence kinds, section suffix, strict "clear".
for n in 41 42 43 44; do
    printf '{"number":%s,"labels":[],"assignees":[]}' "$n" > "$stub_dir/GET_repos_o_n_issues_$n.json"
done
w_dossier 41 plan '# plan

## Questions

~~~
### Q9 fenced
**Answer:**
~~~

### Q1 real
**Answer:** ok

## Outcome

Done.'
w_dossier 42 plan '# plan

## Questions

````
```
### Q9 fenced
**Answer:**
````

### Q1 real
**Answer:** ok

## Outcome

Done.'
w_dossier 43 plan '# plan

## Questions (open)

### Q1 real
**Answer:**

# Next

## Outcome

Done.'
w_dossier 44 qc '# qc

## Outcome

**Verdict: clearly fine**'
git -C "$w_origin" checkout -q main
git -C "$w_clone" fetch -q
w_out=$(run_today "$w_clone")

case_desc="waits_ignores_a_tilde_fence"
assert_contains "next step, not engineer" "  waits:     /codeo:implement" "$(w_block 41)"

case_desc="waits_ignores_a_four_backtick_fence_holding_three"
assert_contains "next step, not engineer" "  waits:     /codeo:implement" "$(w_block 42)"

case_desc="waits_reads_a_questions_heading_with_a_suffix"
assert_contains "engineer" "  waits:     engineer — plan.md Q1" "$(w_block 43)"

case_desc="clearly_is_not_clear"
assert_contains "verdict" "  verdict:   round 1 — clearly fine" "$(w_block 44)"
assert_contains "not close" "  waits:     nothing known" "$(w_block 44)"

# Round 2: waits: follows the rounds past qc's verdict; a stash leads; the next step when there is no verdict.
for n in 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59; do
    printf '{"number":%s,"labels":[],"assignees":[]}' "$n" > "$stub_dir/GET_repos_o_n_issues_$n.json"
done
qc_back_plan='# qc

## Outcome

### Round 1

**Verdict: back to `/codeo:plan`.**'
qc_clear_1='# qc

## Outcome

### Round 1

**Verdict: clear — forward to `/codeo:close`.**'
plan_replanned='# plan

## Outcome

### Round 1

First plan.

### Round 2

2026-11-17
(send-back from qc.md round 1)'
close_review='# close

## Outcome

### Round 1

Opened the PR.

### Round 2 — review feedback

`qc round at review: 1`'
w_dossier 45 qc "$qc_back_plan"
raw_dossier "$w_origin" 45 plan 2026-11-10 "$plan_replanned"
w_dossier 46 qc "$qc_back_plan"
raw_dossier "$w_origin" 46 plan 2026-11-10 "$plan_replanned"
raw_dossier "$w_origin" 46 implement 2026-11-10 '# implement

## Outcome

### Round 2
(after plan.md round 2)
Built it.'
w_dossier 47 qc '# qc

## Outcome

### Round 1

**Verdict: back to `/codeo:implement`.**'
raw_dossier "$w_origin" 47 implement 2026-11-10 '# implement

## Outcome

### Round 2

(send-back from qc.md round 1)
Fixed.'
w_dossier 48 qc "$qc_clear_1"
raw_dossier "$w_origin" 48 close 2026-11-10 "$close_review"
w_dossier 49 qc "$qc_clear_1"
raw_dossier "$w_origin" 49 close 2026-11-10 "$close_review"
raw_dossier "$w_origin" 49 implement 2026-11-10 '# implement

## Outcome

### Round 2

(send-back from close.md round 2)
Fixed.'
w_dossier 50 qc "$qc_clear_1

### Round 2

**Verdict: clear — forward to \`/codeo:close\`.**"
raw_dossier "$w_origin" 50 close 2026-11-10 "$close_review"
raw_dossier "$w_origin" 50 implement 2026-11-10 '# implement

## Outcome

### Round 2

(send-back from close.md round 2)
Fixed.'
w_dossier 51 close '### Round 1 — conflicts with main'
w_dossier 52 plan "# plan

## Outcome

Planned."
w_dossier 53 implement "# implement

## Outcome

Built."
w_dossier 54 init "# init

## Outcome

Started."
w_dossier 55 init "# init

## Outcome

Started."
raw_dossier "$w_origin" 55 close 2026-11-10 "# close

## Outcome

### Round 1 — stashed"
raw_dossier "$w_origin" 55 plan 2026-11-10 "# plan

## Questions

### Q2 second
**Answer:**

## Outcome

Done."
w_dossier 56 qc "$qc_back_plan"
raw_dossier "$w_origin" 56 plan 2026-11-10 '# plan

## Outcome

### Round 2

see (send-back from qc.md round 1)'
w_dossier 57 qc "$qc_back_plan"
raw_dossier "$w_origin" 57 plan 2026-11-10 '# plan

## Outcome

### Round 2

```
(send-back from qc.md round 1)
```'
w_dossier 58 qc "$qc_back_plan"
raw_dossier "$w_origin" 58 plan 2026-11-10 "$(printf '# plan\r\n\r\n## Outcome\r\n\r\n### Round 2\r\n\r\n   (send-back from qc.md round 1)\r\n')"
w_dossier 59 qc "$qc_back_plan"
raw_dossier "$w_origin" 59 plan 2026-11-10 "$plan_replanned"
raw_dossier "$w_origin" 59 implement 2026-11-10 '# implement

## Outcome

### Round 2

(after plan.md round 20, answering something else)
Built.'
git -C "$w_origin" checkout -q main
git -C "$w_clone" fetch -q
w_out=$(run_today "$w_clone")

case_desc="waits_after_a_replan"
assert_contains "plan answered, implement owed" "  waits:     /codeo:implement" "$(w_block 45)"
assert_contains "implement answered, qc owed" "  waits:     /codeo:qc" "$(w_block 46)"

case_desc="waits_after_an_implement_send_back_answered"
assert_contains "line" "  waits:     /codeo:qc" "$(w_block 47)"

case_desc="waits_after_review_feedback"
assert_contains "implement owed" "  waits:     /codeo:implement" "$(w_block 48)"
assert_contains "qc owed" "  waits:     /codeo:qc" "$(w_block 49)"

case_desc="waits_after_review_round_rechecked"
assert_contains "line" "  waits:     /codeo:close" "$(w_block 50)"

case_desc="waits_after_conflicts_with_base"
assert_contains "line" "  waits:     /codeo:implement" "$(w_block 51)"

case_desc="waits_names_the_next_step"
assert_contains "plan" "  waits:     /codeo:implement" "$(w_block 52)"
assert_contains "implement" "  waits:     /codeo:qc" "$(w_block 53)"
assert_contains "init" "  waits:     /codeo:plan" "$(w_block 54)"

case_desc="waits_stash_before_questions"
assert_contains "line" "  waits:     resume — #55's stash is live; engineer — plan.md Q2" "$(w_block 55)"

case_desc="waits_marker_must_start_a_line"
assert_contains "mid-line" "  waits:     /codeo:plan" "$(w_block 56)"
assert_contains "fenced" "  waits:     /codeo:plan" "$(w_block 57)"

case_desc="waits_marker_after_indent_and_crlf"
assert_contains "line" "  waits:     /codeo:implement" "$(w_block 58)"

case_desc="waits_marker_round_is_not_a_prefix_of_another"
assert_contains "round 20 is not round 2" "  waits:     /codeo:implement" "$(w_block 59)"

# touched: — a CRLF log date, and a tie between Updated and the log.
for n in 27 28; do
    printf '{"number":%s,"labels":[],"assignees":[]}' "$n" > "$stub_dir/GET_repos_o_n_issues_$n.json"
done
touched_branch "$t_origin" feat/t27
raw_dossier "$t_origin" 27 init 2026-11-10 "# init

## Log

- 2026-11-15$(printf '\r')"
touched_branch "$t_origin" feat/t28
raw_dossier "$t_origin" 28 plan 2026-11-10 "# plan

| Updated | 2026-11-15 |

## Log

- 2026-11-15 — planned"
git -C "$t_origin" checkout -q main
git -C "$t_clone" fetch -q
t_out=$(run_today "$t_clone")

case_desc="touched_log_date_with_crlf"
assert_contains "line" "  touched:   2026-11-15 (init.md log), 2 days ago" "$(t_block 27)"

case_desc="touched_log_ties_updated"
assert_contains "line" "  touched:   2026-11-15 (plan.md log), 2 days ago" "$(t_block 28)"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
