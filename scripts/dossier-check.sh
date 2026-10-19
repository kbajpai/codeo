#!/usr/bin/env bash
# Checks the structure of one issue's dossier directory against the forms docs/dossier.md and
# docs/handoff.md state, so a skill's output can be verified without reading it. It judges shape
# only — never whether a finding, a plan or an answer is right. It reads no config and sources
# nothing, so it runs on any directory: a live .codeo/<N>/, an archived done/<N>/, or a copy.
#
#   dossier-check.sh <dossier-dir>
#       Checks each of issue.md init.md plan.md implement.md qc.md close.md that is present; an
#       absent file is never a finding. Prints one line per finding,
#           <FAIL|drift> <file> [<check-id>] <text>
#       in that file order, then in the check order below; no summary line. Exits 1 when any FAIL
#       printed, 0 otherwise, and 2 on a usage error (no argument, more than one, not a directory,
#       or a directory holding none of the six files) with one "dossier-check:" line on stderr.
#
# FAIL is a promise the protocol documents make about every dossier the skills write; drift is a
# deviation reported but not failed on. A check's severity never depends on its input. The ids,
# in check order (this list is the checker's documentation, and the test reads it):
#
#   title             FAIL   the first line is "# Issue #<n> — <step>", <step> the file's name
#   header-table      drift  the first non-blank line after the title opens a "| | |" table
#   sections          drift  "## Where this stands", "## Questions", "## Outcome", "## Log" are all
#                            there in that relative order ("## Notes" optional anywhere; issue.md
#                            must also have "## Draft", anywhere)
#   round-numbering   FAIL   the "### Round <n>" headings in a written ## Outcome run consecutively
#                            from 1, or from 2 when the Outcome opens with unheaded content (the
#                            unheaded first round); qc.md and close.md head every round, so they
#                            start at 1 and have no unheaded content
#   log-format        FAIL   every ## Log entry starts "- YYYY-MM-DD — " (an indented line
#                            continues the entry above it)
#   log-cost          FAIL   every ## Log entry contains " · cost: " ("cost: unavailable" passes)
#   footprint         FAIL   plan.md: each "### Footprint" block has files, wiki, exclusive and
#                            sequenced, each with a value ("none" when empty), and once ## Outcome
#                            is written one block sits in it
#   footprint-single  drift  plan.md has at most one "### Footprint" block
#   open-question     FAIL   no question under ## Questions has an empty **Answer:** body once
#                            ## Outcome is written (docs/dossier.md → The gate)
#   verdict-span      FAIL   every qc.md round has a bold "**Verdict: …**" / "**Routing: …**"
#                            decision span (qc-verdict.sh's pattern; the round's last one decides)
#   verdict-route     FAIL   that last span names exactly one route: clear (qc-verdict.sh's rule),
#                            back to implement, or back to plan
#   blocking-to-close FAIL   no qc.md round routed clear has a blocking finding: a list item or
#                            table row saying "blocking" (not "non-blocking", "no blocking" or
#                            "Blocking: none")
#   criteria-count    drift  each qc.md round's criteria table (its first table with a "Verdict"
#                            header cell) has one row per "- [ ]" line in init.md's ## Outcome;
#                            checked only when init.md is there and lists one
#   criterion-verdict drift  each criteria row's verdict cell begins met, not met, untestable or
#                            not yet checkable (any case, bold aside)
#   send-back-link    drift  every implement.md / plan.md round after the first, and close.md's
#                            "— pull request updated" round, carries "(send-back from <file> round
#                            <k>)" (implement.md also "(after plan.md round <k>)") naming a round
#                            <file> has when <file> is there; every qc.md round but the last that
#                            is sent back is named so by the receiving file, when it is there
#   qc-round-at-review FAIL  every close.md "— review feedback" / "— conflicts with <base>" round
#                            carries "qc round at review: <k>", <k> a qc.md round when qc.md is there
#   park-heading      FAIL   a close.md "Round <n>" heading naming a stash or an abandon matches
#                            claim.sh's park_re (read from claim.sh), the heading --stash-live counts
#   finished-qc-clear FAIL   once close.md has a "— pull request opened" round: qc.md's last round
#                            is clear, read exactly as qc-verdict.sh reads it (when qc.md is there)
#   finished-pr       FAIL   once close.md has a "— pull request opened" round: exactly one has
#                            that heading, and each such round has a "#<number> <url>" line
#   env-form          drift  in implement.md and qc.md, a line that reads as "Deployed revision",
#                            "Lease not held" or "Environment (NOT) released" once list, quote and
#                            bold markers are set aside starts its line in exactly the documented
#                            form ("Deployed revision: <x>", …); none is ever required
#
# "Written" means the ## Outcome is neither empty nor the "_Pending …_" placeholder. Headings
# inside a fenced block are not headings, except that "### Footprint" is found wherever it is,
# as inflight.sh and overlap.sh find it. CRLF files read as LF ones.
set -euo pipefail

steps=(issue init plan implement qc close)

# ---------------------------------------------------------------------------------------------
# Shared helpers. Each takes a (CR-stripped) file path; line numbers are the file's own, 1-based.
# ---------------------------------------------------------------------------------------------

# marked_of <file>: every line as "<line>\t<f>\t<text>", <f> 1 for a line inside or delimiting a
# fenced block (``` or ~~~, closed by the same character at least as many times), 0 otherwise.
marked_of() {
    awk '
        function run(s, c,   n) { n = 0; while (substr(s, n + 1, 1) == c) n++; return n }
        {
            if (fence_len == 0) {
                c = substr($0, 1, 1)
                if ((c == "`" || c == "~") && run($0, c) >= 3) {
                    fence_char = c; fence_len = run($0, c)
                    print NR "\t1\t" $0; next
                }
                print NR "\t0\t" $0
            } else {
                n = run($0, fence_char)
                rest = substr($0, n + 1)
                if (n >= fence_len && rest ~ /^[ \t]*$/) fence_len = 0
                print NR "\t1\t" $0
            }
        }' "$1"
}

# headings_of <file>: "<line>\t<level>\t<text>" for each ATX heading outside a fenced block.
headings_of() {
    marked_of "$1" | awk -F'\t' '
        $2 == 0 && $3 ~ /^#+ / {
            level = index($3, " ") - 1
            text = substr($3, level + 2)
            sub(/[ \t]+$/, "", text)
            print $1 "\t" level "\t" text
        }'
}

# section_range <file> <name>: "<heading-line> <last-line>" of the first "## <name>" section
# (heading text equal to <name>, or <name> then a space: "## Draft (approved)"); it runs to the
# next level-1 or level-2 heading. Prints nothing when the section is absent.
section_range() {
    local file=$1 name=$2 total
    total=$(wc -l <"$file")
    headings_of "$file" | awk -F'\t' -v name="$name" -v total="$total" '
        start && $2 <= 2 { print start " " ($1 - 1); found = 1; exit }
        !start && $2 == 2 && ($3 == name || index($3, name " ") == 1) { start = $1 }
        END { if (start && !found) print start " " total }'
}

# section_of <file> <name>: the body of "## <name>" (heading excluded) as "<line>\t<text>".
section_of() {
    local range
    range=$(section_range "$1" "$2")
    [[ -n $range ]] || return 0
    awk -v from="${range% *}" -v to="${range#* }" 'NR > from && NR <= to { print NR "\t" $0 }' "$1"
}

# has_section <file> <name>: status 0 when "## <name>" exists.
has_section() {
    [[ -n $(section_range "$1" "$2") ]]
}

# outcome_written <file>: status 0 when ## Outcome exists and is neither empty nor the pending
# placeholder (its first non-blank line starting "_Pending").
outcome_written() {
    local first
    first=$(section_of "$1" Outcome | cut -f2- | awk 'NF { print; exit }')
    [[ -n $first && $first != _Pending* ]]
}

# rounds_of <file>: "<line>\t<n>\t<heading text>" for each "### Round <n>" heading in ## Outcome,
# outside fenced blocks, in file order.
rounds_of() {
    local range
    range=$(section_range "$1" Outcome)
    [[ -n $range ]] || return 0
    headings_of "$1" | awk -F'\t' -v from="${range% *}" -v to="${range#* }" '
        $1 > from && $1 <= to && $2 == 3 && $3 ~ /^Round [0-9]+([^0-9]|$)/ {
            n = substr($3, 7); sub(/[^0-9].*/, "", n)
            print $1 "\t" n "\t" $3
        }'
}

# outcome_lead_of <file>: the non-blank ## Outcome lines before its first round heading (all of
# them when there is none), as "<line>\t<text>" — the unheaded first round, when there is one.
outcome_lead_of() {
    local first
    first=$(rounds_of "$1" | awk -F'\t' 'NR == 1 { print $1 }')
    section_of "$1" Outcome | awk -F'\t' -v stop="${first:-0}" '
        stop && $1 >= stop { exit }
        { t = $0; sub(/^[0-9]+\t/, "", t) } t ~ /[^ \t]/ { print }'
}

# round_body_of <file> <heading-line>: the round headed at <heading-line>, heading included, to
# the line before the next round heading or the end of ## Outcome, as "<line>\t<text>".
round_body_of() {
    local file=$1 at=$2 range next
    range=$(section_range "$file" Outcome)
    next=$(rounds_of "$file" | awk -F'\t' -v at="$at" '$1 > at { print $1; exit }')
    awk -v from="$at" -v to="${next:-$((${range#* } + 1))}" 'NR >= from && NR < to { print NR "\t" $0 }' "$file"
}

# footprints_of <file>: one "<line>\t<key>=<value>;…" row per "### Footprint" block, wherever it
# is (fenced or not, as inflight.sh and overlap.sh read it); the block runs to the next line
# starting "##". Keys are the four the footprint names, values trimmed, a key repeated keeps its
# first value.
footprints_of() {
    awk '
        function flush() { if (at) print at "\t" kv; at = 0; kv = "" }
        /^### Footprint/ { flush(); at = NR; next }
        /^##/ { flush(); next }
        at && $0 ~ /^ *(files|wiki|exclusive|sequenced):/ {
            line = $0; sub(/^ */, "", line)
            key = line; sub(/:.*/, "", key)
            value = line; sub(/^[a-z]+:/, "", value); gsub(/^[ \t]+|[ \t]+$/, "", value)
            if (index(";" kv, ";" key "=") == 0) kv = kv key "=" value ";"
        }
        END { flush() }' "$1"
}

# ---------------------------------------------------------------------------------------------
# Findings.
# ---------------------------------------------------------------------------------------------

failed=0
# finding <FAIL|drift> <file> <check-id> <text>
finding() {
    printf '%s %s [%s] %s\n' "$1" "$2" "$3" "$4"
    [[ $1 != FAIL ]] || failed=1
}

# Each check takes the CR-stripped copy and the dossier file's name (plan.md).

check_title() {
    local file=$1 name=$2 step=${2%.md} first re
    first=$(head -n1 "$file")
    re="^# Issue #[0-9]+ — $step[[:space:]]*\$"
    [[ $first =~ $re ]] || finding FAIL "$name" title "first line is not \"# Issue #<n> — $step\""
}

check_header_table() {
    local file=$1 name=$2 line
    line=$(awk 'NR > 1 && NF { print; exit }' "$file")
    [[ $line =~ ^\|[[:space:]]*\|[[:space:]]*\|[[:space:]]*$ ]] \
        || finding drift "$name" header-table 'no "| | |" header table after the title'
}

check_sections() {
    local file=$1 name=$2 s range missing=() present=() ordered=()
    local required=("Where this stands" Questions Outcome Log) listed=("Where this stands" Questions)
    [[ $name != issue.md ]] || listed+=(Draft)
    listed+=(Outcome Log)
    for s in "${listed[@]}"; do
        has_section "$file" "$s" || missing+=("## $s")
    done
    if ((${#missing[@]})); then
        local joined
        joined=$(printf '%s, ' "${missing[@]}")
        finding drift "$name" sections "missing: ${joined%, }"
    fi
    # The relative order of the required sections that are there, against their file order.
    for s in "${required[@]}"; do
        range=$(section_range "$file" "$s")
        [[ -z $range ]] || { ordered+=("$s"); present+=("${range% *}	$s"); }
    done
    local actual want
    actual=$(printf '%s\n' "${present[@]}" | sort -n | cut -f2 | paste -sd, - | sed 's/,/, /g')
    want=$(printf '%s\n' "${ordered[@]}" | paste -sd, - | sed 's/,/, /g')
    [[ $actual == "$want" ]] || finding drift "$name" sections "out of order: $actual"
}

check_round_numbering() {
    local file=$1 name=$2 strict=0 lead numbers start want
    outcome_written "$file" || return 0
    [[ $name != qc.md && $name != close.md ]] || strict=1
    lead=$(outcome_lead_of "$file")
    if ((strict)) && [[ -n $lead ]]; then
        finding FAIL "$name" round-numbering "## Outcome has content before its first ### Round heading"
    fi
    numbers=$(rounds_of "$file" | cut -f2)
    [[ -n $numbers ]] || return 0
    if ((strict)) || [[ -z $lead ]]; then start=1; else start=2; fi
    want=$(seq "$start" $((start + $(wc -l <<<"$numbers") - 1)) | paste -sd, - | sed 's/,/, /g')
    numbers=$(paste -sd, - <<<"$numbers" | sed 's/,/, /g')
    [[ $numbers == "$want" ]] || finding FAIL "$name" round-numbering "round headings run $numbers; expected $want"
}

# log_entries_of <file>: one "<line>\t<entry>" row per ## Log entry, an indented line joined
# onto the entry above it with one space.
log_entries_of() {
    section_of "$1" Log | awk -F'\t' '
        { t = $0; sub(/^[0-9]+\t/, "", t) }
        t !~ /[^ \t]/ { next }
        t ~ /^[ \t]/ && at { sub(/^[ \t]+/, "", t); entry = entry " " t; next }
        { if (at) print at "\t" entry; at = $1; entry = t }
        END { if (at) print at "\t" entry }'
}

check_log_format() {
    local file=$1 name=$2 line entry re='^- [0-9]{4}-[0-9]{2}-[0-9]{2} — '
    while IFS=$'\t' read -r line entry; do
        [[ $entry =~ $re ]] || finding FAIL "$name" log-format "line $line: does not start \"- YYYY-MM-DD — \""
    done < <(log_entries_of "$file")
}

check_log_cost() {
    local file=$1 name=$2 line entry
    while IFS=$'\t' read -r line entry; do
        [[ $entry == *" · cost: "* ]] || finding FAIL "$name" log-cost "line $line: no \" · cost: \""
    done < <(log_entries_of "$file")
}

check_footprint() {
    local file=$1 name=$2 range line kv key lacks empty in_outcome=0
    [[ $name == plan.md ]] || return 0
    if outcome_written "$file"; then
        range=$(section_range "$file" Outcome)
        while IFS=$'\t' read -r line kv; do
            ((line > ${range% *} && line <= ${range#* })) && in_outcome=1
        done < <(footprints_of "$file")
        ((in_outcome)) || finding FAIL "$name" footprint "no ### Footprint in ## Outcome"
    fi
    while IFS=$'\t' read -r line kv; do
        lacks=() empty=()
        for key in files wiki exclusive sequenced; do
            if [[ ";$kv" != *";$key="* ]]; then
                lacks+=("$key")
            elif [[ ";$kv" == *";$key=;"* ]]; then
                empty+=("$key")
            fi
        done
        ((${#lacks[@]} == 0)) || finding FAIL "$name" footprint "### Footprint at line $line lacks: $(IFS=,; echo "${lacks[*]}" | sed 's/,/, /g')"
        ((${#empty[@]} == 0)) || finding FAIL "$name" footprint "### Footprint at line $line has no value for: $(IFS=,; echo "${empty[*]}" | sed 's/,/, /g')"
    done < <(footprints_of "$file")
}

check_footprint_single() {
    local file=$1 name=$2 lines count
    [[ $name == plan.md ]] || return 0
    lines=$(footprints_of "$file" | cut -f1)
    [[ -n $lines ]] || return 0
    count=$(wc -l <<<"$lines")
    ((count <= 1)) || finding drift "$name" footprint-single "$count ### Footprint blocks (lines $(paste -sd, - <<<"$lines" | sed 's/,/, /g')); expected one"
}

# open_questions_of <file>: the label of each question under ## Questions — a "### " heading — whose
# **Answer:** body (the rest of that line, then every line to the next heading) is blank. The
# label is the heading's leading "Q<n>", or the whole heading text when it has none. A question
# with no **Answer:** line is not one the gate can call open.
open_questions_of() {
    local range
    range=$(section_range "$1" Questions)
    [[ -n $range ]] || return 0
    marked_of "$1" | awk -F'\t' -v from="${range% *}" -v to="${range#* }" '
        function settle() { if (label != "" && answering && !answered) print label; label = ""; answering = 0; answered = 0 }
        $1 <= from || $1 > to { next }
        { t = $0; sub(/^[0-9]+\t[01]\t/, "", t) }
        $2 == 0 && t ~ /^#+ / {
            settle()
            if (t ~ /^### /) {
                label = substr(t, 5)
                if (label ~ /^Q[0-9]+/) { sub(/[^Q0-9].*/, "", label) }
            }
            next
        }
        label != "" && !answering && t ~ /^\*\*Answer:\*\*/ {
            answering = 1
            rest = substr(t, length("**Answer:**") + 1)
            if (rest ~ /[^ \t]/) answered = 1
            next
        }
        answering && t ~ /[^ \t]/ { answered = 1 }
        END { settle() }'
}

check_open_question() {
    local file=$1 name=$2 q
    outcome_written "$file" || return 0
    while IFS= read -r q; do
        [[ -n $q ]] || continue
        finding FAIL "$name" open-question "$q is open but ## Outcome is written"
    done < <(open_questions_of "$file")
}

# ---------------------------------------------------------------------------------------------
# qc rounds: decisions, findings, criteria.
# ---------------------------------------------------------------------------------------------

# sibling <file> <name>: the path of another dossier file beside <file> (all are copied before
# any check runs); status 1 when that file is absent.
sibling() {
    local path
    path=$(dirname "$1")/$2
    [[ -f $path ]] || return 1
    echo "$path"
}

# round_marked_of <file> <heading-line>: the round headed at <heading-line>, as marked_of rows.
round_marked_of() {
    local file=$1 at=$2 last
    last=$(round_body_of "$file" "$at" | tail -n1 | cut -f1)
    marked_of "$file" | awk -F'\t' -v from="$at" -v to="$last" '$1 >= from && $1 <= to'
}

# round_numbers_of <file>: the round numbers <file> has, one per line — its headed rounds, and 1
# when its ## Outcome opens with unheaded content (the unheaded first round).
round_numbers_of() {
    [[ -z $(outcome_lead_of "$1") ]] || echo 1
    rounds_of "$1" | cut -f2
}

# spans_of: the bold decision spans of stdin, in order — qc-verdict.sh's pattern, on the raw
# text with lines joined, so a span wrapped over two lines is one span.
spans_of() {
    tr '\n' ' ' | grep -o -i -E '\*\*(verdict|routing)( then)?:[^*]*\*\*' || true
}

# span_text <span>: the span's text after its label, bold, backticks and underscores gone — the
# text qc-verdict.sh judges.
span_text() {
    sed -E 's/\*\*//g; s/[`_]//g; s/^[[:space:]]*(verdict|routing)( then)?:[[:space:]]*//I' <<<"$1"
}

# is_clear_text <text>: status 0 when the span text reads clear by qc-verdict.sh's rule: "clear",
# then the end of the span or one of . , ; : — –.
is_clear_text() {
    grep -q -i -E '^clear[[:space:]]*(\.|,|;|:|—|–|$)' <<<"$1"
}

# route_of <span>: "clear", "implement" or "plan" when the span names exactly that one route,
# "none" when it names none, "many" when it names more than one. Clear is qc-verdict.sh's
# reading; a send-back is the steps named in the clause after "back to" (up to a dash, a
# semicolon, a parenthesis or a sentence's end), with or without their plugin prefix.
route_of() {
    local text dest routes=()
    text=$(span_text "$1")
    ! is_clear_text "$text" || routes+=(clear)
    dest=$(grep -o -i -E 'back to .*' <<<"$text" | head -n1 | sed -E 's/(—|–|;|\(|\. |\.$).*//')
    if [[ -n $dest ]]; then
        ! grep -q -i -E '(^|[^[:alnum:]])implement([^[:alnum:]]|$)' <<<"$dest" || routes+=(implement)
        ! grep -q -i -E '(^|[^[:alnum:]])plan([^[:alnum:]]|$)' <<<"$dest" || routes+=(plan)
    fi
    case ${#routes[@]} in
        0) echo none ;;
        1) echo "${routes[0]}" ;;
        *) echo many ;;
    esac
}

# decision_of <file> <heading-line>: the round's last decision span, or nothing.
decision_of() {
    round_body_of "$1" "$2" | cut -f2- | spans_of | tail -n1
}

# last_round_clear <file>: status 0 when qc.md's last round is clear — qc-verdict.sh's reading
# transcribed step for step (## Outcome to the next "## " line, round headings and spans found
# with no regard to fences), so the two cannot disagree; the test holds them to it.
last_round_clear() {
    local outcome headings last_line round decision
    outcome=$(awk '
        /^## Outcome/ { in_outcome = 1; next }
        in_outcome && /^## / { exit }
        in_outcome { print }
    ' "$1")
    headings=$(grep -nE '^### Round [0-9]+' <<<"$outcome" || true)
    [[ -n $headings ]] || return 1
    last_line=$(tail -n1 <<<"$headings")
    last_line=${last_line%%:*}
    round=$(tail -n +"$last_line" <<<"$outcome")
    decision=$(spans_of <<<"$round" | tail -n1)
    [[ -n $decision ]] || return 1
    is_clear_text "$(span_text "$decision")"
}

# blocking_findings_of <file> <heading-line>: the line of each blocking finding in the round,
# outside fenced blocks. A finding is a list item ("- ", "* ", "+ ", "1. ") or a table body row.
# In a table with a "Blocking" header cell, a row is blocking when that cell begins "yes" or
# "blocking". Anywhere else, a finding is blocking when it classifies itself with the word
# "blocking" (any case, bold aside): the word stands alone (not "non-blocking"), comes right
# after the item's start and an optional id ("- F2 blocking", "- Blocking — …"), or after a
# "(", "[", ",", ":", ";", "|", "/" or a dash ("F2 (blocking, implement)", "F2 — blocking"),
# and is not answered as empty ("Blocking: none"). Prose that merely mentions the word ("no
# blocking finding", "two findings it called blocking") is not a finding.
blocking_findings_of() {
    round_marked_of "$1" "$2" | awk -F'\t' '
        function strip(s) { s = tolower(s); gsub(/[*_`]/, "", s); return s }
        function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
        function classifies(s,   rest, at, before, after, prefix) {
            rest = s; at = 0
            while (match(rest, /blocking/)) {
                before = substr(s, 1, at + RSTART - 1); after = substr(rest, RSTART + RLENGTH)
                at += RSTART + RLENGTH - 1; rest = after
                if (before ~ /[[:alnum:]-]$/ || after ~ /^[[:alnum:]-]/) continue
                if (after ~ /^[ \t]*(:|—|–|-)?[ \t]*(none|nothing|no|0)([^[:alnum:]]|$)/) continue
                prefix = before; sub(/[ \t]+$/, "", prefix)
                if (prefix ~ /^[ \t]*([-*+]|[0-9]+[.)])([ \t]+[a-z]{0,3}[0-9]+[.:)]?)?$/) return 1
                if (prefix ~ /(\(|\[|,|:|;|\||\/|—|–|-)$/) return 1
            }
            return 0
        }
        $2 == 1 { tstate = 0; next }
        {
            t = $0; sub(/^[0-9]+\t[01]\t/, "", t)
            if (t ~ /^[ \t]*\|/) {
                # tstate 0: no table; 1: header read; 2: in the body.
                if (tstate == 0) {
                    bcol = 0; n = split(t, c, "|")
                    for (i = 2; i <= n; i++) if (trim(strip(c[i])) ~ /^blocking/) { bcol = i; break }
                    tstate = 1; next
                }
                if (tstate == 1 && t ~ /^[ \t|:-]+$/) { tstate = 2; next }
                tstate = 2
                if (bcol) {
                    split(t, c, "|")
                    if (trim(strip(c[bcol])) ~ /^(yes|blocking)([^[:alnum:]-]|$)/) print $1
                } else if (classifies(strip(t))) print $1
                next
            }
            tstate = 0
            if (t ~ /^[ \t]*([-*+] |[0-9]+[.)] )/ && classifies(strip(t))) print $1
        }'
}

# criteria_of <file> <heading-line>: the round's criteria table — the first table outside a
# fenced block whose header row has a cell containing "verdict" (any case) and whose second row
# is a separator. Prints "table\t<header-line>" and then "<line>\t<verdict cell>" per row;
# nothing when the round has no such table. "\|" in a cell is not a column break.
criteria_of() {
    round_marked_of "$1" "$2" | awk -F'\t' '
        function cells(s, out) {
            gsub(/\\\|/, "\001", s)
            sub(/^[ \t]*\|/, "", s); sub(/\|[ \t]*$/, "", s)
            return split(s, out, "|")
        }
        function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); gsub(/\001/, "|", s); return s }
        done { next }
        {
            t = $0; sub(/^[0-9]+\t[01]\t/, "", t)
            is_row = ($2 == 0 && t ~ /^[ \t]*\|/)
        }
        # state 0: outside a table; 1: header read; 2: in the criteria rows; 3: in another table.
        state == 0 && is_row {
            n = cells(t, c); col = 0
            for (i = 1; i <= n; i++) if (tolower(c[i]) ~ /verdict/) { col = i; break }
            if (col) { state = 1; header = $1 } else state = 3
            next
        }
        state == 3 { if (!is_row) state = 0; next }
        state == 1 {
            if (is_row && t ~ /^[ \t|:-]+$/ && t ~ /-/) { state = 2; print "table\t" header; next }
            state = (is_row ? 3 : 0); next
        }
        state == 2 {
            if (!is_row) { done = 1; next }
            cells(t, c)
            print $1 "\t" trim(c[col])
        }'
}

# init_criteria_count <init-file>: the acceptance criteria in init.md's ## Outcome — its "- [ ]"
# lines ("* " and a ticked "[x]" too), outside fenced blocks.
init_criteria_count() {
    local range
    range=$(section_range "$1" Outcome)
    [[ -n $range ]] || { echo 0; return 0; }
    marked_of "$1" | awk -F'\t' -v from="${range% *}" -v to="${range#* }" '
        $1 > from && $1 <= to && $2 == 0 && $3 ~ /^[ \t]*[-*] \[[ xX]\] / { n++ }
        END { print n + 0 }'
}

check_verdict_span() {
    local file=$1 name=$2 line n heading
    [[ $name == qc.md ]] || return 0
    while IFS=$'\t' read -r line n heading; do
        [[ -n $(decision_of "$file" "$line") ]] \
            || finding FAIL "$name" verdict-span "round $n has no bold \"**Verdict: …**\" or \"**Routing: …**\" span"
    done < <(rounds_of "$file")
}

check_verdict_route() {
    local file=$1 name=$2 line n heading span
    [[ $name == qc.md ]] || return 0
    while IFS=$'\t' read -r line n heading; do
        span=$(decision_of "$file" "$line")
        [[ -n $span ]] || continue
        case $(route_of "$span") in
            none) finding FAIL "$name" verdict-route "round $n's decision names no route: $span" ;;
            many) finding FAIL "$name" verdict-route "round $n's decision names more than one route: $span" ;;
        esac
    done < <(rounds_of "$file")
}

check_blocking_to_close() {
    local file=$1 name=$2 line n heading span at
    [[ $name == qc.md ]] || return 0
    while IFS=$'\t' read -r line n heading; do
        span=$(decision_of "$file" "$line")
        [[ -n $span ]] && is_clear_text "$(span_text "$span")" || continue
        at=$(blocking_findings_of "$file" "$line" | head -n1)
        [[ -z $at ]] || finding FAIL "$name" blocking-to-close "round $n is routed clear with a blocking finding at line $at"
    done < <(rounds_of "$file")
}

check_criteria_count() {
    local file=$1 name=$2 init want line n heading rows
    [[ $name == qc.md ]] || return 0
    init=$(sibling "$file" init.md) || return 0
    want=$(init_criteria_count "$init")
    ((want > 0)) || return 0
    while IFS=$'\t' read -r line n heading; do
        rows=$(criteria_of "$file" "$line")
        if [[ -z $rows ]]; then
            finding drift "$name" criteria-count "round $n has no criteria table; init.md lists $want"
        elif (($(wc -l <<<"$rows") - 1 != want)); then
            finding drift "$name" criteria-count "round $n maps $(($(wc -l <<<"$rows") - 1)) criteria; init.md lists $want"
        fi
    done < <(rounds_of "$file")
}

check_criterion_verdict() {
    local file=$1 name=$2 line n heading row cell bare
    [[ $name == qc.md ]] || return 0
    while IFS=$'\t' read -r line n heading; do
        while IFS=$'\t' read -r row cell; do
            [[ -n $row && $row != table ]] || continue
            bare=$(sed -E 's/[*_`]//g; s/^[[:space:]]+//' <<<"$cell")
            grep -q -i -E '^(met|not met|untestable|not yet checkable)([^[:alnum:]]|$)' <<<"$bare" \
                || finding drift "$name" criterion-verdict "line $row: verdict \"$cell\" does not begin met, not met, untestable or not yet checkable"
        done < <(criteria_of "$file" "$line")
    done < <(rounds_of "$file")
}

# ---------------------------------------------------------------------------------------------
# Links between files, close.md's rounds, and the finished workflow.
# ---------------------------------------------------------------------------------------------

# link_of <file> <heading-line>: the round's first send-back parenthesis outside a fenced block,
# as "send-back <file> <k>" or "after plan.md <k>"; nothing when it has none.
link_of() {
    round_marked_of "$1" "$2" | awk -F'\t' '
        $2 == 1 { next }
        match($3, /\(send-back from [a-z]+\.md round [0-9]+\)/) {
            s = substr($3, RSTART + 16, RLENGTH - 17); sub(/ round /, " ", s)
            print "send-back " s; exit
        }
        match($3, /\(after plan\.md round [0-9]+\)/) {
            s = substr($3, RSTART + 7, RLENGTH - 8); sub(/ round /, " ", s)
            print "after " s; exit
        }'
}

# link_target <file> <name> <n> <target-file> <k>: a drift line when <target-file> is not a
# dossier file, or is present without round <k>. An absent target is not checked.
link_target() {
    local file=$1 name=$2 n=$3 target=$4 k=$5 path
    if [[ $target != *.md || " ${steps[*]} " != *" ${target%.md} "* ]]; then
        finding drift "$name" send-back-link "round $n names $target, not a dossier file"
        return 0
    fi
    path=$(sibling "$file" "$target") || return 0
    round_numbers_of "$path" | grep -qx "$k" \
        || finding drift "$name" send-back-link "round $n names $target round $k, which $target does not have"
    return 0
}

check_send_back_link() {
    local file=$1 name=$2 line n heading first=1 link kind target k
    case $name in
        implement.md | plan.md)
            # Every round after the first; the first is the unheaded lead when there is one.
            [[ -z $(outcome_lead_of "$file") ]] || first=0
            while IFS=$'\t' read -r line n heading; do
                if ((first)); then first=0; continue; fi
                link=$(link_of "$file" "$line")
                kind= target= k=
                [[ -z $link ]] || read -r kind target k <<<"$link"
                if [[ $kind == send-back || ($kind == after && $name == implement.md) ]]; then
                    link_target "$file" "$name" "$n" "$target" "$k"
                elif [[ $name == implement.md ]]; then
                    finding drift "$name" send-back-link "round $n carries no \"(send-back from <file> round <k>)\" or \"(after plan.md round <k>)\""
                else
                    finding drift "$name" send-back-link "round $n carries no \"(send-back from <file> round <k>)\""
                fi
            done < <(rounds_of "$file")
            ;;
        close.md)
            while IFS=$'\t' read -r line n heading; do
                [[ $heading =~ ^Round\ [0-9]+\ —\ pull\ request\ updated ]] || continue
                link=$(link_of "$file" "$line")
                kind= target= k=
                [[ -z $link ]] || read -r kind target k <<<"$link"
                if [[ $kind == send-back ]]; then
                    link_target "$file" "$name" "$n" "$target" "$k"
                else
                    finding drift "$name" send-back-link "round $n carries no \"(send-back from <file> round <k>)\""
                fi
            done < <(rounds_of "$file")
            ;;
        qc.md)
            # A round sent back is followed by a round in the receiving file that names it. The
            # last round is not held to that: its receiver may not have run yet.
            local rounds last route receiver path
            rounds=$(rounds_of "$file")
            last=$(tail -n1 <<<"$rounds" | cut -f1)
            while IFS=$'\t' read -r line n heading; do
                [[ -n $line && $line != "$last" ]] || continue
                route=$(route_of "$(decision_of "$file" "$line")")
                [[ $route == implement || $route == plan ]] || continue
                receiver=$route.md
                path=$(sibling "$file" "$receiver") || continue
                grep -qF "(send-back from qc.md round $n)" "$path" \
                    || finding drift "$name" send-back-link "round $n is routed back to $receiver, but no $receiver round carries \"(send-back from qc.md round $n)\""
            done <<<"$rounds"
            ;;
    esac
    return 0
}

check_qc_round_at_review() {
    local file=$1 name=$2 line n heading k qc
    [[ $name == close.md ]] || return 0
    qc=$(sibling "$file" qc.md) || qc=
    while IFS=$'\t' read -r line n heading; do
        [[ $heading =~ ^Round\ [0-9]+\ —\ (review\ feedback|conflicts\ with\ ) ]] || continue
        k=$(round_marked_of "$file" "$line" | awk -F'\t' '
            $2 == 0 && match($3, /^[ \t]*([-*] )?qc round at review: [0-9]+/) {
                s = substr($3, RSTART, RLENGTH); sub(/.*: /, "", s); print s; exit
            }')
        if [[ -z $k ]]; then
            finding FAIL "$name" qc-round-at-review "round $n carries no \"qc round at review: <k>\""
        elif [[ -n $qc ]] && ! rounds_of "$qc" | cut -f2 | grep -qx "$k"; then
            finding FAIL "$name" qc-round-at-review "round $n names qc round $k, which qc.md does not have"
        fi
    done < <(rounds_of "$file")
}

check_park_heading() {
    local file=$1 name=$2 line level text full
    [[ $name == close.md ]] || return 0
    # A heading that names a round and a stash or an abandon, at any level, is meant as a park
    # and must be one claim.sh --stash-live counts: its park_re, read from claim.sh in Main.
    while IFS=$'\t' read -r line level text; do
        [[ $text =~ ^Round\ [0-9]+ ]] || continue
        grep -q -i -E 'stash|abandon' <<<"$text" || continue
        full="$(printf '%*s' "$level" '' | tr ' ' '#') $text"
        [[ $full =~ $park_re ]] \
            || finding FAIL "$name" park-heading "line $line: \"$full\" is not a park heading claim.sh reads"
    done < <(headings_of "$file")
}

# opened_rounds_of <close-file>: the rounds headed "— pull request opened", as rounds_of rows.
opened_rounds_of() {
    rounds_of "$1" | awk -F'\t' '$3 ~ /^Round [0-9]+ — pull request opened/'
}

check_finished_qc_clear() {
    local file=$1 name=$2 qc
    [[ $name == close.md && -n $(opened_rounds_of "$file") ]] || return 0
    qc=$(sibling "$file" qc.md) || return 0
    last_round_clear "$qc" \
        || finding FAIL "$name" finished-qc-clear "a pull request is opened but qc.md's last round is not clear"
    return 0
}

check_finished_pr() {
    local file=$1 name=$2 opened count line n heading
    [[ $name == close.md ]] || return 0
    opened=$(opened_rounds_of "$file")
    [[ -n $opened ]] || return 0
    count=$(wc -l <<<"$opened")
    ((count == 1)) || finding FAIL "$name" finished-pr "$count rounds headed \"— pull request opened\" (rounds $(cut -f2 <<<"$opened" | paste -sd, - | sed 's/,/, /g')); expected one"
    while IFS=$'\t' read -r line n heading; do
        round_marked_of "$file" "$line" \
            | awk -F'\t' '$2 == 0 && $3 ~ /^#[0-9]+ [a-z]+:\/\/[^ \t]+[ \t]*$/ { found = 1 } END { exit !found }' \
            || finding FAIL "$name" finished-pr "round $n records no \"#<number> <url>\" line"
    done <<<"$opened"
}

check_env_form() {
    local file=$1 name=$2 line f text bare want
    [[ $name == implement.md || $name == qc.md ]] || return 0
    while IFS=$'\t' read -r line f text; do
        [[ $f == 0 ]] || continue
        # A line that reads as a form line once list, quote and bold markers are set aside.
        bare=$(sed -E 's/^[[:space:]>*_+-]+//' <<<"$text")
        bare=${bare,,}
        if [[ $bare =~ ^deployed\ revision[*_\ ]*[:—–-] ]]; then
            want='"Deployed revision: <x>"'
            [[ ! $text =~ ^Deployed\ revision:\ [^[:space:]] ]] || continue
        elif [[ $bare =~ ^lease\ not\ held[*_\ ]*[:—–-] ]]; then
            want='"Lease not held: <x>"'
            [[ ! $text =~ ^Lease\ not\ held:\ [^[:space:]] ]] || continue
        elif [[ $bare =~ ^environment\ (not\ )?released([^[:alnum:]]|$) ]]; then
            want='"Environment released at the clear verdict: <x>" or "Environment NOT released: <x>"'
            [[ ! $text =~ ^Environment\ released\ at\ the\ clear\ verdict:\ [^[:space:]] ]] || continue
            [[ ! $text =~ ^Environment\ NOT\ released:\ [^[:space:]] ]] || continue
        else
            continue
        fi
        finding drift "$name" env-form "line $line: \"$text\" does not start its line as $want"
    done < <(marked_of "$file")
}

checks=(title header_table sections round_numbering log_format log_cost footprint footprint_single open_question
    verdict_span verdict_route blocking_to_close criteria_count criterion_verdict send_back_link
    qc_round_at_review park_heading finished_qc_clear finished_pr env_form)

# ---------------------------------------------------------------------------------------------
# Main.
# ---------------------------------------------------------------------------------------------

usage() {
    echo "dossier-check: $*" >&2
    exit 2
}

(($# == 1)) || usage "usage: dossier-check.sh <dossier-dir>"
dir=$1
[[ -d $dir ]] || usage "not a directory: $dir"

present=()
for step in "${steps[@]}"; do
    [[ ! -f $dir/$step.md ]] || present+=("$step.md")
done
((${#present[@]})) || usage "no dossier files (issue.md init.md plan.md implement.md qc.md close.md) in $dir"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# claim.sh's park heading pattern, read from claim.sh itself so the two cannot diverge.
park_re=$(sed -n "s/^park_re='\(.*\)'\$/\1/p" "$(dirname "${BASH_SOURCE[0]}")/claim.sh" 2>/dev/null || true)
[[ -n $park_re ]] || usage "cannot read park_re from claim.sh beside this script"

# Every file is copied before any check runs: the cross-file checks read a sibling's copy.
for name in "${present[@]}"; do
    tr -d '\r' <"$dir/$name" >"$work/$name"
done
for name in "${present[@]}"; do
    for check in "${checks[@]}"; do
        "check_$check" "$work/$name" "$name"
    done
done

exit "$failed"
