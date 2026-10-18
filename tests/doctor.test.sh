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
echo "$*" >> "${GH_LOG:-/dev/null}"
case "$1 ${2:-}" in
    "api -i")
        [[ -z "${GH_AUTH_FAIL:-}" ]] || { echo "To get started with GitHub CLI, please run:  gh auth login" >&2; exit 4; }
        [[ -z "${GH_NO_SCOPES_HEADER:-}" ]] || { printf 'HTTP/2.0 200 OK\r\n\r\n{"login":"me"}\n'; exit 0; }
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
    [[ $(grep -c '^ok ' <<<"$out") -eq 10 ]] || fail "expected ten ok lines"
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
    [[ $(wc -l <<<"$out") -eq 10 ]] || fail "expected one line per check"
}

doctor_survives_an_unusable_config() {
    echo '{"schema":9,"repo":{"owner":"a","name":"b"},"baseBranch":"main"}' > .codeo/config.json
    run
    grep -q '^fail config: ' <<<"$out" && grep -q '^fail schema: ' <<<"$out" || fail "config/schema failures"
    [[ $(wc -l <<<"$out") -eq 10 ]] || fail "later checks did not run"
}

doctor_reports_a_todo_marker_as_a_config_failure_and_skips_the_ruleset() {
    jq '.baseBranch = "TODO-set-me"' <<<"$healthy" > .codeo/config.json
    run
    [[ $rc -ne 0 ]] || fail "expected non-zero"
    grep -q '^fail config: .*baseBranch is still TODO-set-me' <<<"$out" || fail "no config failure"
    grep -q '^fail ruleset: skipped: baseBranch is not set' <<<"$out" || fail "ruleset not skipped"
}

doctor_reports_an_unauthenticated_gh_without_hanging() {
    echo "$healthy" > .codeo/config.json
    out=$(GH_AUTH_FAIL=1 timeout 20 bash "$script" 2>&1) && rc=0 || rc=$?
    [[ $rc -ne 0 && $rc -ne 124 ]] || fail "expected a prompt non-zero exit, got $rc"
    grep -q '^fail gh-auth: ' <<<"$out" || fail "no gh-auth failure"
    [[ $(wc -l <<<"$out") -eq 10 ]] || fail "expected one line per check"
}

doctor_outside_a_repository_prints_ten_lines_and_fails_cleanly() {
    local outside; outside=$(mktemp -d "$work/outside.XXXXXX")
    out=$(cd "$outside" && bash "$script" 2>&1) && rc=0 || rc=$?
    [[ $rc -ne 0 ]] || fail "expected non-zero"
    [[ $(wc -l <<<"$out") -eq 10 ]] || fail "expected one line per check"
    ! grep -Eqi 'unbound|traceback|syntax error|line [0-9]+:' <<<"$out" || fail "stack trace leaked"
}

doctor_does_not_call_an_unusable_config_no_board() {
    echo '{"schema":9,"repo":{"owner":"a","name":"b"},"baseBranch":"main","board":{"owner":"a","projects":[2]}}' > .codeo/config.json
    run
    grep -q '^fail gh-scopes: skipped: config is unusable' <<<"$out" || fail "gh-scopes masked: $out"
    grep -q '^fail board: skipped: config is unusable' <<<"$out" || fail "board masked: $out"
}

doctor_accepts_a_token_that_sends_no_scopes_header() {
    echo "$healthy" > .codeo/config.json
    GH_NO_SCOPES_HEADER=1 run
    [[ $rc -eq 0 ]] || fail "expected exit 0, got $rc: $out"
    grep -q '^ok gh-scopes: cannot verify scopes for this token type; the board check decides' <<<"$out" || fail "no unverifiable-scopes line"
}

doctor_names_the_right_command_when_build_is_empty() {
    jq '.suites[0].build = "" | .suites[0].test = "no-such-tool-xyz"' <<<"$healthy" > .codeo/config.json
    run
    grep -q '^fail suites: not installed or unset: s:(no command) s:no-such-tool-xyz$' <<<"$out" || fail "wrong report: $out"
}

doctor_encodes_a_slash_in_the_base_branch() {
    jq '.baseBranch = "release/1.x"' <<<"$healthy" > .codeo/config.json
    : > "$work/gh.log"
    GH_LOG="$work/gh.log" run
    grep -q 'rules/branches/release%2F1.x' "$work/gh.log" || fail "branch not encoded: $(cat "$work/gh.log")"
}

doctor_requires_bash_4_3() {
    echo "$healthy" > .codeo/config.json
    printf 'BASH_VERSION=4.2.46\(2\)-release\n' > "$work/old-bash-env"
    out=$(BASH_ENV="$work/old-bash-env" bash "$script" 2>&1) && rc=0 || rc=$?
    [[ $rc -ne 0 ]] || fail "bash 4.2 accepted"
    grep -q '^fail deps: .*bash>=4.3' <<<"$out" || fail "no deps failure: $out"
    printf 'BASH_VERSION=4.3.0\(1\)-release\n' > "$work/old-bash-env"
    out=$(BASH_ENV="$work/old-bash-env" bash "$script" 2>&1) && rc=0 || rc=$?
    [[ $rc -eq 0 ]] || fail "bash 4.3 refused: $out"
}

# Overlay and plugin checks. Each case clears what it made so the others see a bare project.
reg="$work/points.tsv"
printf 'plan\tplan-shape\tdefault\nplan\twiki-rules\tdefault\ninit\thost-workflow\tdefault\n' > "$reg"

doctor_overlays_ok_when_none() {
    echo "$healthy" > .codeo/config.json
    CODEO_EXTENSION_POINTS="$reg" run
    grep -q '^ok overlays: none$' <<<"$out" || fail "no 'none' line: $out"
}

doctor_overlays_ok_counts_sections() {
    echo "$healthy" > .codeo/config.json
    mkdir -p .codeo/overlays
    printf '## plan-shape\nx\n\n## wiki-rules\ny\n' > .codeo/overlays/plan.md
    printf '## host-workflow\nz\n' > .codeo/overlays/init.md
    CODEO_EXTENSION_POINTS="$reg" run
    rm -rf .codeo/overlays
    grep -q '^ok overlays: 3 section(s) in 2 file(s)$' <<<"$out" || fail "wrong count: $out"
}

doctor_overlays_fail_names_file_section_and_known_points() {
    echo "$healthy" > .codeo/config.json
    mkdir -p .codeo/overlays
    printf '## plan-shape\nx\n## plan-shpae\ny\n' > .codeo/overlays/plan.md
    printf '## anything\n' > .codeo/overlays/nosuch.md
    CODEO_EXTENSION_POINTS="$reg" run
    rm -rf .codeo/overlays
    [[ $rc -ne 0 ]] || fail "expected non-zero"
    grep -q '^fail overlays: .*plan.md: ## plan-shpae is not an extension point of plan (known: plan-shape, wiki-rules)' <<<"$out" || fail "no section failure: $out"
    grep -q 'nosuch.md: no extension points for skill nosuch' <<<"$out" || fail "no unknown-skill failure: $out"
    [[ $(wc -l <<<"$out") -eq 10 ]] || fail "overlays must stay one line: $out"
}

doctor_superpowers_fail_with_install_command() {
    echo "$healthy" > .codeo/config.json
    echo '{"version":2,"plugins":{"other@m":[{}]}}' > "$work/plugins.json"
    CODEO_PLUGINS_FILE="$work/plugins.json" run
    [[ $rc -ne 0 ]] || fail "expected non-zero"
    grep -qF 'fail superpowers: not installed; install it with: claude plugin install superpowers@superpowers-marketplace' <<<"$out" || fail "no install line: $out"
}

doctor_superpowers_ok_when_present() {
    echo "$healthy" > .codeo/config.json
    echo '{"version":2,"plugins":{"superpowers@superpowers-marketplace":[{}]}}' > "$work/plugins.json"
    CODEO_PLUGINS_FILE="$work/plugins.json" run
    grep -q '^ok superpowers: installed$' <<<"$out" || fail "not ok: $out"
}

doctor_superpowers_undetectable_is_not_a_fail() {
    echo "$healthy" > .codeo/config.json
    CODEO_PLUGINS_FILE="$work/absent.json" run
    grep -q '^ok superpowers: cannot verify$' <<<"$out" || fail "absent file: $out"
    echo 'not json' > "$work/plugins.json"
    CODEO_PLUGINS_FILE="$work/plugins.json" run
    grep -q '^ok superpowers: cannot verify$' <<<"$out" || fail "bad json: $out"
}

for c in doctor_overlays_ok_when_none doctor_overlays_ok_counts_sections \
    doctor_overlays_fail_names_file_section_and_known_points doctor_superpowers_fail_with_install_command \
    doctor_superpowers_ok_when_present doctor_superpowers_undetectable_is_not_a_fail \
    doctor_reports_an_unauthenticated_gh_without_hanging \
    doctor_outside_a_repository_prints_ten_lines_and_fails_cleanly \
    doctor_does_not_call_an_unusable_config_no_board doctor_accepts_a_token_that_sends_no_scopes_header \
    doctor_names_the_right_command_when_build_is_empty doctor_encodes_a_slash_in_the_base_branch \
    doctor_requires_bash_4_3 \
    doctor_reports_a_todo_marker_as_a_config_failure_and_skips_the_ruleset doctor_passes_a_healthy_project doctor_fails_when_the_board_scope_is_missing \
    doctor_ignores_the_project_scope_without_a_board doctor_fails_when_a_suite_command_is_not_installed \
    doctor_fails_when_the_ruleset_lacks_a_required_check doctor_reports_every_failure_not_only_the_first \
    doctor_survives_an_unusable_config; do
    "$c"
done
echo "all cases passed"
