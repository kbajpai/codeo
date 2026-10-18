#!/usr/bin/env bash
# Every shell script under scripts/ is executable, so a skill can run it by path.
#
#   modes.test.sh
#       Exits non-zero and names the first script that is not; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
for f in "$plugin_root"/scripts/*.sh; do
    [[ -x $f ]] || { echo "FAIL: $f is not executable" >&2; exit 1; }
done
echo "all cases passed"
