# Issue (new) — issue

| | |
|---|---|
| Issue | not filed yet |
| Branch | none |
| Updated | 2026-11-25 |

## Where this stands

Round 1 answered; draft below awaits approval.

## Problem as restated

An engineer on a Mac (mac-studio, over SSH) followed the README's install line and then could not run `codeo`. The README's `install.sh` line installs the Claude Code plugins only; the `codeo` host command has a separate install line that lives in `.devcontainer/README.md`, and the root README never says so. Once installed, `codeo home` failed at the Docker build with a keychain error because the SSH session could not unlock the macOS keychain for `docker-credential-desktop`; nothing documents that.

## Questions

### Q1 — Which of the findings go in this one issue?

**Answer:** Docs only.

### Q2 — Do you know `flock` installs on macOS, and how?

**Answer:** `brew install flock` worked.

### Q3 — Missing pointer, or the curl line sounding like it installs `codeo`?

**Answer:** One-line pointer.

## Draft

**Title:** Docs: say the `codeo` host command installs separately, and cover macOS flock and the keychain over SSH

**Type:** none (no Issue Types). **Labels:** documentation

### Description
The README's one-line `install.sh` installs the Claude Code plugins only. It does not install the `codeo` host command, which has its own install line in `.devcontainer/README.md`. An engineer who runs the README line and then types `codeo` gets "command not found". Two macOS facts are also undocumented: how to get `flock`, and that `codeo home` over SSH fails at the Docker build until the keychain is unlocked.

### Motivation / Context
Found on a Mac Studio over SSH. `codeo --help` failed after the README install line. After installing the host command, `codeo home` failed with `error getting credentials ... keychain cannot be accessed because the current session does not allow user interaction` (Docker's `docker-credential-desktop`). Fixes that worked: `security -v unlock-keychain ~/Library/Keychains/login.keychain-db`, then re-run; and `brew install flock` for the flock requirement.

### Key Requirements
- The root README says near *Installing*, in one line, that `install.sh` does not install the `codeo` host command, and points to the install section of `.devcontainer/README.md`.
- The README's macOS paragraph (line 204) names `brew install flock` as a way to get `flock`.
- The macOS documentation says what to do when `codeo home` or `codeo issue` fails at the Docker build with a keychain error in an SSH session: unlock the login keychain in that session, or drop `credsStore` from `~/.docker/config.json` (with its trade-off).

### Acceptance Criteria
- [ ] README.md, in or next to *Installing*, has one line saying `install.sh` installs the plugins and not the `codeo` command, with a link to the `.devcontainer/README.md` section that has its install line.
- [ ] The README's macOS paragraph names `brew install flock`.
- [ ] A documented macOS note gives the keychain error text and the `security -v unlock-keychain` command.
- [ ] Every command and link the changes name exists and is spelled as in the repo.
- [ ] `bash tests/run.sh` passes (any doc-pin tests updated with the wording).

### Out of Scope
- Changing `codeo` itself: a zsh-aware PATH hint, or detecting the keychain failure and printing the unlock command. A follow-up if wanted.
- Other macOS behaviour not yet verified past `codeo home`.

### Reference
Closed #113 (cmd mode, Linux or macOS), #133 and #143 (host command). README.md line 204; `.devcontainer/README.md` install section.
