# Issue #57 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/57 |
| Branch | `feat/dev-container-follow-ups-55` |
| Updated | 2026-11-14 |

## Where this stands

Branch `feat/dev-container-follow-ups-55` cut off `main` at 09e3013, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/57 — Dev container follow-ups from #55: shared folder names, registry entry, empty lock file, base branch, wording |
| State | open · labels none |
| Branch | `feat/dev-container-follow-ups-55` off `main` at `09e3013` |
| Board | Ready → In progress |

**Problem.** `/codeo:qc` recorded non-blocking findings (F2-F7) for #55 (PR #56) and they were left for triage. None breaks codeo today, but each is a way the home/issue-container scripts and docs fail quietly: two checkouts sharing a folder name collide on the Docker name; `codeo-root.sh` can take another project's `lock.sh` when the plugin registry lists other `codeo@codeo` entries first; an empty `.codeo/active` gives neither a lock nor a `todo:` line; `folder-check.sh` hard-codes `main` instead of the configured base branch; and a header comment, the CHANGELOG entry and the README misname where the Docker name comes from and the start script's path. The reviewers' deferred minors from #55 are to be fixed or dismissed with a reason.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] A test shows two checkouts with the same folder basename starting, or `.devcontainer/README.md` and `CHANGELOG.md` state the limit and the fix.
- [ ] A test has a registry with another project's `codeo@codeo` entry first and the start script uses this project's `lock.sh`.
- [ ] A test starts a container with an empty `.codeo/active` and sees a lock taken or a `todo:` line.
- [ ] A test runs `folder-check.sh` on a project whose base branch is not `main`, on its home clone, and gets no wrong-folder TODO.
- [ ] The comment, the CHANGELOG line and the README path match the code.
- [ ] Each deferred minor is fixed or dismissed in the PR description.
- [ ] `bash tests/run.sh` passes and `CHANGELOG.md` records the change.

**Out of scope.** The Docker host checks for #55's own criteria (filed separately); reworking the reference project's name out of archived dossiers (`.codeo/done/55/`) and issue #55's body; #54's items (mode-change message, title-hook edges, a folder Docker rejects).

**Open at intake.** None; the issue's choice for F4 (run side by side, or document why not) is left to `/codeo:plan`.

## Log

- 2026-11-14 — initialized: branch feat/dev-container-follow-ups-55 off main at 09e3013 · cost: 1m · sonnet-5-5 17k in + 497k cached / 3k out
