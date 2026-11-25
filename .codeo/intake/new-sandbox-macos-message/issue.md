# Issue: `codeo issue <N> --sandbox` on macOS says to install sbx, though sandboxes are Linux and WSL2 only — issue

| | |
|---|---|
| Issue | not filed yet |
| Branch | none |
| Updated | 2026-11-25 |

## Where this stands

Round 1: questions open; no draft yet.

## Problem as restated

On a Mac (mac-studio), `codeo issue 171 --sandbox` stops with `codeo-sandbox: sbx is not installed: install Docker Sandboxes (sbx), or from WSL2 make sbx.exe reachable on PATH`. The sandbox route is documented as Linux or WSL2 only: `.sbx/README.md:7` says "The host is Linux or WSL2 (never macOS)", and the header of `.sbx/codeo-sandbox.sh:3` says the same. But nothing on the way there says so. `codeo` (`.devcontainer/codeo`) runs on macOS and accepts `--sandbox` and `codeo default sandbox` with no OS check. `codeo-sandbox.sh`'s `pick_sbx` (`:68-78`) has no OS check either, and its message tells a macOS user to install sbx, which would lead them onto a route the project does not support. The container route (`codeo issue <N>` with no flag) is the supported one on macOS.

## Phase 1 findings (systematic-debugging)

- **Reproduced from the code:** `codeo issue <N> --sandbox` → `run_script codeo-sandbox.sh issue …` → `pick_sbx` → `die "sbx is not installed: …"` when neither `CODEO_SBX`, `sbx` nor `sbx.exe` is on `PATH`. Neither script reads `uname`; `grep -n -E 'uname|Darwin'` finds nothing in either.
- **What changed:** nothing recent. The macOS exclusion dates from the sandbox work (#85, #86, #99); `codeo` (#133) added `--sandbox` later and README.md:204 now says the `codeo` command runs on macOS.
- **Not shown:** whether sbx, once installed on macOS, would work with `codeo-sandbox.sh`. The script was written for Linux and WSL2 and was never run on macOS. Why it excludes macOS is not written down in the files I read.

## Questions

### Q1 — What should happen on macOS?

**Why it matters:** decides whether this is a small message-and-guard fix or a new platform for the sandbox route.
**Options:**
- **Refuse clearly (recommended):** `codeo … --sandbox`, `codeo default sandbox` and `codeo-sandbox.sh` on macOS stop with one line saying sandboxes run on Linux and WSL2 only, and naming the container route (`codeo issue <N>`). It matches what the docs already say.
- **Support sandboxes on macOS:** make the sandbox route work on a Mac. That is a larger piece of work and needs the sbx behaviour on macOS checked first, perhaps as an evaluation like #73.
- **Both:** refuse now, and file the macOS support as a separate follow-up.

**Answer:**

### Q2 — Did you mean to use a sandbox, or was the container route fine?

**Why it matters:** if you need a sandbox on the Mac for a reason the container route doesn't cover, that reason belongs in the issue's motivation (and argues for Q1's second or third option).
**Options:** container is fine, I was trying the flag · I need a sandbox on the Mac (say why).

**Answer:**

### Q3 — Should the README and `codeo --help` also say sandboxes are Linux and WSL2 only?

**Why it matters:** today only `.sbx/README.md` says it. `codeo --help` lists `--sandbox` on every platform, and README.md:204 says the `codeo` command works on macOS without exception.
**Options:** yes, in both (recommended) · only in the error message.

**Answer:**

## Notes

- Related, closed: #73 (sbx evaluation), #85, #86, #99 (sandbox route), #133 (`codeo` command), #113 (cmd mode on Linux or macOS). Open: #170 (macOS docs for `codeo`, in progress) and #171 (README guide) both touch the README's macOS text.

## Outcome

_Pending — written at the hand-off._
