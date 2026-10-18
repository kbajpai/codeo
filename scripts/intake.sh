#!/usr/bin/env bash
# The intake branch, codeo/intake: where the issue step commits its dossiers, which exist before
# any feature branch does and must never be committed to the base branch, and where every
# workflow's shared state lives — the triage ledger and the leases.
#
#   intake.sh commit <dir> <message> [--drop <old-dir>]
#   intake.sh restore <dir>
#   intake.sh lease take <resource> <N> <purpose> [--override <reason>]
#   intake.sh lease wait <resource> <N>
#   intake.sh lease release <resource> <N>
#   intake.sh lease release-all <N>
#   intake.sh lease check <resource> [N]
#   intake.sh lease list [--tsv]
#
# commit and restore:
#   commit puts .codeo/intake/<dir>/ as it stands in the working tree onto codeo/intake, and pushes
#   it. --drop removes <old-dir> from the branch in the same commit (the rename from new-<slug> to
#   <N> once the issue is filed). restore writes any file of .codeo/intake/<dir>/ that the branch
#   has and this clone does not; a file already here is left alone, as it may carry answers not yet
#   committed. Neither reads the project config.
#
# lease take:
#   A lease is a lock on an exclusive resource, under .codeo/intake/leases/. The resource must be
#   one the config's resources[] lists; an entry with "parameterised": true stands for
#   <name>:<suffix> (the suffix letters, digits, '.', '_' or '-'), never the bare name. A take fails
#   naming the holder while another issue holds it. A plain resource x_y and a parameterised x:y
#   share the lease file name x_y, so avoid configuring both.
#   The config's environment.resource alone has side effects. Its take needs the branch to contain
#   origin/<baseBranch>, since the environment is about to run this branch and one missing merged
#   work would roll it back. It then runs the environment.hooks, in order: start, preflight,
#   activate — each before the lease is published, and a non-zero exit from any of them refuses the
#   take and publishes nothing, --override or not. revoke runs when a take that began running
#   them does not end holding the lease: a hook refused, another issue won the race, the push
#   failed, or the take was interrupted. A holder's own re-take runs the hooks again and keeps the
#   lease (and its activation) whatever they answer.
#   --override <reason> applies to environment.resource only. The reason is exported to the hooks
#   as CODEO_OVERRIDE — whether it excuses anything is the hooks' decision — and recorded as the
#   lease's last line, "override: <reason>". A holder's re-take with --override replaces that
#   line; one without it drops a stale one.
#
# The hooks:
#   Each is a shell command from the config, run with `bash -c` from the project root with
#   CODEO_ISSUE (digits), CODEO_RESOURCE and CODEO_OVERRIDE (empty without --override) exported;
#   its stdout and stderr are the caller's. An absent hook is skipped, and with no
#   environment.resource configured no environment hook runs at all. environment.hooks.deployed is
#   not read here.
#
# lease wait and the queue:
#   A wait queues an issue behind the holder, and the queue binds: while any earlier wait has right
#   of way — each waiter in turn, its clock starting when the one ahead of it ends, for
#   CODEO_LEASE_GRACE_SECONDS (default 3600) — a take by any other issue is refused naming the
#   first live one. A second wait by an issue already queued says it is already waiting; once its
#   right of way has lapsed and the lease is free, it is renewed instead.
#
# lease release and release-all:
#   A release is refused from an issue that does not hold the lease; releasing environment.resource
#   runs the revoke hook. release-all releases everything an issue holds and waits for.
#
# lease check:
#   Exits 0 when N (default: the issue of .codeo/active) holds <resource> on origin, 1 when not
#   (naming the holder), 2 when origin cannot be asked. It fetches strictly and publishes nothing;
#   after a failed fetch it asks origin whether the branch exists, so it never answers from a ref it
#   could not refresh. With no .codeo/active and no N, exit 1: a checkout with no workflow holds
#   nothing.
#
# lease list --tsv:
#   Prints one line per lease instead of the human form, tab-separated:
#   held|waiting<TAB>resource<TAB>issue<TAB>by<TAB>since (issue is digits, no #). Held leases come
#   first, then waiting ones, each in git ls-tree order; nothing is printed when there is no lease
#   or no intake branch.
#
# Every lease decision is read from origin's branch after a fetch. An origin that does not answer
# at all is fatal: `take`, `wait`, `release` and `release-all` fail and say so, and `list` answers
# from the last fetch and says it may be stale. A failed fetch from a reachable origin (the branch
# not created yet, or a transient fetch failure) continues from the last-fetched ref, except
# `check`, which asks origin whether the branch exists and never answers from a ref it could not
# refresh. A push origin refused is retried, never reported as done — and a refused lease push
# moves nothing locally, so no later push from this clone can carry a lease origin never granted. A
# refused commit does keep its local commit, as its PUSH FAILED line says.
#
# After every lease change that reaches origin (take, wait, release, once per `release-all` that
# removed anything) it runs the config's hooks.onLeaseChange, when there is one, best effort: a
# push to the intake branch is how the change lands, and nothing else watches that branch for
# whoever reports on it. Its stdout is discarded and a failure is one stderr line, never a failure
# of the verb — the lease is already on the branch.
#
# None of these checks the branch out, touches the index, or changes what is checked out: every
# commit is built in a throwaway index with plumbing, so it works from any branch or checkout,
# dirty or not. Several engineers push here at once, so a rejected push is rebuilt on origin's new
# tip and retried — safe because each writer owns a directory no other writer touches.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"
[[ -n $CODEO_PROJECT_ROOT ]] || codeo_die "not inside a git repository"
cd "$CODEO_PROJECT_ROOT"

branch=codeo/intake
# Relative to the project root: git trees and every path the pipeline records are relative.
base=${CODEO_STATE_DIR#"$CODEO_PROJECT_ROOT"/}/intake
attempts=3
# release-all defers its onLeaseChange and runs it once at the end if any removal asked for one.
# One that exits through push_failed or die after publishing a removal drops that pending run:
# acceptable, as the command is best effort.
defer_notify=
notify_pending=
# strict: a fetch of origin that fails because origin is unreachable is fatal, since no lease
# decision may come from a stale ref. list, commit and restore set stale-ok and read what they have.
fetch_mode=strict
# What the hooks are told, set once the lease verb has parsed its arguments. Globals rather than
# lease()'s locals because the revoke trap can fire after the frame that set them is gone.
hook_issue=
hook_resource=
hook_override=
# environment.resource, read by lease() once the config is known to be usable.
env_resource=

die() { echo "intake: $*" >&2; exit 1; }

# The newer of the local branch and origin's, after a fetch. Diverged, origin's wins when every
# local-only commit touches nothing but the paths given — the ones the caller is about to re-add
# from the working tree or remove anyway, which is what a push that lost a race leaves behind.
# Anything else is the engineer's to reconcile. With no paths, a reader, origin's wins with a
# warning: what other people pushed is the shared truth.
tip() {
    if ! git fetch -q origin "+refs/heads/$branch:refs/remotes/origin/$branch" 2>/dev/null; then
        # The refspec also fails for a branch origin has not got yet, which is no outage: the first
        # lease ever creates it. Only an origin that will not answer at all is unreachable.
        # --heads: this is a reachability probe, and heads are the cheapest answer — tags are not
        # wanted. --exit-code is not either: an origin with no branch yet is reachable.
        if ! git ls-remote -q --heads origin >/dev/null 2>&1; then
            if [[ $fetch_mode == strict ]]; then
                die "origin is unreachable — could not fetch $branch, and no lease decision is made from a stale ref"
            fi
            echo "intake: origin is unreachable — reading $branch as of the last fetch, which may be stale" >&2
        fi
    fi
    local here there path own
    here=$(git rev-parse -q --verify "refs/heads/$branch" || true)
    there=$(git rev-parse -q --verify "refs/remotes/origin/$branch" || true)
    if [[ -z $here || -z $there ]]; then echo "${here:-$there}"; return; fi
    if git merge-base --is-ancestor "$there" "$here"; then echo "$here"; return; fi
    if git merge-base --is-ancestor "$here" "$there"; then echo "$there"; return; fi
    if (($# == 0)); then
        echo "intake: local $branch has diverged from origin's; reading origin's" >&2
        echo "$there"
        return
    fi
    while IFS= read -r path; do
        own=
        for p; do [[ $path == "$p" || $path == "$p"/* ]] && own=1; done
        [[ -n $own ]] || die "local $branch has unpushed commits touching $path; reconcile them by hand"
    done < <(git diff --name-only "$(git merge-base "$here" "$there")" "$here")
    echo "$there"
}

# A commit on <parent> with <drop> removed and each remaining path taken from the working tree,
# echoed; <parent> itself is echoed when that changes nothing. Its own index, so the real one —
# and whatever the engineer has staged — is untouched.
build() {
    local parent=$1 message=$2 drop=$3 dropped
    shift 3
    # <drop> may name several paths, space-separated (none contains a space: resource suffixes and
    # issue numbers are restricted so).
    read -ra dropped <<< "$drop"
    (
        # Inside the git dir rather than mktemp's /tmp, which a native Windows git cannot see when
        # MSYS path conversion is off.
        GIT_INDEX_FILE=$(git rev-parse --git-path "intake-index.$$")
        export GIT_INDEX_FILE
        trap 'rm -f "$GIT_INDEX_FILE"' EXIT
        if [[ -n $parent ]]; then git read-tree "$parent"; else git read-tree --empty; fi
        # -f: a row rewritten on origin since this clone last wrote it differs from the index entry.
        ((${#dropped[@]} == 0)) || git rm -f -r -q --cached --ignore-unmatch -- "${dropped[@]}"
        # -f: the intake directory is ignored on every other branch. No -A: a dossier absent from
        # this clone is one it never restored, not one to delete.
        (($# == 0)) || git add -f -- "$@"
        local tree
        tree=$(git write-tree)
        if [[ -n $parent && $tree == "$(git rev-parse "$parent^{tree}")" ]]; then
            echo "$parent"
        else
            git commit-tree "$tree" ${parent:+-p "$parent"} -m "$message"
        fi
    )
}

# Push <commit> by sha and move the local branch only once origin took it, so a refused lease push
# leaves nothing a later push could carry (a lease nobody was granted, or a removal nobody
# accepted); `commit` is the one caller that keeps a refused commit, and moves the ref itself.
# Non-zero when origin refused it — almost always because someone else pushed first.
publish() {
    git push -q origin "$1:refs/heads/$branch" && git update-ref "refs/heads/$branch" "$1"
}

# Runs hooks.onLeaseChange after a lease change reached origin. Never fatal and never on stdout —
# the lease is already on the branch, so nothing here may change the command's status or output.
lease_changed() {
    [[ -z $defer_notify ]] || { notify_pending=1; return 0; }
    local cmd err_file rc=0 reason
    cmd=$(codeo_cfg '.hooks.onLeaseChange' 2>/dev/null) || return 0
    err_file=$(mktemp)
    CODEO_ISSUE=$hook_issue CODEO_RESOURCE=$hook_resource CODEO_OVERRIDE=$hook_override \
        bash -c "$cmd" >/dev/null 2>"$err_file" || rc=$?
    if ((rc)); then
        reason=$(sed '/^$/d' "$err_file" | tail -n 1)
        echo "intake: hooks.onLeaseChange failed (${reason:-exit $rc}); the lease change stands" >&2
    fi
    rm -f "$err_file"
    return 0
}

# Runs environment.hooks.<name>, or nothing when the config names none. Its status is the hook's.
run_hook() {
    local cmd
    cmd=$(codeo_cfg ".environment.hooks.$1" 2>/dev/null) || return 0
    CODEO_ISSUE=$hook_issue CODEO_RESOURCE=$hook_resource CODEO_OVERRIDE=$hook_override bash -c "$cmd"
}

# The revoke hook, never fatal: it runs after a release is already on origin, or on the way out of
# a take that is failing anyway, and neither may be turned into a different outcome by it.
revoke() {
    local rc=0
    run_hook revoke || rc=$?
    ((rc == 0)) || echo "intake: the revoke hook exited $rc — $hook_resource may still be active in this checkout" >&2
    return 0
}

# start, preflight and activate in order; 0 when every one passed, else 1 after naming the first
# that did not.
env_hooks() {
    local name rc
    for name in start preflight activate; do
        rc=0
        run_hook "$name" || rc=$?
        if ((rc)); then
            echo "intake: $hook_resource refused — the $name hook exited $rc; nothing was published${hook_override:+ (--override does not cover a failing hook)}" >&2
            return 1
        fi
    done
}

# Exit 0 when <resource> is the configured environment's.
is_env() { [[ -n $env_resource && $1 == "$env_resource" ]]; }

# Two triage runs on two machines both append to the one shared file, so a rebuild on a newer tip
# unions the rows by fingerprint rather than letting the later push drop the earlier one's
# decisions. The later Date wins; a tie keeps the local row.
merge_ledger() {
    local parent=$1 ledger=$base/triage/ledger.md theirs merged
    [[ -n $parent && -f $ledger ]] || return 0
    theirs=$(mktemp)
    merged=$(mktemp)
    if git show "$parent:$ledger" > "$theirs" 2>/dev/null; then
        awk -F'|' '
            function keep(line,   f, n, key, d) {
                n = split(line, f, "|"); key = f[2]; d = f[n - 1]
                gsub(/ /, "", key); gsub(/ /, "", d)
                if (!(key in row)) order[++count] = key
                if (!(key in row) || d >= dated[key]) { row[key] = line; dated[key] = d }
            }
            /^\| `/ { keep($0); if (FILENAME == ARGV[2]) rows = 1; next }
            FILENAME == ARGV[2] { if (rows) tail[++t] = $0; else head[++h] = $0 }
            END {
                for (i = 1; i <= h; i++) print head[i]
                for (i = 1; i <= count; i++) print row[order[i]]
                for (i = 1; i <= t; i++) print tail[i]
            }' "$theirs" "$ledger" > "$merged"
        cat "$merged" > "$ledger"
    fi
    rm -f "$theirs" "$merged"
}

push_failed() {
    local why="$branch is committed locally but not on origin"
    [[ ${1:-} != lease ]] || why="no lease change reached origin, and none was kept locally"
    echo "intake: PUSH FAILED after $attempts attempts — $why" >&2
    exit 3
}

commit() {
    local dir=${1:?dir} message=${2:?message} drop=
    shift 2
    [[ ${1:-} == --drop ]] && drop=${2:?old dir}
    [[ -d $base/$dir ]] || die "$base/$dir does not exist"

    fetch_mode=stale-ok
    local attempt parent new
    for ((attempt = 1; attempt <= attempts; attempt++)); do
        parent=$(tip "$base/$dir" ${drop:+"$base/$drop"})
        [[ $dir != triage ]] || merge_ledger "$parent"
        new=$(build "$parent" "$message" "${drop:+$base/$drop}" "$base/$dir")
        if [[ $new == "$parent" ]]; then echo "intake: nothing to commit for $dir"
        else echo "intake: committed $dir as ${new:0:7}"
        fi
        # Kept locally on a refusal, as the PUSH FAILED line says: the dossier is the engineer's
        # work, and the next commit's push carries it.
        git update-ref "refs/heads/$branch" "$new"
        publish "$new" && return 0
        echo "intake: push refused (attempt $attempt) — rebuilding on origin's tip" >&2
    done
    push_failed
}

restore() {
    local dir=${1:?dir} from path
    fetch_mode=stale-ok
    from=$(tip)
    [[ -n $from ]] || die "no $branch branch, locally or on origin"
    git cat-file -e "$from:$base/$dir" 2>/dev/null || die "$branch has no $base/$dir"
    while IFS= read -r path; do
        if [[ -e $path ]]; then
            echo "intake: kept local $path"
        else
            mkdir -p "$(dirname "$path")"
            git show "$from:$path" > "$path"
            echo "intake: restored $path"
        fi
    done < <(git ls-tree -r --name-only "$from" -- "$base/$dir")
}

# The sha origin's intake branch is at, as of the last fetch, or nothing. Never fetches: `tip` already
# did. Decisions ("already holds", "already waiting") read this, builds read `tip`, because `tip` may be
# ahead by a commit origin refused — a dossier from `commit`, never a lease — which the next push
# carries; a lease is only ever read from what origin accepted.
origin_tip() { git rev-parse -q --verify "refs/remotes/origin/$branch" || true; }

# Exit 0 when origin's intake branch holds <path>.
on_origin() {
    local there
    there=$(origin_tip)
    [[ -n $there ]] && git cat-file -e "$there:$1" 2>/dev/null
}

# The issue holding <lease path> at <commit>, or nothing.
holder() {
    [[ -n $1 ]] || return 0
    field "$1" "$2" issue | sed 's/^#//'
}

# The value of <key>: in the lease file <path> at <commit>, or nothing.
field() { { git show "$1:$2" 2>/dev/null || true; } | sed -n "s/^$3: *//p" | head -n 1; }

# The commit time (epoch seconds) of the newest commit on origin's intake branch that deleted
# <resource>'s lease file, or nothing when it was never held (or never freed).
lease_freed_at() {
    local there
    there=$(origin_tip)
    [[ -n $there ]] || return 0
    git log -1 --diff-filter=D --format=%ct "$there" -- "$base/leases/$(lease_file "$1").md" 2>/dev/null || true
}

# Every wait for <resource> as "<right of way ends, epoch> <issue> <since>", in queue order
# (since, issue number). A wait's right of way starts at its since, when the lease last freed, or
# when the wait ahead of it ends, whichever is latest — time spent behind a holder, or behind the
# waiter ahead, is not time spent waiting — and lasts the grace. Right of way is cumulative so that
# every waiter is protected in turn, not only the first.
queue_rows() {
    local resource=$1 there prefix file stem n since freed grace=${CODEO_LEASE_GRACE_SECONDS:-3600} start prev_end=0
    there=$(origin_tip)
    [[ -n $there ]] || return 0
    prefix=$(lease_file "$resource")
    freed=$(lease_freed_at "$resource")
    local -a rows=()
    while IFS= read -r file; do
        # Compared as strings, not a regex: a configured name may hold a regex metacharacter.
        stem=$(basename "$file" .md)
        [[ $file == *.md && $stem == "$prefix"-* ]] || continue
        n=${stem#"$prefix"-}
        [[ $n =~ ^[0-9]+$ ]] || continue
        since=$(field "$there" "$file" since)
        # A malformed since is skipped, never handed to date.
        [[ $since =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || continue
        rows+=("$since $n")
    done < <(git ls-tree --name-only "$there" -- "$base/leases/waiting/")
    ((${#rows[@]})) || return 0
    # GNU date (-d) only.
    while read -r since n; do
        start=$(date -u -d "$since" +%s)
        ((${freed:-0} <= start)) || start=$freed
        ((prev_end <= start)) || start=$prev_end
        prev_end=$((start + grace))
        echo "$prev_end $n $since"
    done < <(printf '%s\n' "${rows[@]}" | sort -k1,1 -k2,2n)
}

# The first live wait ahead of <issue> in the cumulative order, for <resource> by an issue other than <issue>:
# right of way is per waiter in turn, not just the earliest. That is a wait sorting before <issue>'s
# own wait (or before an absent one), as "<issue> <right of way ends, ISO>", or nothing. The
# search stops at <issue>'s own wait only while that wait is live: an expired own wait is skipped
# like any other, so the waiters behind it still hold their turn.
queue_head() {
    local end n now
    now=$(date -u +%s)
    while read -r end n _; do
        ((end > now)) || continue
        [[ $n != "$2" ]] || break
        echo "$n $(date -u -d "@$end" +%Y-%m-%dT%H:%M:%SZ)"
        return 0
    done < <(queue_rows "$1")
}

# Every wait for <resource> by an issue other than <issue> whose right of way has ended, as
# "<issue> <ended, ISO>" lines.
queue_expired() {
    local end n now
    now=$(date -u +%s)
    while read -r end n _; do
        [[ $n != "$2" ]] || continue
        ((end > now)) || echo "$n $(date -u -d "@$end" +%Y-%m-%dT%H:%M:%SZ)"
    done < <(queue_rows "$1")
}

# Exit 0 when <issue>'s own wait for <resource> is on origin and its right of way has ended.
own_wait_lapsed() {
    local end n now
    now=$(date -u +%s)
    while read -r end n _; do
        [[ $n == "$2" ]] || continue
        ((end <= now))
        return
    done < <(queue_rows "$1")
    return 1
}

# The configured resources: plain names, then parameterised ones, one per line each.
plain_resources() { codeo_cfg '.resources[]? | select(.parameterised != true) | .name // empty' 2>/dev/null || true; }
parameterised_resources() { codeo_cfg '.resources[]? | select(.parameterised == true) | .name // empty' 2>/dev/null || true; }

# The resources a project lists are the things two branches cannot both change and merge cleanly,
# or the one shared environment; anything else is a typo that would lock nothing anyone checks.
# A parameterised suffix is restricted to characters that are safe in a file name and in the
# space-separated drop list build() takes.
resource_ok() {
    local r=$1 name list=()
    while IFS= read -r name; do
        [[ -n $name ]] || continue
        [[ $r != "$name" ]] || return 0
        list+=("$name")
    done < <(plain_resources)
    while IFS= read -r name; do
        [[ -n $name ]] || continue
        if [[ $r == "$name":* && ${r#"$name":} =~ ^[A-Za-z0-9._-]+$ ]]; then return 0; fi
        list+=("$name:<name>")
    done < <(parameterised_resources)
    local configured=none
    if ((${#list[@]})); then
        configured=$(printf '%s, ' "${list[@]}")
        configured=${configured%, }
    fi
    die "unknown resource $r; configured: $configured"
}

# A file name cannot carry the colon of <name>:<suffix>, so it is spelled _ on disk.
lease_file() { echo "${1//:/_}"; }
# The resource a lease file's name stands for; `release-all` and `list` print it as the config
# spells it. Only a configured parameterised name's first _ is read back as the colon, so a plain
# name that itself holds an underscore is printed as it is.
lease_name() {
    local name
    while IFS= read -r name; do
        [[ -n $name && $1 == "$name"_* ]] || continue
        echo "$name:${1#"$name"_}"
        return 0
    done < <(parameterised_resources)
    echo "$1"
}

lease() {
    local head op=${1:-} resource= issue= purpose path waiting attempt parent held new file found= override= checked= ls_status activated_new= row n end drop base_branch
    local -a expired=()
    # An unusable config ends the script here, in the top-level shell, in one line: every lease verb
    # reads the resource list from it.
    codeo_cfg .schema >/dev/null || true
    env_resource=$(codeo_cfg .environment.resource 2>/dev/null || true)
    case $op in
        take | release | wait)
            resource=${2:?resource} issue=${3:?issue number}
            resource_ok "$resource"
            [[ $issue =~ ^[0-9]+$ ]] || die "issue must be a number, got $issue"
            path=$base/leases/$(lease_file "$resource").md
            waiting=$base/leases/waiting/$(lease_file "$resource")-$issue.md
            ;;
    esac
    hook_issue=$issue hook_resource=$resource

    case $op in
        check)
            # Read-only: exit 0 holds, 1 does not, 2 origin cannot be asked — a caller that gates a
            # deploy on this must tell "not yours" from "could not find out".
            resource=${2:?resource}
            resource_ok "$resource"
            issue=${3:-}
            if [[ -z $issue ]]; then
                [[ -f $CODEO_STATE_DIR/active ]] || die "no workflow here — name the issue: lease check <resource> <N>"
                issue=$(sed -n 's/^issue: *#\{0,1\}//p' "$CODEO_STATE_DIR/active" | head -n 1)
            fi
            [[ $issue =~ ^[0-9]+$ ]] || die "issue must be a number, got ${issue:-nothing}"
            path=$base/leases/$(lease_file "$resource").md
            held=
            if ! git fetch -q origin "+refs/heads/$branch:refs/remotes/origin/$branch" 2>/dev/null; then
                # The failed fetch left the last-fetched ref, which may name a holder origin has since
                # dropped, so ask origin whether the branch is there before reading anything from it:
                # exit 2 is "no such branch" (nothing is leased), 0 is a fetch that failed against
                # a branch that exists, and anything else is an origin that does not answer.
                ls_status=0
                git ls-remote -q --exit-code --heads origin "refs/heads/$branch" >/dev/null 2>&1 || ls_status=$?
                case $ls_status in
                    2) ;;
                    0)
                        echo "intake: could not refresh $branch from origin — cannot tell whether #$issue holds $resource" >&2
                        exit 2
                        ;;
                    *)
                        echo "intake: origin is unreachable — cannot tell whether #$issue holds $resource" >&2
                        exit 2
                        ;;
                esac
            else
                held=$(holder "$(origin_tip)" "$path")
            fi
            [[ $held != "$issue" ]] || return 0
            echo "intake: #$issue does not hold $resource (${held:+held by #}${held:-not held})" >&2
            return 1
            ;;
        take)
            purpose=${4:?purpose}
            if [[ ${5:-} == --override ]]; then
                [[ -n ${6:-} ]] || die "--override needs a reason: lease take <resource> <N> <purpose> --override <reason>"
                (($# == 6)) || die "usage: intake.sh lease take <resource> <N> <purpose> [--override <reason>]"
                is_env "$resource" ||
                    die "--override applies only to the environment resource${env_resource:+ ($env_resource)}: $resource has no preflight"
                override=$6
            else
                (($# == 4)) || die "usage: intake.sh lease take <resource> <N> <purpose> [--override <reason>]"
            fi
            hook_override=$override
            # The environment is about to run this branch. Missing something already merged, it
            # would roll the environment back and test against a base that no longer exists.
            if is_env "$resource"; then
                base_branch=$(codeo_base_branch) || exit 1
                if ! git fetch -q origin "$base_branch" 2>/dev/null; then
                    # A failed fetch is an outage only when origin answers nothing at all (the
                    # probe tip() uses); otherwise the configured base branch is the thing at fault.
                    if git ls-remote -q --heads origin >/dev/null 2>&1; then
                        die "branch $base_branch does not exist on origin — check baseBranch in config.json"
                    fi
                    die "origin is unreachable — could not fetch $base_branch, which $resource must be checked against"
                fi
                git merge-base --is-ancestor "origin/$base_branch" HEAD ||
                    die "this branch does not contain origin/$base_branch — merge it in first, then take $resource"
            fi
            for ((attempt = 1; attempt <= attempts; attempt++)); do
                parent=$(tip "$path" "$waiting")
                held=$(holder "$(origin_tip)" "$path")
                if [[ $held == "$issue" ]]; then
                    echo "intake: #$issue already holds $resource"
                    if is_env "$resource"; then
                        # Holding it already, this checkout keeps its activation however the hooks
                        # end — never revoked on this path. That includes the traps an earlier
                        # attempt of this same take set (a concurrent take of this issue published
                        # first): left in place, the EXIT trap would revoke the holder's activation.
                        if [[ -n $activated_new ]]; then trap - EXIT INT TERM; fi
                        activated_new=
                        if [[ -z $checked ]]; then
                            if ! env_hooks; then
                                echo "intake: #$issue still holds $resource — the lease is unchanged" >&2
                                return 1
                            fi
                            checked=1
                        fi
                        if [[ -z $override ]] &&
                            git show "$(origin_tip):$path" 2>/dev/null | grep -q '^override:'; then
                            # The hooks pass without one, so the override the lease records is
                            # stale: dropped the same way it was written, or the lease keeps
                            # claiming one was needed.
                            { git show "$(origin_tip):$path" | grep -v '^override:' || true; } > "$path"
                            new=$(build "$parent" "docs(codeo): $resource override dropped for #$issue" "" "$path")
                            if publish "$new"; then
                                echo "intake: the hooks pass without --override — dropped the lease's override line"
                                lease_changed
                                return 0
                            fi
                            continue
                        fi
                        if [[ -n $override ]]; then
                            # Recorded on the lease: its override line is replaced, the rest kept.
                            { git show "$(origin_tip):$path" | grep -v '^override:' || true; } > "$path"
                            echo "override: $override" >> "$path"
                            new=$(build "$parent" "docs(codeo): $resource override for #$issue" "" "$path")
                            if publish "$new"; then
                                echo "intake: #$issue took $resource WITH OVERRIDE: $override — record it in your dossier's ## Log line"
                                lease_changed
                                return 0
                            fi
                            continue
                        fi
                    fi
                    return 0
                fi
                if [[ -n $held ]]; then
                    git show "$(origin_tip):$path" >&2
                    # The hooks ran for a take that is now lost: give the activation back.
                    if [[ -n $activated_new ]]; then
                        trap - EXIT INT TERM
                        revoke
                    fi
                    die "$resource is leased to #$held — record the wait with 'lease wait', or ask its holder"
                fi
                head=$(queue_head "$resource" "$issue")
                if [[ -n $head ]]; then
                    if [[ -n $activated_new ]]; then
                        trap - EXIT INT TERM
                        revoke
                    fi
                    die "$resource is #${head%% *}'s turn — it has waited since $(field "$(origin_tip)" "$base/leases/waiting/$(lease_file "$resource")-${head%% *}.md" since) and keeps right of way until ${head#* }; record your own wait with 'lease wait', or ask #${head%% *}"
                fi
                expired=()
                while read -r n end; do
                    [[ -z $n ]] || expired+=("$n $end")
                done < <(queue_expired "$resource" "$issue")
                if is_env "$resource" && [[ -z $checked ]]; then
                    # The traps go up before the first hook, not after: a hook may take seconds,
                    # and an interruption (Ctrl-C, a closed terminal, a killed agent) or a set -e
                    # abort in that window would otherwise leave this checkout activated for a
                    # lease it does not hold. The revoke hook must therefore be safe to run when
                    # activation never finished. Until the lease is published, INT and TERM
                    # become exits so the EXIT trap runs and the status is still signal-style.
                    # This runs in the top-level shell (the dispatch below calls `lease` directly), so
                    # the traps are the process's.
                    activated_new=1
                    trap revoke EXIT
                    trap 'exit 130' INT
                    trap 'exit 143' TERM
                    if ! env_hooks; then
                        trap - EXIT INT TERM
                        revoke
                        return 1
                    fi
                    checked=1
                fi
                mkdir -p "$(dirname "$path")"
                printf 'issue:   #%s\nbranch:  %s\nby:      %s\nsince:   %s\npurpose: %s\n' \
                    "$issue" "$(git branch --show-current)" \
                    "$(bash "$CODEO_PLUGIN_ROOT/scripts/github.sh" user login 2>/dev/null || git config user.email)" \
                    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$purpose" > "$path"
                [[ -z $override ]] || echo "override: $override" >> "$path"
                # Taking the lease ends this issue's wait, in the same commit.
                # A wait whose right of way has ended is dropped with it: the take that finds it
                # expired is the one that grants the lease, so no separate sweep exists.
                drop=$waiting
                for row in ${expired[@]+"${expired[@]}"}; do
                    drop+=" $base/leases/waiting/$(lease_file "$resource")-${row%% *}.md"
                done
                new=$(build "$parent" "docs(codeo): lease $resource for #$issue" "$drop" "$path")
                # The push is the compare-and-swap: refused means someone moved the branch, so the
                # holder is read again rather than the take retried blindly.
                if publish "$new"; then
                    # Granted: the activation stays with the holder.
                    trap - EXIT INT TERM
                    rm -f "$waiting"
                    echo "intake: #$issue took $resource"
                    for row in ${expired[@]+"${expired[@]}"}; do
                        echo "intake: dropped #${row%% *}'s wait for $resource — right of way ended ${row#* }"
                    done
                    [[ -z $override ]] ||
                        echo "intake: #$issue took $resource WITH OVERRIDE: $override — record it in your dossier's ## Log line"
                    lease_changed
                    return 0
                fi
            done
            if [[ -n $activated_new ]]; then
                trap - EXIT INT TERM
                revoke
            fi
            push_failed lease
            ;;
        wait)
            # The queue binds: while a wait has right of way, a take by anyone else is refused (see
            # queue_head), and the list shows who has been waiting since when. A wait whose right of
            # way has lapsed protects nobody, so on a free lease it is renewed (since: is rewritten to
            # now) rather than reported as already waiting; on a held lease it is left alone, as the
            # holder's time is not time spent waiting.
            local renewed=
            for ((attempt = 1; attempt <= attempts; attempt++)); do
                parent=$(tip "$waiting")
                if on_origin "$waiting"; then
                    if [[ -n $(holder "$(origin_tip)" "$path") ]] || ! own_wait_lapsed "$resource" "$issue"; then
                        echo "intake: #$issue is already waiting for $resource"
                        return 0
                    fi
                    renewed=1
                fi
                mkdir -p "$(dirname "$waiting")"
                printf 'issue:   #%s\nbranch:  %s\nby:      %s\nsince:   %s\n' \
                    "$issue" "$(git branch --show-current)" \
                    "$(bash "$CODEO_PLUGIN_ROOT/scripts/github.sh" user login 2>/dev/null || git config user.email)" \
                    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$waiting"
                new=$(build "$parent" "docs(codeo): #$issue waits for $resource" "" "$waiting")
                if publish "$new"; then
                    if [[ -n $renewed ]]; then
                        echo "intake: #$issue's wait for $resource had lapsed — renewed"
                    else
                        echo "intake: #$issue is waiting for $resource"
                    fi
                    lease_changed
                    return 0
                fi
            done
            push_failed lease
            ;;
        release)
            for ((attempt = 1; attempt <= attempts; attempt++)); do
                parent=$(tip "$path")
                held=$(holder "$(origin_tip)" "$path")
                if [[ -z $held ]]; then
                    rm -f "$path"
                    echo "intake: $resource is not leased"
                    # Not leased, but this checkout may still be activated from a take whose
                    # release was lost; revoking an inactive one is the hook's no-op.
                    ! is_env "$resource" || revoke
                    return 0
                fi
                [[ $held == "$issue" ]] || die "$resource is leased to #$held, not #$issue — only its holder releases it"
                new=$(build "$parent" "docs(codeo): release $resource from #$issue" "$path")
                if publish "$new"; then
                    rm -f "$path"
                    echo "intake: #$issue released $resource"
                    lease_changed
                    ! is_env "$resource" || revoke
                    return 0
                fi
            done
            push_failed lease
            ;;
        release-all)
            # Everything an issue has on the board — what it holds and what it waits for — for
            # every exit of the close step.
            issue=${2:?issue number}
            [[ $issue =~ ^[0-9]+$ ]] || die "issue must be a number, got $issue"
            hook_issue=$issue
            # tip's fetch is what makes origin_tip current; origin_tip never fetches.
            tip >/dev/null
            parent=$(origin_tip)
            [[ -n $parent ]] || { echo "intake: no leases"; return 0; }
            defer_notify=1
            for file in $(git ls-tree --name-only "$parent" -- "$base/leases/"); do
                [[ $file == *.md ]] || continue
                if [[ $(holder "$parent" "$file") == "$issue" ]]; then
                    lease release "$(lease_name "$(basename "$file" .md)")" "$issue"
                fi
            done
            # The releases above moved origin's tip, so the waiting list is read from it afresh.
            hook_issue=$issue hook_resource=
            for file in $(git ls-tree --name-only "$(origin_tip)" -- "$base/leases/waiting/"); do
                [[ $file == */*-"$issue".md ]] || continue
                removed=
                for ((attempt = 1; attempt <= attempts; attempt++)); do
                    parent=$(tip "$file")
                    new=$(build "$parent" "docs(codeo): #$issue stops waiting" "$file")
                    if publish "$new"; then
                        rm -f "$file"
                        echo "intake: #$issue no longer waits ($(basename "$file" .md))"
                        lease_changed
                        removed=1
                        break
                    fi
                done
                [[ -n $removed ]] || push_failed lease
            done
            defer_notify=
            hook_issue=$issue hook_resource=
            [[ -z $notify_pending ]] || lease_changed
            echo "intake: #$issue holds and waits for nothing"
            ;;
        list)
            (($# <= 2)) || die "usage: intake.sh lease list [--tsv]"
            local tsv= resource_name
            case ${2:-} in
                "") ;;
                --tsv) tsv=1 ;;
                *) die "usage: intake.sh lease list [--tsv]" ;;
            esac
            fetch_mode=stale-ok
            parent=$(tip)
            if [[ -n $parent ]]; then
                for file in $(git ls-tree --name-only "$parent" -- "$base/leases/"); do
                    [[ $file == *.md ]] || continue
                    found=1
                    if [[ -n $tsv ]]; then
                        printf '%s\t%s\t%s\t%s\t%s\n' held "$(lease_name "$(basename "$file" .md)")" "$(holder "$parent" "$file")" "$(field "$parent" "$file" by)" "$(field "$parent" "$file" since)"
                        continue
                    fi
                    echo "== $(lease_name "$(basename "$file" .md)") — held"
                    git show "$parent:$file"
                done
                for file in $(git ls-tree --name-only "$parent" -- "$base/leases/waiting/"); do
                    found=1
                    if [[ -n $tsv ]]; then
                        resource_name=$(basename "$file" .md)
                        printf '%s\t%s\t%s\t%s\t%s\n' waiting "$(lease_name "${resource_name%-*}")" "$(holder "$parent" "$file")" "$(field "$parent" "$file" by)" "$(field "$parent" "$file" since)"
                        continue
                    fi
                    echo "== $(lease_name "$(basename "$file" .md)") — waiting"
                    git show "$parent:$file"
                done
            fi
            [[ -n $found || -n $tsv ]] || echo "intake: no leases"
            ;;
        *) die "usage: intake.sh lease take <resource> <N> <purpose> [--override <reason>] | wait <resource> <N> | release <resource> <N> | release-all <N> | check <resource> [N] | list [--tsv]" ;;
    esac
}

case ${1:-} in
    commit) shift; commit "$@" ;;
    restore) shift; restore "$@" ;;
    lease) shift; lease "$@" ;;
    *) die "usage: intake.sh commit <dir> <message> [--drop <old-dir>] | restore <dir> | lease …" ;;
esac
