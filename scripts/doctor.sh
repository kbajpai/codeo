#!/usr/bin/env bash
# Checks the project is ready to run codeo. Prints one `ok|fail <check>: <detail>` line per check,
# runs every check even after a failure, and exits non-zero if any failed.
#
#   doctor.sh
#
# Checks: config, schema, gh-auth, gh-scopes, board, ruleset, suites, deps. Every GitHub read is
# REST (`gh api`, `gh project view`); nothing uses the GraphQL-backed `gh issue|pr|run`.
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

if [[ $has_board -eq 0 ]]; then
    report ok gh-scopes "no board configured; the project scope is not needed"
elif [[ -z "$response" ]]; then
    report fail gh-scopes "cannot read scopes without a working gh login"
else
    scopes=$(printf '%s\n' "$response" | tr -d '\r' | grep -i '^x-oauth-scopes:' | head -n 1 | cut -d: -f2- || true)
    if [[ ",$(printf '%s' "$scopes" | tr -d ' ')," == *,project,* ]]; then
        report ok gh-scopes "the project scope is granted"
    else
        report fail gh-scopes "the token lacks the project scope; run 'gh auth refresh -s project'"
    fi
fi

if [[ $has_board -eq 0 ]]; then
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
    if rules=$(gh api "repos/$repo/rules/branches/$base" 2>&1); then
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
    while IFS=$'\t' read -r sname build test; do
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
    done < <(jq -r '.suites[]? | [.name, (.build // ""), (.test // "")] | @tsv' "$CODEO_STATE_DIR/config.json")
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
((BASH_VERSINFO[0] >= 4)) || missing+=("bash>=4 (have $BASH_VERSION)")
if [[ ${#missing[@]} -eq 0 ]]; then
    report ok deps "jq, git, bash $BASH_VERSION"
else
    report fail deps "missing: ${missing[*]}"
fi

exit "$failed"
