# Issue #176 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/176 |
| Branch | `feat/176-support-sbx-issue-sandbox-macos` |
| Updated | 2026-11-25 |

## Where this stands

Branch `feat/176-support-sbx-issue-sandbox-macos` cut off `main` at d097737 and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/176 — Support the sbx issue sandbox on macOS: check that sbx and `codeo-sandbox.sh` work there, and fix what does not |
| State | open · labels `enhancement` |
| Branch | `feat/176-support-sbx-issue-sandbox-macos` off `main` at d097737 |
| Board | Ready → In progress |

**Problem.** `codeo issue <N> --sandbox` works on Linux and on Windows through WSL2 and is documented as "never macOS"; on a Mac it stops because `sbx` is not on `PATH` and nothing knows the platform. Whether sbx runs on macOS, and whether `codeo-sandbox.sh` works there, has never been tried. The work is to check, fix what fails, and document it.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] A recorded check, in `docs/dev-environment-sbx-evaluation.md` or a page it links, says whether sbx runs on macOS, on what hardware and macOS version, with the install command and what it needs.
- [ ] On a Mac with sbx installed, `codeo issue <N> --sandbox` starts a sandbox, takes the lock, and adds the `sandbox` row to the tracking comment.
- [ ] On the same Mac, `codeo shell <N>` and `codeo open <N>` open the sandbox, `codeo list` shows it, and `codeo rm <N>` removes it and marks the row `removed`.
- [ ] `codeo-sandbox.sh` runs under macOS's bash 4.3 or later without a Linux-only command; anything it needs beyond Linux's requirements is named in the README.
- [ ] With `sbx` missing on macOS, the error names where to install sbx for macOS.
- [ ] "never macOS" appears in no README or script comment, and each says what macOS needs.
- [ ] `bash tests/run.sh` passes, with the sandbox tests updated for the changed message and wording.

**Out of scope.** Sandboxes on any host not already supported or named here (a different Linux distribution, a Windows host without WSL2). Replacing the dev container route, or changing which route is the default. Changing how sbx itself works.

**Open at intake.** Whether sbx is available on macOS and on what Macs; nobody has shown it. Whether `codeo-sandbox.sh` works on macOS once sbx is installed; never run there.

## Log

- 2026-11-25 — initialized: branch feat/176-support-sbx-issue-sandbox-macos off main at d097737 · cost: 1m · sonnet-5-5 16k in + 416k cached / 2k out
