# Issue #176 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/176 |
| Branch | none |
| Updated | 2026-11-25 |

## Where this stands

Filed as #176.

## Problem as restated

The sbx issue sandbox (`codeo issue <N> --sandbox`, `codeo-sandbox.sh`) is documented and written for a Linux or WSL2 host, "never macOS" (`.sbx/README.md:7`, `.sbx/codeo-sandbox.sh:3`). The engineer, on a Mac, tried `codeo issue 171 --sandbox` to test whether sandboxes work on macOS and got `sbx is not installed: install Docker Sandboxes (sbx), or from WSL2 make sbx.exe reachable on PATH`. The goal is that sandboxes are supported on macOS too, which is a larger piece than a message fix and needs checking first.

## Phase 1 findings (systematic-debugging)

- **Reproduced from the code:** `codeo issue <N> --sandbox` → `codeo-sandbox.sh issue` → `pick_sbx` → `die "sbx is not installed: …"` when neither `CODEO_SBX`, `sbx` nor `sbx.exe` is on `PATH`. Neither script reads `uname`.
- **Where the exclusion came from:** the sandbox evaluation (#73, `docs/dev-environment-sbx-evaluation.md`) tried one host, Windows with WSL2, and read Docker's install page on 2026-11-14 as listing Windows and Linux only. The files read say nothing about trying macOS or why it is excluded.
- **Not shown:** whether sbx is available on macOS today, and whether `codeo-sandbox.sh` works there once it is. A search for common GNU-only commands (`stat -c`, `readlink -f`, `date -d`, `sed -i`, `flock`) in the script found none, but the script has never been run on macOS. Its Windows handling (`sbx.exe`, `git.exe`, `safe.directory`) does not apply on macOS.

## Questions

### Q1 — What should happen on macOS?

**Answer:** Make sandboxes work on macOS, which is bigger and needs checking first.

### Q2 — Did you mean to use a sandbox?

**Answer:** I was testing sandbox works on macOS.

### Q3 — Should the docs and `codeo --help` say where sandboxes run?

**Answer:** We want sandbox to be supported on macOS too.

## Draft

**Title:** Support the sbx issue sandbox on macOS: check that sbx and `codeo-sandbox.sh` work there, and fix what does not

**Type:** none (no Issue Types). **Labels:** enhancement

### Description
`codeo issue <N> --sandbox` works on Linux and on Windows through WSL2, and is documented as "never macOS". Make it work on macOS too: find out whether Docker Sandboxes (sbx) runs on a Mac, run the sandbox route there, fix what fails, and document it.

### Motivation / Context
The engineer works from a Mac Studio over SSH and tried `codeo issue 171 --sandbox` to test whether sandboxes work on macOS. It stopped with `codeo-sandbox: sbx is not installed: install Docker Sandboxes (sbx), or from WSL2 make sbx.exe reachable on PATH`, because `sbx` is not on `PATH` and neither `codeo` nor `codeo-sandbox.sh` knows about the platform. The exclusion is in `.sbx/README.md:7` and `.sbx/codeo-sandbox.sh:3`. The sandbox evaluation (#73) tried a Windows with WSL2 host only, and Docker's install page as read on 2026-11-14 listed Windows and Linux; macOS was never tried.

### Key Requirements
- Check first, and write down what was found: whether sbx is available on macOS and on which hardware and macOS versions, and what it needs (a hypervisor, Docker Desktop, a minimum macOS).
- With sbx installed on a Mac, `codeo issue <N> --sandbox`, `codeo shell <N>`, `codeo open <N>`, `codeo list` and `codeo rm <N>` work for a sandbox, as they do on Linux, including the tracking comment rows and the lock the sandbox takes.
- The script's own requirements hold on macOS, or are named: bash 4.3 or later (the stock bash is 3.2), `flock`, and the tools the script calls.
- A missing `sbx` on macOS says where to get sbx for macOS, not the Linux or WSL2 advice.
- Where a step cannot work on macOS, the error says so in one line and names the container route (`codeo issue <N>`).
- `.sbx/README.md`, `.devcontainer/README.md`, the root `README.md` (the macOS paragraph) and the script's header say sandboxes are supported on macOS, with what it needs, and no longer say "never macOS".

### Acceptance Criteria
- [ ] A recorded check, in `docs/dev-environment-sbx-evaluation.md` or a page it links, says whether sbx runs on macOS, on what hardware and macOS version, with the install command and what it needs.
- [ ] On a Mac with sbx installed, `codeo issue <N> --sandbox` starts a sandbox, takes the lock, and adds the `sandbox` row to the tracking comment.
- [ ] On the same Mac, `codeo shell <N>` and `codeo open <N>` open the sandbox, `codeo list` shows it, and `codeo rm <N>` removes it and marks the row `removed`.
- [ ] `codeo-sandbox.sh` runs under macOS's bash 4.3 or later without a Linux-only command; anything it needs beyond Linux's requirements is named in the README.
- [ ] With `sbx` missing on macOS, the error names where to install sbx for macOS.
- [ ] "never macOS" appears in no README or script comment, and each says what macOS needs.
- [ ] `bash tests/run.sh` passes, with the sandbox tests updated for the changed message and wording.

### Out of Scope
- Sandboxes on any host not already supported or named here (a different Linux distribution, a Windows host without WSL2).
- Replacing the dev container route, or changing which route is the default.
- Changing how sbx itself works.

### Reference
- `.sbx/README.md:7`, `.sbx/codeo-sandbox.sh:3` and `:68-78` (`pick_sbx`), `.devcontainer/codeo` (`--sandbox`, `codeo default sandbox`), `README.md:204` (the macOS paragraph), `tests/sandbox.test.sh:143`.
- #73 (sbx evaluation), #85, #86, #99 (the sandbox route), #133 (the `codeo` command), #113 (cmd mode on Linux and macOS).
- #170 and #171 also edit the README's macOS text.

### Open questions
- Whether sbx is available on macOS and on what Macs. Nobody has shown it; the first requirement is to find out.
- Whether `codeo-sandbox.sh` works on macOS once sbx is installed. It was never run there.

## Notes

- If the check shows sbx cannot run on macOS, the fallback is a clear refusal on macOS and a README that says so; the issue's remaining requirements then do not apply. `/codeo:plan` decides after the check.

## Outcome

_Pending — written at the hand-off._
