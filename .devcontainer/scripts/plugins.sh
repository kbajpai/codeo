#!/usr/bin/env bash
# Installs the two Claude Code plugins codeo's own development needs: superpowers, and codeo at the
# version pinned in .codeo/config.json (plugin.repo and plugin.ref). Safe to re-run: what is already
# installed at the pin is left alone, and a changed pin replaces the installed codeo. Claude loads
# plugins when a session starts, so a session already open will not see a change until it restarts.
# Prints "plugins: ..." lines on stdout; exits 1 with the reason on stderr when either plugin is
# not installed at the end.
#
#   bash .devcontainer/scripts/plugins.sh
set -euo pipefail

root=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
config_dir=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
say() { echo "plugins: $*"; }
ok=1
# claude never runs inside a git repository: `plugin marketplace remove` rewrites the repository's
# tracked .claude/settings.json when it does.
claude_out() { (cd "$HOME" && claude "$@"); }
# The list is captured, then compared word by word: a plugin counts only when its whole name is a word
# of the list (grep would match codeo@codeo inside codeo@codeo-fork, and grep -w treats - as a boundary).
has_plugin() {
    local list word
    list=$(claude_out plugin list 2>/dev/null || true)
    for word in $list; do [[ $word == "$1" ]] && return 0; done
    return 1
}

has_plugin 'superpowers@superpowers-marketplace' || {
    if claude_out plugin marketplace add obra/superpowers-marketplace >/dev/null 2>&1 &&
        claude_out plugin install superpowers@superpowers-marketplace --scope user >/dev/null 2>&1; then
        say "installed superpowers"
    else ok=; echo "plugins: superpowers is not installed: check the network, then re-run this script" >&2; fi
}

repo=$(jq -r '.plugin.repo // empty' "$root/.codeo/config.json" 2>/dev/null || true)
ref=$(jq -r '.plugin.ref // empty' "$root/.codeo/config.json" 2>/dev/null || true)
have_ref=$(jq -r '.codeo.source.ref // empty' "$config_dir/plugins/known_marketplaces.json" 2>/dev/null || true)
if [[ -z $repo || -z $ref ]]; then
    ok=; echo "plugins: .codeo/config.json has no plugin.repo and plugin.ref, so codeo is not installed" >&2
elif [[ $have_ref != "$ref" ]] || ! has_plugin 'codeo@codeo'; then
    # An installed codeo is only replaced once the pin is known to exist: `marketplace remove`
    # also uninstalls it, so an add that then fails offline would leave no codeo at all.
    if has_plugin 'codeo@codeo' &&
        ! GIT_TERMINAL_PROMPT=0 timeout 20 git ls-remote --exit-code -q "https://github.com/$repo" "$ref" >/dev/null 2>&1; then
        ok=; echo "plugins: codeo stays at ${have_ref:-its current version}: the pin $ref could not be fetched: check the network and the pin, then re-run this script" >&2
    else
        claude_out plugin marketplace remove codeo >/dev/null 2>&1 || true
        if claude_out plugin marketplace add "$repo@$ref" >/dev/null 2>&1 &&
            claude_out plugin install codeo@codeo --scope user >/dev/null 2>&1; then
            say "installed codeo $ref"
        else ok=; echo "plugins: codeo is not installed at $ref: check the network, then re-run this script" >&2; fi
    fi
fi
[[ -n $ok ]] || exit 1
say "superpowers, codeo ${ref}"
