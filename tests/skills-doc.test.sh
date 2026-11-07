#!/usr/bin/env bash
# Guards docs/skills.md: every skill under skills/ has its own "## <skill>" section with the four
# sub-headings (Purpose and triggers, Reads and writes, Hand-offs and non-goals, Extension points),
# no section names a skill that does not exist, and each section's Extension points bullets
# (`- `<skill>/<point>``) are exactly the points lib/extension-points.tsv registers for that skill
# (or "None." when it registers none). Headings inside a ``` fence do not count; CRLF is tolerated.
#
#   bash tests/skills-doc.test.sh
#
# Exits 0 and prints "all cases passed" when the scratch cases and the repository check pass; prints
# one "FAIL <check>: <detail>" line per problem and exits 1 otherwise.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# check_skills_doc <skills_dir> <doc> <tsv>: prints FAIL lines; always returns 0.
check_skills_doc() {
    local skills_dir=$1 doc=$2 tsv=$3
    if [[ ! -f "$doc" ]]; then
        printf 'FAIL doc-missing: %s/%s\n' "$(basename "$(dirname "$doc")")" "$(basename "$doc")"
        return 0
    fi
    if [[ ! -f "$tsv" ]]; then
        printf 'FAIL tsv-missing: %s\n' "$tsv"
        return 0
    fi

    local d s x
    local skills=""
    for d in "$skills_dir"/*/; do
        [[ -d "$d" ]] || continue
        skills+="$(basename "$d")"$'\n'
    done

    # Level-2 headings outside a fence: any with no skill directory is unknown.
    local headings
    headings=$(awk '
        { sub(/\r$/, "") }
        /^```/ { fence = !fence; next }
        !fence && /^## / { print substr($0, 4) }
    ' "$doc")

    while IFS= read -r s; do
        [[ -n "$s" ]] || continue
        grep -Fxq -- "$s" <<<"$headings" || printf 'FAIL missing-section: %s\n' "$s"
    done <<<"$skills"
    while IFS= read -r x; do
        [[ -n "$x" ]] || continue
        [[ -d "$skills_dir/$x" ]] || printf 'FAIL unknown-section: %s\n' "$x"
    done <<<"$headings"

    local info want got line n name part
    while IFS= read -r s; do
        [[ -n "$s" ]] || continue
        grep -Fxq -- "$s" <<<"$headings" || continue
        # Per skill: P <heading> per ### part, B <line> per bullet and N <line> per non-blank line
        # of the Extension points part.
        info=$(awk -v s="$s" '
            { sub(/\r$/, "") }
            /^```/ { fence = !fence }
            !fence && /^## / { insec = ($0 == "## " s); part = ""; next }
            !insec { next }
            !fence && /^### / { part = substr($0, 5); print "P " part; next }
            part == "Extension points" && $0 ~ /[^[:space:]]/ {
                print "N " $0
                if ($0 ~ /^- /) print "B " $0
            }
        ' "$doc")
        for part in "Purpose and triggers" "Reads and writes" "Hand-offs and non-goals" "Extension points"; do
            n=$(grep -cFx -- "P $part" <<<"$info" || true)
            [[ "$n" -eq 1 ]] || printf 'FAIL missing-part: %s ### %s\n' "$s" "$part"
        done
        grep -Fxq -- "P Extension points" <<<"$info" || continue

        want=$(awk -F'\t' -v s="$s" '{ sub(/\r$/, "") } $1 == s { print $2 }' "$tsv" | sort)
        got=""
        while IFS= read -r line; do
            [[ "$line" == "B "* ]] || continue
            line=${line#B }
            if [[ "$line" =~ ^-\ \`$s/([^\`/[:space:]]+)\` ]]; then
                got+="$s/${BASH_REMATCH[1]}"$'\n'
            else
                printf 'FAIL points: %s malformed %s\n' "$s" "$line"
            fi
        done <<<"$info"

        if [[ -z "$want" ]]; then
            # No registered points: the part must be exactly "None.".
            n=$(grep -c '^N ' <<<"$info" || true)
            if [[ "$n" -ne 1 ]] || ! grep -Fxq 'N None.' <<<"$info"; then
                printf 'FAIL points: %s expected None.\n' "$s"
            fi
            continue
        fi
        want=$(sed "s|^|$s/|" <<<"$want")
        # Compare as multisets so a duplicated bullet is reported as extra.
        local -A wc=() gc=()
        while IFS= read -r x; do
            [[ -n "$x" ]] || continue
            wc[$x]=$(( ${wc[$x]:-0} + 1 ))
        done <<<"$want"
        while IFS= read -r x; do
            [[ -n "$x" ]] || continue
            gc[$x]=$(( ${gc[$x]:-0} + 1 ))
        done <<<"$got"
        local k i
        for k in "${!wc[@]}"; do
            for ((i = ${gc[$k]:-0}; i < wc[$k]; i++)); do printf 'FAIL points: %s missing %s\n' "$s" "$k"; done
        done
        for k in "${!gc[@]}"; do
            for ((i = ${wc[$k]:-0}; i < gc[$k]; i++)); do printf 'FAIL points: %s extra %s\n' "$s" "$k"; done
        done
    done <<<"$skills"
    return 0
}

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/skills/alpha" "$scratch/skills/beta" "$scratch/lib"
: >"$scratch/skills/alpha/SKILL.md"
: >"$scratch/skills/beta/SKILL.md"
printf 'alpha\tp1\tdefault\n' >"$scratch/lib/extension-points.tsv"
tsv="$scratch/lib/extension-points.tsv"
doc="$scratch/skills.md"

# section <skill> <extension-points body>: one skill's section with the four parts.
section() {
    printf '## %s\n\n### Purpose and triggers\n\nx\n\n### Reads and writes\n\nx\n\n### Hand-offs and non-goals\n\nx\n\n### Extension points\n\n%s\n\n' "$1" "$2"
}
good_alpha=$(section alpha '- `alpha/p1` — the default')
good_beta=$(section beta 'None.')
good="$good_alpha"$'\n'"$good_beta"

cases_failed=0
# expect <case> <substring|""> <doc> [tsv]: "" means the checker must print nothing at all.
expect() {
    local name=$1 want=$2 out
    out=$(check_skills_doc "$scratch/skills" "$3" "${4:-$tsv}")
    if [[ -z "$want" ]]; then
        [[ -z "$out" ]] || { printf 'FAIL: %s printed: %s\n' "$name" "$out"; cases_failed=1; }
    else
        grep -Fq -- "$want" <<<"$out" || { printf 'FAIL: %s wanted "%s", got: %s\n' "$name" "$want" "$out"; cases_failed=1; }
    fi
}

printf '%s\n' "$good" >"$doc"
expect good "" "$doc"
sed 's/$/\r/' "$doc" >"$scratch/crlf.md"
expect crlf "" "$scratch/crlf.md"
{ printf '%s\n' "$good_alpha"; printf '```\n## gamma\n```\n'; printf '%s\n' "$good_beta"; } >"$scratch/fenced.md"
expect fenced "" "$scratch/fenced.md"
printf '%s\n' "$good_alpha" >"$scratch/nobeta.md"
expect missing-section "FAIL missing-section: beta" "$scratch/nobeta.md"
{ printf '%s\n' "$good"; printf '## gamma\n'; } >"$scratch/gamma.md"
expect unknown-section "FAIL unknown-section: gamma" "$scratch/gamma.md"
{ printf '%s\n' "$good_alpha" | sed 's/^### Reads and writes$/### Something else/'; printf '%s\n' "$good_beta"; } >"$scratch/nopart.md"
expect missing-part "FAIL missing-part: alpha ### Reads and writes" "$scratch/nopart.md"
{ printf '%s\n' "$(section alpha $'- `alpha/p1` — a\n- `alpha/p2` — b')"; printf '%s\n' "$good_beta"; } >"$scratch/extra.md"
expect extra "FAIL points: alpha extra alpha/p2" "$scratch/extra.md"
{ printf '%s\n' "$(section alpha $'- `alpha/p1` — a\n- `alpha/p1` — b')"; printf '%s\n' "$good_beta"; } >"$scratch/dup.md"
expect duplicate "FAIL points: alpha extra alpha/p1" "$scratch/dup.md"
{ printf '%s\n' "$(section alpha $'- `alpha/p1` — a\n- `beta/p1` — b')"; printf '%s\n' "$good_beta"; } >"$scratch/mal.md"
expect malformed "FAIL points: alpha malformed" "$scratch/mal.md"
{ printf '%s\n' "$good_alpha"; printf '%s\n' "$(section beta '- `beta/p9`')"; } >"$scratch/none.md"
expect none "FAIL points: beta" "$scratch/none.md"
expect no-tsv "FAIL tsv-missing" "$doc" "$scratch/absent.tsv"
[[ "$cases_failed" -eq 0 ]] || exit 1

out=$(check_skills_doc "$repo/skills" "$repo/docs/skills.md" "$repo/lib/extension-points.tsv")
if [[ -n "$out" ]]; then
    printf '%s\n' "$out"
    exit 1
fi
echo "all cases passed"
