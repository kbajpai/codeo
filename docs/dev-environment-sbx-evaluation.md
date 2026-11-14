# Evaluation: Docker Sandboxes (`sbx`) against the dev container

> **Status: draft, documentation read only.** Every row below rests on Docker's documentation (`cited`). Nothing has been run on a real host yet, so nothing is `tried`. The trials listed under Trials are the engineer's to run; their output replaces `cited` with `tried T<n>`. The recommendation is not written yet.

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

Whether `sbx` runs there: **not yet known** (`yes`, `no` or `partly` is filled in from T1 and T2).

What Docker's pages say, which does not settle it:

- Windows: Windows 11, a 64-bit Intel or AMD processor, and Windows Hypervisor Platform, "required for local sandboxes". Install is `winget install -h Docker.sbx` from Windows (or an administrator MSI). Docker's install page does not mention WSL or WSL2. (install, read 2026-11-14)
- Linux: Ubuntu 24.04 or later, KVM turned on, the user in the `kvm` group; a virtual machine "must support nested virtualization". Whether a WSL2 distribution counts as such a Linux host is not documented. (install, read 2026-11-14)
- The only WSL mention is a troubleshooting entry: on Windows, `sbx run --clone` against a repository on a WSL filesystem can fail with "not in a Git repository" because of Git's dubious-ownership check, fixed by adding the repository to `safe.directory`. (troubleshooting, read 2026-11-14)

So the plan's assumption that `sbx` is run in bash inside WSL2 is not what the documentation describes: the documented Windows route is a Windows install, and the documented Linux route needs KVM. T1 and T2 settle which of the two this host takes.

## Drivers

The four drivers from the issue come first, then the further points the issue asks about.

| ID | Driver | Dev container today | `sbx` | Evidence |
|---|---|---|---|---|
| D1 | Isolation and safety | A container on the host kernel through Docker; `dev` has passwordless sudo (`.devcontainer/Dockerfile`). | Each sandbox is a microVM with its own kernel, its own Docker Engine and deny-by-default network; credentials stay outside the VM. Inside the VM the agent still has sudo; the VM is the boundary. A directly mounted workspace is read-write on the host, so Git hooks and build scripts in it deserve review; clone mode mounts the host repository read-only. | cited https://docs.docker.com/ai/sandboxes/security/ (read 2026-11-14) |
| D2 | VS Code dependency | The container opens only through **Dev Containers: Clone Repository in Named Container Volume…** (`.devcontainer/README.md`). | Sandboxes are created and run from the terminal (`sbx run`, `sbx create`, `sbx exec -it <name> bash`). Editors are optional: VS Code and Cursor can attach over SSH after `sbx setup ssh`. | cited https://docs.docker.com/ai/sandboxes/usage/ (read 2026-11-14) |
| D3 | Per-issue lifecycle | One container and one named volume per issue, named by the clone folder; cleanup is by hand (#70); `~/.claude` is lost on a rebuild (`.devcontainer/README.md`). | `sbx run --name <n> claude`, `sbx ls`, `sbx stop`, `sbx rm`, and `sbx prune --filter until=168h` for sandboxes stopped over a week. Packages, images and configuration persist across stop and start; `sbx rm` deletes the container filesystem. | cited https://docs.docker.com/ai/sandboxes/usage/ (read 2026-11-14) |
| D4 | Parallel agents | Several containers can run at once, each with its own name, clone and volume (`.devcontainer/README.md`). | Several sandboxes, each with a distinct name; the same workspace path with different names is allowed. Each sandbox has its own Docker daemon and image cache, and sandboxes do not share images or layers. How many can run at once on one machine is not documented. | cited https://docs.docker.com/ai/sandboxes/usage/ (read 2026-11-14) |
| D5 | Host support (Windows + WSL2) | Docker (Docker Desktop or the WSL2 engine) on the Windows host; VS Code on Windows (`.devcontainer/devcontainer.json`). | Windows 11 with Windows Hypervisor Platform, installed with winget; Linux needs KVM. WSL2 is not mentioned on the install page; `cited: not documented` whether `sbx` runs from inside a WSL2 distribution. | cited https://docs.docker.com/ai/sandboxes/install/ (read 2026-11-14) |
| D6 | Resource limits | `--memory=4g --cpus=2` in `runArgs` (`.devcontainer/devcontainer.json`). | `sbx create --cpus N --memory 4g`: `--cpus` defaults to 0 (all host CPUs, capped at 16 on Linux arm64); `--memory` defaults to 50% of host memory, clamped to 512 MiB to 32 GiB, with a maximum of the greater of 75% of host memory and 512 MiB. Also `sandboxOptions.cpus` and `sandboxOptions.memory` in a sandbox environment file (experimental `sbx env`). The usage page itself says it does not cover limit flags; the flag defaults come from the `sbx create` reference as quoted in a search result, to be confirmed by T10. | cited https://docs.docker.com/reference/cli/sbx/create/ (read 2026-11-14) |
| D7 | `gh`, git and Claude login persistence | `gh` and git config on the `codeo-gh` and `codeo-git` volumes; Claude login lost on a rebuild (`.devcontainer/README.md`, `.devcontainer/devcontainer.json`). | Secrets live in the host's keychain (Windows Credential Manager, macOS Keychain, Linux Secret Service, else a `0700` file) and a host-side proxy injects them; they take effect in existing sandboxes without a restart. `sbx secret set github --command 'gh auth token'` covers `gh`. Claude: `/login` inside the sandbox runs OAuth with the token kept on the host, or `sbx secret set anthropic` for a key. Git identity (`user.name`, `user.email`): `cited: not documented`. Whether the Claude `/login` survives `sbx rm`: `cited: not documented`. | cited https://docs.docker.com/ai/sandboxes/configuration/credentials/ (read 2026-11-14) |
| D8 | Plugin installation | `.devcontainer/scripts/plugins.sh` installs `superpowers` and `codeo` at the pin in `.codeo/config.json`, run from `postCreateCommand`. | Local sandboxes do not import `~/.claude`; only project-level configuration in the working directory is available. `cited: not documented` how to install Claude plugins. Documented neighbours: `sbx skills add` / `sbx skills import` (skills, not plugins), kits, and lifecycle commands in an environment file, which run on the host. Whether `claude plugin install` run inside the sandbox works and survives a restart is for T7. | cited https://docs.docker.com/ai/sandboxes/faq/ (read 2026-11-14) |
| D9 | Network policy | None set; the container has the host's network (`.devcontainer/devcontainer.json`). | Outbound TCP goes through a host proxy under a preset: `allow-all`, `balanced` (deny by default with a baseline allowlist) or `deny-all`; `sbx policy ls` shows rules and `sbx policy allow network <host>` adds one. UDP is blocked unless an experimental feature is on and ICMP is always blocked. Docker warns the default allowed domains include broad wildcards. | cited https://docs.docker.com/ai/sandboxes/security/policy/ (read 2026-11-14) |
| D10 | Editor attach | VS Code attaches through the Dev Containers extension (`.devcontainer/devcontainer.json`). | `sbx setup ssh` writes a managed block in `~/.ssh/config` (`%USERPROFILE%\.ssh\config` on Windows); then `ssh <name>.sbx` and VS Code or Cursor Remote-SSH to host `<name>.sbx`. No SSH server runs in the sandbox; connection goes through the local daemon. A stopped sandbox starts on connect. The Claude Code VS Code extension is `cited: not documented` on the integrations page. | cited https://docs.docker.com/ai/sandboxes/integrations/ (read 2026-11-14) |

## Duties of the current setup

One row for each duty the issue lists, with the `devcontainer-start.sh` steps taken one by one. The answer is an `sbx` equivalent, a workaround, or `no equivalent`.

| ID | Duty | Current mechanism | `sbx` equivalent, workaround or `no equivalent` | Evidence |
|---|---|---|---|---|
| U1 | Home/issue split | Two kinds of container: `codeo-home` on `main`, `codeo-<N>` on an issue's branch (`.devcontainer/README.md`, `.devcontainer/scripts/container-name.sh`). | Workaround: two kinds of named sandbox, `sbx create --name codeo-home` and `--name codeo-<N>`; nothing in `sbx` knows the difference, so the naming stays a convention. | cited https://docs.docker.com/ai/sandboxes/usage/ (read 2026-11-14) |
| U2 | One clone per issue | Each container is its own clone in its own Docker volume, opened with Clone Repository in Named Container Volume (`.devcontainer/README.md`). | Equivalent: `sbx run --clone claude .` makes a private Git clone inside the sandbox; the host repository is readable at `/run/sandbox/source`. The clone follows whatever ref the host has checked out and creates no branch; to start on the branch `/codeo:init` pushed, it is checked out on the host first (so that branch is checked out in the host checkout, not a second one), or the agent switches branches inside. Clone mode is fixed at create time and removing the sandbox deletes the clone. Mountless sandboxes (no host mount, v0.42.0 or later) are the other model. | cited https://docs.docker.com/ai/sandboxes/workflows/git/ (read 2026-11-14) |
| U3 | Trust and chown of the clone | Step 1 of `.devcontainer/scripts/devcontainer-start.sh`: `safe.directory`, and `sudo chown` of a clone on a Docker volume. | No equivalent needed in clone mode: the agent owns its clone inside the sandbox. Documented hazard on the Windows side: a repository on a WSL filesystem fails `sbx run --clone` until added to `safe.directory`. | cited https://docs.docker.com/ai/sandboxes/troubleshooting/ (read 2026-11-14) |
| U4 | Executable-bit repair | Step 2b of `devcontainer-start.sh`: `core.fileMode` probe and `chmod +x` of files the index records as 100755. | `cited: not documented` whether the clone keeps the executable bit. A clone inside the sandbox lives on the VM's own filesystem, so the repair is probably unneeded; T4 shows whether the suite passes. | cited https://docs.docker.com/ai/sandboxes/architecture/ (read 2026-11-14) |
| U5 | Workflow lock from `init.md` | Step 3a of `devcontainer-start.sh`: codeo's `lock.sh` takes `.codeo/active` from the `init.md` on the branch, in an issue container only. | Workaround: run the same script by hand or as the sandbox's first command (`sbx exec`); `sbx` has no create-time hook. Environment files have `lifecycle.initialize` and `lifecycle.postCreate`, but these run on the host, not in the sandbox, and `sbx env` is experimental. | cited https://docs.docker.com/ai/sandboxes/configuration/environment-files/ (read 2026-11-14) |
| U6 | Folder check | Step 3a' of `devcontainer-start.sh` and `.devcontainer/scripts/folder-check.sh`: the clone folder must equal the container's Docker name. | No equivalent needed: the Docker-name constraint is Docker's rule for container names, and a sandbox is named by `--name`. The check would instead compare the sandbox name with the lock. | cited https://docs.docker.com/ai/sandboxes/usage/ (read 2026-11-14) |
| U7 | TODO lines | Step 7 of `devcontainer-start.sh` prints what is left for the engineer (logins, identity, scope). | Workaround: the script can be run unchanged inside the sandbox; whether it can run at creation is U5's answer. | cited https://docs.docker.com/ai/sandboxes/configuration/environment-files/ (read 2026-11-14) |
| U8 | `gh` wiring and project-scope check | Step 4 of `devcontainer-start.sh`: `gh auth setup-git`, then a check that the token has the project scope; login state on the `codeo-gh` volume. | Equivalent for the login: `sbx secret set github --command 'gh auth token'`, refreshed from that command; `gh` works in the sandbox. Whether the token's scopes carry over, and the project-scope check itself, are not documented. | cited https://docs.docker.com/ai/sandboxes/configuration/credentials/ (read 2026-11-14) |
| U9 | Git identity seeding | Step 5 of `devcontainer-start.sh`: `user.name` and `user.email` from the host `~/.gitconfig` that VS Code copies in, else `GIT_AUTHOR_*`. | `cited: not documented` whether the host `.gitconfig` reaches the sandbox. Workaround: pass `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL` with `-e` or `--env-file` on `sbx create` (stored with the sandbox) and let step 5 run. | cited https://docs.docker.com/ai/sandboxes/usage/ (read 2026-11-14) |
| U10 | Claude login check | Step 6 of `devcontainer-start.sh`: `claude auth status`, with a TODO when not logged in; login lost on rebuild. | Equivalent: `/login` inside the sandbox (OAuth on the host, "the session token stays on your host and is never stored inside the sandbox"), or `sbx secret set anthropic`. | cited https://docs.docker.com/ai/sandboxes/agents/claude-code/ (read 2026-11-14) |
| U11 | Remote Control setting | Step 3c of `devcontainer-start.sh`: `remoteControlAtStartup` merged into the user's Claude settings. | Equivalent: `sbx settings set claude.remoteControl true`, after which `/remote-control` is available. Remote Control is out of scope for the recommendation, so this is recorded as a cost or gain only. | cited https://docs.docker.com/ai/sandboxes/agents/claude-code/ (read 2026-11-14) |
| U12 | `plugins.sh` | `.devcontainer/scripts/plugins.sh` runs `claude plugin marketplace add` and `claude plugin install` for `superpowers` and for `codeo` at the pin. | Workaround: run the script inside the sandbox. `cited: not documented` whether Claude plugins install there; user-level config is not imported. | cited https://docs.docker.com/ai/sandboxes/faq/ (read 2026-11-14) |
| U13 | Window title | `.devcontainer/scripts/window-title.sh` writes `window.title` into `.vscode/settings.json` ("codeo [home]" or "codeo [#N]"). | No equivalent for a window title. The sandbox name (`sbx ls`, and `<name>.sbx` in an editor) can carry the same text. | cited https://docs.docker.com/ai/sandboxes/integrations/ (read 2026-11-14) |
| U14 | Session titles | `.devcontainer/scripts/session-title.sh`, a Claude hook, only when `REMOTE_CONTAINERS=true`. | Workaround: the hook is registered by the project and project-level configuration carries over; the `REMOTE_CONTAINERS` test must change. | cited https://docs.docker.com/ai/sandboxes/faq/ (read 2026-11-14) |
| U15 | `codeo-gh` volume | Named volume mounted at `/home/dev/.config/gh` (`.devcontainer/devcontainer.json`). | Equivalent in effect: the `github` secret in the host keychain replaces the stored `gh` login. A named volume mounted into a sandbox: `cited: not documented` (persistent kit volumes exist, and survive removal). | cited https://docs.docker.com/ai/sandboxes/usage/ (read 2026-11-14) |
| U16 | `codeo-git` volume | Named volume at `/home/dev/.config/git`, with `GIT_CONFIG_GLOBAL` pointing at it (`.devcontainer/devcontainer.json`). | Git config set inside a sandbox persists across stop and start; it is deleted with `sbx rm`, so `no equivalent` of a volume that outlives the sandbox other than a kit volume or a saved template (`sbx template save`). | cited https://docs.docker.com/ai/sandboxes/usage/ (read 2026-11-14) |
| U17 | Memory and CPU limits | `--memory=4g --cpus=2` in `runArgs` (`.devcontainer/devcontainer.json`). | Equivalent: `sbx create --memory 4g --cpus 2`, or `sandboxOptions` in an environment file. | cited https://docs.docker.com/ai/sandboxes/configuration/environment-files/ (read 2026-11-14) |
| U18 | The three VS Code extensions | `anthropic.claude-code`, `timonwong.shellcheck`, `bierner.markdown-mermaid` (`.devcontainer/devcontainer.json`). | No equivalent as a setting: the editor's remote host decides which extensions load. `cited: not documented` for any of the three over `<name>.sbx`; T12 tries Claude Code's. | cited https://docs.docker.com/ai/sandboxes/integrations/ (read 2026-11-14) |

## Trials

Each trial is run in bash in a WSL2 distribution, one plain command per line, unless T1 or T2 shows `sbx` can be run only from Windows (then `sbx.exe` is called from bash through Windows interop, or the commands are run in PowerShell, and the page says which). Names used below: sandbox `codeo-a`, clone folder `codeo-sbx-a`; second sandbox `codeo-b`, clone folder `codeo-sbx-b`. Paste every output with tokens and account names redacted. A trial's output is quoted under its number when it is run, with the date and the host.

**T1: host facts.** Settles D5 and Host.

```bash
cmd.exe /c ver
wsl.exe --status
docker --version
command -v sbx
lsmod | grep kvm
```

Expected: a Windows 11 build number; WSL version 2 and the default distribution; the Docker version or an error; `sbx` absent (no output); `lsmod` showing `kvm_intel` or `kvm_amd` when the distribution can run KVM, and nothing when it cannot.

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

**T3: create a sandbox on a fresh clone.** Settles U2, D3 and the creation time.

```bash
git clone https://github.com/kbajpai/codeo codeo-sbx-a
cd codeo-sbx-a
sbx policy init balanced
time sbx create --clone --name codeo-a claude .
sbx ls
```

Expected: the clone is made, `sbx ls` lists `codeo-a`, and the time of the create command is printed. Say where the clone lives (Windows folder, WSL2 filesystem, or inside the sandbox), and quote any `safe.directory` error (U3).

**T4: run the suite inside the sandbox.** Settles U4 and the claim that the repository's tests run in a sandbox.

```bash
sbx exec codeo-a bash tests/run.sh
```

Expected: `bash tests/run.sh` exits 0 and ends `all cases passed`. A failure on file modes is U4's finding.

**T5: stop and start, timed.** Settles D3.

```bash
sbx stop codeo-a
time sbx run -d --name codeo-a
sbx ls
```

Expected: the sandbox stops, starts again by name, and the start time is printed. Docker's pages give `sbx run --name <n>` as the way to reattach; whether `-d` combines with a reattach is not documented, so record the error if there is one.

**T6: logins.** Settles D7, U8, U10.

```bash
sbx secret set github --command 'gh auth token'
sbx secret ls
sbx exec codeo-a gh auth status
sbx exec codeo-a claude auth status
```

Expected: `sbx secret ls` shows `github`; inside the sandbox `gh auth status` reports a login (token masked); `claude auth status` reports a login after `/login` has been run in Claude Code, or none, which is the finding. The single quotes are Docker's own example.

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

**T8: remove and recreate.** Settles D3, D7, U16.

```bash
sbx rm codeo-a
time sbx create --clone --name codeo-a claude .
sbx exec codeo-a gh auth status
sbx exec codeo-a claude auth status
sbx exec codeo-a claude plugin list
```

Expected: the three outputs of T7 repeated, so "survives a restart" and "survives a rebuild" are separate findings. Anything in the clone that was not pushed is gone, which is documented.

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

**T10: resource limits.** Settles D6, U17.

```bash
sbx create --help
sbx create --clone --cpus 2 --memory 4g --name codeo-lim claude .
sbx exec codeo-lim nproc
sbx exec codeo-lim free -m
```

Expected: `sbx create --help` lists `--cpus` and `--memory` with the defaults cited above; `nproc` prints `2`; `free -m` shows about 4096 MiB total. If it differs, say so.

**T11: network policy.** Settles D9.

```bash
sbx policy ls
sbx exec codeo-a curl -sI https://github.com
sbx exec codeo-a curl -sI https://example.org
```

Expected: the first `curl` returns an HTTP status line (`balanced` allows code hosts); the second is blocked or waits for approval under `balanced`, which Docker's policy page describes as "blocked and you're asked to approve them". Record exactly what each printed.

**T12: editor attach.** Settles D10, U13, U18.

```bash
sbx setup ssh
ssh codeo-a.sbx
```

Then, in VS Code on Windows, run **Remote-SSH: Connect to Host…** and enter `codeo-a.sbx` by hand (the host picker does not list sandboxes). Expected: `ssh codeo-a.sbx` gives a shell; VS Code opens a remote window at `/home/agent` or the workspace path; say whether the Claude Code extension, the ShellCheck extension and the Mermaid extension install and work there, and whether `window.title` has any effect. Record "no way to" for any of these that fails.

## Recommendation

_Pending — written in Task 7._

## Follow-up issues

_Pending — filled in Task 7._
