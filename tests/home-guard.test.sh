#!/usr/bin/env bash
# Exercises hooks/home-guard.sh by feeding it the PreToolUse JSON a session would, against scratch
# clones that hold the real role.sh. Every case judges a host: the container markers point at missing
# files and CLAUDE_CODE_REMOTE / CODEO_HOME_EDITS are unset unless a case sets them.
#
#   home-guard.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
hook="$plugin_root/hooks/home-guard.sh"

scratch_root=$(mktemp -d)
trap 'rm -rf "$scratch_root"' EXIT
export HOME="$scratch_root/home"
mkdir -p "$HOME"

failures=0
case_desc=
assert_eq() {
    if [[ $2 != "$3" ]]; then
        echo "FAIL: $case_desc — $1: want [$2] got [$3]"
        failures=$((failures + 1))
    fi
}
assert_contains() {
    if [[ $3 != *"$2"* ]]; then
        echo "FAIL: $case_desc — $1: want substring [$2] in [$3]"
        failures=$((failures + 1))
    fi
}

# clone <name> <folder> <branch> [lock]: a scratch clone <scratch>/<name>/<folder> holding the real
# role.sh; prints its path.
clone() {
    local dir="$scratch_root/$1/$2" script
    mkdir -p "$dir/.devcontainer/scripts" "$dir/.codeo" "$dir/src"
    git init -q "$dir"
    git -C "$dir" symbolic-ref HEAD "refs/heads/$3"
    for script in container-name.sh role.sh; do
        cp "$plugin_root/.devcontainer/scripts/$script" "$dir/.devcontainer/scripts/$script"
    done
    printf '%s\n' '{"codename":"codeo","baseBranch":"main"}' >"$dir/.codeo/config.json"
    if [[ -n ${4:-} ]]; then printf 'issue: %s\n' "$4" >"$dir/.codeo/active"; fi
    echo a >"$dir/src/a.txt"
    git -C "$dir" add -A
    git -C "$dir" -c user.name=t -c user.email=t@t commit -q -m init
    printf '%s\n' "$dir"
}

# hook <json>: prints the hook's stdout, from the scratch root, on a host.
hook() {
    local json=$1
    shift
    printf '%s' "$json" | (cd "$scratch_root" && env -u CLAUDE_CODE_REMOTE -u CODEO_HOME_EDITS \
        CODEO_DOCKERENV="$scratch_root/no-dockerenv" CODEO_CONTAINERENV="$scratch_root/no-containerenv" \
        "$@" bash "$hook") 2>/dev/null
}
file_json() {
    local key=file_path
    [[ $1 == NotebookEdit ]] && key=notebook_path
    jq -nc --arg t "$1" --arg c "$2" --arg p "$3" --arg k "$key" '{cwd: $c, tool_name: $t, tool_input: {($k): $p}}'
}
bash_json() { jq -nc --arg c "$1" --arg m "$2" '{cwd: $c, tool_name: "Bash", tool_input: {command: $m}}'; }
decision() { if [[ -z $1 ]]; then echo allow; else jq -r ".hookSpecificOutput.permissionDecision" <<<"$1"; fi; }

tools=(Edit Write NotebookEdit)

case_desc=file_tools_refused_in_guarded_roles
for spec in "home:codeo-home:main:home" "stale:codeo-home:other:stale:?" "stray:elsewhere:main:stray"; do
    IFS=: read -r name folder branch role <<<"$spec"
    c=$(clone "$name" "$folder" "$branch")
    for t in "${tools[@]}"; do
        out=$(hook "$(file_json "$t" "$c" "$c/src/a.txt")")
        assert_eq "$name $t" deny "$(decision "$out")"
        reason=$(jq -r '.hookSpecificOutput.permissionDecisionReason // empty' <<<"$out")
        assert_contains "$name role" "role is $role," "$reason"
        assert_contains "$name issue skill" "/codeo:issue" "$reason"
        assert_contains "$name codeo issue" "codeo issue <N>" "$reason"
        assert_contains "$name override" "CODEO_HOME_EDITS=allow" "$reason"
        [[ $reason != *$'\n'* ]] || assert_eq "$name one line" "no newline" "newline"
    done
done

case_desc=file_tools_allowed_elsewhere
iss=$(clone issue codeo-192 feat/192-x 192)
home=$(clone allowhome codeo-home main)
mkdir -p "$home/.codeo/intake/new-x" "$scratch_root/plain" "$scratch_root/norepo"
plain="$scratch_root/plain"
git init -q "$plain"
for t in "${tools[@]}"; do
    out=$(hook "$(file_json "$t" "$iss" "$iss/src/a.txt")")
    assert_eq "issue clone $t" allow "$(decision "$out")"
    out=$(hook "$(file_json "$t" "$home" "$home/src/a.txt")" CLAUDE_CODE_REMOTE=true)
    assert_eq "remote $t" allow "$(decision "$out")"
    out=$(hook "$(file_json "$t" "$home" "$home/.codeo/intake/new-x/issue.md")")
    assert_eq ".codeo path $t" allow "$(decision "$out")"
    out=$(hook "$(file_json "$t" "$home" "$scratch_root/norepo/x.txt")")
    assert_eq "path outside a repo $t" allow "$(decision "$out")"
    out=$(hook "$(file_json "$t" "$scratch_root/norepo" "$scratch_root/norepo/x.txt")")
    assert_eq "cwd outside a repo $t" allow "$(decision "$out")"
    out=$(hook "$(file_json "$t" "$plain" "$plain/x.txt")")
    assert_eq "no role.sh $t" allow "$(decision "$out")"
done
out=$(hook "$(jq -nc --arg c "$home" '{cwd: $c, tool_name: "Read", tool_input: {file_path: "x"}}')")
assert_eq "other tool" allow "$(decision "$out")"

case_desc=file_tools_resolve_the_path
h=$(clone resolve codeo-home main)
out=$(hook "$(file_json Write "$h" "$h/src/new/deep/f.txt")")
assert_eq "new file in missing dirs" deny "$(decision "$out")"
out=$(hook "$(file_json Edit "$h" "src/a.txt")")
assert_eq "relative path" deny "$(decision "$out")"
ln -s "$h" "$scratch_root/link"
out=$(hook "$(file_json Edit "$scratch_root/norepo" "$scratch_root/link/src/a.txt")")
assert_eq "symlink" deny "$(decision "$out")"
out=$(hook "$(file_json Edit "$h" "$iss/src/a.txt")")
assert_eq "issue file with home cwd" allow "$(decision "$out")"
out=$(hook "$(file_json Write "$h" "$h/.codeo/nope/../../src/x.txt")")
assert_eq ".codeo dot-dot escape" deny "$(decision "$out")"
out=$(hook "$(file_json Write "$h" "$h/.codeo/new/dir/f.md")")
assert_eq ".codeo new nested file" allow "$(decision "$out")"
out=$(hook "$(file_json Write "$h" "$h/.codeo-x/f.txt")")
assert_eq ".codeo-x sibling" deny "$(decision "$out")"

case_desc=override_and_fail_open
h=$(clone override codeo-home main)
j=$(file_json Edit "$h" "$h/src/a.txt")
out=$(hook "$j" CODEO_HOME_EDITS=allow)
assert_eq "override" allow "$(decision "$out")"
for v in 1 yes deny ""; do
    out=$(hook "$j" CODEO_HOME_EDITS="$v")
    assert_eq "override [$v]" deny "$(decision "$out")"
done
printf '#!/usr/bin/env bash\nexit 3\n' >"$h/.devcontainer/scripts/role.sh"
out=$(hook "$j")
assert_eq "failing role.sh output" "" "$out"
rc=0
printf '%s' "$j" | env CODEO_DOCKERENV=x bash "$hook" >/dev/null 2>&1 || rc=$?
assert_eq "failing role.sh status" 0 "$rc"
rc=0
out=$(printf 'not json' | bash "$hook" 2>/dev/null) || rc=$?
assert_eq "bad json output" "" "$out"
assert_eq "bad json status" 0 "$rc"

# bcheck <want> <cwd> <command> [env…]: the decision for a Bash call.
bcheck() {
    local want=$1 cwd=$2 cmd=$3 out
    shift 3
    out=$(hook "$(bash_json "$cwd" "$cmd")" "$@")
    assert_eq "[$cmd]" "$want" "$(decision "$out")"
}
# bhome <name> [staged]: a home clone with src/a.txt modified, and src/b.txt or .codeo/192/init.md staged.
bhome() {
    local d
    d=$(clone "$1" codeo-home main)
    echo m >>"$d/src/a.txt"
    mkdir -p "$d/.codeo/192"
    case ${2:-} in
        src) echo b >"$d/src/b.txt"; git -C "$d" add src/b.txt ;;
        codeo) echo i >"$d/.codeo/192/init.md"; git -C "$d" add .codeo/192/init.md ;;
    esac
    printf '%s\n' "$d"
}

case_desc=bash_git_writes_refused_in_home
h=$(bhome bw1 src)
for cmd in "git commit -m x" "git push" "git push origin main" "git checkout -b feat/x" "git switch -c feat/x" \
    "git add src/a.txt" "git add -A" "git add ." "git stash" "git reset --hard" "git commit --amend -m x" \
    "git commit -m x -- src/a.txt" "git -C $h commit -m x" "cd $h && git push" "echo hi && git push" \
    "ls | git push" "CODEO_HOME_EDITS=allow git push" "git tag v1" "git merge x" "git rebase main"; do
    bcheck deny "$h" "$cmd"
done
h=$(bhome bw2)
bcheck deny "$h" "git commit -a -m x"
bcheck deny "$h" "git commit -am x"

case_desc=bash_allowed_in_home
h=$(bhome ba1 codeo)
mkdir -p "$scratch_root/wt"
for cmd in "git status" "git log --oneline" "git diff" "git fetch origin" "git pull --ff-only" \
    "git worktree add $scratch_root/wt/w1 -b b origin/main" "git worktree remove $scratch_root/wt/w1" \
    "git branch -D b" "git checkout main" "git switch main" "git add .codeo/192/init.md" \
    "git add ./.codeo/192/init.md .codeo/.gitignore" "git commit -m x" "bash scripts/claim.sh 1 b w" \
    'echo "git push"' "git status && echo done" 'git commit -m "a; git push"'; do
    bcheck allow "$h" "$cmd"
done

case_desc=bash_judged_by_the_checkout_it_addresses
h=$(bhome bj1 src)
i=$(clone bj2 codeo-192 feat/192-x 192)
bcheck allow "$h" "git -C $i commit -m x"
bcheck allow "$h" "cd $i && git push"
bcheck deny "$i" "git -C $h commit -m x"
bcheck deny "$i" "cd $h && git push"
bcheck deny "$i" "cd $i && git -C $h push"
mkdir -p "$h/.codeo/192"
git -C "$h" -c user.name=t -c user.email=t@t commit -q -m s
git -C "$h" worktree add -q "$scratch_root/bj-wt" -b scratch
echo i >"$scratch_root/bj-wt/.codeo/n.md"
git -C "$scratch_root/bj-wt" add .codeo/n.md
bcheck allow "$h" "git -C $scratch_root/bj-wt commit -m x"
echo c >"$scratch_root/bj-wt/src/c.txt"
git -C "$scratch_root/bj-wt" add src/c.txt
bcheck deny "$h" "git -C $scratch_root/bj-wt commit -m x"
bcheck deny "$h" "cd $scratch_root/bj-wt && git commit -m x"
bcheck deny "$scratch_root" "git -C bj-wt commit -m x"

case_desc=bash_unguarded_roles
h=$(bhome bu1 src)
for cmd in "git commit -m x" "git push" "git add -A" "git checkout -b x" "git stash"; do
    bcheck allow "$i" "$cmd"
    bcheck allow "$h" "$cmd" CLAUDE_CODE_REMOTE=true
    bcheck allow "$scratch_root/norepo" "$cmd"
    bcheck allow "$h" "$cmd" CODEO_HOME_EDITS=allow
done

if [[ $failures -gt 0 ]]; then
    echo "$failures assertion(s) failed" >&2
    exit 1
fi
echo "all cases passed"
