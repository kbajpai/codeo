#!/usr/bin/env bash
# $CODEO_STATE_DIR/active — the workflow lock: which issue this checkout is bound to. Shared by the
# dev container's start script (host container), a web session's start script (host web) and a
# plain checkout (host local, which the default init takes itself). Only a web session needs the
# branch-checkout step below; container and local differ only in the line that identifies the
# checkout: a container records its volume (or its sandbox, when told with --sandbox), and a plain
# checkout has nothing to identify.
#
#   lock.sh take <container|web|local> [--sandbox <name>] [session-id]
#       Writes $CODEO_STATE_DIR/active from the working tree's dossier and prints what it did, or
#       a TODO line when it could not. Never fails the caller.
#       With CODEO_LOCK_SKIP_PARKED=1 in the environment it takes no lock, and says so in a TODO
#       line, when the dossier it found is parked by claim.sh's rule: more park headings
#       (park_re) in <state>/<N>/close.md than resume lines (resume_re) in <state>/<N>/init.md, both
#       trimmed of trailing whitespace, an absent file counting 0. Decided before any web checkout.
#       Unset, or anything else, it behaves as above.
#       Needs a verified login (lib/identity.sh codeo_whoami): without one, or when the issue's
#       owner or assignees are someone else, it takes no lock and prints a TODO line. The lock
#       records the login on a `user:` line after `host:`.
#
#   lock.sh verify [--override "<words>"]
#       Exit 0 and "lock: verified #<N> as <login>" when the acting login owns the locked issue;
#       exit 1 and one "codeo:" line on stderr otherwise. --override passes one ownership refusal
#       and records an `override:` line under ## Notes of the local init.md.
#
#   lock.sh owner [<N>]
#       Prints the recorded owner login of #<N> (default: the locked issue), or nothing.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/identity.sh"
# The dossier globs and git pathspecs below are relative to the repo root, not the caller's cwd.
[[ -z $CODEO_PROJECT_ROOT ]] || cd "$CODEO_PROJECT_ROOT"

# The state directory as git sees it (relative to the repo root, where this runs): dossier paths
# are compared against branch contents, which are never absolute.
state_rel=${CODEO_STATE_DIR#"$CODEO_PROJECT_ROOT"/}

say() { echo "lock: $*"; }

# The park rule of claim.sh --stash-live (same regexes and trimming), read from the working tree:
# parked while the park headings in <dossier>/close.md outnumber the resume lines in <dossier>/init.md.
park_re='^### Round [0-9]+ — (.+ — )?(stashed|abandoned)([^[:alnum:]].*)?$'
resume_re='^- .* — resumed: by .* after the (stash|abandon) of '
is_parked() {
    local parks=0 resumes=0
    [[ ! -f $1/close.md ]] || parks=$(sed 's/[[:space:]]*$//' "$1/close.md" | grep -cE "$park_re" || true)
    [[ ! -f $1/init.md ]] || resumes=$(sed 's/[[:space:]]*$//' "$1/init.md" | grep -cE "$resume_re" || true)
    ((parks > resumes))
}

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

same_login() { [[ ${1,,} == "${2,,}" ]]; }

# The local dossier file of <issue>: live, else archived under done/. Prints nothing when absent.
local_init() {
    local f
    for f in "$state_rel/$1/init.md" "$state_rel/done/$1/init.md"; do
        [[ -f $f ]] && { printf '%s\n' "$f"; return 0; }
    done
    return 0
}

# check_owner <issue> <branch> <login> <type>: exit 0 when <login> may act on the issue; 1 with one
# "codeo:" line in $refusal (and $refused_owner) when it belongs to someone else; 2 when it could
# not be checked (no override applies). $note collects what a pass should say. A hosted web
# session's unverified login is never compared with the owner or the assignees (verify compares it
# with the lock's own user: line). The pushed dossier is read from FETCH_HEAD after fetching <branch>; no such ref,
# or no origin remote at all, means the local dossier; a branch on origin without a dossier, or
# any other failure to reach origin, fails closed.
check_owner() {
    local n=$1 branch=$2 login=$3 type=$4 rc=0 src= p tmp owner date when assignees out
    refusal= refused_owner= note=
    [[ $type != unverified ]] || return 0
    tmp=$(mktemp)
    if git remote get-url origin >/dev/null 2>&1; then
        git ls-remote --exit-code origin "refs/heads/$branch" >/dev/null 2>&1 || rc=$?
        if ((rc == 0)); then
            if ! git fetch -q origin "$branch" 2>/dev/null; then
                refusal="codeo: could not check who owns #$n: cannot reach origin"
                rm -f "$tmp"; return 2
            fi
            for p in "$state_rel/$n/init.md" "$state_rel/done/$n/init.md"; do
                if git show "FETCH_HEAD:$p" > "$tmp" 2>/dev/null; then src=origin; break; fi
            done
            if [[ -z $src ]]; then
                refusal="codeo: could not check who owns #$n: no dossier on origin's $branch"
                rm -f "$tmp"; return 2
            fi
        elif ((rc != 2)); then
            refusal="codeo: could not check who owns #$n: cannot reach origin"
            rm -f "$tmp"; return 2
        fi
    fi
    if [[ -z $src ]]; then
        p=$(local_init "$n")
        if [[ -n $p ]]; then cp "$p" "$tmp"; fi
        note="branch not on origin: read the local dossier"
    fi
    owner=$(codeo_owner_of_init "$tmp")
    date=$(sed -n 's/^- \([0-9-]\{1,\}\) — resumed: by .* after .*/\1/p' "$tmp" | tail -n1)
    rm -f "$tmp"
    if [[ -n $owner ]] && ! same_login "$owner" "$login"; then
        refused_owner=$owner
        when=claimed
        if [[ -n $date ]]; then when="last resumed $date"; fi
        refusal="codeo: #$n belongs to $owner ($when) — you are $login; ask them, or take it over with /codeo:init #$n"
        return 1
    fi
    if ! out=$(bash "$CODEO_PLUGIN_ROOT/scripts/github.sh" issue view "$n" 2>/dev/null) ||
        ! assignees=$(jq -r '.assignees | join(", ")' <<< "$out" 2>/dev/null); then
        refusal="codeo: could not check who owns #$n: cannot read the issue's assignees"
        return 2
    fi
    if [[ -n $assignees ]] && ! jq -e --arg l "${login,,}" '.assignees | map(ascii_downcase) | index($l)' <<< "$out" >/dev/null; then
        refused_owner=${owner:-$assignees}
        refusal="codeo: #$n is assigned to $assignees, not $login — ask them, or take it over with /codeo:init #$n"
        return 1
    fi
    return 0
}

# Appends one override line to the local dossier's ## Notes (created before ## Outcome when absent).
record_override() {
    local file=$1 line=$2 i notes=-1 outcome=-1 end lines=()
    mapfile -t lines < "$file"
    for i in "${!lines[@]}"; do
        if [[ ${lines[i]} == '## Notes' && $notes -lt 0 ]]; then notes=$i; fi
        if [[ ${lines[i]} == '## Outcome' && $outcome -lt 0 ]]; then outcome=$i; fi
    done
    {
        if ((notes >= 0)); then
            end=${#lines[@]}
            for ((i = notes + 1; i < ${#lines[@]}; i++)); do
                if [[ ${lines[i]} == '## '* ]]; then end=$i; break; fi
            done
            while ((end - 1 > notes)) && [[ -z ${lines[end - 1]} ]]; do end=$((end - 1)); done
            printf '%s\n' "${lines[@]:0:end}"
            if ((end == notes + 1)); then echo; fi
            printf '%s\n' "$line"
            if ((end < ${#lines[@]})); then echo; printf '%s\n' "${lines[@]:end}"; fi
        elif ((outcome >= 0)); then
            if ((outcome > 0)); then printf '%s\n' "${lines[@]:0:outcome}"; fi
            printf '## Notes\n\n%s\n\n' "$line"
            printf '%s\n' "${lines[@]:outcome}"
        else
            printf '%s\n' "${lines[@]}"
            printf '\n## Notes\n\n%s\n' "$line"
        fi
    } > "$file.tmp.$$" && mv "$file.tmp.$$" "$file"
}

verify() {
    local override= have_override= row login type n branch locked_user rc=0 file line
    while (($#)); do
        case $1 in
            --override) have_override=1; override=${2:-}; shift; if (($# > 0)); then shift; fi ;;
            *) echo "usage: lock.sh verify [--override \"<words>\"]" >&2; return 1 ;;
        esac
    done
    if [[ -n $have_override && -z ${override//[[:space:]]/} ]]; then
        echo "codeo: --override needs the engineer's words" >&2
        return 1
    fi
    if [[ ! -f $CODEO_STATE_DIR/active ]]; then
        echo "lock: no workflow lock here" >&2
        return 1
    fi
    n=$(sed -n 's/^issue: *//p' "$CODEO_STATE_DIR/active" | head -n1)
    branch=$(sed -n 's/^branch: *//p' "$CODEO_STATE_DIR/active" | head -n1)
    locked_user=$(sed -n 's/^user: *//p' "$CODEO_STATE_DIR/active" | head -n1)
    row=$(codeo_whoami) || return 1
    login=${row%%$'\t'*}
    type=${row#*$'\t'}

    refusal=
    note=
    refused_owner=
    if [[ $type == unverified ]]; then
        note="not independently verified: hosted web session"
        if [[ -n $locked_user ]] && ! same_login "$locked_user" "$login"; then
            refused_owner=$locked_user
            refusal="codeo: this checkout was locked by $locked_user, you are $login — ask them, or take it over with /codeo:init #$n"
        fi
    else
        check_owner "$n" "$branch" "$login" "$type" || rc=$?
        if ((rc == 2)); then echo "$refusal" >&2; return 1; fi
        if ((rc == 0)); then
            if [[ -z $locked_user ]]; then
                note="${note:+$note; }legacy lock: no recorded user"
            elif ! same_login "$locked_user" "$login"; then
                refused_owner=$locked_user
                refusal="codeo: this checkout was locked by $locked_user, you are $login — ask them, or take it over with /codeo:init #$n"
            fi
        fi
    fi

    if [[ -n $refusal ]]; then
        if [[ -z $have_override ]]; then
            echo "$refusal" >&2
            return 1
        fi
        file=$(local_init "$n")
        if [[ -z $file ]]; then
            echo "codeo: no local dossier for #$n to record the override in" >&2
            return 1
        fi
        line="- $(date -u +%Y-%m-%d) — override: $login over ${refused_owner:-unknown}: \"$override\""
        record_override "$file" "$line"
        echo "$line"
        say "verified #$n as $login (by override)"
        return 0
    fi
    say "verified #$n as $login${note:+ ($note)}"
}

owner() {
    local n=${1:-} file
    if [[ -z $n ]]; then
        [[ -f $CODEO_STATE_DIR/active ]] || { echo "lock: no workflow lock here" >&2; return 1; }
        n=$(sed -n 's/^issue: *//p' "$CODEO_STATE_DIR/active" | head -n1)
    fi
    file=$(local_init "$n")
    if [[ -n $file ]]; then codeo_owner_of_init "$file"; fi
    return 0
}

take() {
    local host=${1:?container, web or local} session todo=() refused= sandbox= sandbox_flag=
    shift
    # --sandbox <name> is read only for a container, and shifted off before the session id.
    if [[ ${1:-} == --sandbox ]]; then
        sandbox_flag=1
        sandbox=${2:-}
        shift
        (($# == 0)) || shift
    fi
    session=${1:-}

    if [[ $host == web ]]; then
        # Exactly one live dossier in the working tree, whose recorded branch differs from what
        # is checked out: fetch and check it out first, so every later commit and push lands on
        # the issue's branch rather than whatever harness-named branch the session started on.
        mapfile -t live_dirs < <(find "$CODEO_STATE_DIR" -mindepth 1 -maxdepth 1 -type d -name '[0-9]*' 2>/dev/null)
        if [[ ${CODEO_LOCK_SKIP_PARKED:-} == 1 ]] && ((${#live_dirs[@]} == 1)) && is_parked "${live_dirs[0]}"; then
            echo "lock: TODO — #$(basename "${live_dirs[0]}") is stashed or abandoned: no lock taken" >&2
            return 0
        fi
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
        elif n=$(basename "$(dirname "${found[0]}")") &&
            [[ ${CODEO_LOCK_SKIP_PARKED:-} == 1 ]] && is_parked "$(dirname "${found[0]}")"; then
            # Opt-in, for a session whose hook retakes the lock: close --stash and an abandon leave
            # the dossier at <state>/<N>/ with no lock, and a retake would undo them.
            todo+=("#$n is stashed or abandoned: no lock taken")
        elif ! who=$(codeo_whoami 2>&1); then
            todo+=("no lock taken: ${who#codeo: }")
        elif n=$(basename "$(dirname "${found[0]}")") && login=${who%%$'\t'*} &&
            ! check_owner "$n" "$branch" "$login" "${who#*$'\t'}"; then
            todo+=("no lock taken: ${refusal#codeo: }")
        else
            n=$(basename "$(dirname "${found[0]}")")
            {
                printf 'issue:   %s\nbranch:  %s\nstarted: %s\nhost:    %s\nuser:    %s\n' \
                    "$n" "$branch" "$(date -u +%Y-%m-%d)" "$host" "$login"
                if [[ $host == container && -n $sandbox_flag && $sandbox =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
                    # Told which sandbox this checkout runs in: record it, not a volume.
                    printf 'sandbox: %s\n' "$sandbox"
                elif [[ $host == container ]]; then
                    [[ -z $sandbox_flag ]] ||
                        todo+=("--sandbox needs a name of letters, digits, ., _ and -: the lock records a volume instead")
                    # A host convention (the dev container mounts its volume at /workspaces), kept in
                    # the core for parity with web sessions; the host module will own it later.
                    volume=$(awk '$5 == "/workspaces" { n = split($4, p, "/"); if (p[n] == "_data") print p[n - 1] }' \
                        "${CODEO_MOUNTINFO:-/proc/self/mountinfo}" 2>/dev/null | head -n 1) || volume=
                    printf 'volume:  %s\n' "${volume:-unknown}"
                    [[ -n $volume ]] || todo+=("could not read the workspace volume's name from /proc/self/mountinfo: fill the lock's volume line in by hand (docker volume ls on the host)")
                elif [[ $host == local ]]; then
                    # A plain checkout is identified by its own path, which the lock never records.
                    :
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
    verify) shift; verify "$@" ;;
    owner) shift; owner "$@" ;;
    *) echo "usage: lock.sh take <container|web|local> [--sandbox <name>] [session-id] | verify [--override \"<words>\"] | owner [<N>]" >&2; exit 1 ;;
esac
