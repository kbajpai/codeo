#!/usr/bin/env bash
# Exercises tests/run.sh against a scratch tests/ directory holding one passing and one failing
# stub, so the runner's filter, exit status and success line are checked without running the
# real suite (which would recurse into this file).
#
#   run.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

# run.sh finds the tests next to itself, so the scratch copy sees only the stubs.
mkdir -p "$scratch/tests"
cp "$repo_root/tests/run.sh" "$scratch/tests/run.sh"
printf '#!/usr/bin/env bash\necho "stub ok"\n' > "$scratch/tests/alpha.test.sh"
printf '#!/usr/bin/env bash\necho "stub boom"\nexit 1\n' > "$scratch/tests/beta.test.sh"
runner="$scratch/tests/run.sh"

fail() { echo "FAIL: $1" >&2; exit 1; }

out=$(bash "$runner" alpha 2>&1) || fail "passing filter should exit 0"
[[ "$out" == *"all cases passed"* ]] || fail "success should print 'all cases passed'"

rc=0
out=$(bash "$runner" beta 2>&1) || rc=$?
[[ "$rc" -ne 0 ]] || fail "failing filter should exit non-zero"
[[ "$out" == *"stub boom"* ]] || fail "a failing file's output should be printed"
[[ "$out" != *"all cases passed"* ]] || fail "failure must not print 'all cases passed'"

rc=0
out=$(bash "$runner" 2>&1) || rc=$?
[[ "$rc" -ne 0 ]] || fail "no filter runs every file, so the failing one should fail the run"

echo "all cases passed"
