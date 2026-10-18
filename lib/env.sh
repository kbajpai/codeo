#!/usr/bin/env bash
# Resolves where codeo runs and reads the project's config. Source it; it is safe under
# `set -euo pipefail` and does nothing at source time except resolve the roots. The config is read
# lazily by the codeo_cfg* functions, so a script that never needs it never requires it to exist.
#
# Exports:
#   CODEO_PLUGIN_ROOT   the directory above lib/ (where the plugin is installed)
#   CODEO_PROJECT_ROOT  git top level of the caller's cwd (not of this file: the plugin is
#                       installed outside the project it serves)
#   CODEO_STATE_DIR     $CODEO_PROJECT_ROOT/.codeo
#   CODEO_SCHEMA        the highest config schema this plugin understands
#
# Functions:
#   codeo_die <msg>               print "codeo: <msg>" to stderr and exit 1
#   codeo_cfg <jq-filter>         raw result from .codeo/config.json; empty and exit 1 if null/absent
#   codeo_cfg_required <filter>   as codeo_cfg, but dies with "config.json: missing <filter>"
#   codeo_base_branch             baseBranch (required)
#
# Config keys (.codeo/config.json):
#   schema                  integer, required, <= CODEO_SCHEMA
#   repo{owner,name}        required
#   baseBranch              required
#   board{owner,projects[],gateProject,statuses{}}   optional project board
#   labelTypes{}            issue label -> branch type
#   suites[]{name,paths[],build,test,filter}          test suites and the paths that trigger them
#   skipGlobs[]             paths that never trigger a suite
#   resources[]{name,paths[],parameterised}           exclusive resources (locks) and their footprints
#   environment{resource,hooks{activate,revoke,preflight,start,deployed}}   optional shared environment
#   invariants              path to the project's invariants document
#   models{subagent,reviewer}
#   modules[]               optional modules the project enables
#   ci{requiredChecks[]}    optional; checks the project's CI requires before a merge

CODEO_PLUGIN_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# Failure leaves the root empty rather than aborting the sourcing script; codeo_cfg then says why.
CODEO_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
CODEO_STATE_DIR="$CODEO_PROJECT_ROOT/.codeo"
CODEO_SCHEMA=1
export CODEO_PLUGIN_ROOT CODEO_PROJECT_ROOT CODEO_STATE_DIR CODEO_SCHEMA

codeo_die() {
    echo "codeo: $*" >&2
    exit 1
}

# Prints the config path after checking it exists and parses, so every reader refuses the same way.
_codeo_config_file() {
    [[ -n "$CODEO_PROJECT_ROOT" ]] || codeo_die "not inside a git repository"
    local file="$CODEO_STATE_DIR/config.json"
    [[ -f "$file" ]] || codeo_die "config.json not found at $file"
    jq empty "$file" 2>/dev/null || codeo_die "config.json: invalid JSON in $file"
    printf '%s\n' "$file"
}

codeo_cfg() {
    local file value
    file=$(_codeo_config_file)
    value=$(jq -r "$1" "$file") || codeo_die "config.json: bad filter $1"
    # jq prints the word null for an absent key; a literal "null" string is not a valid setting.
    if [[ -z "$value" || "$value" == "null" ]]; then
        return 1
    fi
    printf '%s\n' "$value"
}

codeo_cfg_required() {
    codeo_cfg "$1" || codeo_die "config.json: missing $1"
}

codeo_base_branch() {
    codeo_cfg_required .baseBranch
}
