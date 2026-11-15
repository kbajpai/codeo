# Evaluation: Docker Sandboxes (`sbx`) against the dev container

> **Status: draft, trials recorded, recommendation not written.** Trials T1 to T12 were run by the engineer on 2026-11-14 and 2026-11-15; rows they settled say `tried T<n>`, the rest still rest on Docker's documentation (`cited`). The recommendation and follow-up issues are not written yet.

## Contents

- [Scope](#scope)
- [Host](#host)
- [Drivers](#drivers)
- [Duties of the current setup](#duties-of-the-current-setup)
- [Trials](#trials)
- [Recommendation](#recommendation)
- [Follow-up issues](#follow-up-issues)

## Scope

This page concerns codeo's own development environment only: the dev container in `.devcontainer/` against Docker Sandboxes (`sbx`), the standalone CLI that runs a coding agent in a microVM. It is not about how projects that use codeo run it. `docs/` ships with the plugin, so a project that installs codeo receives this page; nothing here applies to that project's setup.

Out of scope: doing the migration, changing `.devcontainer/` or any skill, other sandbox or remote options (Codespaces, Claude Code's built-in sandbox, Podman), Remote Control and cloud sessions, and Docker's cloud sandboxes (`sbx --cloud`).

Every row of the two tables ends in an Evidence cell: `cited <URL> (read <date>)` for a point taken from Docker's documentation, later `tried T<n>, <date>` for a point settled by running it. Where Docker's page does not say, the row says `cited: not documented in <URL>` in its `sbx` column and the Evidence cell names that page; nothing is guessed.

Docker pages read, all on 2026-11-14:

| Short name | URL |
|---|---|
| overview | https://docs.docker.com/ai/sandboxes/ |
| get-started | https://docs.docker.com/ai/sandboxes/get-started/ |
| install | https://docs.docker.com/ai/sandboxes/install/ |
| usage | https://docs.docker.com/ai/sandboxes/usage/ |
| faq | https://docs.docker.com/ai/sandboxes/faq/ |
| security | https://docs.docker.com/ai/sandboxes/security/ |
| policy | https://docs.docker.com/ai/sandboxes/security/policy/ |
| credentials | https://docs.docker.com/ai/sandboxes/configuration/credentials/ |
| environment files | https://docs.docker.com/ai/sandboxes/configuration/environment-files/ |
| architecture | https://docs.docker.com/ai/sandboxes/architecture/ |
| git workflows | https://docs.docker.com/ai/sandboxes/workflows/git/ |
| Claude Code agent | https://docs.docker.com/ai/sandboxes/agents/claude-code/ |
| integrations | https://docs.docker.com/ai/sandboxes/integrations/ |
| troubleshooting | https://docs.docker.com/ai/sandboxes/troubleshooting/ |
| `sbx create` reference | https://docs.docker.com/reference/cli/sbx/create/ |

The `sbx` command reference pages (`sbx`, `sbx create`, `sbx run`) rendered as a title only when read, so flag defaults below come from the usage page and from a search result quoting the `sbx create` page; T10 checks them with `sbx create --help`.

## Host

The current host is Windows with WSL2.

Whether `sbx` runs there: **yes, partly**. It installs as a Windows program (`winget.exe install -h Docker.sbx`, v0.53.0; no elevation and no Windows-feature step was asked for) and works from WSL bash under the name `sbx.exe`, not `sbx`: plain `sbx` is not found from WSL, even after `wsl.exe --shutdown`. The Linux-in-WSL2 route was not available: `lsmod | grep kvm` printed nothing in the Ubuntu-24.04 distribution.

Facts from T1 and T2 (WSL2 bash, 2026-11-14):

- Windows `10.0.26300.9818`; WSL default version 2; default distribution `Ubuntu-24.04`; Docker `29.9.3` reachable from it.
- `/etc/wsl.conf` has `systemd=true` and an automount `options = "metadata,uid=1001,gid=1001,umask=22,fmask=11"` (relevant to file modes for a clone on `/mnt/c`; a clone inside the sandbox is not affected, U4).
- The Windows PATH is passed through to WSL, so interop resolves `sbx.exe`; `sbx` without the suffix is not found.
- Windows Git needs a `safe.directory` line for every clone, because `sbx.exe` hands Windows `git.exe` a `\\wsl.localhost\...` path (U3 tried; T3 and T9).
- `sbx.exe login` used a device-code flow and then printed `warning: schedule credential exchange failed: the schedule service could not verify your Docker sign-in`; it did not block creating, running or exec in a sandbox.
- For SSH, `ssh.exe` (Windows OpenSSH) reads the file `sbx.exe setup ssh` wrote; plain `ssh` in WSL reads the WSL home's config and cannot resolve `*.sbx` (T12).



What Docker's pages say, which does not settle it:

- Windows: Windows 11, a 64-bit Intel or AMD processor, and Windows Hypervisor Platform, "required for local sandboxes". Install is `winget install -h Docker.sbx` from Windows (or an administrator MSI). Docker's install page does not mention WSL or WSL2. (install, read 2026-11-14)
- Linux: Ubuntu 24.04 or later, KVM turned on, the user in the `kvm` group; a virtual machine "must support nested virtualization". Whether a WSL2 distribution counts as such a Linux host is not documented. (install, read 2026-11-14)
- The only WSL mention is a troubleshooting entry: on Windows, `sbx run --clone` against a repository on a WSL filesystem can fail with "not in a Git repository" because of Git's dubious-ownership check, fixed by adding the repository to `safe.directory`. (troubleshooting, read 2026-11-14)

So the plan's assumption that `sbx` is run in bash inside WSL2 is not what the documentation describes: the documented Windows route is a Windows install, and the documented Linux route needs KVM. The trials settled the question: this host takes the Windows route, driven from WSL bash through `sbx.exe`.

## Drivers

The four drivers from the issue come first, then the further points the issue asks about.

| ID | Driver | Dev container today | `sbx` | Evidence |
|---|---|---|---|---|
| D1 | Isolation and safety | A container on the host kernel through Docker; `dev` has passwordless sudo (`.devcontainer/Dockerfile`). | Each sandbox is a microVM with its own kernel, its own Docker Engine and deny-by-default network; credentials stay outside the VM. Inside the VM the agent still has sudo; the VM is the boundary. A directly mounted workspace is read-write on the host, so Git hooks and build scripts in it deserve review; clone mode mounts the host repository read-only. Safety note, observed: the `gh` login inside the sandbox carries the host token's full scopes (`delete_repo, gist, project, read:org, read:packages, repo, workflow`), including `delete_repo`, so an agent in a sandbox can use everything the host's `gh` token can. | tried T6; cited https://docs.docker.com/ai/sandboxes/security/ (read 2026-11-14) |
| D2 | VS Code dependency | The container opens only through **Dev Containers: Clone Repository in Named Container Volume…** (`.devcontainer/README.md`). | Sandboxes are created and run from the terminal with no editor (`sbx.exe create`, `sbx.exe exec`, `sbx.exe run`). The terminal route needs no VS Code: `claude` ran interactively in the sandbox from WSL bash. After `sbx.exe setup ssh`, `ssh.exe codeo-a.sbx -- echo hello` printed `hello` from WSL (the Windows OpenSSH client; plain `ssh` in WSL does not resolve `*.sbx`). VS Code Remote-SSH to `codeo-a.sbx` connected, but opened no folder (Open Folder by hand) and did not install the dev container's extensions. | tried T12, 2026-11-15 |
| D3 | Per-issue lifecycle | One container and one named volume per issue, named by the clone folder; cleanup is by hand (#70); `~/.claude` is lost on a rebuild (`.devcontainer/README.md`). | Observed: first `sbx.exe create --clone` took 1m47s (image pull); a recreate with the image cached took 13s; `sbx.exe stop` then `sbx.exe run -d --name codeo-a` restarted in 5.6s (`-d` does combine with reattaching by name), with a new git daemon port per start and per sandbox. `sbx.exe rm` warns that commits inside a `--clone` sandbox are lost unless fetched (`git fetch sandbox-codeo-a` mirrors branches into `refs/sandboxes/codeo-a/*`, which survive removal) or pushed. A sandbox name cannot be reused (`sandbox 'codeo-b' already exists`). From WSL each new clone needs its own Windows `safe.directory` line before `create` works (U3). `sbx prune` was not tried (`cited` from the usage page). | tried T3, T5, T8, 2026-11-14/15 |
| D4 | Parallel agents | Several containers can run at once, each with its own name, clone and volume (`.devcontainer/README.md`). | Observed: `codeo-a` and `codeo-b` ran at once (both `running (detached)`), and the suite passed in both at once at about 3m10 each against about 2m36 alone (about 23% longer, no failures). Each sandbox has its own git daemon port. Observation, cause unknown: twice a running sandbox was found stopped with no `stop` command (`codeo-a` after `codeo-b` was created, `codeo-b` after `codeo-a` was started); starting both afterwards worked, so it is not a rule. Per-sandbox image caches were not tried. | tried T9, 2026-11-15 |
| D5 | Host support (Windows + WSL2) | Docker (Docker Desktop or the WSL2 engine) on the Windows host; VS Code on Windows (`.devcontainer/devcontainer.json`). | Windows 10.0.26300.9818, WSL 2, default distribution Ubuntu-24.04, Docker 29.9.3 reachable from it. `winget.exe install -h Docker.sbx` from WSL installed Docker Sandboxes 0.53.0 with no elevation or Windows-feature step asked for; from WSL the program is `sbx.exe`, not `sbx` (`Command 'sbx' not found` even after `wsl.exe --shutdown`). The Linux-in-WSL2 route has no basis: `lsmod` showed no `kvm` module. `sbx.exe create --clone` works from WSL once Windows Git trusts the clone's folder (U3). `sbx.exe login` printed a `schedule credential exchange failed` warning that did not block anything. | tried T1-T2, T3, 2026-11-14 |
| D6 | Resource limits | `--memory=4g --cpus=2` in `runArgs` (`.devcontainer/devcontainer.json`). | Observed: `sbx.exe create --help` (v0.53.0) lists `--cpus int` (0 = all host CPUs) and `-m/--memory` (default 50% of host memory, clamped to 512 MiB to 32 GiB, maximum host memory, warns above 75%); the defaults on this host were 20 CPUs and 32 GiB. With `--cpus 2 --memory 4g` the summary printed `CPU: 2`, `Memory: 4g`, `nproc` printed `2` and `free -m` showed `Mem: 3997` MiB total. The limit is enforced like the dev container's `--memory=4g --cpus=2`. `sandboxOptions` in an environment file was not tried. | tried T10, 2026-11-15 |
| D7 | `gh`, git and Claude login persistence | `gh` and git config on the `codeo-gh` and `codeo-git` volumes; Claude login lost on a rebuild (`.devcontainer/README.md`, `.devcontainer/devcontainer.json`). | Observed: `sbx.exe secret set github --command 'gh auth token'` made `gh` logged in inside the running sandbox at once (global secret, applied without a restart), with the host token's scopes. `/login` inside the sandbox worked (`claude auth status` `loggedIn: true`). Both logins survived stop and start unchanged. After `sbx.exe rm` and recreate, `gh` was logged in again and `claude -p "reply with the single word: ok"` printed `ok` with no login step in the new sandbox (its `auth status` showed null expiry, email and organisation), so the Claude login did not need redoing; how the credential reaches the sandbox is not shown. Git identity: `git config user.name` printed nothing, so the sandbox has no git identity. | tried T6, T7, T8, 2026-11-15 |
| D8 | Plugin installation | `.devcontainer/scripts/plugins.sh` installs `superpowers` and `codeo` at the pin in `.codeo/config.json`, run from `postCreateCommand`. | Observed: `claude plugin list` showed `No plugins installed` in a new sandbox. `bash .devcontainer/scripts/plugins.sh` ran unchanged inside the sandbox (jq, git and the network under policy `balanced` were all there) and printed `plugins: superpowers, codeo v1.0.6`; the list then showed `codeo@codeo` 1.0.6 and `superpowers@superpowers-marketplace` 7.0.2, both enabled, scope user. After `sbx.exe rm` and recreate the list was `No plugins installed` again, so `plugins.sh` has to be rerun in every new sandbox. Survival of a plain restart was not shown (the plugins were installed after the restart). `--kit` as an install route was not tried. | tried T7, T8, 2026-11-15 |
| D9 | Network policy | None set; the container has the host's network (`.devcontainer/devcontainer.json`). | Observed: `sbx.exe policy ls` showed `default-deny-all` and `local-policy` (the `balanced` preset: 195 allowed hosts), plus a per-sandbox kit policy of 8 allows. `curl -sI https://github.com` returned `HTTP/1.1 200 OK` from GitHub. `curl -sI https://example.org` and `https://example.net` each returned the proxy's `200 OK` for the tunnel and then `HTTP/1.1 403 Forbidden` at once, with no approval prompt and no hang in a non-interactive `exec` (the policy page says blocked hosts ask for approval; how a terminal approves was not shown). The dev container sets no network policy. | tried T11, 2026-11-15 |
| D10 | Editor attach | VS Code attaches through the Dev Containers extension (`.devcontainer/devcontainer.json`). | Observed: `sbx.exe setup ssh` (Windows `~/.ssh/config`) printed `Status: enabled` and `Access: *.sbx -> sandboxd.sock (no port, login-gated)`, with a warning that `sh` is not on the Windows PATH. `ssh codeo-a.sbx` from WSL bash failed (`Could not resolve hostname`) because WSL's `ssh` reads the WSL home's config; `ssh.exe codeo-a.sbx` worked. VS Code Remote-SSH connected to `codeo-a.sbx`, opened no folder by itself, and the only extension present was GitHub Pull Requests; the Claude Code, ShellCheck and Markdown Mermaid extensions were not there. The integrated terminal ran `claude`. | tried T12, 2026-11-15 |

## Duties of the current setup

One row for each duty the issue lists, with the `devcontainer-start.sh` steps taken one by one. The answer is an `sbx` equivalent, a workaround, or `no equivalent`.

| ID | Duty | Current mechanism | `sbx` equivalent, workaround or `no equivalent` | Evidence |
|---|---|---|---|---|
| U1 | Home/issue split | Two kinds of container: `codeo-home` on `main`, `codeo-<N>` on an issue's branch (`.devcontainer/README.md`, `.devcontainer/scripts/container-name.sh`). | Workaround: two kinds of named sandbox, `sbx create --name codeo-home` and `--name codeo-<N>`; nothing in `sbx` knows the difference, so the naming stays a convention. | cited https://docs.docker.com/ai/sandboxes/usage/ (read 2026-11-14) |
| U2 | One clone per issue | Each container is its own clone in its own Docker volume, opened with Clone Repository in Named Container Volume (`.devcontainer/README.md`). | Equivalent, tried: `sbx.exe create --clone --name codeo-a claude .` made a clone inside the sandbox, with the host folder read-only at `/run/sandbox/source`; from WSL it needed a Windows Git `safe.directory` line first (U3). Still `cited`: the clone follows whatever ref the host has checked out and creates no branch, so to start on the branch `/codeo:init` pushed it is checked out on the host first (so that branch is checked out in the host checkout, not a second one), or the agent switches branches inside; clone mode is fixed at create time; mountless sandboxes (no host mount, v0.42.0 or later) are the other model. | tried T3, 2026-11-14; cited https://docs.docker.com/ai/sandboxes/workflows/git/ (read 2026-11-14) |
| U3 | Trust and chown of the clone | Step 1 of `.devcontainer/scripts/devcontainer-start.sh`: `safe.directory`, and `sudo chown` of a clone on a Docker volume. | Error reproduced from WSL: `sbx.exe create --clone` failed in 1.3 s with `--clone cannot use \\wsl.localhost\Ubuntu-24.04\home\<user>\Source\codeo-sbx-a as a Git repository: git failed: fatal: detected dubious ownership` (`sbx.exe` turns the path into a UNC path and runs Windows `git.exe`). The fix is `git.exe config --global --add safe.directory '%(prefix)///wsl.localhost/Ubuntu-24.04/home/<user>/Source/<clone folder>'`, one line in the Windows global Git config for every clone (needed again for `codeo-sbx-b` and `codeo-sbx-lim`). Inside the sandbox no chown or trust step is needed; the create then succeeded. | tried T3, T9, T10, 2026-11-14/15 |
| U4 | Executable-bit repair | Step 2b of `devcontainer-start.sh`: `core.fileMode` probe and `chmod +x` of files the index records as 100755. | Observed: `bash tests/run.sh` inside the sandbox printed `all cases passed` (2m37.9s). File modes survive in the clone: the index records `tests/run.sh` as `100644` (it is run as `bash tests/run.sh`) and `ls -l` in the sandbox showed `-rw-r--r--` for it and `-rwxr-xr-x` for every file under `scripts/`. No repair step like step 2b is needed; the WSL automount's `fmask=11` did not matter because the clone is inside the sandbox, not on `/mnt/c`. | tried T4, 2026-11-14 |
| U5 | Workflow lock from `init.md` | Step 3a of `devcontainer-start.sh`: codeo's `lock.sh` takes `.codeo/active` from the `init.md` on the branch, in an issue container only. | Workaround: run the same script by hand or as the sandbox's first command (`sbx exec`); `sbx` has no create-time hook. Environment files have `lifecycle.initialize` and `lifecycle.postCreate`, but these run on the host, not in the sandbox, and `sbx env` is experimental. | cited https://docs.docker.com/ai/sandboxes/configuration/environment-files/ (read 2026-11-14) |
| U6 | Folder check | Step 3a' of `devcontainer-start.sh` and `.devcontainer/scripts/folder-check.sh`: the clone folder must equal the container's Docker name. | No equivalent needed: the Docker-name constraint is Docker's rule for container names, and a sandbox is named by `--name`. The check would instead compare the sandbox name with the lock. | cited https://docs.docker.com/ai/sandboxes/usage/ (read 2026-11-14) |
| U7 | TODO lines | Step 7 of `devcontainer-start.sh` prints what is left for the engineer (logins, identity, scope). | Workaround: the script can be run unchanged inside the sandbox; whether it can run at creation is U5's answer. | cited https://docs.docker.com/ai/sandboxes/configuration/environment-files/ (read 2026-11-14) |
| U8 | `gh` wiring and project-scope check | Step 4 of `devcontainer-start.sh`: `gh auth setup-git`, then a check that the token has the project scope; login state on the `codeo-gh` volume. | Equivalent, tried: `sbx.exe secret set github --command 'gh auth token'`, and `gh auth status` inside the sandbox printed `Logged in to github.com account <user> (GH_TOKEN)` with scopes `delete_repo, gist, project, read:org, read:packages, repo, workflow`. The scopes carry over from the host token, so the `project` scope the start script checks for is present (and so is `delete_repo`, see D1). The start script's check itself was not run. | tried T6, 2026-11-15 |
| U9 | Git identity seeding | Step 5 of `devcontainer-start.sh`: `user.name` and `user.email` from the host `~/.gitconfig` that VS Code copies in, else `GIT_AUTHOR_*`. | No equivalent found: `git config user.name` inside the sandbox printed nothing, so there is no git identity from the host, and one is needed before the first commit in a sandbox. Workaround, untried and still `cited`: pass `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL` with `-e` or `--env-file` on `sbx create` (stored with the sandbox) and let step 5 run. | tried T7; cited https://docs.docker.com/ai/sandboxes/usage/ (read 2026-11-14) |
| U10 | Claude login check | Step 6 of `devcontainer-start.sh`: `claude auth status`, with a TODO when not logged in; login lost on rebuild. | Equivalent, tried: `claude auth status` before a login printed `loggedIn: false`; `/login` inside the sandbox (interactive `claude`) printed `Login successful` and then `loggedIn: true`, `authMethod: claude.ai`. The login survived stop and start, and after `sbx.exe rm` and recreate `claude -p` printed `ok` with no login step, so no re-login after a rebuild was needed. How the credential is kept outside the sandbox is not shown. | tried T6, T8, 2026-11-15 |
| U11 | Remote Control setting | Step 3c of `devcontainer-start.sh`: `remoteControlAtStartup` merged into the user's Claude settings. | Equivalent: `sbx settings set claude.remoteControl true`, after which `/remote-control` is available. Remote Control is out of scope for the recommendation, so this is recorded as a cost or gain only. | cited https://docs.docker.com/ai/sandboxes/agents/claude-code/ (read 2026-11-14) |
| U12 | `plugins.sh` | `.devcontainer/scripts/plugins.sh` runs `claude plugin marketplace add` and `claude plugin install` for `superpowers` and for `codeo` at the pin. | Equivalent: `bash .devcontainer/scripts/plugins.sh` ran unchanged inside the sandbox and installed `superpowers` and `codeo v1.0.6` (list showed both enabled). The plugins are gone after `sbx.exe rm` and recreate, so the script runs once per new sandbox (nothing in `sbx` runs it at creation, U5). | tried T7, T8, 2026-11-15 |
| U13 | Window title | `.devcontainer/scripts/window-title.sh` writes `window.title` into `.vscode/settings.json` ("codeo [home]" or "codeo [#N]"). | No way to set a window title found: VS Code Remote-SSH to `codeo-a.sbx` connected, and nothing was observed that sets a title from the sandbox; `window.title` in `.vscode/settings.json` was not tried further. The sandbox name (`sbx.exe ls`, and `<name>.sbx` in an editor) can carry the same text. | tried T12, 2026-11-15 |
| U14 | Session titles | `.devcontainer/scripts/session-title.sh`, a Claude hook, only when `REMOTE_CONTAINERS=true`. | Workaround: the hook is registered by the project and project-level configuration carries over; the `REMOTE_CONTAINERS` test must change. | cited https://docs.docker.com/ai/sandboxes/faq/ (read 2026-11-14) |
| U15 | `codeo-gh` volume | Named volume mounted at `/home/dev/.config/gh` (`.devcontainer/devcontainer.json`). | Equivalent in effect, tried for the `gh` part: the global `github` secret replaced the stored `gh` login, and `gh` stayed logged in across a restart and a recreate. A named volume mounted into a sandbox: `cited: not documented` (persistent kit volumes exist, and survive removal); `sbx.exe --help` lists `volume` as cloud only, and a volume was not tried. | tried T6, T7, T8; cited https://docs.docker.com/ai/sandboxes/usage/ (read 2026-11-14) |
| U16 | `codeo-git` volume | Named volume at `/home/dev/.config/git`, with `GIT_CONFIG_GLOBAL` pointing at it (`.devcontainer/devcontainer.json`). | Observed: the user-level state tried (the plugins from `plugins.sh`) did not survive `sbx.exe rm`; the logins did not need redoing because they do not live in the sandbox. Git config set inside a sandbox was not tried: `cited` that it persists across stop and start and is deleted with `sbx rm`, so `no equivalent` of a volume that outlives the sandbox other than a kit volume or a saved template (`sbx template save`). | tried T7, T8; cited https://docs.docker.com/ai/sandboxes/usage/ (read 2026-11-14) |
| U17 | Memory and CPU limits | `--memory=4g --cpus=2` in `runArgs` (`.devcontainer/devcontainer.json`). | Equivalent, tried: `sbx.exe create --clone --cpus 2 --memory 4g --name codeo-lim claude .` printed `CPU: 2`, `Memory: 4g`; inside it `nproc` printed `2` and `free -m` printed `Mem: 3997` MiB. `sandboxOptions` in an environment file was not tried. | tried T10, 2026-11-15 |
| U18 | The three VS Code extensions | `anthropic.claude-code`, `timonwong.shellcheck`, `bierner.markdown-mermaid` (`.devcontainer/devcontainer.json`). | No equivalent as a setting: over Remote-SSH to `codeo-a.sbx` the only extension present was GitHub Pull Requests; the Claude Code, ShellCheck and Markdown Mermaid extensions did not install by themselves (a Remote-SSH host has no devcontainer.json). Whether installing them by hand works was not tried. The integrated terminal ran `claude`. | tried T12, 2026-11-15 |

## Trials

All `sbx` commands below were run as `sbx.exe` from WSL bash (T1 and T2 showed plain `sbx` is not found there); the command text is kept as planned. Each trial is run in bash in a WSL2 distribution, one plain command per line, unless T1 or T2 shows `sbx` can be run only from Windows (then `sbx.exe` is called from bash through Windows interop, or the commands are run in PowerShell, and the page says which). Names used below: sandbox `codeo-a`, clone folder `codeo-sbx-a`; second sandbox `codeo-b`, clone folder `codeo-sbx-b`. Paste every output with tokens and account names redacted. A trial's output is quoted under its number when it is run, with the date and the host.

**T1: host facts.** Settles D5 and Host.

```bash
cmd.exe /c ver
wsl.exe --status
docker --version
command -v sbx
lsmod | grep kvm
```

Expected: a Windows 11 build number; WSL version 2 and the default distribution; the Docker version or an error; `sbx` absent (no output); `lsmod` showing `kvm_intel` or `kvm_amd` when the distribution can run KVM, and nothing when it cannot.

Result (2026-11-14/15, WSL2 bash on the engineer's host):

```
Microsoft Windows [Version 10.0.26300.9818]
Default Distribution: Ubuntu-24.04
Default Version: 2
Docker version 29.9.3, build 5457199
```

`command -v sbx` and `lsmod | grep kvm` printed nothing: `sbx` not installed, and no `kvm` module in the distribution. `cmd.exe` printed its UNC-path warning first (harmless). `/etc/wsl.conf`: `systemd=true`, automount `options = "metadata,uid=1001,gid=1001,umask=22,fmask=11"`.


**T2: install `sbx`.** Settles D5.

```bash
winget.exe install -h Docker.sbx
sbx login
sbx --version
```

Expected: winget reports the package installed (Windows Hypervisor Platform needs enabling first from an elevated PowerShell with `Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All`, an administrator step to record); `sbx login` opens the browser for Docker OAuth; `sbx --version` prints a version and exits 0. If the Windows binary is not on the distribution's `PATH`, say so and use `sbx.exe`. On an Ubuntu 24.04 distribution with KVM, Docker's Linux route is the alternative:

```bash
curl -fsSL https://get.docker.com | sudo REPO_ONLY=1 sh
sudo apt install docker-sbx
```

Result (2026-11-14/15, WSL2 bash on the engineer's host):

Differed from the plan: no elevation and no Windows-feature step was asked for, and the install worked.

```
Successfully installed            (winget.exe, Docker Sandboxes 0.53.0)
$ sbx --version
Command 'sbx' not found
$ sbx.exe --version
sbx version v0.53.0 2c62838074738845f8f1096ff5f8920df61152fb
```

`sbx` stayed not found after `wsl.exe --shutdown`; from WSL the program is `sbx.exe`. `sbx.exe login` used a device-code flow, printed `Signed in as <account>`, then `warning: schedule credential exchange failed: the schedule service could not verify your Docker sign-in` (did not block anything later). The Linux route was not tried: no KVM.


**T3: create a sandbox on a fresh clone.** Settles U2, D3 and the creation time.

```bash
git clone https://github.com/kbajpai/codeo codeo-sbx-a
cd codeo-sbx-a
sbx policy init balanced
time sbx create --clone --name codeo-a claude .
sbx ls
```

Expected: the clone is made, `sbx ls` lists `codeo-a`, and the time of the create command is printed. Say where the clone lives (Windows folder, WSL2 filesystem, or inside the sandbox), and quote any `safe.directory` error (U3).

Result (2026-11-14/15, WSL2 bash on the engineer's host):

Differed from the plan: the first `sbx.exe create` failed in 1.3 s, and Windows Git needed a `safe.directory` line. The clone was in the WSL home (`~/Source/codeo-sbx-a`).

```
error: --clone cannot use \\wsl.localhost\Ubuntu-24.04\home\<user>\Source\codeo-sbx-a as a Git repository: git failed: fatal: detected dubious ownership in repository at '//wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-a'
try: git.exe config --global --add safe.directory "%(prefix)///wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-a"
```

After `git.exe config --global --add safe.directory '%(prefix)///wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-a'`:

```
✓ Created sandbox codeo-a
CPU 20, Memory 32 GiB   source \\wsl.localhost\... -> /run/sandbox/source (ro)
real 1m46.930s
codeo-a  claude  running  127.0.0.1:60000->9418/tcp4
```

`sbx.exe policy init balanced` printed `Initialized global network policy balanced`. The clone lives inside the sandbox; the host folder is read-only at `/run/sandbox/source`.


**T4: run the suite inside the sandbox.** Settles U4 and the claim that the repository's tests run in a sandbox.

```bash
sbx exec codeo-a bash tests/run.sh
```

Expected: `bash tests/run.sh` exits 0 and ends `all cases passed`. A failure on file modes is U4's finding.

Result (2026-11-14/15, WSL2 bash on the engineer's host):

`time sbx.exe exec codeo-a bash tests/run.sh` printed `all cases passed`, `real 2m37.938s`. File modes: `git ls-files -s tests/run.sh` printed `100644` (run as `bash tests/run.sh`), `ls -l` in the sandbox showed `-rw-r--r--` for it and `-rwxr-xr-x` for every file under `scripts/`, so the bit the index records survives (2026-11-14).


**T5: stop and start, timed.** Settles D3.

```bash
sbx stop codeo-a
time sbx run -d --name codeo-a
sbx ls
```

Expected: the sandbox stops, starts again by name, and the start time is printed. Docker's pages give `sbx run --name <n>` as the way to reattach; whether `-d` combines with a reattach is not documented, so record the error if there is one.

Result (2026-11-14/15, WSL2 bash on the engineer's host):

```
Stopped sandbox codeo-a
✓ sandbox codeo-a — started       real 0m5.602s
codeo-a  claude  running (detached)
```

`-d` does combine with reattaching by name (the docs left it open). The git daemon port changed from `60000` to `60002`; the sandbox was the same one (7 minutes old). (2026-11-14)


**T6: logins.** Settles D7, U8, U10.

```bash
sbx secret set github --command 'gh auth token'
sbx secret ls
sbx exec codeo-a gh auth status
sbx exec codeo-a claude auth status
```

Expected: `sbx secret ls` shows `github`; inside the sandbox `gh auth status` reports a login (token masked); `claude auth status` reports a login after `/login` has been run in Claude Code, or none, which is the finding. The single quotes are Docker's own example.

Result (2026-11-14/15, WSL2 bash on the engineer's host):

```
✓ command resolved successfully
Applied global secret to existing sandboxes
Saved command secret github (global)
Logged in to github.com account <user> (GH_TOKEN)   scopes: delete_repo, gist, project, read:org, read:packages, repo, workflow
claude auth status (before login): loggedIn: false, authMethod: none
claude auth status (after /login):  loggedIn: true, authMethod: claude.ai, loginExpiresAt: 2026-12-12
```

Differed from the plan: `claude auth status` needed an interactive `sbx.exe exec -it codeo-a claude` and `/login` first (`Login successful`). The secret is global and applied to the running sandbox without a restart. The `gh` token carries the host token's full scopes, including `delete_repo`.


**T7: restart persistence.** Settles D7, D8, U12, U16.

```bash
sbx stop codeo-a
sbx run -d --name codeo-a
sbx exec codeo-a gh auth status
sbx exec codeo-a claude auth status
sbx exec codeo-a bash .devcontainer/scripts/plugins.sh
sbx exec codeo-a claude plugin list
```

Expected: `plugins.sh` prints `plugins: superpowers, codeo v1.0.6` and exits 0; the two logins and the plugin list are as before the restart, or the output shows which was lost.

Result (2026-11-14/15, WSL2 bash on the engineer's host):

```
gh auth status: still logged in (GH_TOKEN), same scopes
claude auth status: loggedIn: true, authMethod: claude.ai, loginExpiresAt unchanged
git config user.name: (nothing printed)
claude plugin list (before plugins.sh): No plugins installed
plugins: installed superpowers / plugins: installed codeo v1.0.6 / plugins: superpowers, codeo v1.0.6
claude plugin list: codeo@codeo 1.0.6 enabled; superpowers@superpowers-marketplace 7.0.2 enabled
```

Both logins survive a restart. The sandbox has no git identity. `plugins.sh` ran unchanged. Whether the plugins survive a restart was not shown (installed after it).


**T8: remove and recreate.** Settles D3, D7, U16.

```bash
sbx rm codeo-a
time sbx create --clone --name codeo-a claude .
sbx exec codeo-a gh auth status
sbx exec codeo-a claude auth status
sbx exec codeo-a claude plugin list
```

Expected: the three outputs of T7 repeated, so "survives a restart" and "survives a rebuild" are separate findings. Anything in the clone that was not pushed is gone, which is documented.

Result (2026-11-14/15, WSL2 bash on the engineer's host):

`sbx.exe rm codeo-a` warned that commits inside a `--clone` sandbox are lost unless fetched (`git fetch sandbox-codeo-a` mirrors into `refs/sandboxes/codeo-a/*`) or pushed, asked `Remove sandbox 'codeo-a'? ... (y/N)`, and printed `Removed sandbox codeo-a`.

```
create: real 0m13.078s   (assembled kit image ready (cached); git daemon port 60004)
gh auth status: logged in
claude auth status: loggedIn: true, authMethod: claude.ai, storedClaudeAiLogin: true (loginExpiresAt, email, orgId, orgName: null)
claude plugin list: No plugins installed
claude -p "reply with the single word: ok": ok
```

The Claude login worked in the recreated sandbox with no login step; plugins did not survive the recreate. `claude -p` was added to the plan's commands to check the login works.


**T9: two sandboxes at once.** Settles D4.

```bash
git clone https://github.com/kbajpai/codeo codeo-sbx-b
cd codeo-sbx-b
sbx create --clone --name codeo-b claude .
sbx ls
sbx exec codeo-a bash tests/run.sh
sbx exec codeo-b bash tests/run.sh
sbx exec codeo-b free -m
```

Expected: `sbx ls` shows `codeo-a` and `codeo-b` running together; the suite exits 0 in each; `free -m` shows the memory in use.

Result (2026-11-14/15, WSL2 bash on the engineer's host):

Differed from the plan, four attempts:

- First: the second clone landed inside the first (`~/Source/codeo-sbx-a/codeo-sbx-b`); `create` failed in 1.3 s with the same dubious-ownership error, so the `safe.directory` step is per clone. Solo suite in `codeo-a`: `real 2m35.310s`.
- Second (from `~/Source`, after another `safe.directory` line): `codeo-b` created in `real 0m13.599s` (port `60006`). `sbx.exe ls` then showed `codeo-b running` and `codeo-a stopped`, with no `stop` issued. Re-running the block: `error: sandbox 'codeo-b' already exists; connect to the existing sandbox`.
- Third: `sbx.exe run -d --name codeo-a` left `codeo-a running (detached)` and `codeo-b stopped`. Suites run one after the other: `codeo-a` `real 2m51.385s`, `codeo-b` `real 3m8.409s`, both `all cases passed`.
- Fourth: with `codeo-a` running, `sbx.exe run -d --name codeo-b` left both `running (detached)` (ports `60007`, `60009`), so one sandbox does not stop the other as a rule; the two earlier stops are unexplained.

Parallel run, suites started in both at about the same time: `codeo-a` `real 3m10.790s`, `codeo-b` `real 3m10.205s`, both `all cases passed` (about 23% longer than solo). `free -m` and an `ls` after the run were not pasted.


**T10: resource limits.** Settles D6, U17.

```bash
sbx create --help
sbx create --clone --cpus 2 --memory 4g --name codeo-lim claude .
sbx exec codeo-lim nproc
sbx exec codeo-lim free -m
```

Expected: `sbx create --help` lists `--cpus` and `--memory` with the defaults cited above; `nproc` prints `2`; `free -m` shows about 4096 MiB total. If it differs, say so.

Result (2026-11-14/15, WSL2 bash on the engineer's host):

```
--cpus int      0 = auto: all host CPUs
-m, --memory    Minimum: 512 MiB. Default: 50% of host memory, clamped to 512 MiB-32 GiB. Maximum: host memory. Warns above 75% of host memory
create summary: CPU: 2   Memory: 4g
nproc: 2
Mem: 3997 (total MiB)   147 used   Swap: 0
```

Limits are enforced. The sandbox needed its own clone (`codeo-sbx-lim`) and its own `safe.directory` line. The defaults on this host were 20 CPUs and 32 GiB. The Claude kit digest differed from the first create's (`0fb3e2c5...` against `4df39400...`).


**T11: network policy.** Settles D9.

```bash
sbx policy ls
sbx exec codeo-a curl -sI https://github.com
sbx exec codeo-a curl -sI https://example.org
```

Expected: the first `curl` returns an HTTP status line (`balanced` allows code hosts); the second is blocked or waits for approval under `balanced`, which Docker's policy page describes as "blocked and you're asked to approve them". Record exactly what each printed.

Result (2026-11-14/15, WSL2 bash on the engineer's host):

```
sbx.exe policy ls: sandbox:codeo-a / codeo-b / codeo-lim (kit, network: 8 allow each); default-deny-all; local-policy (network: 195 allow)
curl -sI https://github.com   -> HTTP/1.1 200 OK (tunnel), HTTP/1.1 200 OK (GitHub)
curl -sI https://example.org  -> HTTP/1.1 200 OK (tunnel), HTTP/1.1 403 Forbidden, Content-Length: 90, Content-Type: text/plain
curl -sI --max-time 20 https://example.net -> the same 403
```

Differed from the plan: the blocked host got an immediate `403 Forbidden`, not an approval prompt and not a hang, in a non-interactive `exec`.


**T12: editor attach.** Settles D10, U13, U18.

```bash
sbx setup ssh
ssh codeo-a.sbx
```

Then, in VS Code on Windows, run **Remote-SSH: Connect to Host…** and enter `codeo-a.sbx` by hand (the host picker does not list sandboxes). Expected: `ssh codeo-a.sbx` gives a shell; VS Code opens a remote window at `/home/agent` or the workspace path; say whether the Claude Code extension, the ShellCheck extension and the Mermaid extension install and work there, and whether `window.title` has any effect. Record "no way to" for any of these that fails.

Result (2026-11-14/15, WSL2 bash on the engineer's host):

Differed from the plan: plain `ssh` failed from WSL and `ssh.exe` was needed.

```
Status: enabled · signed in as <account>
Access: *.sbx -> sandboxd.sock (no port · login-gated)
warning: sh is not on the Windows PATH
$ ssh codeo-a.sbx
ssh: Could not resolve hostname codeo-a.sbx: Name or service not known
$ ssh.exe codeo-a.sbx -- echo hello
hello
```

`sbx.exe setup ssh` wrote the Windows user's `~/.ssh/config`, which Linux `ssh` in WSL does not read; the `sh` warning did not stop `ssh.exe`. VS Code Remote-SSH to `codeo-a.sbx` connected. The window opened no folder (Open Folder chosen by hand). The only extension present was GitHub Pull Requests: the Claude Code, ShellCheck and Markdown Mermaid extensions were not there. No network errors were seen. The integrated terminal ran `claude`. `window.title` was not tried.


## Recommendation

_Pending — written in Task 7._

## Follow-up issues

_Pending — filled in Task 7._
