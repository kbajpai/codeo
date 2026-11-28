#!/usr/bin/env bash
# Assembles per-issue changelog fragments (changelog.d/<N>.md) into CHANGELOG.md at release time.
# Run from the repository root; this repository only, not part of the shipped plugin scripts.
#
#   changelog.sh assemble vX.Y.Z YYYY-MM-DD
#       Inserts the section for the release above the first "## v" heading of CHANGELOG.md, built from
#       every fragment in numeric order, then deletes the fragments. Writes nothing on an error.
#   changelog.sh cat
#       Prints CHANGELOG.md, then every fragment.
#
# A fragment is optional header lines (Config schema: / Shared state: / Safe to bump mid-workflow:),
# a blank line, then the body. Exit 1 on a refusal, 2 on a bad call.
set -euo pipefail

usage() { echo "usage: changelog.sh assemble vX.Y.Z YYYY-MM-DD | changelog.sh cat" >&2; exit 2; }

changelog=CHANGELOG.md
dir=changelog.d

# Prints the fragment paths in numeric order.
fragment_paths() {
    local f n
    for f in "$dir"/[0-9]*.md; do
        [[ -e $f ]] || continue
        n=$(basename "$f" .md)
        [[ $n =~ ^[0-9]+$ ]] || continue
        printf '%s %s\n' "$n" "$f"
    done | sort -n | cut -d' ' -f2-
}

case "${1:-}" in
cat)
    (($# == 1)) || usage
    cat "$changelog"
    while IFS= read -r f; do
        printf '\n'
        cat "$f"
    done < <(fragment_paths)
    ;;
assemble)
    (($# == 3)) || usage
    version=$2 date=$3
    mapfile -t frags < <(fragment_paths)
    if ((${#frags[@]} == 0)); then
        echo "changelog: no fragments in $dir" >&2
        exit 1
    fi

    if awk -v h="## $version —" 'index($0, h) == 1 { found = 1 } END { exit !found }' "$changelog"; then
        echo "changelog: $changelog already has a section for $version" >&2
        exit 1
    fi
    if grep -q -- "^## Unreleased" "$changelog"; then
        echo "changelog: $changelog has an ## Unreleased heading; fold it into a fragment first" >&2
        exit 1
    fi

    schema= schema_from= safe= shared= safe_no= safe_reasons=
    body=
    for f in "${frags[@]}"; do
        n=$(basename "$f" .md)
        in_header=1
        frag_body=
        while IFS= read -r line || [[ -n $line ]]; do
            line=${line%$'\r'}
            if ((in_header)); then
                case $line in
                "Config schema: "*)
                    v=${line#"Config schema: "}
                    if [[ -n $schema && $schema != "$v" ]]; then
                        echo "changelog: fragments disagree on Config schema: #$schema_from says $schema, #$n says $v" >&2
                        exit 1
                    fi
                    schema=$v schema_from=$n
                    continue ;;
                "Safe to bump mid-workflow: "*)
                    v=${line#"Safe to bump mid-workflow: "}
                    if [[ $v == no ]]; then
                        safe_no=1
                    elif [[ $v == "no — "* ]]; then
                        safe_no=1
                        safe_reasons=${safe_reasons:+$safe_reasons; }${v#"no — "}
                    elif [[ -z $safe ]]; then
                        safe=$v
                    fi
                    continue ;;
                "Shared state: "*)
                    v=${line#"Shared state: "}
                    if [[ $v != none && -n $v ]]; then
                        shared=${shared:+$shared; }$v
                    fi
                    continue ;;
                "") in_header=0; continue ;;
                esac
                in_header=0
            fi
            frag_body+=$line$'\n'
        done < "$f"
        while [[ $frag_body == *$'\n\n' ]]; do frag_body=${frag_body%$'\n'}; done
        body+=$frag_body
    done

    section=$(mktemp)
    out=$(mktemp)
    trap 'rm -f "$section" "$out"' EXIT
    safe_line=${safe:-yes}
    if [[ -n $safe_no ]]; then
        safe_line=no
        [[ -z $safe_reasons ]] || safe_line="no — $safe_reasons"
    fi
    {
        printf '## %s — %s\n\n' "$version" "$date"
        printf 'Config schema: %s\n' "${schema:-1 (unchanged)}"
        printf 'Shared state: %s\n' "${shared:-none}"
        printf 'Safe to bump mid-workflow: %s\n\n' "$safe_line"
        printf '%s\n' "${body%$'\n'}"
    } > "$section"

    awk -v sec="$section" '
        !done && /^## v/ {
            while ((getline l < sec) > 0) print l
            print ""
            done = 1
        }
        { print }
        END {
            if (!done) {
                print ""
                while ((getline l < sec) > 0) print l
            }
        }' "$changelog" > "$out"
    cat "$out" > "$changelog"
    rm -f "${frags[@]}"
    ;;
*)
    usage
    ;;
esac
