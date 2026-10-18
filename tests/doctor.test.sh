#!/usr/bin/env bash
# Exercises scripts/doctor.sh against a stubbed gh: a healthy project, a missing board scope, an
# uninstalled suite command, a ruleset missing a required check, and every failure reported rather
# than only the first. Makes no network call.
#
#   doctor.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$plugin_root/scripts/doctor.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export HOME="$work/home"
mkdir -p "$HOME" "$work/bin" "$work/repo/.codeo"
git init -q "$work/repo"
cd "$work/repo"

# Stub gh: `api -i user` answers headers with scopes from GH_SCOPES; the rules endpoint answers
# the contexts in GH_CHECKS; `project view` fails for the number in GH_BAD_PROJECT.
cat > "$work/bin/gh" <<'STUB'
#!/usr/bin/env bash
case "$1 ${2:-}" in
    "api -i")
        printf 'HTTP/2.0 200 OK\r\nX-Oauth-Scopes: %s\r\n\r\n{"login":"me"}\n' "${GH_SCOPES:-repo, project}" ;;
    "api repos/"*)
        jq -n --arg c "${GH_CHECKS:-tests qc-verdict}" '[{type:"required_status_checks",parameters:{required_status_checks:($c|split(" ")|map({context:.}))}}]' ;;
    "project view")
        [[ "$3" != "${GH_BAD_PROJECT:-}" ]] || { echo "not found" >&2; exit 1; }
        echo '{}' ;;
    *) echo "unexpected gh $*" >&2; exit 1 ;;
esac
STUB
chmod +x "$work/bin/gh"
export PATH="$work/bin:$PATH"

fail() { echo "FAIL: $1" >&2; echo "$out" >&2; exit 1; }

healthy='{"schema":1,"repo":{"owner":"acme","name":"widgets"},"baseBranch":"main","board":{"owner":"acme","projects":[2]},"suites":[{"name":"s","paths":["a"],"build":"git status","test":"jq --version"}]}'
run() { out=$(bash "$script" 2>&1) && rc=0 || rc=$?; }

doctor_passes_a_healthy_project() {
    echo "$healthy" > .codeo/config.json
    run
    [[ $rc -eq 0 ]] || fail "expected exit 0, got $rc"
    [[ $(grep -c '^ok ' <<<"$out") -eq 8 ]] || fail "expected eight ok lines"
}

doctor_fails_when_the_board_scope_is_missing() {
    echo "$healthy" > .codeo/config.json
    GH_SCOPES="repo" run
    [[ $rc -ne 0 ]] || fail "expected non-zero"
    grep -q '^fail gh-scopes: ' <<<"$out" || fail "no gh-scopes failure"
}

doctor_ignores_the_project_scope_without_a_board() {
    jq 'del(.board)' <<<"$healthy" > .codeo/config.json
    GH_SCOPES="repo" run
    [[ $rc -eq 0 ]] || fail "board-less project should pass"
}

doctor_fails_when_a_suite_command_is_not_installed() {
    jq '.suites[0].build = "no-such-tool-xyz --go"' <<<"$healthy" > .codeo/config.json
    run
    grep -q '^fail suites: .*no-such-tool-xyz' <<<"$out" || fail "no suites failure"
}

doctor_fails_when_the_ruleset_lacks_a_required_check() {
    echo "$healthy" > .codeo/config.json
    GH_CHECKS="tests" run
    grep -q '^fail ruleset: .*qc-verdict' <<<"$out" || fail "no ruleset failure"
    jq '.ci.requiredChecks = ["tests"]' <<<"$healthy" > .codeo/config.json
    GH_CHECKS="tests" run
    [[ $rc -eq 0 ]] || fail "ci.requiredChecks not honoured"
}

doctor_reports_every_failure_not_only_the_first() {
    jq '.suites[0].test = "no-such-tool-xyz"' <<<"$healthy" > .codeo/config.json
    GH_SCOPES="repo" GH_CHECKS="tests" GH_BAD_PROJECT=2 run
    [[ $rc -ne 0 ]] || fail "expected non-zero"
    for c in gh-scopes board ruleset suites; do
        grep -q "^fail $c: " <<<"$out" || fail "missing failure for $c"
    done
    [[ $(wc -l <<<"$out") -eq 8 ]] || fail "expected one line per check"
}

doctor_survives_an_unusable_config() {
    echo '{"schema":9,"repo":{"owner":"a","name":"b"},"baseBranch":"main"}' > .codeo/config.json
    run
    grep -q '^fail config: ' <<<"$out" && grep -q '^fail schema: ' <<<"$out" || fail "config/schema failures"
    [[ $(wc -l <<<"$out") -eq 8 ]] || fail "later checks did not run"
}

doctor_reports_a_todo_marker_as_a_config_failure_and_skips_the_ruleset() {
    jq '.baseBranch = "TODO-set-me"' <<<"$healthy" > .codeo/config.json
    run
    [[ $rc -ne 0 ]] || fail "expected non-zero"
    grep -q '^fail config: .*baseBranch is still TODO-set-me' <<<"$out" || fail "no config failure"
    grep -q '^fail ruleset: skipped: baseBranch is not set' <<<"$out" || fail "ruleset not skipped"
}

for c in doctor_reports_a_todo_marker_as_a_config_failure_and_skips_the_ruleset doctor_passes_a_healthy_project doctor_fails_when_the_board_scope_is_missing \
    doctor_ignores_the_project_scope_without_a_board doctor_fails_when_a_suite_command_is_not_installed \
    doctor_fails_when_the_ruleset_lacks_a_required_check doctor_reports_every_failure_not_only_the_first \
    doctor_survives_an_unusable_config; do
    "$c"
done
echo "all cases passed"
