# Issue #185 — issue

Filed as #185: Close the #173, #176 and #170 QC leftovers (documentation, priority: low). Approved by the engineer.


### Description

Three merged workflows left non-blocking findings that nobody filed: #173 (QC round 2, R2-F1 to R2-F5), #176 (QC round 2, F9 to F18) and #170 (QC round 1, F1). All are small wording, comment or test-guard gaps, plus one unverified claim. This issue closes them in one pull request, as #173, #177 and #179 did for earlier rounds.

### Motivation / Context

`/codeo:triage` run 4 (2026-11-25) found them in the archived dossiers `.codeo/done/173/qc.md`, `.codeo/done/176/qc.md` and `.codeo/done/170/qc.md`. Each was classified non-blocking by QC and rode along. Checked against `main`: the lines named below are still as QC described them, and neither #177 nor #179 names any of them. Nothing here breaks a run; each item makes a doc, comment or test say something untrue or less than it could.

### Key Requirements

From #173 (`.codeo/done/173/qc.md`, round 2):
- `.claude/hooks/session-start.sh:19-21` and its header comment: the hook skips when any user-scope `superpowers@*` entry is enabled, while `install.sh`'s `installed_entry` judges only the first match. Make the two agree, or make the comment say they differ. Line 16's comment also says "both counts" where the code has one variable (`ready`).
- `.devcontainer/README.md:199` says "It prints no stop-failure line, because the container is removed"; when `docker rm -f` then fails the container stays and no line is printed. Say what happens. The same paragraph mentions the stop-failure line only for a failed `docker inspect`, though `codeo` also prints it on a cannot-check or dirty refusal of a container it started (round 1 F4).
- `docs/release-checklist.md` step 6: `v1.0.5` is listed under "do not move" as a stub that "only orders tags or is refused", but `tests/install.test.sh:757-759` asks for it with `--version`; `t_latest_is_highest_release` (`:236`) uses `v1.0.9` and `v1.0.8` that no group names; step 6 does not name `docs/updating.md`, whose release-version examples `tests/install.test.sh` checks (round 1 F3); and the refused input `'v1.0.9;x'` (`tests/install.test.sh:335`) fits no group (round 1 F7). Make step 6 match the test.
- `CONTRIBUTING.md` → Hosted sessions: whether "start a new session" loads the plugins in a fresh hosted environment is unverified (R2-F5). Verify it, or keep the hedge and record that it is unverified.

From #176 (`.codeo/done/176/qc.md`, round 2):
- `.sbx/README.md`: the last *On macOS* bullet (`:51`) is trial history and repeats the `code` bullet above it; *On macOS* mixes in the `sbx secret set`, `sbx setup ssh` and git-identity bullets that hold on every host, so a Mac reader cannot tell what is Mac-only (F9, F10).
- `docs/dev-environment-sbx-evaluation.md` T14: mention the second `codeo issue 176 --sandbox --yes` that recreated the sandbox, and say that the later `codeo rm 176 --sandbox` is inferred, not pasted (F11, F12).
- `tests/sandbox.test.sh`: `open_on_macos_without_code_is_one_line` returns early, passing without testing, on a host with `/usr/bin/code` or `/bin/code`; `a_failing_uname_is_not_macos` does not assert the exit code (F14, F15).
- The CHANGELOG bullet leaves out that on macOS the git identity is read from `git config --global` only once `xcode-select -p` succeeds (F16).
- On a Mac without the Command Line Tools `issue` fails at `git clone` with the stub's installer error, because `ensure_host_clone` runs before `git_is_usable` is read; a one-line hint before the clone would close the gap (F17).
- Optional: the macOS missing-`sbx` message names `codeo issue <N> --container` with a literal `<N>` (`.sbx/codeo-sandbox.sh:81`) (F13).
- Confirm that `codeo open <N> --sandbox` on a Mac connects VS Code to the sandbox, which T14 records only on the engineer's word (F18).

From #170 (`.codeo/done/170/qc.md`, F1):
- `docs/home-checkout.md:22` says `install.sh` needs `flock`; only the `codeo` command does (`.devcontainer/codeo:159`). Say that the `codeo` command needs `flock`.

### Acceptance Criteria
- [ ] Each requirement above is fixed, or the pull request names it as dismissed with a reason.
- [ ] `.claude/hooks/session-start.sh` and `installed_entry` in `install.sh` agree on a case with two `superpowers@*` entries, the first disabled, or the comment states the difference; a test pins whichever is chosen.
- [ ] `docs/release-checklist.md` step 6 names every release-version stub and example in `tests/install.test.sh` and `docs/updating.md`, with none in a group that contradicts the test.
- [ ] `docs/home-checkout.md` says the `codeo` command, not `install.sh`, needs `flock`.
- [ ] `open_on_macos_without_code_is_one_line` runs its check on a host that has `code` on a standard path, and `a_failing_uname_is_not_macos` asserts the exit code.
- [ ] `bash tests/run.sh` ends `all cases passed`.

### Out of Scope

- The #177 and #179 findings, and the release #182.
- The `readlink -f` in `codeo update`: QC noted it as pre-existing and it works on macOS 12.3 or later, so it is not a defect here.
- Any new behaviour beyond what the findings name; F13 and F16 are optional and may be dismissed.

### Reference

- `.codeo/done/173/qc.md`, `.codeo/done/176/qc.md` and `.codeo/done/170/qc.md` on `main`.
- Related issues: #173, #176, #170 (the sources), #177 and #179 (the earlier leftover rounds, not overlapping), #182 (the v1.0.10 release, which does not wait for this one).
- Surfaced by `/codeo:triage` run 4, 2026-11-25.
