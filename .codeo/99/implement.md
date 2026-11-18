# Issue #99 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/99 |
| Branch | `feat/make-sbx-issue-sandbox-usable` |
| Plan | `docs/plans/2026-11-17-sbx-issue-sandbox.md` |
| Updated | 2026-11-17 |

## Where this stands

Round 2 (after plan.md round 2), finished; Task 22 partly run (2026-11-18): steps 1-9 and 12 are under `## Acceptance`, steps 10 and 11 are owed on 2026-11-19, step 13 is not run. Two findings from the run go to `/codeo:qc`: `remote.SSH.defaultExtensions` is blocked by the sbx network policy, and `issue` never runs `run -d`, so sandboxes stop when idle. Next: steps 10-11, then `/codeo:qc`.

## Questions

None.

## Trials

_Task 5 — the engineer's output for S1-S9 (WSL2 bash, Ubuntu-24.04), with tokens and account names removed._

**S1, first attempt.** The plan's `<user>` placeholder was pasted as it was, so `create` refused:

```
    ○ claude — now ships as a kit; resolving docker.io/sbx/claude:latest

  error: --clone cannot use \\wsl.localhost\Ubuntu-24.04\home\<user>\Source\codeo-sbx-t as a Git repository: git failed: fatal: detected dubious ownership in repository at '//wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-t'
    try: git.exe config --global --add safe.directory "%(prefix)///wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-t"
```

- The `claude` agent is now a kit, and it resolves `docker.io/sbx/claude:latest`.
- `create`'s own hint uses the same `safe.directory` form that Task 8 writes.

**S1, retry** (sbx v0.53.0; v0.54.0 was offered):

```
    ○ claude — now ships as a kit; resolving docker.io/sbx/claude:latest
    ✓ workspace — Git repository at \\wsl.localhost\Ubuntu-24.04\home\<user>\Source\codeo-sbx-t

  SANDBOX
    Name:       codeo-t
    Agent:      claude
    Kit:        docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332
    Workspace:  \\wsl.localhost\Ubuntu-24.04\home\<user>\Source\codeo-sbx-t → /wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-t (rw)
    Skills:     0 entries · read-only
      Source:   ~\AppData\Local\DockerSandboxes\sandboxes\state\agent-skills
      Target:   /home/agent/.claude/skills
    Image:      docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332
    CPU:        20
    Memory:     32 GiB

  IMAGE
    ✓ image — ready
    Git daemon:  git://127.0.0.1:60011/codeo-sbx-t
    Remote:      sandbox-codeo-t

    ✓ Created sandbox codeo-t
        source \\wsl.localhost\Ubuntu-24.04\home\<user>\Source\codeo-sbx-t → /run/sandbox/source (ro)
        try: sbx run --name codeo-t
```

- **A third digest.** On 2026-11-17 `:latest` resolved to `fd56087a…`, which matches neither `4df39400…` (T3/T8) nor `0fb3e2c5…` (T10). `Kit:` and `Image:` carry the same full digest, so it is the reference Task 10 pins. The engineer did not say whether the T3, T8 and T10 output survives, so the page keeps those two digests as recorded, shortened.
- **The default size is the whole host,** 20 CPUs and 32 GiB, which is why Task 8 passes `--cpus 2 --memory 4g`.
- **The working folder inside is the host path made POSIX:** `/wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-t` (rw). The read-only source is at `/run/sandbox/source`. S3's `pwd` shows which of the two `exec` starts in.
- `create` adds a git remote, `sandbox-codeo-t`, to the host clone, served by the Git daemon on `127.0.0.1`.

**S2.**

```
gh auth token                              → gho_<real token, not pasted>
sbx.exe exec codeo-t gh auth token         → gho_sbxproxymanaged000000000000000000000
sbx.exe exec codeo-t printenv GH_TOKEN     → gho_sbxproxymanaged000000000000000000000
```

The sandbox never holds the real token. `gh` and `GH_TOKEN` inside it both see the same 40-character placeholder, `gho_sbxproxymanaged` padded with zeros. sbx's proxy presumably swaps in the real credential on the way out. S4 shows whether a push works with it.

**S3.**

```
sbx.exe exec codeo-t git config user.name       → (nothing)
sbx.exe exec codeo-t git config user.email      → (nothing)
sbx.exe exec codeo-t printenv REMOTE_CONTAINERS → (nothing)

    ✓ sandbox codeo-t — started

ls: cannot access '/.dockerenv': No such file or directory
agent
/wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-t
```

- **No git identity inside.** `user.name` and `user.email` are unset. Task 8 already handles this: it passes `GIT_AUTHOR_*` to the start script. Step 5 of that script writes them to `git config --global`, which covers the committer too.
- **Nothing marks it as a container:** no `REMOTE_CONTAINERS` and no `/.dockerenv`. The plan handles `REMOTE_CONTAINERS` with Task 9's marker. It does not handle `/.dockerenv`. Without that file, `role.sh` (line 55) classifies a sandbox as `unguarded`, so the codeo skills run there with no role check. That is permissive, not broken: it loses the issue-folder guard, but blocks nothing. To decide after S5: does `role.sh` also accept the sandbox marker? That is a change outside the plan's footprint.
- `exec` runs as `agent`, in the working folder: the host path made POSIX, not `/run/sandbox/source`.
- The sandbox had stopped between S2 and S3, and the first `exec` started it again. Recorded for #86's unexplained stops.

**S4.**

```
sbx.exe exec codeo-t gh auth setup-git                                       → (nothing)

    ✓ sandbox codeo-t — started

sbx.exe exec codeo-t git push origin HEAD:refs/heads/scratch/sbx-push-test
To https://github.com/<owner>/codeo
 * [new branch]      HEAD -> scratch/sbx-push-test
sbx.exe exec codeo-t git fetch origin
 * [new branch]      … (3 branches)
sbx.exe exec codeo-t git push origin --delete scratch/sbx-push-test
 - [deleted]         scratch/sbx-push-test
```

- **A push over HTTPS works from inside the sandbox,** although it holds only the placeholder token from S2. `gh auth setup-git` makes `gh` the credential helper, and sbx's proxy puts the real token on the request. A push needs no token copied in and no extra step after `create`, apart from `gh auth setup-git`.
- **The sandbox had stopped again between S3 and S4,** and the first `exec` started it. Both times it stopped while idle between two batches of commands. That points to an idle stop rather than a crash, and it bears on #86.

**S5** (the start script from `main`, so without step 3d):

```
sbx.exe exec codeo-t env CODEO_CMD_MODE=1 bash .devcontainer/scripts/devcontainer-start.sh

    ✓ sandbox codeo-t — started

plugins: installed superpowers
plugins: installed codeo v1.0.6
plugins: superpowers, codeo v1.0.6
devcontainer-start: TODO — this container's folder is 'codeo-sbx-t' but its clone is on main with no lock, so it is the home container and 'docker ps' names it wrongly: remove it and open it again with the folder 'codeo-home' (.devcontainer/README.md)
devcontainer-start: TODO — git identity is not set (missing: user.name, user.email; tried ~/.gitconfig, then GIT_AUTHOR_NAME / GIT_AUTHOR_EMAIL): run git config --global user.name 'Your Name' and git config --global user.email you@example.com
sbx.exe exec codeo-t claude plugin list
  ❯ codeo@codeo                            1.0.6  user  ✔ enabled
  ❯ superpowers@superpowers-marketplace    7.0.2  user  ✔ enabled
```

- **The start script runs unchanged inside a sandbox.** It installs both plugins, and it raises no TODO about the GitHub login, the Claude login or Remote Control. Only two TODOs come out, both expected for this trial:
  - the folder name, because `codeo-sbx-t` is on `main` with no lock;
  - the git identity, because this trial passed no `GIT_AUTHOR_*`. That confirms Task 8 must pass them.
- **The sandbox had stopped a third time,** again in the gap before the batch.

**S6, first attempt.**

```
sbx.exe exec codeo-t bash .devcontainer/scripts/window-title.sh

    ✓ sandbox codeo-t — started

window-title: codeo [home]
cmd.exe /c code --folder-uri vscode-remote://ssh-remote+codeo-t.sbx/home/<user>/Source/codeo-sbx-t
'\\wsl.localhost\Ubuntu-24.04\home\<user>\Source\codeo-sbx-t'
CMD.EXE was started with the above path as the current directory.
UNC paths are not supported.  Defaulting to Windows directory.
```

- `window-title.sh` runs in the sandbox and gives `codeo [home]`, as expected for a clone on `main` with no lock.
- **The URI used the WSL path from the host's `pwd`, not the sandbox's working folder** (S3: `/wsl.localhost/…`). Task 11 has to build the URI from the sandbox's path, not from the host's `$PWD`.
- `cmd.exe` started from a WSL folder warns `UNC paths are not supported` and falls back to the Windows folder. The warning is harmless, but Task 11 should run `cmd.exe` from a Windows folder (`cd /mnt/c`) so the user doesn't see it.
- Whether VS Code opened: _pending the retry._

**S6, retry with the sandbox's path** (from `/mnt/c`). VS Code opened a window and asked for the remote platform ("Select the platform of the remote host "codeo-t.sbx""). It then failed: `Could not establish connection to "codeo-t.sbx": Could not resolve hostname`, and Remote - SSH logged `OfflineError (Could not resolve hostname)`. In T12, `codeo-a.sbx` resolved after `sbx.exe setup ssh`. The Windows `~/.ssh/config` entry for `*.sbx` is either missing now or no longer applies. 

**S6, after `sbx.exe setup ssh`.**

```
  SSH
    Status:  ● enabled · signed in as <user>
    Access:  *.sbx -> sandboxd.sock (no port · login-gated)
  …
  You can safely re-run sbx setup ssh to reconfigure
  warning: sh is not available on PATH. Claude Desktop runs the SSH ProxyCommand through sh on Windows. …
ssh.exe codeo-t.sbx -- pwd
/wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-t
cmd.exe /c code --folder-uri …   → (nothing printed; no UNC warning from /mnt/c)
```

- Re-running `setup ssh` is safe, and afterwards `ssh.exe` resolves `codeo-t.sbx`. Its login shell starts in the working folder. `setup ssh` was not tested on its own before this re-run, so it is not known which case caused the earlier failure: an entry that was never written, one that `sbx` removed, or VS Code's own resolution.
- The `sh` warning is about Claude Desktop, not VS Code or `ssh.exe`.
- **What VS Code showed** (screenshot): it connected (status bar `SSH: codeo-t.sbx`, branch `main`) and opened the clone folder by itself: Explorer `codeo-sbx-t [SSH: codeo-t.sbx]`, with the repository's top-level folders. The window title is `codeo [home]`, so the `window.title` that `window-title.sh` wrote into `.vscode/settings.json` takes effect over Remote - SSH (this answers U13). The activity bar shows Remote Explorer and GitHub. Extensions on the remote side (screenshot, Extensions view): `SSH: Codeo-T.Sbx - Installed` lists 1, GitHub Pull Requests, the same as T12. Claude Code, ShellCheck and Markdown Mermaid are not there. `Local - Installed` lists 37, and `Recommended` lists 7.
- **What this means for Task 11.** `--folder-uri vscode-remote://ssh-remote+codeo-<N>.sbx<sandbox working path>` opens the folder, if two things hold:
  - the path is the sandbox's own working folder (`ssh.exe codeo-<N>.sbx -- pwd`, or S1's `Workspace:` target), not the host's `$PWD`;
  - `*.sbx` resolves, which `sbx.exe setup ssh` makes so and which is safe to re-run.

**S7.**

- **The engineer's run gave no answer.** It ran in WSL bash, not in a dev container, and the plan's path was wrong anyway:

  ```
  jq .projects /home/dev/.claude/.claude.json
  jq: error: Could not open file /home/dev/.claude/.claude.json: No such file or directory
  ```

- **The answer came from this session's dev container,** `codeo-99`. Its folder was trusted by hand in Claude Code's dialog. There `CLAUDE_CONFIG_DIR=/workspaces/.claude`, so the file is `/workspaces/.claude/.claude.json` (mode 600, owner `dev`), and `$HOME/.claude.json` does not exist.

  ```
  jq '.projects | with_entries(.value |= {hasTrustDialogAccepted})' /workspaces/.claude/.claude.json
  {
    "/workspaces/codeo-99": {
      "hasTrustDialogAccepted": true
    }
  }
  ```

- **This confirms what Task 1's step 3d writes:**
  - the file is `$CLAUDE_CONFIG_DIR/.claude.json`;
  - the key is the clone's exact top-level path;
  - the field is `hasTrustDialogAccepted: true`, merged into the project's existing entry.

**S8** (sbx v0.53.0 help text; what bears on the plan):

- **`create`:**
  - `create AGENT|SANDBOX_KIT [PATH...]`: "The first positional argument may be a built-in agent name or a sandbox kit reference", and kit references may be "OCI references".
  - `-t, --template string`: "Container image to use for the sandbox (default: agent-specific image)".
  - `--kit`: mixins only, experimental.
  - `kit.shortcuts.claude`: a global setting that maps the agent name to a kit reference.
  - `--pull always|missing|never`.
  - `-e, --env` and `--env-file`: "Set an environment variable in the sandbox", kept with it.
  - `--cpus` (0 = all host CPUs) and `-m, --memory` ("Default: 50% of host memory, clamped to 512 MiB–32 GiB").
  - `--name` (2-63 characters).
  - `--clone`: "the agent's commits are accessible via the sandbox-<name> git remote on the host".
- **`exec`:**
  - "If the sandbox is stopped, it is started first", which matches the `started` lines in S2-S6.
  - `-e/--env`, `--env-file`, `-w/--workdir` and `-u/--user`.
  - "sbx exits 125 if it could not run the command, for example because the sandbox does not exist. A missing command exits 127."
- **`rm`:**
  - "stops them, removes their containers, **removes any Git remote added to the host repository for them**, deletes sandbox state … This action cannot be undone."
  - "Removal requires confirmation; use `-f, --force` to skip confirmation prompts (for non-interactive scripts) and to delete a sandbox that is in use (e.g. an open SSH connection)."
  - `--json` and `--format`.
- **`template`:** `save`, `load`, `ls`, `inspect` and `rm`. A template is a saved snapshot of a sandbox, used through `-t`.
- **Global flags:** `--no-input` ("Never prompt; commands that need an answer fail with the command to run instead") and `-D, --debug`.

**S9, first attempt** (the VS Code window from S6 was still connected):

```
sbx.exe exec codeo-t git -c user.name=t -c user.email=t@example.com commit --allow-empty -m scratch
[main 82a2f9b] scratch
git fetch sandbox-codeo-t
fatal: unable to connect to 127.0.0.1:
127.0.0.1[0: 127.0.0.1]: errno=Connection refused
git for-each-ref refs/sandboxes
e9988133afc619d07de524e376bbd6eb3a3da934 commit refs/sandboxes/codeo-t/main
sbx.exe rm codeo-t

  warning: sandbox "codeo-t" runs on an in-container clone (--clone); commits the agent made inside it are lost on removal unless fetched first (fetched branches are mirrored into refs/sandboxes/codeo-t/* and survive removal; recover one with `git branch LOCAL refs/sandboxes/codeo-t/BRANCH`), or ask the agent to push them to an upstream remote
    try: git fetch sandbox-codeo-t

  Remove sandbox 'codeo-t'? This cannot be undone. (y/N) y

  error: sandbox 'codeo-t' is in use (e.g. an open SSH connection); close it or re-run with --force
```

- **WSL's `git fetch` cannot reach the sandbox's Git daemon** (connection refused on `127.0.0.1`). The daemon listens on the Windows side (S1: `git://127.0.0.1:60011/…`), and WSL2's `127.0.0.1` is not Windows's unless networking is mirrored. A second possibility is that the port changed when the sandbox restarted. The retry checks both with `git remote get-url` and `git.exe fetch`.
- `refs/sandboxes/codeo-t/main` exists without a successful fetch, at `e9988133`, and does not include `82a2f9b`. sbx seems to have written it at create time.
- **`rm`'s warning** is printed for every `--clone` sandbox, whether or not it holds unfetched commits. It points to `git fetch sandbox-<name>` and `refs/sandboxes/<name>/*`.
- **`rm` refuses a sandbox that is in use,** even after `y`. An open VS Code Remote - SSH window counts as in use. `--force` overrides this. Task 12's `end` has to say so rather than fail without explanation.

**S9, retry** (VS Code window closed):

```
git remote get-url sandbox-codeo-t
git://127.0.0.1:60017/codeo-sbx-t
git.exe fetch sandbox-codeo-t
From git://127.0.0.1:60017/codeo-sbx-t
 * [new branch]      main       -> sandbox-codeo-t/main
   e998813..82a2f9b  main       -> refs/sandboxes/codeo-t/main
git for-each-ref refs/sandboxes
82a2f9bce33c30c5f929932189feb8c0dddda621 commit refs/sandboxes/codeo-t/main
sbx.exe rm codeo-t
  warning: … (as above)
  Remove sandbox 'codeo-t'? This cannot be undone. (y/N) y
  Removed sandbox codeo-t
git remote -v
origin  https://github.com/<owner>/codeo (fetch)
origin  https://github.com/<owner>/codeo (push)
git for-each-ref refs/sandboxes
82a2f9bce33c30c5f929932189feb8c0dddda621 commit refs/sandboxes/codeo-t/main
```

- **The Git daemon's port changes when the sandbox restarts** (60011 at create, 60017 now), and sbx rewrites the remote's URL to follow it.
- **From WSL, only Windows Git reaches it.** `git.exe fetch sandbox-<name>` works, where WSL's `git fetch` is refused. On WSL (`windows=1`), Task 12's `end` fetches with `git.exe`.
- **The fetch mirrors each branch into `refs/sandboxes/<name>/<branch>`** and into the remote-tracking `sandbox-<name>/<branch>`.
- **`rm` removes the `sandbox-<name>` remote.** `refs/sandboxes/<name>/*` survive it, so the commit made inside is still reachable afterwards (`82a2f9b`).

**S10 (added during the trials): `create` from a pinned digest, passed as the kit reference.**

```
sbx.exe create --clone --name codeo-p --cpus 2 --memory 4g docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332 .
  SANDBOX
    Name:       codeo-p
    Agent:      claude
    Kit:        docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332
    Image:      docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332
    CPU:        2
    Memory:     4g
  AGENT
    ✓ assembled kit image ready (cached)
    Git daemon:  git://127.0.0.1:60018/codeo-sbx-t
    Remote:      sandbox-codeo-p
    ✓ Created sandbox codeo-p
sbx.exe exec codeo-p claude --version
2.1.326 (Claude Code)
sbx.exe rm --force codeo-p
  warning: … (as in S9)
  Removed sandbox codeo-p
```

- **The full digest works as the kit reference** in place of `claude`:
  - the agent is still `claude`;
  - `Kit:` and `Image:` both carry the pinned digest;
  - the line `now ships as a kit; resolving …:latest` no longer appears.
- `--cpus 2 --memory 4g` take effect.
- **`rm --force` removes without a prompt,** but it still prints the warning.

### Decisions

- **D-token:** a **placeholder**. The sandbox's `gh auth token` and `GH_TOKEN` are both `gho_sbxproxymanaged000000000000000000000`; the real token stays on the host (S2). A push with it works (S4).
- **D-start:** **yes.** The unchanged `devcontainer-start.sh` ran in the sandbox and installed both plugins. It raised exactly two TODOs, both expected for the trial: the folder name (on `main`, no lock) and the git identity (none passed) (S5).
- **D-exec:**
  - working folder: `exec` runs as `agent` in the sandbox's working folder, which is the host path made POSIX, `/wsl.localhost/<distro>/<path>` (S3).
  - flags: `exec` takes `-e`, `-w` and `-u`, starts a stopped sandbox, and exits 125 when it cannot run (S8).
  - the plan keeps `env VAR=… bash …`.
- **D-image:**
  - the pin is passed as `create`'s first positional argument, the kit reference, in place of `claude` (S10);
  - the pinned reference is `docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332` (S1, 2026-11-17);
  - `-t` was not needed.
- **D-rm:**
  - `sbx rm --force <name>` skips the prompt (S8, S10);
  - it also removes a sandbox that is in use, while plain `rm` refuses one with an open SSH connection (S9);
  - it removes the `sandbox-<name>` remote and keeps `refs/sandboxes/<name>/*` (S9).
- **D-open:** **yes, with two conditions** (S6):
  - `code --folder-uri vscode-remote://ssh-remote+codeo-<N>.sbx<path>` opened the folder, and `window.title` took effect;
  - `<path>` is the sandbox's working folder, `/wsl.localhost/$WSL_DISTRO_NAME<host path>` on WSL, not the host's `$PWD`;
  - `*.sbx` must resolve through `sbx setup ssh`; `ssh.exe <name>.sbx -- true` checks it.
  - Only GitHub Pull Requests is installed on the remote side.
- **D-push:** **yes.** After `gh auth setup-git`, push, fetch and branch delete all work from inside (S4).

### Rulings from the trials, for the tasks still to run

- **Task 8:**
  - On WSL the sandbox's working folder is `/wsl.localhost/$WSL_DISTRO_NAME$(pwd -P)`. Task 8 computes the same path for `safe.directory`.
  - No change to the plan. The start script already runs `gh auth setup-git` (`devcontainer-start.sh:341`), Task 8 already passes `GIT_AUTHOR_*`, and step 5 writes the global identity.
- **Task 10:** pass the pin as the kit reference: `create --clone --name codeo-N --cpus 2 --memory 4g "$(cat .sbx/claude-image)" .`. The file holds the S1 digest.
- **Task 11:**
  - The folder URI uses the sandbox's working folder (the D-exec path), not the host's `$PWD`.
  - Before opening, `open` runs `ssh.exe codeo-N.sbx -- true` (`ssh` off WSL). If that fails, it stops and tells the user to run `sbx setup ssh`.
  - On WSL, `cmd.exe` runs from `/mnt/c`, so the UNC warning does not appear.
  - Cost if wrong: one `open` that stops early.
- **Task 12:**
  - `end` fetches with `git.exe` when `windows=1`.
  - It removes with `rm --force` only when the user passes `--force`. Otherwise it answers the prompt itself, and when `rm` reports the sandbox is in use it tells the user to close the VS Code window.
  - This keeps the plan's rule that `--force` is the user's choice.
- **`role.sh` (outside the footprint):** a sandbox has no `/.dockerenv`, so `role.sh` classifies it as `unguarded`.
  - Effect: the skills run there with no role check. That is permissive and blocks nothing.
  - Ruling: left unchanged for this round, and reported in the Outcome as a gap for its own issue.
  - Cost if wrong: an issue sandbox can run home-only skills.

- **The `--folder-uri` form reaches Remote - SSH and names the right host.** Opening the folder depends on `*.sbx` resolving through Windows OpenSSH's config, which `sbx setup ssh` writes. That command is marked experimental. Task 11's `open` therefore has to check that the host resolves (`ssh.exe <name>.sbx -- true`), and if it does not, point the user to `sbx.exe setup ssh` rather than open a window that fails.
- **VS Code asks for the platform** the first time it connects to each host. A new `codeo-<N>.sbx` asks again unless `remote.SSH.remotePlatform` maps it, or a `*.sbx` pattern covers it.

## Acceptance

Task 22 (round 2 plan), run by the engineer on their Windows host from WSL2, in `D:\Downloads	ask22`. The outputs are pasted as given, with the sbx banner art left out.

### Step 2 — `bash codeo-sandbox.sh issue 99 feat/make-sbx-issue-sandbox-usable` (2026-11-18)

```
Cloning into 'codeo-99'...
…
    ✓ workspace — Git repository at D:\Downloads	ask22\codeo-99
  SANDBOX
    Name:       codeo-99
    Agent:      claude
    Kit:        docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332
    Workspace:  D:\Downloads	ask22\codeo-99 → /d/Downloads/task22/codeo-99 (rw)
    Image:      docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332
    CPU:        2
    Memory:     4g
    ✓ Created sandbox codeo-99
    … (banner: base Debian 13 (trixie), egress gateway proxy, kits claude 2.1.326)
plugins: installed superpowers
plugins: installed codeo v1.0.6
plugins: superpowers, codeo v1.0.6
lock: took the lock for #99 on feat/make-sbx-issue-sandbox-usable
devcontainer-start: git identity: user.name set from GIT_AUTHOR_NAME
devcontainer-start: git identity: user.email set from GIT_AUTHOR_EMAIL
devcontainer-start: TODO — could not read the workspace volume's name from /proc/self/mountinfo: fill the lock's volume line in by hand (docker volume ls on the host)
```

- Step 1 (download of `codeo-sandbox.sh` alone, no `claude-image` beside it) worked: `issue` created at the digest in `.sbx/claude-image` (`fd56087a…3593332`), which was read from the clone.
- No `dubious ownership`.
- The lock line is not the last line. Two identity lines and one TODO follow it. The TODO comes from `scripts/lock.sh:145`: a sandbox's workspace is a bind mount, not a Docker volume, so the lock's `volume:` line is left for the user. `scripts/` is out of this plan's scope; noted for `/codeo:qc`.

### Step 2a — role check

```
$ sbx.exe exec codeo-99 test -e /run/.containerenv; echo $?

    ✓ sandbox codeo-99 — started

1
$ sbx.exe exec codeo-99 bash .devcontainer/scripts/role.sh
unguarded
```

- The sandbox has no `/run/.containerenv`, and `role.sh` prints `unguarded` there, so it has no `/.dockerenv` either. This confirms the `role.sh` gap: codeo's skills run in a sandbox with no role check. It is out of this plan's scope (`role.sh` markers); noted for `/codeo:qc`.
- `sbx exec` printed `sandbox codeo-99 — started`. The sandbox had stopped by itself between step 2 and this step, with no `stop` issued. This is evidence for "Stopped sandboxes" (step 9).

### Step 3 — identity, and a rerun that creates nothing

```
$ sbx.exe exec codeo-99 git config user.name

    ✓ sandbox codeo-99 — started

<the engineer's name>
$ sbx.exe exec codeo-99 git config user.email
<the engineer's email>
$ bash codeo-sandbox.sh issue 99 feat/make-sbx-issue-sandbox-usable
plugins: superpowers, codeo v1.0.6
devcontainer-start: ready
$ sbx.exe exec codeo-99 git config user.name
<the engineer's name>
$ sbx.exe exec codeo-99 git config user.email
<the engineer's email>
```

The name and email are redacted here; they are the engineer's GitHub identity.
- Both values print, and the rerun leaves them unchanged.
- The rerun created nothing: no clone, no create, no clone fetch (the sandbox existed).
- The sandbox had stopped by itself again before the first `exec`.

### Step 4 — plugins

```
$ sbx.exe exec codeo-99 claude plugin list

    ✓ sandbox codeo-99 — started

Installed plugins:
  ❯ codeo@codeo
    Version: 1.0.6
    Scope: user
    Status: ✔ enabled
  ❯ superpowers@superpowers-marketplace
    Version: 7.0.2
    Scope: user
    Status: ✔ enabled
```

- codeo is at the pin in `.codeo/config.json` (`plugin.ref` `v1.0.6`).
- `.codeo/config.json` does not pin superpowers. The installed copy is 7.0.2, the same version this session runs.
- The sandbox had stopped by itself a third time.

### Step 5 — push from inside, no login

```
$ sbx.exe exec codeo-99 git push origin HEAD:refs/heads/scratch/sbx-99-push

    ✓ sandbox codeo-99 — started

remote:
remote: Create a pull request for 'scratch/sbx-99-push' on GitHub by visiting:
remote:      https://github.com/kbajpai/codeo/pull/new/scratch/sbx-99-push
remote:
To https://github.com/kbajpai/codeo.git
 * [new branch]      HEAD -> scratch/sbx-99-push
$ git -C codeo-99 push origin --delete scratch/sbx-99-push
To https://github.com/kbajpai/codeo.git
 - [deleted]         scratch/sbx-99-push
```

- The push from inside the sandbox succeeded with no login prompt.
- The scratch branch is deleted.
- The sandbox had stopped by itself a fourth time.

### Step 6 — VS Code

```
$ bash codeo-sandbox.sh open 99

    ✓ sandbox codeo-99 — started

window-title: codeo [#99]
$ sbx.exe exec codeo-99 git status --short
$ sbx.exe exec codeo-99 git log --oneline -3
87c72ad docs(codeo): implement dossier for #99 — round 2
1a942c2 docs: correct the sbx route's end and pin wording (#99, #86)
0baf43c docs: the sbx route's pin source, clone refresh and ref handling (#99, #86)
```

- The first `open` attempt was redone. The engineer judged it to have gone wrong; `open` has no side effects to undo beyond the title it rewrites.
- The sandbox's tree is clean, and its `HEAD` is `87c72ad`, the pushed tip.
- The sandbox had stopped by itself a fifth time.

Screenshot from the engineer, of the VS Code window after `open`:
- The window title is `codeo [#99]`.
- The Explorer shows `codeo-99 [SSH: codeo-99.sbx]`.
- The status bar shows `SSH: codeo-99.sbx` and the branch `feat/make-sbx-issue-sandbox-usable`.
- A Dev Containers toast offers "Reopen in Container" because the folder holds `.devcontainer/`. Taking it would leave the sandbox route. `.sbx/README.md` does not mention it yet.

Screenshot from the engineer, of the Extensions view:
- "SSH: Codeo-99.Sbx - Installed" lists one extension, GitHub Pull Requests (GitHub).
- None of the three in `.sbx/README.md:16` (`anthropic.claude-code`, `timonwong.shellcheck`, `bierner.markdown-mermaid`) is installed on the sandbox side.
- "Local - Installed" shows 37. The check of the user setting `remote.SSH.defaultExtensions` is pending.

- Cause: the engineer's VS Code user settings had no `remote.SSH.defaultExtensions` key, so the prerequisite in `.sbx/README.md:16` was not set up. This is not a script fault. `remote.SSH.remotePlatform` already maps `codeo-99.sbx` to `linux`. The check is redone after the setting is added.

After `remote.SSH.defaultExtensions` was added and `open 99` rerun, the engineer sent a screenshot:
- "SSH: Codeo-99.Sbx - Installed" lists 0 extensions.
- VS Code reported: `Failed to connect to the remote extension host server (Error: ExtensionInstallFailed(... Server returned 403 / Server returned 403 / Server returned 403 / Failed Installing Extensions: anthropic.claude-code, timonwong.shellcheck, bierner.markdown-mermaid))`.
- **Not met.** The VS Code server inside the sandbox fetches extensions from the marketplace, and gets 403 three times. That matches the egress proxy refusing a host outside the `balanced` allow list (evaluation page D9/T11: a blocked host gets an immediate 403). The plan and `.sbx/README.md` assumed the setting was enough. Diagnosis in progress.

```
$ sbx.exe exec codeo-99 curl -sS -o /dev/null -w "%{http_code}
" https://marketplace.visualstudio.com/
200
$ sbx.exe exec codeo-99 curl -sS -o /dev/null -w "%{http_code}
" https://open-vsx.org/
403
```
- The marketplace front page is allowed, so the 403 comes from another host the install uses. The candidates are the gallery API and the VSIX CDN.

```
$ sbx.exe exec codeo-99 curl … https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery
405
$ sbx.exe exec codeo-99 curl … https://anthropic.gallery.vsassets.io/
403
$ sbx.exe exec codeo-99 curl … https://anthropic.gallerycdn.vsassets.io/
403
$ sbx.exe exec codeo-99 curl … https://update.code.visualstudio.com/
200
$ sbx.exe exec codeo-99 sh -c "grep -ho 'https://…' ~/.vscode-server/data/logs/*/remoteagent.log | …"
(nothing)
```
- **Cause.** The gallery API answers (405 to a GET), but the hosts that serve the extension files, `*.gallery.vsassets.io` and `*.gallerycdn.vsassets.io`, get the proxy's 403. The sandbox's `balanced` network policy does not allow them. As a result, `remote.SSH.defaultExtensions` cannot install anything on the sandbox side.
- This is a finding against the plan. The README's extension step does not work under the default policy. Two fixes are possible: `remote.downloadExtensionsLocally` (VS Code fetches on the host and copies the files in), or allowing `*.gallery.vsassets.io` and `*.gallerycdn.vsassets.io` in the sbx policy.

With `"remote.downloadExtensionsLocally": true` added and `open 99` rerun, the engineer's screenshot shows:
- The same `ExtensionInstallFailed … Server returned 403 ×3` for all three extensions.
- A second error, `Could not fetch remote environment`.
- 0 extensions installed on the SSH side. The Explorer no longer shows the folder.

`remote.downloadExtensionsLocally` does not cover `remote.SSH.defaultExtensions`. The VS Code server installs those itself at start-up, from inside the sandbox. The failed install also stops the remote extension host from starting, which is worse than having no setting at all: before the key was added, the window worked with no extensions.

The engineer removed `remote.SSH.defaultExtensions`, kept `remote.downloadExtensionsLocally: true`, reran `open 99`, and installed Claude Code by hand with "Install in SSH: codeo-99.sbx". Screenshot:
- "SSH: Codeo-99.Sbx - Installed" lists 2: Claude Code for VS Code (Anthropic) and GitHub Pull Requests.
- No error toasts. The title is `codeo [#99]` and the status bar shows `SSH: codeo-99.sbx`, the branch and `Claude Code`.

**Workaround found.** With `remote.downloadExtensionsLocally`, an extension installed from the window is downloaded on the host and copied into the sandbox, so it never meets the sandbox's network policy. `remote.SSH.defaultExtensions` cannot be used under the default policy, because the server installs that list itself and is blocked. The plan's "one step opens VS Code … with the three extensions" is therefore not met as written. The route the README should give is to set `remote.downloadExtensionsLocally` and install the three by hand (once per sandbox), or to allow `*.gallery.vsassets.io` and `*.gallerycdn.vsassets.io` in the sbx policy.

Screenshot from the engineer, of `claude` running in the window's terminal:
- The terminal tab title is `✳ codeo [#99] · b7178c8d - codeo-99`, so the session title starts with `codeo [#99]` (met).
- Claude Code is v2.1.326, `/d/Downloads/task22/codeo-99`. The prompt shows "bypass permissions on", which is the sandbox kit's default.

**Step 6 summary:**
- Folder: met.
- Window title `codeo [#99]`: met.
- Session title: met.
- Three extensions: **not met** as planned. `remote.SSH.defaultExtensions` is blocked by the sbx network policy; the workaround is above.

### Step 7 — a second sandbox (N2 = 122 on `main`; no other issue has a branch on origin)

```
$ bash codeo-sandbox.sh issue 122 main
Cloning into 'codeo-122'...
…
codeo-sandbox: no image pin: set CODEO_SBX_IMAGE to a file, or commit codeo-122/.sbx/claude-image, or put .sbx/claude-image on origin/HEAD (git show origin/HEAD:.sbx/claude-image)
$ bash codeo-sandbox.sh open 122
codeo-sandbox: codeo-122 does not exist: create it with codeo-sandbox.sh issue 122 <branch>
```

- This is correct behaviour, and it exercises Task 15's no-pin refusal on a real host. `main` (origin/HEAD) does not carry `.sbx/claude-image` until this branch merges, so neither the clone nor `origin/HEAD` has a pin. The refusal is one line naming all three sources, and nothing is created.
- The run is repeated with `CODEO_SBX_IMAGE` pointing at `codeo-99/.sbx/claude-image`.

The engineer reran with `CODEO_SBX_IMAGE=codeo-99/.sbx/claude-image bash codeo-sandbox.sh issue 122 main`, then `open 122`. Screenshot:
- The second window is titled `codeo [home]`. The Explorer shows `codeo-122 [SSH: codeo-122.sbx]`, and the status bar shows `SSH: codeo-122.sbx` on `main`.
- Next to `codeo [#99]`, the two window titles differ (met).

```
$ CODEO_SBX_IMAGE=codeo-99/.sbx/claude-image bash codeo-sandbox.sh issue 122 main
    ✓ workspace — Git repository at D:\Downloads	ask22\codeo-122
  SANDBOX
    Name:       codeo-122
    Kit:        docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332
    Image:      docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332
    CPU:        2
    Memory:     4g
  AGENT
    ✓ assembled kit image ready (cached)
    ✓ Created sandbox codeo-122
    … (banner)
plugins: installed superpowers
plugins: installed codeo v1.0.6
plugins: superpowers, codeo v1.0.6
devcontainer-start: git identity: user.name set from GIT_AUTHOR_NAME
devcontainer-start: git identity: user.email set from GIT_AUTHOR_EMAIL
devcontainer-start: TODO — this container's folder is 'codeo-122' but its clone is on main with no lock, so it is the home container and 'docker ps' names it wrongly: remove it and open it again with the folder 'codeo-home' (.devcontainer/README.md)
todo: the sandbox is codeo-122 but its clone holds no workflow lock: run /codeo:init #122 on its branch, then issue 122 <branch> again
$ bash codeo-sandbox.sh open 122
window-title: codeo [home]
```

- The existing `codeo-122` clone, with its sandbox missing, was refreshed silently (`fetch -q`, `merge --ff-only`; already up to date). There was no clone message, and the sandbox was created. This exercises Task 16's path.
- `CODEO_SBX_IMAGE` won: the sandbox was created at the same digest as #99. This exercises Task 15's override.
- Task 19's no-lock todo printed as specified.
- The start script's own TODO, about a home clone in a `codeo-<N>` folder, is expected for `main` in a `codeo-122` folder.

### Step 8 — `end` refuses an unpushed commit

```
$ sbx.exe exec codeo-99 git commit --allow-empty -m scratch
    ✓ sandbox codeo-99 — started
[feat/make-sbx-issue-sandbox-usable 37a09c4] scratch
$ bash codeo-sandbox.sh end 99
From git://127.0.0.1:60027/codeo-99
 * [new branch]      feat/make-sbx-issue-sandbox-usable -> sandbox-codeo-99/feat/make-sbx-issue-sandbox-usable
   87c72ad..37a09c4  feat/make-sbx-issue-sandbox-usable -> refs/sandboxes/codeo-99/feat/make-sbx-issue-sandbox-usable
… (origin fetch)
From https://github.com/kbajpai/codeo
 * [new ref]         refs/pull/1/head   -> origin/pr/1
 … (59 pull-request heads in all)
codeo-99 has 1 commit(s) on no origin branch:
37a09c4 scratch
nothing removed: push them from the sandbox, or run: codeo-sandbox.sh end 99 --force
$ sbx.exe ls
  SANDBOX     AGENT    STATUS      PORTS                        WORKSPACE                       CREATED
  codeo-122   claude   ● running   127.0.0.1:60026->9418/tcp4   D:\Downloads	ask22\codeo-122   4m
  codeo-99    claude   ● running   127.0.0.1:60027->9418/tcp4   D:\Downloads	ask22\codeo-99    37m
```

- Met: the scratch commit is named, nothing is removed, and `codeo-99` is still listed.
- The pull-request fetch (Task 17) ran against the real origin and fetched 59 heads into `origin/pr/*`.
- Non-blocking, for `/codeo:qc`:
  - The first `end` prints one line per pull-request head, about 60 lines.
  - "on no origin branch" now also means "on no pull-request head".
  - The sandbox fetch also writes a remote-tracking ref `sandbox-codeo-99/<branch>` (the sbx remote's own refspec), besides `refs/sandboxes/codeo-99/*`. `end` does not clear that ref.

### Step 8a — `end` with nothing to lose, then recreate

```
$ sbx.exe exec codeo-99 git reset --hard HEAD~1
    ✓ sandbox codeo-99 — started
HEAD is now at 87c72ad docs(codeo): implement dossier for #99 — round 2
$ bash codeo-sandbox.sh end 99
From git://127.0.0.1:60028/codeo-99
 * [new branch]      feat/make-sbx-issue-sandbox-usable -> sandbox-codeo-99/feat/make-sbx-issue-sandbox-usable
 + 37a09c4...87c72ad feat/make-sbx-issue-sandbox-usable -> refs/sandboxes/codeo-99/feat/make-sbx-issue-sandbox-usable  (forced update)
  warning: sandbox "codeo-99" runs on an in-container clone (--clone); commits the agent made inside it are lost on removal unless fetched first (…)
  Removed sandbox codeo-99
removed codeo-99
$ sbx.exe ls
  SANDBOX     AGENT    STATUS      PORTS                        WORKSPACE                       CREATED
  codeo-122   claude   ● running   127.0.0.1:60026->9418/tcp4   D:\Downloads	ask22\codeo-122   5m
$ bash codeo-sandbox.sh issue 99 feat/make-sbx-issue-sandbox-usable
    ✓ workspace — Git repository at D:\Downloads	ask22\codeo-99
    Image:      docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332
    ✓ Created sandbox codeo-99
    … (banner)
plugins: installed superpowers
plugins: installed codeo v1.0.6
plugins: superpowers, codeo v1.0.6
lock: took the lock for #99 on feat/make-sbx-issue-sandbox-usable
devcontainer-start: git identity: user.name set from GIT_AUTHOR_NAME
devcontainer-start: git identity: user.email set from GIT_AUTHOR_EMAIL
devcontainer-start: TODO — could not read the workspace volume's name from /proc/self/mountinfo: fill the lock's volume line in by hand (docker volume ls on the host)
```

- Met (F2's normal case): with nothing unpushed, a plain `end` exited 0 with `removed codeo-99`, and the sandbox is gone from `ls`. No `--force` was needed.
- Met (F3): `issue` reused the existing clone with no `Cloning into`, brought it up to origin silently, created the sandbox at the pinned digest, and took the lock again. It printed the same `scripts/lock.sh` volume TODO as in step 2.

### Step 9 — stops

Repeat 1:
```
$ sbx.exe stop codeo-122
  Git remote sandbox-codeo-122 is restored when the sandbox next starts.
  Stopped sandbox codeo-122
$ sbx.exe run -d --name codeo-122
    ✓ sandbox codeo-122 — attaching to the existing sandbox (workspace D:\Downloads	ask22\codeo-122)
    ✓ sandbox codeo-122 — started
    ✓ sandbox codeo-122 — running detached
beeea403-6e58-4e82-931f-5031b28dadb2
$ sbx.exe ls
  SANDBOX     AGENT    STATUS                 PORTS                        WORKSPACE                       CREATED
  codeo-122   claude   ● running (detached)   127.0.0.1:60030->9418/tcp4   D:\Downloads	ask22\codeo-122   6m
  codeo-99    claude   ○ stopped                                           D:\Downloads	ask22\codeo-99    1m
```

- `codeo-99` was recreated by `issue` one minute earlier and is already `stopped`, with no `stop` issued. `codeo-122`, after `run -d`, shows `running (detached)`.
- The working hypothesis for "Stopped sandboxes": a sandbox that `create` and `exec` brought up stops once nothing is attached, and one started with `run -d` stays up. The five `sandbox codeo-99 — started` lines in steps 2a-6 fit this. The remaining repeats and an idle check test it.

Idle check:
```
$ sbx.exe run -d --name codeo-99
    ✓ sandbox codeo-99 — attaching to the existing sandbox (workspace D:\Downloads	ask22\codeo-99)
    ✓ sandbox codeo-99 — started
    ✓ sandbox codeo-99 — running detached
5eefb202-9e88-4ba9-96ec-9d61da59f46c
$ sbx.exe ls
  codeo-122   claude   ● running (detached)   127.0.0.1:60030->9418/tcp4   D:\Downloads	ask22\codeo-122   8m
  codeo-99    claude   ● running (detached)   127.0.0.1:60031->9418/tcp4   D:\Downloads	ask22\codeo-99    2m
(about four minutes idle)
$ sbx.exe ls
  codeo-122   claude   ● running (detached)   127.0.0.1:60030->9418/tcp4   D:\Downloads	ask22\codeo-122   11m
  codeo-99    claude   ● running (detached)   127.0.0.1:60031->9418/tcp4   D:\Downloads	ask22\codeo-99    6m
```

Repeat 2:
```
$ sbx.exe stop codeo-122
  Stopped sandbox codeo-122
$ sbx.exe run -d --name codeo-122
    ✓ sandbox codeo-122 — running detached
$ sbx.exe ls
  codeo-122   claude   ● running (detached)   127.0.0.1:60032->9418/tcp4   D:\Downloads	ask22\codeo-122   12m
  codeo-99    claude   ● running (detached)   127.0.0.1:60031->9418/tcp4   D:\Downloads	ask22\codeo-99    6m
```

**Cause of the stops, found.** A sandbox that `sbx create` made, and that only `sbx exec` has touched since, stops by itself within about a minute of the last `exec`. One started with `sbx run -d` stays `running (detached)` while idle; both sandboxes held for four minutes here. Stopping and restarting one sandbox did not disturb the other.

**Finding for `/codeo:qc`, which belongs to the plan.** The plan's `issue` creates the sandbox and runs the start script through `exec`, and never runs `run -d`. As a result:
- every later `exec`, `open` and `shell` pays a cold start (the `sandbox … — started` lines);
- a VS Code window can lose its host;
- "Stopped sandboxes" in `.sbx/README.md` says the cause is not known.

The likely fix is for `issue` to end with `sbx run -d --name codeo-<N>`, and for the README to state the cause.

Repeats 3-10, run as one loop: `for i in 3 … 10; do sbx.exe stop codeo-122 >/dev/null; sbx.exe run -d --name codeo-122 >/dev/null; sbx.exe ls; done`. Each repeat printed the same lines:
```
== repeat <i>
Git remote sandbox-codeo-122 is restored when the sandbox next starts.
  ✓ sandbox codeo-122 — attaching to the existing sandbox (workspace D:\Downloads	ask22\codeo-122)
  ✓ sandbox codeo-122 — started
  ✓ sandbox codeo-122 — running detached
  SANDBOX     AGENT    STATUS                 PORTS                        WORKSPACE                       CREATED
  codeo-122   claude   ● running (detached)   127.0.0.1:600<33…40>->9418/tcp4   D:\Downloads	ask22\codeo-122   13m
  codeo-99    claude   ● running (detached)   127.0.0.1:60031->9418/tcp4   D:\Downloads	ask22\codeo-99    7m-8m
```

- 10 of 10 repeats: `codeo-122` came back `running (detached)`, and `codeo-99` stayed `running (detached)` on the same port throughout. No sandbox stopped unasked during the stop trials.
- The git daemon port of `codeo-122` moves on every start, from 60030 to 60040. sbx restores the `sandbox-codeo-122` remote's URL each time.

### Step 12 — home dev container (folder trust)

- The first attempt failed in the image build: `curl: (6) Could not resolve host: claude.ai` at the Dockerfile's `curl -fsSL https://claude.ai/install.sh | bash -s latest` line. This branch does not touch the Dockerfile. Afterwards, `curl` to `claude.ai` returned 302 and `docker run --rm alpine nslookup claude.ai` resolved, so this was a transient DNS failure. The retry built the container.
- Screenshot after the retry:
  - The status bar shows `Dev Container: codeo @ desktop-linux` on `feat/make-sbx-issue-sandbox-usable`, and the window title is `codeo [#99]`.
  - Claude Code's Manage Plugins lists `codeo@codeo` at user scope and at project scope, both enabled, and `superpowers@superpowers-marketplace` enabled, among 12.
  - Because the clone is this issue's branch, the start script took the #99 lock, so the "home" container is in fact an issue container. Round 1's Task 14 wording (clone the branch into `codeo-home`) causes this.

- No "Trust this folder" dialog appeared when Claude Code opened (the engineer). Met.
- After one message (`hi`), the Claude Code panel's session title is `codeo [#99] · 9bbb522c`. That is the `session-title.sh` hook registered in the project's `.claude/settings.json`, so the project settings were in effect in the first session (met). Before any message the panel showed `Untitled`, so the panel shows the title from the first prompt on.
- `codeo@codeo` is enabled (met).
- Remote Control was active in the session.
- Still to do: the same checks after **Rebuild Container**.

After **Dev Containers: Rebuild Container**, a screenshot shows a new session titled `codeo [#99] · 92aea675` after one message (`Hi`), with Remote Control active. The project hook is in effect after the rebuild (met). The engineer is to confirm no trust dialog and codeo enabled after the rebuild.

- After the rebuild there was no trust dialog, and codeo is still enabled in `/plugin` (the engineer). Step 12 is met before and after the rebuild.

### Steps 10, 11, 13

- Step 10 (the next-day image check) and step 11 (cleanup with `end --force`) are still owed, for 2026-11-19.
- Step 13 is not run. No issue other than #99 has a branch on origin, and step 12 already ran on an issue clone (it took the #99 lock), so with `main` step 13 would only repeat step 12.

## Notes

- Ruling (Task 3): the "was not tried" check counts occurrences (15 → 14), not lines. `grep -c` counts lines, and the Host paragraph is one line that keeps its single mention.
- Ruling (Task 4): the #94 section of #99's body still quotes "T5 to T12" as the finding it describes, so `grep -c 'T5 to T12'` prints 1. The #86 section carries none, and "T8 to T12" appears 3 times.
- Minor, for QC: an empty `.claude.json` gets a "could not write" TODO from step 3d, where step 3c fills an empty `settings.json`.

## Outcome

**Built.** Tasks 1-13 are done and committed; Task 14 is the engineer's acceptance run on their host.

| Part | Tasks | Commits |
|---|---|---|
| #114 folder trust | 1-2 | `9c376ce`, `5ac3e7b` |
| #94 evaluation wording | 3-4, 6 | `f45a6da`, #99's body (Task 4), `279f193` and the #73 comment (Task 6) |
| Trials | 5 | dossier `c96c4a8`, `1d2cc43`, `facccbd` (S1-S10 under `## Trials`) |
| #85 host script | 7-8 | `4e6fbdb`, `30a39a6`, `5096870` |
| #86 sandbox use | 9-13 | `475229c`, `59bda33`, `dde95c2`, `8d60849`, `cf5a0b3`, `7007cb9` |

**Documentation changed:** `.devcontainer/README.md` (Tasks 2, 13), `.sbx/README.md` (new, Task 13), `.codeo/overlays/init.md`'s hand-off (Task 13), `docs/dev-environment-sbx-evaluation.md` (Tasks 3, 6), `CHANGELOG.md` (Tasks 2, 13).

**Build:** the `shell` suite's build is `true`, exit 0. No environment is configured, so nothing was deployed.

**Base branch (step 2a):** `origin/main` merged as `4d219c1`. One conflict, `CHANGELOG.md`: this branch's #114 bullet kept, main's #71 bullet taken (it extends this branch's copy with the `issue:<N>` fingerprint sentence). Also changed on main and re-checked against this branch:
- `.devcontainer/scripts/role.sh` now also treats `/run/.containerenv` as a container marker. The `role.sh` gap below depends on whether a sandbox has that file; Task 14 can check it with `sbx.exe exec codeo-99 test -e /run/.containerenv`.
- `.devcontainer/README.md`, `tests/devcontainer.test.sh` (#116): merged cleanly; Task 13's README paragraph was written after the merge.

**Deviations and rulings.**
- Task 12 `end` removes with `sbx rm --force`, superseding the trials ruling that it would answer `rm`'s prompt itself: answering through a pipe is untried, and `end` has already proved nothing is unpushed (or the user passed `--force`). Cost if wrong: an open VS Code window on the sandbox is cut off; `.sbx/README.md` says to close it first.
- Task 12 review fix (`cf5a0b3`): `end` refuses when the fetch leaves no refs under `refs/sandboxes/codeo-<N>/`, unless `--force` — zero refs means a misconfigured remote, not a clean sandbox.
- Tasks 8, 11, 12: a stopped sandbox is started by `sbx exec` itself, not `run -d`; `open` checks `ssh(.exe) codeo-N.sbx -- true` first; on WSL, VS Code is launched as `cmd.exe /c code` from `/mnt/c`, and `end` fetches the sandbox with `git.exe`.
- Task 13: "Stopped sandboxes" in `.sbx/README.md` gives the cause as not known and the recovery `sbx run -d --name codeo-<N>`. Update it with Task 14's result.
- The sub-skill's final whole-branch review was not run here: `/codeo:qc`'s independent review is that gate (implement-09).

**Gaps, for QC and for issues of their own.**
- `end` checks commits only: uncommitted changes, stashes and work on a detached HEAD in the sandbox are not detected. `.sbx/README.md` says so.
- `role.sh` classifies a sandbox as `unguarded` (no `/.dockerenv`), so skills run there with no role check — see the base-branch note above.

**Deferred minors from the task reviews** (in the SDD ledger, for QC to triage): Task 11 — the pty test skips silently without `script`, the ssh check has no `BatchMode`/`ConnectTimeout`, the folder URI is not percent-encoded; Task 12 — the refusal prints its hint on stdout, test gaps for a failed `exec true` start; Task 13 — README:137 should quote the exact `%(prefix)///wsl.localhost/…` safe.directory entry, `init.md:34` "Either way" reads as two routes, the README omits the `CODEO_CODE` override, one docs test greps two strings independently.


### Round 2

2026-11-18
(after plan.md round 2)

Plan: `docs/plans/2026-11-17-sbx-issue-sandbox-round-2.md` (committed `c752e87`), answering `qc.md` round 1's F1-F8 as Q10-Q13 settled them.

**Built.** Tasks 15-21 are done and committed. Each one passed its task review. Task 22 is the engineer's acceptance run on their host.

| Task | Finding | Commits |
|---|---|---|
| 15 Pin read from `CODEO_SBX_IMAGE`, else the clone's `.sbx/claude-image`, else `origin/HEAD:.sbx/claude-image` | F1 | `b0464c9` |
| 16 An existing clone is fast-forwarded to `origin/<branch>` before a missing sandbox is created | F3 | `034a6fc` |
| 17 `end` fetches `+refs/pull/*/head:refs/remotes/origin/pr/*`, so a squash-merged branch counts as delivered | F2 | `c3ec483` |
| 18 `end` deletes `refs/sandboxes/codeo-<N>/` after `rm`; `--force` moves them to `refs/codeo/ended/codeo-<N>/<UTC>/` | F4 | `cb71ff2` |
| 19 ssh `BatchMode`/`ConnectTimeout`, `uri_path` percent-encoding, the no-lock todo, a test of the identity read from `~/.gitconfig` | F7, F8 | `987ef06` |
| 20 An empty `.claude.json` reads as `{}` | F7 | `c9daf5b` |
| 21 Documentation and `docs_*` tests | F1-F6, F8 | `0baf43c`, `1a942c2` (review fix) |

**Documentation changed:**
- `.sbx/README.md`: Getting the script, Commands, Ending a sandbox and its flowchart, The image pin, safe.directory, `CODEO_CODE`.
- `.codeo/overlays/init.md`: "Whichever route".
- `docs/dev-environment-sbx-evaluation.md:455`: the host script is named as it is.
- `CHANGELOG.md`: this branch's sandbox-route bullet, amended.

The token line (F6, README:11) already stated what T13 showed, so it is unchanged.

**Build:** the `shell` suite's build is `true`, exit 0. No environment is configured, so nothing was deployed.

**Base branch (step 2a):** `sync-main: the branch already contains origin/main`, at the start and again before this outcome.

**Deviations and rulings.**
- Task 15: `issue_pin_override_wins_over_the_clone` passed before the change. The override path was already there; the plan expected all four new cases to fail.
- Task 15: `a_pin_that_is_not_a_digest_is_refused` no longer asserts that no clone happens, because the plan's order puts the clone before the pin read.
- Task 16: a branch deleted on `origin` is detected with `git ls-remote --exit-code --heads origin <branch>`. A plain fetch leaves the stale `origin/<branch>` ref, so the merge alone would not catch it.
- Task 16: the fetch runs with `-q`, so a refusal stays one stderr line.
- Task 17: `end_lists_a_commit_made_after_the_pull_request_head` asserts exactly one listed commit. That is stricter than the plan, so it fails without the pull-request fetch.
- Task 18: `end --force` with nothing unpushed also sets the refs aside, and its message reads "its refs are kept in <prefix>".
- Task 18: earlier `end_*` assertions that `rm` is the last call were relaxed to "`rm` was called", because the ref steps now follow it.
- Task 18 review: two cases appeared to pass before the change. That was a `set -e` abort hiding them. The reviewer ran the new tests against the old script and showed all four fail. Task 19 made the guilty `grep` non-fatal.
- Task 19: `issue_takes_the_identity_from_the_host_gitconfig` passed at once, as the plan allowed; it covers an untested path. The test sets `GIT_CONFIG_GLOBAL` as well as `HOME`.
- Task 19: `check_name` treats any lock output other than `codeo-<digits>` as "no lock".
- Task 21 review fix (`1a942c2`): the flowchart and prose said a plain `end` and `end --force` with nothing unpushed both delete the refs; `--force` always sets them aside. The pin text implied a fallback past a set-but-missing `CODEO_SBX_IMAGE`; the script refuses instead. A CHANGELOG clause read as if `--force` replaces the `docker rm` line.
- `tests/sandbox.test.sh` lost its executable bit in `034a6fc`; `c3ec483` restored it.
- The sub-skill's final whole-branch review was not run here: `/codeo:qc`'s independent review is that gate (implement-09).

**Deferred minors from the task reviews** (in the SDD ledger, for QC to triage):
- Task 15: a present but empty clone pin file is refused, not passed over to `origin/HEAD`.
- Task 16: no test for a dirty clone whose changes block the merge. It is the same code path as the diverged case.
- Task 17: the pull-request refspec does not prune, so a deleted pull-request head stays counted as delivered.
- Task 18: `end_force_sets_the_refs_aside` checks only the `work` ref.
- Task 19: the identity test's `unset` runs in the suite's main shell. Older cases do the same, and no later case reads those variables.
- Task 20: the whitespace-only `.claude.json` case is untested.
- Task 21: the evaluation page's `:455` parenthesis keeps its issue numbers. The page is an evaluation record and cites issues throughout.

**Gaps, unchanged from round 1:** `end` checks commits only. `role.sh` classifies a sandbox as `unguarded`; Task 22 checks `/run/.containerenv`.

## Log
- 2026-11-17 — Tasks 1-4 and 7 done; paused at Task 5 for the engineer's trials · cost: 38m · opus-5-5 55k in + 9.1M cached / 19k out · sonnet-5-5 312k in + 4.2M cached / 44k out
- 2026-11-17 — Tasks 6, 8-13 done (Task 12 fix round, Task 13 docs); merged origin/main; handed to /codeo:qc · cost: 12m · opus-5-5 63k in + 3M cached / 15k out · sonnet-5-5 165k in + 1.2M cached / 18k out
- 2026-11-18 — round 2 (after plan.md round 2): Tasks 15-21 done, Task 21 one fix round; build passes; handed to /codeo:qc · cost: 64m · opus-5-5 105k in + 11.1M cached / 30k out · sonnet-5-5 634k in + 9.1M cached / 96k out
