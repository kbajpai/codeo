#!/usr/bin/env bash
# Exercises codeo_owner_of_init and codeo_owner_date_of_init in lib/identity.sh against scratch
# dossier files: the Owner row's spacing and backticks, resume lines, imitations, legacy lines.
#
#   identity.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../lib/identity.sh
source "$plugin_root/lib/identity.sh"

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

assert_eq() {
    local name=$1 want=$2 got=$3
    if [[ $want != "$got" ]]; then
        echo "FAIL: $name: want '$want', got '$got'" >&2
        exit 1
    fi
}

write() { printf '%b' "$2" > "$scratch/$1"; }

write plain.md '| Owner | alice |\n'
write tick.md '| Owner | `alice` |\n'
write wide.md '| Owner  |   alice   |\n'
write two.md '| Owner | carol |\n- 2026-01-02 — resumed: by alice after the stash of 2026-01-01\n- 2026-01-05 — resumed: by bob after the stash of 2026-01-04\n'
write imit.md '| Owner | carol |\n- 2026-01-02 — resumed: by alice after the stash of 2026-01-01\n- 2026-01-06 — override: note that resumed: by mallory after nothing\n'
write legacy.md '- 2026-01-02 — resumed: by no login after the stash of 2026-01-01\n'

assert_eq 'plain row' alice "$(codeo_owner_of_init "$scratch/plain.md")"
assert_eq 'backticked row' alice "$(codeo_owner_of_init "$scratch/tick.md")"
assert_eq 'wide row' alice "$(codeo_owner_of_init "$scratch/wide.md")"
assert_eq 'two resumes' bob "$(codeo_owner_of_init "$scratch/two.md")"
assert_eq 'imitation' alice "$(codeo_owner_of_init "$scratch/imit.md")"
assert_eq 'legacy owner' '' "$(codeo_owner_of_init "$scratch/legacy.md")"
assert_eq 'no file' '' "$(codeo_owner_of_init "$scratch/none.md")"

assert_eq 'date of two resumes' 2026-01-05 "$(codeo_owner_date_of_init "$scratch/two.md")"
assert_eq 'date of row only' '' "$(codeo_owner_date_of_init "$scratch/plain.md")"
assert_eq 'date of legacy' '' "$(codeo_owner_date_of_init "$scratch/legacy.md")"

echo "all cases passed"
