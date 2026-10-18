#!/usr/bin/env bash
# Exercises scripts/board.sh against a stubbed gh: status read from the gate project
# (#2) and not another, set adding a missing issue before editing it, set writing every project
# the issue is on, a project lacking the option skipped, an unknown Status option, and the missing
# `project` scope. Makes no network call.
#
#   board.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

# board.sh degrades whenever CLAUDE_CODE_REMOTE=true, which a web session exports into every shell
# — so the cases that exercise the real path must not inherit it. The two web cases set it per call.
unset CLAUDE_CODE_REMOTE

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$plugin_root/scripts/board.sh"
stub_bin=$(mktemp -d)
project_dir=$(mktemp -d)
trap 'rm -rf "$stub_bin" "$project_dir"' EXIT

# The script reads the repository and board from the project's config, so every case runs inside a
# scratch git repo that carries one; HOME is scratch too so nothing real is read.
export HOME="$project_dir/home"
mkdir -p "$HOME" "$project_dir/repo/.codeo"
git -C "$project_dir/repo" init -q
config="$project_dir/repo/.codeo/config.json"
with_board='{"schema":1,"repo":{"owner":"acme","name":"widgets"},"baseBranch":"main","board":{"owner":"acme","projects":[1,2],"gateProject":2,"statuses":{}}}'
without_board='{"schema":1,"repo":{"owner":"acme","name":"widgets"},"baseBranch":"main"}'
printf '%s\n' "$with_board" > "$config"
cd "$project_dir/repo"

# The real gh applies --jq itself, so the stub answers with what the filter would have produced.
# Every call is appended to $GH_STUB_LOG for the cases to assert on.
cat > "$stub_bin/gh" <<'STUB'
#!/usr/bin/env bash
echo "$*" >> "${GH_STUB_LOG:?}"
if [[ -n ${GH_STUB_NO_SCOPE:-} ]]; then
    echo "gh: Your token has not been granted the required scopes to execute this query. The 'project' scope is required." >&2
    exit 1
fi
case "$1 ${2:-}" in
    "api graphql") printf '%b\n' "${GH_STUB_ROWS:?}" ;;
    # Answers per project: #2 has the five real options, #1 the same, #9 lacks "In review".
    "project field-list")
        if [[ -n ${GH_STUB_FIELDS_FAIL:-} && $3 == "$GH_STUB_FIELDS_FAIL" ]]; then
            echo "gh: GraphQL: Could not resolve to a ProjectV2" >&2
            exit 1
        fi
        case $3 in
            2|1) printf 'F%s\tO_BACKLOG\tBacklog\nF%s\tO_READY\tReady\nF%s\tO_PROG\tIn progress\nF%s\tO_REVIEW\tIn review\nF%s\tO_DONE\tDone\n' "$3" "$3" "$3" "$3" "$3" ;;
            9) printf 'F9\tO_TODO\tTodo\nF9\tO_DOING\tDoing\n' ;;
        esac ;;
    "project item-add")
        if [[ -n ${GH_STUB_ADD_FAILS:-} && $3 == "$GH_STUB_ADD_FAILS" ]]; then
            echo "gh: could not resolve to a Project" >&2
            exit 1
        fi
        echo ITEM_NEW ;;
    "project view") echo "PROJ_$3" ;;
    "project item-edit")
        if [[ -n ${GH_STUB_EDIT_FAILS:-} && $* == *"--project-id $GH_STUB_EDIT_FAILS "* ]]; then
            echo "gh: GraphQL: Resource not accessible" >&2
            exit 1
        fi
        echo '{}' ;;
    *) echo "unexpected gh call: $*" >&2; exit 2 ;;
esac
STUB
chmod +x "$stub_bin/gh"
export PATH="$stub_bin:$PATH"

url=https://github.com/acme/widgets/issues/7
fail() { echo "FAIL: $1" >&2; exit 1; }
run() {
    export GH_STUB_LOG=$stub_bin/log
    : > "$GH_STUB_LOG"
    out=$(bash "$script" "$@" 2>"$stub_bin/err") && rc=0 || rc=$?
    err=$(cat "$stub_bin/err")
}

# One row per project item: url, item id, status, project number, project title.
P2="$url\tITEM_2\tReady\t2\tAcme - Kanban"
P1="$url\tITEM_1\tReady\t1\tAcme - Feature Tracker"

GH_STUB_ROWS="$url\tITEM_2\tReady\t2\tAcme - Kanban\n$url\tITEM_1\tBacklog\t1\tAcme - Feature Tracker" run status 7
[[ $rc -eq 0 && $out == Ready ]] || fail "status reads the gate project (#2), not #1: rc=$rc out=$out"

GH_STUB_ROWS="$P2\n$url\tITEM_1\tBacklog\t1\tAcme - Feature Tracker" run status 7
[[ $err == *"board.sh: #7 differs across boards — #1 Backlog, #2 Ready"* ]] || fail "status notes drift between the boards: err=$err"
[[ $out == Ready ]] || fail "...and still answers from #2: out=$out"

GH_STUB_ROWS="$P2\n$P1" run status 7
[[ -z $err ]] || fail "status says nothing when the boards agree: err=$err"

GH_STUB_ROWS="$P2" run status 7
[[ -z $err ]] || fail "an issue missing from #1 is not a difference: err=$err"

GH_STUB_ROWS="$P1" run status 7
[[ $rc -eq 0 && $out == none ]] || fail "status is none when the issue is only on another project: out=$out"

GH_STUB_ROWS="$url\tITEM_2\tIn progress\t2\tAcme - Kanban" run status '#7'
[[ $rc -eq 0 && $out == "In progress" ]] || fail "status with a # and a space in the option: rc=$rc out=$out"

GH_STUB_ROWS="$url\t\t\t\t" run status 7
[[ $rc -eq 0 && $out == none ]] || fail "status off the board: rc=$rc out=$out"

GH_STUB_ROWS="$url\tITEM_2\t\t2\tAcme - Kanban" run status 7
[[ $rc -eq 0 && $out == unset ]] || fail "status on the board with no Status: rc=$rc out=$out"

GH_STUB_ROWS="\t\t\t\t" run status 7
[[ $rc -ne 0 && $err == *"no issue #7"* ]] || fail "status of a missing issue: rc=$rc err=$err"

GH_STUB_ROWS="$url\t\t\t\t" run set 7 Ready
[[ $rc -eq 0 ]] || fail "set off the board: rc=$rc err=$err"
grep -q "^project item-add 2 --owner acme --url $url" "$GH_STUB_LOG" || fail "an issue on no project is added to #2"
grep -q -- "item-edit --id ITEM_NEW --project-id PROJ_2 --field-id F2 --single-select-option-id O_READY" "$GH_STUB_LOG" ||
    fail "...and set there"

GH_STUB_ROWS="$P1" run set 7 "In progress"
[[ $rc -eq 0 && $out == *"(not on the board) → In progress on #2"* ]] || fail "set on #1 only: rc=$rc out=$out err=$err"
grep -q "^project item-add 2 --owner acme --url $url" "$GH_STUB_LOG" || fail "an issue only on #1 is added to #2"
grep -q -- "item-edit --id ITEM_NEW --project-id PROJ_2 --field-id F2 --single-select-option-id O_PROG" "$GH_STUB_LOG" || fail "...and set on #2"
grep -q -- "item-edit --id ITEM_1 --project-id PROJ_1 --field-id F1 --single-select-option-id O_PROG" "$GH_STUB_LOG" || fail "...and still on #1"

GH_STUB_ROWS="$url\tITEM_2\t\t2\tAcme - Kanban" run set 7 Ready
[[ $out == *"(unset) → Ready on #2"* ]] || fail "an item with no Status prints (unset): $out"

GH_STUB_ROWS="$P2" run set 7 "In progress"
[[ $rc -eq 0 && $out == *"Ready → In progress on #2 Acme - Kanban"* ]] || fail "set on the board: rc=$rc out=$out"
! grep -q "item-add 2" "$GH_STUB_LOG" || fail "set on the board added the issue to #2 again"
grep -q -- "item-edit --id ITEM_2 --project-id PROJ_2 --field-id F2 --single-select-option-id O_PROG" "$GH_STUB_LOG" ||
    fail "set on the board did not edit the existing item to In progress"

GH_STUB_ROWS="$P2\n$P1" run set 7 "In progress"
! grep -q "item-add" "$GH_STUB_LOG" || fail "set on both boards added the issue again"
[[ $rc -eq 0 ]] || fail "set on two projects: rc=$rc err=$err"
grep -q -- "item-edit --id ITEM_2 --project-id PROJ_2 --field-id F2 --single-select-option-id O_PROG" "$GH_STUB_LOG" || fail "set did not write #2"
grep -q -- "item-edit --id ITEM_1 --project-id PROJ_1 --field-id F1 --single-select-option-id O_PROG" "$GH_STUB_LOG" || fail "set did not write #1"
[[ $out == *"Ready → In progress on #2 Acme - Kanban"* && $out == *"on #1 Acme - Feature Tracker"* ]] || fail "set did not report both projects: $out"

# Both boards are kept in step: an issue on neither is added to both and set on both; one only on
# the Kanban board is added to the Feature Tracker; the pinned project is still the one status reads.
GH_STUB_ROWS="$url\t\t\t\t" run set 7 Ready
grep -q "^project item-add 1 --owner acme --url $url" "$GH_STUB_LOG" || fail "an issue on no board is added to #1"
grep -q "^project item-add 2 --owner acme --url $url" "$GH_STUB_LOG" || fail "an issue on no board is added to #2"
[[ $(grep -c -- "item-edit --id ITEM_NEW" "$GH_STUB_LOG") -eq 2 ]] || fail "an issue on no board is set on both"
grep -q -- "--project-id PROJ_1 --field-id F1" "$GH_STUB_LOG" || fail "...including #1"

GH_STUB_ROWS="$P2" run set 7 "In progress"
grep -q "^project item-add 1 --owner" "$GH_STUB_LOG" || fail "an issue only on #2 is added to #1"
! grep -q "^project item-add 2" "$GH_STUB_LOG" || fail "...and not to #2 again"
grep -q -- "item-edit --id ITEM_NEW --project-id PROJ_1 --field-id F1 --single-select-option-id O_PROG" "$GH_STUB_LOG" || fail "...and set there"
grep -q -- "item-edit --id ITEM_2 --project-id PROJ_2" "$GH_STUB_LOG" || fail "...and on #2"

GH_STUB_ROWS="$P2\n$url\tITEM_9\tTodo\t9\tOther" run set 7 "In review"
[[ $rc -eq 0 && $err == *"project #9 Other has no option 'In review' — skipped"* ]] || fail "one project lacks the option: rc=$rc err=$err"
grep -q -- "item-edit --id ITEM_2" "$GH_STUB_LOG" || fail "the project with the option was not written"
! grep -q -- "item-edit --id ITEM_9" "$GH_STUB_LOG" || fail "the project without the option was written"

GH_STUB_ROWS="$url\tITEM_9\tTodo\t9\tOther" run set 7 Blocked
[[ $rc -ne 0 && $err == *"no project"* && $err == *"Todo"* ]] || fail "nothing writable fails naming the options: rc=$rc err=$err"
! grep -q "item-edit" "$GH_STUB_LOG" || fail "nothing writable still edited an item"

# One board's failed add must not stop the other's: #1 refuses the add, #2 still gets it and the
# Status write, stderr names #1, and the exit status is still non-zero.
GH_STUB_ADD_FAILS=1 GH_STUB_ROWS="$url\t\t\t\t" run set 7 Ready
[[ $rc -ne 0 ]] || fail "a failed add must leave the exit status non-zero: rc=$rc"
[[ $err == *"#1"* && $err == *"could not resolve to a Project"* ]] || fail "a failed add names the project and the reason: err=$err"
grep -q "^project item-add 2 --owner" "$GH_STUB_LOG" || fail "a failed add for #1 still adds the issue to #2"
grep -q -- "item-edit --id ITEM_NEW --project-id PROJ_2 --field-id F2 --single-select-option-id O_READY" "$GH_STUB_LOG" ||
    fail "a failed add for #1 still writes the Status on #2"
! grep -q -- "--project-id PROJ_1" "$GH_STUB_LOG" || fail "the project whose add failed was written"

# A failed Status write on #1 must not stop #2's: #1 is listed first, so #2 is written only if the
# loop carries on.
GH_STUB_EDIT_FAILS=PROJ_1 GH_STUB_ROWS="$P1\n$P2" run set 7 "In progress"
[[ $rc -ne 0 ]] || fail "a failed write must leave the exit status non-zero: rc=$rc"
[[ $err == *"#1"* && $err == *"Resource not accessible"* ]] || fail "a failed write names the project and the reason: err=$err"
grep -q -- "item-edit --id ITEM_2 --project-id PROJ_2" "$GH_STUB_LOG" || fail "a failed write on #1 still writes #2"
[[ $out == *"on #2 Acme - Kanban"* ]] || fail "...and reports #2: $out"

# A failed field lookup on #1 must not stop #2's write either: #1 is listed first.
GH_STUB_FIELDS_FAIL=1 GH_STUB_ROWS="$P1\n$P2" run set 7 "In progress"
[[ $rc -ne 0 ]] || fail "a failed field lookup must leave the exit status non-zero: rc=$rc"
[[ $err == *"#1"* && $err == *"Could not resolve to a ProjectV2"* ]] || fail "a failed field lookup names the project and the reason: err=$err"
grep -q -- "item-edit --id ITEM_2 --project-id PROJ_2" "$GH_STUB_LOG" || fail "a failed field lookup on #1 still writes #2"
! grep -q -- "--project-id PROJ_1" "$GH_STUB_LOG" || fail "the project whose field lookup failed was written"

GH_STUB_ROWS="$P2" run set 7 Blocked
[[ $rc -ne 0 && $err == *"has the option 'Blocked'"* && $err == *"In progress"* ]] || fail "unknown option: rc=$rc err=$err"
! grep -q "item-edit" "$GH_STUB_LOG" || fail "unknown option still edited the item"

GH_STUB_NO_SCOPE=1 GH_STUB_ROWS=x run status 7
[[ $rc -ne 0 && $err == *"gh auth refresh -s project"* ]] || fail "missing scope: rc=$rc err=$err"

run frobnicate 7
[[ $rc -ne 0 && $err == usage* ]] || fail "unknown command: rc=$rc err=$err"

run set 7
[[ $rc -ne 0 && $err == usage* ]] || fail "set with no status: rc=$rc err=$err"
[[ ! -s $GH_STUB_LOG ]] || fail "set with no status called gh"

CLAUDE_CODE_REMOTE=true run set 5
[[ $rc -ne 0 && $err == usage* ]] || fail "set with no status in a web session: rc=$rc err=$err"
[[ ! -s $GH_STUB_LOG ]] || fail "set with no status in a web session called gh"

CLAUDE_CODE_REMOTE=true run status 7
[[ $rc -eq 0 && $out == unavailable ]] || fail "status in a web session: rc=$rc out=$out"
[[ ! -s $GH_STUB_LOG ]] || fail "status in a web session called gh"

CLAUDE_CODE_REMOTE=true run set 7 Ready
[[ $rc -ne 0 && $err == *"move #7 to Ready by hand"* ]] || fail "set in a web session: rc=$rc err=$err"
[[ ! -s $GH_STUB_LOG ]] || fail "set in a web session called gh"

# A project whose board is not configured at all: every verb says so and exits 3, calling no gh.
printf '%s\n' "$without_board" > "$config"
board_reports_not_configured_with_exit_3() {
    local args
    for args in "status 7" "set 7 Ready"; do
        # shellcheck disable=SC2086
        GH_STUB_ROWS=x run $args
        [[ $rc -eq 3 ]] || fail "not configured ($args): rc=$rc"
        [[ $out == "board: not configured" ]] || fail "not configured ($args) prints it on stdout: out=$out err=$err"
        [[ ! -s $GH_STUB_LOG ]] || fail "not configured ($args) called gh"
    done
}
board_reports_not_configured_with_exit_3
printf '%s\n' "$with_board" > "$config"

# Logical status keys in board.statuses map to the project's own option names; a name that is not a
# key passes through untouched (every case above relies on that).
printf '%s\n' '{"schema":1,"repo":{"owner":"acme","name":"widgets"},"baseBranch":"main","board":{"owner":"acme","projects":[2],"gateProject":2,"statuses":{"inProgress":"In progress"}}}' > "$config"
GH_STUB_ROWS="$P2" run set 7 inProgress
[[ $rc -eq 0 && $out == *"Ready → In progress on #2"* ]] || fail "a logical status resolves to the configured name: rc=$rc out=$out err=$err"
printf '%s\n' "$with_board" > "$config"

# A board without board.projects is just its gate project, and says nothing about the absent key.
printf '%s\n' '{"schema":1,"repo":{"owner":"acme","name":"widgets"},"baseBranch":"main","board":{"owner":"acme","gateProject":2,"statuses":{}}}' > "$config"
GH_STUB_ROWS="$P2" run set 7 "In progress"
[[ $rc -eq 0 && -z $err ]] || fail "gate-project-only board: rc=$rc err=$err"
GH_STUB_ROWS="$P2" run status 7
[[ $rc -eq 0 && -z $err && $out == Ready ]] || fail "gate-project-only status: rc=$rc err=$err out=$out"
printf '%s\n' "$with_board" > "$config"

echo "board.test.sh: all cases passed"
