#!/usr/bin/env bash
# $CODEO_STATE_DIR/active — the workflow lock: which issue this checkout is bound to. Shared by the
# dev container's start script (host container) and a web session's start script (host web); the
# only difference between them is the branch-checkout step below, which only a web session needs.
#
#   lock.sh take <container|web> [session-id]
#       Writes $CODEO_STATE_DIR/active from the working tree's dossier and prints what it did, or
#       a TODO line when it could not. Never fails the caller.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"
# The dossier globs and git pathspecs below are relative to the repo root, not the caller's cwd.
[[ -z $CODEO_PROJECT_ROOT ]] || cd "$CODEO_PROJECT_ROOT"

# The state directory as git sees it (relative to the repo root, where this runs): dossier paths
# are compared against branch contents, which are never absolute.
state_rel=${CODEO_STATE_DIR#"$CODEO_PROJECT_ROOT"/}

say() { echo "lock: $*"; }

# The issue whose init.md names <branch>: the live dossier at <state>/<N>/ first, else one
# archived under done/ by close while its PR is open — but only an archive the base branch does
# not have yet, since every branch carries the base branch's archive of issues long merged.
find_issue() {
    local branch=$1 path
    mapfile -t found < <(grep -l -F "| Branch | \`$branch\`" "$state_rel"/[0-9]*/init.md 2>/dev/null || true)
    if ((${#found[@]} == 0)); then
        git fetch -q origin "$base" 2>/dev/null || true
        while IFS= read -r path; do
            git cat-file -e "origin/$base:$path" 2>/dev/null || found+=("$path")
        done < <(grep -l -F "| Branch | \`$branch\`" "$state_rel"/done/[0-9]*/init.md 2>/dev/null || true)
    fi
}

# A local branch of this name exists and is not an ancestor of <target>: `checkout -B <branch>
# <target>` would move it off commits that only it holds, leaving them in the reflog.
stale_local() {
    local branch=$1 target=$2
    git show-ref --verify --quiet "refs/heads/$branch" &&
        ! git merge-base --is-ancestor "$branch" "$target"
}

take() {
    local host=${1:?container or web} session=${2:-} todo=() refused=

    if [[ $host == web ]]; then
        # Exactly one live dossier in the working tree, whose recorded branch differs from what
        # is checked out: fetch and check it out first, so every later commit and push lands on
        # the issue's branch rather than whatever harness-named branch the session started on.
        mapfile -t live_dirs < <(find "$CODEO_STATE_DIR" -mindepth 1 -maxdepth 1 -type d -name '[0-9]*' 2>/dev/null)
        if ((${#live_dirs[@]} == 1)) && [[ -f "${live_dirs[0]}/init.md" ]]; then
            dossier_branch=$(sed -n 's/^| Branch | `\([^`]*\)`.*/\1/p' "${live_dirs[0]}/init.md" | head -n1)
            current=$(git branch --show-current)
            if [[ -n $dossier_branch && $dossier_branch != "$current" ]]; then
                # What HEAD holds that origin/<branch> does not decides the checkout. Nothing:
                # check out as before. Commits of its own, with origin/<branch> an ancestor: this
                # session's work, committed on the harness branch before a VM was reclaimed and
                # never pushed — carried as the issue branch's unpushed tip rather than left in
                # the reflog, which is what `-B origin/<branch>` did. A divergence: refused; only
                # the engineer can say which side wins, and with no checkout no dossier names
                # $current, so no lock is taken and every skill stops until it is reconciled.
                # A local <branch> holding commits the checkout would discard (stale_local) is
                # refused the same way, on either path. A refusal sets $refused, so it leaves one
                # TODO and no lock rather than a second, misleading "run init".
                if ! git fetch -q origin "$dossier_branch" 2>/dev/null; then
                    todo+=("could not check out $dossier_branch: fetch or checkout failed; the lock will be judged against $current instead")
                elif git merge-base --is-ancestor HEAD "origin/$dossier_branch"; then
                    if stale_local "$dossier_branch" "origin/$dossier_branch"; then
                        todo+=("local $dossier_branch holds commits origin/$dossier_branch lacks: not checking out, so no lock is taken here — reconcile by hand (git log --oneline origin/$dossier_branch..$dossier_branch shows them), then re-run this script")
                        refused=1
                    elif git checkout -q -B "$dossier_branch" "origin/$dossier_branch"; then
                        say "checked out $dossier_branch (was $current)"
                    else
                        todo+=("could not check out $dossier_branch: fetch or checkout failed; the lock will be judged against $current instead")
                    fi
                elif git merge-base --is-ancestor "origin/$dossier_branch" HEAD; then
                    ahead=$(git rev-list --count "origin/$dossier_branch..HEAD") || ahead="an unknown number of"
                    if stale_local "$dossier_branch" HEAD; then
                        todo+=("local $dossier_branch holds commits HEAD lacks: not checking out, so no lock is taken here — reconcile by hand (git log --oneline HEAD..$dossier_branch shows them), then re-run this script")
                        refused=1
                    elif git checkout -q -B "$dossier_branch" HEAD; then
                        say "checked out $dossier_branch (was $current), carrying $ahead unpushed commit(s) from $current — push before anything else"
                        git branch -q --set-upstream-to="origin/$dossier_branch" "$dossier_branch" ||
                            todo+=("could not set the upstream of $dossier_branch to origin/$dossier_branch: run git branch --set-upstream-to=origin/$dossier_branch $dossier_branch")
                    else
                        todo+=("could not check out $dossier_branch with $current's $ahead unpushed commit(s): checkout failed; the lock will be judged against $current instead")
                    fi
                else
                    todo+=("$current and origin/$dossier_branch have diverged: not checking out, so no lock is taken here — reconcile by hand (git log --oneline origin/$dossier_branch..HEAD shows what $current has), then re-run this script")
                    refused=1
                fi
            fi
        fi
    fi

    # Read only now, and as a TODO rather than a failure: the lock never fails its caller.
    if ! base=$(codeo_base_branch 2>&1); then
        todo+=("${base}")
        for t in "${todo[@]}"; do echo "lock: TODO — $t" >&2; done
        return 0
    fi
    branch=$(git branch --show-current)
    if [[ $branch == "$base" ]]; then
        say "on $base: no workflow lock"
    elif [[ -f "$CODEO_STATE_DIR/active" ]]; then
        # A lock first written while the session id was unset says `session: unknown` for good,
        # since a taken lock is never rewritten. Only that one line is refreshed, only for web,
        # and only by a real id: a real id already recorded is the session that owns the lock.
        if [[ $host == web && -n $session && $session != unknown ]] &&
            grep -qx 'session: unknown' "$CODEO_STATE_DIR/active"; then
            # awk, not sed: the id is data, and must not be read as a sed replacement. Captured
            # first and written back in place only when awk succeeded, so a failed refresh is
            # reported as one — and the file keeps its inode and mode, with no temp file to leave
            # behind.
            if new=$(awk -v id="$session" '$0 == "session: unknown" { print "session: " id; next } { print }' "$CODEO_STATE_DIR/active"); then
                printf '%s\n' "$new" > "$CODEO_STATE_DIR/active"
                say "refreshed the lock's session id to $session"
            else
                todo+=("could not refresh the lock's session id to $session (awk failed): the lock still says session: unknown")
            fi
        fi
        say "lock already taken: $(tr -s ' \n' ' ' < "$CODEO_STATE_DIR/active")"
    elif [[ -n $refused ]]; then
        # A refusal above has already recorded its TODO and taken no lock, so there is nothing to
        # decide here, and the init advice below would be wrong for a divergence.
        :
    else
        found=()
        find_issue "$branch"
        if ((${#found[@]} != 1)); then
            todo+=("no single init.md names branch $branch (found ${#found[@]}): run init for the issue, and bind this host to the branch it pushes")
        else
            n=$(basename "$(dirname "${found[0]}")")
            {
                printf 'issue:   %s\nbranch:  %s\nstarted: %s\nhost:    %s\n' \
                    "$n" "$branch" "$(date -u +%Y-%m-%d)" "$host"
                if [[ $host == container ]]; then
                    volume=$(awk '$5 == "/workspaces" { n = split($4, p, "/"); if (p[n] == "_data") print p[n - 1] }' \
                        /proc/self/mountinfo | head -n 1)
                    printf 'volume:  %s\n' "${volume:-unknown}"
                    [[ -n $volume ]] || todo+=("could not read the workspace volume's name from /proc/self/mountinfo: fill the lock's volume line in by hand (docker volume ls on the host)")
                else
                    printf 'session: %s\n' "${session:-unknown}"
                fi
            } > "$CODEO_STATE_DIR/active"
            say "took the lock for #$n on $branch"
            bash "$CODEO_PLUGIN_ROOT/scripts/intake.sh" restore "$n" >/dev/null 2>&1 || true
        fi
    fi

    for t in "${todo[@]}"; do echo "lock: TODO — $t" >&2; done
}

case ${1:-} in
    take) shift; take "$@" ;;
    *) echo "usage: lock.sh take <container|web> [session-id]" >&2; exit 1 ;;
esac
