#!/usr/bin/env bash
# Writes the dev container and sbx sandbox files into the project from the plugin's templates
# (templates/containers/), filling in the project's own names from .codeo/config.json. Run from
# inside the project.
#
#   containers.sh [--check] [--force]
#
# Names come from config: the codename (`codename`, required) prefixes every container,
# sandbox, image and volume (<codename>-home, <codename>-<N>, <codename>-dev, <codename>-gh), and
# repo.owner/repo.name give the repository URL, and baseBranch (default main) is the branch the raw URL and the clones follow. Nothing defaults to codeo's own values.
#
# Two kinds of file:
#   managed  the scripts (.devcontainer/scripts/*, copied as they are, and codeo, codeo-container.sh, codeo-track.sh, codeo-sandbox.sh): rewritten from
#            the template whenever --force is given; --check fails when one differs from its template.
#   seed     the files a project edits (the Dockerfile and its toolchain section, devcontainer.json,
#            the sbx image pin, the skill overlays under .codeo/overlays/): written only when absent, never checked, never overwritten.
# Without --force an existing file is left alone and reported as skipped. --check writes nothing.
# Output is one "containers: wrote|skip|ok|differs <path>" line per file. Exit 0 on success, 1 when
# --check finds a difference or the config is unusable, 2 on a usage error.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"

usage() {
    echo "usage: containers.sh [--check] [--force]" >&2
    exit 2
}

check=0
force=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --check) check=1 ;;
        --force) force=1 ;;
        *) usage ;;
    esac
    shift
done
((check == 0 || force == 0)) || usage

[[ -n "$CODEO_PROJECT_ROOT" ]] || codeo_die "not inside a git repository"
owner=$(codeo_cfg_required .repo.owner)
repo=$(codeo_cfg_required .repo.name)
codename=$(codeo_cfg .codename) || codeo_die "config.json has no codename: run setup.sh --codename <name> --containers (or set codename in .codeo/config.json); it names the containers, sandboxes, images and volumes"
base=$(codeo_cfg .baseBranch || echo main)

# setup.sh writes TODO-set-me for what it could not read; that must never be rendered into a file or a URL.
[[ $base != TODO-set-me ]] || codeo_die "config.json: baseBranch is TODO-set-me; set baseBranch in .codeo/config.json to the repository's base branch"
[[ $owner != TODO-set-me && $repo != TODO-set-me ]] || codeo_die "config.json: repo.owner and repo.name are TODO-set-me; set repo in .codeo/config.json to the GitHub owner and repository name"

# These land in file names, container names and URLs, so only the characters those allow get through.
[[ $codename =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]] ||
    codeo_die "config.json: codename '$codename' must be lower-case letters, digits and single hyphens, starting with a letter"
[[ $base =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ ]] ||
    codeo_die "config.json: baseBranch '$base' is not a branch name (letters, digits, dot, underscore, slash and hyphen, starting with a letter or digit)"
[[ $owner =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ && $repo =~ ^[A-Za-z0-9_.-]+$ ]] ||
    codeo_die "config.json: repo.owner/repo.name are not a GitHub owner and repository name"

tpl_root="$CODEO_PLUGIN_ROOT/templates/containers"
[[ -d $tpl_root ]] || codeo_die "no templates at $tpl_root"

seeds=(.devcontainer/Dockerfile .devcontainer/devcontainer.json .sbx/claude-image)
is_seed() {
    local s
    [[ $1 == .codeo/overlays/* ]] && return 0
    for s in "${seeds[@]}"; do [[ $1 == "$s" ]] && return 0; done
    return 1
}

# render <template> <destination>: the template with the project's names filled in.
render() {
    CODENAME=$codename REPO_SLUG="$owner/$repo" BASE_BRANCH=$base perl -pe 's/\@CODENAME\@/$ENV{CODENAME}/g; s/\@REPO_SLUG\@/$ENV{REPO_SLUG}/g; s/\@BASE_BRANCH\@/$ENV{BASE_BRANCH}/g' "$1" >"$2"
}

differs=0
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
while IFS= read -r -d '' src; do
    case "$src" in
        "$tpl_root"/*) rel=${src#"$tpl_root"/} ;;
        *) rel=${src#"$CODEO_PLUGIN_ROOT"/} ;; # the generic container scripts ship in the plugin as they are
    esac
    dest="$CODEO_PROJECT_ROOT/$rel"
    if ((check)); then
        is_seed "$rel" && continue
        render "$src" "$tmp"
        if [[ -f $dest ]] && cmp -s "$tmp" "$dest"; then
            echo "containers: ok $rel"
        else
            echo "containers: differs $rel"
            differs=1
        fi
        continue
    fi
    if [[ -e $dest ]] && { ((force == 0)) || is_seed "$rel"; }; then
        echo "containers: skip $rel"
        continue
    fi
    mkdir -p "$(dirname "$dest")"
    render "$src" "$tmp"
    cat "$tmp" >"$dest"
    chmod --reference="$src" "$dest" 2>/dev/null || { [[ -x $src ]] && chmod +x "$dest"; } || true
    echo "containers: wrote $rel"
done < <({ find "$tpl_root" -type f -print0; find "$CODEO_PLUGIN_ROOT/.devcontainer/scripts" -type f -print0; } | sort -z)
exit "$differs"
