# Issue #73 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/73 |
| Branch | `docs/evaluate-docker-sandboxes-sbx-against` |
| Updated | 2026-11-14 |

## Where this stands

Task 1 is done and committed (`9bddbbc`): `docs/dev-environment-sbx-evaluation.md` has 28 rows (10 drivers, 18 duties), every one `cited` with a Docker URL, and trials T1-T12. `bash tests/run.sh` exits 0, no evidence cell is blank, and `.devcontainer/` and `skills/` are unchanged.

Tasks 2-5 are the engineer's, on their own host, and are stopped on Q1 below: the docs show two install routes and the plan assumed one. After Q1 is answered, run the trials T1-T12 in `docs/dev-environment-sbx-evaluation.md` → `## Trials` in order, and paste each output (tokens and account names redacted) into the conversation. Tasks 6-7 follow.

## Questions

### Q1 — Which install route should T1-T2 follow on your machine?

**Why it matters:** Docker documents two. The plan assumed one (`sbx` in bash inside WSL2), and the choice decides what T1-T2 run, which shell they need, and whether Task 2 has a step that is not bash.
**Options:**
- **A — Windows native.** `winget.exe install -h Docker.sbx` run from WSL bash, after enabling Windows Hypervisor Platform from an *elevated PowerShell* (`Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All`, a restart may be needed). `sbx` then runs as `sbx.exe` through Windows interop, or from PowerShell. This is the Windows route in Docker's install page and the one I'd try first on Windows + WSL2.
- **B — Linux inside WSL2.** An Ubuntu 24.04 or later distribution with KVM and nested virtualization (`lsmod | grep kvm` in T1 shows whether the distribution can), then `sudo apt install docker-sbx`. All bash, but only if the distribution has KVM.
- **C — run T1 first and decide from its output.** T1 is five read-only commands; paste them and I pick the route.

**Answer:**

## Notes

- The Docker pages did not say: whether WSL2 is supported (the one mention is a troubleshooting entry about `sbx run --clone` failing on a WSL filesystem over Git's dubious-ownership check), whether a Claude login survives `sbx rm`, how to install Claude plugins in a sandbox, git identity handling, and whether a clone keeps the executable bit. Those rows say `not documented`, and the trials are what settle them.
- `--clone` follows whatever ref is checked out on the host and makes no branch, so a sandbox on an issue branch needs that branch checked out first (row U2).
- Two small plan deviations, both inside the trials: T4, T6-T9 use `sbx exec codeo-a <command>` rather than an interactive `sbx exec -it … bash` followed by commands, so each is one command; T6 keeps Docker's own single quotes in `gh auth token`, which bash on WSL passes through unchanged.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — Task 1 done, Q1 raised · cost: 13m · sonnet-5-5 122k in + 2.2M cached / 24k out
