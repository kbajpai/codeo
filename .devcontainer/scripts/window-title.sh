#!/usr/bin/env bash
# Names the VS Code window after the clone's state: "<codename> [home]" when no workflow holds the
# clone, "<codename> [#<N>]" while .codeo/active holds issue N (written "issue: 44" or "issue: #44").
# The codename is .codeo/config.json's, else the clone directory's name. Keeps .vscode/settings.json
# out of git status through the clone's info/exclude first, then merges window.title into it (every
# other key stays). Safe to re-run.
# Prints "window-title: <title>" on stdout. Every failure (not a repository, an unwritable
# info/exclude or .vscode, a settings.json that is not valid JSON, which is left untouched) exits 1
# with one "window-title: ..." line on stderr. With --print it prints the title alone and writes
# nothing.
#
#   bash .devcontainer/scripts/window-title.sh [--print]
set -euo pipefail

die() { echo "window-title: $*" >&2; exit 1; }

root=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null) \
    || die "not inside a git repository"

codename=$(jq -r '.codename // empty' "$root/.codeo/config.json" 2>/dev/null || true)
[[ -n $codename ]] || codename=$(basename "$root")
issue=""
[[ ! -f $root/.codeo/active ]] || issue=$(awk '/^issue:/ {print $2; exit}' "$root/.codeo/active")
issue=${issue#\#}
if [[ -n $issue ]]; then title="$codename [#$issue]"; else title="$codename [home]"; fi

if [[ ${1:-} == --print ]]; then
    echo "$title"
    exit 0
fi

exclude=$(git -C "$root" rev-parse --git-path info/exclude) || die "could not locate the clone's info/exclude"
[[ $exclude == /* ]] || exclude="$root/$exclude"
msg="could not add .vscode/settings.json to $exclude"
mkdir -p "$(dirname "$exclude")" 2>/dev/null || die "$msg"
touch "$exclude" 2>/dev/null || die "$msg"
grep -qxF '.vscode/settings.json' "$exclude" 2>/dev/null \
    || { echo '.vscode/settings.json' >> "$exclude"; } 2>/dev/null || die "$msg"

settings="$root/.vscode/settings.json"
mkdir -p "$root/.vscode" || die "could not create $root/.vscode"
[[ -f $settings ]] || echo '{}' > "$settings" || die "could not write $settings"
tmp=$(mktemp "$root/.vscode/.settings.XXXXXX") || die "could not write in $root/.vscode"
if ! jq -n --arg t "$title" '([inputs][0] // {}) + {"window.title": $t}' "$settings" > "$tmp" 2>/dev/null || [[ ! -s $tmp ]]; then
    rm -f "$tmp"
    die "$settings is not valid JSON; left untouched"
fi
mv "$tmp" "$settings" || { rm -f "$tmp"; die "could not write $settings"; }

echo "window-title: $title"
