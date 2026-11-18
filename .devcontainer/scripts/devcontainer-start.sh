#!/usr/bin/env bash
# The dev container's postCreateCommand. Trusts the clone (and takes ownership of it when it is on a Docker volume), records the clone as trusted in Claude Code, installs the Claude Code
# plugins, writes the window title, turns on Claude Code Remote Control (remoteControlAtStartup in the user
# settings), restores the executable bit the index records on tracked files and turns core.fileMode back on, only on a clone on a Docker volume where the filesystem keeps the bit as set, wires git to the GitHub login, and prints what is still left for the engineer to do
# (the GitHub and Claude logins, a git identity (filled from the host ~/.gitconfig or GIT_AUTHOR_* when the volume lacks it), credentials that block Remote Control). Safe to re-run: each step checks before it acts.
# With CODEO_CMD_MODE set (a container started from a host command line, no VS Code) it skips the window title and the wait for the host ~/.gitconfig.
# It always exits 0, so it never fails the container's creation; what is undone is reported instead.
# The home container (on the base branch) takes no workflow lock; an issue container takes it with codeo's lock.sh from the init.md
# on its branch, and its clone folder is checked against the lock. A .codeo/active that names no issue, or cannot be read, or is empty and cannot be removed, is reported and left alone.
#
#   bash .devcontainer/scripts/devcontainer-start.sh
set -euo pipefail

todo=()
need_login=()
say() { echo "devcontainer-start: $*"; }
add_todo() { todo+=("$1"); }

# clone_on_named_volume <path>: succeeds when <path> lives on a Docker named volume. It takes the mount
# that holds <path> (the longest mount point that is <path> or a parent of it) and checks that the mount's
# root, field 4 of its mountinfo line, is /var/lib/docker/volumes/<name>/_data. A bind mount's root is the
# host path instead, so a checkout bind-mounted from the host is never taken for a volume.
clone_on_named_volume() {
    local path=$1 info best_len=-1 best_root="" root mnt
    info=${CODEO_MOUNTINFO:-/proc/self/mountinfo}
    while read -r _ _ _ root mnt _; do
        [[ -n $mnt ]] || continue
        # (The last of several lines for one mount point is the one in effect, hence >=.)
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
trust_ok=1
grep -qxF -- "$clone" <<<"$trusted" ||
    git config --global --add safe.directory "$clone" || { trust_ok=; add_todo "git was not told to trust the clone: run git config --global --add safe.directory $clone"; }
if [[ $(stat -c %u "$clone" 2>/dev/null || true) != "$(id -u)" ]]; then
    if clone_on_named_volume "$clone"; then
        sudo chown -R "$(id -u):$(id -g)" "$clone" ||
            add_todo "the clone is not owned by you and chown failed: run sudo chown -R $(id -u):$(id -g) $clone"
    else
        add_todo "the clone at $clone is not owned by you and is not on a Docker volume, so it was left alone: under rootless Docker or Podman the user namespace mapping makes host files look owned by another user, changing that ownership would change the host's files${trust_ok:+, and git is already told to trust the clone}"
    fi
fi

# 2. Work from the top of the clone.
# An empty result is a failure here, not `cd ""`. When git cannot find a top level (no .git in the clone), the clone
# folder itself is the working directory, so every later step, which uses relative paths, runs there and never in
# the caller's directory; that is one TODO of its own. Only when the folder cannot be entered either is it "could not enter".
if top=$(git -C "$clone" rev-parse --show-toplevel 2>/dev/null) && [[ -n $top ]] && cd "$top"; then
    :
elif cd "$clone"; then
    add_todo "git could not find the top level of the clone at $clone, so the steps ran from that folder"
else
    add_todo "could not enter the clone at $clone"
fi

# 2b. Executable scripts. Some container filesystems (a Windows or macOS host mount) set core.fileMode=false, and then
# `git add` records every new script as 100644. This runs only on a clone that is on a Docker volume, as step 1
# does: a bind-mounted host checkout's config and file modes are the host's, so it gets a TODO and nothing else. On a
# volume, when it is false, probe the git dir: only if the fresh probe file is not
# executable, chmod u+x makes it executable and chmod u-x makes it not executable again does the filesystem keep the
# executable bit as set. Then the files the index records as executable but the disk has as not are made executable
# again (only that direction: an executable bit the index does not record is left, and shows as a mode change), the
# files named in the message, and only when that worked does core.fileMode go back on for this clone; if a file could
# not be restored or the modes could not be listed, say how to stage by hand. A `true` that does not take effect (a command or
# worktree scope outranks the clone's config and still gives false) is reported as a TODO, not as an override.

# restore_modes: chmod +x each tracked file the index records as 100755 but the disk has as 100644 (what a filesystem
# that dropped the bit did), then list again. Only that direction: a file the disk has executable and the index does
# not record is the developer's, and stays. The listing (`git -c core.fileMode=true diff --raw -z --no-renames`) goes
# through a temp file in the git dir (kept in modes_list, which the EXIT trap removes when the script ends), because bash drops NUL
# bytes from a command substitution; its stderr goes to list_err. Prints nothing; sets kept_paths (executable on disk,
# 100644 in the index), restored_count, restored_paths and left_paths (the paths still differing). Returns 0 when none
# are left, 1 when some are, 2 when a listing failed.
restore_modes() {
    local meta path old new
    restored_count=0
    restored_paths=()
    left_paths=()
    kept_paths=()
    list_err=
    modes_list=$(mktemp "$(git rev-parse --git-dir)/modes.XXXXXX" 2>&1) || { list_err=${modes_list//$'\n'/ / }; modes_list=; return 2; }
    if ! list_err=$(git -c core.fileMode=true diff --raw -z --no-renames 2>&1 >"$modes_list"); then
        list_err=${list_err//$'\n'/ / }
        return 2
    fi
    while IFS= read -r -d '' meta && IFS= read -r -d '' path; do
        read -r old new _ <<<"${meta#:}"
        [[ $old == 100755 && $new == 100644 ]] || continue
        if chmod +x -- "$path" 2>/dev/null; then
            restored_count=$((restored_count + 1))
            restored_paths+=("$path")
        fi
    done <"$modes_list"
    if ! list_err=$(git -c core.fileMode=true diff --raw -z --no-renames 2>&1 >"$modes_list"); then
        list_err=${list_err//$'\n'/ / }
        return 2
    fi
    while IFS= read -r -d '' meta && IFS= read -r -d '' path; do
        read -r old new _ <<<"${meta#:}"
        if [[ $old == 100755 && $new == 100644 ]]; then
            left_paths+=("$path")
        elif [[ $old == 100644 && $new == 100755 ]]; then
            kept_paths+=("$path")
        fi
    done <"$modes_list"
    ((${#left_paths[@]} == 0)) || return 1
}

# The listing's temp file is removed on every exit, an interrupt included.
modes_list=
trap '[[ -z ${modes_list:-} ]] || rm -f -- "$modes_list"' EXIT

if [[ $(git config --type=bool core.fileMode 2>/dev/null || true) == false ]]; then
    if ! clone_on_named_volume "$clone"; then
        add_todo "core.fileMode is false and the clone is not on a Docker volume, so it was left alone (its config and file modes are the host's): stage each new script with git update-index --chmod=+x <file>"
    else
        if filemode_probe=$(mktemp "$(git rev-parse --git-dir)/filemode.XXXXXX" 2>/dev/null); then
            if [[ ! -x $filemode_probe ]] && chmod u+x -- "$filemode_probe" 2>/dev/null && [[ -x $filemode_probe ]] \
                && chmod u-x -- "$filemode_probe" 2>/dev/null && [[ ! -x $filemode_probe ]]; then
                rm -f -- "$filemode_probe"
                filemode_scope=$(git config --show-scope --get core.fileMode 2>/dev/null) && filemode_scope=${filemode_scope%%[[:space:]]*} || filemode_scope=local
                restore_rc=0
                restore_modes || restore_rc=$?
                if ((restore_rc == 2)); then
                    add_todo "core.fileMode is false and the tracked files' modes could not be listed${list_err:+ ($list_err)}: stage each new script with git update-index --chmod=+x <file>"
                elif ((restore_rc == 1)); then
                    left_list=$(printf '%s, ' "${left_paths[@]:0:5}")
                    left_list=${left_list%, }
                    ((${#left_paths[@]} <= 5)) || left_list+=" and $((${#left_paths[@]} - 5)) more"
                    add_todo "core.fileMode is false and could not restore the modes of $left_list: chmod them to the index's modes, or stage with git update-index --chmod=+x <file>"
                elif git config core.fileMode true; then
                    if [[ $(git config --type=bool core.fileMode 2>/dev/null || true) == false ]]; then
                        outranked=$(git config --show-scope --get core.fileMode 2>/dev/null || true)
                        outranked=${outranked%%[[:space:]]*}
                        add_todo "core.fileMode is still false from the ${outranked:-wider} config, which outranks this clone's own config: unset it there (for the command scope, the GIT_CONFIG_COUNT or GIT_CONFIG_PARAMETERS variable), or stage each new script with git update-index --chmod=+x <file>"
                        filemode_clause=''
                    else
                        filemode_clause=' and set it to true for this clone'
                        if [[ $filemode_scope != local ]]; then
                            say "core.fileMode was false from the $filemode_scope config: this clone's config now overrides it with true"
                        fi
                    fi
                    if ((restored_count > 0)); then
                        restored_list=$(printf '%s, ' "${restored_paths[@]:0:5}")
                        restored_list=${restored_list%, }
                        ((${#restored_paths[@]} <= 5)) || restored_list+=" and $((${#restored_paths[@]} - 5)) more"
                        say "core.fileMode was false and this filesystem keeps the executable bit as set: restored the modes of $restored_count tracked file$( ((restored_count == 1)) || echo s) ($restored_list) to the index's$filemode_clause"
                    elif [[ -n $filemode_clause ]]; then
                        say "core.fileMode was false and this filesystem keeps the executable bit as set: set it to true for this clone"
                    fi
                    if ((${#kept_paths[@]} > 0)); then
                        kept_list=$(printf '%s, ' "${kept_paths[@]:0:5}")
                        kept_list=${kept_list%, }
                        ((${#kept_paths[@]} <= 5)) || kept_list+=" and $((${#kept_paths[@]} - 5)) more"
                        say "executable on disk but 100644 in the index, so left as they are: $kept_list; they show as a mode change, and git add -A would commit them as executable"
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
# detached HEAD names no branch, so it is a TODO. A zero-byte .codeo/active holds no lock: it is removed
# first (and said so), then the step runs as for a clone with no lock; if it cannot be removed that is
# one TODO and no lock is taken. A file with content that has no line of the form `issue:`, optional
# whitespace, optional `#`s, then digits (the rule container-name.sh reads the number with) is a TODO on
# any branch: it is left as it is and takes no lock. So is a file grep cannot read. A file that does name
# an issue is a held lock and is left alone.
# When lock.sh exits 0 its output is printed unchanged, except that its `lock: TODO — …` lines become
# TODOs; when it exits non-zero its output is not printed, the one failure TODO carries it. The plugin is pinned and not ours: the `|| rc=$?` guard is
# for a crash or a changed interface after a pin bump, where a non-zero exit would otherwise end this
# script under set -e before its TODO list.
mark=${CODEO_SANDBOX_MARK:-${HOME:-}/.codeo-sandbox}
sbx_name=
branch=$(git branch --show-current 2>/dev/null || true)
base=$(jq -r '.baseBranch // "main"' .codeo/config.json 2>/dev/null || true)
[[ -n $base ]] || base=main
# A regular, non-empty .codeo/active is searched once for the rule container-name.sh reads the number with
# (`issue:`, optional whitespace, optional `#`s, then digits). active_rc stays empty when there is no such
# file, else it is grep's status: 0 names an issue, 1 does not, 2 cannot be read. The `-f &&` is there because
# a directory is out of scope of #87: `-f` keeps it out of the new TODO.
active_rc=
if [[ -f .codeo/active && -s .codeo/active ]]; then
    active_rc=0
    grep -Eq '^issue:[[:space:]]*#*[0-9]+' .codeo/active 2>/dev/null || active_rc=$?
fi
empty_stuck=
if [[ -f .codeo/active && ! -s .codeo/active ]]; then
    if rm -f .codeo/active; then
        say ".codeo/active was empty and held no lock: removed it"
    else
        empty_stuck=1
        add_todo ".codeo/active is empty and could not be removed: remove it, then re-run this script"
    fi
fi
if [[ $active_rc == 1 ]]; then
    add_todo ".codeo/active names no issue, so it holds no usable lock: look at it, remove it if it is not yours, then re-run this script"
elif [[ -n $active_rc ]] && ((active_rc >= 2)); then
    add_todo ".codeo/active could not be read, so it may hold a lock: fix its permissions or remove it, then re-run this script"
elif [[ -s .codeo/active ]]; then
    : # a directory, or a held lock: the checkout is already bound to an issue, whatever HEAD is
elif [[ -n $empty_stuck ]]; then
    : # the empty file could not be removed and lock.sh would refuse it; its own TODO is already listed
elif [[ -z $branch ]]; then
    add_todo "HEAD is detached, so no branch names an issue: check out the issue's branch, then re-run this script"
elif [[ $branch != "$base" ]]; then
    if codeo_root=$(bash .devcontainer/scripts/codeo-root.sh 2>/dev/null); then
        lock_rc=0
        lock_args=(take container)
        if [[ -e $mark ]]; then
            # Inside a sandbox the lock records the sandbox: the marker's first line, else the clone folder's name (the sandbox is named after it; lock.sh judges a bad value).
            IFS= read -r sbx_name < "$mark" || true
            [[ -n $sbx_name ]] || sbx_name=$(basename "$clone")
            if [[ -n $sbx_name ]]; then
                lock_args+=(--sandbox "$sbx_name")
            else
                add_todo "the sandbox marker names no sandbox and the clone folder has no name: the lock records a volume"
            fi
        fi
        lock_out=$(bash "$codeo_root/scripts/lock.sh" "${lock_args[@]}" 2>&1) || lock_rc=$?
        if ((lock_rc == 0)); then
            while IFS= read -r line; do
                case $line in
                    "lock: TODO — "*) add_todo "${line#lock: TODO — }" ;;
                    '') ;;
                    *) echo "$line" ;;
                esac
            done <<<"$lock_out"
        fi
        ((lock_rc == 0)) || add_todo "codeo's lock.sh failed (exit $lock_rc): ${lock_out//$'\n'/ / }"
    else
        add_todo "codeo is not installed, so no lock was taken: fix what plugins.sh printed above, then re-run this script"
    fi
fi

# 3a'. The clone folder is the container's Docker name (devcontainer.json runArgs --name), so it
# should say what the lock does; folder-check.sh judges it. Captured, not read through `< <(…)`,
# which would swallow its exit status: a check that itself fails is one TODO, never a stray error.
# Its `todo:` lines become TODOs; it prints nothing else this script passes on.
# Inside an sbx sandbox (the marker codeo-sandbox.sh writes, as session-title.sh reads it) the folder is not a
# Docker name, so this advice does not apply and the check is skipped.
if [[ -e $mark ]]; then
    :
elif folder_out=$(bash .devcontainer/scripts/folder-check.sh "$(basename "$clone")" 2>&1); then
    while IFS= read -r line; do
        case $line in
            todo:*) add_todo "${line#todo: }" ;;
        esac
    done <<<"$folder_out"
else
    add_todo "the folder check failed: ${folder_out//$'\n'/ / } — fix it and re-run this script"
fi

# 3b. Window title: write this clone's title into .vscode/settings.json. Cmd mode (CODEO_CMD_MODE set) skips it: there is no VS Code to name.
[[ -n ${CODEO_CMD_MODE:-} ]] || bash .devcontainer/scripts/window-title.sh || add_todo "window-title.sh did not finish: fix what it printed, then run bash .devcontainer/scripts/window-title.sh"

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

# 3d. Folder trust: record the clone as trusted in Claude Code's user state file, so the "Trust this folder?" dialog never appears.
# The file is $CLAUDE_CONFIG_DIR/.claude.json, else $HOME/.claude.json; a missing one is created as {} with mode 600. Only the clone's own
# key is set (.projects[<top>].hasTrustDialogAccepted), every other key kept. It runs after step 3 because `claude plugin ...` writes this file too.
# An empty or whitespace-only file counts as {}. A file that is not valid JSON, not an object, or whose projects is not an object is left untouched, and one TODO says so.
trust_key=${top:-$clone}
trust_state=${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR/.claude.json}
trust_state=${trust_state:-$HOME/.claude.json}
if [[ ! -e $trust_state ]]; then
    (umask 077 && echo '{}' > "$trust_state") 2>/dev/null || add_todo "could not create $trust_state: $trust_key is not trusted in Claude Code"
fi
if [[ -f $trust_state ]]; then
    trust_target=$(readlink -f -- "$trust_state" 2>/dev/null || true)
    trust_kind=
    [[ -z $trust_target ]] || trust_kind=$(jq -rn '[inputs] | if length == 0 then "object" elif length == 1 then (.[0] | if type != "object" then type elif has("projects") and (.projects | type) != "object" then "projects-not-object" else "object" end) else "multi" end' "$trust_target" 2>/dev/null || true)
    if [[ -z $trust_target ]]; then
        add_todo "could not resolve $trust_state: $trust_key is not trusted in Claude Code"
    elif [[ -z $trust_kind || $trust_kind == multi ]]; then
        add_todo "$trust_state is not valid JSON and was left alone: fix it, then trust $trust_key in Claude Code"
    elif [[ $trust_kind == projects-not-object ]]; then
        add_todo "$trust_state has a projects value that is not an object and was left alone: fix it, then trust $trust_key in Claude Code"
    elif [[ $trust_kind != object ]]; then
        add_todo "$trust_state is not a JSON object and was left alone: fix it, then trust $trust_key in Claude Code"
    elif trust_tmp=$(mktemp "$(dirname "$trust_target")/.claude.json.XXXXXX" 2>/dev/null); then
        if jq -n --arg p "$trust_key" '([inputs][0] // {}) | .projects[$p] = ((.projects[$p] // {}) + {hasTrustDialogAccepted: true})' "$trust_target" > "$trust_tmp" 2>/dev/null \
            && [[ -s $trust_tmp ]] \
            && chmod --reference="$trust_target" -- "$trust_tmp" 2>/dev/null \
            && mv -- "$trust_tmp" "$trust_target"; then
            :
        else
            rm -f "$trust_tmp"
            add_todo "could not write $trust_target: $trust_key is not trusted in Claude Code"
        fi
    else
        add_todo "could not write $trust_target: $trust_key is not trusted in Claude Code"
    fi
elif [[ -e $trust_state ]]; then
    add_todo "$trust_state is not a regular file and was left alone: fix it, then trust $trust_key in Claude Code"
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

# 5. Git identity: fill what the volume's config lacks, each key on its own, from the host's ~/.gitconfig
# (which VS Code copies into the container) first and then GIT_AUTHOR_NAME / GIT_AUTHOR_EMAIL. A value
# already in the volume config is never changed, a source counts only when it holds a non-empty value, and
# nothing but these two keys is read from the host file. A seeded value is not printed.
identity_missing() { [[ -z $(git config --global --get "$1" 2>/dev/null || true) ]]; }
# VS Code copies the host ~/.gitconfig in alongside postCreateCommand, so it can land after this step starts, and it can
# exist empty or half-written first: when a value is missing, wait until the file is there, not empty, and its size and
# mtime are the same on two reads 0.2 s apart, for at most CODEO_GITCONFIG_WAIT seconds (default 10; a value that is not a
# whole number is taken as 10, so a typo cannot stop this script; 0 does not wait). A file that never fills falls
# through to the environment. A volume that already holds the identity never waits.
gitconfig_stamp() { stat -c '%s %y' "$HOME/.gitconfig" 2>/dev/null || true; }
# Cmd mode (CODEO_CMD_MODE set) never waits: no VS Code is there to copy the host file in.
if { identity_missing user.name || identity_missing user.email; } && [[ -z ${CODEO_CMD_MODE:-} ]]; then
    ticks=0
    wait_max=${CODEO_GITCONFIG_WAIT:-10}
    [[ $wait_max =~ ^[0-9]+$ ]] || wait_max=10
    stamp=$(gitconfig_stamp)
    while ((ticks < 10#$wait_max * 5)); do
        sleep 0.2
        ticks=$((ticks + 1))
        now=$(gitconfig_stamp)
        if [[ -s $HOME/.gitconfig && $now == "$stamp" ]]; then break; fi
        stamp=$now
    done
fi
for pair in user.name:GIT_AUTHOR_NAME user.email:GIT_AUTHOR_EMAIL; do
    key=${pair%%:*}
    var=${pair#*:}
    identity_missing "$key" || continue
    value=$(git config --file "$HOME/.gitconfig" --get "$key" 2>/dev/null || true)
    # shellcheck disable=SC2088 # a label for the report, not a path
    from='~/.gitconfig'
    if [[ -z $value ]]; then
        value=${!var:-}
        from=$var
    fi
    [[ -n $value ]] || continue
    if git config --global "$key" "$value"; then
        say "git identity: $key set from $from"
    fi
done
# What is still missing is judged on the effective identity, as before: a repository-level one counts.
missing_keys=()
[[ -n $(git config user.name || true) ]] || missing_keys+=(user.name)
[[ -n $(git config user.email || true) ]] || missing_keys+=(user.email)
if ((${#missing_keys[@]} > 0)); then
    missing_list=$(printf '%s, ' "${missing_keys[@]}")
    add_todo "git identity is not set (missing: ${missing_list%, }; tried ~/.gitconfig, then GIT_AUTHOR_NAME / GIT_AUTHOR_EMAIL): run git config --global user.name 'Your Name' and git config --global user.email you@example.com"
fi

# 6. Claude Code login.
# Remote Control needs a claude.ai login, so these credentials must not be set. The output is captured before it is read.
# While CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY is set the check is skipped: the variable overrides any login, so
# `claude auth login` would not help, and the "unset it" TODO below is the advice.
if [[ -z ${CLAUDE_CODE_OAUTH_TOKEN:-} && -z ${ANTHROPIC_API_KEY:-} ]]; then
    # Run from $HOME, the way plugins.sh's claude_out does, so claude does not touch the clone.
    if claude_status=$(cd "$HOME" && claude auth status 2>&1); then
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
