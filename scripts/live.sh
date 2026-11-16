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
#       through `github.sh ref put`. Exits 0 whatever happens; a failure is one `live:` stderr line.
#   live.sh clear
#       Deletes this checkout's signal (`git push --delete`, else `github.sh ref delete`) and its
#       throttle stamp. Exits 0 whatever happens.
#   live.sh fetch
#       Brings origin's signals into refs/codeo/live/, pruning the ones cleared there. Exit 0, or
#       exit 1 with one `live:` stderr line.
#   live.sh list [--tsv]
#       Prints the signals last fetched (it never fetches) that are within the TTL. --tsv:
#       issue<TAB>user<TAB>machine<TAB>host<TAB>age-in-seconds, oldest issue first. Otherwise one
#       `#<issue>  <user> on <machine> (<host>), <age> ago` line each. A signal missing a field, or
#       with a non-numeric beat, is skipped; a beat up to the TTL in the future counts as age 0, one
#       further ahead is skipped.
#
# The signal's commit message:
#       codeo live signal
#
#       issue: <N>
#       user: <GitHub login, else git user.name, else unknown>
#       machine: <label>
#       host: <container|web|local>
#       beat: <epoch seconds>
#   The machine is $CODEO_MACHINE, else the container's volume, else `web-<first 8 of the session>`,
#   else `hostname`, cut to 64 characters of [A-Za-z0-9._-] and made a valid ref component. The
#   commit's identity is codeo-live <codeo-live@invalid>, passed per command; no git config is read
#   for it or written, and no email address goes in the message.
#
# Limits worth knowing:
#   - Without a `timeout` binary (stock macOS) a push or fetch is unbounded.
#   - `beat` is fail-open by design: it is called as `beat "$@" || true`, which turns `set -e` off
#     inside it, so a failing step never stops the caller.
#   - The throttle stamp is written before the push, so a failed publish is not retried until the
#     refresh interval has passed (or a --force beat).
#   - A detached `beat` can republish after `clear`; that signal simply expires after the TTL.
#
# Environment:
#   CODEO_LIVE_REFRESH_SECONDS  minimum seconds between two unforced beats (default 300)
#   CODEO_LIVE_TTL_SECONDS      how old a beat may be and still be listed (default 900)
#   CODEO_MACHINE               the machine label, overriding the host's default
#   CODEO_LIVE_PUSH_TIMEOUT     seconds each git push or fetch, the login lookup, and the REST fallback
#                               (`github.sh ref put`, all its calls together) may take (default 8)
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

machine_label() {
    local host=$1 name=
    if [[ -n ${CODEO_MACHINE:-} ]]; then
        name=$CODEO_MACHINE
    else
        case $host in
            container) name=$(lock_field volume) ;;
            web) name=$(lock_field session) ; [[ -z $name || $name == unknown ]] || name=web-${name:0:8} ;;
        esac
        [[ -n $name && $name != unknown ]] || name=$(hostname 2> /dev/null || echo unknown)
    fi
    ref_label "$name"
}

user_label() {
    local name
    name=$(bounded bash "$github" user login 2> /dev/null) || name=$(git config user.name 2> /dev/null) || name=
    name=$(clean "$name" 64)
    printf '%s' "${name:-unknown}"
}

# Sets issue, host and signal_ref from the lock; non-zero when there is none to speak for.
read_lock() {
    [[ -f $CODEO_STATE_DIR/active ]] || return 1
    issue=$(lock_field issue)
    host=$(lock_field host)
    [[ $issue =~ ^[1-9][0-9]{0,8}$ ]] || return 1
    case $host in container | web | local) ;; *) return 1 ;; esac
    machine=$(machine_label "$host")
    signal_ref=refs/codeo/live/$issue/$machine
}

stamp() { git rev-parse --git-path codeo-live-beat; }

beat() {
    local force= now last base current tree sha message_file reason
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

    message_file=$(mktemp "$(git rev-parse --git-path codeo-live-message).XXXXXX")
    printf 'codeo live signal\n\nissue: %s\nuser: %s\nmachine: %s\nhost: %s\nbeat: %s\n' \
        "$issue" "$(user_label)" "$machine" "$host" "$now" > "$message_file"
    tree=$(git hash-object -t tree -w /dev/null)
    sha=$(GIT_AUTHOR_NAME=codeo-live GIT_AUTHOR_EMAIL=codeo-live@invalid \
        GIT_COMMITTER_NAME=codeo-live GIT_COMMITTER_EMAIL=codeo-live@invalid \
        git commit-tree "$tree" -F "$message_file") || { rm -f "$message_file"; warn "could not publish — commit-tree failed"; return 0; }

    if reason=$(bounded git push -q --no-verify --force origin "$sha:$signal_ref" 2>&1); then
        rm -f "$message_file"
        return 0
    fi
    if reason=$(bounded bash "$github" ref put "$signal_ref" "$message_file" 2>&1 > /dev/null); then
        rm -f "$message_file"
        return 0
    fi
    rm -f "$message_file"
    warn "could not publish — $(last_line "$reason")"
}

clear() {
    local reason
    read_lock || return 0
    rm -f "$(stamp)"
    bounded git push -q --no-verify origin --delete "$signal_ref" > /dev/null 2>&1 && return 0
    if reason=$(bounded bash "$github" ref delete "$signal_ref" 2>&1 > /dev/null); then return 0; fi
    warn "could not clear — $(last_line "$reason")"
}

fetch() {
    local reason
    if reason=$(bounded git fetch -q --prune origin '+refs/codeo/live/*:refs/codeo/live/*' 2>&1); then return 0; fi
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
    done < <(git for-each-ref --format='%(refname)' refs/codeo/live/) | sort -t $'\t' -k1,1n -s |
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
