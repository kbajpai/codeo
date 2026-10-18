#!/usr/bin/env bash
# The branch name for an issue, derived mechanically so two inits on one issue derive one name
# rather than whatever each run happens to think of.
#
#   branch-name.sh <issue>
#       Prints <type>/<slug> and exits 0. The type is the one the first of the issue's labels that
#       the config's labelTypes maps (default: enhancement -> feat, bug -> fix, documentation ->
#       docs), else chore. The slug is the title with one leading [...] group stripped,
#       lower-cased, every run of characters outside [a-z0-9] turned into a separator, the stop
#       words dropped, and the first five words kept, joined by `-`. The issue number is never
#       part of it. Exits 1 when no words are left in the title.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

die() { echo "branch-name: $*" >&2; exit 1; }

n=${1:?usage: branch-name.sh <issue>}
here=$(dirname "${BASH_SOURCE[0]}")
stop=(a an the and or of to for in on with from through into as is are be by)

# label -> type. The config's labelTypes replaces the defaults whole when present, so a project can
# drop a mapping as well as add one. An absent key is codeo_cfg's quiet exit 1, not an error.
declare -A types=()
if mapped=$(codeo_cfg '(.labelTypes // empty) | to_entries[] | "\(.key)\t\(.value)"'); then
    while IFS=$'\t' read -r key value; do types[$key]=$value; done <<<"$mapped"
else
    types=([enhancement]=feat [bug]=fix [documentation]=docs)
fi

issue=$(bash "$here/github.sh" issue view "$n") || exit 1
title=$(jq -r .title <<<"$issue")

type=chore
while IFS= read -r label; do
    if [[ -n ${types[$label]+set} ]]; then type=${types[$label]}; break; fi
done < <(jq -r '.labels[]' <<<"$issue")

slug=$(sed -E 's/^[[:space:]]*\[[^]]*\]//' <<<"$title" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g')

words=()
IFS=- read -r -a parts <<<"$slug"
for word in "${parts[@]}"; do
    [[ -n $word ]] || continue
    [[ " ${stop[*]} " == *" $word "* ]] && continue
    words+=("$word")
    ((${#words[@]} == 5)) && break
done

((${#words[@]})) || die "no words left in the title of #$n"
slug=$(IFS=-; echo "${words[*]}")
echo "$type/$slug"
