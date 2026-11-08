#!/usr/bin/env bash
# Names the VS Code window after the clone's state: "<codename> [home]" when no workflow holds the
# clone, "<codename> [#<N>]" while .codeo/active holds issue N. The codename is .codeo/config.json's,
# else the clone directory's name. Merges window.title into <clone>/.vscode/settings.json (every other
# key stays) and keeps that file out of git status through the clone's info/exclude. Safe to re-run.
# Prints "window-title: <title>" on stdout; exits 1 with one "window-title: ..." line on stderr when it
# could not write (a settings.json that is not valid JSON is left untouched). With --print it prints
# the title alone and writes nothing.
#
#   bash .devcontainer/scripts/window-title.sh [--print]
set -euo pipefail

root=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
die() { echo "window-title: $*" >&2; exit 1; }

codename=$(jq -r '.codename // empty' "$root/.codeo/config.json" 2>/dev/null || true)
[[ -n $codename ]] || codename=$(basename "$root")
issue=""
[[ ! -f $root/.codeo/active ]] || issue=$(awk '/^issue:/ {print $2; exit}' "$root/.codeo/active")
if [[ -n $issue ]]; then title="$codename [#$issue]"; else title="$codename [home]"; fi

if [[ ${1:-} == --print ]]; then
    echo "$title"
    exit 0
fi

settings="$root/.vscode/settings.json"
mkdir -p "$root/.vscode" || die "could not create $root/.vscode"
[[ -f $settings ]] || echo '{}' > "$settings" || die "could not write $settings"
tmp=$(mktemp "$root/.vscode/.settings.XXXXXX") || die "could not write in $root/.vscode"
if ! jq --arg t "$title" '. + {"window.title": $t}' "$settings" > "$tmp" 2>/dev/null; then
    rm -f "$tmp"
    die "$settings is not valid JSON; left untouched"
fi
mv "$tmp" "$settings" || { rm -f "$tmp"; die "could not write $settings"; }

exclude=$(git -C "$root" rev-parse --git-path info/exclude)
[[ $exclude == /* ]] || exclude="$root/$exclude"
mkdir -p "$(dirname "$exclude")"
touch "$exclude"
grep -qxF '.vscode/settings.json' "$exclude" || echo '.vscode/settings.json' >> "$exclude"

echo "window-title: $title"
