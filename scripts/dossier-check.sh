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

checks=(title header_table sections round_numbering log_format log_cost footprint footprint_single open_question)

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

for name in "${present[@]}"; do
    tr -d '\r' <"$dir/$name" >"$work/$name"
    for check in "${checks[@]}"; do
        "check_$check" "$work/$name" "$name"
    done
done

exit "$failed"
