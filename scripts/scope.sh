#!/usr/bin/env bash
# Which test suites a change needs — one rule for CI and the local quality gate, so they cannot
# disagree about what a change touches.
#
#   scope.sh <base> <head>
#       Run from the project root. Diffs <base>...<head> and prints, in GITHUB_OUTPUT's key=value
#       form, one line per configured suite:
#         suite.<name>=true|false
#       and, only when `environment` is configured, whether the change touches its resource:
#         deploy=true|false
#       followed on stderr by the paths that decided each true. With no suites configured it
#       prints nothing and exits 0. Renames are off (`--no-renames`), so a rename lists both its
#       old and its new path and a deletion counts.
#
#   The rule: paths matching `skipGlobs` are ignored; a suite is true if any remaining path
#   matches one of its `paths`; a remaining path matching NO suite's `paths` makes EVERY suite
#   true. The skip list names what is safe to ignore rather than what is code, so a path nobody
#   thought about runs everything: missing a skip costs minutes, missing a run ships a broken build.
#   `deploy` looks at every changed path, skipped or not, against the `paths` of the entry in
#   `resources` that `environment.resource` names.
#
#   Glob semantics (matched against the whole repo-relative path, "/" separated):
#     *    any run of characters within one path segment (never "/")
#     ?    one character within a segment
#     **   any run of characters across segments; "**/" also matches no directory at all,
#          so "src/**/x.cs" matches "src/x.cs"
#     everything else is literal (no brackets, braces or extglob)
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

if [[ $# -ne 2 ]]; then
    echo "usage: scope.sh <base> <head>" >&2
    exit 1
fi

# Translates a glob to an anchored extended regex, one character at a time so that a path
# containing regex metacharacters or spaces is matched literally.
glob_to_regex() {
    local glob=$1 re='' i=0 c
    while ((i < ${#glob})); do
        c=${glob:i:1}
        if [[ $c == '*' ]]; then
            if [[ ${glob:i:2} == '**' ]]; then
                if [[ ${glob:i+2:1} == '/' ]]; then
                    re+='(.*/)?'
                    i=$((i + 3))
                else
                    re+='.*'
                    i=$((i + 2))
                fi
            else
                re+='[^/]*'
                i=$((i + 1))
            fi
            continue
        elif [[ $c == '?' ]]; then
            re+='[^/]'
        elif [[ $c =~ [][\\.^\$+\(\)\{\}\|] ]]; then
            re+="\\$c"
        else
            re+=$c
        fi
        i=$((i + 1))
    done
    printf '^%s$' "$re"
}

# matches_any <path> <regex>... — success when the path matches one of the regexes.
matches_any() {
    local path=$1 re
    shift
    for re in "$@"; do
        if [[ $path =~ $re ]]; then return 0; fi
    done
    return 1
}

# Reads the glob list printed by a codeo_cfg filter into the named array; empty when absent.
read_globs() {
    local -n out=$1
    local line regexes
    out=()
    regexes=$(codeo_cfg "$2" || true)
    while IFS= read -r line; do
        if [[ -n $line ]]; then out+=("$(glob_to_regex "$line")"); fi
    done <<<"$regexes"
}

suite_names=()
if names=$(codeo_cfg '.suites[]?.name'); then
    while IFS= read -r line; do suite_names+=("$line"); done <<<"$names"
fi
# Nothing to decide; answering would only invent suites.
if [[ ${#suite_names[@]} -eq 0 ]]; then
    exit 0
fi

# -z keeps a path with a newline or unusual bytes in one piece, unquoted.
changed=()
while IFS= read -r -d '' path; do
    changed+=("$path")
done < <(git diff --name-only -z --no-renames "$1...$2")

read_globs skip_res '.skipGlobs[]?'

remaining=()
for path in "${changed[@]}"; do
    if ! matches_any "$path" "${skip_res[@]}"; then
        remaining+=("$path")
    fi
done

# One array of regexes per suite, by index; bash has no nested arrays.
declare -A suite_deciding=()   # suite index -> newline list of deciding paths
unknown=()
for path in "${remaining[@]}"; do
    known=false
    for i in "${!suite_names[@]}"; do
        read_globs suite_res ".suites[$i].paths[]?"
        if matches_any "$path" "${suite_res[@]}"; then
            known=true
            suite_deciding[$i]+="$path"$'\n'
        fi
    done
    if [[ $known != true ]]; then unknown+=("$path"); fi
done

for i in "${!suite_names[@]}"; do
    name=${suite_names[$i]}
    deciding=${suite_deciding[$i]:-}
    if [[ ${#unknown[@]} -gt 0 ]]; then
        # Fail-safe: a path no suite claims could affect any of them.
        printf 'scope: suite %s needed for unclassified paths:\n' "$name" >&2
        printf '  %s\n' "${unknown[@]}" >&2
        echo "suite.$name=true"
    elif [[ -n $deciding ]]; then
        printf 'scope: suite %s needed for:\n' "$name" >&2
        printf '%s' "$deciding" | sed 's/^/  /' >&2
        echo "suite.$name=true"
    else
        echo "suite.$name=false"
    fi
done

if resource=$(codeo_cfg '.environment.resource'); then
    # Escape the name for jq by passing it as an argument rather than splicing it into the filter.
    deploy_paths=$(jq -r --arg r "$resource" '.resources[]? | select(.name == $r) | .paths[]?' "$CODEO_STATE_DIR/config.json")
    deploy_res=()
    while IFS= read -r line; do
        if [[ -n $line ]]; then deploy_res+=("$(glob_to_regex "$line")"); fi
    done <<<"$deploy_paths"
    deploy=false
    for path in "${changed[@]}"; do
        if matches_any "$path" "${deploy_res[@]}"; then
            deploy=true
            echo "scope: deploy needed for: $path" >&2
        fi
    done
    echo "deploy=$deploy"
fi
