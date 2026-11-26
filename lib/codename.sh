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
