# Issue — issue

## Where this stands

Drafted from triage run 8 (the engineer chose to file and consolidate). Awaiting approval.

## Questions

None.

## Draft

**Title:** Dev container follow-ups from #96: the changelog test that breaks at release, small start-script defects, and tests that cannot fail
**Type:** none (no Issue Types); **Labels:** enhancement

### Description

Small defects and weak tests that #96's QC (`.codeo/done/96/qc.md`, rounds 2-3) recorded as non-blocking, in the dev container start script, `codeo-root.sh`, `tests/devcontainer.test.sh` and the CHANGELOG. One of them (the first) turns the suite red on the next release commit.

### Motivation / Context

`docs/release-checklist.md` step 6 retitles `## Unreleased` to `## vX.Y.Z`. A test added by #96 reads only `## Unreleased`, so it fails on the release commit; #100 (v1.0.7) is the next one. The other items are wrong or empty messages in rare cases, and assertions that cannot fail. Triage run 8 decided to file them as one issue, as #88 and #54 did.

### Key Requirements

- `docs_changelog_names_the_replay_sed_and_the_folder_limit` finds the `(#52)` bullet and the folder-name limit wherever they sit in `CHANGELOG.md`, not only under `## Unreleased`.
- Start script (`.devcontainer/scripts/devcontainer-start.sh`):
  - The bind-mount TODO says git "is already told to trust the clone" only when the `safe.directory` add succeeded or the entry already existed (F3).
  - The `core.fileMode` override line is not claimed when the `false` came from the `command` or `worktree` scope (`GIT_CONFIG_PARAMETERS`, `GIT_CONFIG_COUNT`), where the local `true` changes nothing (F4); `.devcontainer/README.md` says the same.
  - A failed `mktemp` gives the "could not be listed" TODO a reason (F17).
- `codeo-root.sh` matches a registry `projectPath` containing a backslash, and an empty or `false` `projectPath` is handled as the documented "none" (F7).
- Tests: the lock-crash case counts occurrences of its marker, not lines (F5); the `.settings.*` assertion and the `git status` half of `start_runs_claude_outside_the_clone` can fail (F6, F10); the gitconfig-growing case does not depend on 0.05 s sleeps staying under the 0.2 s window (F14); the `# shellcheck disable=SC2016` covers the line it should (F18); the stray `Terminated  env …` line is gone from the suite output (F13).
- The EXIT trap's `rm -f -- ""` is checked on the Rust coreutils the 26.04 image ships, and removed or guarded if it complains (F15).
- The CHANGELOG #96 bullet names `docs/release-checklist.md` step 8 and the follow-up set it covers (F11); the test header names both volumes, `codeo-gh` and `codeo-git` (F12).

### Acceptance Criteria

- [ ] With `## Unreleased` retitled to `## v9.9.9` in a scratch copy, `docs_changelog_names_the_replay_sed_and_the_folder_limit` still passes; with the `(#52)` bullet's `tests/replay.test.sh` removed it fails.
- [ ] A test starts a container where the `safe.directory` add fails and sees no "already told to trust the clone" in the bind-mount TODO.
- [ ] A test with `core.fileMode=false` from `GIT_CONFIG_COUNT`/`GIT_CONFIG_PARAMETERS` sees no "overrode" claim; with it set globally the message is unchanged.
- [ ] A test makes `mktemp` fail and sees the reason in the "could not be listed" TODO.
- [ ] A test gives `codeo-root.sh` a `projectPath` with a backslash and one that is empty or `false`, and sees this clone's entry taken or skipped as documented, and no other project's entry taken.
- [ ] Each of F5, F6, F10 fails when the behaviour it guards is broken (shown by a mutation in a scratch copy), and the suite output has no `Terminated` line.
- [ ] `bash tests/devcontainer.test.sh` passes 20 times in a row under `nice` load, or the timing dependence is gone by construction (F14).
- [ ] `rm -f -- ""` on the image's coreutils is checked and recorded on the issue, and the trap does not run it when no temp file exists.
- [ ] The CHANGELOG bullet and the test header say what F11 and F12 name.
- [ ] `bash tests/run.sh` passes and `CHANGELOG.md` records the change.

### Out of Scope

- The folder-name limit for `my project` / `_x` (dismissed in triage run 8; documented in the CHANGELOG and README).
- Persisting Claude's login across a container rebuild (dismissed in triage run 8).
- Image changes, new tools, anything under `scripts/`, `hooks/` or `skills/`.

### Reference

- `.codeo/done/96/qc.md` rounds 2-3: F3-F7, F10-F18; PR #106.
- Related: #88, #54, #100 (the release that the first item would break).
- Triage run 8: `.codeo/intake/triage/2026-11-15-8.md` Q1-Q3.

## Outcome

_Pending — written when filed._

## Log

- 2026-11-15 — drafted from triage run 8 · cost: unavailable
