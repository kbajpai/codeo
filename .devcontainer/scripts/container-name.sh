#!/usr/bin/env bash
# What this clone's dev container is called, for the VS Code window (window-title.sh), every Claude
# session in it (session-title.sh) and the Docker container name: "<codename> [#<N>]" while
# .codeo/active holds issue N (the digits after the first "issue:" line, with or without spaces, tabs
# or "#"), else "<codename> [home]". The Docker name is "<codename>-<N>" / "<codename>-home". A lock
# that names no issue reads as home. The codename is .codeo/config.json's, else the clone
# directory's name. All three names come from this one script so they cannot drift apart.
# Prints one line on stdout. Outside a git repository it exits 1 with one "container-name: ..." line
# on stderr.
#
#   bash .devcontainer/scripts/container-name.sh [--docker|--codename] [dir]
#       --docker   prints the Docker name instead of the title.
#       --codename prints the codename alone.
#       dir        anywhere inside the clone (default: the current directory).
set -euo pipefail

die() { echo "container-name: $*" >&2; exit 1; }

mode=title
case ${1:-} in
    --docker) mode=docker; shift ;;
    --codename) mode=codename; shift ;;
esac
dir=${1:-.}

root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || die "$dir is not inside a git repository"

codename=$(jq -r '.codename // empty' "$root/.codeo/config.json" 2>/dev/null || true)
[[ -n $codename ]] || codename=$(basename "$root")
issue=""
[[ ! -f $root/.codeo/active ]] \
    || issue=$(sed -n 's/^issue:[[:space:]]*#*\([0-9]\{1,\}\).*/\1/p' "$root/.codeo/active" | head -n 1) || true

case $mode in
    codename) echo "$codename" ;;
    docker) echo "$codename-${issue:-home}" ;;
    *) if [[ -n $issue ]]; then echo "$codename [#$issue]"; else echo "$codename [home]"; fi ;;
esac
