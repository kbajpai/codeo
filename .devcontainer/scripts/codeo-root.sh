#!/usr/bin/env bash
# Prints the root of the installed codeo plugin, the directory that holds scripts/lock.sh.
#
#   .devcontainer/scripts/codeo-root.sh
#
# Exit 0 with the root on stdout; exit 1 with one "codeo-root:" line on stderr when there is none.
# Order: $CODEO_ROOT when set, else the installPath of codeo@codeo in the plugin registry under
# ${CLAUDE_CONFIG_DIR:-$HOME/.claude} (the lookup devcontainer-start.sh does). A set $CODEO_ROOT that
# lacks scripts/lock.sh fails rather than falling through: a wrong override someone typed must not be
# quietly replaced by a different codeo. No path is ever guessed.
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
    root=$(jq -r '.plugins["codeo@codeo"][0].installPath // empty' "$registry" 2>/dev/null || true)
fi
if [[ -z $root ]] || ! has_lock "$root"; then
    echo "codeo-root: no installed codeo@codeo with scripts/lock.sh in $registry; install it or set CODEO_ROOT" >&2
    exit 1
fi
echo "$root"
