#!/usr/bin/env bash
# Self-test for tests/skills.test.sh: builds a scratch plugin tree with one good skill and nine
# deliberately broken ones, runs the real lint checks against it, and asserts the good skill is
# clean and each broken one is reported with its skill name, check and offender.
#
#   skills-lint.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=skills.test.sh
source "$plugin_root/tests/skills.test.sh"

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }

PREC='Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.'

# Writes a skill. $1 = name (directory), $2 = body after the precedence line ("" for none),
# $3 = frontmatter name (default $1), $4 = "noprec" to omit the precedence sentence.
make_skill() {
    local dir="$scratch/skills/$1"
    mkdir -p "$dir"
    {
        printf -- '---\nname: %s\ndescription: A test skill.\nmodel: sonnet\n---\n\n' "${3:-$1}"
        [[ "${4:-}" == noprec ]] || printf '%s\n\n' "$PREC"
        printf '# Title\n\n%s\n' "$2"
    } >"$dir/SKILL.md"
}

mkdir -p "$scratch/scripts" "$scratch/lib" "$scratch/docs"
echo '#!/usr/bin/env bash' >"$scratch/scripts/real.sh"
printf '#!/usr/bin/env bash\n# Config keys:\n#   baseBranch   required\n#   suites[]{name}\n' >"$scratch/lib/env.sh"
printf 'good\tp1\tdefault\nunreg\tp1\td\nmissing\tp1\td\nmissing\tp2\td\ndup\tp1\td\n' >"$scratch/lib/extension-points.tsv"
printf '### good/p1\n### unreg/p1\n### missing/p1\n### missing/p2\n### dup/p1\n' >"$scratch/docs/extension-points.md"
cat >"$scratch/docs/skills-inventory.md" <<'I'
## good
- [good-01] Rule one.
## norule
- [norule-01] Rule that has no marker.
## unreg
## missing
I

CALL='bash "${CLAUDE_PLUGIN_ROOT}/scripts/real.sh"'
make_skill good "<!-- point: good/p1 -->
Fetch the overlay. $CALL

<!-- rule: good-01 -->
Never skip it. $CALL; config: scripts/config.sh is not mentioned.
Read bash \"\${CLAUDE_PLUGIN_ROOT}/scripts/real.sh\" get .baseBranch .suites[].name" 
# The line above is prose, not a config call; a proper one follows.
printf 'Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/real.sh"`; then config.sh get .baseBranch\n' >>"$scratch/skills/good/SKILL.md"
sed -i '/scripts\/config.sh is not/d; /^Read bash/d' "$scratch/skills/good/SKILL.md"
make_skill wrongdir "x" "other-name"
make_skill noprec "x" "" noprec
make_skill deadcall 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/gone.sh"'
make_skill agentcall 'bash .agentskills/scripts/real.sh'
make_skill unreg '<!-- point: unreg/p9 -->'
make_skill missing '<!-- point: missing/p1 -->'
make_skill dup '<!-- point: dup/p1 -->
<!-- point: dup/p1 -->'
make_skill norule 'No marker here.'
make_skill badkey 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/real.sh" and config.sh get .nosuchkey'

out=$(lint_root "$scratch")

expect() { grep -qF -- "$1" <<<"$out" || { echo "$out" >&2; fail "missing report: $1"; }; }

grep -q 'FAIL good ' <<<"$out" && { echo "$out" >&2; fail "good skill was reported"; }
expect 'FAIL wrongdir check 1 frontmatter: name'
expect 'FAIL noprec check 2 precedence'
expect 'FAIL deadcall check 3 script-calls: scripts/gone.sh does not exist'
expect 'FAIL agentcall check 3 script-calls: other script form: .agentskills'
expect 'FAIL unreg check 4 points: marker unreg/p9'
expect 'FAIL missing check 4 points: registry row missing/p2 has no marker'
expect 'FAIL dup check 4 points: registry row dup/p1 appears 2 times'
expect 'FAIL norule check 5 rules: inventory rule norule-01 has no marker'
expect 'FAIL badkey check 6 config-keys: '"'nosuchkey'"

# The doc half of check 4 is skipped, not failed, while the doc is absent.
rm "$scratch/docs/extension-points.md"
out=$(lint_root "$scratch" good)
expect 'skipped good check 4 points (docs/extension-points.md not written yet)'
grep -q '^FAIL' <<<"$out" && { echo "$out" >&2; fail "good skill failed without the doc"; }

echo "all cases passed"
