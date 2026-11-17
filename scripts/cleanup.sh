#!/usr/bin/env bash
# Proves each finished issue is really finished, and prints what a project's overlay says removes its leftovers.
# It only prints: it never runs the command it prints, and runs no container-engine command at all.
#
#   cleanup.sh
#       Fetches origin with --prune, lists the .codeo/done/<N> directories on origin/<baseBranch>, and prints
#       one tab-separated line per issue, in ascending N:
#           <N> TAB proven TAB <command>    every proof passed; <command> is `-` when the overlay gives none
#           <N> TAB failed TAB <proof>      the first proof that failed
#       Proofs, in order:
#           issue         the issue's state is closed
#           pull-request  done/<N>/close.md has a `#<number> <url>` line and that PR has a merged_at
#           branch        the PR's head branch is gone from origin (an empty or null head
#                         branch fails)
#           dossier       no origin branch still has a .codeo/<N>/ directory (.codeo/done/<N>/ does not count)
#           lease         no lease is held and no wait is recorded for the issue on the intake branch
#                         (intake.sh lease list --tsv, read once after the fetch; unreadable stops the script)
#           name          the overlay's name template, pattern and command are all present, and the expanded
#                         name matches the pattern. The only place a command is built.
#
# The overlay body (cleanup/removal-command) is three lines: `name: <template with {N}>`,
# `pattern: <extended regex>` and `command: <template with {name}>`; it comes from `overlay.sh cleanup removal-command`. No
# overlay (overlay.sh exit 3, or 2 while the point is unregistered) means `proven` with `-`; any other failure dies.
#
# Config keys read: baseBranch (see lib/env.sh).
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"
die() { echo "cleanup: $*" >&2; exit 1; }

cd "$(git rev-parse --show-toplevel)"
base=$(codeo_base_branch)
state_rel=${CODEO_STATE_DIR#"$CODEO_PROJECT_ROOT"/}
github=$CODEO_PLUGIN_ROOT/scripts/github.sh

git fetch -q --prune origin || die "fetch failed; nothing proven"
# The proofs read refs/remotes/origin/*, which only a clone that fetches every branch keeps whole.
git config --get-all remote.origin.fetch | grep -Eqx '\+?refs/heads/\*:refs/remotes/origin/\*' ||
    die "origin's fetch refspec does not cover every branch; nothing proven"
base_sha=$(git rev-parse "origin/$base") || die "no origin/$base"
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

# Last proof, and the only place a command is built: prints the command, `-`, or `name` for a failure.
name_proof() {
    local n=$1 tpl pattern cmd name
    [[ -n $overlay ]] || { echo -; return; }
    tpl=$(overlay_value name) pattern=$(overlay_value pattern) cmd=$(overlay_value command)
    [[ -n $tpl && -n $pattern && -n $cmd ]] || { echo name; return; }
    name=${tpl//\{N\}/$n}
    [[ -n $name && $name =~ $pattern ]] || { echo name; return; }
    cmd=${cmd//\{name\}/"$name"}
    echo "cmd:$cmd"
}

while IFS= read -r n; do
    proof=$(first_failed_proof "$n")
    if [[ $proof == ok ]]; then
        out=$(name_proof "$n")
        case $out in
            -) printf '%s\tproven\t-\n' "$n" ;;
            name) printf '%s\tfailed\tname\n' "$n" ;;
            *) printf '%s\tproven\t%s\n' "$n" "${out#cmd:}" ;;
        esac
    else
        printf '%s\tfailed\t%s\n' "$n" "$proof"
    fi
done < <(git ls-tree --name-only "$base_sha" -- "$state_rel/done/" 2>/dev/null |
    sed -n 's|.*/\([0-9][0-9]*\)$|\1|p' | sort -n)
