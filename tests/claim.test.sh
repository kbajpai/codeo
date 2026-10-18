#!/usr/bin/env bash
# Exercises `claim.sh` — the create-only branch push that claims an issue — against real scratch git repos:
# the first push claims, the second on the same name is refused (a descendant of origin's tip
# included) and names the first pusher and what the branch carries, and a network failure is exit 1.
# The resume modes (--stash-live, --resume) are covered below the create-only cases.
# No network, no real git config: "origin" is a scratch repo reached by a local path.
#
#   claim.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
claim="$plugin_root/scripts/claim.sh"

export GIT_COMMITTER_NAME="Claim Test" GIT_COMMITTER_EMAIL="claim-test@example.com"
export GIT_AUTHOR_NAME="Claim Test" GIT_AUTHOR_EMAIL="claim-test@example.com"

scratch_root=$(mktemp -d)
cleanup() { rm -rf "$scratch_root"; }
trap cleanup EXIT
export HOME="$scratch_root/home"
mkdir -p "$HOME"

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
assert_not_contains() {
    local label=$1 needle=$2 haystack=$3
    if [[ $haystack == *"$needle"* ]]; then
        echo "FAIL: $case_desc — $label: unwanted substring [$needle] in [$haystack]"
        failures=$((failures + 1))
    fi
}

fresh_origin() {
    local dir
    dir=$(mktemp -d "$scratch_root/origin.XXXXXX")
    git -C "$dir" -c init.defaultBranch=main init -q
    # Every push into this origin makes receive-pack start a detached `git maintenance run --auto`,
    # whose repack deletes loose objects while a later local clone is hardlinking them ("fatal:
    # failed to copy file"). It is the origin's own config that counts: receive-pack drops the
    # caller's GIT_CONFIG_* environment.
    git -C "$dir" config gc.auto 0
    git -C "$dir" config maintenance.auto false
    git -C "$dir" config receive.autogc false
    echo placeholder > "$dir/README.md"
    git -C "$dir" add README.md
    git -C "$dir" commit -q -m init
    printf '%s' "$dir"
}

clone_of() {
    local dir
    dir=$(mktemp -d "$scratch_root/clone.XXXXXX")
    git clone -q "$1" "$dir"
    printf '%s' "$dir"
}

# worktree_for <clone> <branch> <issue> <author-name> <author-email>: a worktree on <branch> off
# origin/main carrying .codeo/<issue>/init.md, committed by that author.
worktree_for() {
    local clone=$1 branch=$2 issue=$3 name=$4 email=$5 wt
    wt=$(mktemp -d "$scratch_root/wt.XXXXXX")
    rmdir "$wt"
    git -C "$clone" worktree add -q --no-track "$wt" -b "$branch" origin/main
    mkdir -p "$wt/.codeo/$issue"
    printf '| | |\n|---|---|\n| Issue | https://example.com/issues/%s — title |\n' "$issue" > "$wt/.codeo/$issue/init.md"
    git -C "$wt" add .codeo
    GIT_AUTHOR_NAME=$name GIT_AUTHOR_EMAIL=$email git -C "$wt" commit -q -m "docs: dossier for #$issue"
    printf '%s' "$wt"
}

# claim.sh reads the base branch from the config of the project it runs in; the repos it is
# pointed at (-C) are scratch ones, so the project is a repo of its own.
project=$(mktemp -d "$scratch_root/project.XXXXXX")
git -C "$project" init -q
mkdir -p "$project/.codeo"
printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}\n' > "$project/.codeo/config.json"

status=0 out= err=
run_claim() {
    local errfile
    errfile=$(mktemp "$scratch_root/err.XXXXXX")
    status=0
    out=$(cd "$project" && bash "$claim" "$@" 2>"$errfile") || status=$?
    err=$(cat "$errfile")
}

o=$(fresh_origin)
a=$(clone_of "$o"); b=$(clone_of "$o")
a_wt=$(worktree_for "$a" feat/x 42 "Engineer A" a@example.com)
b_wt=$(worktree_for "$b" feat/x 42 "Engineer B" b@example.com)

case_desc="first push claims"
run_claim 42 feat/x "$a_wt"
assert_eq "exit" 0 "$status"
assert_contains "claimed" "claim: #42 claimed feat/x" "$out"
a_tip=$(git -C "$o" rev-parse feat/x)
assert_eq "origin has A's tip" "$(git -C "$a_wt" rev-parse HEAD)" "$a_tip"

case_desc="second push on the same name is refused and names the first pusher"
run_claim 42 feat/x "$b_wt"
assert_eq "exit" 2 "$status"
assert_contains "names the pusher" "pushed by Engineer A <a@example.com>" "$err"
assert_contains "names the dossier" "it carries #42's init.md" "$err"
assert_contains "names the issue line" "| Issue |" "$err"
assert_eq "origin unchanged" "$a_tip" "$(git -C "$o" rev-parse feat/x)"
assert_eq "one stderr line is the refusal" 1 "$(grep -c 'already exists on origin' <<<"$err")"

case_desc="a descendant of origin's tip is refused too (no fast-forward claim)"
git -C "$b_wt" reset -q --hard "$a_tip"
echo more > "$b_wt/more.txt"
git -C "$b_wt" add more.txt
git -C "$b_wt" commit -q -m "one more"
run_claim 42 feat/x "$b_wt"
assert_eq "exit" 2 "$status"
assert_eq "origin unchanged" "$a_tip" "$(git -C "$o" rev-parse feat/x)"

case_desc="another issue's dossier"
o2=$(fresh_origin)
c1=$(clone_of "$o2"); c2=$(clone_of "$o2")
c1_wt=$(worktree_for "$c1" feat/y 43 "Engineer C" c@example.com)
c2_wt=$(worktree_for "$c2" feat/y 42 "Engineer B" b@example.com)
run_claim 43 feat/y "$c1_wt"
assert_eq "first exit" 0 "$status"
run_claim 42 feat/y "$c2_wt"
assert_eq "exit" 2 "$status"
assert_contains "names the other issue" "it carries #43's dossier" "$err"
assert_not_contains "not a resume" "init.md" "$err"

case_desc="a branch with no dossier"
o3=$(fresh_origin)
d1=$(clone_of "$o3"); d2=$(clone_of "$o3")
git -C "$d1" push -q origin HEAD:refs/heads/feat/z
d2_wt=$(worktree_for "$d2" feat/z 42 "Engineer B" b@example.com)
run_claim 42 feat/z "$d2_wt"
assert_eq "exit" 2 "$status"
assert_contains "says so" "it carries no dossier" "$err"

case_desc="a network failure is exit 1, not 2"
o4=$(fresh_origin)
e=$(clone_of "$o4")
e_wt=$(worktree_for "$e" feat/n 42 "Engineer A" a@example.com)
git -C "$e_wt" remote set-url origin "$scratch_root/does-not-exist"
run_claim 42 feat/n "$e_wt"
assert_eq "exit" 1 "$status"
assert_not_contains "not a refusal" "already exists" "$err"

# --- resume mode (--stash-live, --resume) ----------------------------------------------------

# stashed_branch <origin> <branch> <issue>: pushes <branch> carrying .codeo/<issue>/init.md and,
# in a later commit, a close.md whose ## Outcome carries a stash heading.
stashed_branch() {
    local origin=$1 branch=$2 issue=$3 c
    c=$(clone_of "$origin")
    git -C "$c" checkout -q -b "$branch" origin/main
    mkdir -p "$c/.codeo/$issue"
    printf '| | |\n|---|---|\n| Issue | https://example.com/issues/%s — title |\n\n## Log\n\n- initialized: branch %s\n' "$issue" "$branch" > "$c/.codeo/$issue/init.md"
    git -C "$c" add .codeo
    git -C "$c" commit -q -m "docs: init for #$issue"
    stash_commit "$c" "$issue"
    git -C "$c" push -q origin "$branch"
}

# stash_commit <clone> <issue>: commits, on the clone's HEAD, a close.md whose ## Outcome carries the
# next "### Round <n> — stashed" heading (n counts the headings already there).
stash_commit() {
    local c=$1 issue=$2 f n
    f="$c/.codeo/$issue/close.md"
    [[ -f $f ]] || printf '## Outcome\n\n' > "$f"
    n=$(( $(grep -cE '^### Round [0-9]+ — stashed$' "$f" || true) + 1 ))
    printf '### Round %s — stashed\n\nparked, see the notes\n\n' "$n" >> "$f"
    git -C "$c" add .codeo
    git -C "$c" commit -q -m "docs: close for #$issue"
}

# resume_wt <clone> <branch> <issue> <name> <email>: fetches, makes a worktree on <branch> at
# origin/<branch>, appends a dated resumed: line under ## Log in init.md and commits it as that author.
resume_wt() {
    local clone=$1 branch=$2 issue=$3 name=$4 email=$5 wt
    git -C "$clone" fetch -q origin
    wt=$(mktemp -d "$scratch_root/rwt.XXXXXX")
    rmdir "$wt"
    git -C "$clone" worktree add -q --no-track -B "$branch" "$wt" "origin/$branch"
    printf -- '- 2026-10-01 — resumed: by %s after the stash of 2026-10-01\n' "$name" >> "$wt/.codeo/$issue/init.md"
    git -C "$wt" add ".codeo/$issue/init.md"
    GIT_AUTHOR_NAME=$name GIT_AUTHOR_EMAIL=$email git -C "$wt" commit -q -m "docs: resumed #$issue"
    printf '%s' "$wt"
}

ro=$(fresh_origin)
stashed_branch "$ro" feat/s 42
a=$(clone_of "$ro"); b=$(clone_of "$ro")
git -C "$a" fetch -q origin; git -C "$b" fetch -q origin
seen=$(git -C "$a" rev-parse origin/feat/s)
a_wt=$(resume_wt "$a" feat/s 42 "Engineer A" a@example.com)
b_wt=$(resume_wt "$b" feat/s 42 "Engineer B" b@example.com)

case_desc="a stash is live before any resume"
run_claim --stash-live 42 feat/s "$a"; assert_eq "exit" 0 "$status"
assert_contains "says live" "claim: #42's stash is live" "$out"

case_desc="first resume claims against the tip it saw"
run_claim --resume 42 feat/s "$a_wt" "$seen"; assert_eq "exit" 0 "$status"
assert_contains "resumed" "claim: #42 resumed feat/s" "$out"
assert_eq "origin has A's resume" "$(git -C "$a_wt" rev-parse HEAD)" "$(git -C "$ro" rev-parse feat/s)"
a_tip=$(git -C "$ro" rev-parse feat/s)

case_desc="a simultaneous second resume is refused and names the first"
run_claim --resume 42 feat/s "$b_wt" "$seen"; assert_eq "exit" 2 "$status"
assert_contains "says resumed" "was resumed since" "$err"
assert_contains "names the resumer" "resumed: by Engineer A" "$err"
assert_eq "origin unchanged" "$a_tip" "$(git -C "$ro" rev-parse feat/s)"

case_desc="a resume that fetched after the winner, still expecting the old tip, is refused"
git -C "$b_wt" reset -q --hard "$a_tip"
echo more > "$b_wt/more.txt"
git -C "$b_wt" add more.txt
git -C "$b_wt" commit -q -m "one more"
run_claim --resume 42 feat/s "$b_wt" "$seen"; assert_eq "exit" 2 "$status"
assert_contains "says resumed" "was resumed since" "$err"
assert_contains "names the resumer" "resumed: by Engineer A" "$err"
assert_eq "origin unchanged" "$a_tip" "$(git -C "$ro" rev-parse feat/s)"

case_desc="after a resume the stash is spent"
git -C "$b" fetch -q origin
run_claim --stash-live 42 feat/s "$b"; assert_eq "exit" 3 "$status"
assert_contains "names who" "already resumed — 2026-10-01 — resumed: by Engineer A" "$out"

case_desc="a second stash makes it live again"
git -C "$a_wt" reset -q --hard "$a_tip"
stash_commit "$a_wt" 42
git -C "$a_wt" push -q origin feat/s
git -C "$b" fetch -q origin
run_claim --stash-live 42 feat/s "$b"; assert_eq "exit" 0 "$status"
assert_contains "says live" "claim: #42's stash is live" "$out"

case_desc="a branch with no close.md has no stash"
ro2=$(fresh_origin)
n1=$(clone_of "$ro2")
n1_wt=$(worktree_for "$n1" feat/q 42 "Engineer A" a@example.com)
git -C "$n1_wt" push -q origin feat/q
git -C "$n1" fetch -q origin
run_claim --stash-live 42 feat/q "$n1"; assert_eq "exit" 3 "$status"
assert_contains "says none" "claim: #42 has no stash" "$out"

case_desc="a missing branch is exit 1"
run_claim --stash-live 42 feat/nope "$n1"; assert_eq "exit" 1 "$status"

case_desc="a tip moved by something other than a resume"
ro3=$(fresh_origin)
stashed_branch "$ro3" feat/m 42
m=$(clone_of "$ro3"); m2=$(clone_of "$ro3")
m_seen=$(git -C "$m" rev-parse origin/feat/m)
m_wt=$(resume_wt "$m" feat/m 42 "Engineer B" b@example.com)
git -C "$m2" checkout -q -b feat/m origin/feat/m
echo plan > "$m2/.codeo/42/plan.md"
git -C "$m2" add .codeo/42/plan.md
GIT_AUTHOR_NAME="Engineer C" GIT_AUTHOR_EMAIL=c@example.com git -C "$m2" commit -q -m "docs: plan"
git -C "$m2" push -q origin feat/m
run_claim --resume 42 feat/m "$m_wt" "$m_seen"; assert_eq "exit" 2 "$status"
assert_contains "moved" "moved since" "$err"
assert_contains "names pusher" "pushed by Engineer C <c@example.com>" "$err"
assert_not_contains "not a resume" "was resumed" "$err"

case_desc="a network failure on a resume is exit 1"
git -C "$m_wt" remote set-url origin "$scratch_root/does-not-exist"
run_claim --resume 42 feat/m "$m_wt" "$m_seen"; assert_eq "exit" 1 "$status"
assert_not_contains "not a refusal" "resumed by" "$err"

# resume_wt_from <clone> <branch> <name> <email> <dir>: like resume_wt, but the dossier sits at
# .codeo/<dir> (an archived one) and the commit touches its close.md.
resume_wt_from() {
    local clone=$1 branch=$2 name=$3 email=$4 dir=$5 wt
    git -C "$clone" fetch -q origin
    wt=$(mktemp -d "$scratch_root/rwt.XXXXXX")
    rmdir "$wt"
    git -C "$clone" worktree add -q --no-track -B "$branch" "$wt" "origin/$branch"
    printf 'seen by %s\n' "$name" >> "$wt/.codeo/$dir/close.md"
    git -C "$wt" add .codeo
    GIT_AUTHOR_NAME=$name GIT_AUTHOR_EMAIL=$email git -C "$wt" commit -q -m "docs: touch"
    printf '%s' "$wt"
}

# commit_all <clone> <message>: stages .codeo and commits.
commit_all() { git -C "$1" add .codeo; git -C "$1" commit -q -m "$2"; }

# dossier_branch <origin> <branch> <issue>: a clone on <branch> off main with init.md committed.
dossier_branch() {
    local c
    c=$(clone_of "$1")
    git -C "$c" checkout -q -b "$2" origin/main
    mkdir -p "$c/.codeo/$3"
    printf '| | |\n|---|---|\n| Issue | https://example.com/issues/%s — title |\n\n## Log\n\n- initialized: branch %s\n' "$3" "$2" > "$c/.codeo/$3/init.md"
    commit_all "$c" "docs: init"
    printf '%s' "$c"
}

# --- --carries ---------------------------------------------------------------------------------

case_desc="--carries: this issue's init.md is exit 0"
co=$(fresh_origin); c=$(dossier_branch "$co" feat/c 42); git -C "$c" push -q origin feat/c
d=$(clone_of "$co"); git -C "$d" checkout -q -b feat/d origin/main
mkdir -p "$d/.codeo/done/42"; echo x > "$d/.codeo/done/42/init.md"
commit_all "$d" "docs: archived"; git -C "$d" push -q origin feat/d
e=$(clone_of "$co"); git -C "$e" checkout -q -b feat/e origin/main
mkdir -p "$e/src"; echo x > "$e/src/x.txt"
git -C "$e" add src; git -C "$e" commit -q -m "feat: x"; git -C "$e" push -q origin feat/e
r=$(clone_of "$co"); git -C "$r" fetch -q origin
run_claim --carries 42 feat/c "$r"; assert_eq "exit" 0 "$status"
assert_contains "names it" "claim: feat/c carries #42's init.md (| Issue | https://example.com/issues/42" "$out"
case_desc="--carries: another issue's dossier is a collision, exit 2, naming #M and the remedy"
run_claim --carries 43 feat/c "$r"; assert_eq "exit" 2 "$status"
assert_contains "names the other" "it carries #42's dossier (| Issue | https://example.com/issues/42" "$out"
assert_contains "remedy" "claim: #43's title derives the same branch name as #42's — retitle #43" "$out"
case_desc="--carries: an archived dossier still names its issue"
run_claim --carries 43 feat/d "$r"; assert_eq "exit" 2 "$status"; assert_contains "done/" "#42's dossier" "$out"
case_desc="--carries: only the issue's own archived dossier says it has been through close"
run_claim --carries 42 feat/d "$r"; assert_eq "exit" 2 "$status"
assert_contains "own" "claim: feat/d carries only #42's own archived dossier — #42 has already been through close; finish or verify it with close in its container, and retitle #42 only for an issue reopened after its merge" "$out"
assert_not_contains "old remedy" "start a new branch name by retitling" "$out"
assert_not_contains "no collision wording" "derives the same branch name" "$out"
case_desc="--carries: no dossier"
run_claim --carries 43 feat/e "$r"; assert_eq "exit" 2 "$status"
assert_contains "none" "it carries no dossier" "$out"; assert_contains "remedy" "is not a pipeline branch" "$out"
case_desc="--carries: a missing branch is exit 1"
run_claim --carries 43 feat/none "$r"; assert_eq "exit" 1 "$status"

case_desc="--carries: a branch merged into main with a merge commit and left behind says so"
# main is checked out in the non-bare scratch origin and this case pushes to it.
mo=$(fresh_origin); git -C "$mo" config receive.denyCurrentBranch ignore
m=$(clone_of "$mo"); git -C "$m" checkout -q -b feat/m origin/main
mkdir -p "$m/.codeo/done/42"
printf '| | |\n|---|---|\n| Issue | https://example.com/issues/42 — title |\n' > "$m/.codeo/done/42/init.md"
commit_all "$m" "docs: archived"; git -C "$m" push -q origin feat/m
git -C "$m" checkout -q main
git -C "$m" merge -q --no-ff feat/m -m "Merge pull request #1 from feat/m"; git -C "$m" push -q origin main
mr=$(clone_of "$mo"); git -C "$mr" fetch -q origin
run_claim --carries 42 feat/m "$mr"; assert_eq "exit" 2 "$status"
assert_contains "merged" "it was merged into main and left behind" "$out"
assert_contains "remedy" "claim: #42 has already been through close — delete feat/m on origin" "$out"
assert_not_contains "not no-dossier" "carries no dossier" "$out"
assert_not_contains "not own-archived" "own archived dossier" "$out"
assert_not_contains "not bare" "it is bare" "$out"

case_desc="--carries: a squash-merged branch left behind is still the own-archived dossier"
# main is checked out in the non-bare scratch origin and this case pushes to it.
sqo=$(fresh_origin); git -C "$sqo" config receive.denyCurrentBranch ignore
sq=$(clone_of "$sqo"); git -C "$sq" checkout -q -b feat/sq origin/main
mkdir -p "$sq/.codeo/done/42"
printf '| | |\n|---|---|\n| Issue | https://example.com/issues/42 — title |\n' > "$sq/.codeo/done/42/init.md"
commit_all "$sq" "docs: archived"; git -C "$sq" push -q origin feat/sq
git -C "$sq" checkout -q main
git -C "$sq" checkout -q feat/sq -- .codeo/done/42
git -C "$sq" commit -q -m "feat: squash of feat/sq"; git -C "$sq" push -q origin main
sqr=$(clone_of "$sqo"); git -C "$sqr" fetch -q origin
run_claim --carries 42 feat/sq "$sqr"; assert_eq "exit" 2 "$status"
assert_contains "own" "carries only #42's own archived dossier" "$out"
assert_not_contains "not merged-and-left" "left behind" "$out"

case_desc="--carries: a branch cut from main with nothing added and no archive of the issue is no dossier"
git -C "$mr" push -q origin origin/main:refs/heads/feat/n
git -C "$mr" fetch -q origin
run_claim --carries 43 feat/n "$mr"; assert_eq "exit" 2 "$status"
assert_contains "none" "it carries no dossier" "$out"
assert_not_contains "not merged-and-left" "left behind" "$out"

case_desc="--carries: a branch with its own commits and no dossier is no dossier even when main archived the issue"
git -C "$mr" checkout -q -b feat/z origin/main
mkdir -p "$mr/src"; echo x > "$mr/src/y.txt"
git -C "$mr" add src; git -C "$mr" commit -q -m "feat: y"; git -C "$mr" push -q origin feat/z
git -C "$mr" fetch -q origin
run_claim --carries 42 feat/z "$mr"; assert_eq "exit" 2 "$status"
assert_contains "none" "it carries no dossier" "$out"
assert_not_contains "not merged-and-left" "left behind" "$out"

case_desc="--carries: a branch cut from main with nothing added, for an issue main has archived, is bare, not merged"
git -C "$mr" push -q origin origin/main:refs/heads/feat/bare
git -C "$mr" fetch -q origin
run_claim --carries 42 feat/bare "$mr"; assert_eq "exit" 2 "$status"
assert_contains "bare" "it is bare — cut from main with nothing of its own, and main holds #42's archive" "$out"
assert_contains "remedy" "claim: #42 has already been through close — delete feat/bare on origin" "$out"
assert_not_contains "not merged-and-left" "merged into main and left behind" "$out"

case_desc="--carries: a bare branch is still bare when main's first-parent history is long (no SIGPIPE under pipefail)"
# rev-list's output must be far past what grep -q has read when it quits, or the pipe never takes SIGPIPE:
# measured, 6000 first-parent commits (~240 KB of shas) still passes and 8000 fails every run; 12000 is margin.
# The branch is cut from the TIP, so the match is the first line, early in the stream.
lo=$(fresh_origin); git -C "$lo" config receive.denyCurrentBranch ignore
l=$(clone_of "$lo")
body=$'| | |\n|---|---|\n| Issue | https://example.com/issues/42 — title |'
body_bytes=$(printf %s "$body" | wc -c)
{
    for i in $(seq 1 12000); do
        printf 'commit refs/heads/main\ncommitter t <t@example.com> %s +0000\ndata 2\nc\n' "$((1700000000 + i))"
        [ "$i" -eq 1 ] && printf 'from refs/remotes/origin/main\n'
        [ "$i" -eq 12000 ] && printf 'M 100644 inline .codeo/done/42/init.md\ndata %s\n%s\n' "$body_bytes" "$body"
    done
} | git -C "$l" fast-import --quiet
git -C "$l" push -q origin main
git -C "$l" push -q origin main:refs/heads/feat/long
lr=$(clone_of "$lo"); git -C "$lr" fetch -q origin
assert_eq "history is long" 1 "$([ "$(git -C "$lr" rev-list --first-parent --count origin/main)" -ge 12000 ] && echo 1 || echo 0)"
run_claim --carries 42 feat/long "$lr"; assert_eq "exit" 2 "$status"
assert_contains "bare" "it is bare — cut from main with nothing of its own, and main holds #42's archive" "$out"
assert_not_contains "not merged-and-left" "merged into main and left behind" "$out"

case_desc="a stash of an archived dossier is live (P7)"
po=$(fresh_origin)
p=$(dossier_branch "$po" feat/p 42)
printf '## Outcome\n\nPR opened\n' > "$p/.codeo/42/close.md"
commit_all "$p" "docs: close"
mkdir -p "$p/.codeo/done"
git -C "$p" mv .codeo/42 .codeo/done/42
commit_all "$p" "docs: archive"
git -C "$p" mv .codeo/done/42 .codeo/42
printf '### Round 2 — stashed\n\nparked\n' >> "$p/.codeo/42/close.md"
commit_all "$p" "docs: stash"
git -C "$p" push -q origin feat/p
run_claim --stash-live 42 feat/p "$p"; assert_eq "exit" 0 "$status"
assert_contains "says live" "is live" "$out"

case_desc="a close round after a resume does not revive the stash (P8)"
qo=$(fresh_origin)
stashed_branch "$qo" feat/r 42
q=$(clone_of "$qo")
q_wt=$(resume_wt "$q" feat/r 42 "Engineer A" a@example.com)
printf '### Round 3 — conflicts with main\n\nrebase needed\n' >> "$q_wt/.codeo/42/close.md"
commit_all "$q_wt" "docs: close round"
git -C "$q_wt" push -q origin feat/r
git -C "$q" fetch -q origin
run_claim --stash-live 42 feat/r "$q"; assert_eq "exit" 3 "$status"
assert_contains "spent" "already resumed" "$out"

case_desc="an abandoned workflow is exit 4 and names its round, not a stash (P8)"
ao=$(fresh_origin)
x=$(dossier_branch "$ao" feat/a 42)
printf '## Outcome\n\n### Round 2 — abandoned\n\nnot stashed — abandoned\n' > "$x/.codeo/42/close.md"
commit_all "$x" "docs: abandon"
git -C "$x" push -q origin feat/a
run_claim --stash-live 42 feat/a "$x"; assert_eq "exit" 4 "$status"
assert_contains "names the abandon" "claim: #42 was abandoned on " "$out"
assert_contains "names the round" "(close.md round 2)" "$out"

case_desc="prose saying stash without the heading is not a stash"
x=$(dossier_branch "$ao" feat/prose 42)
printf '## Outcome\n\nthe work was stashed\n' > "$x/.codeo/42/close.md"
commit_all "$x" "docs: prose"
git -C "$x" push -q origin feat/prose
run_claim --stash-live 42 feat/prose "$x"; assert_eq "exit" 3 "$status"
assert_contains "none" "has no stash" "$out"

case_desc="stash, resume, stash is live; a second resume spends it"
so=$(fresh_origin)
stashed_branch "$so" feat/t 42
s1=$(clone_of "$so")
s_wt=$(resume_wt "$s1" feat/t 42 "Engineer A" a@example.com)
stash_commit "$s_wt" 42
git -C "$s_wt" push -q origin feat/t
git -C "$s1" fetch -q origin
run_claim --stash-live 42 feat/t "$s1"; assert_eq "live exit" 0 "$status"
printf -- '- 2026-10-02 — resumed: by Engineer B after the stash of 2026-10-02\n' >> "$s_wt/.codeo/42/init.md"
commit_all "$s_wt" "docs: resumed again"
git -C "$s_wt" push -q origin feat/t
git -C "$s1" fetch -q origin
run_claim --stash-live 42 feat/t "$s1"; assert_eq "spent exit" 3 "$status"
assert_contains "last resume" "already resumed — 2026-10-02 — resumed: by Engineer B" "$out"

case_desc="a resume refused by an un-archive alone says moved, not resumed (minor 7)"
uo=$(fresh_origin)
u=$(dossier_branch "$uo" feat/u 42)
printf '### Round 1 — stashed\n\nparked\n' > "$u/.codeo/42/close.md"
mkdir -p "$u/.codeo/done"
git -C "$u" mv .codeo/42 .codeo/done/42
commit_all "$u" "docs: archived stash"
git -C "$u" push -q origin feat/u
u_seen=$(git -C "$u" rev-parse HEAD)
u2=$(clone_of "$uo")
u_wt=$(resume_wt_from "$u2" feat/u "Engineer B" b@example.com "done/42")
git -C "$u" mv .codeo/done/42 .codeo/42
commit_all "$u" "docs: un-archive"
git -C "$u" push -q origin feat/u
run_claim --resume 42 feat/u "$u_wt" "$u_seen"; assert_eq "exit" 2 "$status"
assert_contains "moved" "moved since" "$err"
assert_not_contains "not a resume" "resumed" "$err"

# --- --resume-line, and a tolerant stash heading ---------------------------------------

# run_dated <args…>: run_claim, bracketed by the UTC date before and after (M5: a run across
# midnight UTC may print either).
before= after=
run_dated() {
    before=$(date -u +%F)
    run_claim "$@"
    after=$(date -u +%F)
}
# assert_dated <label> <suffix> <out>: <out> is "- <before> — <suffix>" or "- <after> — <suffix>".
assert_dated() {
    local label=$1 suffix=$2 got=$3
    if [[ $got != "- $before — $suffix" && $got != "- $after — $suffix" ]]; then
        echo "FAIL: $case_desc — $label: want [- $before — $suffix] (or $after) got [$got]"
        failures=$((failures + 1))
    fi
}

case_desc="resume-line after a live stash names the stash and its date"
rlo=$(fresh_origin)
GIT_COMMITTER_DATE=2026-09-30T12:00:00Z GIT_AUTHOR_DATE=2026-09-30T12:00:00Z stashed_branch "$rlo" feat/s 42
a=$(clone_of "$rlo")
run_dated --resume-line 42 feat/s "$a" a-login; assert_eq "exit" 0 "$status"
assert_dated "line" "resumed: by a-login after the stash of 2026-09-30" "$out"

case_desc="resume-line with no login says no login"
run_claim --resume-line 42 feat/s "$a"; assert_contains "no login" "resumed: by no login after the stash of" "$out"
run_claim --resume-line 42 feat/s "$a" ""; assert_contains "empty login" "resumed: by no login after the stash of" "$out"

case_desc="the printed stash line spends the stash"
run_claim --resume-line 42 feat/s "$a" a-login
git -C "$a" checkout -q -B feat/s origin/feat/s
printf -- '%s · cost: 1m\n' "$out" >> "$a/.codeo/42/init.md"
commit_all "$a" "docs: resumed"
git -C "$a" push -q origin feat/s
git -C "$a" fetch -q origin
run_claim --stash-live 42 feat/s "$a"; assert_eq "exit" 3 "$status"

case_desc="resume-line on a spent stash says a lost container"
lo=$(fresh_origin)
stashed_branch "$lo" feat/l 42
l=$(clone_of "$lo")
git -C "$l" checkout -q -B feat/l origin/feat/l
printf -- '- 2026-10-01 — resumed: by a-login after the stash of 2026-10-01 · cost: 1m\n' >> "$l/.codeo/42/init.md"
commit_all "$l" "docs: resumed"
git -C "$l" push -q origin feat/l; git -C "$l" fetch -q origin
run_dated --resume-line 42 feat/l "$l" a-login; assert_eq "exit" 0 "$status"
assert_dated "line" "resumed: by a-login after a lost container" "$out"

case_desc="stash, resume, lost-container resume, stash: live (P10)"
po2=$(fresh_origin)
stashed_branch "$po2" feat/pp 42
pp=$(clone_of "$po2")
git -C "$pp" checkout -q -B feat/pp origin/feat/pp
printf -- '- 2026-10-01 — resumed: by a-login after the stash of 2026-10-01 · cost: 1m\n' >> "$pp/.codeo/42/init.md"
commit_all "$pp" "docs: resumed"
git -C "$pp" push -q origin feat/pp; git -C "$pp" fetch -q origin
run_claim --resume-line 42 feat/pp "$pp" a-login
printf -- '%s · cost: 1m\n' "$out" >> "$pp/.codeo/42/init.md"
commit_all "$pp" "docs: lost container"
stash_commit "$pp" 42
git -C "$pp" push -q origin feat/pp
git -C "$pp" fetch -q origin
run_claim --stash-live 42 feat/pp "$pp"; assert_eq "exit" 0 "$status"

case_desc="the stash date is the commit that added the heading, not a later close.md commit (M4)"
mo=$(fresh_origin)
GIT_COMMITTER_DATE=2026-09-30T12:00:00Z GIT_AUTHOR_DATE=2026-09-30T12:00:00Z stashed_branch "$mo" feat/m4 42
m4=$(clone_of "$mo"); git -C "$m4" checkout -q -B feat/m4 origin/feat/m4
printf '\n## Log\n\n- 2026-10-01 — stashed · board: Ready on #2\n' >> "$m4/.codeo/42/close.md"
GIT_COMMITTER_DATE=2026-10-01T12:00:00Z GIT_AUTHOR_DATE=2026-10-01T12:00:00Z commit_all "$m4" "docs: close log line"
git -C "$m4" push -q origin feat/m4; git -C "$m4" fetch -q origin
run_dated --resume-line 42 feat/m4 "$m4" a-login
assert_dated "line" "resumed: by a-login after the stash of 2026-09-30" "$out"

case_desc="two stashes: the date is the second stash's commit"
to=$(fresh_origin)
GIT_COMMITTER_DATE=2026-09-28T12:00:00Z GIT_AUTHOR_DATE=2026-09-28T12:00:00Z stashed_branch "$to" feat/m5 42
t=$(clone_of "$to"); git -C "$t" checkout -q -B feat/m5 origin/feat/m5
printf -- '- 2026-09-29 — resumed: by a-login after the stash of 2026-09-28\n' >> "$t/.codeo/42/init.md"
GIT_COMMITTER_DATE=2026-09-29T12:00:00Z GIT_AUTHOR_DATE=2026-09-29T12:00:00Z commit_all "$t" "docs: resumed"
GIT_COMMITTER_DATE=2026-09-30T12:00:00Z GIT_AUTHOR_DATE=2026-09-30T12:00:00Z stash_commit "$t" 42
printf '\n## Log\n\n- 2026-10-01 — stashed · board: Ready on #2\n' >> "$t/.codeo/42/close.md"
GIT_COMMITTER_DATE=2026-10-01T12:00:00Z GIT_AUTHOR_DATE=2026-10-01T12:00:00Z commit_all "$t" "docs: close log line"
git -C "$t" push -q origin feat/m5; git -C "$t" fetch -q origin
run_dated --resume-line 42 feat/m5 "$t" a-login
assert_dated "line" "resumed: by a-login after the stash of 2026-09-30" "$out"

case_desc="the stash date survives a diff whose first added line is the heading and ~1500 more follow"
bo=$(fresh_origin)
b=$(dossier_branch "$bo" feat/big 42)
{ printf '### Round 1 — stashed\n\n'; for i in $(seq 1 1500); do printf 'filler line %s of the parked notes\n' "$i"; done; } > "$b/.codeo/42/close.md"
GIT_COMMITTER_DATE=2026-09-30T12:00:00Z GIT_AUTHOR_DATE=2026-09-30T12:00:00Z commit_all "$b" "docs: big stash"
printf '\n## Log\n\n- 2026-10-01 — stashed · board: Ready on #2\n' >> "$b/.codeo/42/close.md"
GIT_COMMITTER_DATE=2026-10-01T12:00:00Z GIT_AUTHOR_DATE=2026-10-01T12:00:00Z commit_all "$b" "docs: close log line"
git -C "$b" push -q origin feat/big; git -C "$b" fetch -q origin
run_dated --resume-line 42 feat/big "$b" a-login
assert_dated "line" "resumed: by a-login after the stash of 2026-09-30" "$out"

# heading_branch <origin> <branch> <heading>: a branch whose close.md carries only that heading line.
heading_branch() {
    local c
    c=$(dossier_branch "$1" "$2" 42)
    printf '## Outcome\n\n%s\n\nparked\n' "$3" > "$c/.codeo/42/close.md"
    commit_all "$c" "docs: heading"
    git -C "$c" push -q origin "$2"
    printf '%s' "$c"
}

case_desc="a dated stash heading counts (P11)"
ho=$(fresh_origin)
i=0
for heading in "### Round 2 — stashed (2026-10-01)" "### Round 2 — 2026-10-01 — stashed" "### Round 2 — stashed " $'### Round 2 — stashed\r'; do
    i=$((i + 1))
    h=$(heading_branch "$ho" "feat/h$i" "$heading")
    run_claim --stash-live 42 "feat/h$i" "$h"; assert_eq "exit for [$heading]" 0 "$status"
done

case_desc="headings that only mention a stash do not count (P11)"
for heading in "### Round 2 — not stashed" "### Round 2 — unstashed" "### Round 2 — retro (was stashed)"; do
    i=$((i + 1))
    h=$(heading_branch "$ho" "feat/h$i" "$heading")
    run_claim --stash-live 42 "feat/h$i" "$h"; assert_eq "exit for [$heading]" 3 "$status"
    assert_contains "none for [$heading]" "has no stash" "$out"
done

case_desc="the last park decides: stash, resume, abandon is exit 4; abandon, resume, stash is live"
sa=$(fresh_origin)
stashed_branch "$sa" feat/sa 42
sa1=$(clone_of "$sa")
sa_wt=$(resume_wt "$sa1" feat/sa 42 "Engineer A" a@example.com)
printf '### Round 2 — abandoned\n\ngave up\n\n' >> "$sa_wt/.codeo/42/close.md"
commit_all "$sa_wt" "docs: abandon"
git -C "$sa_wt" push -q origin feat/sa
git -C "$sa1" fetch -q origin
run_claim --stash-live 42 feat/sa "$sa1"; assert_eq "exit after stash, resume, abandon" 4 "$status"
assert_contains "round" "(close.md round 2)" "$out"
abo=$(fresh_origin)
abh=$(heading_branch "$abo" feat/ab2 "### Round 1 — abandoned")
printf -- '- 2026-10-01 — resumed: by a-login after the abandon of 2026-10-01\n' >> "$abh/.codeo/42/init.md"
stash_commit "$abh" 42
git -C "$abh" push -q origin feat/ab2
run_claim --stash-live 42 feat/ab2 "$abh"; assert_eq "exit after abandon, resume, stash" 0 "$status"
assert_contains "live" "is live" "$out"

case_desc="resume-line after an abandon names the abandon and its date, and the line spends it"
abo=$(fresh_origin)
abh=$(GIT_COMMITTER_DATE=2026-09-30T12:00:00Z GIT_AUTHOR_DATE=2026-09-30T12:00:00Z \
    heading_branch "$abo" feat/ab1 "### Round 1 — abandoned")
run_dated --resume-line 42 feat/ab1 "$abh" a-login; assert_eq "exit" 0 "$status"
assert_dated "line" "resumed: by a-login after the abandon of 2026-09-30" "$out"
printf -- '%s · cost: 1m\n' "$out" >> "$abh/.codeo/42/init.md"
commit_all "$abh" "docs: resumed"
git -C "$abh" push -q origin feat/ab1
git -C "$abh" fetch -q origin
run_claim --stash-live 42 feat/ab1 "$abh"; assert_eq "spent exit" 3 "$status"
assert_contains "spent" "abandon was already resumed" "$out"

case_desc="a dated, padded or CRLF abandon heading counts, and so does one that mentions a stash"
hao=$(fresh_origin)
i=0
for heading in "### Round 2 — abandoned (2026-10-01)" "### Round 2 — 2026-10-01 — abandoned" "### Round 2 — abandoned " $'### Round 2 — abandoned\r' "### Round 2 — abandoned (was stashed)"; do
    i=$((i + 1))
    h=$(heading_branch "$hao" "feat/ha$i" "$heading")
    run_claim --stash-live 42 "feat/ha$i" "$h"; assert_eq "exit for [$heading]" 4 "$status"
done

case_desc="headings that only mention an abandon do not count, and neither does prose"
for heading in "### Round 2 — not abandoned" "### Round 2 — unabandoned" "### Round 2 — retro (was abandoned)"; do
    i=$((i + 1))
    h=$(heading_branch "$hao" "feat/ha$i" "$heading")
    run_claim --stash-live 42 "feat/ha$i" "$h"; assert_eq "exit for [$heading]" 3 "$status"
    assert_contains "none for [$heading]" "has no stash" "$out"
done
x=$(dossier_branch "$hao" feat/haprose 42)
printf '## Outcome\n\nthe work was abandoned\n' > "$x/.codeo/42/close.md"
commit_all "$x" "docs: prose"; git -C "$x" push -q origin feat/haprose
run_claim --stash-live 42 feat/haprose "$x"; assert_eq "prose exit" 3 "$status"
assert_contains "prose none" "has no stash" "$out"

case_desc="resume-line on a missing branch is exit 1"
run_claim --resume-line 42 feat/nope "$a" a-login; assert_eq "exit" 1 "$status"

case_desc="a develop base branch: the first push claims, the second is refused"
od=$(fresh_origin)
git -C "$od" branch -m main develop
cd1=$(clone_of "$od"); cd2=$(clone_of "$od")
dev_worktree() { # <clone> <name> <email>: a worktree on feat/d off origin/develop with #44's dossier
    local wt
    wt=$(mktemp -d "$scratch_root/wt.XXXXXX"); rmdir "$wt"
    git -C "$1" worktree add -q --no-track "$wt" -b feat/d origin/develop
    mkdir -p "$wt/.codeo/44"
    printf '| | |\n|---|---|\n| Issue | https://example.com/issues/44 — title |\n' > "$wt/.codeo/44/init.md"
    git -C "$wt" add .codeo
    GIT_AUTHOR_NAME=$2 GIT_AUTHOR_EMAIL=$3 git -C "$wt" commit -q -m "docs: dossier for #44"
    printf '%s' "$wt"
}
d1=$(dev_worktree "$cd1" "Engineer D" d@example.com)
d2=$(dev_worktree "$cd2" "Engineer E" e@example.com)
sed -i 's/"baseBranch":"main"/"baseBranch":"develop"/' "$project/.codeo/config.json"
run_claim 44 feat/d "$d1"
assert_eq "first exit" 0 "$status"
run_claim 44 feat/d "$d2"
assert_eq "second exit" 2 "$status"
assert_contains "names the first pusher" "pushed by Engineer D <d@example.com>" "$err"
sed -i 's/"baseBranch":"develop"/"baseBranch":"main"/' "$project/.codeo/config.json"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
