#!/usr/bin/env bash
# Proves each finished issue is really finished, and prints what a project's overlay says removes its leftovers.
# It only prints: it never runs the command it prints, and runs no container-engine command at all.
#
#   cleanup.sh
#       Fetches origin with --prune, lists the .codeo/done/<N> directories on origin/<baseBranch>, and prints
#       one tab-separated line per issue, in ascending N, and after a proven issue (or one whose only failed proof is
#       `name`) with leftover branches a second line, `leftover`:
#           <N> TAB proven TAB <command> TAB <fallback>
#                                           every proof passed and no removal is recorded; <command> is `-` when the overlay gives none;
#                                           <fallback> is the overlay's expanded fallback text, or `-` when it has none
#           <N> TAB failed TAB <proof>      the first proof that failed
#           <N> TAB leftover TAB <command>  right after a proven line, or a `failed name` line, when origin still holds codeo-live/<N>/<machine> branches
#                                           (a hosted web session's live signal); <command> is one `git push origin --delete` naming
#                                           each such branch whose name is only letters, digits, `.`, `_` and `-`. Read from the
#                                           refs the fetch pruned; none, no line.
#       An issue that passes every proof but has a removal record on origin's codeo/intake (see `record`) is not listed
#       (its leftover line still is), and stderr says `cleanup: note: <k> issue(s) with a recorded removal are not listed`.
#       A record never hides a failed proof: an issue that fails one is listed as failed, recorded or not.
#       Proofs, in order:
#           issue         the issue's state is closed
#           pull-request  done/<N>/close.md has a `#<number> <url>` line and that PR has a merged_at
#           branch        the PR's head branch is gone from origin (an empty or null head
#                         branch fails)
#           dossier       no origin branch still has a .codeo/<N>/ directory (.codeo/done/<N>/ does not count)
#           lease         no lease is held and no wait is recorded for the issue on the intake branch
#                         (intake.sh lease list --tsv, read once after the fetch; unreadable stops the script)
#           name          the overlay's name template, pattern and command are all present, and the expanded
#                         name matches the pattern.
#
#   cleanup.sh record <N>…
#       Writes .codeo/intake/cleanup/removed/<N>.md in the working tree for each issue the engineer has removed, and prints
#           <N> TAB recorded            a record was written
#           <N> TAB already recorded    the record is on origin's codeo/intake or already in the working tree
#       It restores the intake branch's cleanup files first, because intake.sh commit replaces the directory.
#       It runs no proof, never commits, and writes nothing unless every number is an issue with a .codeo/done/<N> on origin/<baseBranch>
#       (otherwise exit 1 with a cleanup: line).
#
# The overlay's command is built in name_proof and the leftover delete in leftover_proof: the only two places a command is built.
# The overlay body (cleanup/removal-command) is three lines, and an optional fourth: `name: <template with {N}>`,
# `pattern: <extended regex>`, `command: <template with {N} and {name}>` and `fallback: <text with {N} and {name}>`; command: and fallback: may hold only {N} and {name}, and any other {word} ends the run; it comes from `overlay.sh cleanup removal-command`. No
# overlay (overlay.sh exit 3, or 2 while the point is unregistered) means `proven` with `-` and `-`; any other failure dies.
#
# Config keys read: baseBranch (see lib/env.sh).
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"
die() { echo "cleanup: $*" >&2; exit 1; }

mode=list
if [[ ${1:-} == record ]]; then
    mode=record
    shift
    (($#)) || die "usage: cleanup.sh record <issue>…"
elif (($#)); then
    die "usage: cleanup.sh [record <issue>…]"
fi

cd "$(git rev-parse --show-toplevel)"
base=$(codeo_base_branch)
state_rel=${CODEO_STATE_DIR#"$CODEO_PROJECT_ROOT"/}
github=$CODEO_PLUGIN_ROOT/scripts/github.sh

git fetch -q --prune origin || die "fetch failed; nothing proven"
# The proofs read refs/remotes/origin/*, which only a clone that fetches every branch keeps whole.
git config --get-all remote.origin.fetch | grep -Eqx '\+?refs/heads/\*:refs/remotes/origin/\*' ||
    die "origin's fetch refspec does not cover every branch; nothing proven"
base_sha=$(git rev-parse "origin/$base") || die "no origin/$base"
# The intake branch's name is intake.sh's `branch`; its removal records are the files under removed_rel.
intake_ref=refs/remotes/origin/codeo/intake
removed_rel=$state_rel/intake/cleanup/removed
recorded=
if git rev-parse -q --verify "$intake_ref" >/dev/null; then
    recorded=$(git ls-tree --name-only "$intake_ref" -- "$removed_rel/" | sed -n 's|.*/\([0-9][0-9]*\)\.md$|\1|p')
fi

if [[ $mode == record ]]; then
    for n; do
        [[ $n =~ ^[1-9][0-9]*$ ]] || die "not an issue number: $n; nothing recorded"
        git cat-file -e "$base_sha:$state_rel/done/$n" 2>/dev/null || die "#$n has no $state_rel/done/$n on origin/$base; nothing recorded"
    done
    # commit replaces the directory, so bring in the intake branch's records first (never overwrites a local file; harmless when none exist).
    bash "$CODEO_PLUGIN_ROOT/scripts/intake.sh" restore cleanup </dev/null >/dev/null 2>&1 || true
    mkdir -p "$removed_rel"
    for n; do
        if grep -qxF "$n" <<<"$recorded" || [[ -e $removed_rel/$n.md ]]; then
            printf '%s\talready recorded\n' "$n"
            continue
        fi
        printf 'issue:    #%s\nrecorded: %s\n' "$n" "$(date -u +%F)" > "$removed_rel/$n.md"
        printf '%s\trecorded\n' "$n"
    done
    exit 0
fi

# Every lease and wait on the intake branch, read once: held|waiting TAB resource TAB issue TAB by TAB since.
leases=$(bash "$CODEO_PLUGIN_ROOT/scripts/intake.sh" lease list --tsv </dev/null 2>/dev/null) || die "could not read the leases"

# The overlay body, or nothing when there is none.
overlay=
rc=0
overlay=$(bash "$CODEO_PLUGIN_ROOT/scripts/overlay.sh" cleanup removal-command 2>/dev/null) || rc=$?
case $rc in
    0) ;;
    2 | 3) overlay= ;;
    *) die "overlay.sh cleanup removal-command failed (exit $rc)" ;;
esac

# The value after `<key>:` on the key's first line, or nothing.
overlay_value() {
    awk -v k="$1" 'index($0, k ":") == 1 { sub(/^[^:]*:[ \t]*/, ""); sub(/[ \t\r]+$/, ""); print; exit }' <<<"$overlay"
}

# A placeholder the script does not expand would print as a command nobody can run.
if [[ -n $overlay ]]; then
    unknown='\{[A-Za-z0-9_]+\}'
    for key in command fallback; do
        left=$(overlay_value "$key")
        left=${left//\{N\}/}
        left=${left//\{name\}/}
        [[ ! $left =~ $unknown ]] || die "the overlay's $key: keeps a placeholder the script does not expand: ${BASH_REMATCH[0]}"
    done
fi

# The first failing proof for issue $1, or `ok`.
first_failed_proof() {
    local n=$1 issue pr info ref sha
    issue=$(bash "$github" issue view "$n" </dev/null 2>/dev/null) || die "could not read issue #$n"
    [[ $(jq -r '.state' <<<"$issue") == closed ]] || { echo issue; return; }

    pr=$({ git show "$base_sha:$state_rel/done/$n/close.md" 2>/dev/null || true; } |
        awk '/^#[0-9]+ https?:\/\// { sub(/^#/, ""); print $1; exit }')
    [[ -n $pr ]] || { echo pull-request; return; }
    info=$(bash "$github" pr get "$pr" </dev/null) || die "could not read pull request #$pr"
    [[ -n $(jq -r '.merged_at // empty' <<<"$info") ]] || { echo pull-request; return; }

    ref=$(jq -r '.head_ref // empty' <<<"$info")
    [[ -n $ref && $ref != null ]] || { echo branch; return; }
    # From the refs the fetch above just pruned, never ls-remote: a failed ls-remote prints nothing and would read as "gone".
    ! git rev-parse --verify -q "refs/remotes/origin/$ref" >/dev/null || { echo branch; return; }

    while IFS= read -r ref; do
        sha=$(git rev-parse "$ref")
        ! git cat-file -e "$sha:$state_rel/$n" 2>/dev/null || { echo dossier; return; }
    done < <(git for-each-ref --format='%(refname)' refs/remotes/origin | grep -v '^refs/remotes/origin/HEAD$' || true)

    # The workflow let go of its leases: no held lease and no wait names the issue.
    ! awk -F'\t' -v n="$n" '$3 == n { found = 1 } END { exit !found }' <<<"$leases" || { echo lease; return; }

    echo ok
}

# Last proof; builds the overlay's command: prints `-`, or `name` for a failure, or `cmd:<command>` and then
# a second line, the expanded fallback or `-`.
name_proof() {
    local n=$1 tpl pattern cmd name fb
    [[ -n $overlay ]] || { echo -; return; }
    tpl=$(overlay_value name) pattern=$(overlay_value pattern) cmd=$(overlay_value command)
    [[ -n $tpl && -n $pattern && -n $cmd ]] || { echo name; return; }
    name=${tpl//\{N\}/$n}
    [[ -n $name && $name =~ $pattern ]] || { echo name; return; }
    cmd=${cmd//\{N\}/$n}
    cmd=${cmd//\{name\}/"$name"}
    fb=$(overlay_value fallback)
    fb=${fb//\{N\}/$n}
    fb=${fb//\{name\}/"$name"}
    printf 'cmd:%s\n%s\n' "$cmd" "${fb:--}"
}

# The `<N>\tleftover\t<command>` line for issue $1, or nothing. Reads the refs the fetch pruned, never ls-remote (a failed
# ls-remote prints nothing and would read as "none"). Only names that are exactly codeo-live/<N>/<letters, digits, . _ ->
# go in (the five proofs that the issue is finished passed, so its branches are deletable whatever the container name): anyone with push access can name a branch with shell metacharacters, and the engineer runs what is printed.
leftover_proof() {
    local n=$1 name names=()
    while IFS= read -r name; do
        [[ $name =~ ^codeo-live/$n/[A-Za-z0-9._-]+$ ]] || continue
        names+=("$name")
    done < <(git for-each-ref --format='%(refname:strip=3)' "refs/remotes/origin/codeo-live/$n/")
    ((${#names[@]})) || return 0
    printf '%s\tleftover\tgit push origin --delete %s\n' "$n" "${names[*]}"
}

hidden=0
while IFS= read -r n; do
    proof=$(first_failed_proof "$n")
    if [[ $proof == ok ]]; then
        out=$(name_proof "$n")
        if [[ $out == name ]]; then
            printf '%s\tfailed\tname\n' "$n"
        elif grep -qxF "$n" <<<"$recorded"; then
            hidden=$((hidden + 1))
        elif [[ $out == - ]]; then
            printf '%s\tproven\t-\t-\n' "$n"
        else
            printf '%s\tproven\t%s\t%s\n' "$n" "$(head -n1 <<<"${out#cmd:}")" "$(tail -n1 <<<"$out")"
        fi
        leftover_proof "$n"
    else
        printf '%s\tfailed\t%s\n' "$n" "$proof"
    fi
done < <(git ls-tree --name-only "$base_sha" -- "$state_rel/done/" 2>/dev/null |
    sed -n 's|.*/\([0-9][0-9]*\)$|\1|p' | sort -n)
if ((hidden)); then echo "cleanup: note: $hidden issue(s) with a recorded removal are not listed" >&2; fi
