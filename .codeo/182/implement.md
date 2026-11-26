# Issue #182 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/182 |
| Branch | `feat/182-release-v1-0-10-once` |
| Updated | 2026-11-26 |

## Where this stands

All 14 tasks of `docs/plans/2026-11-26-release-v1-0-10.md` are done and the tree builds. Next step: `/codeo:qc`.

## Questions

None.

## Notes

Rulings and deviations, none of which changed what ships:
- **Task 1 expected counts.** The plan's Step 5 expected `tests/install.test.sh` to hold no `1.0.8` (it holds 2: the older-release tags in the two skipped functions, as designed), the `v1.0.9;x`/`v1.0.9.1` line count to be at least 4 (it is 1 line) and a `refs/tags/v1.0.9` count of 2 (9). Both test files pass, which is the proof that matters; the plan's text is not edited.
- **Task 3 baseline.** `overlap` was already in the README twice (implement and qc steps), not 0; the new text is right.
- **README text checked against the code.** An independent review of every sentence Tasks 2-6 added against the code found three imprecise sentences (the close step's behind-the-base condition and step order, and "the other `lock: TODO` line") and one remedy the code does not state ("install the plugin again"); all four were corrected (`84a5c1d`, `32de182`). `/codeo:close`'s dossier write-up of the `--sandbox` TODO's fix ("give the sandbox a name made of those characters") is inferred from `lock.sh` and `devcontainer-start.sh`, which state the cause and not a remedy.
- **Changelog #170 bullet.** The first draft credited the README with the `flock` and keychain notes; they are in `.devcontainer/README.md` and `docs/home-checkout.md`. Corrected before pushing.
- **Reviews.** Tasks 3-6 were one dispatch of four commits (same file, same kind); one reviewer checked Tasks 2-6 together. Every dispatch passed `model: sonnet`.
- Not done, as planned: the container rebuild and the version check (Task 14).

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-26-release-v1-0-10.md` |
| Build result | no suite has a build command that does anything (`shell`: `true`); `bash tests/run.sh` ends `all cases passed` on this branch with the pin, and in a clean clone of the merge commit |

**Built.**
- **Release PR #189** (`release/v1.0.10`, five files) merged as `d60c26a`: `plugin.json` `1.0.10`; `CHANGELOG.md` `## v1.0.10 — 2026-11-26` (the UTC date #189 opened) with entries added for #179, #170 and the README corrections; the version examples in `README.md`, `docs/updating.md` and `tests/install.test.sh` moved up one release, the three ordering and refused stubs left alone and the `v1.0.10` ordering stub taken to `v1.0.11`.
- **README corrected against the code** (criterion 2): the two `/codeo:implement` mismatches, and every omission the audit found (installer `--help` and exit statuses, `TODO-set-me` and the config failures, `priority-labels`, the overlays and `--sandbox` lock failures, what init, plan and close also do, `sync-main.sh` at the start of a round, the `resources[].paths` and `environment.hooks.start` rows).
- **Clean-clone test** of `d60c26a`: version `1.0.10`, `bash tests/run.sh` ends `all cases passed`.
- **Tag `v1.0.10`** on origin at `d60c26a`, lightweight, pushed by the engineer (criterion 6). **Release `v1.0.10`** is published and Latest, title `v1.0.10`, notes the changelog section only, 9 bullets (criterion 7).
- **Pin:** `.codeo/config.json` `plugin.ref` is `v1.0.10` on this branch (`2f1467b`); `/codeo:close` opens this branch's PR, and criterion 8 is met when it merges.
- **Version after the rebuild (criterion 9):** `claude plugin list` shows `codeo@codeo` `Version: 1.0.10`, `Status: enabled`, for both the `user` and the `project` scope. No scope reports another version.

**Documentation pages changed:** `README.md` and `docs/updating.md`, both through #189.

**Deviations from the plan:** none that changed what shipped. Task 1's expected counts and Task 3's `overlap` baseline were wrong in the plan; see `## Notes`. The plan's text is not edited.

**For `/codeo:qc`:** criterion 1 (the four gating issues closed) was checked at Task 1 and again when the release PR was opened; criteria 3 and 4 are on `main` at `d60c26a`; criterion 5 is the clean-clone line above; criteria 6 and 7 are `git ls-remote --tags origin v1.0.10` and `gh release view v1.0.10`. The README sentences Tasks 2-6 added were reviewed against the code by a separate reviewer; one fix text (the `--sandbox` lock TODO's remedy) is inferred, as `## Notes` says.

## Log


- 2026-11-26 — Tasks 1-8 done; release PR #189 open, waiting for the engineer's merge · cost: 15m · sonnet-5-5 374k in + 13.8M cached / 60k out
- 2026-11-26 — release merged (#189, d60c26a), clean-clone test passed, tag v1.0.10 and Release published, pin moved; waiting for the container rebuild · cost: unavailable (see the previous line)
- 2026-11-26 — container rebuilt; claude plugin list shows codeo@codeo 1.0.10 at user and project scope; implemented: docs/plans/2026-11-26-release-v1-0-10.md · cost: 42m · sonnet-5-5 388k in + 16.4M cached / 66k out
