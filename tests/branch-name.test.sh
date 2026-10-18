#!/usr/bin/env bash
# Exercises scripts/branch-name.sh: the type from the labels (the defaults and the config's
# labelTypes), the slug from the title (bracket group, case, separators, stop words, five-word cap,
# glob characters), and the refusal when no words are left. Makes no network call: the script runs
# from a scratch copy of the plugin whose github.sh is a stub that answers `issue view <N>` from
# canned JSON in the shape the real one prints ({number, title, labels: [names]}).
#
#   branch-name.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

scratch_root=$(mktemp -d)
cleanup() { rm -rf "$scratch_root"; }
trap cleanup EXIT

export HOME="$scratch_root/home"
mkdir -p "$HOME"

# A scratch plugin: the script under test and the library it sources, with the stub beside them.
fake_plugin="$scratch_root/plugin"
mkdir -p "$fake_plugin/scripts" "$fake_plugin/lib"
cp "$plugin_root/scripts/branch-name.sh" "$fake_plugin/scripts/"
cp "$plugin_root/lib/env.sh" "$fake_plugin/lib/"
canned_dir="$scratch_root/canned"
mkdir -p "$canned_dir"
export CANNED_DIR="$canned_dir"
cat > "$fake_plugin/scripts/github.sh" <<'STUB'
#!/usr/bin/env bash
[[ ${1:-} == issue && ${2:-} == view ]] || { echo "stub github.sh: unexpected: $*" >&2; exit 1; }
cat "${CANNED_DIR:?}/$3.json" 2>/dev/null || { echo "stub github.sh: no issue $3" >&2; exit 1; }
STUB

# The project: a repo with a config, and a few files so an unquoted glob would have something to hit.
project="$scratch_root/project"
mkdir -p "$project/.codeo"
git -C "$project" init -q
touch "$project/alpha.sh" "$project/beta.sh" "$project/x"
write_config() {
    printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"%s}\n' "${1:+,$1}" > "$project/.codeo/config.json"
}
write_config

failures=0
case_desc=
assert_eq() {
    local label=$1 want=$2 got=$3
    if [[ $want != "$got" ]]; then
        echo "FAIL: $case_desc — $label: want [$want] got [$got]"
        failures=$((failures + 1))
    fi
}
assert_contains() {
    local label=$1 needle=$2 haystack=$3
    if [[ $haystack != *"$needle"* ]]; then
        echo "FAIL: $case_desc — $label: want substring [$needle] in [$haystack]"
        failures=$((failures + 1))
    fi
}

# canned <N> <title> [label...] — the shape github.sh issue view prints.
canned() {
    local n=$1 title=$2 labels
    shift 2
    labels=$(printf '%s\n' "$@" | jq -R 'select(length > 0)' | jq -s -c .)
    jq -n -c --argjson n "$n" --arg t "$title" --argjson l "$labels" \
        '{number: $n, title: $t, state: "open", labels: $l, assignees: []}' > "$canned_dir/$n.json"
}

run_name() { (cd "$project" && bash "$fake_plugin/scripts/branch-name.sh" "$1"); }

case_desc="branch-name.sh"
canned 120 '[Task] Work through the backlog of pipeline and environment chores (consolidates #72, #73)' enhancement ci
assert_eq "#120" "feat/work-backlog-pipeline-environment-chores" "$(run_name 120)"
canned 73 '[Task] Refuse a lease while the environment carries migrations the incoming branch does not have' enhancement
assert_eq "#73" "feat/refuse-lease-while-environment-carries" "$(run_name 73)"
canned 5 'Fix the thing' bug
assert_eq "bug label" "fix/fix-thing" "$(run_name 5)"
canned 6 'Docs: a page' documentation
assert_eq "documentation label" "docs/docs-page" "$(run_name 6)"
canned 7 'Three words only'
assert_eq "no type label, fewer than five words" "chore/three-words-only" "$(run_name 7)"
canned 8 'Fix   the---THING!!   now  '
assert_eq "runs of separators and case" "chore/fix-thing-now" "$(run_name 8)"
canned 9 '[Bug] the of a'
status=0; out=$(run_name 9 2>&1) || status=$?
assert_eq "nothing left: exit" 1 "$status"
assert_contains "nothing left: message" "no words left" "$out"
assert_eq "same input, same name" "$(run_name 120)" "$(run_name 120)"

case_desc="the config's labelTypes replace the defaults"
write_config '"labelTypes":{"story":"feat","defect":"fix"}'
canned 10 'Add a widget' story
assert_eq "mapped label" "feat/add-widget" "$(run_name 10)"
canned 11 'Add a widget' defect enhancement
assert_eq "first mapped label wins" "fix/add-widget" "$(run_name 11)"
canned 12 'Add a widget' enhancement
assert_eq "a default no longer mapped is chore" "chore/add-widget" "$(run_name 12)"
write_config

case_desc="branch_name_quotes_a_title_with_spaces_and_glob_characters"
canned 13 'Handle * and [x]? in "my file" *.sh' bug
assert_eq "glob characters stay inert" "fix/handle-x-my-file-sh" "$(run_name 13)"
canned 14 '* ? [a-z]* x' 
assert_eq "only glob characters and a stop word" "chore/z-x" "$(run_name 14)"
assert_eq "nothing was created or expanded" "alpha.sh beta.sh x" "$(cd "$project" && ls | tr '\n' ' ' | sed 's/ $//')"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
