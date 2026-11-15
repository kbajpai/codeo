# Issue #107 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/107 |
| Branch | `feat/dev-container-follow-ups-96` |
| Updated | 2026-11-15 |

## Where this stands

Branch `feat/dev-container-follow-ups-96` cut off `main` at 896d6d6, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/107 — Dev container follow-ups from #96: the changelog test that breaks at release, small start-script defects, and tests that cannot fail |
| State | open · labels `enhancement` |
| Branch | `feat/dev-container-follow-ups-96` off `main` at 896d6d6 |
| Board | Ready → In progress |

**Problem.** A test added by #96 reads only `## Unreleased` in `CHANGELOG.md`, so it fails on the release commit (#100, v1.0.7) when the checklist retitles that heading. Alongside it, the dev container start script and `codeo-root.sh` give wrong or empty messages in rare cases, and several tests in `tests/devcontainer.test.sh` cannot fail or depend on timing. All were recorded as non-blocking in #96's QC (F3-F7, F10-F18).

**Acceptance criteria** — verbatim from the issue, unchecked:
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

**Out of scope.** The folder-name limit for `my project` / `_x`; persisting Claude's login across a container rebuild; image changes, new tools, anything under `scripts/`, `hooks/` or `skills/`.

**Open at intake.** None.

## Log

- 2026-11-15 — initialized: branch feat/dev-container-follow-ups-96 off main at 896d6d6 · cost: unavailable
