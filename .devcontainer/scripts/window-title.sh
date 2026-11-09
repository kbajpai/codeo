#!/usr/bin/env bash
# Names the VS Code window after the clone's state: "<codename> [home]" when no workflow holds the
# clone, "<codename> [#<N>]" while .codeo/active holds issue N (the digits after "issue:", with or without
# spaces or "#").
# The codename is .codeo/config.json's, else the clone directory's name. Keeps .vscode/settings.json
# out of git status through the clone's info/exclude first, then merges window.title into it (every
# other key stays). Safe to re-run: a symlinked settings.json is written through (a dangling one is
# created at its target), its mode is kept, and a title already current is not rewritten.
# Prints "window-title: <title>" on stdout. Every failure (not a repository, an unwritable
# info/exclude or .vscode, a settings.json that is not valid JSON, JSONC with comments included, or
# not a JSON object, which is left untouched) exits 1 with one "window-title: ..." line on stderr.
# With --print it prints the title alone and writes nothing.
#
#   bash .devcontainer/scripts/window-title.sh [--print]
set -euo pipefail

die() { echo "window-title: $*" >&2; exit 1; }

root=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null) \
    || die "not inside a git repository"

codename=$(jq -r '.codename // empty' "$root/.codeo/config.json" 2>/dev/null || true)
[[ -n $codename ]] || codename=$(basename "$root")
issue=""
[[ ! -f $root/.codeo/active ]] \
    || issue=$(sed -n 's/^issue: *#*\([0-9]\{1,\}\).*/\1/p' "$root/.codeo/active" | head -n 1) || true
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

mkdir -p "$root/.vscode" || die "could not create $root/.vscode"
# Write through a symlink: the resolved path is the file we read and replace (a dangling link is created
# at its target).
target=$(readlink -f -- "$root/.vscode/settings.json") || die "could not resolve $root/.vscode/settings.json"
src=$target
if [[ -e $target ]]; then
    kind=$(jq -rn '[inputs] | if length == 0 then "object" elif length == 1 then (.[0] | type) else "multi" end' "$target" 2>/dev/null || true)
    [[ -n $kind && $kind != multi ]] || die "$target is not valid JSON; left untouched"
    [[ $kind == object ]] || die "$target is not a JSON object; left untouched"
    current=$(jq -r '.["window.title"] // empty | strings' "$target" 2>/dev/null || true)
    if [[ $current == "$title" ]]; then
        echo "window-title: $title"
        exit 0
    fi
else
    src=/dev/null
fi
tmp=$(mktemp "$(dirname "$target")/.settings.XXXXXX") || die "could not write in $(dirname "$target")"
if ! jq -n --arg t "$title" '([inputs][0] // {}) + {"window.title": $t}' "$src" > "$tmp" 2>/dev/null || [[ ! -s $tmp ]]; then
    rm -f "$tmp"
    die "could not merge window.title into $target; left untouched"
fi
if [[ -e $target ]]; then
    chmod --reference="$target" -- "$tmp" 2>/dev/null || { rm -f "$tmp"; die "could not keep the mode of $target"; }
else
    chmod 644 -- "$tmp" 2>/dev/null || { rm -f "$tmp"; die "could not write $target"; }
fi
mv -- "$tmp" "$target" || { rm -f "$tmp"; die "could not write $target"; }

echo "window-title: $title"
