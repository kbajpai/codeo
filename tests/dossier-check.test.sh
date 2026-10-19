#!/usr/bin/env bash
# Exercises scripts/dossier-check.sh against the invented dossiers under tests/fixtures/dossiers/:
# every good-* fixture prints nothing, every bad-* fixture prints exactly its expected lines (and
# exits 1 when one is a FAIL), every check id in the script's header comment has a bad-<id>/
# fixture whose lines carry that id at that severity, and every usage error exits 2 with one
# "dossier-check:" stderr line, and the checker's reading of a clear last qc.md round agrees with
# scripts/qc-verdict.sh's on every qc.md here. Makes no network call; the only git state it
# touches is a scratch repository of its own.
#
#   dossier-check.test.sh
#       Exits non-zero and reports how many cases failed; prints "all cases passed" otherwise.
set -euo pipefail

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$plugin_root/scripts/dossier-check.sh"
fixtures="$plugin_root/tests/fixtures/dossiers"

failures=0
case_desc=
assert_eq() {
    local label=$1 want=$2 got=$3
    if [[ $want != "$got" ]]; then
        echo "FAIL: $case_desc — $label: want [$want] got [$got]"
        failures=$((failures + 1))
    fi
}

# run_check <dir>: sets out (stdout), err (stderr) and rc.
run_check() {
    out=$(bash "$script" "$@" 2>"$scratch/stderr") && rc=0 || rc=$?
    err=$(cat "$scratch/stderr")
}

# The expected stdout of every fixture, one finding per line; an empty string is a clean dossier.
declare -A want
want[good-basic]=
want[good-unheaded-first-round]=
want[good-park]=
want[good-open-pending]=
want[bad-title]='FAIL implement.md [title] first line is not "# Issue #<n> — implement"'
want[bad-header-table]='drift init.md [header-table] no "| | |" header table after the title'
want[bad-sections]='drift implement.md [sections] missing: ## Questions
drift close.md [sections] out of order: Where this stands, Outcome, Questions, Log'
want[bad-round-numbering]='FAIL implement.md [round-numbering] round headings run 3; expected 2
FAIL qc.md [round-numbering] ## Outcome has content before its first ### Round heading
FAIL qc.md [round-numbering] round headings run 2; expected 1'
want[bad-log-format]='FAIL init.md [log-format] line 28: does not start "- YYYY-MM-DD — "'
want[bad-log-cost]='FAIL plan.md [log-cost] line 46: no " · cost: "'
want[bad-footprint]='FAIL plan.md [footprint] ### Footprint at line 35 lacks: sequenced
FAIL plan.md [footprint] ### Footprint at line 35 has no value for: wiki'
want[bad-footprint-absent]='FAIL plan.md [footprint] no ### Footprint in ## Outcome'
want[bad-footprint-single]='drift plan.md [footprint-single] 2 ### Footprint blocks (lines 35, 44); expected one'
want[bad-open-question]='FAIL implement.md [open-question] Q2 is open but ## Outcome is written'
want[good-env]=
want[good-planned-sendback]=
want[good-first-round-clear]=
want[bad-verdict-span]='FAIL qc.md [verdict-span] round 1 has no bold "**Verdict: …**" or "**Routing: …**" span'
want[bad-verdict-route]='FAIL qc.md [verdict-route] round 1'"'"'s decision names no route: **Verdict:**
FAIL qc.md [verdict-route] round 2'"'"'s decision names more than one route: **Verdict: back to `/codeo:implement` or `/codeo:plan`.**'
want[bad-blocking-to-close]='FAIL qc.md [blocking-to-close] round 1 is routed clear with a blocking finding at line 29'
want[bad-criteria-count]='drift qc.md [criteria-count] round 1 maps 2 criteria; init.md lists 3
drift qc.md [criteria-count] round 2 has no criteria table; init.md lists 3'
want[bad-criterion-verdict]='drift qc.md [criterion-verdict] line 24: verdict "partly met" does not begin met, not met, untestable or not yet checkable
drift qc.md [criterion-verdict] line 25: verdict "" does not begin met, not met, untestable or not yet checkable'
want[bad-send-back-link]='drift implement.md [send-back-link] round 2 carries no "(send-back from <file> round <k>)" or "(after plan.md round <k>)"
drift implement.md [send-back-link] round 3 names qc.md round 5, which qc.md does not have
drift qc.md [send-back-link] round 1 is routed back to implement.md, but no implement.md round carries "(send-back from qc.md round 1)"
drift qc.md [send-back-link] round 2 is routed back to implement.md, but no implement.md round carries "(send-back from qc.md round 2)"
drift close.md [send-back-link] round 1 carries "(send-back from qc.md round 3)", which only a later implement.md or plan.md round or a "— pull request updated" round carries
drift close.md [send-back-link] round 3 carries no "(send-back from <file> round <k>)"'
want[good-review-cycle]=
want[good-issue-no-draft]=
want[bad-pending-above-rounds]='FAIL plan.md [footprint] no ### Footprint in ## Outcome
FAIL plan.md [open-question] Q2 is open but ## Outcome is written'
want[bad-qc-round-at-review]='FAIL close.md [qc-round-at-review] round 2 carries no "qc round at review: <k>"
FAIL close.md [qc-round-at-review] round 3 names qc round 7, which qc.md does not have'
want[bad-park-heading]='FAIL close.md [park-heading] line 19: "### Round 1 — Stashed" is not a park heading claim.sh reads
FAIL close.md [park-heading] line 25: "### Round 2 - abandoned" is not a park heading claim.sh reads'
want[bad-finished-qc-clear]='FAIL close.md [finished-qc-clear] a pull request is opened but qc.md'"'"'s last round is not clear'
want[bad-finished-pr]='FAIL close.md [finished-pr] 2 rounds headed "— pull request opened" (rounds 1, 3); expected one
FAIL close.md [finished-pr] round 1 records no "#<number> <url>" line'
want[bad-env-form]='drift implement.md [env-form] line 13: "- Deployed revision: rev-0042" does not start its line as "Deployed revision: <x>"
drift qc.md [env-form] line 28: "Lease not held — lease env is held by #13" does not start its line as "Lease not held: <x>"
drift qc.md [env-form] line 32: "Environment not released: origin could not be asked" does not start its line as "Environment released at the clear verdict: <x>" or "Environment NOT released: <x>"'

# --- every fixture: exact output, exit 1 exactly when a FAIL printed, nothing on stderr ----------
for dir in "$fixtures"/*/; do
    name=$(basename "$dir")
    case_desc="fixture $name"
    if [[ ! -v "want[$name]" ]]; then
        echo "FAIL: $case_desc — has no expected output in this test"
        failures=$((failures + 1))
        continue
    fi
    run_check "$dir"
    assert_eq "stdout" "${want[$name]}" "$out"
    assert_eq "stderr" "" "$err"
    if grep -q '^FAIL ' <<<"${want[$name]}"; then want_rc=1; else want_rc=0; fi
    assert_eq "exit code" "$want_rc" "$rc"
done
for name in "${!want[@]}"; do
    [[ -d $fixtures/$name ]] || { echo "FAIL: fixture $name is expected but missing"; failures=$((failures + 1)); }
done

# --- every documented check id has a bad-<id>/ fixture that prints it at its severity -----------
case_desc="check ids in the header comment"
ids=$(sed -nE 's/^#   ([a-z][a-z-]*) +(FAIL|drift) .*/\1 \2/p' "$script")
assert_eq "at least one id documented" 1 "$([[ -n $ids ]] && echo 1 || echo 0)"
while read -r id severity; do
    [[ -n $id ]] || continue
    case_desc="check id $id"
    if [[ ! -v "want[bad-$id]" ]]; then
        echo "FAIL: $case_desc — no bad-$id fixture"
        failures=$((failures + 1))
        continue
    fi
    # Every line of the fixture carries this id at the documented severity, and there is one.
    lines=$(grep -c " \[$id\] " <<<"${want[bad-$id]}" || true)
    others=$(grep -vc "^$severity [^ ]* \[$id\] " <<<"${want[bad-$id]}" || true)
    assert_eq "lines naming the id" 1 "$((lines > 0))"
    assert_eq "lines of another id or severity" 0 "$others"
done <<<"$ids"

# --- the checker's "clear" agrees with qc-verdict.sh's on every qc.md ----------------------------
# Each qc.md (every fixture's, plus decision forms on qc-verdict.sh's edges) is judged twice: by
# qc-verdict.sh, archived under .codeo/done/<n>/ in a scratch repo, and by the checker, beside a
# close.md that records an opened pull request, where finished-qc-clear prints exactly when the
# last round is not clear.
export GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@example.com"
export GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@example.com"
mkdir "$scratch/forms"
form_n=0
add_form() {
    form_n=$((form_n + 1))
    printf '# Issue #12 — qc\n\n## Outcome\n\n%s\n\n## Log\n\n- 2026-03-06 — x · cost: 1m\n' "$1" \
        >"$scratch/forms/form-$form_n.md"
}
add_form $'### Round 1 — 2026-03-06\n\n**Verdict: clear**'
add_form $'### Round 1 — 2026-03-06\n\n**Verdict:** clear'
add_form $'### Round 1 — 2026-03-06\n\n**Verdict: clearly fine**'
add_form $'### Round 1 — 2026-03-06\n\n**Verdict: not clear — back to `/codeo:implement`.**'
add_form $'### Round 1 — 2026-03-06\n\n**Routing: clear.**'
add_form $'### Round 1 — 2026-03-06\n\n**Verdict: clear — forward to `/codeo:close`.**\n\n### Round 2 — 2026-03-07\n\n**Verdict: back to `/codeo:plan`.**'
add_form $'### Round 1 — 2026-03-06\n\n**Verdict: back to `/codeo:plan`.**\n\n### Round 2 — 2026-03-07\n\n**Verdict:\nclear — forward to `/codeo:close`.**'
add_form $'### Round 1 — 2026-03-06\n\n**Verdict: clear** then **Routing: back to `/codeo:implement`.**'
add_form $'### Round 1 — 2026-03-06\n\nThe verdict is clear.'
add_form $'No round heading at all. **Verdict: clear**'
# qc-verdict.sh reads round headings without regard to fences, so the fenced heading is the last
# round there, and it has no span.
add_form $'### Round 1 — 2026-03-06\n\n**Verdict: clear**\n\n```\n### Round 2 — 2026-03-07\n```'
add_form $'### Round 1 — 2026-03-06\n\n**Verdict: Clear.**'
add_form $'### Round 1 — 2026-03-06\n\n**verdict: clear**'
add_form $'### Round 1 — 2026-03-06\n\n**Verdict: `clear`**'
add_form $'### Round 1 — 2026-03-06\n\n**Verdict: clear (no blocking)**'
add_form $'### Round 1 — 2026-03-06\n\n**Verdict: clear—forward to `/codeo:close`.**'
# A bold recap after the decision decides, wrongly, in both readers (qc/SKILL.md step 11).
add_form $'### Round 1 — 2026-03-06\n\n**Verdict: back to `/codeo:implement`.** The last round read **Verdict: clear**'
add_form $'### Round 1 — 2026-03-06\n\n**Verdict: clear — forward to `/codeo:close`.**'
sed -i 's/$/\r/' "$scratch/forms/form-$form_n.md"

agree_repo=$(mktemp -d -p "$scratch")
git -C "$agree_repo" -c init.defaultBranch=main init -q
git -C "$agree_repo" commit -q --allow-empty -m base
agree_base=$(git -C "$agree_repo" rev-parse HEAD)
qc_files=("$fixtures"/*/qc.md "$scratch"/forms/*.md)
seen_clear=0 seen_not_clear=0
for i in "${!qc_files[@]}"; do
    qc=${qc_files[$i]}
    case_desc="clear agreement on ${qc#"$plugin_root"/}"
    archive=.codeo/done/$((i + 1))
    git -C "$agree_repo" checkout -q --detach "$agree_base"
    mkdir -p "$agree_repo/$archive"
    cp "$qc" "$agree_repo/$archive/qc.md"
    git -C "$agree_repo" add -A
    git -C "$agree_repo" commit -q -m "archive $((i + 1))"
    verdict_out=$(cd "$agree_repo" && bash "$plugin_root/scripts/qc-verdict.sh" "$agree_base" HEAD 2>&1) || true
    if [[ $verdict_out == "qc-verdict: $archive/qc.md: round "*" clear" ]]; then
        verdict_says=clear seen_clear=$((seen_clear + 1))
    else
        verdict_says=not-clear seen_not_clear=$((seen_not_clear + 1))
    fi
    rm -rf "$scratch/agree" && mkdir "$scratch/agree"
    cp "$qc" "$scratch/agree/qc.md"
    cp "$fixtures/good-basic/close.md" "$scratch/agree/close.md"
    run_check "$scratch/agree"
    if grep -q ' \[finished-qc-clear\] ' <<<"$out"; then checker_says=not-clear; else checker_says=clear; fi
    assert_eq "checker against qc-verdict.sh" "$verdict_says" "$checker_says"
    assert_eq "stderr" "" "$err"
done
# Both answers must have been exercised, or the agreement would be vacuous.
case_desc="clear agreement"
assert_eq "qc.md files judged clear" 1 "$((seen_clear > 0))"
assert_eq "qc.md files judged not clear" 1 "$((seen_not_clear > 0))"

# --- the checker reads CRLF files as it reads LF ones --------------------------------------------
case_desc="CRLF line endings"
mkdir "$scratch/crlf"
for f in "$fixtures"/good-basic/*.md; do
    sed 's/$/\r/' "$f" >"$scratch/crlf/$(basename "$f")"
done
run_check "$scratch/crlf"
assert_eq "stdout" "" "$out"
assert_eq "exit code" 0 "$rc"

# --- a file whose last line has no newline keeps that line ---------------------------------------
case_desc="no final newline"
mkdir "$scratch/no-eol"
for f in "$fixtures"/good-basic/*.md; do
    printf '%s' "$(cat "$f")" >"$scratch/no-eol/$(basename "$f")"
done
run_check "$scratch/no-eol"
assert_eq "stdout" "" "$out"
assert_eq "exit code" 0 "$rc"
case_desc="no final newline after a pull request heading"
mkdir "$scratch/no-eol-close"
printf '%s' "$(sed '/^## Log/,$d; /^### Round 1/q' "$fixtures/good-basic/close.md")" >"$scratch/no-eol-close/close.md"
run_check "$scratch/no-eol-close"
assert_eq "stdout" 'drift close.md [sections] missing: ## Log
FAIL close.md [finished-pr] round 1 records no "#<number> <url>" line' "$out"
assert_eq "exit code" 1 "$rc"

# --- a long file is read to its end: no reader stops early and kills its writer -----------------
case_desc="thousands of headings and findings"
mkdir "$scratch/long"
{
    sed '/^## Outcome/,$d' "$fixtures/good-basic/qc.md"
    printf '## Notes\n\n'
    for i in $(seq 1 5000); do printf '### Note %d\n\n' "$i"; done
    printf '## Outcome\n\n### Round 1 — 2026-03-06\n\n'
    for i in $(seq 1 20000); do printf -- '- F%d (blocking) — x\n' "$i"; done
    printf '\n**Verdict: clear**\n\n## Log\n\n- 2026-03-06 — round 1 · cost: 1m\n'
} >"$scratch/long/qc.md"
run_check "$scratch/long"
assert_eq "stdout" 'FAIL qc.md [blocking-to-close] round 1 is routed clear with a blocking finding at line 10023' "$out"
assert_eq "stderr" "" "$err"
assert_eq "exit code" 1 "$rc"

# --- a file with none of the shape is classified, not a crash -----------------------------------
case_desc="shapeless file"
mkdir "$scratch/shapeless"
printf 'hello\n' >"$scratch/shapeless/plan.md"
run_check "$scratch/shapeless"
assert_eq "stdout" 'FAIL plan.md [title] first line is not "# Issue #<n> — plan"
drift plan.md [header-table] no "| | |" header table after the title
drift plan.md [sections] missing: ## Where this stands, ## Questions, ## Outcome, ## Log' "$out"
assert_eq "stderr" "" "$err"
assert_eq "exit code" 1 "$rc"

# --- usage errors: exit 2, one "dossier-check:" line on stderr, nothing on stdout --------------
mkdir "$scratch/empty" "$scratch/unrelated"
printf 'notes\n' >"$scratch/unrelated/notes.md"
printf 'x\n' >"$scratch/a-file"
usage_case() {
    case_desc=$1
    shift
    run_check "$@"
    assert_eq "exit code" 2 "$rc"
    assert_eq "stdout" "" "$out"
    assert_eq "stderr line count" 1 "$(wc -l <<<"$err")"
    assert_eq "stderr prefix" "dossier-check:" "${err%% *}"
}
usage_case "no argument"
usage_case "two arguments" "$fixtures/good-basic" "$fixtures/good-park"
usage_case "not a directory" "$scratch/a-file"
usage_case "missing path" "$scratch/nowhere"
usage_case "empty directory" "$scratch/empty"
usage_case "no dossier files" "$scratch/unrelated"
# Root reads a mode-000 file anyway, so the case means nothing there.
if (($(id -u) != 0)); then
    mkdir "$scratch/unreadable"
    cp "$fixtures/good-basic/qc.md" "$scratch/unreadable/qc.md"
    chmod 000 "$scratch/unreadable/qc.md"
    usage_case "unreadable file" "$scratch/unreadable"
    chmod 644 "$scratch/unreadable/qc.md"
fi

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
