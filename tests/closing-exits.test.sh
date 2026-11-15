#!/usr/bin/env bash
# The closing block names only a command that can run (docs/handoff.md → Closing block). Each exit
# whose next command is not the skill's default carries a labelled paragraph in its SKILL.md; this
# checks the rule is stated and that each paragraph names the command the exit's state allows.
#
#   closing-exits.test.sh [case]
#       Cases: rule close-lock-kept close-finished stash-interrupted stash-completed init-no-lock
#       issue-ready issue-not-ready issue-unreadable abandon-finished abandon-interrupted
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
    echo "FAIL: $case_name — $1"
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

case_rule() {
    local block
    block=$(sed -n '/^## Closing block$/,/^## Spinning out subagents$/p' "$doc")
    has "$block" '**It names only a command that can run.**'
    for row in 'lock kept' 'stash — interrupted' 'init — no lock' 'issue — not Ready'; do
        has "$block" "$row"
    done
    has "$block" 'Exits whose next command is not the default'
    has "$block" 'stash — completed'
    # The init row names the recovery and lock.sh take local, never the default /codeo:plan.
    local row
    row=$(grep -F '`init — no lock`' <<<"$block" || true)
    has "$row" 'lock.sh take local'
    lacks "$row" '/codeo:plan'
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
}

case_stash_interrupted() {
    para "$close" '**Closing block — stash interrupted:**' || return 0
    has "$p" '/codeo:close --stash'
    lacks "$p" '/codeo:init'
}

case_stash_completed() {
    para "$close" '**Closing block — stash completed:**' || return 0
    has "$p" '/codeo:init #<N>'
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
    lacks "$s" 'Either way, end with the closing block'
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

case_abandon_finished() {
    para "$close" '**Closing block — abandon finished:**' || return 0
    has "$p" '/codeo:triage'
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
    lacks "$s" 'Report** that the workflow is finished'
}

case_stash_prose() {
    local text
    text=$(awk '/^## Stash, and closed unmerged$/ { f = 1 } f && /^\*\*Closed unmerged\*\*/ { exit } f' "$close")
    [[ -n $text ]] || { fail "no stash section in skills/close/SKILL.md"; return; }
    lacks "$text" 'Report that `/codeo:init #<N>` resumes it'
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
    return 0
}

all=(rule close-lock-kept close-finished stash-interrupted stash-completed init-no-lock
    issue-ready issue-not-ready issue-unreadable abandon-finished abandon-interrupted
    close-step17-lead stash-prose bites)

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

if ((failures == 0)); then
    echo "all cases passed"
else
    exit 1
fi
