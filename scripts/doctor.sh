#!/usr/bin/env bash
# Checks the project is ready to run codeo. Prints one `ok|fail <check>: <detail>` line per check,
# runs every check even after a failure, and exits non-zero if any failed.
#
#   doctor.sh
#
# Checks: config, schema, codename, gh-auth, gh-scopes, board, ruleset, suites, deps, overlays, superpowers.
# Every GitHub read is `gh api` except the board check's `gh project view`, which is GraphQL-backed; nothing uses the
# GraphQL-backed `gh issue|pr|run`.
# The ruleset check reads the effective rules for the base branch from
# `gh api repos/<owner>/<repo>/rules/branches/<base>`, which covers rulesets and branch
# protection alike, and compares required_status_checks contexts with ci.requiredChecks
# (default: tests, qc-verdict).
set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

failed=0
report() { # status check detail
    printf '%s %s: %s\n' "$1" "$2" "$3"
    [[ "$1" == ok ]] || failed=1
}

# Probe the config in a subshell: codeo_die exits, and doctor must carry on past it.
config_msg=$("$CODEO_PLUGIN_ROOT/scripts/config.sh" validate 2>&1) && config_ok=1 || config_ok=0
if [[ $config_ok -eq 1 ]]; then
    report ok config "config.json is valid"
    report ok schema "supported (plugin understands up to $CODEO_SCHEMA)"
else
    report fail config "${config_msg#codeo: }"
    # A newer schema is a separate fact from an unreadable file; say so under its own check.
    schema=$(jq -r '.schema // empty' "$CODEO_STATE_DIR/config.json" 2>/dev/null || true)
    if [[ "$schema" =~ ^[0-9]+$ ]] && ((schema > CODEO_SCHEMA)); then
        report fail schema "$schema is newer than this plugin supports ($CODEO_SCHEMA)"
    elif [[ "$schema" =~ ^[0-9]+$ ]]; then
        report ok schema "supported (plugin understands up to $CODEO_SCHEMA)"
    else
        report fail schema "no usable schema value"
    fi
fi

cfg() { jq -r "$1" "$CODEO_STATE_DIR/config.json" 2>/dev/null; }

# codename: the project's own key, used by projects that derive their tooling names from it. Absent is
# fine (codeo itself does not need one); present, it must be a string of lower-case letters and digits
# with single hyphens between them, starting with a letter, 2 to 30 characters.
if [[ $config_ok -eq 0 ]]; then
    report fail codename "skipped: config is unusable"
elif [[ $(cfg 'has("codename")') != true ]]; then
    report ok codename "not set"
elif [[ $(cfg '.codename | type') != string ]]; then
    report fail codename "must be a string, found $(cfg '.codename | type')"
else
    codename=$(cfg '.codename')
    if [[ $codename =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ && ${#codename} -ge 2 && ${#codename} -le 30 ]]; then
        report ok codename "$codename"
    else
        report fail codename "\"$codename\" is not valid: lower-case letters, digits and single hyphens between them, starting with a letter, 2-30 characters"
    fi
fi

# gh-auth and gh-scopes share one call: -i keeps the response headers, which carry the scopes.
if ! command -v gh >/dev/null 2>&1; then
    report fail gh-auth "gh is not installed"
    response=""
elif response=$(gh api -i user 2>&1); then
    report ok gh-auth "gh api user succeeded"
else
    report fail gh-auth "gh api user failed: $(printf '%s' "$response" | head -n 1)"
    response=""
fi

board_owner="" projects=""
if [[ $config_ok -eq 1 ]]; then
    board_owner=$(cfg '.board.owner // empty')
    projects=$(cfg '.board.projects[]?')
fi
has_board=0
[[ -n "$board_owner" || -n "$projects" ]] && has_board=1

if [[ $config_ok -eq 0 ]]; then
    # An unusable config says nothing about the board, so "no board configured" would be a false ok.
    report fail gh-scopes "skipped: config is unusable"
elif [[ $has_board -eq 0 ]]; then
    report ok gh-scopes "no board configured; the project scope is not needed"
elif [[ -z "$response" ]]; then
    report fail gh-scopes "cannot read scopes without a working gh login"
else
    scopes=$(printf '%s\n' "$response" | tr -d '\r' | grep -i '^x-oauth-scopes:' | head -n 1 | cut -d: -f2- || true)
    if ! printf '%s\n' "$response" | grep -qi '^x-oauth-scopes:'; then
        # Fine-grained PATs and App/Actions tokens send no scopes header; the board check decides.
        report ok gh-scopes "cannot verify scopes for this token type; the board check decides"
    elif [[ ",$(printf '%s' "$scopes" | tr -d ' ')," == *,project,* ]]; then
        report ok gh-scopes "the project scope is granted"
    else
        report fail gh-scopes "the token lacks the project scope; run 'gh auth refresh -s project'"
    fi
fi

if [[ $config_ok -eq 0 ]]; then
    report fail board "skipped: config is unusable"
elif [[ $has_board -eq 0 ]]; then
    report ok board "no board configured"
elif ! command -v gh >/dev/null 2>&1; then
    report fail board "gh is not installed"
else
    bad=()
    while IFS= read -r p; do
        [[ -n "$p" ]] || continue
        gh project view "$p" --owner "$board_owner" --format json >/dev/null 2>&1 || bad+=("$p")
    done <<<"$projects"
    if [[ ${#bad[@]} -eq 0 ]]; then
        report ok board "every configured project is readable"
    else
        report fail board "not readable: ${bad[*]}"
    fi
fi

if [[ $config_ok -eq 0 && "$(cfg .baseBranch)" == TODO-set-me ]]; then
    report fail ruleset "skipped: baseBranch is not set"
elif [[ $config_ok -eq 0 ]]; then
    report fail ruleset "skipped: config is unusable"
elif ! command -v gh >/dev/null 2>&1; then
    report fail ruleset "gh is not installed"
else
    repo="$(cfg .repo.owner)/$(cfg .repo.name)"
    base=$(cfg .baseBranch)
    required=$(cfg '.ci.requiredChecks[]?')
    [[ -n "$required" ]] || required=$'tests\nqc-verdict'
    # A base branch such as release/1.x holds a "/" that would split the URL path.
    base_enc=$(jq -rn --arg b "$base" '$b | @uri')
    if rules=$(gh api "repos/$repo/rules/branches/$base_enc" 2>&1); then
        have=$(printf '%s' "$rules" | jq -r '.[] | select(.type == "required_status_checks") | .parameters.required_status_checks[].context' 2>/dev/null || true)
        missing=()
        while IFS= read -r c; do
            grep -Fxq -- "$c" <<<"$have" || missing+=("$c")
        done <<<"$required"
        if [[ ${#missing[@]} -eq 0 ]]; then
            report ok ruleset "$base requires: $(tr '\n' ' ' <<<"$required" | sed 's/ $//')"
        else
            report fail ruleset "$base does not require: ${missing[*]}"
        fi
    else
        report fail ruleset "could not read rules for $repo@$base: $(printf '%s' "$rules" | head -n 1)"
    fi
fi

if [[ $config_ok -eq 0 ]]; then
    report fail suites "skipped: config is unusable"
else
    missing=()
    count=0
    # A unit separator, not a tab: tab is IFS whitespace, so read would collapse an empty build
    # field and shift the test command into its place.
    while IFS=$'\x1f' read -r sname build test; do
        [[ -n "$sname" ]] || continue
        count=$((count + 1))
        for cmd in "$build" "$test"; do
            word=${cmd%% *}
            if [[ -z "$word" ]]; then
                missing+=("$sname:(no command)")
            elif ! command -v "$word" >/dev/null 2>&1; then
                missing+=("$sname:$word")
            fi
        done
    done < <(jq -r '.suites[]? | [.name, (.build // ""), (.test // "")] | join("\u001f")' "$CODEO_STATE_DIR/config.json")
    if [[ ${#missing[@]} -eq 0 ]]; then
        report ok suites "$count suite(s), every build and test command resolves"
    else
        report fail suites "not installed or unset: ${missing[*]}"
    fi
fi

missing=()
for tool in jq git; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
# scope.sh uses `local -n` (namerefs), which arrived in bash 4.3. Parsed from BASH_VERSION so a test
# can stand in an older version; BASH_VERSINFO is read-only.
bash_ver=${BASH_VERSION%%[!0-9.]*}
bash_major=${bash_ver%%.*}
bash_rest=${bash_ver#*.}
bash_minor=${bash_rest%%.*}
((bash_major > 4 || (bash_major == 4 && bash_minor >= 3))) || missing+=("bash>=4.3 (have $BASH_VERSION)")
if [[ ${#missing[@]} -eq 0 ]]; then
    report ok deps "jq, git, bash $BASH_VERSION"
else
    report fail deps "missing: ${missing[*]}"
fi

# overlays: every "## <name>" in $CODEO_STATE_DIR/overlays/<skill>.md must be a registered
# <skill>/<name>, else overlay.sh would never fetch it and the section would be dead text. Offenders
# are joined on one line so the check stays one line of output. CODEO_EXTENSION_POINTS is tests only.
registry=${CODEO_EXTENSION_POINTS:-$CODEO_PLUGIN_ROOT/lib/extension-points.tsv}
overlay_dir="$CODEO_STATE_DIR/overlays"
if [[ ! -d "$overlay_dir" ]]; then
    report ok overlays "none"
elif [[ ! -r "$registry" ]]; then
    report fail overlays "extension-point registry not readable: $registry"
else
    bad=() sections=0 files=0
    for f in "$overlay_dir"/*.md; do
        [[ -f "$f" ]] || continue
        files=$((files + 1))
        skill=$(basename "$f" .md)
        known=$(awk -F'\t' -v s="$skill" '$1 == s { print $2 }' "$registry" | paste -sd, - | sed 's/,/, /g')
        if [[ -z "$known" ]]; then
            bad+=("$(basename "$f"): no extension points for skill $skill")
            continue
        fi
        # A heading is normalised exactly as overlay.sh does it (CR stripped, trailing blanks trimmed,
        # "## " prefix of three characters) so a section overlay.sh can fetch is never reported as
        # dead here; keep the two in step.
        names=$(awk '{ sub(/\r$/, ""); if (substr($0, 1, 3) == "## ") { h = $0; sub(/[ \t]+$/, "", h); print substr(h, 4) } }' "$f")
        [[ -n "$names" ]] || continue
        dups=$(sort <<<"$names" | uniq -d)
        while IFS= read -r name; do
            [[ -n "$name" ]] || continue
            bad+=("$(basename "$f"): duplicate section ## $name")
        done <<<"$dups"
        while IFS= read -r name; do
            sections=$((sections + 1))
            [[ ",$(sed 's/, /,/g' <<<"$known")," == *",$name,"* ]] && continue
            hint=""
            [[ "$name" == " "* ]] && hint="; a heading is exactly '## <point>' with one space"
            bad+=("$(basename "$f"): ## $name is not an extension point of $skill (known: $known$hint)")
        done <<<"$names"
    done
    if [[ ${#bad[@]} -eq 0 ]]; then
        report ok overlays "$sections section(s) in $files file(s)"
    else
        joined=$(printf '%s; ' "${bad[@]}")
        report fail overlays "${joined%; }"
    fi
fi

# superpowers: plan and implement call its skills. The source of truth is the installed-plugins file
# the claude CLI keeps; claude itself is never run (slow, may prompt). CODEO_PLUGINS_FILE overrides
# the path and exists for the tests only. A file we cannot read or parse is "cannot verify", never a fail.
plugins_file=${CODEO_PLUGINS_FILE:-$HOME/.claude/plugins/installed_plugins.json}
if [[ -r "$plugins_file" ]] && jq -e '.plugins | type == "object"' "$plugins_file" >/dev/null 2>&1; then
    if jq -e '.plugins | keys | any(startswith("superpowers@"))' "$plugins_file" >/dev/null 2>&1; then
        report ok superpowers "installed"
    else
        report fail superpowers "not installed; install it with: claude plugin install superpowers@superpowers-marketplace"
    fi
else
    report ok superpowers "cannot verify"
fi

exit "$failed"
