#!/usr/bin/env bash
# Pins the role guard: each skill that needs one declares the role-guard point, calls it once and
# carries a rule saying a refusal has no override; this repository's overlay for it runs the role
# check and stops on a refusal. doctor and setup run anywhere and must declare nothing.
#
#   bash tests/role-guard.test.sh
#
# Prints one "FAIL <detail>" line per problem and exits 1; prints "all cases passed" otherwise.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# The skills that carry the guard. Adding one is a one-word edit here.
guarded=(issue init triage plan implement qc close cleanup)
unguarded=(doctor setup)

# check_guarded <root> <skill>: prints FAIL lines; always returns 0.
check_guarded() {
    local root=$1 skill=$2 file="$1/skills/$2/SKILL.md" text rc=0 n
    if ! awk -F'\t' -v s="$skill" '$1==s && $2=="role-guard"{f=1} END{exit !f}' "$root/lib/extension-points.tsv"; then
        printf 'FAIL %s: no role-guard row in lib/extension-points.tsv\n' "$skill"
    fi
    n=$(grep -oF "<!-- point: $skill/role-guard -->" "$file" | wc -l)
    [[ "$n" -eq 1 ]] || printf 'FAIL %s: the point marker appears %s times, expected once\n' "$skill" "$n"
    if ! grep -qE "<!-- rule: $skill-[0-9]+ -->" "$file" ||
        ! grep -A3 -E '<!-- rule: '"$skill"'-[0-9]+ -->' "$file" | grep -q 'The engineer.s words do not lift it'; then
        printf 'FAIL %s: no rule marker whose paragraph says there is no override\n' "$skill"
    fi
    grep -q "overlay.sh\" $skill role-guard" "$file" ||
        printf 'FAIL %s: the skill does not fetch its role-guard point\n' "$skill"
    text=$(cd "$root" && bash scripts/overlay.sh "$skill" role-guard 2>&1) || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        printf 'FAIL %s: overlay.sh %s role-guard exited %s\n' "$skill" "$skill" "$rc"
        return 0
    fi
    grep -qF "role.sh --check $skill" <<<"$text" ||
        printf 'FAIL %s: the overlay text does not run role.sh --check %s\n' "$skill" "$skill"
    grep -qF 'Any other exit (the script is missing, or failed): report what it printed and go on.' <<<"$text" ||
        printf 'FAIL %s: the overlay text does not say what to do on any other exit\n' "$skill"
    grep -qw 'stop' <<<"$text" ||
        printf 'FAIL %s: the overlay text does not stop on a refusal\n' "$skill"
    return 0
}

# check_unguarded <root> <skill>
check_unguarded() {
    local root=$1 skill=$2
    ! awk -F'\t' -v s="$skill" '$1==s && $2=="role-guard"{f=1} END{exit !f}' "$root/lib/extension-points.tsv" ||
        printf 'FAIL %s: has a role-guard row but runs anywhere\n' "$skill"
    ! grep -qF "role-guard" "$root/skills/$skill/SKILL.md" ||
        printf 'FAIL %s: mentions role-guard but runs anywhere\n' "$skill"
    return 0
}

out=""
for s in "${guarded[@]}"; do out+=$(check_guarded "$repo" "$s")$'\n'; done
for s in "${unguarded[@]}"; do out+=$(check_unguarded "$repo" "$s")$'\n'; done

# The test sees its own failure: a copy of issue's skill without the marker is reported.
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/skills/issue" "$scratch/lib"
cp "$repo/lib/extension-points.tsv" "$scratch/lib/"
grep -vF '<!-- point: issue/role-guard -->' "$repo/skills/issue/SKILL.md" >"$scratch/skills/issue/SKILL.md"
reported=$(check_guarded "$scratch" issue 2>/dev/null)
if ! grep -q 'the point marker appears 0 times' <<<"$reported"; then
    out+="FAIL self-check: a skill without its marker is not reported"$'\n'
fi

out=$(sed '/^$/d' <<<"$out")
if [[ -n "$out" ]]; then
    echo "$out"
    exit 1
fi
echo "all cases passed"
