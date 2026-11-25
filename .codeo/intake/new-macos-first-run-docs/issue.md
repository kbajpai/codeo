# Issue (new) — issue

| | |
|---|---|
| Issue | not filed yet |
| Branch | none |
| Updated | 2026-11-25 |

## Where this stands

Round 1. Problem restated and checked against the repo; three questions open before a draft.

## Problem as restated

An engineer on a Mac (mac-studio, over SSH) followed the README's install line and then could not run `codeo`. The README's `install.sh` line installs the Claude Code plugins only; the `codeo` host command has a separate install line that lives in `.devcontainer/README.md`, and the root README never says so. Once installed, `codeo home` failed at the Docker build with a keychain error because the SSH session could not unlock the macOS keychain for `docker-credential-desktop`; nothing documents that.

## What the repo already says (checked)

- macOS needs bash 4.3+ and `flock` for `install.sh` and `codeo`: already in README.md line 204. Not a gap.
- No mention of `~/.local/bin` or the host-command install line in README.md. `codeo` prints a `~/.bashrc` line when `~/.local/bin` is off PATH; macOS defaults to zsh.
- No mention of keychain / `credsStore` / SSH anywhere in README.md or .devcontainer/README.md.
- Related, closed: #113 (cmd mode, Linux or macOS), #133 (host command, Linux, bash), #143.

## Questions

### Q1 — Which of the findings go in this one issue?

**Why it matters:** each is a separate doc change; a code change (zsh PATH hint, keychain detection in `codeo`) is a bigger issue than wording.
**Options:** docs only: root README points to the `codeo` install line, macOS notes for keychain over SSH · docs plus `codeo` prints a zsh-aware PATH line · docs plus `codeo` detects the keychain failure and prints the unlock command · you pick.

**Answer:**

### Q2 — Do you know `flock` installs on macOS, and how?

**Why it matters:** README line 204 says "and `flock`" with no way to get it; I could not verify a Homebrew formula from here. The issue can require the doc to name the command, but only if you know it works on the Mac Studio.
**Options:** `brew install flock` worked for me · I used something else (name it) · I did not need it, `codeo` ran without · not sure, leave as an open question in the issue.

**Answer:**

### Q3 — Is the gap the missing pointer, or that the curl line sounds like it installs `codeo`?

**Why it matters:** decides whether the requirement is "root README links to the host-command install" or "root README opens with both lines, one per tool".
**Options:** add a short section to root README with the host-command line · only a one-line pointer to `.devcontainer/README.md` · you pick.

**Answer:**
