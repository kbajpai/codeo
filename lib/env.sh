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
#   codeo_cfg <jq-filter>         raw result from .codeo/config.json; empty and exit 1 if null/absent.
#                                 An empty string or the literal "null" counts as absent. Array filters
#                                 such as .suites[] print one value per line. An unusable config (missing,
#                                 invalid JSON, no repo) prints one "codeo:" line and exits the shell.
#   codeo_cfg_required <filter>   as codeo_cfg, but dies with "config.json: missing <filter>"
#   codeo_base_branch             baseBranch (required)
#   codeo_docs_dir                docsDir, or "docs" when the key is absent
#   codeo_plans_dir               plansDir, or "docs/plans" when the key is absent
#
# Config keys (.codeo/config.json):
#   schema                  integer, required, <= CODEO_SCHEMA
#   repo{owner,name}        required
#   baseBranch              required
#   board{owner,projects[],gateProject,statuses{}}   optional project board. projects[] and
#                           gateProject are integers (project numbers). statuses keys are camelCase
#                           logical names (ready, inProgress, inReview, done, backlog) mapping to the
#                           board's own option names; a name that is not a key passes through.
#   labelTypes{}            issue label -> branch type
#   suites[]{name,paths[],build,test,filter,parallel} test suites and the paths that trigger them.
#                           parallel is a bool, default false: true means the suite may run together
#                           with other parallel suites.
#                           filter is a command template that runs ONE test, {} standing for the
#                           test's name (e.g. pytest -k {}); absent means the suite has no
#                           single-test form and its whole test command is the proof
#   skipGlobs[]             paths that never trigger a suite
#   resources[]{name,paths[],parameterised}           exclusive resources (locks) and their footprints
#   environment{resource,hooks{activate,revoke,preflight,start,deployed,deploy}}   optional shared environment
#                           deployed prints one line per workload, four tab-separated columns: name,
#                           revision, state (running|rolling|stopped), declared (yes|no); the fourth
#                           column is optional and absent means unknown. A non-zero exit from deployed
#                           means "not yet checkable", never a pass. deploy is the project's whole
#                           deploy step: its last stdout line is the deployed revision (an empty last
#                           line means HEAD after the hook), a non-zero exit is a failed task, and it
#                           commits its own bookkeeping, printing the revision after that commit, so
#                           there is no tag-only exemption. The caller stops if the tree is dirty
#                           after the hook.
#   hooks{onLeaseChange}    optional; a shell command run best effort after every lease change
#                           that reaches origin (stdout discarded, a failure only reported)
#   docsDir                 optional; the project's documentation directory, relative to the root
#                           (default docs)
#   plansDir                optional; where plans are saved, relative to the root (default docs/plans)
#   invariants              path to the project's invariants document
#   models{subagent,reviewer}
#   modules[]               optional modules the project enables
#   stacks[]                optional; names recorded by setup.sh --stack (informational only)
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
    # exit, not return: the resolver has already printed the one line explaining the failure, and
    # a function on the left of || runs with errexit off, so a mere failed assignment would let
    # the caller carry on with an empty file name.
    file=$(_codeo_config_file) || exit 1
    value=$(jq -r "$1" "$file" 2>/dev/null) || codeo_die "config.json: bad filter $1"
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

# The directory keys are optional, so a project that sets neither still gets conventional paths.
codeo_docs_dir() {
    codeo_cfg .docsDir || echo docs
}

codeo_plans_dir() {
    codeo_cfg .plansDir || echo docs/plans
}
