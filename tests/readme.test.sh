#!/usr/bin/env bash
# Guards README.md, docs/updating.md and docs/home-checkout.md as the complete guide:
#   commands         every /codeo:<name> is a directory under skills/
#   paths            every path-shaped word in a backticked span (.codeo/ docs/ scripts/ tests/ hooks/ lib/ skills/ .devcontainer/)
#                    resolves to a file or directory; .codeo/active and .codeo/intake are allowed by name (gitignored)
#   links            every relative link resolves, and its #anchor is a GitHub slug of a heading in the target
#   config-keys      the Configuration table lists exactly the keys in known_keys below (a hand-kept list: a key the
#                    code starts reading is added there by hand), and each key's last segment (its parent, for name,
#                    paths, build and test) appears somewhere in the code, a weak check ("stacks" only in scripts/setup.sh, "read by nothing")
#   sections         the "##" headings are the thirteen expected ones, in order; Contents links to all the others
#   start-here       Start here links #installing, #setting-a-project-up and #your-first-workflow
#   walkthrough      Your first workflow has six "###" steps: issue, init, plan, implement, qc, close
#   troubleshooting  the four new entries sit beside the existing doctor entries
#   home-checkout    docs/home-checkout.md says what a missing jq and an existing container do
#   host-command     Installing points at the codeo command's section of .devcontainer/README.md; home-checkout.md and
#                    .devcontainer/README.md carry the macOS notes (flock, the keychain over SSH)
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
        tr 'A-Z' 'a-z' | sed 's/[^a-z0-9 _-]//g; s/ /-/g'
}

pages=("$readme" docs/updating.md docs/home-checkout.md)
for p in "${pages[@]:1}"; do [[ -f $p ]] || fail pages "$p is missing"; done
pages=("$readme")
for p in docs/updating.md docs/home-checkout.md; do [[ -f $p ]] && pages+=("$p"); done

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
            slugs "$file" | grep -qxF -- "$anchor" || fail links "$page: $link has no heading $anchor in $file"
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
            section "$readme" Configuration | grep '^| *`stacks`' | grep -qF 'read by nothing' ||
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
    board. priority-labels. ruleset. suites. deps. overlays. superpowers.; do
    grep -qF -- "**$lead" <<<"$trouble" || fail troubleshooting "no entry starting **$lead"
done

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

if [[ $failed -ne 0 ]]; then
    exit 1
fi
echo "all cases passed"
