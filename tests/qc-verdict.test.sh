#!/usr/bin/env bash
# Exercises scripts/qc-verdict.sh's verdict-reading rule against scratch git repos: the
# live-dossier check, the three verdict-line forms, multi-round precedence, the "checked but not
# judged" case for an unchanged archive, and the failure-message requirement that stderr names the
# file. Touches no real git config beyond the identity exported below and makes no network call.
#
#   qc-verdict.test.sh
#       Exits non-zero and reports how many cases failed; prints "all cases passed" otherwise.
set -euo pipefail

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$plugin_root/scripts/qc-verdict.sh"

export GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@example.com"
export GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@example.com"

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
        echo "FAIL: $case_desc — $label: [$haystack] does not contain [$needle]"
        failures=$((failures + 1))
    fi
}
assert_lacks() {
    local label=$1 needle=$2 haystack=$3
    if [[ $haystack == *"$needle"* ]]; then
        echo "FAIL: $case_desc — $label: [$haystack] contains [$needle]"
        failures=$((failures + 1))
    fi
}

new_repo() {
    local dir
    dir=$(mktemp -d -p "$scratch")
    git -C "$dir" -c init.defaultBranch=main init -q
    echo "$dir"
}

# Writes a dossier body: '## Outcome', then each round block given as an argument (blank-line
# separated), then '## Log'.
qc_md() {
    printf '## Outcome\n\n'
    local r
    for r in "$@"; do
        printf '%s\n\n' "$r"
    done
    printf '## Log\n\n- log line\n'
}

run_case() {
    local dir=$1 base=$2 head=$3
    out=$(cd "$dir" && bash "$script" "$base" "$head" 2>&1) && rc=0 || rc=$?
}

# --- case: wrong argument count ------------------------------------------------------------
case_desc="wrong argument count"
out=$(bash "$script" HEAD 2>&1) && rc=0 || rc=$?
assert_eq "exit code (one argument)" 1 "$rc"
assert_contains "usage on one argument" "usage: qc-verdict.sh <base> <head>" "$out"
out=$(bash "$script" HEAD HEAD HEAD 2>&1) && rc=0 || rc=$?
assert_eq "exit code (three arguments)" 1 "$rc"
assert_contains "usage on three arguments" "usage: qc-verdict.sh <base> <head>" "$out"

# --- case: no dossier ---------------------------------------------------------------------
case_desc="no dossier"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
echo hello > "$dir/README.md"
git -C "$dir" add README.md
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 0 "$rc"
assert_contains "output" "qc-verdict: no archived dossier in this PR" "$out"

# --- case: clear, Verdict: form ------------------------------------------------------------
case_desc="clear, Verdict: form"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

Everything checked out.

**Verdict: clear.**' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 0 "$rc"

# --- case: clear, Routing: form -------------------------------------------------------------
case_desc="clear, Routing: form"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

Everything checked out.

**Routing: clear, forward to `/codeo:close`.**' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 0 "$rc"

# --- case: clear, "verdict is" form ----------------------------------------------------------
case_desc="clear, verdict is form"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

The verdict is **clear**, and the change goes on.' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "output" "no bold Verdict/Routing span in round 1" "$out"

# --- case: prose "verdict is **clear**" after a bold send-back is not a decision --------------
case_desc="prose \"verdict is **clear**\" after a bold send-back is not a decision"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: back to `/codeo:implement`.**

F3 is blocking; as noted, the verdict is **clear** in spirit but not in fact.' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "output" "round 1 is not clear" "$out"

# --- case: a label outside the bold is not clear -------------------------------------------------
case_desc="a label outside the bold is not clear"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict:** clear' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "output" "round 1 is not clear" "$out"

# --- case: round 1 back to, round 2 clear -----------------------------------------------------
case_desc="round 1 back to, round 2 clear"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: back to `/codeo:implement`.**' \
     '### Round 2 — 2026-09-02

**Verdict: clear.**' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 0 "$rc"

# --- case: round 1 clear, round 2 back to -----------------------------------------------------
case_desc="round 1 clear, round 2 back to"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: clear.**' \
     '### Round 2 — 2026-09-02

**Verdict: back to `/codeo:implement`.**' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "stderr names the file" ".codeo/done/1/qc.md" "$out"

# --- case: not clear ---------------------------------------------------------------------------
case_desc="not clear"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

The verdict is **not clear**, more work is needed.' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "stderr names the file" ".codeo/done/1/qc.md" "$out"

# --- case: every not-clear archive in the diff is reported -------------------------------------
case_desc="every not-clear archive in the diff is reported"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1" "$dir/.codeo/done/2"
qc_md '### Round 1 — 2026-09-01

**Verdict: back to `/codeo:implement`.**' > "$dir/.codeo/done/1/qc.md"
qc_md '### Round 1 — 2026-09-01

**Verdict: blocked.**' > "$dir/.codeo/done/2/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "first archive named" ".codeo/done/1/qc.md: round 1 is not clear" "$out"
assert_contains "second archive named" ".codeo/done/2/qc.md: round 1 is not clear" "$out"

# --- case: a nested or non-numeric qc.md under done/ is not judged ------------------------------
case_desc="a nested or non-numeric qc.md under done/ is not judged"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/50/sub" "$dir/.codeo/done/abc"
for f in "$dir/.codeo/done/50/sub/qc.md" "$dir/.codeo/done/abc/qc.md"; do
    {
        printf '## Outcome\n\n'
        printf 'No round heading — this fails if it is judged.\n\n'
        printf '## Log\n\n- log line\n'
    } > "$f"
done
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 0 "$rc"
assert_lacks "nested path not judged" "done/50/sub/qc.md" "$out"
assert_lacks "non-numeric path not judged" "done/abc/qc.md" "$out"
assert_contains "the numeric parent is named, not judged" "qc-verdict: .codeo/done/50 touched, qc.md absent at head: not judged" "$out"
assert_lacks "a non-numeric directory is not an archive" "done/abc touched" "$out"

# --- case: an unbolded not-clear recap after the decision is ignored ---------------------------
case_desc="an unbolded not-clear recap after the decision is ignored"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: clear.**

Verdict then: not clear, back to `/codeo:plan`.' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 0 "$rc"
assert_contains "output" "round 1 clear" "$out"

# --- case: reviewer's verdict only --------------------------------------------------------------
case_desc="reviewer's verdict only"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

Its verdict was **with fixes**.' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "stderr names the file" ".codeo/done/1/qc.md" "$out"

# --- case: a clear… prefix is not a verdict: clearly -------------------------------------------
case_desc="a clear… prefix is not a verdict: clearly"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: clearly not ready, see B1.**' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "output" "round 1 is not clear" "$out"

# --- case: a clear… prefix is not a verdict: clear once -----------------------------------------
case_desc="a clear… prefix is not a verdict: clear once"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: clear once B1 is fixed**' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "output" "round 1 is not clear" "$out"

# --- case: clear closed by a dash passes ---------------------------------------------------------
case_desc="clear closed by a dash passes"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: clear — hand off to /codeo:close.**' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 0 "$rc"
assert_contains "output" "round 1 clear" "$out"

# --- case: no round heading ---------------------------------------------------------------------
case_desc="no round heading"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
{
    printf '## Outcome\n\n'
    printf 'Some prose with no round heading at all.\n\n'
    printf '## Log\n\n- log line\n'
} > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "stderr names the file" ".codeo/done/1/qc.md" "$out"

# --- case: an unchanged archive on base is not re-judged -----------------------------------------
case_desc="an unchanged archive on base is not re-judged"
dir=$(new_repo)
mkdir -p "$dir/.codeo/done/2"
{
    printf '## Outcome\n\n'
    printf 'No round heading here either — this would fail if it were re-judged.\n\n'
    printf '## Log\n\n- log line\n'
} > "$dir/.codeo/done/2/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m base
base=$(git -C "$dir" rev-parse HEAD)
echo hello > "$dir/README.md"
git -C "$dir" add README.md
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 0 "$rc"
assert_contains "output" "qc-verdict: no archived dossier in this PR" "$out"

# --- case: a touched archive with no qc.md at head is named, not judged --------------------------
case_desc="a touched archive with no qc.md at head is named, not judged"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/4"
echo "closed" > "$dir/.codeo/done/4/close.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 0 "$rc"
assert_contains "output" "qc-verdict: .codeo/done/4 touched, qc.md absent at head: not judged" "$out"
assert_lacks "not reported as nothing archived" "no archived dossier" "$out"

# --- case: a touched archive whose qc.md is unchanged is named, not judged -----------------------
case_desc="a touched archive whose qc.md is unchanged is named, not judged"
dir=$(new_repo)
mkdir -p "$dir/.codeo/done/5"
qc_md '### Round 1 — 2026-09-01

**Verdict: back to `/codeo:implement`.**' > "$dir/.codeo/done/5/qc.md"
echo "closed" > "$dir/.codeo/done/5/close.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m base
base=$(git -C "$dir" rev-parse HEAD)
echo "amended" > "$dir/.codeo/done/5/close.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 0 "$rc"
assert_contains "output" "qc-verdict: .codeo/done/5 touched, qc.md unchanged by this PR: not judged" "$out"
assert_lacks "not reported as nothing archived" "no archived dossier" "$out"

# --- case: live dossier ---------------------------------------------------------------------------
case_desc="live dossier"
dir=$(new_repo)
mkdir -p "$dir/.codeo/done/7"
echo "issue 7" > "$dir/.codeo/done/7/init.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/7"
git -C "$dir" mv .codeo/done/7/init.md .codeo/7/init.md
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "stderr names the file" ".codeo/7" "$out"
assert_lacks "no archived-dossier line on a failure" "no archived dossier" "$out"

# --- case: live dossier, run from a subdirectory -----------------------------------------------
case_desc="live dossier, run from a subdirectory"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/7" "$dir/sub/deep"
echo "issue 7" > "$dir/.codeo/7/init.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir/sub/deep" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "stderr names the dossier" ".codeo/7" "$out"

# --- case: a quoted earlier verdict is not the decision ------------------------------------------
case_desc="a quoted earlier verdict is not the decision"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: back to `/codeo:implement`.**' \
     "### Round 2 — 2026-09-02

Round 1's verdict: clear, B1 aside. **Verdict: returned to /codeo:implement.**" > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "output" "round 2 is not clear" "$out"

# --- case: a routing without its colon is no span -------------------------------------------------
case_desc="a routing without its colon is no span"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: back to `/codeo:implement`.**' \
     '### Round 2 — 2026-09-02

Round 1 verdict: clear.

F3 is blocking. **Routing — back to `/codeo:implement`.**' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "output" "no bold Verdict/Routing span in round 2" "$out"

# --- case: the reviewer's quoted verdict is not the decision --------------------------------------
case_desc="the reviewer's quoted verdict is not the decision"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: back to `/codeo:implement`.**' \
     "### Round 2 — 2026-09-02

The reviewer's verdict: clear.

**Verdict: blocked.** Hand-off to /codeo:implement." > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "output" "round 2 is not clear" "$out"

# --- case: an unbolded verdict is no span ----------------------------------------------------------
case_desc="an unbolded verdict is no span"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: back to `/codeo:implement`.**' \
     '### Round 2 — 2026-09-02

Verdict: clear

Correction: F2 is blocking after all; send back to implement.' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "output" "no bold Verdict/Routing span in round 2" "$out"

# --- case: a span wrapped over two lines is one span -------------------------------------------------
case_desc="a span wrapped over two lines is one span"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: back to `/codeo:implement`.**' \
     '### Round 2 — 2026-09-02

No finding is blocking. **Routing: clear, forward to
`/codeo:close`.** N1 is cosmetic.' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 0 "$rc"
assert_contains "output" "round 2 clear" "$out"

# --- case: a bold recap after the decision overrides it -----------------------------------------------
case_desc="a bold recap after the decision overrides it"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: back to `/codeo:implement`.**' \
     '### Round 2 — 2026-09-02

**Verdict: clear.** All good.

**Verdict then: not clear, back to `/codeo:plan`.**' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 1 "$rc"
assert_contains "output" "round 2 is not clear" "$out"

# --- case: a touched, judged archive prints only its round line --------------------------------
case_desc="a touched, judged archive prints only its round line"
dir=$(new_repo)
git -C "$dir" commit -q --allow-empty -m base
base=$(git -C "$dir" rev-parse HEAD)
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: clear.**' > "$dir/.codeo/done/1/qc.md"
echo "closed" > "$dir/.codeo/done/1/close.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 0 "$rc"
assert_eq "exactly the round line" "qc-verdict: .codeo/done/1/qc.md: round 1 clear" "$out"

# --- case: a PR that only deletes under done/ reports no archived dossier ------------------------
case_desc="a PR that only deletes under done/ reports no archived dossier"
dir=$(new_repo)
mkdir -p "$dir/.codeo/done/6"
echo "closed" > "$dir/.codeo/done/6/close.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m base
base=$(git -C "$dir" rev-parse HEAD)
git -C "$dir" rm -q .codeo/done/6/close.md
git -C "$dir" commit -q -m head
head=$(git -C "$dir" rev-parse HEAD)
run_case "$dir" "$base" "$head"
assert_eq "exit code" 0 "$rc"
assert_eq "output" "qc-verdict: no archived dossier in this PR" "$out"

# --- case: the configured base branch, not a literal main --------------------------------------
case_desc="qc_verdict_uses_the_configured_base_branch"
dir=$(mktemp -d -p "$scratch")
git -C "$dir" -c init.defaultBranch=trunk init -q
mkdir -p "$dir/.codeo"
printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"trunk"}\n' > "$dir/.codeo/config.json"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m base
git -C "$dir" checkout -q -b feature
mkdir -p "$dir/.codeo/done/1"
qc_md '### Round 1 — 2026-09-01

**Verdict: clear.**' > "$dir/.codeo/done/1/qc.md"
git -C "$dir" add .codeo
git -C "$dir" commit -q -m head
base_branch=$(cd "$dir" && bash "$plugin_root/scripts/config.sh" get .baseBranch)
assert_eq "no main branch exists" "" "$(git -C "$dir" branch --list main)"
run_case "$dir" "$base_branch" feature
assert_eq "exit code" 0 "$rc"
assert_eq "output" "qc-verdict: .codeo/done/1/qc.md: round 1 clear" "$out"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
