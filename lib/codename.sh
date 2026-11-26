#!/usr/bin/env bash
# Shared by scripts/setup.sh and scripts/codeo-init.sh so the two cannot drift.
#
#   codeo_derive_codename <repo-name>   prints the codename a repository name makes: lower case, "." "_" and spaces
#                                       as hyphens, repeated hyphens collapsed, leading non-letters and edge hyphens
#                                       stripped, at most 30 characters. Prints nothing (exit 1) when what is left is
#                                       not a valid codename (2-30 characters of lower-case letters, digits, single hyphens).
#   codeo_latest_release <git-url>      prints the newest vX.Y.Z release tag of the repository; nothing (exit 1) when none.
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
        printf 'rename or re-clone it as %s-home to run /codeo:issue and /codeo:init here\n' "$1"
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
    printf '%s\n' 'kept files are yours and are not checked against the templates (a Dockerfile needs the dev user, gh and Claude Code; an overlay needs its role-guard and host-workflow sections): see docs/container-templates.md, Managed and seed files'
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
