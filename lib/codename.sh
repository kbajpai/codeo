#!/usr/bin/env bash
# Shared by scripts/setup.sh and scripts/codeo-init.sh so the two cannot drift.
#
#   codeo_derive_codename <repo-name>   prints the codename a repository name makes: lower case, "." "_" and spaces
#                                       as hyphens, repeated hyphens collapsed, leading non-letters and edge hyphens
#                                       stripped, at most 30 characters. Prints nothing (exit 1) when what is left is
#                                       not a valid codename (2-30 characters of lower-case letters, digits, single hyphens).
#   codeo_latest_release <git-url>      prints the newest vX.Y.Z release tag of the repository; nothing (exit 1) when none.
#   codeo_home_lines <codename> <root>  prints where the home checkout lives (and, when the folder is named otherwise, how to rename it).
#   codeo_pin_missing <config>          prints which of plugin.repo, plugin.ref the config lacks ("repo", "ref", "repo ref"), or nothing.
#   codeo_pin_fill <config> <repo> <ref>  writes only the absent or empty pin keys, atomically; exit 1 (config untouched) on failure.
#   codeo_pin_url <config>              prints the git URL to look the newest release up in (CODEO_PLUGIN_URL, the config's plugin.repo,
#                                       CODEO_PLUGIN_REPO; CODEO_PLUGIN_BASE stands in for https://github.com).
#   codeo_pin_repo_error <config>       prints a line and exits 1 when plugin.repo is set but not owner/name.
#   codeo_config_is_object <config>     succeeds when the config parses and is a JSON object.
#   codeo_config_shape_error <config>   prints "is not valid JSON" or "is not a JSON object" (exit 1) when it is not one.
#   codeo_base_error <config>           prints the baseBranch message and exits 1 when baseBranch is TODO-set-me.
#   codeo_kept_seeds <output>, codeo_kept_seeds_note   count the seed files containers.sh kept; the one-line note about them.
codeo_derive_codename() {
    local c
    c=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr '._ ' '---' | tr -s '-' | sed 's/^[^a-z]*//' | cut -c1-30 | sed 's/-*$//')
    [[ $c =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ && ${#c} -ge 2 ]] || return 1
    printf '%s\n' "$c"
}

codeo_latest_release() {
    local t
    t=$(git ls-remote --tags --refs "$1" 'v*' 2>/dev/null | sed 's|.*refs/tags/||' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1)
    [[ -n $t ]] || return 1
    printf '%s\n' "$t"
}

# codeo_home_lines <codename> <project-root>: where the home checkout lives (the role guard reads the folder name).
# Prints the line saying so and, only when this folder is named otherwise, the line saying to rename or re-clone it.
codeo_home_lines() {
    local dir=${2##*/}
    printf "the home checkout is a clone whose folder is named %s-home; this folder is '%s'\n" "$1" "$dir"
    [[ $dir == "$1-home" ]] ||
        printf 'rename or re-clone it as %s-home to run the home skills (/codeo:issue, /codeo:init, /codeo:triage, /codeo:cleanup) here\n' "$1"
}

# codeo_pin_missing <config>: prints which half of the plugin pin the config lacks, "repo", "ref" or "repo ref", and
# nothing when the pin is complete. An empty string counts as absent. scripts/doctor.sh, scripts/setup.sh and
# scripts/codeo-init.sh all ask this, so what the wizard fills is exactly what doctor checks.
codeo_pin_missing() {
    jq -r '[(if ((.plugin | objects | .repo) // "") == "" then "repo" else empty end),
            (if ((.plugin | objects | .ref) // "") == "" then "ref" else empty end)] | join(" ")' "$1" 2>/dev/null
}

# codeo_pin_fill <config> <repo> <ref>: writes the non-empty <repo> and <ref> into .plugin, only where that key is
# absent or empty, keeping every other key. Atomic (temp file, then mv); on failure the temp file is removed and the
# config is untouched (exit 1).
codeo_pin_fill() {
    local cfg=$1
    jq -e '(has("plugin") | not) or .plugin == null or (.plugin | type) == "object"' "$cfg" >/dev/null 2>&1 ||
        echo "codeo: .codeo/config.json plugin was not an object; replaced" >&2
    if jq --arg r "$2" --arg f "$3" '
        .plugin = ((.plugin | objects) // {})
        | if $r != "" and ((.plugin.repo // "") == "") then .plugin.repo = $r else . end
        | if $f != "" and ((.plugin.ref // "") == "") then .plugin.ref = $f else . end' "$cfg" >"$cfg.new" &&
        mv "$cfg.new" "$cfg"; then
        return 0
    fi
    rm -f "$cfg.new"
    return 1
}

# codeo_kept_seeds <containers.sh output>: how many seed files containers.sh left alone (its "containers: skip <path>"
# lines for the Dockerfile, devcontainer.json, the sandbox image and the overlays); the managed scripts do not count.
codeo_kept_seeds() {
    printf '%s\n' "$1" | grep -cE '^containers: skip (\.devcontainer/Dockerfile|\.devcontainer/devcontainer\.json|\.sbx/claude-image|\.codeo/overlays/.+)$' || true
}

codeo_kept_seeds_note() {
    printf '%s\n' "kept files are yours and are not checked against the templates (a Dockerfile needs the dev user, gh and Claude Code; an overlay needs the sections its template has (role-guard in every overlay; host-workflow in init and close; removal-command in cleanup)): see the codeo plugin's docs/container-templates.md, Managed and seed files"
}

# codeo_pin_url <config>: the repository to look the newest release up in. CODEO_PLUGIN_URL when set; else the
# config's own plugin.repo (a fork's tags are the fork's); else CODEO_PLUGIN_REPO (default kbajpai/codeo). The
# repository is joined to CODEO_PLUGIN_BASE (default https://github.com; tests point it at local bare repositories).
# The lone-script fetch at the top of scripts/codeo-init.sh cannot source this file; it fetches the release the script
# itself is cloned from and keeps its own lookup.
codeo_pin_url() {
    local repo
    [[ -z ${CODEO_PLUGIN_URL:-} ]] || { printf '%s\n' "$CODEO_PLUGIN_URL"; return 0; }
    repo=$(jq -r '(.plugin | objects | .repo) // ""' "$1" 2>/dev/null || true)
    [[ -n $repo ]] || repo=${CODEO_PLUGIN_REPO:-kbajpai/codeo}
    printf '%s/%s.git\n' "${CODEO_PLUGIN_BASE:-https://github.com}" "$repo"
}

# codeo_config_is_object <config>: the config parses and is a JSON object.
codeo_config_is_object() {
    jq -e 'type == "object"' "$1" >/dev/null 2>&1
}

codeo_config_shape_error() {
    codeo_config_is_object "$1" && return 0
    if jq empty "$1" >/dev/null 2>&1; then echo "is not a JSON object"; else echo "is not valid JSON"; fi
    return 1
}

# codeo_base_value_error <base>: the message, and exit 1, when a baseBranch is TODO-set-me or not a branch name. scripts/containers.sh
# and codeo_base_error both use it, so they cannot drift.
codeo_base_value_error() {
    if [[ $1 == TODO-set-me ]]; then
        echo "config.json: baseBranch is TODO-set-me; set baseBranch in .codeo/config.json to the repository's base branch"
        return 1
    fi
    [[ $1 =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ ]] || {
        echo "config.json: baseBranch '$1' is not a branch name (letters, digits, dot, underscore, slash and hyphen, starting with a letter or digit)"
        return 1
    }
}

# codeo_base_error <config>: the same check on the config's baseBranch; an absent or empty one is not refused (containers.sh uses main).
codeo_base_error() {
    local b
    b=$(jq -r '.baseBranch // empty | tostring' "$1" 2>/dev/null || true)
    [[ -z $b ]] || codeo_base_value_error "$b"
}

# codeo_pin_repo_error <config>: prints "config.json: plugin.repo '<x>' is not an owner/name" and returns 1 when the
# config's plugin.repo is set but is not owner/name; returns 0 (printing nothing) otherwise. Callers stop on it before
# they write anything, so a hand-edited value never reaches a URL.
codeo_pin_repo_error() {
    local repo
    repo=$(jq -r '(.plugin | objects | .repo) // "" | tostring' "$1" 2>/dev/null || true)
    [[ -z $repo || $repo =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*/[A-Za-z0-9_.-]+$ ]] && return 0
    printf "config.json: plugin.repo '%s' is not an owner/name\n" "$repo"
    return 1
}
