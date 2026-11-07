#!/usr/bin/env bash
# The dev container's postCreateCommand. Takes ownership of the clone, installs the Claude Code
# plugins, wires git to the GitHub login, and prints what is still left for the engineer to do
# (the GitHub and Claude logins, a git identity). Safe to re-run: each step checks before it acts.
# It always exits 0, so it never fails the container's creation; what is undone is reported instead.
#
#   bash .devcontainer/scripts/devcontainer-start.sh
set -euo pipefail

todo=()
need_login=()
say() { echo "devcontainer-start: $*"; }
add_todo() { todo+=("$1"); }

# 1. VS Code's clone-in-volume clones as root, and git then refuses the clone as dubious ownership.
clone=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
if [[ $(stat -c %u "$clone" 2>/dev/null || true) != "$(id -u)" ]]; then
    sudo chown -R "$(id -u):$(id -g)" "$(dirname "$clone")" ||
        add_todo "the clone is not owned by you and chown failed: run sudo chown -R $(id -u):$(id -g) $(dirname "$clone")"
fi

# 2. Work from the top of the clone.
cd "$(git -C "$clone" rev-parse --show-toplevel)" || { add_todo "could not enter the clone at $clone"; }

# 3. Plugins.
bash .devcontainer/scripts/plugins.sh || add_todo "plugins.sh did not finish: fix what it printed, then run bash .devcontainer/scripts/plugins.sh"

# 4. GitHub: wire git to the login, and check the project scope the board needs.
# The output is captured before grep reads it: a pipeline ending in `grep -q` can kill the writer early.
if gh_status=$(gh auth status 2>&1); then
    gh auth setup-git || add_todo "gh auth setup-git failed: run it again"
    if ! grep -q "'project'" <<<"$gh_status"; then
        add_todo "the GitHub token lacks the project scope: run gh auth refresh -s project"
        need_login+=("gh auth refresh -s project")
    fi
else
    add_todo "GitHub is not logged in: run gh auth login"
    need_login+=("gh auth login" "gh auth refresh -s project")
fi

# 5. Git identity.
if [[ -z $(git config user.email || true) || -z $(git config user.name || true) ]]; then
    add_todo "git identity is not set: run git config --global user.name 'Your Name' and git config --global user.email you@example.com"
fi

# 6. Claude Code login.
if ! claude auth status >/dev/null 2>&1; then
    add_todo "Claude Code is not logged in: run claude auth login"
    need_login+=("claude auth login")
fi

# 7. Report.
if ((${#todo[@]} == 0)); then
    say "ready"
else
    for item in "${todo[@]}"; do
        echo "devcontainer-start: TODO — $item" >&2
    done
    if ((${#need_login[@]} > 0)); then
        echo "devcontainer-start: what is left to do, in this order:" >&2
        n=0
        for item in "${need_login[@]}" "bash .devcontainer/scripts/devcontainer-start.sh"; do
            n=$((n + 1))
            echo "  $n. $item" >&2
        done
    fi
fi
exit 0
