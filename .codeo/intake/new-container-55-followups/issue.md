# Issue (new) — issue

## Where this stands

Draft A of two issues from triage run 2026-11-11-2 (Q1-Q6). Scope was settled in the triage dossier; the questions below are the ones whose answer would still change the issue.

## Questions

### Q1 — Is `codeo-root.sh`'s choice of plugin entry in scope as a defect or as a robustness note?

**Why it matters.** F3 says entry `[0]` of `codeo@codeo` can be another project's install. The issue's criterion is either "picks the entry that matches this project" or "documents that the first entry wins".

**Options.** *defect: pick the right entry* · *note: document the assumption* · *drop F3*.

**Answer:** (the engineer accepted filing F3 with the rest at triage; the issue states it as a defect, with the choice left to `/codeo:plan`)

### Q2 — F4 (shared folder names): fix, or only document?

**Why it matters.** The named-volume flow (`codeo-<N>`) never clashes; only open-folder checkouts that share a basename do. The criterion differs: "two such checkouts run at once" versus "the README and CHANGELOG say why it fails and what to do".

**Options.** *fix* · *document only* · *either, `/codeo:plan` decides*.

**Answer:** either, `/codeo:plan` decides (recommendation accepted at triage)

## Draft

**Title:** Dev container follow-ups from #55: shared folder names, registry entry, empty lock file, base branch, wording

**Type:** none (user-owned repository, no Issue Types). **Labels:** `enhancement`.

### Description

Fix the non-blocking findings `/codeo:qc` recorded for #55 (PR #56): five small defects and inaccuracies in the home/issue-container scripts and docs.

### Motivation / Context

#55 merged with these findings recorded and deliberately not fixed. They were left for triage (run 2026-11-11-2) and none breaks codeo today, but each is a way the container workflow fails quietly in a case the tests do not cover.

### Key Requirements

- Two open-folder checkouts that share a folder name (`~/a/codeo`, `~/b/codeo`) either run at once or the README and CHANGELOG say why not and what to do. Today they fail with "name already in use", which the docs explain only as a leftover container (F4).
- `.devcontainer/scripts/codeo-root.sh` does not take another project's `lock.sh` when the plugin registry lists other entries for `codeo@codeo` first (F3).
- An empty `.codeo/active` in a container gives either a lock or a `todo:` line, not silence (F6).
- `.devcontainer/scripts/folder-check.sh` honours the configured base branch the way `devcontainer-start.sh` does, instead of hard-coding `main` (F2).
- The header comment in `.devcontainer/scripts/container-name.sh` and the CHANGELOG entry say where the Docker name actually comes from (the folder, through `runArgs`), and `.devcontainer/README.md` names the start script by its real path (F5, F7).
- The reviewers' deferred minors from #55 are done or dismissed with a reason: header wording in `container-name.sh`; `window-title.sh` capturing `container-name.sh` with `2>&1`; no test for a bare `-home` folder on a non-main branch; the `lock.sh` crash output repeated in its failure TODO; the weak `.codeo/active` needle in `tests/init-overlay.test.sh`.

### Acceptance Criteria

- [ ] A test shows two checkouts with the same folder basename starting, or `.devcontainer/README.md` and `CHANGELOG.md` state the limit and the fix.
- [ ] A test has a registry with another project's `codeo@codeo` entry first and the start script uses this project's `lock.sh`.
- [ ] A test starts a container with an empty `.codeo/active` and sees a lock taken or a `todo:` line.
- [ ] A test runs `folder-check.sh` on a project whose base branch is not `main`, on its home clone, and gets no wrong-folder TODO.
- [ ] The comment, the CHANGELOG line and the README path match the code.
- [ ] Each deferred minor is fixed or dismissed in the PR description.
- [ ] `bash tests/run.sh` passes and `CHANGELOG.md` records the change.

### Out of Scope

- The Docker host checks for #55's own criteria (filed separately).
- Reworking the reference project's name out of archived dossiers (`.codeo/done/55/`) and issue #55's body.
- #54's items (mode-change message, title-hook edges, a folder Docker rejects).

### Reference

- `.codeo/done/55/qc.md` round 1, findings F2-F7; `.codeo/done/55/implement.md`, "Deferred minors".
- PR #56, issue #55; related and not duplicate: #54, #51 (shares `devcontainer-start.sh`).
- Triage dossier `2026-11-11-2.md`, Q1-Q6.
