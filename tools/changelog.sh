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
    [[ $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ && $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || usage
    if [[ ! -f $changelog ]]; then
        echo "changelog: no CHANGELOG.md here" >&2
        exit 1
    fi
    mapfile -t frags < <(fragment_paths)
    if ((${#frags[@]} == 0)); then
        echo "changelog: no fragments in $dir" >&2
        exit 1
    fi

    if awk -v h="## $version —" 'index($0, h) == 1 { found = 1 } END { exit !found }' "$changelog"; then
        echo "changelog: $changelog already has a section for $version" >&2
        exit 1
    fi
    if grep -qE -- "^## Unreleased([[:space:]]|\$)" "$changelog"; then
        echo "changelog: $changelog has an ## Unreleased heading; fold it into a fragment first" >&2
        exit 1
    fi

    schema= schema_from= safe= yes_notes= shared= safe_no= safe_reasons= safe_other= lc=
    body=
    blank_tail=$'\n''[[:blank:]]*'$'\n''$'
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
                    v=${v#"${v%%[![:space:]]*}"}
                    v=${v%"${v##*[![:space:]]}"}
                    lc=${v,,}
                    if [[ -z $v || $lc =~ ^yes($|[^[:alnum:]_]) ]]; then
                        if [[ -n $v && $lc != yes ]]; then
                            case "; $yes_notes; " in *"; $v; "*) ;; *) yes_notes=${yes_notes:+$yes_notes; }$v ;; esac
                        fi
                    elif [[ $lc =~ ^no($|[^[:alnum:]_]) ]]; then
                        safe_no=1
                        [[ $v =~ ^[Nn][Oo][[:space:]]*(—|-|:|,)?[[:space:]]*(.*)$ ]]
                        [[ -z ${BASH_REMATCH[2]} ]] || safe_reasons=${safe_reasons:+$safe_reasons; }${BASH_REMATCH[2]}
                    else
                        safe_other=${safe_other:+$safe_other; }$v
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
            [[ -n $frag_body || -n $line ]] || continue
            frag_body+=$line$'\n'
        done < "$f"
        while [[ $frag_body =~ $blank_tail ]]; do frag_body=${frag_body%$'\n'}; frag_body=${frag_body%$'\n'*}$'\n'; done
        body+=$frag_body
    done

    if [[ -z $schema ]]; then
        newest=$(awk '/^## v/ { if (seen) exit; seen = 1; next } seen && /^Config schema: / { sub(/^Config schema: /, ""); print; exit }' "$changelog")
        if [[ $newest =~ ^([0-9]+) ]]; then
            schema="${BASH_REMATCH[1]} (unchanged)"
        else
            echo "changelog: cannot read Config schema from CHANGELOG.md; say it in a fragment" >&2
            exit 1
        fi
    fi

    section=$(mktemp)
    out=$(mktemp)
    trap 'rm -f "$section" "$out"' EXIT
    safe_line=${yes_notes:-yes}
    if [[ -n $safe_no ]]; then
        safe_line=no
        [[ -z $safe_reasons && -z $safe_other ]] || safe_line="no — ${safe_reasons}${safe_reasons:+${safe_other:+; }}$safe_other"
    elif [[ -n $safe_other ]]; then
        safe_line=$safe_other
    fi
    {
        printf '## %s — %s\n\n' "$version" "$date"
        printf 'Config schema: %s\n' "$schema"
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
