#!/usr/bin/env bash
# codeo is public and serves every project, so nothing in the repository may name a project that uses
# it. This guards that: a project's name, its owner or its private paths show up here only by
# mistake, usually pasted from a design note or a fixture.
#
#   agnostic.test.sh
#       Exits non-zero naming each tracked file and line that matches a forbidden word; prints
#       "all cases passed" otherwise. Add a word to `forbidden` when a new project starts using codeo.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

# Assembled from parts so this file does not match its own list.
forbidden=("road""master" "sara""thi" "\.agent""skills")

fail=0
for word in "${forbidden[@]}"; do
    hits=$(git ls-files -z | xargs -0 grep -nIiE -- "$word" 2>/dev/null || true)
    if [[ -n $hits ]]; then
        echo "FAIL: tracked files mention a project-specific word (/$word/):" >&2
        echo "$hits" >&2
        fail=1
    fi
done
((fail == 0)) || exit 1
echo "all cases passed"
