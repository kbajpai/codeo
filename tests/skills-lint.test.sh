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

# The retired plugin directory, assembled from parts so the repository-wide guard does not match this file.
old=".agent""skills"

fail() { echo "FAIL: $1" >&2; exit 1; }

PREC='Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.'

# Writes a skill. $1 = name (directory), $2 = body after the precedence sentence,
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
cp "$scratch/scripts/real.sh" "$scratch/scripts/config.sh"
printf '#!/usr/bin/env bash\n# Config keys:\n#   baseBranch   required\n#   suites[]{name,paths[]}\n' >"$scratch/lib/env.sh"
printf 'good\tp1\tdefault\nunreg\tp1\td\nmissing\tp1\td\nmissing\tp2\td\ndup\tp1\td\ninline\tp1\td\ninline\tp2\td\n' >"$scratch/lib/extension-points.tsv"
printf '### good/p1\n### unreg/p1\n### missing/p1\n### missing/p2\n### dup/p1\n### inline/p1\n### inline/p2\n' >"$scratch/docs/extension-points.md"
cat >"$scratch/docs/skills-inventory.md" <<'I'
## good
- [good-01] Rule one.
## norule
- [norule-01] Rule that has no marker.
## extramark
- [extramark-01] Listed rule.
## dblmark
- [dblmark-01] Listed rule.
I

# The good skill exercises every allowed form: both marker kinds, the call form, option and
# quoted, multi-path, piped, defaulted and dynamic config filters.
make_skill good '<!-- point: good/p1 -->
Fetch the overlay. bash "${CLAUDE_PLUGIN_ROOT}/scripts/real.sh"

<!-- rule: good-01 -->
Never skip it.
bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '"'"'.suites[].paths[]'"'"'
bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get -r .baseBranch
bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '"'"'.baseBranch, .suites[].name'"'"'
bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '"'"'.suites[] | select(.name=="qqq") | .paths // "zzz"'"'"'
bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get "$KEY"'
make_skill wrongdir "x" "other-name"
make_skill noprec "x" "" noprec
make_skill deadcall 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/gone.sh"'
make_skill agentcall "bash $old/scripts/real.sh"
make_skill agentprose "The old tooling lived under $old in another project."
make_skill barecall 'Run scripts/real.sh from the root.'
make_skill squote "bash '\${CLAUDE_PLUGIN_ROOT}/scripts/real.sh'"
make_skill nosuffix 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/real"'
make_skill unreg '<!-- point: unreg/p9 -->'
make_skill missing '<!-- point: missing/p1 -->'
make_skill dup '<!-- point: dup/p1 -->
<!-- point: dup/p1 -->'
make_skill inline '<!-- point: inline/p1 --> <!-- point: inline/p1 -->
<!-- point: inline/p2 -->'
make_skill norule 'No marker here.'
make_skill extramark '<!-- rule: extramark-01 -->
<!-- rule: extramark-99 -->'
make_skill dblmark '<!-- rule: dblmark-01 -->
<!-- rule: dblmark-01 -->'
make_skill badkey 'bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .nosuchkey'
make_skill multikey "bash \"\${CLAUDE_PLUGIN_ROOT}/scripts/config.sh\" get '.baseBranch, .zzzsecond.y'"
make_skill pipekey "bash \"\${CLAUDE_PLUGIN_ROOT}/scripts/config.sh\" get '.suites[] | select(.name==\"a\") | .qqqpiped'"

# CRLF frontmatter and a folded description are accepted.
mkdir -p "$scratch/skills/crlf" "$scratch/skills/folded"
printf -- '---\r\nname: crlf\r\ndescription: Fine.\r\nmodel: opus\r\n---\r\n\r\n%s\r\n' "$PREC" >"$scratch/skills/crlf/SKILL.md"
printf -- '---\nname: folded\ndescription: >\n  Folded text\n  on two lines.\nmodel: haiku\n---\n\n%s\n' "$PREC" >"$scratch/skills/folded/SKILL.md"

out=$(lint_root "$scratch")

expect() { grep -qF -- "$1" <<<"$out" || { echo "$out" >&2; fail "missing report: $1"; }; }
refute() { ! grep -qF -- "$1" <<<"$out" || { echo "$out" >&2; fail "unexpected report: $1"; }; }

for ok in good crlf folded; do refute "FAIL $ok "; done
expect 'good check 6 skipped for a dynamic filter: $KEY'
expect 'FAIL wrongdir check 1 frontmatter: name'
expect 'FAIL noprec check 2 precedence'
expect 'FAIL deadcall check 3 script-calls: scripts/gone.sh does not exist'
expect 'FAIL agentcall check 3 script-calls: other script form: '"$old"
expect 'FAIL agentprose check 3 script-calls: other script form: '"$old"
expect 'FAIL barecall check 3 script-calls: other script form: scripts/real.sh'
expect 'FAIL squote check 3 script-calls: other script form: '"'"'${CLAUDE_PLUGIN_ROOT}/scripts/real.sh'"'"
expect 'FAIL nosuffix check 3 script-calls: other script form: ${CLAUDE_PLUGIN_ROOT}/scripts/real'
expect 'FAIL unreg check 4 points: marker unreg/p9'
expect 'FAIL missing check 4 points: registry row missing/p2 has no marker'
expect 'FAIL dup check 4 points: registry row dup/p1 appears 2 times'
expect 'FAIL inline check 4 points: registry row inline/p1 appears 2 times'
refute 'inline/p2'
expect 'FAIL norule check 5 rules: inventory rule norule-01 has no marker'
expect 'FAIL extramark check 5 rules: marker extramark-99 is not in the inventory'
expect 'FAIL dblmark check 5 rules: rule dblmark-01 appears 2 times'
expect 'FAIL badkey check 6 config-keys: '"'nosuchkey'"
expect 'FAIL multikey check 6 config-keys: '"'zzzsecond'"
expect 'FAIL pipekey check 6 config-keys: '"'qqqpiped'"

# A missing registry is a reported failure, not a silent exit.
mv "$scratch/lib/extension-points.tsv" "$scratch/tsv.away"
out=$(lint_root "$scratch" good)
expect 'FAIL good check 4 points: registry lib/extension-points.tsv is missing'
mv "$scratch/tsv.away" "$scratch/lib/extension-points.tsv"

# The doc half of check 4 is skipped, not failed, while the doc is absent.
rm "$scratch/docs/extension-points.md"
out=$(lint_root "$scratch" good)
expect 'skipped good check 4 points (docs/extension-points.md not written yet)'
refute 'FAIL'

echo "all cases passed"
