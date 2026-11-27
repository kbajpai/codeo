#!/usr/bin/env bash
# Guards README.md, docs/updating.md and docs/home-checkout.md as the complete guide:
#   commands         every /codeo:<name> is a directory under skills/
#   paths            every path-shaped word in a backticked span (.codeo/ docs/ scripts/ tests/ hooks/ lib/ skills/ .devcontainer/)
#                    resolves to a file or directory; .codeo/active and .codeo/intake are allowed by name (gitignored).
#                    .codeo/, .codeo/.gitignore, .codeo/config.json and docs/plans/, which these pages name for a
#                    user's project, resolve only because codeo uses itself, so this check cannot catch a path a
#                    new project lacks
#   links            every relative link resolves, and its #anchor is a GitHub slug of a heading in the target
#   slugs            a self-check: repeated headings get -1, -2 as GitHub does (so a link to the second one resolves)
#   config-keys      the Configuration table lists exactly the keys in known_keys below (a hand-kept list: a key the
#                    code starts reading is added there by hand), and each key's last segment (its parent, for name,
#                    paths, build and test) appears somewhere in the code, a weak check ("stacks" only in scripts/setup.sh, "read by nothing")
#   sections         the "##" headings are the thirteen expected ones, in order; Contents links to all the others
#   start-here       Start here links #installing, #setting-a-project-up and #your-first-workflow; its step 6 names
#                    /codeo:close and says "again"
#   walkthrough      Your first workflow has six "###" steps: issue, init, plan, implement, qc, close
#   troubleshooting  the four new entries sit beside the existing doctor entries
#   lock-entry       the stuck-lock entry names both groups: /codeo:init #<N> and "reconcile by hand" (with diverged)
#   setup-steps      Setting a project up has ### 1. 2. 3., Running on the host, then Adopting codeo with containers; no prose line starts with a space
#   adopting-paths   Setting a project up has an "Adopting codeo with containers" section naming scripts/codeo-init.sh and
#                    /codeo:setup --containers and linking docs/container-templates.md
#   troubleshooting-groups
#                    Troubleshooting has three ### groups in order; the doctor group's bold leads are the thirteen
#                    check names; the Installing and the pin group opens with its two entries; the intro says three groups
#   adopting-guard   docs/home-checkout.md has "Adopting the guard in your project" (role-guard, .codeo/overlays/,
#                    /codeo:doctor); the README role-guard entry and docs/extension-points.md link to it
#   adopting-guard-ships  the Adopting the guard section no longer says role.sh "is not shipped" and says
#                    `/codeo:setup --containers` writes it
#   updating         docs/updating.md's Updating superpowers section says restart
#   skill-count      docs/handoff.md has a line starting "Six pipeline skills" (and none "Seven"), docs/skills.md one starting "Six skills form the pipeline"
#   home-checkout    docs/home-checkout.md says what a missing jq and an existing container do
#   host-command     Installing points at the codeo command's section of .devcontainer/README.md; home-checkout.md and
#                    .devcontainer/README.md carry the macOS notes (flock, the keychain over SSH)
#   pipefail-safe    no code line in this file ends a pipeline in grep -q: a producer still writing when grep -q exits
#                    dies of SIGPIPE and pipefail reports a false failure, so it reads grep -q... <(producer) instead
# Headings and backticked tokens inside a ``` fence do not count; commands inside a fence do.
#
#   bash tests/readme.test.sh
#
# Exits 0 and prints "all cases passed" when every check passes; prints one "FAIL <check>: <detail>"
# line per problem and exits 1 otherwise.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo"

export LC_ALL=C

readme=README.md
expected_sections=(Contents "Start here" Requirements Installing "Setting a project up" "Your first workflow"
    Configuration Troubleshooting Updating Uninstalling "The skills" "More documentation" Contributing)
known_keys="schema repo.owner repo.name baseBranch codename plugin.repo plugin.ref suites[].name suites[].paths
suites[].build suites[].test suites[].filter suites[].parallel skipGlobs docsDir plansDir invariants modules
labelTypes stacks board.owner board.gateProject board.projects board.statuses.backlog board.statuses.ready
board.statuses.inProgress board.statuses.inReview board.statuses.done issue.priority triage.parkedDays
resources[].name resources[].paths resources[].parameterised environment.resource environment.hooks.start
environment.hooks.preflight environment.hooks.activate environment.hooks.revoke environment.hooks.deploy
environment.hooks.deployed hooks.onLeaseChange models.subagent models.reviewer ci.requiredChecks"

failed=0
fail() { printf 'FAIL %s: %s\n' "$1" "$2"; failed=1; }

# prose <file>: the file without fenced code blocks, CRLF removed.
prose() { tr -d '\r' <"$1" | awk '/^```/ { f = !f; next } !f'; }

# headings <file> <hashes>: headings of exactly that level outside fences, text only.
headings() { prose "$1" | sed -n "s/^$2 \\(.*\\)\$/\\1/p"; }

# section <file> <title>: the body of the "## <title>" section, outside fences, up to the next "##".
section() {
    prose "$1" | awk -v t="$2" '/^## / { on = ($0 == "## " t); next } on'
}

# slugs <file>: GitHub slugs of every heading of the file outside fences.
slugs() {
    prose "$1" | sed -n 's/^#\{1,6\} \(.*\)$/\1/p' |
        tr 'A-Z' 'a-z' | sed 's/[^a-z0-9 _-]//g; s/ /-/g' |
        awk '{ n = seen[$0]++; print (n ? $0 "-" n : $0) }'
}

# slugs self-check: a repeated heading gets -1, then -2, as on GitHub.
slug_tmp=$(mktemp -d)
printf '# x\n\n## x\n\n## x\n\n## y\n' >"$slug_tmp/h.md"
slug_got=$(slugs "$slug_tmp/h.md" | tr '\n' ' ')
rm -rf "$slug_tmp"
[[ "$slug_got" == "x x-1 x-2 y " ]] || fail slugs "repeated headings give \"$slug_got\", want \"x x-1 x-2 y \""

pages=("$readme" docs/updating.md docs/home-checkout.md docs/container-templates.md)
for p in "${pages[@]:1}"; do [[ -f $p ]] || fail pages "$p is missing"; done
pages=("$readme")
for p in docs/updating.md docs/home-checkout.md docs/container-templates.md; do [[ -f $p ]] && pages+=("$p"); done

# commands: every /codeo:<name> on every page, fences included.
while IFS= read -r name; do
    [[ -d "skills/$name" ]] || fail commands "/codeo:$name has no skills/$name/"
done < <(grep -ho '/codeo:[a-z][a-z-]*' "${pages[@]}" | sed 's|/codeo:||' | sort -u)

# paths: every path-shaped word inside a backticked span resolves, so `bash scripts/x.sh arg` is checked
# as well as a bare path. Two paths the README names for a user's project are not in this repository:
# .codeo/active is the per-checkout lock and .codeo/intake is the intake branch's worktree; both are
# gitignored (.codeo/.gitignore), so they are allowed by name rather than looked up.
runtime_paths=".codeo/active .codeo/intake"
for page in "${pages[@]}"; do
    while IFS= read -r word; do
        word=${word%[.,;:)]}
        [[ "$word" == *'<'* || "$word" == *'*'* || "$word" == *'{'* ]] && continue
        grep -qxF -- "${word%/}" < <(printf '%s\n' $runtime_paths) && continue
        [[ -e "${word%/}" ]] || fail paths "$page: \`$word\` does not exist"
    done < <(prose "$page" | grep -o '`[^`]*`' | tr -d '`' | tr ' ' '\n' |
        grep -E '^(\.codeo/|docs/|scripts/|tests/|hooks/|lib/|skills/|\.devcontainer/)' | sort -u || true)
done

# links: relative links resolve and their anchors match a heading.
for page in "${pages[@]}"; do
    dir=$(dirname "$page")
    while IFS= read -r link; do
        target=${link%%#*}
        anchor=""
        [[ "$link" == *'#'* ]] && anchor=${link#*#}
        case "$link" in http*|mailto:*) continue ;; esac
        if [[ -z "$target" ]]; then
            file=$page
        else
            file="$dir/$target"
            [[ "$dir" == . ]] && file=$target
            if [[ ! -e "$file" ]]; then
                fail links "$page: $link points at a missing file"
                continue
            fi
        fi
        if [[ -n "$anchor" && -f "$file" && "$file" == *.md ]]; then
            grep -qxF -- "$anchor" <(slugs "$file") || fail links "$page: $link has no heading $anchor in $file"
        fi
    done < <(prose "$page" | grep -o ']([^)]*)' | sed 's/^](//; s/)$//' | sort -u || true)
done

# config-keys: the Configuration table against known_keys and against the code.
table_keys=$(section "$readme" Configuration | grep '^|' | sed '1,2d' |
    awk -F'|' '{ k = $2; gsub(/[ `]/, "", k); print k }' || true)
if [[ -z "$table_keys" ]]; then
    fail config-keys "README.md has no Configuration table"
else
    for key in $table_keys; do
        grep -qxF -- "$key" < <(printf '%s\n' $known_keys) || fail config-keys "table key $key is not a key the plugin reads"
    done
    for key in $known_keys; do
        grep -qxF -- "$key" <<<"$table_keys" || fail config-keys "key $key is missing from the table"
    done
    code_dirs=()
    for d in scripts lib hooks skills .devcontainer; do [[ -d $d ]] && code_dirs+=("$d"); done
    for key in $known_keys; do
        if [[ "$key" == stacks ]]; then
            grep -qF stacks scripts/setup.sh || fail config-keys "stacks is not written by scripts/setup.sh"
            grep -qF 'read by nothing' <(section "$readme" Configuration | grep '^| *`stacks`') ||
                fail config-keys "the stacks row is not labelled \"read by nothing\""
            continue
        fi
        # Last dotted segment without "[]"; a generic one stands for its parent key.
        seg=${key##*.}
        seg=${seg//\[\]/}
        if [[ "$seg" == name || "$seg" == paths || "$seg" == build || "$seg" == test ]]; then
            parent=${key%.*}
            seg=${parent##*.}
            seg=${seg//\[\]/}
        fi
        grep -rqF -- "$seg" "${code_dirs[@]}" || fail config-keys "$key: \"$seg\" appears nowhere in the code"
    done
fi

# sections: the "##" headings, in order, and Contents linking to the rest.
actual=$(headings "$readme" '##')
want=$(printf '%s\n' "${expected_sections[@]}")
if [[ "$actual" != "$want" ]]; then
    fail sections "## headings are: $(tr '\n' ',' <<<"$actual"); want: $(tr '\n' ',' <<<"$want")"
fi
contents=$(section "$readme" Contents | grep -o '\[[^]]*\]([^)]*)' | sed 's/^\[\(.*\)\](.*)$/\1/' || true)
for h in "${expected_sections[@]:1}"; do
    grep -qxF -- "$h" <<<"$contents" || fail sections "Contents does not link to \"$h\""
done

# start-here
start=$(section "$readme" "Start here")
for a in installing setting-a-project-up your-first-workflow; do
    grep -qF "](#$a)" <<<"$start" || fail start-here "Start here does not link #$a"
done
step6=$(grep '^6\. ' <<<"$start" || true)
[[ "$step6" == *'/codeo:close'* ]] || fail start-here "step 6 does not name /codeo:close"
[[ "$step6" == *again* ]] || fail start-here "step 6 does not say \"again\""

# walkthrough: six ### steps, in order.
steps=$(section "$readme" "Your first workflow" | sed -n 's/^### \(.*\)$/\1/p')
n=$(grep -c . <<<"$steps" || true)
if [[ "$n" -ne 6 ]]; then
    fail walkthrough "Your first workflow has $n ### headings, want 6"
else
    i=0
    for cmd in issue init plan implement qc close; do
        i=$((i + 1))
        line=$(sed -n "${i}p" <<<"$steps")
        [[ "$line" == *"/codeo:$cmd"* ]] || fail walkthrough "step $i is \"$line\", want one naming /codeo:$cmd"
    done
fi

# troubleshooting: new and existing entries by bold lead words.
trouble=$(section "$readme" Troubleshooting)
for lead in "A role-guard refusal" "A lock that is stuck or not yours" "A step that was interrupted" \
    "A card that is not Ready" config. schema. codename. gh-auth. gh-scopes. \
    board. priority-labels. ruleset. suites. deps. overlays. superpowers. containers.; do
    grep -qF -- "**$lead" <<<"$trouble" || fail troubleshooting "no entry starting **$lead"
done

# entry <text> <lead>: the entry of a section that starts with **<lead>, up to the next bold-led line or ### heading.
entry() {
    awk -v l="**$2" 'index($0, l) == 1 { on = 1; print; next } /^\*\*/ || /^### / { on = 0 } on' <<<"$1"
}

# lock-entry: the stuck-lock entry names both groups.
lock=$(entry "$trouble" "A lock that is stuck or not yours")
if [[ -z "$lock" ]]; then
    fail lock-entry "Troubleshooting has no entry **A lock that is stuck or not yours"
else
    grep -qF '/codeo:init #<N>' <<<"$lock" || fail lock-entry "the lock entry does not contain /codeo:init #<N>"
    grep -qF 'reconcile by hand' <<<"$lock" || fail lock-entry "the lock entry does not contain reconcile by hand"
    grep -qF diverged <(tr '\n' ' ' <<<"$lock" | sed 's/\. /.\n/g' | grep -F 'reconcile by hand') ||
        fail lock-entry "no sentence of the lock entry names both reconcile by hand and diverged"
fi

# subsection <text> <title>: the body of a ### subsection, up to the next ###.
subsection() { awk -v t="### $2" '/^### / { on = ($0 == t); next } on' <<<"$1"; }

# setup-steps: three numbered ### steps, then Running on the host and Adopting codeo with containers; no prose line starts with a space.
setup=$(section "$readme" "Setting a project up")
setup_heads=$(sed -n 's/^### \(.*\)$/\1/p' <<<"$setup")
for i in 1 2 3; do
    [[ "$(sed -n "${i}p" <<<"$setup_heads")" == "$i. "* ]] ||
        fail setup-steps "Setting a project up: ### heading $i does not start \"$i. \""
done
[[ "$(sed -n 4p <<<"$setup_heads")" == "Running on the host" ]] ||
    fail setup-steps "Setting a project up: the ### heading after step 3 is not \"Running on the host\""
[[ "$(sed -n 5p <<<"$setup_heads")" == "Adopting codeo with containers" ]] ||
    fail setup-steps "Setting a project up: the ### heading after Running on the host is not \"Adopting codeo with containers\""
indented=$(grep -c '^ ' <<<"$setup" || true)
[[ "$indented" -eq 0 ]] || fail setup-steps "Setting a project up has $indented prose lines starting with a space"

# adopting-paths: the section names both ways to adopt the containers and links the reference page.
adopting=$(subsection "$setup" "Adopting codeo with containers")
if [[ -z $adopting ]]; then
    fail adopting-paths "Setting a project up has no ### Adopting codeo with containers"
else
    grep -qF 'scripts/codeo-init.sh' <<<"$adopting" || fail adopting-paths "the Adopting section does not name scripts/codeo-init.sh"
    grep -qF '/codeo:setup --containers' <<<"$adopting" || fail adopting-paths "the Adopting section does not name /codeo:setup --containers"
    grep -qF '](docs/container-templates.md' <<<"$adopting" || fail adopting-paths "the Adopting section does not link docs/container-templates.md"
    grep -qiF "is public" <<<"$adopting" || fail adopting-paths "the Adopting section does not say the repository must be public"
    grep -qF "<codename>-home" <<<"$adopting" || fail adopting-paths "the Adopting section does not name the <codename>-home folder"
    grep -qF "CODEO_HOME" <<<"$adopting" || fail adopting-paths "the Adopting section does not name CODEO_HOME"
    grep -qiF 'one `codeo` command serves one project per machine' <<<"$adopting" || fail adopting-paths "the Adopting section does not state the one codeo command per machine condition"
    grep -qF "](.devcontainer/README.md#using-this-in-another-project)" <<<"$adopting" || fail adopting-paths "the Adopting section does not link the project install line in .devcontainer/README.md"
    ! grep -qF "bash scripts/containers.sh" <<<"$adopting" || fail adopting-paths "the Adopting section shows bash scripts/containers.sh, which a project does not have"
fi

# troubleshooting-groups: three ### groups, the doctor group's leads, the pin group's first entries.
t_heads=$(sed -n 's/^### \(.*\)$/\1/p' <<<"$trouble")
[[ "$t_heads" == "During a workflow
Checks from /codeo:doctor
Installing and the pin" ]] ||
    fail troubleshooting-groups "Troubleshooting ### headings are: $(tr '\n' ',' <<<"$t_heads"); want During a workflow, Checks from /codeo:doctor, Installing and the pin"
if ! grep -qxF '### Checks from /codeo:doctor' <<<"$trouble"; then
    fail troubleshooting-groups "Troubleshooting has no ### Checks from /codeo:doctor"
else
    doctor_checks="config schema codename gh-auth gh-scopes board priority-labels ruleset suites deps overlays superpowers containers"
    while IFS= read -r line; do
        lead=$(sed -n 's/^\*\*\([^*]*\)\*\*.*$/\1/p' <<<"$line")
        lead=${lead%.}
        grep -qxF -- "$lead" < <(printf '%s\n' $doctor_checks) ||
            fail troubleshooting-groups "an entry under Checks from /codeo:doctor starts \"${line:0:60}\", not one of the thirteen checks"
    done < <(subsection "$trouble" "Checks from /codeo:doctor" | grep '^\*\*' || true)
    doctor_leads=$(subsection "$trouble" "Checks from /codeo:doctor" | grep '^\*\*' | sed -n 's/^\*\*\([^*]*\)\*\*.*$/\1/p' | sed 's/\.$//' || true)
    for check in $doctor_checks; do
        grep -qxF -- "$check" <<<"$doctor_leads" ||
            fail troubleshooting-groups "the doctor group has no entry $check."
    done
fi
if ! grep -qxF '### Installing and the pin' <<<"$trouble"; then
    fail troubleshooting-groups "Troubleshooting has no ### Installing and the pin"
else
    pin_leads=$(subsection "$trouble" "Installing and the pin" | grep '^\*\*' || true)
    [[ "$(sed -n 1p <<<"$pin_leads")" == "**\`its source doesn't match its extraKnownMarketplaces entry\`.**"* ]] ||
        fail troubleshooting-groups "Installing and the pin does not open with **\`its source doesn't match its extraKnownMarketplaces entry\`.**"
    [[ "$(sed -n 2p <<<"$pin_leads")" == '**A hand-edited `ref` does not take effect.**'* ]] ||
        fail troubleshooting-groups "Installing and the pin's second entry is not **A hand-edited \`ref\` does not take effect.**"
fi
grep -qi 'three groups' <(sed '/^### /,$d' <<<"$trouble") ||
    fail troubleshooting-groups "the Troubleshooting intro does not say three groups"

# adopting-guard: the home-checkout section and the two links to it.
anchor='home-checkout.md#adopting-the-guard-in-your-project)'
grep -qxF '## Adopting the guard in your project' <(prose docs/home-checkout.md) ||
    fail adopting-guard "docs/home-checkout.md has no line \"## Adopting the guard in your project\""
adopt=$(section docs/home-checkout.md "Adopting the guard in your project")
for w in role-guard .codeo/overlays/ /codeo:doctor; do
    grep -qF -- "$w" <<<"$adopt" || fail adopting-guard "the Adopting the guard section does not mention $w"
done
grep -qF "](docs/$anchor" <(entry "$trouble" "A role-guard refusal") ||
    fail adopting-guard "README.md's role-guard entry does not link ](docs/$anchor"
grep -qF "]($anchor" <(prose docs/extension-points.md 2>/dev/null) ||
    fail adopting-guard "docs/extension-points.md does not link ]($anchor"

# adopting-guard-ships: the section says the containers setup writes role.sh, not that it is withheld.
! grep -qF 'is not shipped' <<<"$adopt" ||
    fail adopting-guard-ships "the Adopting the guard section still says role.sh is not shipped"
grep -qF '`/codeo:setup --containers` writes `.devcontainer/scripts/role.sh`' <<<"$adopt" ||
    fail adopting-guard-ships "the Adopting the guard section does not say /codeo:setup --containers writes role.sh"

# updating: the superpowers update says to restart.
grep -qF restart <(section docs/updating.md "Updating superpowers") ||
    fail updating "docs/updating.md's Updating superpowers section does not say restart"

# skill-count: the page ledes say six.
grep -q '^Six pipeline skills' docs/handoff.md ||
    fail skill-count "docs/handoff.md has no line starting \"Six pipeline skills\""
! grep -q '^Seven pipeline skills' docs/handoff.md ||
    fail skill-count "docs/handoff.md still says Seven pipeline skills"
grep -q '^Six skills form the pipeline' docs/skills.md ||
    fail skill-count "docs/skills.md has no line starting \"Six skills form the pipeline\""

# host-command: the codeo command's install pointer and the macOS notes. Each assertion fails on its own.
grep -qF '](.devcontainer/README.md#installing-the-codeo-command)' <(section "$readme" Installing) ||
    fail host-command "Installing does not link .devcontainer/README.md#installing-the-codeo-command"
home=$(prose docs/home-checkout.md)
grep -qF 'brew install flock' <<<"$home" ||
    fail host-command "docs/home-checkout.md does not mention brew install flock"
grep -qF '](../.devcontainer/README.md#the-keychain-over-ssh-on-macos)' <<<"$home" ||
    fail host-command "docs/home-checkout.md does not link ../.devcontainer/README.md#the-keychain-over-ssh-on-macos"
grep -qF 'deps: missing: jq' <<<"$home" ||
    fail home-checkout "docs/home-checkout.md does not say /codeo:doctor reaches deps: missing: jq"
grep -qF 'live.sh` publishes the signal without `jq`' <<<"$home" ||
    fail home-checkout "docs/home-checkout.md does not say live.sh publishes the signal without jq"
grep -qF 'asks about it even with no active row' <<<"$home" ||
    fail home-checkout "docs/home-checkout.md does not say the tracker asks about an existing container even with no active row"
dc=.devcontainer/README.md
grep -qxF '### The keychain over SSH on macOS' "$dc" ||
    fail host-command "$dc has no line \"### The keychain over SSH on macOS\""
grep -qF 'brew install flock' "$dc" ||
    fail host-command "$dc does not mention brew install flock"
grep -qF 'security -v unlock-keychain ~/Library/Keychains/login.keychain-db' "$dc" ||
    fail host-command "$dc does not mention security -v unlock-keychain ~/Library/Keychains/login.keychain-db"
grep -qF 'keychain cannot be accessed because the current session does not allow user interaction' "$dc" ||
    fail host-command "$dc does not quote the keychain-cannot-be-accessed error"

# containers-transcript: the adoption section shows the wizard's init lines inside a code fence.
awk -v t="### Adopting codeo with containers" '/^### / { on = ($0 == t); next } on && /^```/ { f = !f; next } on && f && /^init: ok containers:/ { found = 1 } END { exit !found }' "$readme" ||
    fail containers-transcript "Adopting codeo with containers has no code-fenced line starting init: ok containers:"

# adopting-install-line: the adoption section shows the project's own codeo install line inside a code fence.
awk -v t="### Adopting codeo with containers" '/^### / { on = ($0 == t); next } on && /^```/ { f = !f; next } on && f && /curl -fsSL -o ~\/.local\/bin\/codeo https:\/\/raw.githubusercontent.com\/<owner>\/<repo>\/<base>\/.devcontainer\/codeo && chmod \+x ~\/.local\/bin\/codeo/ { found = 1 } END { exit !found }' "$readme" ||
    fail adopting-install-line "Adopting codeo with containers has no code-fenced project install line for the codeo command"

# adopting-notes: the adoption section names the wizard's `init: note:` lines (the kept-seed and home-checkout notes, and the private-repository note).
sec=$(awk -v t="### Adopting codeo with containers" '/^### / { on = ($0 == t); next } on' "$readme")
for w in '`init: note:`' 'init: note: kept files are yours' 'init: note: the home checkout is a clone whose folder is named' 'init: note: rename or re-clone it as' 'is private;'; do
    [[ $sec == *"$w"* ]] || fail adopting-notes "Adopting codeo with containers does not mention $w"
done

# setup-containers-over-config: docs/skills.md's setup section says --containers works over an existing config.
setup_sec=$(sed -n '/^## setup$/,/^## doctor$/p' docs/skills.md)
[[ $setup_sec == *'`--containers` alone, or with `--codename <name>`, works over an existing config'* ]] ||
    fail setup-containers-over-config "docs/skills.md setup section does not say --containers works over an existing config"

# A pipeline whose consumer is grep -q: grep exits at its first match, a producer still writing is killed
# by SIGPIPE (141), and pipefail fails the whole pipeline although the line was found. The race is lost
# on a slow runner and won on a fast machine, so this reads the source instead of waiting for it to flake.
while IFS=: read -r n text; do
    [[ $text =~ ^[[:space:]]*# ]] && continue
    fail pipefail-safe "${BASH_SOURCE[0]##*/}:$n: a producer still writing when grep -q exits dies of SIGPIPE and pipefail reports a false failure; use grep -q... <(producer) instead"
done < <(grep -nE '[|] *grep -[a-zA-Z]*q' "${BASH_SOURCE[0]}" || true)

if [[ $failed -ne 0 ]]; then
    exit 1
fi
echo "all cases passed"
