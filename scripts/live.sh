#!/usr/bin/env bash
# The live-session signal: a short-lived marker that this checkout is working on an issue right now,
# kept as a git ref — refs/codeo/live/<issue>/<machine> on origin — so every other clone can see
# who is live without a branch, a commit on any branch or a pull request. "Live" means the signal's
# `beat` is at most CODEO_LIVE_TTL_SECONDS old; whatever beats it keeps it fresh, and a signal
# nobody refreshes simply ages out of `list`.
#
#   live.sh beat [--force]
#       Publishes this checkout's signal: one parentless commit on the empty tree, force-pushed over
#       the previous one, so a signal never accumulates history. Does nothing without a
#       $CODEO_STATE_DIR/active lock or on the base branch, and — without --force — while the last
#       beat is younger than CODEO_LIVE_REFRESH_SECONDS. A refused or failed push is retried once
#       through `github.sh ref put`, except for a web session: it cannot write refs/codeo/live/*, so
#       it force-pushes refs/heads/codeo-live/<issue>/<machine> instead and has no fallback. Exits 0
#       whatever happens; a failure is one `live:` stderr line.
#   live.sh clear
#       Deletes this checkout's signal (`git push --delete`, else `github.sh ref delete`) and its
#       throttle stamp. A web session deletes nothing (it cannot): it removes the stamp, its saved
#       machine label (codeo-live-machine) and its
#       branch ages out after the TTL. Exits 0 whatever happens.
#   live.sh fetch
#       Brings origin's signals into refs/codeo/live/, and a web session's codeo-live branches into
#       refs/codeo/live-web/ (their own namespace, so equal labels never collide), pruning the ones
#       cleared there. Exit 0, or exit 1 with one `live:` stderr line.
#   live.sh list [--tsv]
#       Prints the signals last fetched (it never fetches) from refs/codeo/live/ and
#       refs/codeo/live-web/ that are within the TTL. --tsv:
#       issue<TAB>user<TAB>machine<TAB>host<TAB>age-in-seconds, oldest issue first. Otherwise one
#       `#<issue>  <user> on <machine> (<host>), <age> ago` line each. A signal missing a field, or
#       with a non-numeric beat, is skipped; a beat up to the TTL in the future counts as age 0, one
#       further ahead is skipped.
#
# The signal's commit message:
#       codeo live signal   (a web host: `codeo live signal [skip ci]`, so push-triggered CI skips the beat; subject line only)
#
#       issue: <N>
#       user: <GitHub login, else git user.name, else unknown; a web session never uses git config user.name>
#       machine: <label>
#       host: <container|web|local>   (always web when CLAUDE_CODE_REMOTE is true, whatever the lock's host says)
#       beat: <epoch seconds>
#   The machine is $CODEO_MACHINE, else the container's volume or sandbox, else for a web session the label
#   saved in <git dir>/codeo-live-machine by its first beat (kept while it is a clean label; `clear` removes
#   it), else `web-<first 8 of the session>`, else `hostname`, cut to 64 characters of [A-Za-z0-9._-] and made a valid ref component. The
#   commit's identity is codeo-live <codeo-live@invalid>, passed per command; no git config is read
#   for it or written, and no email address goes in the message.
#
# Limits worth knowing:
#   - Without a `timeout` binary (stock macOS) a push or fetch is unbounded.
#   - `beat` is fail-open by design: it is called as `beat "$@" || true`, which turns `set -e` off
#     inside it, so a failing step never stops the caller.
#   - The throttle stamp is written before the push, so a failed publish is not retried until the
#     refresh interval has passed (or a --force beat).
#   - Two beats started together from one checkout can both push the same ref, and one can
#     lose the origin's ref lock; the other has then just published, so the signal is fresh
#     either way.
#   - A web session's signal is a branch that is never deleted: it expires from `list` after the TTL
#     but the branch stays on origin until someone removes it.
#   - A web checkout keeps its first label until `clear`: a session id that changes between beats
#     does not publish a second signal, but a changed CODEO_MACHINE never rewrites the saved label.
#   - A detached `beat` can republish after `clear`; that signal simply expires after the TTL.
#   - `clear` can take two bounds (the push `--delete`, then the REST delete), so the `SessionEnd`
#     hook allows 20 seconds. That is two bounds at the default of 8; at 10 or more the hook can
#     end `clear` during the REST delete, and the signal then only ages out after the TTL.
#
# Environment:
#   CODEO_LIVE_REFRESH_SECONDS  minimum seconds between two unforced beats (default 300)
#   CODEO_LIVE_TTL_SECONDS      how old a beat may be and still be listed (default 900)
#   CODEO_MACHINE               the machine label, overriding the host's default
#   CODEO_GITHUB_LOGIN          the user named in the signal, read before any lookup (all sessions)
#   CLAUDE_CODE_REMOTE_SESSION_ID  a web session's id, which gives its machine label `web-<first 8>`
#                               when the lock holds none
#   CODEO_LIVE_PUSH_TIMEOUT     seconds each git push or fetch, the login lookup, the issue-assignee
#                               lookup, and the REST fallback may take (default 8); the fallback is `github.sh ref put`
#                               for a `beat` and `github.sh ref delete` for a `clear`, all of its
#                               calls together
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"
[[ -z $CODEO_PROJECT_ROOT ]] || cd "$CODEO_PROJECT_ROOT"

refresh=${CODEO_LIVE_REFRESH_SECONDS:-300}
ttl=${CODEO_LIVE_TTL_SECONDS:-900}
push_timeout=${CODEO_LIVE_PUSH_TIMEOUT:-8}
export GIT_TERMINAL_PROMPT=0
github=$(dirname "${BASH_SOURCE[0]}")/github.sh

warn() { echo "live: $*" >&2; }

# One line, whatever the command said, for a warning.
last_line() { tr '\r\n' '\n\n' <<< "$1" | grep . | tail -n 1 || true; }

# Runs a command with the push timeout when `timeout` exists.
bounded() {
    if command -v timeout > /dev/null 2>&1; then timeout "$push_timeout" "$@"; else "$@"; fi
}

# A lock field's value; the lock aligns its values with spaces after the colon.
lock_field() { sed -n "s/^$1:[[:space:]]*//p" "$CODEO_STATE_DIR/active" | head -n 1; }

# Printable single-line text of at most <n> characters, with no '@': nothing in a signal can look
# like an email address or carry a second field.
clean() { tr -c '[:print:]' ' ' <<< "$1" | tr -s ' ' | tr '@' '-' | cut -c "1-$2" | sed 's/^ //; s/ $//'; }

# A label that is one valid ref component whatever the host calls itself: only [A-Za-z0-9._-],
# at most 64 characters, no "..", no leading or trailing ".", no ".lock" suffix.
ref_label() {
    local label
    label=$(printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '-' | cut -c 1-64 | sed 's/\.\.*\./-/g; s/^\./-/; s/\.$/-/')
    label=${label/%.lock/-lock}
    [[ -n $label ]] || label=unknown
    printf '%s' "$label"
}

# Where a web checkout keeps its first machine label, so a session id that changes later does not
# publish under a second one.
label_file() { git rev-parse --git-path codeo-live-machine; }

# The saved web label, or nothing when there is none or it is not already a clean ref label.
saved_label() {
    local saved
    saved=$(head -n 1 "$(label_file)" 2> /dev/null) || saved=
    if [[ -n $saved && $(ref_label "$saved") == "$saved" ]]; then printf '%s' "$saved"; fi
}

machine_label() {
    local host=$1 name= saved
    if [[ -n ${CODEO_MACHINE:-} ]]; then
        name=$CODEO_MACHINE
    elif [[ $host == web ]] && saved=$(saved_label) && [[ -n $saved ]]; then
        name=$saved
    else
        case $host in
            container) name=$(lock_field volume); [[ -n $name ]] || name=$(lock_field sandbox) ;;
            web)
                name=$(lock_field session)
                [[ -n $name && $name != unknown ]] || name=${CLAUDE_CODE_REMOTE_SESSION_ID:-}
                name=${name#cse_}
                name=${name#session_}
                [[ -z $name || $name == unknown ]] || name=web-${name:0:8}
                ;;
        esac
        [[ -n $name && $name != unknown ]] || name=$(hostname 2> /dev/null || echo unknown)
    fi
    ref_label "$name"
}

# The first assignee of the issue, or nothing on any failure.
assignee_label() {
    bounded bash "$github" issue view "$issue" 2> /dev/null | jq -r '.assignees[0] // empty' 2> /dev/null || true
}

user_label() {
    local name=${CODEO_GITHUB_LOGIN:-}
    [[ -n $name ]] || name=$(bounded bash "$github" user login 2> /dev/null) || name=
    [[ -n $name || $host != web ]] || name=$(assignee_label)
    [[ -n $name || $host == web ]] || name=$(git config user.name 2> /dev/null) || name=
    name=$(clean "$name" 64)
    printf '%s' "${name:-unknown}"
}

# Sets issue, host, signal_ref and push_ref from the lock; non-zero when there is none to speak for.
read_lock() {
    [[ -f $CODEO_STATE_DIR/active ]] || return 1
    issue=$(lock_field issue)
    host=$(lock_field host)
    [[ $issue =~ ^[1-9][0-9]{0,8}$ ]] || return 1
    case $host in container | web | local) ;; *) return 1 ;; esac
    # A hosted web session is web whatever its lock says (init may have written local): the label,
    # the route and the REST-fallback guard all follow. The lock file is left as it is.
    [[ ${CLAUDE_CODE_REMOTE:-} != true ]] || host=web
    machine=$(machine_label "$host")
    signal_ref=refs/codeo/live/$issue/$machine
    # A hosted web session cannot write refs/codeo/live/*, but it can force-push a branch.
    if [[ $host == web ]]; then push_ref=refs/heads/codeo-live/$issue/$machine; else push_ref=$signal_ref; fi
}

stamp() { git rev-parse --git-path codeo-live-beat; }

beat() {
    local force= subject now last base current tree sha message_file reason
    [[ ${1:-} != --force ]] || force=1
    read_lock || return 0
    base=$(codeo_base_branch 2> /dev/null) || base=
    current=$(git branch --show-current 2> /dev/null) || current=
    [[ -z $base || $current != "$base" ]] || return 0

    now=$(date +%s)
    if [[ -z $force && -f $(stamp) ]]; then
        last=$(cat "$(stamp)" 2> /dev/null) || last=
        [[ $last =~ ^[0-9]+$ ]] && ((now - last < refresh)) && return 0
    fi
    echo "$now" > "$(stamp)"
    # A web checkout keeps the first label it publishes under; CODEO_MACHINE is never saved.
    if [[ $host == web && -z ${CODEO_MACHINE:-} ]]; then
        printf '%s\n' "$machine" > "$(label_file)" 2> /dev/null || true
    fi

    message_file=$(mktemp "$(git rev-parse --git-path codeo-live-message).XXXXXX")
    subject='codeo live signal'
    [[ $host == web ]] && subject='codeo live signal [skip ci]'
    printf '%s\n\nissue: %s\nuser: %s\nmachine: %s\nhost: %s\nbeat: %s\n' \
        "$subject" "$issue" "$(user_label)" "$machine" "$host" "$now" > "$message_file"
    tree=$(git hash-object -t tree -w /dev/null)
    sha=$(GIT_AUTHOR_NAME=codeo-live GIT_AUTHOR_EMAIL=codeo-live@invalid \
        GIT_COMMITTER_NAME=codeo-live GIT_COMMITTER_EMAIL=codeo-live@invalid \
        git commit-tree "$tree" -F "$message_file") || { rm -f "$message_file"; warn "could not publish — commit-tree failed"; return 0; }

    if reason=$(bounded git push -q --no-verify --force origin "$sha:$push_ref" 2>&1); then
        rm -f "$message_file"
        return 0
    fi
    if [[ $host != web ]] && reason=$(bounded bash "$github" ref put "$signal_ref" "$message_file" 2>&1 > /dev/null); then
        rm -f "$message_file"
        return 0
    fi
    rm -f "$message_file"
    warn "could not publish — $(last_line "$reason")"
}

clear() {
    local reason
    read_lock || return 0
    rm -f "$(stamp)" "$(label_file)"
    [[ $host != web ]] || return 0
    bounded git push -q --no-verify origin --delete "$signal_ref" > /dev/null 2>&1 && return 0
    if reason=$(bounded bash "$github" ref delete "$signal_ref" 2>&1 > /dev/null); then return 0; fi
    warn "could not clear — $(last_line "$reason")"
}

fetch() {
    local reason
    if reason=$(bounded git fetch -q --prune origin '+refs/codeo/live/*:refs/codeo/live/*' '+refs/heads/codeo-live/*:refs/codeo/live-web/*' 2>&1); then return 0; fi
    warn "could not fetch — $(last_line "$reason")"
    return 1
}

list() {
    local tsv= ref msg issue user machine host beat now age
    [[ ${1:-} != --tsv ]] || tsv=1
    now=$(date +%s)
    while IFS= read -r ref; do
        msg=$(git log -1 --format=%B "$ref" 2> /dev/null) || continue
        issue=$(sed -n 's/^issue: //p' <<< "$msg" | head -n 1)
        user=$(sed -n 's/^user: //p' <<< "$msg" | head -n 1)
        machine=$(sed -n 's/^machine: //p' <<< "$msg" | head -n 1)
        host=$(sed -n 's/^host: //p' <<< "$msg" | head -n 1)
        beat=$(sed -n 's/^beat: //p' <<< "$msg" | head -n 1)
        [[ -n $issue && -n $user && -n $machine && -n $host ]] || continue
        # Anyone with push access can plant a ref here, so every field is checked on the way out.
        case $host in container | web | local) ;; *) continue ;; esac
        [[ $issue =~ ^[1-9][0-9]{0,8}$ && $beat =~ ^[1-9][0-9]{0,11}$ ]] || continue
        user=$(clean "$user" 64)
        machine=$(clean "$machine" 64)
        [[ -n $user && -n $machine ]] || continue
        ((beat - now <= ttl)) || continue
        age=$((now - beat))
        ((age >= 0)) || age=0
        ((age <= ttl)) || continue
        printf '%s\t%s\t%s\t%s\t%s\n' "$issue" "$user" "$machine" "$host" "$age"
    done < <(git for-each-ref --format='%(refname)' refs/codeo/live/ refs/codeo/live-web/) | sort -t $'\t' -k1,1n -s |
        if [[ -n $tsv ]]; then
            cat
        else
            while IFS=$'\t' read -r issue user machine host age; do
                if ((age < 60)); then age="${age}s"; else age="$((age / 60))m"; fi
                printf '#%s  %s on %s (%s), %s ago\n' "$issue" "$user" "$machine" "$host" "$age"
            done
        fi
}

case ${1:-} in
    beat) shift; beat "$@" || true; exit 0 ;;
    clear) clear || true; exit 0 ;;
    fetch) fetch ;;
    list) shift; list "$@" ;;
    *) echo "usage: live.sh beat [--force] | clear | fetch | list [--tsv]" >&2; exit 1 ;;
esac
