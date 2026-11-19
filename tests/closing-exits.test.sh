#!/usr/bin/env bash
# The closing block names only a command that can run (docs/handoff.md → Closing block). Each exit
# whose next command is not the skill's default carries a labelled paragraph in its SKILL.md; this
# checks the rule is stated and that each paragraph names the command the exit's state allows.
#
#   closing-exits.test.sh [case]
#       Cases: rule close-lock-kept close-finished stash-interrupted stash-completed init-no-lock
#       init-lock-wording issue-ready issue-not-ready issue-unreadable issue-backlog abandon-finished abandon-interrupted
#       close-step17-lead stash-prose bites. CLOSING_EXITS_ROOT points the checks at another tree.
#       No argument runs them all; an unknown case exits 2. Prints "all cases passed" and exits 0, or
#       a FAIL line per failure and exits 1.
set -euo pipefail

root=${CLOSING_EXITS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
doc="$root/docs/handoff.md"
close="$root/skills/close/SKILL.md"
init="$root/skills/init/SKILL.md"
issue="$root/skills/issue/SKILL.md"

failures=0
p=
case_name=
fail() {
    echo "FAIL: $case_name — $1" >&2
    failures=$((failures + 1))
}

# $1 file, $2 fixed label. Prints from the line containing the label to the next blank line.
# Sets $p (no subshell, so a failure counts); returns 1 after failing the case if the label is absent.
para() {
    local text
    text=$(awk -v l="$2" '
        f && $0 == "" { exit }
        f || index($0, l) { f = 1; print }' "$1")
    [[ -n $text ]] || { fail "no paragraph labelled [$2] in ${1#"$root"/}"; return 1; }
    p=$text
}

# $1 text, $2 fixed string it must contain.
has() { [[ $1 == *"$2"* ]] || fail "no [$2]"; }
# $1 text, $2 fixed string it must not contain.
lacks() { [[ $1 != *"$2"* ]] || fail "has [$2], which this exit must not name"; }

# $1 text, $2 a, $3 b. True when $2 occurs and $3 occurs only after it; fails the case otherwise.
before() {
    local text=$1 head first
    if [[ $text != *"$2"* || $text != *"$3"* ]]; then
        fail "no [$3] after [$2]"
        return
    fi
    head=${text%%"$2"*}
    first=${#head}
    head=${text%%"$3"*}
    ((${#head} > first)) || fail "[$3] comes before [$2]"
}

# Prints step $2 of skill $1: from its "<n>. **" line to the next step or "## " heading.
step() {
    awk -v n="$2" '
        $0 ~ "^" n "\\. \\*\\*" { f = 1; print; next }
        f && (/^[0-9]+\. \*\*/ || /^## /) { exit }
        f { print }' "$1"
}

# Prints $1 with newlines joined and runs of spaces squeezed, so a phrase wrapped over lines matches.
flat() { printf '%s' "$1" | tr '\n' ' ' | tr -s ' '; }

case_rule() {
    local block row
    block=$(sed -n '/^## Closing block$/,/^## Spinning out subagents$/p' "$doc")
    has "$block" '**It names only a command that can run.**'
    has "$block" 'Exits whose next command is not the default'
    has "$block" 'stashed or abandoned'
    # $1 label. Prints its row of the exceptions table; fails the case when the table has none.
    row_for() {
        local r
        r=$(grep -F "| \`$1\` |" <<<"$block" || true)
        [[ -n $r ]] || { fail "docs/handoff.md has no row for [$1]"; return 0; }
        printf '%s\n' "$r"
    }
    for row in 'close — lock kept' 'stash — interrupted' 'stash — completed' 'issue — not Ready'; do
        row_for "$row" >/dev/null
    done
    local nl ai ab ur
    ab=$(row_for 'abandon — finished')
    ai=$(row_for 'abandon — interrupted')
    nl=$(row_for 'init — no lock')
    ur=$(row_for 'issue — Status unreadable')
    # The init row names the recovery and lock.sh take local, never the default /codeo:plan.
    has "$nl" 'lock: TODO'
    has "$nl" 'host workflow'
    has "$nl" 'lock.sh take local'
    lacks "$nl" '/codeo:plan'
    has "$ai" '/codeo:close'
    lacks "$ai" '--stash'
    has "$ab" '/codeo:triage'
    has "$ab" 'host workflow'
    has "$(row_for 'stash — completed')" 'host workflow'
    has "$ur" '/codeo:triage'
}

case_close_lock_kept() {
    para "$close" '**Closing block — lock kept:**' || return 0
    has "$p" '/codeo:close'
    for bad in 'remove' 'clean-up' '/codeo:triage'; do lacks "$p" "$bad"; done
    # /codeo:close must be the first command named: nothing slash-prefixed precedes it.
    local head=${p%%/codeo:close*}
    [[ $head != */codeo:* ]] || fail "another command comes before /codeo:close"
}

case_close_finished() {
    para "$close" '**Closing block — finished:**' || return 0
    has "$p" '/codeo:triage'
    has "$p" "the checkout the project's host workflow names"
}

case_stash_interrupted() {
    para "$close" '**Closing block — stash interrupted:**' || return 0
    has "$p" '/codeo:close --stash'
    lacks "$p" '/codeo:init'
}

case_stash_completed() {
    para "$close" '**Closing block — stash completed:**' || return 0
    has "$p" '/codeo:init #<N>'
    before "$(flat "$p")" 'and the next is `/codeo:init #<N>`' "the checkout the project's host workflow names"
    has "$(flat "$p")" "the checkout the project's host workflow names"
    has "$p" 'by hand'
    has "$p" 'Ready'
    before "$p" 'by hand' '/codeo:init'
}

case_init_no_lock() {
    para "$init" '**Closing block — no lock:**' || return 0
    has "$p" 'lock.sh" take local'
    lacks "$p" '/codeo:plan'
    # Step 11 once ended both exits with one sentence naming /codeo:plan; it must not return.
    local s
    s=$(step "$init" 11)
    [[ -n $s ]] || { fail "no step 11 in skills/init/SKILL.md"; return; }
    lacks "$s" 'Either way, end with the closing block'
}

# Some lock: TODO lines print after the lock was written, so step 11 must not say a TODO means no lock.
case_init_lock_wording() {
    local s
    s=$(step "$init" 11)
    [[ -n $s ]] || { fail "no step 11 in skills/init/SKILL.md"; return; }
    s=$(flat "$s")
    lacks "$s" 'there is no lock'
    has "$s" 'lock already taken'
    has "$s" 'took the lock'
    has "$s" 'lock.sh" take local'
    para "$init" '**Closing block — no lock:**' || return 0
    lacks "$(flat "$p")" '/codeo:plan'
}

# Reads step 8 of the issue skill; both Ready cases also need it to read the board.
issue_step8() {
    local s
    s=$(step "$issue" 8)
    [[ -n $s ]] || { fail "no step 8 in skills/issue/SKILL.md"; return; }
    has "$s" 'board.sh" status <N>'
    has "$s" 'config.sh" get .board'
}

case_issue_ready() {
    issue_step8
    para "$issue" '**Closing block — Ready, no board or unavailable:**' || return 0
    has "$p" '/codeo:init #<N>'
    lacks "$p" '/codeo:triage'
    has "$p" 'unavailable'
}

case_issue_not_ready() {
    issue_step8
    para "$issue" '**Closing block — not Ready:**' || return 0
    before "$p" '/codeo:triage' '/codeo:init #<N>'
}

case_issue_unreadable() {
    para "$issue" '**Closing block — Status unreadable:**' || return 0
    before "$p" 'gh auth refresh -s project' '/codeo:triage'
    before "$p" '/codeo:triage' '/codeo:init #<N>'
}

case_issue_backlog() {
    local s
    s=$(step "$issue" 8)
    [[ -n $s ]] || { fail "no step 8 in skills/issue/SKILL.md"; return; }
    has "$s" 'board.sh" set <N> backlog'
    has "$s" 'board.sh" status <N>'
    before "$s" 'board.sh" set <N> backlog' 'board.sh" status <N>'
}

case_abandon_finished() {
    para "$close" '**Closing block — abandon finished:**' || return 0
    has "$p" '/codeo:triage'
    has "$p" 'with no board'
    has "$p" 'the last copy'
    has "$(flat "$p")" "the checkout the project's host workflow names"
    lacks "$p" '/codeo:init #<N>'
    lacks "$p" '/codeo:close --stash'
}

case_abandon_interrupted() {
    para "$close" '**Closing block — abandon interrupted:**' || return 0
    has "$p" '/codeo:close'
    lacks "$p" '/codeo:close --stash'
    lacks "$p" '/codeo:init #<N>'
    # /codeo:close must be the first command named: nothing slash-prefixed precedes it.
    local head=${p%%/codeo:close*}
    [[ $head != */codeo:* ]] || fail "another command comes before /codeo:close"
}

case_close_step17_lead() {
    local s
    s=$(step "$close" 17)
    [[ -n $s ]] || { fail "no step 17 in skills/close/SKILL.md"; return; }
    lacks "$(flat "$s")" 'Report** that the workflow is finished'
    lacks "$(flat "$s")" 'End with the closing block: the goal is the loose ends found'
}

case_stash_prose() {
    local text
    text=$(awk '/^## Stash, and closed unmerged$/ { f = 1 } f && /^\*\*Closed unmerged\*\*/ { exit } f' "$close")
    [[ -n $text ]] || { fail "no stash section in skills/close/SKILL.md"; return; }
    text=$(flat "$text")
    lacks "$text" 'Report that `/codeo:init #<N>` resumes it'
    lacks "$text" 'End with the closing block: the goal is resuming the work'
}

case_host_workflow_fetch() {
    local text seg
    text=$(flat "$(cat "$close")")
    seg=${text#*'Once the lock is gone, everything is pushed'}
    seg=${seg%%'how the stash ended'*}
    has "$seg" 'overlay.sh" close host-workflow'
    seg=${text#*'Once the lock is gone, say what is left of the checkout'}
    seg=${seg%%'how the abandon ended'*}
    has "$seg" 'overlay.sh" close host-workflow'
}

# Puts each old wording back in a scratch copy and checks the named case then fails by name.
case_bites() {
    local t out copy pristine
    t=$(mktemp -d)
    # shellcheck disable=SC2064
    trap "rm -rf '$t'" RETURN
    mkdir -p "$t/skills/close" "$t/skills/init" "$t/skills/issue" "$t/docs"
    cp "$root/skills/close/SKILL.md" "$t/skills/close/SKILL.md"
    cp "$root/skills/init/SKILL.md" "$t/skills/init/SKILL.md"
    cp "$root/skills/issue/SKILL.md" "$t/skills/issue/SKILL.md"
    cp "$root/docs/handoff.md" "$t/docs/handoff.md"
    copy=$t/skills/close/SKILL.md
    pristine=$t/close.orig
    cp "$copy" "$pristine"

    sed -i 's/^17\. \*\*Report\*\* how the close ended:.*$/17. **Report** that the workflow is finished. Read the lock'"'"'s `host` line, and its `volume:` or/' "$copy"
    ! cmp -s "$pristine" "$copy" || fail "the step 17 mutation changed nothing"
    out=$(CLOSING_EXITS_ROOT=$t bash "${BASH_SOURCE[0]}" close-step17-lead 2>&1) &&
        fail "the old step 17 lead passed close-step17-lead"
    [[ $out == *close-step17-lead* ]] || fail "close-step17-lead failed without naming itself: $out"

    cp "$pristine" "$copy"
    sed -i 's/^\*\*Closed unmerged\*\*/Report that `\/codeo:init #<N>` resumes it.\n\n&/' "$copy"
    ! cmp -s "$pristine" "$copy" || fail "the stash mutation changed nothing"
    out=$(CLOSING_EXITS_ROOT=$t bash "${BASH_SOURCE[0]}" stash-prose 2>&1) &&
        fail "the old stash sentence passed stash-prose"
    [[ $out == *stash-prose* ]] || fail "stash-prose failed without naming itself: $out"

    # The old sentences as they were wrapped (2a86915^), so a line break cannot hide them.
    cp "$pristine" "$copy"
    sed -i 's/^    from a step having been attempted\. End with the closing block for the exit step 16 took:$/    from a step having been attempted. End with the closing block: the goal is the loose ends found,\n    the first step `\/codeo:triage`, then the host'"'"'s checkout clean-up above./' "$copy"
    ! cmp -s "$pristine" "$copy" || fail "the wrapped step 17 mutation changed nothing"
    out=$(CLOSING_EXITS_ROOT=$t bash "${BASH_SOURCE[0]}" close-step17-lead 2>&1) &&
        fail "the old step 17 ending passed close-step17-lead"
    [[ $out == *close-step17-lead* ]] || fail "close-step17-lead failed without naming itself: $out"

    cp "$pristine" "$copy"
    sed -i 's/^\*\*Closed unmerged\*\*/Report that `\/codeo:init #<N>`\nresumes it, on any machine.\n\n&/' "$copy"
    ! cmp -s "$pristine" "$copy" || fail "the wrapped stash sentence mutation changed nothing"
    out=$(CLOSING_EXITS_ROOT=$t bash "${BASH_SOURCE[0]}" stash-prose 2>&1) &&
        fail "the old stash sentence passed stash-prose"
    [[ $out == *stash-prose* ]] || fail "stash-prose failed without naming itself: $out"

    cp "$pristine" "$copy"
    sed -i 's/^\*\*Closed unmerged\*\*/request stays open; say so. End with the closing block: the goal is resuming the work, the first\nstep `\/codeo:init #<N>`.\n\n&/' "$copy"
    ! cmp -s "$pristine" "$copy" || fail "the wrapped stash ending mutation changed nothing"
    out=$(CLOSING_EXITS_ROOT=$t bash "${BASH_SOURCE[0]}" stash-prose 2>&1) &&
        fail "the old stash ending passed stash-prose"
    [[ $out == *stash-prose* ]] || fail "stash-prose failed without naming itself: $out"

    # The clause deleted from the stash paragraph makes stash-completed fail.
    cp "$pristine" "$copy"
    sed -i '/Closing block — stash completed:/,/^$/s/the checkout the project'"'"'s host workflow names/the checkout/' "$copy"
    ! cmp -s "$pristine" "$copy" || fail "the stash clause mutation changed nothing"
    out=$(CLOSING_EXITS_ROOT=$t bash "${BASH_SOURCE[0]}" stash-completed 2>&1) &&
        fail "the stash paragraph without the host workflow clause passed stash-completed"
    [[ $out == *stash-completed* ]] || fail "stash-completed failed without naming itself: $out"

    # The clause deleted from the abandon paragraph makes abandon-finished fail.
    cp "$pristine" "$copy"
    sed -i '/Closing block — abandon finished:/,/^$/s/the checkout the project'"'"'s host workflow names/the checkout/' "$copy"
    ! cmp -s "$pristine" "$copy" || fail "the abandon clause mutation changed nothing"
    out=$(CLOSING_EXITS_ROOT=$t bash "${BASH_SOURCE[0]}" abandon-finished 2>&1) &&
        fail "the abandon paragraph without the host workflow clause passed abandon-finished"
    [[ $out == *abandon-finished* ]] || fail "abandon-finished failed without naming itself: $out"

    # The fetch clause removed from the abandon section makes host-workflow-fetch fail.
    cp "$pristine" "$copy"
    sed -i '/^before the lock goes\. With the branch kept/,/^End with the closing block that matches how the abandon ended/{s/overlay\.sh" close host-workflow/overlay.sh" close X/}' "$copy"
    ! cmp -s "$pristine" "$copy" || fail "the abandon fetch mutation changed nothing"
    out=$(CLOSING_EXITS_ROOT=$t bash "${BASH_SOURCE[0]}" host-workflow-fetch 2>&1) &&
        fail "the abandon section without the fetch clause passed host-workflow-fetch"
    [[ $out == *host-workflow-fetch* ]] || fail "host-workflow-fetch failed without naming itself: $out"

    # The old step 17 lead wrapped over two lines: the guard reads the step flattened.
    cp "$pristine" "$copy"
    sed -i 's/^17\. \*\*Report\*\* how the close ended:.*$/17. **Report** that the workflow\n    is finished. Read the lock'"'"'s `host` line, and its `volume:` or/' "$copy"
    ! cmp -s "$pristine" "$copy" || fail "the wrapped step 17 lead mutation changed nothing"
    out=$(CLOSING_EXITS_ROOT=$t bash "${BASH_SOURCE[0]}" close-step17-lead 2>&1) &&
        fail "the wrapped old step 17 lead passed close-step17-lead"
    [[ $out == *close-step17-lead* ]] || fail "close-step17-lead failed without naming itself: $out"

    # A handoff row renamed so it only contains the label makes rule fail, naming the row.
    sed -i 's/`close — lock kept`/`close — stale lock kept`/' "$t/docs/handoff.md"
    cmp -s "$root/docs/handoff.md" "$t/docs/handoff.md" && fail "the renamed row mutation changed nothing"
    out=$(CLOSING_EXITS_ROOT=$t bash "${BASH_SOURCE[0]}" rule 2>&1) &&
        fail "the renamed handoff row passed rule"
    [[ $out == *"close — lock kept"* ]] || fail "rule failed without naming the row: $out"
    cp "$root/docs/handoff.md" "$t/docs/handoff.md"

    rm -rf "$t"
    trap - RETURN
    return 0
}

all=(rule close-lock-kept close-finished stash-interrupted stash-completed init-no-lock
    init-lock-wording issue-ready issue-not-ready issue-unreadable issue-backlog abandon-finished abandon-interrupted
    close-step17-lead stash-prose host-workflow-fetch bites)

if (($# > 0)); then
    known=0
    for c in "${all[@]}"; do [[ $c == "$1" ]] && known=1; done
    ((known)) || { echo "unknown case: $1 (cases: ${all[*]})" >&2; exit 2; }
    all=("$1")
fi

for c in "${all[@]}"; do
    case_name=$c
    "case_${c//-/_}"
done

case_name=bites
[[ -z $(trap -p RETURN) ]] || fail "a RETURN trap outlived case_bites"

if ((failures == 0)); then
    echo "all cases passed"
else
    exit 1
fi
