#!/usr/bin/env bash
# Pins /codeo:cleanup: the skill names its script, its warnings and its record; it never names the
# container engine; and this repository's removal-command overlay, run through scripts/cleanup.sh's
# name check, refuses the shared containers' names and accepts an issue's.
#
#   bash tests/cleanup-skill.test.sh
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
skill="$repo/skills/cleanup/SKILL.md"
fail=0
check_fail() { printf 'FAIL %s\n' "$1"; fail=1; }

text=$(cat "$skill") || exit 1
for needle in 'cleanup.sh' 'git status' 'unpushed work' 'intake.sh" commit cleanup'; do
    grep -qF -- "$needle" <<<"$text" || check_fail "the skill does not contain: $needle"
done
grep -qF 'the lock lives only in that clone' "$skill" || check_fail "the skill does not say where the lock lives"
grep -qF 'any branch other than `codeo/intake`' "$skill" || check_fail "the hand-off does not name the intake branch exception"
! grep -qF 'recorded a clean tree' "$skill" || check_fail "the skill still claims close.md recorded a clean tree"
grep -qF '`issue`, `pull-request`, `branch`, `dossier`, `lease` or `name`' "$skill" || check_fail "step 1 does not list the five proofs"
grep -qF '/codeo:init #<M>' "$skill" || check_fail "the closing block does not name /codeo:init #<M>"
! grep -qF '/codeo:init #<N>' "$skill" || check_fail "the closing block still names /codeo:init #<N>"
row=$(grep -F '| `cleanup` |' "$repo/docs/handoff.md")
[[ $row == *'#<M>'* && $row != *'#<N>'* ]] || check_fail "the handoff cleanup row does not name /codeo:init #<M>: $row"
! grep -qiw 'docker' "$skill" || check_fail "the skill names the container engine"
! grep -qF 'codeo-home' "$skill" || check_fail "the skill names the home container"

# Generic text names no container, and the list's reach is stated.
! grep -qF 'Home-container' "$skill" || check_fail "the skill still says Home-container"
! grep -qF 'home container' "$skill" || check_fail "the skill still says home container"
step2=$(awk '/^2\. \*\*Say what the proof cannot see/{f=1; next} /^3\. /{f=0} f' "$skill")
grep -qF 'every issue under `.codeo/done/`' <<<"$step2" || check_fail "step 2 does not state the list's reach"
docs="$repo/docs/skills.md"
section=$(awk '/^## cleanup$/{f=1; next} /^## /{f=0} f' "$docs")
grep -qF 'every issue under `.codeo/done/`' <<<"$section" || check_fail "docs/skills.md cleanup section does not state the list's reach"
! grep -qF 'in the home container, and only prints' "$docs" || check_fail "docs/skills.md still says cleanup runs in the home container"
! grep -qF 'runs in the home container only' "$docs" || check_fail "docs/skills.md still says cleanup runs in the home container only"

# The overlay's removal-command body, fed to cleanup.sh over a scratch origin with a stubbed gh.
body=$(awk '/^## removal-command$/{f=1; next} /^## /{f=0} f && NF' "$repo/.codeo/overlays/cleanup.md")
[[ -n $body ]] || check_fail "the overlay has no removal-command body"

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch/home" GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
mkdir -p "$HOME" "$scratch/bin" "$scratch/canned"
cat >"$scratch/bin/gh" <<'STUB'
#!/usr/bin/env bash
[[ ${1:-} == api ]] || exit 1
shift
path= filter=
while (($#)); do
    case $1 in -q) filter=$2; shift 2 ;; -X | -f | -F) shift 2 ;; -*) shift ;; *) path=$1; shift ;; esac
done
file="$GH_STUB_DIR/GET_${path//\//_}.json"
[[ -f $file ]] || exit 1
if [[ -n $filter ]]; then jq -r -c "$filter" "$file"; else cat "$file"; fi
STUB
chmod +x "$scratch/bin/gh"
export GH_STUB_DIR="$scratch/canned"

git init -q --bare -b main "$scratch/origin"
git clone -q "$scratch/origin" "$scratch/work" 2>/dev/null
git -C "$scratch/work" checkout -q -b main
echo x >"$scratch/work/README.md"
mkdir -p "$scratch/work/.codeo/done/70"
printf '#41 https://github.com/o/n/pull/41\n' >"$scratch/work/.codeo/done/70/close.md"
git -C "$scratch/work" add -A
git -C "$scratch/work" commit -q -m init
git -C "$scratch/work" push -q origin main
printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}\n' >"$scratch/work/.codeo/config.json"
printf '{"number":70,"state":"closed","labels":[],"assignees":[]}' >"$GH_STUB_DIR/GET_repos_o_n_issues_70.json"
printf '{"state":"closed","merged_at":"2026-01-01T00:00:00Z","head":{"ref":"feat/70"}}' >"$GH_STUB_DIR/GET_repos_o_n_pulls_41.json"

run() {
    mkdir -p "$scratch/work/.codeo/overlays"
    printf '## removal-command\n%s\n' "$1" >"$scratch/work/.codeo/overlays/cleanup.md"
    (cd "$scratch/work" && PATH="$scratch/bin:$PATH" bash "$repo/scripts/cleanup.sh" 2>&1) || true
}

for bad in codeo-home codeo-gh codeo-git codeo-; do
    out=$(run "${body//codeo-\{N\}/$bad}")
    [[ $out == $'70\tfailed\tname' ]] || check_fail "the overlay's pattern does not reject $bad: $out"
done
out=$(run "$body")
[[ $out == $'70\tproven\t'* && $out == *codeo-70* ]] || check_fail "the overlay does not accept codeo-70: $out"

[[ $fail -eq 0 ]] || exit 1
echo "all cases passed"
