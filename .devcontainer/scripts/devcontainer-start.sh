#!/usr/bin/env bash
# The dev container's postCreateCommand. Trusts the clone (and takes ownership of it when it is on a Docker volume), installs the Claude Code
# plugins, writes the window title, turns on Claude Code Remote Control (remoteControlAtStartup in the user
# settings), restores the executable bit the index records on tracked files and turns core.fileMode back on, only on a clone on a Docker volume where the filesystem keeps the bit as set, wires git to the GitHub login, and prints what is still left for the engineer to do
# (the GitHub and Claude logins, a git identity, credentials that block Remote Control). Safe to re-run: each step checks before it acts.
# It always exits 0, so it never fails the container's creation; what is undone is reported instead.
# The home container (on the base branch) takes no workflow lock; an issue container takes it with codeo's lock.sh from the init.md
# on its branch, and its clone folder is checked against the lock.
#
#   bash .devcontainer/scripts/devcontainer-start.sh
set -euo pipefail

todo=()
need_login=()
say() { echo "devcontainer-start: $*"; }
add_todo() { todo+=("$1"); }

# (The last of several lines for one mount point is the one in effect, hence >=.)
# clone_on_named_volume <path>: succeeds when <path> lives on a Docker named volume. It takes the mount
# that holds <path> (the longest mount point that is <path> or a parent of it) and checks that the mount's
# root, field 4 of its mountinfo line, is /var/lib/docker/volumes/<name>/_data. A bind mount's root is the
# host path instead, so a checkout bind-mounted from the host is never taken for a volume.
clone_on_named_volume() {
    local path=$1 info best_len=-1 best_root="" root mnt
    info=${CODEO_MOUNTINFO:-/proc/self/mountinfo}
    while read -r _ _ _ root mnt _; do
        [[ -n $mnt ]] || continue
        if [[ $path == "$mnt" || $path == "${mnt%/}"/* ]] && ((${#mnt} >= best_len)); then
            best_len=${#mnt}
            best_root=$root
        fi
    done < "$info" 2>/dev/null || return 1
    [[ $best_root =~ /volumes/[^/]+/_data$ ]]
}

# 1. Let git trust the clone. VS Code's clone-in-volume clones as root, and a root-owned clone must be
# handed to this user; but only a clone on a Docker volume is: a bind-mounted host checkout looks
# root-owned under rootless Docker and Podman, and changing it would change the engineer's files on the host.
clone=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
trusted=$(git config --global --get-all safe.directory 2>/dev/null || true)
grep -qxF -- "$clone" <<<"$trusted" ||
    git config --global --add safe.directory "$clone" || add_todo "git was not told to trust the clone: run git config --global --add safe.directory $clone"
if [[ $(stat -c %u "$clone" 2>/dev/null || true) != "$(id -u)" ]]; then
    if clone_on_named_volume "$clone"; then
        sudo chown -R "$(id -u):$(id -g)" "$clone" ||
            add_todo "the clone is not owned by you and chown failed: run sudo chown -R $(id -u):$(id -g) $clone"
    else
        add_todo "the clone at $clone is not owned by you and is not on a Docker volume, so it was left alone: run 'sudo chown -R $(id -u):$(id -g) $clone' yourself if that is what you want"
    fi
fi

# 2. Work from the top of the clone.
cd "$(git -C "$clone" rev-parse --show-toplevel)" || { add_todo "could not enter the clone at $clone"; }

# 2b. Executable scripts. Some container filesystems (a Windows or macOS host mount) set core.fileMode=false, and then
# `git add` records every new script as 100644. This runs only on a clone that is on a Docker volume, as step 1
# does: a bind-mounted host checkout's config and file modes are the host's, so it gets a TODO and nothing else. On a
# volume, when it is false, probe the git dir: only if the fresh probe file is not
# executable, chmod u+x makes it executable and chmod u-x makes it not executable again does the filesystem keep the
# executable bit as set. Then the files the index records as executable but the disk has as not are made executable
# again (only that direction: an executable bit the index does not record is left, and shows as a mode change), the
# files named in the message, and only when that worked does core.fileMode go back on for this clone; if a file could
# not be restored or the modes could not be listed, say how to stage by hand.

# restore_modes: chmod +x each tracked file the index records as 100755 but the disk has as 100644 (what a filesystem
# that dropped the bit did), then list again. Only that direction: a file the disk has executable and the index does
# not record is the developer's, and stays. The listing (`git -c core.fileMode=true diff --raw -z --no-renames`) goes
# through a temp file in the git dir, because bash drops NUL bytes from a command substitution. Prints nothing; sets
# restored_count, restored_paths and left_paths (the paths still differing). Returns 0 when none are left, 1 when
# some are, 2 when a listing failed (the temp file is removed on every path).
restore_modes() {
    local meta path old new list
    restored_count=0
    restored_paths=()
    left_paths=()
    list=$(mktemp "$(git rev-parse --git-dir)/modes.XXXXXX" 2>/dev/null) || return 2
    if ! git -c core.fileMode=true diff --raw -z --no-renames >"$list" 2>/dev/null; then
        rm -f -- "$list"
        return 2
    fi
    while IFS= read -r -d '' meta && IFS= read -r -d '' path; do
        read -r old new _ <<<"${meta#:}"
        [[ $old == 100755 && $new == 100644 ]] || continue
        if chmod +x -- "$path" 2>/dev/null; then
            restored_count=$((restored_count + 1))
            restored_paths+=("$path")
        fi
    done <"$list"
    if ! git -c core.fileMode=true diff --raw -z --no-renames >"$list" 2>/dev/null; then
        rm -f -- "$list"
        return 2
    fi
    while IFS= read -r -d '' meta && IFS= read -r -d '' path; do
        read -r old new _ <<<"${meta#:}"
        [[ $old == 100755 && $new == 100644 ]] || continue
        left_paths+=("$path")
    done <"$list"
    rm -f -- "$list"
    ((${#left_paths[@]} == 0)) || return 1
}

if [[ $(git config --type=bool core.fileMode 2>/dev/null || true) == false ]]; then
    if ! clone_on_named_volume "$clone"; then
        add_todo "core.fileMode is false and the clone is not on a Docker volume, so it was left alone (its config and file modes are the host's): stage each new script with git update-index --chmod=+x <file>"
    else
        if filemode_probe=$(mktemp "$(git rev-parse --git-dir)/filemode.XXXXXX" 2>/dev/null); then
            if [[ ! -x $filemode_probe ]] && chmod u+x -- "$filemode_probe" 2>/dev/null && [[ -x $filemode_probe ]] \
                && chmod u-x -- "$filemode_probe" 2>/dev/null && [[ ! -x $filemode_probe ]]; then
                rm -f -- "$filemode_probe"
                restore_rc=0
                restore_modes || restore_rc=$?
                if ((restore_rc == 2)); then
                    add_todo "core.fileMode is false and the tracked files' modes could not be listed: stage each new script with git update-index --chmod=+x <file>"
                elif ((restore_rc == 1)); then
                    left_list=$(printf '%s, ' "${left_paths[@]:0:5}")
                    left_list=${left_list%, }
                    ((${#left_paths[@]} <= 5)) || left_list+=" and $((${#left_paths[@]} - 5)) more"
                    add_todo "core.fileMode is false and could not restore the modes of $left_list: chmod them to the index's modes, or stage with git update-index --chmod=+x <file>"
                elif git config core.fileMode true; then
                    if ((restored_count > 0)); then
                        restored_list=$(printf '%s, ' "${restored_paths[@]:0:5}")
                        restored_list=${restored_list%, }
                        ((${#restored_paths[@]} <= 5)) || restored_list+=" and $((${#restored_paths[@]} - 5)) more"
                        say "core.fileMode was false and this filesystem keeps the executable bit as set: restored the modes of $restored_count tracked file$( ((restored_count == 1)) || echo s) ($restored_list) to the index's and set it to true for this clone"
                    else
                        say "core.fileMode was false and this filesystem keeps the executable bit as set: set it to true for this clone"
                    fi
                else
                    add_todo "core.fileMode is false and could not be turned on: run git config core.fileMode true, or stage new scripts with git update-index --chmod=+x"
                fi
            else
                rm -f -- "$filemode_probe"
                add_todo "core.fileMode is false and this filesystem does not keep the executable bit as set: stage each new script with git update-index --chmod=+x <file>"
            fi
        else
            add_todo "core.fileMode is false and the git dir is not writable to probe it: stage each new script with git update-index --chmod=+x <file>"
        fi
    fi
fi

# 3. Plugins.
bash .devcontainer/scripts/plugins.sh || add_todo "plugins.sh did not finish: fix what it printed, then run bash .devcontainer/scripts/plugins.sh"

# 3a. The workflow lock: .codeo/active, taken by codeo's own lock.sh from the .codeo/<N>/init.md that
# names this branch. The home container is on the base branch (.codeo/config.json's baseBranch, else
# main) and takes none; a container that already holds the lock (a re-run) takes none again; a
# detached HEAD names no branch, so it is a TODO. lock.sh's output is printed unchanged, except that
# its `lock: TODO — …` lines become TODOs. The plugin is pinned and not ours: the `|| rc=$?` guard is
# for a crash or a changed interface after a pin bump, where a non-zero exit would otherwise end this
# script under set -e before its TODO list.
branch=$(git branch --show-current 2>/dev/null || true)
base=$(jq -r '.baseBranch // "main"' .codeo/config.json 2>/dev/null || true)
[[ -n $base ]] || base=main
if [[ -s .codeo/active ]]; then
    : # a lock means the checkout is already bound to an issue, whatever HEAD is
elif [[ -z $branch ]]; then
    add_todo "HEAD is detached, so no branch names an issue: check out the issue's branch, then re-run this script"
elif [[ $branch != "$base" ]]; then
    if codeo_root=$(bash .devcontainer/scripts/codeo-root.sh 2>/dev/null); then
        lock_rc=0
        lock_out=$(bash "$codeo_root/scripts/lock.sh" take container 2>&1) || lock_rc=$?
        while IFS= read -r line; do
            case $line in
                "lock: TODO — "*) add_todo "${line#lock: TODO — }" ;;
                '') ;;
                *) echo "$line" ;;
            esac
        done <<<"$lock_out"
        ((lock_rc == 0)) || add_todo "codeo's lock.sh failed (exit $lock_rc): ${lock_out//$'\n'/ / }"
    else
        add_todo "codeo is not installed, so no lock was taken: fix what plugins.sh printed above, then re-run this script"
    fi
fi

# 3a'. The clone folder is the container's Docker name (devcontainer.json runArgs --name), so it
# should say what the lock does; folder-check.sh judges it. Captured, not read through `< <(…)`,
# which would swallow its exit status: a check that itself fails is one TODO, never a stray error.
# Its `todo:` lines become TODOs; it prints nothing else this script passes on.
if folder_out=$(bash .devcontainer/scripts/folder-check.sh "$(basename "$clone")" 2>&1); then
    while IFS= read -r line; do
        case $line in
            todo:*) add_todo "${line#todo: }" ;;
        esac
    done <<<"$folder_out"
else
    add_todo "the folder check failed: ${folder_out//$'\n'/ / } — fix it and re-run this script"
fi

# 3b. Window title: write this clone's title into .vscode/settings.json.
bash .devcontainer/scripts/window-title.sh || add_todo "window-title.sh did not finish: fix what it printed, then run bash .devcontainer/scripts/window-title.sh"

# 3c. Remote Control: merge {"remoteControlAtStartup": true} into the user-scope Claude settings, keeping every other key.
# A symlinked settings.json is written through (readlink -f), and the file keeps its mode. A file that is not valid
# JSON, or not a JSON object, is left untouched; a path that exists but is not a regular file is reported as a TODO and left alone. The merge goes through a temp file beside the target, removed on failure.
claude_dir=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
claude_settings=$claude_dir/settings.json
mkdir -p "$claude_dir" || add_todo "could not create $claude_dir: Remote Control was not enabled"
if [[ ! -e $claude_settings ]]; then
    echo '{}' > "$claude_settings" || add_todo "could not create $claude_settings: Remote Control was not enabled"
fi
if [[ -f $claude_settings ]]; then
    claude_target=$(readlink -f -- "$claude_settings" 2>/dev/null || true)
    claude_kind=
    [[ -z $claude_target ]] || claude_kind=$(jq -rn '[inputs] | if length == 0 then "object" elif length == 1 then (.[0] | type) else "multi" end' "$claude_target" 2>/dev/null || true)
    if [[ -z $claude_target ]]; then
        add_todo "could not resolve $claude_settings: Remote Control was not enabled"
    elif [[ -z $claude_kind || $claude_kind == multi ]]; then
        add_todo "$claude_settings is not valid JSON and was left alone: fix it, then add \"remoteControlAtStartup\": true"
    elif [[ $claude_kind != object ]]; then
        add_todo "$claude_settings is not a JSON object and was left alone: fix it, then add \"remoteControlAtStartup\": true"
    elif claude_tmp=$(mktemp "$(dirname "$claude_target")/.settings.XXXXXX" 2>/dev/null); then
        if jq -n '([inputs][0] // {}) + {remoteControlAtStartup: true}' "$claude_target" > "$claude_tmp" 2>/dev/null \
            && [[ -s $claude_tmp ]] \
            && chmod --reference="$claude_target" -- "$claude_tmp" 2>/dev/null \
            && mv -- "$claude_tmp" "$claude_target"; then
            :
        else
            rm -f "$claude_tmp"
            add_todo "could not write $claude_target: Remote Control was not enabled"
        fi
    else
        add_todo "could not write $claude_target: Remote Control was not enabled"
    fi
elif [[ -e $claude_settings ]]; then
    add_todo "$claude_settings is not a regular file and was left alone: fix it, then add \"remoteControlAtStartup\": true"
fi

# 4. GitHub: wire git to the login, and check the project scope the board needs.
# The output is captured before grep reads it: a pipeline ending in `grep -q` can kill the writer early.
if gh_status=$(gh auth status 2>&1); then
    gh auth setup-git || add_todo "gh auth setup-git failed: run it again"
    if ! grep -q "'project'" <<<"$gh_status"; then
        add_todo "the GitHub token lacks the project scope: run gh auth refresh -s project"
        need_login+=("gh auth refresh -s project")
    fi
else
    add_todo "GitHub is not logged in: run gh auth login -s project"
    need_login+=("gh auth login -s project")
fi

# 5. Git identity.
if [[ -z $(git config user.email || true) || -z $(git config user.name || true) ]]; then
    add_todo "git identity is not set: run git config --global user.name 'Your Name' and git config --global user.email you@example.com"
fi

# 6. Claude Code login.
# Remote Control needs a claude.ai login, so these credentials must not be set. The output is captured before it is read.
# While CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY is set the check is skipped: the variable overrides any login, so
# `claude auth login` would not help, and the "unset it" TODO below is the advice.
if [[ -z ${CLAUDE_CODE_OAUTH_TOKEN:-} && -z ${ANTHROPIC_API_KEY:-} ]]; then
    if claude_status=$(claude auth status 2>&1); then
        auth_method=$(jq -r '.authMethod // empty' <<<"$claude_status" 2>/dev/null || true)
        if [[ -n $auth_method && $auth_method != "claude.ai" ]]; then
            add_todo "Claude Code is logged in with $auth_method, not claude.ai, and Remote Control needs claude.ai: run claude auth login"
            need_login+=("claude auth login")
        fi
    else
        add_todo "Claude Code is not logged in: run claude auth login"
        need_login+=("claude auth login")
    fi
fi
for var in CLAUDE_CODE_OAUTH_TOKEN ANTHROPIC_API_KEY ANTHROPIC_BASE_URL; do
    if [[ -n ${!var:-} ]]; then
        add_todo "$var is set, and Remote Control does not work while it is set: unset it"
    fi
done

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
