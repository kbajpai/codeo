#!/usr/bin/env bash
# Exercises scripts/cleanup.sh on a scratch bare origin plus clone and a stubbed `gh api`:
# each proof failing in turn (issue, pull-request, branch, dossier, lease, name), the overlay's name check, and that nothing is ever run.
# The overlay body arrives through the scratch project's .codeo/overlays/cleanup.md (set_overlay), which overlay.sh reads.
# Touches no real git config and makes no network call.
#
#   cleanup.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_src=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script=$plugin_src/scripts/cleanup.sh

export GIT_AUTHOR_NAME="Cleanup Test" GIT_AUTHOR_EMAIL="cleanup-test@example.com"
export GIT_COMMITTER_NAME="Cleanup Test" GIT_COMMITTER_EMAIL="cleanup-test@example.com"

scratch_root=$(mktemp -d)
trap 'rm -rf "$scratch_root"' EXIT
export HOME="$scratch_root/home"
mkdir -p "$HOME"
unset CODEO_CLEANUP_REMOVAL

# A stub `gh api`: the answer is $GH_STUB_DIR/GET_<path with / as _>.json, or a failed call.
stub_bin="$scratch_root/bin"
export GH_STUB_DIR="$scratch_root/canned"
mkdir -p "$stub_bin" "$GH_STUB_DIR"
cat > "$stub_bin/gh" <<'STUB'
#!/usr/bin/env bash
[[ ${1:-} == api ]] || exit 1
shift
path= filter=
while (($#)); do
    case $1 in
        -q) filter=$2; shift 2 ;;
        -X | -f | -F) shift 2 ;;
        -*) shift ;;
        *) path=$1; shift ;;
    esac
done
file="$GH_STUB_DIR/GET_${path//\//_}.json"
[[ -f $file ]] || { echo '{"message":"Not Found"}'; exit 1; }
if [[ -n $filter ]]; then jq -r -c "$filter" "$file"; else cat "$file"; fi
STUB
chmod +x "$stub_bin/gh"
# A container-engine stand-in that records any call: cleanup.sh must never make one.
export DOCKER_MARKER="$scratch_root/docker-called"
# shellcheck disable=SC2016
printf '#!/usr/bin/env bash\necho "$*" >> "$DOCKER_MARKER"\n' > "$stub_bin/docker"
chmod +x "$stub_bin/docker"

failures=0
case_desc=
assert_eq() {
    if [[ $2 != "$3" ]]; then
        echo "FAIL: $case_desc — $1: want [$2] got [$3]"
        failures=$((failures + 1))
    fi
}

tab=$'\t'
overlay=$'name: codeo-{N}\npattern: ^codeo-[0-9]+$\ncommand: docker rm -f {name}; docker volume rm {name}'
want_cmd='docker rm -f codeo-12; docker volume rm codeo-12'

# set_overlay <body>: the scratch project's cleanup overlay, whose removal-command section is the body; none for an empty body.
set_overlay() {
    local file=$REPO_WORK/.codeo/overlays/cleanup.md
    if [[ -z $1 ]]; then
        rm -f "$file"
        return 0
    fi
    mkdir -p "${file%/*}"
    printf '## removal-command\n%s\n' "$1" > "$file"
}

# fixture <N> <issue state> <pr number|none> <merged_at|null> <head ref>
fixture() {
    local n=$1 state=$2 pr=$3 merged=$4 ref=$5
    printf '{"number":%s,"state":"%s","labels":[],"assignees":[]}' "$n" "$state" > "$GH_STUB_DIR/GET_repos_o_n_issues_$n.json"
    [[ $pr == none ]] && return 0
    local m=null
    [[ $merged == null ]] || m="\"$merged\""
    printf '{"state":"closed","merged_at":%s,"head":{"ref":"%s"}}' "$m" "$ref" > "$GH_STUB_DIR/GET_repos_o_n_pulls_$pr.json"
}

# A scratch origin whose main carries .codeo/done/<N>/close.md for each "N:body" argument; a clone of it.
setup_repo() {
    local origin work
    origin=$(mktemp -d "$scratch_root/origin.XXXXXX")
    git init -q --bare -b main "$origin"
    work=$(mktemp -d "$scratch_root/work.XXXXXX")
    git clone -q "$origin" "$work" 2>/dev/null
    git -C "$work" checkout -q -b main
    echo x > "$work/README.md"
    local spec n
    for spec in "$@"; do
        n=${spec%%:*}
        mkdir -p "$work/.codeo/done/$n"
        printf '%s\n' "${spec#*:}" > "$work/.codeo/done/$n/close.md"
    done
    git -C "$work" add -A
    git -C "$work" commit -q -m init
    git -C "$work" push -q origin main
    mkdir -p "$work/.codeo"
    printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}\n' > "$work/.codeo/config.json"
    REPO_WORK=$work
}

# A branch on origin, optionally carrying a .codeo/<N>/ dossier.
push_branch() {
    local name=$1 dossier=${2:-}
    git -C "$REPO_WORK" checkout -q -b "$name" main
    if [[ -n $dossier ]]; then
        mkdir -p "$REPO_WORK/.codeo/$dossier"
        echo d > "$REPO_WORK/.codeo/$dossier/plan.md"
        git -C "$REPO_WORK" add -f ".codeo/$dossier/plan.md"
    fi
    git -C "$REPO_WORK" commit -q --allow-empty -m "$name"
    git -C "$REPO_WORK" push -q origin "$name"
    git -C "$REPO_WORK" checkout -q main
    [[ -z $dossier ]] || rm -rf "$REPO_WORK/.codeo/$dossier"
}

run_cleanup() {
    (cd "$REPO_WORK" && PATH="$stub_bin:$PATH" bash "$script" 2>&1) || true
}

body='Opened.
#41 https://github.com/o/n/pull/41'

case_desc="all five proofs pass"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay "$overlay"
assert_eq "line" "12${tab}proven${tab}$want_cmd${tab}-" "$(run_cleanup)"

case_desc="leftover branches of a proven issue are printed after its line"
setup_repo "7:$body"
fixture 7 closed 41 2026-01-01T00:00:00Z feat/7
push_branch codeo-live/7/web-a
push_branch codeo-live/7/web-b
assert_eq "lines" "7${tab}proven${tab}-${tab}-
7${tab}leftover${tab}git push origin --delete codeo-live/7/web-a codeo-live/7/web-b" "$(run_cleanup)"

case_desc="an issue that failed a proof gets no leftover line"
setup_repo "7:$body"
fixture 7 open 41 2026-01-01T00:00:00Z feat/7
push_branch codeo-live/7/web-a
assert_eq "line" "7${tab}failed${tab}issue" "$(run_cleanup)"

case_desc="a leftover branch with metacharacters is not printed"
setup_repo "7:$body"
fixture 7 closed 41 2026-01-01T00:00:00Z feat/7
push_branch codeo-live/7/web-a
push_branch 'codeo-live/7/x;touch-y'
assert_eq "lines" "7${tab}proven${tab}-${tab}-
7${tab}leftover${tab}git push origin --delete codeo-live/7/web-a" "$(run_cleanup)"

case_desc="an issue that failed only the name proof still gets its leftover line"
setup_repo "7:$body"
fixture 7 closed 41 2026-01-01T00:00:00Z feat/7
set_overlay 'name: codeo-{N}'
push_branch codeo-live/7/web-a
assert_eq "lines" "7${tab}failed${tab}name
7${tab}leftover${tab}git push origin --delete codeo-live/7/web-a" "$(run_cleanup)"

case_desc="an issue that failed only the name proof with no leftover branch gets one line"
setup_repo "7:$body"
fixture 7 closed 41 2026-01-01T00:00:00Z feat/7
set_overlay 'name: codeo-{N}'
assert_eq "line" "7${tab}failed${tab}name" "$(run_cleanup)"

case_desc="leftovers of another issue are not printed"
setup_repo "7:$body"
fixture 7 closed 41 2026-01-01T00:00:00Z feat/7
push_branch codeo-live/70/web-z
assert_eq "line" "7${tab}proven${tab}-${tab}-" "$(run_cleanup)"

case_desc="issue still open"
setup_repo "12:$body"
fixture 12 open 41 2026-01-01T00:00:00Z feat/12
assert_eq "line" "12${tab}failed${tab}issue" "$(run_cleanup)"

case_desc="an unreadable issue stops the script: exit non-zero, a cleanup: line, no proven or failed line"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
rm "$GH_STUB_DIR/GET_repos_o_n_issues_12.json"
rc=0
err=$(cd "$REPO_WORK" && PATH="$stub_bin:$PATH" bash "$script" 2>&1 >"$scratch_root/out.txt") || rc=$?
assert_eq "exit non-zero" "yes" "$([[ $rc -ne 0 ]] && echo yes || echo no)"
assert_eq "stderr" "cleanup: could not read issue #12" "$err"
assert_eq "stdout empty" "" "$(cat "$scratch_root/out.txt")"

case_desc="pull request not merged"
setup_repo "12:$body"
fixture 12 closed 41 null feat/12
assert_eq "line" "12${tab}failed${tab}pull-request" "$(run_cleanup)"

case_desc="close.md has no pull request line"
setup_repo "12:Nothing opened."
fixture 12 closed none null x
assert_eq "line" "12${tab}failed${tab}pull-request" "$(run_cleanup)"

case_desc="branch still on origin"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
push_branch feat/12
assert_eq "line" "12${tab}failed${tab}branch" "$(run_cleanup)"

case_desc="branch deleted on origin is pruned by the fetch and passes"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay "$overlay"
push_branch feat/12
git -C "$REPO_WORK" fetch -q origin
git -C "$REPO_WORK" push -q origin --delete feat/12
assert_eq "line" "12${tab}proven${tab}$want_cmd${tab}-" "$(run_cleanup)"

case_desc="a failing fetch exits non-zero with a cleanup: message and no proven line"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
git -C "$REPO_WORK" remote set-url origin "$scratch_root/does-not-exist"
rc=0
out=$(cd "$REPO_WORK" && PATH="$stub_bin:$PATH" bash "$script" 2>&1) || rc=$?
assert_eq "exit non-zero" "yes" "$([[ $rc -ne 0 ]] && echo yes || echo no)"
assert_eq "cleanup: message" "yes" "$([[ $out == *"cleanup: fetch failed"* ]] && echo yes || echo no)"
assert_eq "no proven line" "no" "$([[ $out == *"${tab}proven"* ]] && echo yes || echo no)"

case_desc="a single-branch clone proves nothing: exit non-zero, a cleanup: refspec message, no proven line"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
git -C "$REPO_WORK" config remote.origin.fetch '+refs/heads/main:refs/remotes/origin/main'
rc=0
out=$(cd "$REPO_WORK" && PATH="$stub_bin:$PATH" bash "$script" 2>&1) || rc=$?
assert_eq "exit non-zero" "yes" "$([[ $rc -ne 0 ]] && echo yes || echo no)"
assert_eq "cleanup: refspec message" "yes" "$([[ $out == "cleanup: "*refspec* ]] && echo yes || echo no)"
assert_eq "no proven line" "no" "$([[ $out == *"${tab}proven"* ]] && echo yes || echo no)"

case_desc="a name containing & is substituted literally"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay $'name: a&b-{N}\npattern: ^a&b-[0-9]+$\ncommand: rm {name} {name}'
assert_eq "line" "12${tab}proven${tab}rm a&b-12 a&b-12${tab}-" "$(run_cleanup)"

case_desc="{N} is expanded in the command as well as {name}"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay $'name: codeo-{N}\npattern: ^codeo-[0-9]+$\ncommand: remove {N} {name}'
assert_eq "line" "12${tab}proven${tab}remove 12 codeo-12${tab}-" "$(run_cleanup)"

# Like run_cleanup, but a last line `rc=<exit status>` keeps the exit status.
run_cleanup_rc() {
    local rc=0 out
    out=$(cd "$REPO_WORK" && PATH="$stub_bin:$PATH" bash "$script" 2>&1) || rc=$?
    printf '%s\nrc=%s' "$out" "$rc"
}

case_desc="an unexpanded placeholder in the command stops the run"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay $'name: codeo-{N}\npattern: ^codeo-[0-9]+$\ncommand: codeo rm {M}'
assert_eq "line" $'cleanup: the overlay\'s command: keeps a placeholder the script does not expand: {M}\nrc=1' "$(run_cleanup_rc)"

case_desc="an unexpanded placeholder in the fallback stops the run"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay $'name: codeo-{N}\npattern: ^codeo-[0-9]+$\ncommand: codeo rm {N}\nfallback: run {issue}'
assert_eq "line" $'cleanup: the overlay\'s fallback: keeps a placeholder the script does not expand: {issue}\nrc=1' "$(run_cleanup_rc)"

case_desc="a shell brace and a Go template are not placeholders"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay $'name: codeo-{N}\npattern: ^codeo-[0-9]+$\ncommand: x {{.Names}}'
assert_eq "line" "12${tab}proven${tab}x {{.Names}}${tab}-" "$(run_cleanup)"
set_overlay $'name: codeo-{N}\npattern: ^codeo-[0-9]+$\ncommand: x ${HOME}'
assert_eq "line" $'cleanup: the overlay\'s command: keeps a placeholder the script does not expand: {HOME}\nrc=1' "$(run_cleanup_rc)"

case_desc="a doubled brace around {N} is refused"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay $'name: codeo-{N}\npattern: ^codeo-[0-9]+$\ncommand: rm {{N}}'
assert_eq "line" $'cleanup: the overlay\'s command: keeps a placeholder the script does not expand: {1}\nrc=1' "$(run_cleanup_rc)"

case_desc="a placeholder in the name template is refused when the command prints it"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay $'name: x-{M}\npattern: ^x-.*$\ncommand: rm {name}'
assert_eq "line" $'cleanup: the overlay\'s command: keeps a placeholder the script does not expand: {M}\nrc=1' "$(run_cleanup_rc)"

case_desc="a name template that no printed text uses is not refused"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay $'name: x-{M}\npattern: ^x-.*$\ncommand: codeo rm {N}'
assert_eq "line" "12${tab}proven${tab}codeo rm 12${tab}-" "$(run_cleanup)"

case_desc="a brace expansion is not a placeholder"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay $'name: codeo-{N}\npattern: ^codeo-[0-9]+$\ncommand: rm codeo-{1,2}'
assert_eq "line" "12${tab}proven${tab}rm codeo-{1,2}${tab}-" "$(run_cleanup)"

case_desc="dossier still on another branch"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
push_branch other/thing 12
assert_eq "line" "12${tab}failed${tab}dossier" "$(run_cleanup)"

case_desc="done/<N> alone is not a dossier"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay "$overlay"
push_branch other/thing 13
assert_eq "line" "12${tab}proven${tab}$want_cmd${tab}-" "$(run_cleanup)"

# A lease on origin's codeo/intake branch: push_lease <held|waiting> <resource> <N>
push_lease() {
    local kind=$1 resource=$2 n=$3 t file
    t=$(mktemp -d "$scratch_root/lease.XXXXXX")
    git clone -q "$(git -C "$REPO_WORK" remote get-url origin)" "$t" 2>/dev/null
    if git -C "$t" rev-parse -q --verify origin/codeo/intake >/dev/null; then
        git -C "$t" checkout -q -B codeo/intake origin/codeo/intake
    else
        git -C "$t" checkout -q --orphan codeo/intake
        git -C "$t" rm -rqf . 2>/dev/null || true
    fi
    if [[ $kind == held ]]; then file=$t/.codeo/intake/leases/$resource.md; else file=$t/.codeo/intake/leases/waiting/$resource-$n.md; fi
    mkdir -p "$(dirname "$file")"
    printf 'issue:   #%s\nbranch:  feat/%s\nby:      someone@example.com\nsince:   2026-01-01T00:00:00Z\npurpose: p\n' "$n" "$n" > "$file"
    git -C "$t" add -A
    git -C "$t" commit -q -m "lease $kind"
    git -C "$t" push -q origin codeo/intake
}

case_desc="a lease the issue holds on the intake branch"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
push_lease held dev 12
assert_eq "line" "12${tab}failed${tab}lease" "$(run_cleanup)"

case_desc="a wait the issue has recorded"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
push_lease waiting dev 12
assert_eq "line" "12${tab}failed${tab}lease" "$(run_cleanup)"

case_desc="another issue's lease does not fail this one; the intake branch is read once"
setup_repo "12:$body" "13:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay "$overlay"
fixture 13 closed 42 2026-01-01T00:00:00Z feat/13
push_lease held dev 13
assert_eq "lines" "12${tab}proven${tab}$want_cmd${tab}-
13${tab}failed${tab}lease" "$(run_cleanup)"

case_desc="no intake branch at all: the issue is still proven"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay "$overlay"
assert_eq "line" "12${tab}proven${tab}$want_cmd${tab}-" "$(run_cleanup)"

case_desc="an unreadable lease list stops the script"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
fake_plugin=$scratch_root/plugin-no-intake
rm -rf "$fake_plugin"
mkdir -p "$fake_plugin"
cp -r "$plugin_src/scripts" "$plugin_src/lib" "$fake_plugin"/
printf '#!/usr/bin/env bash\nexit 1\n' > "$fake_plugin/scripts/intake.sh"
rc=0
err=$(cd "$REPO_WORK" && PATH="$stub_bin:$PATH" bash "$fake_plugin/scripts/cleanup.sh" 2>&1 >"$scratch_root/out.txt") || rc=$?
assert_eq "exit non-zero" "yes" "$([[ $rc -ne 0 ]] && echo yes || echo no)"
assert_eq "stderr" "cleanup: could not read the leases" "$err"
assert_eq "stdout empty" "" "$(cat "$scratch_root/out.txt")"
rm -rf "$fake_plugin"

case_desc="a pull request whose head ref is null fails the branch proof"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
printf '{"state":"closed","merged_at":"2026-01-01T00:00:00Z","head":{"ref":null}}' > "$GH_STUB_DIR/GET_repos_o_n_pulls_41.json"
assert_eq "line" "12${tab}failed${tab}branch" "$(run_cleanup)"

case_desc="a pull request whose head ref is empty fails the branch proof"
printf '{"state":"closed","merged_at":"2026-01-01T00:00:00Z","head":{"ref":""}}' > "$GH_STUB_DIR/GET_repos_o_n_pulls_41.json"
assert_eq "line" "12${tab}failed${tab}branch" "$(run_cleanup)"

for bad in codeo-home codeo-gh codeo-git; do
    case_desc="name template expands to $bad"
    setup_repo "12:$body"
    fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
    set_overlay $'name: '"$bad"$'\npattern: ^codeo-[0-9]+$\ncommand: docker rm -f {name}'
    assert_eq "line" "12${tab}failed${tab}name" "$(run_cleanup)"
done

case_desc="overlay without a pattern"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay $'name: codeo-{N}\ncommand: docker rm -f {name}'
assert_eq "line" "12${tab}failed${tab}name" "$(run_cleanup)"

case_desc="overlay without a command"
set_overlay $'name: codeo-{N}\npattern: ^codeo-[0-9]+$'
assert_eq "line" "12${tab}failed${tab}name" "$(run_cleanup)"

case_desc="an_exported_removal_override_changes_nothing"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay $'name: codeo-{N}\npattern: ^codeo-[0-9]+$\ncommand: docker rm -f {name}'
plain=$(run_cleanup)
assert_eq "line with an overlay, before the export" "12${tab}proven${tab}docker rm -f codeo-12${tab}-" "$plain"
export CODEO_CLEANUP_REMOVAL=$'name: x-{N}\npattern: ^x-[0-9]+$\ncommand: rm {name}'
assert_eq "line with an overlay" "$plain" "$(run_cleanup)"
set_overlay ""
assert_eq "line without an overlay" "12${tab}proven${tab}-${tab}-" "$(run_cleanup)"
unset CODEO_CLEANUP_REMOVAL

case_desc="no overlay at all"
set_overlay ""
assert_eq "line" "12${tab}proven${tab}-${tab}-" "$(run_cleanup)"

case_desc="ascending N, mixed outcomes"
setup_repo "30:$body" "7:$body" "12:$body"
fixture 30 closed 41 2026-01-01T00:00:00Z feat/30
fixture 7 open 41 2026-01-01T00:00:00Z feat/7
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay "$overlay"
assert_eq "lines" "7${tab}failed${tab}issue
12${tab}proven${tab}$want_cmd${tab}-
30${tab}proven${tab}${want_cmd//codeo-12/codeo-30}${tab}-" "$(run_cleanup)"

case_desc="fallback_expanded"
setup_repo "7:$body"
fixture 7 closed 41 2026-01-01T00:00:00Z feat/7
set_overlay $'name: codeo-{N}\npattern: ^codeo-[0-9]+$\ncommand: codeo rm {N}\nfallback: docker rm -f {name} then mark {N}'
assert_eq "line" "7${tab}proven${tab}codeo rm 7${tab}docker rm -f codeo-7 then mark 7" "$(run_cleanup)"

case_desc="fallback_absent_is_dash"
set_overlay $'name: codeo-{N}\npattern: ^codeo-[0-9]+$\ncommand: codeo rm {N}'
assert_eq "line" "7${tab}proven${tab}codeo rm 7${tab}-" "$(run_cleanup)"

case_desc="failed_lines_unchanged"
set_overlay $'name: codeo-{N}\npattern: ^nope-[0-9]+$\ncommand: codeo rm {N}\nfallback: docker rm -f {name}'
assert_eq "name failure" "7${tab}failed${tab}name" "$(run_cleanup)"
fixture 7 open 41 2026-01-01T00:00:00Z feat/7
set_overlay $'name: codeo-{N}\npattern: ^codeo-[0-9]+$\ncommand: codeo rm {N}\nfallback: docker rm -f {name}'
assert_eq "proof failure" "7${tab}failed${tab}issue" "$(run_cleanup)"

# A removal record on origin's codeo/intake branch: push_removed <N>…
push_removed() {
    local t n
    t=$(mktemp -d "$scratch_root/removed.XXXXXX")
    git clone -q "$(git -C "$REPO_WORK" remote get-url origin)" "$t" 2>/dev/null
    if git -C "$t" rev-parse -q --verify origin/codeo/intake >/dev/null; then
        git -C "$t" checkout -q -B codeo/intake origin/codeo/intake
    else
        git -C "$t" checkout -q --orphan codeo/intake
        git -C "$t" rm -rqf . 2>/dev/null || true
    fi
    mkdir -p "$t/.codeo/intake/cleanup/removed"
    for n; do
        printf 'issue:    #%s\nrecorded: 2026-01-01\n' "$n" > "$t/.codeo/intake/cleanup/removed/$n.md"
    done
    git -C "$t" add -A
    git -C "$t" commit -q -m "removed"
    git -C "$t" push -q origin codeo/intake
}

run_record() {
    (cd "$REPO_WORK" && PATH="$stub_bin:$PATH" bash "$script" record "$@" 2>&1) || true
}

case_desc="record writes one file per issue"
setup_repo "12:$body" "30:$body"
rec=$REPO_WORK/.codeo/intake/cleanup/removed
assert_eq "lines" "12${tab}recorded
30${tab}recorded" "$(run_record 12 30)"
assert_eq "issue line" "issue:    #12" "$(sed -n 1p "$rec/12.md")"
assert_eq "date line" "recorded: $(date -u +%F)" "$(sed -n 2p "$rec/12.md")"
assert_eq "30 file" "yes" "$([[ -f $rec/30.md ]] && echo yes || echo no)"
assert_eq "tracked files unchanged" "" "$(git -C "$REPO_WORK" status --porcelain --untracked-files=no)"
assert_eq "no commit" "init" "$(git -C "$REPO_WORK" log -1 --format=%s)"

case_desc="record refuses before writing"
setup_repo "12:$body"
rec=$REPO_WORK/.codeo/intake/cleanup/removed
for args in "12 99" "12 abc" "012" ""; do
    rc=0
    # shellcheck disable=SC2086
    out=$(cd "$REPO_WORK" && PATH="$stub_bin:$PATH" bash "$script" record $args 2>&1) || rc=$?
    assert_eq "exit 1 [$args]" "1" "$rc"
    assert_eq "cleanup: line [$args]" "yes" "$([[ $out == cleanup:* ]] && echo yes || echo no)"
    assert_eq "no file [$args]" "absent" "$([[ -e $rec/12.md ]] && echo present || echo absent)"
done

case_desc="record is idempotent"
setup_repo "12:$body" "30:$body"
rec=$REPO_WORK/.codeo/intake/cleanup/removed
run_record 12 >/dev/null
before=$(cat "$rec/12.md")
assert_eq "second run" "12${tab}already recorded" "$(run_record 12)"
assert_eq "file as it was" "$before" "$(cat "$rec/12.md")"
push_removed 30
assert_eq "recorded on origin" "30${tab}already recorded" "$(run_record 30)"
assert_eq "no local file for a record on origin" "absent" "$([[ -e $rec/30.md ]] && echo present || echo absent)"

case_desc="record runs no container command and no proof"
setup_repo "12:$body"
rm -f "$DOCKER_MARKER" "$GH_STUB_DIR"/GET_repos_o_n_issues_12.json
assert_eq "line" "12${tab}recorded" "$(run_record 12)"
assert_eq "marker" "absent" "$([[ -e $DOCKER_MARKER ]] && echo present || echo absent)"

# stdout and stderr apart: run_cleanup_split sets cleanup_out and cleanup_err.
run_cleanup_split() {
    local errf=$scratch_root/split.err
    cleanup_out=$(cd "$REPO_WORK" && PATH="$stub_bin:$PATH" bash "$script" 2>"$errf") || true
    cleanup_err=$(cat "$errf")
}
hide_note="cleanup: note: 1 issue(s) with a recorded removal are not listed"

# Issues 12 and 30, both proven, as in the ascending case.
two_proven() {
    setup_repo "12:$body" "30:$body"
    fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
    fixture 30 closed 42 2026-01-01T00:00:00Z feat/30
    set_overlay "$overlay"
}

case_desc="a recorded issue that passes is not listed"
two_proven
push_removed 12
run_cleanup_split
assert_eq "stdout" "30${tab}proven${tab}docker rm -f codeo-30; docker volume rm codeo-30${tab}-" "$cleanup_out"
assert_eq "stderr" "$hide_note" "$cleanup_err"

case_desc="a recorded issue whose proof fails is listed as not proven"
two_proven
fixture 12 open 41 2026-01-01T00:00:00Z feat/12
push_removed 12
run_cleanup_split
assert_eq "stdout" "12${tab}failed${tab}issue
30${tab}proven${tab}docker rm -f codeo-30; docker volume rm codeo-30${tab}-" "$cleanup_out"
assert_eq "stderr" "" "$cleanup_err"

case_desc="a recorded issue whose only failure is name is listed as not proven"
two_proven
set_overlay $'name: codeo-{N}\npattern: ^codeo-3[0-9]$\ncommand: docker rm -f {name}'
push_removed 12
run_cleanup_split
assert_eq "stdout" "12${tab}failed${tab}name
30${tab}proven${tab}docker rm -f codeo-30${tab}-" "$cleanup_out"
assert_eq "stderr" "" "$cleanup_err"

case_desc="a recorded issue keeps its leftover line"
two_proven
push_branch codeo-live/12/m
push_removed 12
run_cleanup_split
assert_eq "stdout" "12${tab}leftover${tab}git push origin --delete codeo-live/12/m
30${tab}proven${tab}docker rm -f codeo-30; docker volume rm codeo-30${tab}-" "$cleanup_out"
assert_eq "stderr" "$hide_note" "$cleanup_err"

case_desc="a record for another issue hides nothing"
two_proven
push_removed 99
run_cleanup_split
assert_eq "stdout" "12${tab}proven${tab}$want_cmd${tab}-
30${tab}proven${tab}docker rm -f codeo-30; docker volume rm codeo-30${tab}-" "$cleanup_out"
assert_eq "stderr" "" "$cleanup_err"

# A clone of origin with the project's config, as an engineer's checkout: new_clone <var>
new_clone() {
    local d
    d=$(mktemp -d "$scratch_root/engineer.XXXXXX")
    git clone -q "$(git -C "$REPO_WORK" remote get-url origin)" "$d" 2>/dev/null
    mkdir -p "$d/.codeo"
    cp "$REPO_WORK/.codeo/config.json" "$d/.codeo/config.json"
    printf -v "$1" '%s' "$d"
}
commit_in() {
    (cd "$1" && PATH="$stub_bin:$PATH" bash "$plugin_src/scripts/intake.sh" commit cleanup "x" >/dev/null 2>&1) || true
}
record_in() {
    (cd "$1" && PATH="$stub_bin:$PATH" bash "$script" record "$2" >/dev/null 2>&1) || true
}

case_desc="two engineers keep each other's records"
two_proven
new_clone clone_b
# Both clones exist and have recorded before either commits: A commits first, then B.
record_in "$REPO_WORK" 12
record_in "$clone_b" 30
commit_in "$REPO_WORK"
commit_in "$clone_b"
git -C "$REPO_WORK" fetch -q origin
assert_eq "files" "12.md
30.md" "$(git -C "$REPO_WORK" ls-tree -r --name-only origin/codeo/intake | sed -n 's|.*/removed/||p' | sort)"

case_desc="a clone that never restored does not delete records"
two_proven
new_clone clone_b
record_in "$REPO_WORK" 12
record_in "$clone_b" 30
commit_in "$REPO_WORK"
commit_in "$clone_b"
new_clone clone_c
mkdir -p "$clone_c/.codeo/intake/cleanup"
printf 'run\n' > "$clone_c/.codeo/intake/cleanup/2026-11-27.md"
commit_in "$clone_c"
git -C "$REPO_WORK" fetch -q origin
assert_eq "files" "2026-11-27.md
removed/12.md
removed/30.md" "$(git -C "$REPO_WORK" ls-tree -r --name-only origin/codeo/intake | sed 's|.*/cleanup/||' | sort)"

# prove <N>: stdout only, then the exit status on a last line.
run_prove() {
    local rc=0 out
    out=$(cd "$REPO_WORK" && PATH="$stub_bin:$PATH" bash "$script" prove "$@" 2>/dev/null) || rc=$?
    printf '%s\nrc=%s' "$out" "$rc"
}

case_desc="prove_prints_proven_when_every_proof_passes"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
set_overlay "$overlay"
assert_eq "line" "12${tab}proven"$'\nrc=0' "$(run_prove 12)"

case_desc="prove_names_each_failing_proof"
setup_repo "12:$body"
fixture 12 open 41 2026-01-01T00:00:00Z feat/12
assert_eq "issue" "12${tab}failed${tab}issue"$'\nrc=0' "$(run_prove 12)"
fixture 12 closed 41 null feat/12
assert_eq "pull-request" "12${tab}failed${tab}pull-request"$'\nrc=0' "$(run_prove 12)"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
push_branch feat/12
assert_eq "branch" "12${tab}failed${tab}branch"$'\nrc=0' "$(run_prove 12)"
git -C "$REPO_WORK" push -q origin --delete feat/12
push_branch other/thing 12
assert_eq "dossier" "12${tab}failed${tab}dossier"$'\nrc=0' "$(run_prove 12)"
git -C "$REPO_WORK" push -q origin --delete other/thing
push_lease held shared 12
assert_eq "lease" "12${tab}failed${tab}lease"$'\nrc=0' "$(run_prove 12)"

case_desc="prove fails pull-request for an issue with no done directory"
setup_repo "12:$body"
fixture 30 closed 41 2026-01-01T00:00:00Z feat/30
assert_eq "line" "30${tab}failed${tab}pull-request"$'\nrc=0' "$(run_prove 30)"

case_desc="prove_ignores_a_removal_record_and_the_overlay"
setup_repo "12:$body"
fixture 12 closed 41 2026-01-01T00:00:00Z feat/12
push_removed 12
set_overlay ""
assert_eq "line" "12${tab}proven"$'\nrc=0' "$(run_prove 12)"

case_desc="prove_needs_one_issue_number"
setup_repo "12:$body"
for args in "" "x" "1 2"; do
    rc=0
    # shellcheck disable=SC2086
    out=$(cd "$REPO_WORK" && PATH="$stub_bin:$PATH" bash "$script" prove $args 2>&1) || rc=$?
    assert_eq "exit 1 [$args]" "1" "$rc"
    assert_eq "cleanup: line [$args]" "yes" "$([[ $out == cleanup:*usage* ]] && echo yes || echo no)"
done

case_desc="no container-engine command is ever run"
assert_eq "marker" "absent" "$([[ -e $DOCKER_MARKER ]] && echo present || echo absent)"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
