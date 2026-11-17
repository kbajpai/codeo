# Issue #99 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/99 |
| Branch | `feat/make-sbx-issue-sandbox-usable` |
| Plan | `docs/plans/2026-11-17-sbx-issue-sandbox.md` |
| Updated | 2026-11-17 |

## Where this stands

Round 1, paused at Task 5. Tasks 1, 2, 3, 4 and 7 are done: commits `9c376ce`, `5ac3e7b`, `f45a6da` and `4e6fbdb`, and #99's body edited. Each was reviewed and found clean. `sync-main.sh` reported that the branch already contains `origin/main`, and `overlap.sh 99` printed nothing. Waiting on the engineer: run trials S1-S9 (`.codeo/99/plan.md` → Notes → Trials) in WSL2 bash and paste each output under `## Trials` below, with tokens and account names removed. Tasks 6, 8, 10, 11 and 12 read their results. Then run `/codeo:implement` again.

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

- **The `--folder-uri` form reaches Remote - SSH and names the right host.** Opening the folder depends on `*.sbx` resolving through Windows OpenSSH's config, which `sbx setup ssh` writes. That command is marked experimental. Task 11's `open` therefore has to check that the host resolves (`ssh.exe <name>.sbx -- true`), and if it does not, point the user to `sbx.exe setup ssh` rather than open a window that fails.
- **VS Code asks for the platform** the first time it connects to each host. A new `codeo-<N>.sbx` asks again unless `remote.SSH.remotePlatform` maps it, or a `*.sbx` pattern covers it.

## Notes

- Ruling (Task 3): the "was not tried" check counts occurrences (15 → 14), not lines. `grep -c` counts lines, and the Host paragraph is one line that keeps its single mention.
- Ruling (Task 4): the #94 section of #99's body still quotes "T5 to T12" as the finding it describes, so `grep -c 'T5 to T12'` prints 1. The #86 section carries none, and "T8 to T12" appears 3 times.
- Minor, for QC: an empty `.claude.json` gets a "could not write" TODO from step 3d, where step 3c fills an empty `settings.json`.

## Outcome

_Pending — written at the hand-off._

## Log
- 2026-11-17 — Tasks 1-4 and 7 done; paused at Task 5 for the engineer's trials · cost: 38m · opus-5-5 55k in + 9.1M cached / 19k out · sonnet-5-5 312k in + 4.2M cached / 44k out
