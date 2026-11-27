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
grep -qF '`leftover`' "$skill" || check_fail "step 1 does not name the leftover lines"
grep -qF 'a second line, `leftover`' "$skill" || check_fail "step 1 does not say a proven issue can print two lines"
grep -qF 'a second line, `leftover`' "$repo/scripts/cleanup.sh" || check_fail "the script header does not say a proven issue can print two lines"
grep -qF 'git push origin --delete' "$skill" || check_fail "step 1 does not show the leftover command as printed"
grep -qF 'only when `name` is the proof that failed' "$skill" || check_fail "rule cleanup-02 does not say a name failure still gets the leftover line"
grep -qF 'or an issue whose only failed proof is `name`' "$skill" || check_fail "step 1 does not say which issues get a leftover line"
grep -qF 'an issue that fails a proof is listed with it and no container command' "$repo/docs/skills.md" || check_fail "docs/skills.md cleanup purpose still says a failed proof gets no command at all"
grep -qF '/codeo:init #<M>' "$skill" || check_fail "the closing block does not name /codeo:init #<M>"
! grep -qF '/codeo:init #<N>' "$skill" || check_fail "the closing block still names /codeo:init #<N>"
row=$(grep -F '| `cleanup` |' "$repo/docs/handoff.md")
[[ $row == *'#<M>'* && $row != *'#<N>'* ]] || check_fail "the handoff cleanup row does not name /codeo:init #<M>: $row"
! grep -qiw 'docker' "$skill" || check_fail "the skill names the container engine"
! grep -qF 'codeo-home' "$skill" || check_fail "the skill names the home container"
step4=$(awk '/^4\. \*\*Close/{f=1; next} /^## /{f=0} f' "$skill")
grep -qF 'or a `leftover` line was printed' <<<"$step4" || check_fail "step 4 does not send a leftover-only run to the printed commands"
grep -qF '/codeo:triage' <<<"$step4" || check_fail "step 4 no longer names /codeo:triage"
grep -qF 'while origin still holds a validly named' <<<"$step4" || check_fail "step 4 does not say a failed-name issue gets a leftover line only while origin holds a validly named branch"

# Recording removals: the skill runs the record command, relays the note, and never removes or runs anything itself.
grep -qF 'cleanup.sh" record' "$skill" || check_fail "the skill does not run cleanup.sh record"
grep -qF 'removed/' "$skill" || check_fail "the skill does not name removed/"
! grep -qF 'rm -f' "$skill" || check_fail "the skill names rm -f"
step1=$(awk '/^1\. \*\*Run the script/{f=1; next} /^2\. /{f=0} f' "$skill")
grep -qF 'cleanup: note:' <<<"$step1" || check_fail "step 1 does not relay the cleanup: note: line"
step3=$(awk '/^3\. \*\*Record/{f=1; next} /^4\. /{f=0} f' "$skill")
for needle in 'record <N>' "the engineer's statement" 'intake.sh" commit cleanup'; do
    grep -qF -- "$needle" <<<"$step3" || check_fail "step 3 does not contain: $needle"
done

# Generic text names no container, and the list's reach is stated.
! grep -qF 'Home-container' "$skill" || check_fail "the skill still says Home-container"
! grep -qF 'home container' "$skill" || check_fail "the skill still says home container"
step2=$(awk '/^2\. \*\*Say what the proof cannot see/{f=1; next} /^3\. /{f=0} f' "$skill")
grep -qF 'every issue under `.codeo/done/`' <<<"$step2" || check_fail "step 2 does not state the list's reach"
grep -qF 'until their removals are recorded' <<<"$step2" || check_fail "step 2 does not say the list holds an issue until its removal is recorded"
docs="$repo/docs/skills.md"
section=$(awk '/^## cleanup$/{f=1; next} /^## /{f=0} f' "$docs")
grep -qF 'every issue under `.codeo/done/`' <<<"$section" || check_fail "docs/skills.md cleanup section does not state the list's reach"
grep -qF 'cleanup.sh record' <<<"$section" || check_fail "docs/skills.md cleanup section does not name cleanup.sh record"
grep -qF 'records that so the next run' "$repo/README.md" || check_fail "README.md does not say cleanup records the removal so the next run omits it"
! grep -qF 'in the home container, and only prints' "$docs" || check_fail "docs/skills.md still says cleanup runs in the home container"
! grep -qF 'runs in the home container only' "$docs" || check_fail "docs/skills.md still says cleanup runs in the home container only"

# The overlay's removal-command body, fed to cleanup.sh over a scratch origin with a stubbed gh.
body=$(awk '/^## removal-command$/{f=1; next} /^## /{f=0} f && NF' "$repo/.codeo/overlays/cleanup.md")
[[ -n $body ]] || check_fail "the overlay has no removal-command body"
grep -qxF 'command: codeo rm {N}' <<<"$body" || check_fail "the overlay's command line is not: codeo rm {N}"
grep -qE '^fallback: .*docker rm -f \{name\}' "$repo/.codeo/overlays/cleanup.md" || check_fail "the cleanup overlay has no docker fallback line"
! grep -qi powershell "$repo/.codeo/overlays/cleanup.md" || check_fail "the cleanup overlay names PowerShell"
grep -qF '`fallback:`' "$skill" || check_fail "the skill text does not name the fallback line"

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
[[ $out != *'{'* && $out != *'}'* ]] || check_fail "the overlay's printed line holds a brace"
tbody=$(awk '/^## removal-command$/{f=1; next} /^## /{f=0} f && NF' "$repo/templates/containers/.codeo/overlays/cleanup.md")
tout=$(run "${tbody//@CODENAME@/codeo}")
[[ $tout == *$'\tproven\t'* ]] || check_fail "the template overlay's run did not print a proven line: $tout"
[[ $tout != *'{'* && $tout != *'}'* ]] || check_fail "the template overlay's printed line holds a brace"
[[ $out == $'70\tproven\tcodeo rm 70\t'* ]] || check_fail "the overlay does not accept codeo-70: $out"
fb=${out#$'70\tproven\tcodeo rm 70\t'}
[[ $fb == *'docker rm -f codeo-70'* && $fb == *'docker volume rm codeo-70'* && $fb == *'codeo-track.sh mark 70 container codeo-70 removed'* && $fb == *'unpushed'* && $fb != *'{'* ]] || check_fail "the overlay's fallback does not expand: $fb"
for needle in 'docker rmi codeo-dev:codeo-70' 'codeo-sandbox.sh end 70' 'docker rm does not end a sandbox' 'on the host that created the container' 'not inside a container' 'mark 70 image codeo-dev:codeo-70 removed'; do
    [[ $fb == *"$needle"* ]] || check_fail "the overlay's fallback lacks: $needle"
done

# The by-hand fallback: git status before any docker command, the sandbox script's own marking, marks after removal.
fbline=$(grep -E '^fallback: ' "$repo/.codeo/overlays/cleanup.md")
[[ ${fbline%%docker rm -f*} == *'git status'* ]] || check_fail "the overlay's fallback does not put git status before the first docker rm -f"
for needle in 'from the folder that holds the script' 'else codeo-track.sh sits beside' 'CODEO_TRACK names it' 'records nothing' 'once the removal succeeds'; do
    [[ $fbline == *"$needle"* ]] || check_fail "the overlay's fallback line lacks: $needle"
done

# Wording pins: a commit never deletes, record does not restore, the undo is by hand.
step3=$(awk '/^3\. \*\*Record what was printed/{f=1} /^4\. \*\*Close/{f=0} f' "$skill")
p1=$(printf '%s\n' "$step3" | awk 'NR>1 && /^$/{exit} {print}')
p2=$(printf '%s\n' "$step3" | awk '/Record a removal the engineer says/{f=1} f&&/^$/{exit} f')
[[ $p1 != *'Nothing else is written.' ]] || check_fail "step 3's first paragraph still ends Nothing else is written."
[[ $p2 == *'Nothing else is written outside the run record and the removal records.' ]] || check_fail "step 3's record paragraph lacks its closing sentence"
[[ $(<"$skill") != *"restores origin's"* ]] || check_fail "the skill still says record restores origin's records"
[[ $(<"$skill") == *'right after its own, or alone when its removal is recorded'* ]] || check_fail "step 1's leftover sentence lacks the recorded case"
reads=$(grep -E '^- \*\*Reads\*\*' -A1 "$skill")
[[ $reads == *'on `origin/codeo/intake`'* ]] || check_fail "the Hand-off Reads does not name codeo/intake"
cs=$(awk '/^## cleanup$/{f=1;next} /^## /{f=0} f' "$repo/docs/skills.md")
[[ $cs != *"restores origin's records first"* ]] || check_fail "docs/skills.md cleanup still says record restores origin's records first"
[[ $cs == *'adds it back'* ]] || check_fail "docs/skills.md cleanup does not say a clone adds it back"
[[ $(<"$repo/README.md") == *'still listed'* ]] || check_fail "README.md does not say the issue is still listed"

[[ $fail -eq 0 ]] || exit 1
echo "all cases passed"
