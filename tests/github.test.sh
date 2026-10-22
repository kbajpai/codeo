#!/usr/bin/env bash
# Exercises scripts/github.sh's verb table against a stubbed `gh` that answers only
# `gh api` (never `gh issue`/`gh pr`/`gh run`, which github.sh must never call — see the header
# comment on github.sh for why), keyed by fixture files this test writes into a scratch dir before
# each case, plus one failing-call case per group (issue view, issue-types, user login). Touches
# no real GitHub API and makes no network call.
#
#   github.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail
unset GH_TOKEN CODEO_GITHUB_LOGIN

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$plugin_root/scripts/github.sh"
repo=acme/widgets

# The script reads the repository from the project's config, so every case runs inside a scratch
# git repo that carries one; HOME is scratch too so nothing real is read.
project_dir=$(mktemp -d)
export HOME="$project_dir/home"
mkdir -p "$HOME" "$project_dir/repo/.codeo"
git -C "$project_dir/repo" init -q
printf '%s\n' '{"schema":1,"repo":{"owner":"acme","name":"widgets"},"baseBranch":"main"}' > "$project_dir/repo/.codeo/config.json"
cd "$project_dir/repo"

stub_bin=$(mktemp -d)
fixtures_dir=$(mktemp -d)
scratch_dir=$(mktemp -d)
calls_log=$(mktemp)
err_file=$(mktemp)
cleanup() { rm -rf "$project_dir" "$stub_bin" "$fixtures_dir" "$scratch_dir" "$calls_log" "$err_file"; }
trap cleanup EXIT

# Stubs `gh api` only: real github.sh never calls another `gh` subcommand. Looks up a fixture by
# "METHOD_PATH" (sanitized the same way this test's write_fixture/mark_fail name their files),
# applies the caller's -q filter with jq in raw+compact mode (matching how `gh api --jq` prints
# unquoted strings for scalars and single-line JSON for objects/arrays, which is what lets
# github.sh treat -q output as plain text or as JSON interchangeably), and exits 1 when the key is
# marked to fail. Every call is appended to $GH_STUB_LOG so a case can assert on the method, path
# and fields a verb actually sent.
cat > "$stub_bin/gh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

[[ ${1:-} == api ]] || { echo "gh-stub: only 'gh api' is stubbed, got: $*" >&2; exit 1; }
shift

method=
path=
query=
paginate=
fields=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -X|--method) method=$2; shift 2 ;;
        -f|-F) fields+=("$2"); shift 2 ;;
        -q) query=$2; shift 2 ;;
        --paginate) paginate=1; shift ;;
        -*) shift ;;
        *) path=$1; shift ;;
    esac
done

# Real gh switches to POST as soon as any -f/-F field is present unless a method is given, so a
# read verb that forgets `-X GET` must not find its GET fixture here.
if [[ -z $method ]]; then
    if ((${#fields[@]})); then method=POST; else method=GET; fi
fi

if [[ -n ${GH_STUB_LOG:-} ]]; then
    {
        printf 'METHOD=%s PATH=%s' "$method" "$path"
        if ((${#fields[@]})); then
            for f in "${fields[@]}"; do printf ' FIELD=%s' "$f"; done
        fi
        [[ -z $paginate ]] || printf ' PAGINATE=1'
        printf '\n'
    } >> "$GH_STUB_LOG"
fi

key=$(printf '%s_%s' "$method" "$path" | tr -c 'A-Za-z0-9_-' '_')
fixture="$GH_STUB_FIXTURES/$key.json"
fail_marker="$GH_STUB_FIXTURES/$key.fail"

if [[ -f $fail_marker ]]; then
    echo '{"message": "Not Found", "status": "404"}'
    echo "gh: 404 (stubbed failure for $method $path)" >&2
    exit 1
fi
if [[ ! -f $fixture ]]; then
    echo "gh-stub: no fixture for $method $path (key $key)" >&2
    exit 1
fi

if [[ -n $query ]]; then
    jq -rc "$query" "$fixture"
else
    cat "$fixture"
fi
STUB
chmod +x "$stub_bin/gh"
export PATH="$stub_bin:$PATH"
export GH_STUB_FIXTURES="$fixtures_dir"
export GH_STUB_LOG="$calls_log"

fixture_key() { printf '%s_%s' "$1" "$2" | tr -c 'A-Za-z0-9_-' '_'; }
write_fixture() { cat > "$fixtures_dir/$(fixture_key "$1" "$2").json"; }
mark_fail() { touch "$fixtures_dir/$(fixture_key "$1" "$2").fail"; }
reset_case() {
    rm -rf "$fixtures_dir"
    mkdir -p "$fixtures_dir"
    : > "$calls_log"
    : > "$err_file"
}

printf 'PR body text\n' > "$scratch_dir/body.txt"

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

case_desc="issue view 85"
reset_case
write_fixture GET "repos/$repo/issues/85" <<'JSON'
{"number":85,"title":"Web session pipeline","state":"open","closed_at":null,"html_url":"https://github.com/acme/widgets/issues/85","body":"Some body text","labels":[{"name":"enhancement"},{"name":"widgets"}],"assignees":[{"login":"kbajpai"}]}
JSON
if out=$(bash "$script" issue view 85 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "number" 85 "$(jq -r '.number' <<<"$out")"
assert_eq "title" "Web session pipeline" "$(jq -r '.title' <<<"$out")"
assert_eq "state" "open" "$(jq -r '.state' <<<"$out")"
assert_eq "closed_at" "null" "$(jq -r '.closed_at // "null"' <<<"$out")"
assert_eq "html_url" "https://github.com/acme/widgets/issues/85" "$(jq -r '.html_url' <<<"$out")"
assert_eq "body" "Some body text" "$(jq -r '.body' <<<"$out")"
assert_eq "labels" "enhancement,widgets" "$(jq -r '.labels | join(",")' <<<"$out")"
assert_eq "assignees" "kbajpai" "$(jq -r '.assignees | join(",")' <<<"$out")"

case_desc="issue view 999 (fixture 404s)"
reset_case
mark_fail GET "repos/$repo/issues/999"
if out=$(bash "$script" issue view 999 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "stdout empty" "" "$out"
assert_contains "stderr names the issue" "999" "$(cat "$err_file")"

case_desc="issue assignee-add 85 kbajpai"
reset_case
write_fixture POST "repos/$repo/issues/85/assignees" <<'JSON'
{"id":85}
JSON
if out=$(bash "$script" issue assignee-add 85 kbajpai 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_contains "call" "METHOD=POST PATH=repos/$repo/issues/85/assignees FIELD=assignees[]=kbajpai" "$(cat "$calls_log")"

case_desc="issue assignee-remove 85 kbajpai"
reset_case
write_fixture DELETE "repos/$repo/issues/85/assignees" <<'JSON'
{"id":85}
JSON
if out=$(bash "$script" issue assignee-remove 85 kbajpai 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_contains "call" "METHOD=DELETE PATH=repos/$repo/issues/85/assignees FIELD=assignees[]=kbajpai" "$(cat "$calls_log")"

case_desc='issue search "web session"'
reset_case
write_fixture GET "search/issues" <<'JSON'
{"items":[{"number":10,"title":"Web session pipeline planning","state":"open"},{"number":11,"title":"unrelated","state":"closed"}]}
JSON
if out=$(bash "$script" issue search "web session" 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "line count" 2 "$(printf '%s\n' "$out" | grep -c .)"
assert_eq "first number" 10 "$(printf '%s\n' "$out" | sed -n '1p' | jq -r '.number')"
assert_eq "second title" unrelated "$(printf '%s\n' "$out" | sed -n '2p' | jq -r '.title')"
assert_contains "call carries the query" "FIELD=q=repo:$repo is:issue web session" "$(cat "$calls_log")"
assert_contains "sent as GET" "METHOD=GET PATH=search/issues" "$(cat "$calls_log")"

case_desc='issue search "web session" (search refused, list-all answers)'
reset_case
mark_fail GET "search/issues"
write_fixture GET "repos/$repo/issues" <<'JSON'
[{"number":12,"title":"Web session lock","state":"open","body":"the session is bound to one issue"},{"number":15,"title":"Session timeout","state":"open","body":"idle sessions expire"},{"number":20,"title":"web session pipeline","state":"open","body":"pr body","pull_request":{"url":"x"}}]
JSON
if out=$(bash "$script" issue search "web session" 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "line count" 1 "$(printf '%s\n' "$out" | grep -c .)"
assert_eq "number" 12 "$(jq -r '.number' <<<"$out")"
assert_contains "stderr notice" "refused; matched locally" "$(cat "$err_file")"
assert_contains "fallback sent as GET" "METHOD=GET PATH=repos/$repo/issues" "$(cat "$calls_log")"

case_desc='issue search "web session" (both refused)'
reset_case
mark_fail GET "search/issues"
mark_fail GET "repos/$repo/issues"
if out=$(bash "$script" issue search "web session" 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_contains "stderr reason" "search failed" "$(cat "$err_file")"
assert_eq "stdout empty" "" "$out"

case_desc="issue list-all"
reset_case
write_fixture GET "repos/$repo/issues" <<'JSON'
[{"number":1,"title":"A pull request","state":"open","body":"pr body","pull_request":{"url":"x"}},{"number":2,"title":"A real issue","state":"open","body":"issue body","pull_request":null}]
JSON
if out=$(bash "$script" issue list-all 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "line count" 1 "$(printf '%s\n' "$out" | grep -c .)"
assert_eq "number" 2 "$(jq -r '.number' <<<"$out")"
assert_eq "title" "A real issue" "$(jq -r '.title' <<<"$out")"
assert_contains "sent as GET" "METHOD=GET PATH=repos/$repo/issues" "$(cat "$calls_log")"

case_desc="issue list-all (fixture 404s)"
reset_case
mark_fail GET "repos/$repo/issues"
if out=$(bash "$script" issue list-all 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "stdout empty" "" "$out"
assert_contains "stderr reason" "issue list failed" "$(cat "$err_file")"

case_desc="issue-types (org endpoint succeeds, GH_TOKEN set)"
reset_case
export GH_TOKEN=dummy
write_fixture GET "users/acme" <<'JSON'
{"type":"Organization"}
JSON
write_fixture GET "orgs/acme/issue-types" <<'JSON'
[{"name":"Bug"},{"name":"Feature"},{"name":"Task"}]
JSON
if out=$(bash "$script" issue-types 2>"$err_file"); then rc=0; else rc=$?; fi
unset GH_TOKEN
assert_eq "exit code" 0 "$rc"
assert_eq "types" "$(printf 'Bug\nFeature\nTask')" "$out"

case_desc="issue-types (org endpoint 403s)"
reset_case
write_fixture GET "users/acme" <<'JSON'
{"type":"Organization"}
JSON
mark_fail GET "orgs/acme/issue-types"
if out=$(bash "$script" issue-types 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "fixed list" "$(printf 'Bug\nFeature\nTask')" "$out"
assert_contains "stderr note" "falling back" "$(cat "$err_file")"

case_desc="issue_types_is_empty_for_a_user_owner"
reset_case
write_fixture GET "users/acme" <<'JSON'
{"type":"User"}
JSON
if out=$(bash "$script" issue-types 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "stdout empty" "" "$out"
assert_eq "stderr empty" "" "$(cat "$err_file")"
if grep -q 'orgs/' "$calls_log"; then assert_eq "no org call" "none" "made one"; fi

case_desc="user login (GET /user succeeds)"
reset_case
write_fixture GET "user" <<'JSON'
{"login":"kbajpai"}
JSON
if out=$(bash "$script" user login 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "login" "kbajpai" "$out"

case_desc="user login (GET /user 403s, CODEO_GITHUB_LOGIN set)"
reset_case
mark_fail GET "user"
export CODEO_GITHUB_LOGIN=someone
if out=$(bash "$script" user login 2>"$err_file"); then rc=0; else rc=$?; fi
unset CODEO_GITHUB_LOGIN
assert_eq "exit code" 0 "$rc"
assert_eq "login" "someone" "$out"

case_desc="user login (GET /user 403s, no env var)"
reset_case
mark_fail GET "user"
if out=$(bash "$script" user login 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "stdout" "" "$out"
assert_contains "stderr explains the fallback" "CODEO_GITHUB_LOGIN" "$(cat "$err_file")"

case_desc="pr list-for-branch feat/x (CHANGES_REQUESTED wins)"
reset_case
write_fixture GET "repos/$repo/pulls" <<'JSON'
[{"number":42,"html_url":"https://github.com/acme/widgets/pull/42","state":"open","merged_at":null,"merge_commit_sha":null,"head":{"sha":"abc123"},"base":{"ref":"main"}}]
JSON
write_fixture GET "repos/$repo/pulls/42/reviews" <<'JSON'
[{"user":{"login":"alice"},"state":"APPROVED","submitted_at":"2026-01-01T00:00:00Z"},{"user":{"login":"bob"},"state":"CHANGES_REQUESTED","submitted_at":"2026-01-02T00:00:00Z"}]
JSON
if out=$(bash "$script" pr list-for-branch feat/x 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "number" 42 "$(jq -r '.number' <<<"$out")"
assert_eq "head_sha" "abc123" "$(jq -r '.head_sha' <<<"$out")"
assert_eq "base_ref" "main" "$(jq -r '.base_ref' <<<"$out")"
assert_eq "review_decision" "CHANGES_REQUESTED" "$(jq -r '.review_decision' <<<"$out")"
assert_contains "sent as GET" "METHOD=GET PATH=repos/$repo/pulls FIELD=head=" "$(cat "$calls_log")"

case_desc="pr list-for-branch feat/x (APPROVED then COMMENTED stays APPROVED)"
reset_case
write_fixture GET "repos/$repo/pulls" <<'JSON'
[{"number":42,"html_url":"https://github.com/acme/widgets/pull/42","state":"open","merged_at":null,"merge_commit_sha":null,"head":{"sha":"abc123"},"base":{"ref":"main"}}]
JSON
write_fixture GET "repos/$repo/pulls/42/reviews" <<'JSON'
[{"user":{"login":"alice"},"state":"APPROVED","submitted_at":"2026-01-01T00:00:00Z"},{"user":{"login":"alice"},"state":"COMMENTED","submitted_at":"2026-01-02T00:00:00Z"}]
JSON
if out=$(bash "$script" pr list-for-branch feat/x 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "review_decision" "APPROVED" "$(jq -r '.review_decision' <<<"$out")"

case_desc="pr list-for-branch feat/x (APPROVED, then another reviewer CHANGES_REQUESTED)"
reset_case
write_fixture GET "repos/$repo/pulls" <<'JSON'
[{"number":42,"html_url":"https://github.com/acme/widgets/pull/42","state":"open","merged_at":null,"merge_commit_sha":null,"head":{"sha":"abc123"},"base":{"ref":"main"}}]
JSON
write_fixture GET "repos/$repo/pulls/42/reviews" <<'JSON'
[{"user":{"login":"alice"},"state":"APPROVED","submitted_at":"2026-01-01T00:00:00Z"},{"user":{"login":"bob"},"state":"CHANGES_REQUESTED","submitted_at":"2026-01-02T00:00:00Z"}]
JSON
if out=$(bash "$script" pr list-for-branch feat/x 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "review_decision" "CHANGES_REQUESTED" "$(jq -r '.review_decision' <<<"$out")"

case_desc="pr list-for-branch feat/x (last counting review DISMISSED is no decision)"
reset_case
write_fixture GET "repos/$repo/pulls" <<'JSON'
[{"number":42,"html_url":"https://github.com/acme/widgets/pull/42","state":"open","merged_at":null,"merge_commit_sha":null,"head":{"sha":"abc123"},"base":{"ref":"main"}}]
JSON
write_fixture GET "repos/$repo/pulls/42/reviews" <<'JSON'
[{"user":{"login":"alice"},"state":"APPROVED","submitted_at":"2026-01-01T00:00:00Z"},{"user":{"login":"alice"},"state":"DISMISSED","submitted_at":"2026-01-02T00:00:00Z"}]
JSON
if out=$(bash "$script" pr list-for-branch feat/x 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "review_decision" "null" "$(jq -r '.review_decision' <<<"$out")"

case_desc="pr list-for-branch feat/x (latest review per user is APPROVED)"
reset_case
write_fixture GET "repos/$repo/pulls" <<'JSON'
[{"number":42,"html_url":"https://github.com/acme/widgets/pull/42","state":"open","merged_at":null,"merge_commit_sha":null,"head":{"sha":"abc123"},"base":{"ref":"main"}}]
JSON
write_fixture GET "repos/$repo/pulls/42/reviews" <<'JSON'
[{"user":{"login":"bob"},"state":"CHANGES_REQUESTED","submitted_at":"2026-01-01T00:00:00Z"},{"user":{"login":"bob"},"state":"APPROVED","submitted_at":"2026-01-03T00:00:00Z"}]
JSON
if out=$(bash "$script" pr list-for-branch feat/x 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "review_decision" "APPROVED" "$(jq -r '.review_decision' <<<"$out")"

case_desc="pr list-for-branch feat/y (reviews fetched successfully, array empty)"
reset_case
write_fixture GET "repos/$repo/pulls" <<'JSON'
[{"number":50,"html_url":"https://github.com/acme/widgets/pull/50","state":"open","merged_at":null,"merge_commit_sha":null,"head":{"sha":"empty123"},"base":{"ref":"main"}}]
JSON
write_fixture GET "repos/$repo/pulls/50/reviews" <<'JSON'
[]
JSON
if out=$(bash "$script" pr list-for-branch feat/y 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "review_decision" "null" "$(jq -r '.review_decision' <<<"$out")"

case_desc="pr list-for-branch feat/y (reviews fetch fails — a real failure, not empty)"
reset_case
write_fixture GET "repos/$repo/pulls" <<'JSON'
[{"number":51,"html_url":"https://github.com/acme/widgets/pull/51","state":"open","merged_at":null,"merge_commit_sha":null,"head":{"sha":"fail123"},"base":{"ref":"main"}}]
JSON
mark_fail GET "repos/$repo/pulls/51/reviews"
if out=$(bash "$script" pr list-for-branch feat/y 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "stdout" "" "$out"
assert_contains "stderr names the PR" "51" "$(cat "$err_file")"

case_desc="pr view 12 (mergeable_state: behind)"
reset_case
write_fixture GET "repos/$repo/pulls/12" <<'JSON'
{"mergeable_state":"behind","mergeable":true}
JSON
if out=$(bash "$script" pr view 12 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "mergeStateStatus" "BEHIND" "$(jq -r '.mergeStateStatus' <<<"$out")"
assert_eq "mergeable" "true" "$(jq -r '.mergeable' <<<"$out")"

case_desc="pr view 12 (mergeable_state: dirty)"
reset_case
write_fixture GET "repos/$repo/pulls/12" <<'JSON'
{"mergeable_state":"dirty","mergeable":false}
JSON
if out=$(bash "$script" pr view 12 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "mergeStateStatus" "CONFLICTING" "$(jq -r '.mergeStateStatus' <<<"$out")"
assert_eq "mergeable" "false" "$(jq -r '.mergeable' <<<"$out")"

case_desc="pr view 12 (mergeable still null while GitHub computes it)"
reset_case
write_fixture GET "repos/$repo/pulls/12" <<'JSON'
{"mergeable_state":"unknown","mergeable":null}
JSON
if out=$(bash "$script" pr view 12 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "mergeStateStatus" "UNKNOWN" "$(jq -r '.mergeStateStatus' <<<"$out")"
assert_eq "mergeable" "null" "$(jq -c '.mergeable' <<<"$out")"

case_desc="pr view 13 (fixture 404s)"
reset_case
mark_fail GET "repos/$repo/pulls/13"
if out=$(bash "$script" pr view 13 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "stdout empty" "" "$out"
assert_contains "stderr names the PR" "13" "$(cat "$err_file")"

case_desc="pr reviews 12"
reset_case
write_fixture GET "repos/$repo/pulls/12/reviews" <<'JSON'
[{"user":{"login":"alice"},"state":"APPROVED"}]
JSON
if out=$(bash "$script" pr reviews 12 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "count" 1 "$(jq 'length' <<<"$out")"
assert_eq "login" "alice" "$(jq -r '.[0].user.login' <<<"$out")"

case_desc="pr comments 12"
reset_case
write_fixture GET "repos/$repo/issues/12/comments" <<'JSON'
[{"id":1,"body":"looks good"}]
JSON
if out=$(bash "$script" pr comments 12 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "body" "looks good" "$(jq -r '.[0].body' <<<"$out")"

case_desc="pr review-comments 12"
reset_case
write_fixture GET "repos/$repo/pulls/12/comments" <<'JSON'
[{"id":2,"path":"foo.cs","body":"nit"}]
JSON
if out=$(bash "$script" pr review-comments 12 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "path" "foo.cs" "$(jq -r '.[0].path' <<<"$out")"

case_desc="pr checks 12"
reset_case
write_fixture GET "repos/$repo/pulls/12" <<'JSON'
{"head":{"sha":"deadbeef"}}
JSON
write_fixture GET "repos/$repo/commits/deadbeef/check-runs" <<'JSON'
{"check_runs":[{"name":"tests","status":"completed","conclusion":"success"}]}
JSON
if out=$(bash "$script" pr checks 12 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "name" "tests" "$(jq -r '.[0].name' <<<"$out")"
assert_eq "conclusion" "success" "$(jq -r '.[0].conclusion' <<<"$out")"

case_desc="pr reviews 12 (fixture 404s)"
reset_case
mark_fail GET "repos/$repo/pulls/12/reviews"
if out=$(bash "$script" pr reviews 12 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "stdout empty" "" "$out"
assert_contains "stderr names the failure" "pr reviews 12" "$(cat "$err_file")"

case_desc="pr comments 12 (fixture 404s)"
reset_case
mark_fail GET "repos/$repo/issues/12/comments"
if out=$(bash "$script" pr comments 12 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "stdout empty" "" "$out"
assert_contains "stderr names the failure" "pr comments 12" "$(cat "$err_file")"

case_desc="pr review-comments 12 (fixture 404s)"
reset_case
mark_fail GET "repos/$repo/pulls/12/comments"
if out=$(bash "$script" pr review-comments 12 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "stdout empty" "" "$out"
assert_contains "stderr names the failure" "pr review-comments 12" "$(cat "$err_file")"

case_desc="pr checks 12 (check-runs 404s)"
reset_case
write_fixture GET "repos/$repo/pulls/12" <<'JSON'
{"head":{"sha":"deadbeef"}}
JSON
mark_fail GET "repos/$repo/commits/deadbeef/check-runs"
if out=$(bash "$script" pr checks 12 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "stdout empty" "" "$out"
assert_contains "stderr names the failure" "pr checks 12" "$(cat "$err_file")"

case_desc="pr checks 12 (two pages merge into one array)"
reset_case
write_fixture GET "repos/$repo/pulls/12" <<'JSON'
{"head":{"sha":"deadbeef"}}
JSON
write_fixture GET "repos/$repo/commits/deadbeef/check-runs" <<'JSON'
{"check_runs":[{"name":"tests","status":"completed","conclusion":"success"}]}
{"check_runs":[{"name":"qc-verdict","status":"completed","conclusion":"failure"}]}
JSON
if out=$(bash "$script" pr checks 12 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "one array" 2 "$(jq 'length' <<<"$out")"
assert_eq "second page" "qc-verdict" "$(jq -r '.[1].name' <<<"$out")"
assert_contains "paginated" "check-runs PAGINATE=1" "$(cat "$calls_log")"

case_desc="label list (two pages)"
reset_case
write_fixture GET "repos/$repo/labels" <<'JSON'
[{"name":"bug"}]
[{"name":"enhancement"}]
JSON
if out=$(bash "$script" label list 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "labels" "$(printf 'bug\nenhancement')" "$out"
assert_contains "paginated" "PATH=repos/$repo/labels PAGINATE=1" "$(cat "$calls_log")"

case_desc="pr list-for-branch leaves no temp file when a call fails"
reset_case
write_fixture GET "repos/$repo/pulls" <<'JSON'
[{"number":51,"html_url":"u","state":"open","merged_at":null,"merge_commit_sha":null,"head":{"sha":"f"},"base":{"ref":"main"}}]
JSON
mark_fail GET "repos/$repo/pulls/51/reviews"
tmp_home=$(mktemp -d)
if out=$(TMPDIR=$tmp_home bash "$script" pr list-for-branch feat/y 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "temp files left" 0 "$(find "$tmp_home" -type f | wc -l | tr -d ' ')"
rm -rf "$tmp_home"

case_desc="pr list-for-branch leaves no temp file when TMPDIR holds a quote"
reset_case
write_fixture GET "repos/$repo/pulls" <<'JSON'
[{"number":51,"html_url":"u","state":"open","merged_at":null,"merge_commit_sha":null,"head":{"sha":"f"},"base":{"ref":"main"}}]
JSON
mark_fail GET "repos/$repo/pulls/51/reviews"
tmp_home=$(mktemp -d "$scratch_dir/it's.XXXXXX")
if out=$(TMPDIR=$tmp_home bash "$script" pr list-for-branch feat/y 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "temp files left" 0 "$(find "$tmp_home" -type f | wc -l | tr -d ' ')"

case_desc="pr create"
reset_case
write_fixture POST "repos/$repo/pulls" <<'JSON'
{"number":99,"html_url":"https://github.com/acme/widgets/pull/99"}
JSON
if out=$(bash "$script" pr create "My PR title" "$scratch_dir/body.txt" feat/x main 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "number" 99 "$(jq -r '.number' <<<"$out")"
assert_eq "html_url" "https://github.com/acme/widgets/pull/99" "$(jq -r '.html_url' <<<"$out")"
assert_contains "title field" "FIELD=title=My PR title" "$(cat "$calls_log")"
assert_contains "head field" "FIELD=head=feat/x" "$(cat "$calls_log")"
assert_contains "base field" "FIELD=base=main" "$(cat "$calls_log")"
assert_eq "no draft field" 0 "$(grep -c 'FIELD=draft=' "$calls_log" || true)"

case_desc="pr create --draft"
reset_case
write_fixture POST "repos/$repo/pulls" <<'JSON'
{"number":99,"html_url":"https://github.com/acme/widgets/pull/99"}
JSON
if out=$(bash "$script" pr create --draft "My PR title" "$scratch_dir/body.txt" feat/x main 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "number" 99 "$(jq -r '.number' <<<"$out")"
assert_contains "title field" "FIELD=title=My PR title" "$(cat "$calls_log")"
assert_contains "head field" "FIELD=head=feat/x" "$(cat "$calls_log")"
assert_contains "draft field" "FIELD=draft=true" "$(cat "$calls_log")"

case_desc="pr create (POST fails)"
reset_case
mark_fail POST "repos/$repo/pulls"
if out=$(bash "$script" pr create "My PR title" "$scratch_dir/body.txt" feat/x main 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "stdout empty" "" "$out"
assert_contains "stderr names the failure" "pr create" "$(cat "$err_file")"

case_desc="pr comment 12 body.txt"
reset_case
write_fixture POST "repos/$repo/issues/12/comments" <<'JSON'
{"id":5}
JSON
if out=$(bash "$script" pr comment 12 "$scratch_dir/body.txt" 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"

case_desc="run list wiki.yml abc123"
reset_case
write_fixture GET "repos/$repo/actions/workflows/wiki.yml/runs" <<'JSON'
{"workflow_runs":[{"status":"completed","conclusion":"success","html_url":"https://github.com/acme/widgets/actions/runs/1"}]}
JSON
if out=$(bash "$script" run list wiki.yml abc123 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "status" "completed" "$(jq -r '.status' <<<"$out")"
assert_eq "conclusion" "success" "$(jq -r '.conclusion' <<<"$out")"
assert_eq "html_url" "https://github.com/acme/widgets/actions/runs/1" "$(jq -r '.html_url' <<<"$out")"
assert_contains "sent as GET" "METHOD=GET PATH=repos/$repo/actions/workflows/wiki.yml/runs" "$(cat "$calls_log")"

case_desc="run list wiki.yml deadsha (fixture 404s)"
reset_case
mark_fail GET "repos/$repo/actions/workflows/wiki.yml/runs"
if out=$(bash "$script" run list wiki.yml deadsha 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "stdout empty" "" "$out"
assert_contains "stderr names the failure" "run list" "$(cat "$err_file")"

case_desc="workflow dispatch workflow-status.yml feat/x"
reset_case
write_fixture POST "repos/$repo/actions/workflows/workflow-status.yml/dispatches" <<'JSON'
{}
JSON
if out=$(bash "$script" workflow dispatch workflow-status.yml feat/x 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "stdout empty" "" "$out"
assert_contains "call" "METHOD=POST PATH=repos/$repo/actions/workflows/workflow-status.yml/dispatches FIELD=ref=feat/x" "$(cat "$calls_log")"

case_desc="workflow dispatch workflow-status.yml feat/x (POST fails)"
reset_case
mark_fail POST "repos/$repo/actions/workflows/workflow-status.yml/dispatches"
if out=$(bash "$script" workflow dispatch workflow-status.yml feat/x 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "stdout empty" "" "$out"
assert_contains "stderr names the failure" "workflow dispatch workflow-status.yml feat/x" "$(cat "$err_file")"

case_desc="workflow dispatch (ref missing)"
reset_case
if out=$(bash "$script" workflow dispatch workflow-status.yml 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit non-zero" 1 "$((rc != 0))"
assert_eq "stdout empty" "" "$out"
assert_eq "no gh call" "" "$(cat "$calls_log")"

case_desc="label list"
reset_case
write_fixture GET "repos/$repo/labels" <<'JSON'
[{"name":"bug"},{"name":"enhancement"}]
JSON
if out=$(bash "$script" label list 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 0 "$rc"
assert_eq "labels" "$(printf 'bug\nenhancement')" "$out"

case_desc="label list (fixture 404s)"
reset_case
mark_fail GET "repos/$repo/labels"
if out=$(bash "$script" label list 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_eq "stdout empty" "" "$out"
assert_contains "stderr names the failure" "label list" "$(cat "$err_file")"

case_desc="no such verb"
reset_case
if out=$(bash "$script" bogus 2>"$err_file"); then rc=0; else rc=$?; fi
assert_eq "exit code" 1 "$rc"
assert_contains "usage on stderr" "usage: github.sh" "$(cat "$err_file")"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
