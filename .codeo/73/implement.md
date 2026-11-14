# Issue #73 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/73 |
| Branch | `docs/evaluate-docker-sandboxes-sbx-against` |
| Updated | 2026-11-14 |

## Where this stands

Task 1 is done and committed (`9bddbbc`): `docs/dev-environment-sbx-evaluation.md` has 28 rows (10 drivers, 18 duties), every one `cited` with a Docker URL, and trials T1-T12. `bash tests/run.sh` exits 0, no evidence cell is blank, and `.devcontainer/` and `skills/` are unchanged.

Q1 is answered (route A, Windows native) and T1 is run. Nothing is open. Next is the engineer's T2 (install `sbx`), then T3-T12 in `docs/dev-environment-sbx-evaluation.md` → `## Trials` in order, each output pasted into the conversation with tokens and account names redacted. Tasks 6-7 follow.

## Questions

### Q1 — Which install route should T1-T2 follow on your machine?

**Why it matters:** Docker documents two. The plan assumed one (`sbx` in bash inside WSL2), and the choice decides what T1-T2 run, which shell they need, and whether Task 2 has a step that is not bash.
**Options:**
- **A — Windows native.** `winget.exe install -h Docker.sbx` run from WSL bash, after enabling Windows Hypervisor Platform from an *elevated PowerShell* (`Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All`, a restart may be needed). `sbx` then runs as `sbx.exe` through Windows interop, or from PowerShell. This is the Windows route in Docker's install page and the one I'd try first on Windows + WSL2.
- **B — Linux inside WSL2.** An Ubuntu 24.04 or later distribution with KVM and nested virtualization (`lsmod | grep kvm` in T1 shows whether the distribution can), then `sudo apt install docker-sbx`. All bash, but only if the distribution has KVM.
- **C — run T1 first and decide from its output.** T1 is five read-only commands; paste them and I pick the route.

**Answer:**
C — run T1 first (given in the conversation, 2026-11-14). T1's output came back; the route it points to is A, Windows native (see Notes).

## Notes

- **T1 output, as pasted** (WSL2 bash on the engineer's host, 2026-11-14; `cmd.exe` printed its UNC-path warning first, harmless):
  ```
  Microsoft Windows [Version 10.0.26300.9818]
  Default Distribution: Ubuntu-24.04
  Default Version: 2
  Docker version 29.9.3, build 5457199
  ```
  `command -v sbx` and `lsmod | grep kvm` printed nothing: `sbx` is not installed, and the distribution has no `kvm` module loaded.
- **T2, first run (2026-11-14, WSL2 bash):** `winget.exe install -h Docker.sbx` found Docker Sandboxes 0.53.0, downloaded `DockerSandboxes.msi` (177 MB) from `github.com/docker/sbx-releases`, verified the installer hash and printed `Successfully installed`, with no elevation or Windows-feature step asked for. Straight afterwards `sbx login` and `sbx --version` both printed `Command 'sbx' not found` from the distribution's shell. The install worked; the running WSL session does not have the new Windows PATH entry. Next: `sbx.exe --version`, and if that is not found either, restart WSL.
- **T1-T2, second run (2026-11-14), after `wsl.exe --shutdown` and a new terminal:** T1 printed the same as the first run; `command -v sbx` and `sbx --version` still said `command not found`. `sbx.exe --version` printed `sbx version v0.53.0 2c62838074738845f8f1096ff5f8920df61152fb`. So the restart was not the cause: **from WSL the program is `sbx.exe`, not `sbx`** — the Windows PATH is passed through (the install's `…/AppData/Local/DockerSandboxes/bin/` is on the WSL `$PATH`, and Docker Desktop's `resources/bin` is there too), and interop resolves the name with its `.exe`. `/etc/wsl.conf` has `systemd=true` and an automount `options = "metadata,uid=1001,gid=1001,umask=22,fmask=11"` (relevant to the executable-bit row U4 for any clone on `/mnt/c`). Every later trial uses `sbx.exe` where the page says `sbx`; the page's `## Host` records this in Task 6.
- **T2 login (2026-11-14):** `sbx.exe login` used a device-code flow (a code and a `login.docker.com/activate` URL, completed in the browser), printed `Signed in as <account>` and then `warning: schedule credential exchange failed: the schedule service could not verify your Docker sign-in`. The account name and the one-time code are not recorded here. Whether the warning matters is open until T3's create and run succeed or fail; the page's Host section records it either way.
- **T3, first run (2026-11-14), clone in the WSL home (`~/Source/codeo-sbx-a`):** `git clone` fine. `sbx.exe policy init balanced` printed `✓ started daemon (1s)` and `Initialized global network policy balanced`. `sbx.exe create --clone --name codeo-a claude .` then failed in 1.3 s with `claude — now ships as a kit; resolving docker.io/sbx/claude:latest` and `error: --clone cannot use \\wsl.localhost\Ubuntu-24.04\home\<user>\Source\codeo-sbx-a as a Git repository: git failed: fatal: detected dubious ownership in repository at '//wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-a'`, with the hint `try: git.exe config --global --add safe.directory "%(prefix)///wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-a"`. `sbx.exe ls` then said `No sandboxes found`. This is the failure the docs' troubleshooting page describes (row U3): from WSL, `sbx.exe` turns the path into a `\\wsl.localhost` UNC path and runs Windows `git.exe` on it, which does not trust a repository owned by the WSL user. The warning from `login` did not appear and was not the cause.
- **T3, second run (2026-11-14), after `git.exe config --global --add safe.directory '%(prefix)///wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-a'` (route A for the dubious-ownership error, a one-line change to the Windows global Git config):** `sbx.exe create --clone --name codeo-a claude .` succeeded. Output: `claude — now ships as a kit; resolving docker.io/sbx/claude:latest`, `✓ workspace — Git repository at \\wsl.localhost\Ubuntu-24.04\home\<user>\Source\codeo-sbx-a`; sandbox `codeo-a`, agent `claude`, kit/image `docker.io/sbx/claude@sha256:4df39400…`; workspace mapped `\\wsl.localhost\…\codeo-sbx-a → /wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-a (rw)`; skills mount `0 entries · read-only` at `/home/agent/.claude/skills`; **CPU 20, Memory 32 GiB** (the sandbox's defaults on this machine; the dev container is `--cpus=2 --memory=4g`); `Git daemon: git://127.0.0.1:60000/codeo-sbx-a`, `Remote: sandbox-codeo-a`; `✓ Created sandbox codeo-a`, `source \\wsl.localhost\… → /run/sandbox/source (ro)`. `real 1m46.930s` (the first create, so it includes pulling the image). `sbx.exe ls`: `codeo-a  claude  ● running  127.0.0.1:60000->9418/tcp4`, 9 s old. Settles for rows U2 and D3: a sandbox on a clone works from WSL once Windows Git trusts the folder; the clone is inside the sandbox with the host folder read-only at `/run/sandbox/source`.
- **T4 (2026-11-14):** `time sbx.exe exec codeo-a bash tests/run.sh` printed `all cases passed`, `real 2m37.941s`. The suite passes inside a sandbox on a clone, from the default working directory, so `exec` starts in the clone (the `pwd`, `ls` and branch commands were not pasted; this follows from `tests/run.sh` resolving). The dev container's run of the same suite took a little over two minutes in this session (a timed-out first run, backgrounded at 120 s), so the two are in the same range. Settles row U4's suite claim; the executable-bit question (the clone's file modes) is not shown by a passing suite and stays as the page's `cited` text unless a later trial lists modes.
- **T5 (2026-11-14):** `sbx.exe stop codeo-a` printed `Git remote sandbox-codeo-a is restored when the sandbox next starts.` and `Stopped sandbox codeo-a`. `time sbx.exe run -d --name codeo-a` printed `✓ sandbox codeo-a — started`, `✓ … running detached`, a container id, `real 0m5.602s`: **`-d` does combine with reattaching by name** (the docs left it open). `sbx.exe ls` then showed `● running (detached)`, the git daemon port changed from `60000` to `60002` on restart, and the sandbox was still 7 minutes old (same sandbox, not a new one). Settles D3's restart time: about 6 s, against the first create's 1m47s.
- **Executable bit (row U4), 2026-11-14:** `git ls-files -s tests/run.sh` printed mode `100644` (the repository records `tests/run.sh` as not executable, which is how it is run: `bash tests/run.sh`), and `ls -l` in the sandbox showed `-rw-r--r--` for it and `-rwxr-xr-x` for every file under `scripts/` — the bit the index records survives in the sandbox's clone, so no repair step like the start script's step 2b is needed here. (The WSL automount's `fmask=11` did not matter: the clone is inside the sandbox, not on the mount.)
- **Route chosen: A (Windows native).** The distribution is Ubuntu 24.04 (the version Docker's Linux route needs) but shows no KVM, so route B has no basis on this machine; Windows is build 26300 and Docker reaches the distribution at 29.9.3. Whether Windows Hypervisor Platform is enabled is not known from T1; T2 finds out. Row D5 and `## Host` in the page take these facts in Task 6.

- The Docker pages did not say: whether WSL2 is supported (the one mention is a troubleshooting entry about `sbx run --clone` failing on a WSL filesystem over Git's dubious-ownership check), whether a Claude login survives `sbx rm`, how to install Claude plugins in a sandbox, git identity handling, and whether a clone keeps the executable bit. Those rows say `not documented`, and the trials are what settle them.
- `--clone` follows whatever ref is checked out on the host and makes no branch, so a sandbox on an issue branch needs that branch checked out first (row U2).
- Two small plan deviations, both inside the trials: T4, T6-T9 use `sbx exec codeo-a <command>` rather than an interactive `sbx exec -it … bash` followed by commands, so each is one command; T6 keeps Docker's own single quotes in `gh auth token`, which bash on WSL passes through unchanged.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — Q1 answered (C), T1 run, route A chosen · cost: unavailable until the hand-off
- 2026-11-14 — Task 1 done, Q1 raised · cost: 13m · sonnet-5-5 122k in + 2.2M cached / 24k out
