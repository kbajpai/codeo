#!/usr/bin/env bash
# Lints the plugin's skills. Run directly it checks every skill under the repository root (or the
# one named); sourced, it exposes lint_root so tests/skills-lint.test.sh can aim the same checks at
# a scratch plugin tree.
#
#   skills.test.sh [skill]
#       Prints one "FAIL <skill> check <n> <name>: <offender>" line per failure and exits non-zero if
#       there was any; prints "all cases passed" otherwise. A check that has nothing to compare
#       against yet prints a "skipped" line instead.
#
# Checks: (1) frontmatter  (2) precedence sentence  (3) script calls and document references  (4) points  (5) rules
#         (6) config keys
set -euo pipefail

# The retired plugin directory, assembled from parts so the repository-wide guard does not match this file.
old_dir='\.agent''skills'
PRECEDENCE='Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.'

# Prints a failure line. $1 skill, $2 check number, $3 check name, $4 offender.
lint_fail() { printf 'FAIL %s check %s %s: %s\n' "$1" "$2" "$3" "$4"; }

# (1) $1 = SKILL.md path, $2 = skill (directory) name.
lint_frontmatter() {
    local file=$1 skill=$2 fm name desc model
    if [[ "$(sed -n 1p "$file")" != "---" ]] || ! sed -n '2,$p' "$file" | grep -q '^---$'; then
        lint_fail "$skill" 1 frontmatter "no frontmatter block"
        return
    fi
    fm=$(sed -n '2,$p' "$file" | awk '/^---$/{exit} {print}')
    name=$(sed -n 's/^name:[[:space:]]*//p' <<<"$fm" | head -1)
    # A folded or literal block ("description: >") keeps its text on the indented lines below.
    desc=$(awk '/^description:/{sub(/^description:[[:space:]]*/,""); v=$0; d=1; next}
        d && /^[[:space:]]+[^[:space:]]/{gsub(/^[[:space:]]+/,""); v=v $0; next}
        d{d=0} END{gsub(/^[>|][-+]?$/,"",v); print v}' <<<"$fm")
    model=$(sed -n 's/^model:[[:space:]]*//p' <<<"$fm" | head -1)
    [[ "$name" == "$skill" ]] || lint_fail "$skill" 1 frontmatter "name '$name' is not the directory name '$skill'"
    [[ -n "$desc" ]] || lint_fail "$skill" 1 frontmatter "description is empty"
    case "$model" in
        opus | sonnet | fable | haiku) ;;
        *) lint_fail "$skill" 1 frontmatter "model '$model' is not opus, sonnet, fable or haiku" ;;
    esac
}

# The body: everything after the closing frontmatter line.
lint_body() { awk 'c>=2{print} /^---$/ && c<2{c++}' "$1"; }

# (2)
lint_precedence() {
    local file=$1 skill=$2 first
    first=$(lint_body "$file" | grep -v '^[[:space:]]*$' | head -1 || true)
    [[ "$first" == "$PRECEDENCE" ]] || lint_fail "$skill" 2 precedence "first body line is '$first'"
}

# (3) $3 = plugin root.
lint_scripts() {
    local file=$1 skill=$2 root=$3 call stripped leftovers
    while IFS= read -r call; do
        [[ -n "$call" ]] || continue
        [[ -f "$root/scripts/$call" ]] || lint_fail "$skill" 3 script-calls "scripts/$call does not exist"
    done < <(grep -oE 'bash "\$\{CLAUDE_PLUGIN_ROOT\}/scripts/[A-Za-z0-9_.-]+\.sh"' "$file" |
        sed -E 's#.*/scripts/([^"]+)"#\1#' || true)
    # A document the skill cites by its plugin path must be shipped.
    while IFS= read -r call; do
        [[ -n "$call" ]] || continue
        [[ -f "$root/docs/$call" ]] || lint_fail "$skill" 3 script-calls "docs/$call does not exist"
    done < <(grep -oE '\$\{CLAUDE_PLUGIN_ROOT\}/docs/[A-Za-z0-9_.-]+\.md' "$file" |
        sed -E 's#.*/docs/##' | sort -u || true)
    # What is left once the one allowed call form is removed must name no script at all.
    stripped=$(sed -E 's#bash "\$\{CLAUDE_PLUGIN_ROOT\}/scripts/[A-Za-z0-9_.-]+\.sh"##g' "$file")
    leftovers=$(grep -oE "$old_dir"'[^[:space:]]*|[^[:space:]]*scripts/[^[:space:]]*\.sh[^[:space:]]*|\$\{CLAUDE_PLUGIN_ROOT\}/scripts[^[:space:]]*' <<<"$stripped" || true)
    while IFS= read -r call; do
        [[ -n "$call" ]] && lint_fail "$skill" 3 script-calls "other script form: $call"
    done <<<"$leftovers"
    return 0
}

# (4) $3 = plugin root.
lint_points() {
    local file=$1 skill=$2 root=$3 tsv="$3/lib/extension-points.tsv" doc="$3/docs/extension-points.md"
    local marker rows row n doc_missing=0
    if [[ ! -f "$tsv" ]]; then
        lint_fail "$skill" 4 points "registry lib/extension-points.tsv is missing"
        return
    fi
    while IFS= read -r marker; do
        [[ -n "$marker" ]] || continue
        if ! awk -F'\t' -v s="${marker%%/*}" -v p="${marker#*/}" '$1==s && $2==p{f=1} END{exit !f}' "$tsv" ||
            [[ "${marker%%/*}" != "$skill" ]]; then
            lint_fail "$skill" 4 points "marker $marker is not a registry row for this skill"
        fi
    done < <(grep -oE '<!-- point: [^ ]+ -->' "$file" | sed -E 's/<!-- point: ([^ ]+) -->/\1/' || true)
    rows=$(awk -F'\t' -v s="$skill" '$1==s{print $2}' "$tsv")
    [[ -f "$doc" ]] || doc_missing=1
    while IFS= read -r row; do
        [[ -n "$row" ]] || continue
        # -o puts each marker on its own line, so two on one line count as two.
        n=$(grep -oF "<!-- point: $skill/$row -->" "$file" | wc -l)
        if [[ "$n" -eq 0 ]]; then
            lint_fail "$skill" 4 points "registry row $skill/$row has no marker"
        elif [[ "$n" -gt 1 ]]; then
            lint_fail "$skill" 4 points "registry row $skill/$row appears $n times"
        fi
        if [[ "$doc_missing" -eq 0 ]] && ! grep -qxF "### $skill/$row" "$doc"; then
            lint_fail "$skill" 4 points "docs/extension-points.md has no '### $skill/$row' heading"
        fi
    done <<<"$rows"
    if [[ "$doc_missing" -eq 1 && -n "$rows" ]]; then
        echo "skipped $skill check 4 points (docs/extension-points.md not written yet)"
    fi
}

# (5) $3 = plugin root.
lint_rules() {
    local file=$1 skill=$2 inv="$3/docs/skills-inventory.md" want got id n
    want=$(grep -oE "^- \[$skill-[0-9]+\]" "$inv" 2>/dev/null | sed -E 's/^- \[(.*)\]/\1/' | sort || true)
    if [[ -z "$want" ]]; then
        echo "skipped $skill check 5 rules (no inventory IDs yet)"
        return
    fi
    got=$(grep -oE '<!-- rule: [^ ]+ -->' "$file" | sed -E 's/<!-- rule: ([^ ]+) -->/\1/' | sort || true)
    while IFS= read -r id; do
        [[ -n "$id" ]] || continue
        n=$(grep -cxF "$id" <<<"$got" || true)
        if [[ "$n" -eq 0 ]]; then
            lint_fail "$skill" 5 rules "inventory rule $id has no marker"
        elif [[ "$n" -gt 1 ]]; then
            lint_fail "$skill" 5 rules "rule $id appears $n times"
        fi
    done <<<"$want"
    while IFS= read -r id; do
        [[ -n "$id" ]] || continue
        grep -qxF "$id" <<<"$want" || lint_fail "$skill" 5 rules "marker $id is not in the inventory"
    done < <(sort -u <<<"$got")
}

# (6) Every identifier in a config.sh get filter must appear as a word in lib/env.sh's header.
lint_config_keys() {
    local file=$1 skill=$2 root=$3 header line tail filter scrubbed seg
    header=$(awk 'NR>1 && !/^#/{exit} {print}' "$root/lib/env.sh" 2>/dev/null || true)
    # One call per line, so several on a source line are all seen.
    while IFS= read -r line; do
        [[ "$line" =~ ^config\.sh\"?[[:space:]]+get[[:space:]]+(.*)$ ]] || continue
        tail=${BASH_REMATCH[1]}
        # Options such as -r come before the filter.
        while [[ "$tail" == -* ]]; do
            [[ "$tail" == *[[:space:]]* ]] || { tail=""; break; }
            tail=${tail#*[[:space:]]}
            tail=${tail#"${tail%%[![:space:]]*}"}
        done
        case "$tail" in
            \'*) filter=$(sed -E "s/^'([^']*)'.*/\1/" <<<"$tail") ;;
            \"*) filter=$(sed -E 's/^"(([^"\\]|\\.)*)".*/\1/' <<<"$tail"); filter=${filter//\\\"/\"} ;;
            *)
                filter=${tail%%[[:space:]]*}
                filter=${filter%%\`*}
                while [[ "$filter" == *[\),\;.] ]]; do filter=${filter%?}; done
                ;;
        esac
        [[ -n "$filter" ]] || continue
        if [[ "$filter" == *'$'* ]]; then
            echo "$skill check 6 skipped for a dynamic filter: $filter"
            continue
        fi
        # String literals are data, not paths.
        scrubbed=$(sed -E 's/"[^"]*"/""/g' <<<"$filter")
        while IFS= read -r seg; do
            [[ -n "$seg" ]] || continue
            seg=${seg#.}
            grep -qw -- "$seg" <<<"$header" ||
                lint_fail "$skill" 6 config-keys "'$seg' (in $filter) is not documented in lib/env.sh"
        done < <(grep -oE '\.[A-Za-z_][A-Za-z0-9_]*' <<<"$scrubbed" | sort -u || true)
    done < <(sed 's/config\.sh/\nconfig.sh/g' "$file")
}

# Lints the skills under plugin root $1 (all, or only $2). Prints failure and skipped lines.
lint_root() {
    local root=$1 only=${2:-} dir skill file clean
    for dir in "$root"/skills/*/; do
        skill=$(basename "$dir")
        [[ -z "$only" || "$only" == "$skill" ]] || continue
        file="$dir/SKILL.md"
        if [[ ! -f "$file" ]]; then
            lint_fail "$skill" 1 frontmatter "SKILL.md is missing"
            continue
        fi
        # CRLF files are linted as their LF equivalent.
        clean=$(mktemp)
        tr -d '\r' <"$file" >"$clean"
        file=$clean
        lint_frontmatter "$file" "$skill"
        lint_precedence "$file" "$skill"
        lint_scripts "$file" "$skill" "$root"
        lint_points "$file" "$skill" "$root"
        lint_rules "$file" "$skill" "$root"
        lint_config_keys "$file" "$skill" "$root"
        rm -f "$clean"
    done
}

# Only when executed, not when sourced by the self-test.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
    if [[ -n "${1:-}" && ! -d "$repo/skills/$1" ]]; then
        echo "no such skill: $1" >&2
        exit 1
    fi
    out=$(lint_root "$repo" "${1:-}")
    [[ -z "$out" ]] || echo "$out"
    if grep -q '^FAIL' <<<"$out"; then
        exit 1
    fi
    echo "all cases passed"
fi
