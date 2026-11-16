#!/usr/bin/env bash
# Prints the root of the installed codeo plugin, the directory that holds scripts/lock.sh.
#
#   .devcontainer/scripts/codeo-root.sh
#
# Exit 0 with the root on stdout; exit 1 with one "codeo-root:" line on stderr when there is none.
# Order: $CODEO_ROOT when set, else the installPath of codeo@codeo in the plugin registry under
# ${CLAUDE_CONFIG_DIR:-$HOME/.claude} (the lookup devcontainer-start.sh does): the first entry whose projectPath
# is this clone's root (compared after the recorded path is resolved: trailing slash, symlink), else the first with no
# projectPath; an entry with no installPath never qualifies. An entry for another project is never taken,
# and outside a git clone only entries with no projectPath qualify. A set $CODEO_ROOT that
# lacks scripts/lock.sh fails rather than falling through: a wrong override someone typed must not be
# quietly replaced by a different codeo. No path is ever guessed. A path holding a tab or a newline is not
# supported; an empty or false projectPath counts as none.
set -euo pipefail

has_lock() { [[ -f $1/scripts/lock.sh ]]; }

if [[ -n ${CODEO_ROOT:-} ]]; then
    has_lock "$CODEO_ROOT" || { echo "codeo-root: CODEO_ROOT=$CODEO_ROOT has no scripts/lock.sh" >&2; exit 1; }
    echo "$CODEO_ROOT"
    exit 0
fi

registry="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/installed_plugins.json"
root=
if [[ -f $registry ]]; then
    # The clone's physical root; empty outside a git clone, so that only entries with no projectPath qualify
    # (the failure must not abort under set -e).
    clone=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || true)
    [[ -z $clone ]] || clone=$(cd "$clone" && pwd -P)
    # One "projectPath<TAB>installPath" line per entry; an absent, null or false field is empty (jq joins the fields,
    # so a backslash arrives as written, which @tsv would double). A recorded projectPath
    # matches after it is resolved (trailing slash, symlink); one that no longer exists is compared as written.
    # An entry with no installPath never qualifies.
    entries=$(jq -r '.plugins["codeo@codeo"][]? | [((.projectPath // "") | tostring), ((.installPath // "") | tostring)] | join("\t")' \
        "$registry" 2>/dev/null || true)
    fallback=
    while IFS= read -r line; do
        pp=${line%%$'\t'*}
        ip=${line#*$'\t'}
        [[ -n $ip ]] || continue
        if [[ -z $pp ]]; then
            [[ -n $fallback ]] || fallback=$ip
        elif [[ -n $clone ]]; then
            resolved=$(cd "$pp" 2>/dev/null && pwd -P) || resolved=${pp%/}
            if [[ $resolved == "$clone" ]]; then
                root=$ip
                break
            fi
        fi
    done <<< "$entries"
    [[ -n $root ]] || root=$fallback
fi
if [[ -z $root ]] || ! has_lock "$root"; then
    echo "codeo-root: no installed codeo@codeo with scripts/lock.sh in $registry; install it or set CODEO_ROOT" >&2
    exit 1
fi
echo "$root"
