#!/usr/bin/env bash
# Every codeo workflow in flight, derived from what is pushed rather than kept anywhere.
#
#   inflight.sh [--except <N>] [--tsv | --branches | --live]
#       One block per workflow: the issue, its branch, its assignee, the last step whose dossier
#       has an `## Outcome`, the plan's `### Footprint` lines when there is one, and `changed:` — the files the branch
#       actually changes against origin/<base> (`git diff --name-only origin/<base>...<branch>`, dossiers left out,
#       comma-joined, `none` when empty). --except leaves the caller's own issue out.
#       `touched:` follows `changed:` — when the workflow was last touched and by what evidence, `<date> (<source>),
#       <d> days ago`: the newest of the branch tip's committer date, each dossier's `Updated` row and its newest
#       `## Log` date, the source naming which (`branch tip`, `<step>.md Updated`, `<step>.md log`; a tie goes to the
#       dossier). Whole calendar days to today (CODEO_TODAY=YYYY-MM-DD overrides, for tests), never negative; a
#       date that does not parse is skipped, and the line is left out when none does. Human blocks only; git only.
#       `waits:` follows `touched:` — what the workflow waits on, the first that applies: `resume — …` when its
#       stash is live or it was abandoned unresumed (claim.sh --stash-live, reading the fetched branch; working
#       dossiers only); `engineer — plan.md Q2; qc.md Q1` for open questions in its dossiers (after `resume — …;`
#       when both apply); `review — dossier archived` once close has opened its PR; the step a close send-back
#       (review feedback, a conflict with the base) leaves owing (`/codeo:implement`, then `/codeo:qc` until qc
#       grades a later round); the step qc's last verdict leaves owing, read from the `(send-back from …)` and
#       `(after plan.md round <j>…)` markers (`/codeo:close` when clear, else `/codeo:plan`, `/codeo:implement`
#       or `/codeo:qc`); with no verdict, the step after the last finished one (init: `/codeo:plan`, plan:
#       `/codeo:implement`, implement: `/codeo:qc`); else `nothing known`. `verdict:` follows it, only when
#       qc.md's last round has a bold Verdict/Routing span: `round <k> — <span>`. Human blocks only; no network.
#       --branches prints one `N<TAB>branch<TAB>dir` line per workflow (dir is <state>/N or
#       <state>/done/N, <state> being the .codeo directory) and nothing else — no assignee lookup, so no `gh` call, and nothing at
#       all when nothing is in flight. It cannot be combined with --tsv: they are different outputs.
#       --tsv prints one tab-separated line per workflow instead — issue, branch, state (working
#       or pr-open), last step (issue|init|plan|implement|qc|close|none), assignee logins joined
#       by `,` (empty when none) — with no footprint and no "nothing in flight" line. A failed
#       assignee lookup fails the whole listing instead: exit 1, the reason on stderr, nothing on
#       stdout, so a consumer never mistakes "unknown" for "none".
#       It exists for status reporters, which read it rather than scraping the human blocks. Lines come in origin's ref order, not sorted by issue.
#       Each human block ends with one `live:` line per live session of that issue (`<user> on <machine>
#       (<host>), <age> ago`, from `live.sh list --tsv` after one `live.sh fetch`), or a single
#       `live: unknown (could not fetch the signals)` when the fetch failed, never a stale signal.
#       --tsv and --branches neither fetch nor read the signals.
#       --live prints `live.sh list --tsv`'s lines (issue, user, machine, host, age in seconds) after a
#       fetch, minus the --except issue, and nothing when no one is live. A failed fetch exits 1 with the
#       reason on stderr and nothing on stdout. It cannot be combined with --tsv or --branches.
#
# A workflow is a branch on origin, other than the base branch and codeo/intake, carrying a dossier:
# at <state>/<N>/ while it is being worked, or at <state>/done/<N>/ once close has opened its PR —
# the latter only when the base branch does not already have it, since every branch inherits the
# base branch's archive.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

steps=(issue init plan implement qc close)

except= tsv= branches= live=
while (($#)); do
    case $1 in
        --except) except=${2:?issue number}; shift 2 ;;
        --tsv) tsv=1; shift ;;
        --branches) branches=1; shift ;;
        --live) live=1; shift ;;
        *) echo "usage: inflight.sh [--except <N>] [--tsv | --branches | --live]" >&2; exit 1 ;;
    esac
done
modes=0; [[ -z $tsv ]] || modes=$((modes + 1)); [[ -z $branches ]] || modes=$((modes + 1)); [[ -z $live ]] || modes=$((modes + 1))
((modes <= 1)) || { echo "usage: inflight.sh [--except <N>] [--tsv | --branches | --live]" >&2; exit 1; }

cd "$(git rev-parse --show-toplevel)"

if [[ -n $live ]]; then
    bash "$CODEO_PLUGIN_ROOT/scripts/live.sh" fetch </dev/null || exit 1
    bash "$CODEO_PLUGIN_ROOT/scripts/live.sh" list --tsv </dev/null | awk -F'\t' -v x="$except" '$1 != x'
    exit 0
fi
base=$(codeo_base_branch)
# The state directory as git sees it (relative to the repo root, where this runs).
state_rel=${CODEO_STATE_DIR#"$CODEO_PROJECT_ROOT"/}
git fetch -q --prune origin 2>/dev/null || echo "inflight: fetch failed; reading what is already here" >&2

# The last step, in pipeline order, whose dossier has an `## Outcome` that is not still pending.
last_step() {
    local ref=$1 dir=$2 step done=
    for step in "${steps[@]}"; do
        git show "$ref:$dir/$step.md" 2>/dev/null | awk '
            /^## Outcome/ { o = 1; next }
            /^## / { o = 0 }
            o && NF && !/_Pending/ { found = 1 }
            END { exit !found }' && done=$step
    done
    echo "${done:-none}"
}

# A date worth trusting: YYYY-MM-DD that `date` accepts.
valid_date() { [[ $1 =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && date -u -d "$1" +%s >/dev/null 2>&1; }

# When a workflow was last touched, and by what evidence: `<date><TAB><source>`. The candidates are the
# branch tip's committer date and, per dossier step, its `| Updated |` row and its newest `## Log` date.
# Each replaces the best so far when its date is >= it, so a tie goes to the later candidate (a dossier
# over the tip, a log over `Updated`). A date that does not parse is skipped, never fatal.
touched_of() {
    local sha=$1 dir=$2 step best_d best_s d text
    best_d=$(git log -1 --format=%cs "$sha" 2>/dev/null || true)
    valid_date "$best_d" || return 0
    best_s="branch tip"
    for step in "${steps[@]}"; do
        text=$(git show "$sha:$dir/$step.md" 2>/dev/null | tr -d '\r') || continue
        d=$(printf '%s\n' "$text" | awk -F'|' '/^\| *Updated *\|/ { gsub(/ /, "", $3); print $3; exit }')
        if valid_date "$d" && [[ ! $d < $best_d ]]; then best_d=$d best_s="$step.md Updated"; fi
        d=$(printf '%s\n' "$text" | awk '
            /^## Log/ { l = 1; next }
            /^## / { l = 0 }
            l && /^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]( |$)/ { if ($2 > m) m = $2 }
            END { print m }')
        if valid_date "$d" && [[ ! $d < $best_d ]]; then best_d=$d best_s="$step.md log"; fi
    done
    printf '%s\t%s\n' "$best_d" "$best_s"
}

# Whole calendar days from a YYYY-MM-DD to today (CODEO_TODAY, else `date +%F`), never below 0.
days_since() {
    local then now today=${CODEO_TODAY:-$(date +%F)}
    then=$(date -u -d "$1" +%s) now=$(date -u -d "$today" +%s)
    echo $(((now - then) / 86400 > 0 ? (now - then) / 86400 : 0))
}

# The awk every reader of a dossier shares: sets t to the line and f to 1 when it is a ``` or ~~~ fence
# line or inside a fence (which closes on a run at least as long as the one that opened it).
fence_awk='
    function run(s, c,   n) { n = 0; while (substr(s, n + 1, 1) == c) n++; return n }
    {
        t = $0; f = 0
        if (fence_len == 0) {
            c = substr(t, 1, 1)
            if ((c == "`" || c == "~") && run(t, c) >= 3) { fence_char = c; fence_len = run(t, c); f = 1 }
        } else {
            f = 1
            n = run(t, fence_char)
            if (n >= fence_len && substr(t, n + 1) ~ /^[ \t]*$/) fence_len = 0
        }
    }'

# The open questions of one dossier file at <sha>: `Q3, Q4` (or the whole heading when it has no Q<n>), or
# nothing. dossier-check.sh's open_questions_of, read from git: a `### ` heading under `## Questions` whose
# `**Answer:**` body (the rest of that line, then each line to the next heading) is blank; a heading with
# no `**Answer:**` line is not open; lines inside a ``` fence are ignored.
open_questions_in() {
    { git show "$1:$2" 2>/dev/null || true; } | tr -d '\r' | awk "$fence_awk"'
        function settle() { if (label != "" && answering && !answered) out = out (out == "" ? "" : ", ") label; label = ""; answering = 0; answered = 0 }
        sec == 2 { next }
        !f && t ~ /^#+ / {
            level = index(t, " ") - 1
            text = substr(t, level + 2); sub(/[ \t]+$/, "", text)
            if (sec == 1 && level <= 2) { settle(); sec = 2; next }
            if (sec == 0) {
                if (level == 2 && (text == "Questions" || index(text, "Questions ") == 1)) sec = 1
                next
            }
            settle()
            if (t ~ /^### /) {
                label = substr(t, 5)
                if (label ~ /^Q[0-9]+/) sub(/[^Q0-9].*/, "", label)
            }
            next
        }
        sec != 1 { next }
        label != "" && !answering && t ~ /^\*\*Answer:\*\*/ {
            answering = 1
            rest = substr(t, length("**Answer:**") + 1)
            if (rest ~ /[^ \t]/) answered = 1
            next
        }
        answering && t ~ /[^ \t]/ { answered = 1 }
        END { settle(); if (out != "") print out }'
}

# qc's last verdict, as qc-verdict.sh reads it: `round <k> — <span text>`, or nothing. The last bold
# `**Verdict: …**` / `**Routing: …**` span in the last round of qc.md's `## Outcome`; the round is the
# number of its last `### Round <k>` heading, else 1.
verdict_of() {
    local outcome round k span
    outcome=$({ git show "$1:$2/qc.md" 2>/dev/null || true; } | awk '
        /^## Outcome/ { o = 1; next }
        /^## / { o = 0 }
        o')
    k=$(printf '%s\n' "$outcome" | sed -nE 's/^### Round ([0-9]+).*/\1/p' | tail -n1)
    round=$(printf '%s\n' "$outcome" | awk '/^### Round [0-9]+/ { r = "" } { r = r $0 "\n" } END { printf "%s", r }')
    span=$(printf '%s\n' "$round" | tr '\n' ' ' | { grep -o -i -E '\*\*(verdict|routing)( then)?:[^*]*\*\*' || true; } | tail -n1)
    [[ -n $span ]] || return 0
    span=$(sed -E 's/\*\*//g; s/[`_]//g; s/^[[:space:]]*(verdict|routing)( then)?:[[:space:]]*//I; s/[[:space:]]+$//' <<< "$span")
    printf 'round %s — %s\n' "${k:-1}" "$span"
}

# The round number of the `### Round <n>` heading above the first line that starts (after whitespace) with
# <prefix> and is not followed by a digit; 1 when no heading precedes it; nothing when no line does. Fenced
# lines do not count, CR is ignored, a missing file is nothing.
marker_round() {
    { git show "$1:$2" 2>/dev/null || true; } | tr -d '\r' | awk -v p="$3" "$fence_awk"'
        !f && t ~ /^### Round [0-9]+/ { r = t; sub(/^### Round /, "", r); sub(/[^0-9].*/, "", r) }
        !f {
            s = t; sub(/^[ \t]+/, "", s)
            if (index(s, p) == 1 && substr(s, length(p) + 1, 1) !~ /[0-9]/) { print (r == "" ? 1 : r); exit }
        }' || true
}

# `<m> <k>` when close.md's last `### Round <m>` is a send-back (`— review feedback`, `— conflicts with …`);
# <k> is the `qc round at review: <k>` that round records, empty when it records none. Else nothing.
close_send_back() {
    { git show "$1:$2/close.md" 2>/dev/null || true; } | tr -d '\r' | awk "$fence_awk"'
        !f && t ~ /^## Outcome/ { o = 1; next }
        !f && t ~ /^## / { o = 0 }
        o && !f && t ~ /^### Round [0-9]+/ {
            m = t; sub(/^### Round /, "", m); sub(/[^0-9].*/, "", m)
            sendback = (t ~ /^### Round [0-9]+[^A-Za-z0-9]+(review feedback|conflicts with)/); k = ""; next
        }
        o && !f && sendback && k == "" && match(t, /qc round at review:[ `]*[0-9]+/) {
            k = substr(t, RSTART, RLENGTH); sub(/^[^0-9]*/, "", k)
        }
        END { if (sendback) print m " " k }' || true
}

# The number of the last `### Round` in qc.md's `## Outcome`, else 1 when it has an outcome, else nothing.
last_qc_round() {
    { git show "$1:$2/qc.md" 2>/dev/null || true; } | tr -d '\r' | awk "$fence_awk"'
        !f && t ~ /^## Outcome/ { o = 1; next }
        !f && t ~ /^## / { o = 0 }
        o && !f && t ~ /^### Round [0-9]+/ { r = t; sub(/^### Round /, "", r); sub(/[^0-9].*/, "", r) }
        o && !f && t ~ /[^ \t]/ { has = 1 }
        END { if (r != "") print r; else if (has) print 1 }' || true
}

# What a workflow waits on, first that applies (rules 1 and 2 share one line): a live stash or abandon
# (`resume — …`, claim.sh --stash-live on the already-fetched branch, working dossiers only); an open
# question (`engineer — plan.md Q2; qc.md Q1`); an archived dossier (`review — dossier archived`); the round
# close sent back (`/codeo:implement`, then `/codeo:qc` until qc re-grades); qc's last verdict (clear:
# `/codeo:close`; back to plan or implement: that step until its round answers the verdict's round, then
# `/codeo:qc`); else the step after the last one finished; else `nothing known`. Any failure falls to the next.
waits_of() {
    local sha=$1 dir=$2 state_token=$3 branch=$4 n=$5 verdict=$6 step=$7
    local s q parts= out rc=0 lead= sb m k j qcr
    if [[ $state_token == working ]]; then
        out=$(bash "$CODEO_PLUGIN_ROOT/scripts/claim.sh" --stash-live "$n" "$branch" . </dev/null 2>/dev/null) || rc=$?
        if [[ $rc == 0 || $rc == 4 ]] && [[ -n $out ]]; then lead="resume — ${out#claim: }"; fi
    fi
    for s in "${steps[@]}"; do
        q=$(open_questions_in "$sha" "$dir/$s.md")
        [[ -z $q ]] || parts+="${parts:+; }$s.md $q"
    done
    if [[ -n $parts ]]; then lead+="${lead:+; }engineer — $parts"; fi
    if [[ -n $lead ]]; then echo "$lead"; return 0; fi
    if [[ $state_token == pr-open ]]; then echo "review — dossier archived"; return 0; fi
    sb=$(close_send_back "$sha" "$dir")
    if [[ -n $sb ]]; then
        m=${sb% *} k=${sb#* }
        if [[ -z $(marker_round "$sha" "$dir/implement.md" "(send-back from close.md round $m)") ]]; then
            echo "/codeo:implement"; return 0
        fi
        qcr=$(last_qc_round "$sha" "$dir")
        if [[ -z $k || ${qcr:-0} -le $k ]]; then echo "/codeo:qc"; return 0; fi
    fi
    if [[ -n $verdict ]]; then
        k=${verdict#round } k=${k%% *}
        verdict=${verdict#round * — }
        if grep -q -i -E '^clear[[:space:]]*(\.|,|;|:|—|–|$)' <<< "$verdict"; then echo "/codeo:close"; return 0; fi
        case $verdict in
            *"/codeo:implement"*)
                if [[ -z $(marker_round "$sha" "$dir/implement.md" "(send-back from qc.md round $k)") ]]; then
                    echo "/codeo:implement"
                else
                    echo "/codeo:qc"
                fi
                return 0 ;;
            *"/codeo:plan"*)
                j=$(marker_round "$sha" "$dir/plan.md" "(send-back from qc.md round $k)")
                if [[ -z $j ]]; then
                    echo "/codeo:plan"
                elif [[ -z $(marker_round "$sha" "$dir/implement.md" "(after plan.md round $j") ]]; then
                    echo "/codeo:implement"
                else
                    echo "/codeo:qc"
                fi
                return 0 ;;
        esac
    fi
    case $step in
        init) echo "/codeo:plan" ;;
        plan) echo "/codeo:implement" ;;
        implement) echo "/codeo:qc" ;;
        *) echo "nothing known" ;;
    esac
}

# The live sessions, for the human blocks only: fetched once, read once.
live_ok= live_rows=
if [[ -z $tsv && -z $branches ]]; then
    if bash "$CODEO_PLUGIN_ROOT/scripts/live.sh" fetch </dev/null 2>/dev/null; then
        live_ok=1
        live_rows=$(bash "$CODEO_PLUGIN_ROOT/scripts/live.sh" list --tsv </dev/null 2>/dev/null || true)
    fi
fi

base_sha=$(git rev-parse "origin/$base")
found=0 rows=
while IFS= read -r ref; do
    branch=${ref#origin/}
    [[ $branch == "$base" || $branch == codeo/intake || $branch == HEAD || $ref == origin ]] && continue
    # By sha: Git for Windows' shell rewrites an `origin/x:path` argument as if it were a path list.
    sha=$(git rev-parse "$ref")

    dossiers=$(git ls-tree --name-only "$sha" -- "$state_rel/" "$state_rel/done/" 2>/dev/null |
        grep -E "^${state_rel//./\\.}/(done/)?[0-9]+\$" || true)
    for dir in $dossiers; do
        n=${dir##*/}
        [[ $n == "$except" ]] && continue
        if [[ $dir == "$state_rel"/done/* ]]; then
            git cat-file -e "$base_sha:$dir" 2>/dev/null && continue
            state="PR open" state_token=pr-open
        else
            state=working state_token=working
        fi
        found=1
        if [[ -n $branches ]]; then
            rows+=$(printf '%s\t%s\t%s' "$n" "$branch" "$dir")$'\n'
            continue
        fi
        # </dev/null: gh reads stdin, and would swallow the rest of the branch list.
        assignee=$(bash "$CODEO_PLUGIN_ROOT/scripts/github.sh" issue view "$n" </dev/null 2>/dev/null \
            | jq -r '[.assignees[]?] // [] | join(",")' 2>/dev/null || echo '?')
        if [[ -n $tsv ]]; then
            # A failed lookup (the `?` above) fails the whole listing: a consumer would read an empty
            # field as "no assignee", and rows are held back so a failure prints nothing at all.
            if [[ $assignee == '?' ]]; then
                echo "inflight: assignee lookup for #$n failed" >&2
                exit 1
            fi
            rows+=$(printf '%s\t%s\t%s\t%s\t%s' "$n" "$branch" "$state_token" "$(last_step "$sha" "$dir")" "$assignee")$'\n'
            continue
        fi
        echo "#$n  $branch"
        echo "  assignee:  ${assignee:-none}"
        echo "  step:      $(last_step "$sha" "$dir") ($state)"
        { git show "$sha:$dir/plan.md" 2>/dev/null || true; } | awk '
            /^### Footprint/ { f = 1; next }
            /^##/ { f = 0 }
            f && /^ *(files|wiki|exclusive|sequenced):/ { sub(/^ */, ""); print "  " $0 }'
        changed=$(git diff --name-only "$base_sha...$sha" -- . ":!$state_rel" 2>/dev/null | paste -sd, - | sed 's/,/, /g')
        echo "  changed:    ${changed:-none}"
        IFS=$'\t' read -r t_date t_source <<< "$(touched_of "$sha" "$dir")"
        [[ -z $t_date ]] || echo "  touched:   $t_date ($t_source), $(days_since "$t_date") days ago"
        verdict=$(verdict_of "$sha" "$dir")
        echo "  waits:     $(waits_of "$sha" "$dir" "$state_token" "$branch" "$n" "$verdict" "$(last_step "$sha" "$dir")")"
        [[ -z $verdict ]] || echo "  verdict:   $verdict"
        if [[ -z $live_ok ]]; then
            echo "  live:      unknown (could not fetch the signals)"
        else
            while IFS=$'\t' read -r l_issue l_user l_machine l_host l_age; do
                [[ $l_issue == "$n" ]] || continue
                if ((l_age < 60)); then l_age="${l_age}s"; else l_age="$((l_age / 60))m"; fi
                echo "  live:      $l_user on $l_machine ($l_host), $l_age ago"
            done <<< "$live_rows"
        fi
        echo
    done
done < <(git for-each-ref --format='%(refname:short)' refs/remotes/origin)

[[ -z $rows ]] || printf '%s' "$rows"
((found)) || [[ -n $tsv || -n $branches ]] || echo "inflight: no other workflow in flight"
