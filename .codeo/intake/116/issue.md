# Issue #116 — issue

| | |
|---|---|
| Source | `/codeo:triage` run 2026-11-16, Q1-Q5 (engineer: "File it. Consolidate as one issue") |
| Updated | 2026-11-16 |

## Where this stands

The finding list is fixed by triage; no duplicate found (`issue search "Podman"` returns only closed #73). Three scope questions remain before the draft can be approved.

## Questions

### Q1 — #104's F3 (web-session user label): in this issue, or only a reference to #112?
`.codeo/done/104/qc.md` F3 settles with #112's by-hand check, which may show the label is fine.
**Options:** reference #112 only, no requirement here (recommended) · add a requirement here.

**Answer:**

### Q2 — Design-level items: fix, or document the limit?
F5 (a future-dated `beat` reads as live), F7 (`SessionEnd` 10 s timeout vs a 16 s worst-case clear), F16 (same volume name shares a ref) and J8 (`/codeo:cleanup` lists every archived issue) are choices the earlier plans made. 
**Options:** state each as "fix or document the limit; `/codeo:plan` decides" (recommended) · require a code fix for each · drop them from the issue.

**Answer:**

### Q3 — #107's F1 (the `rm -f -- ""` check): a requirement of this issue?
It is a one-minute human action in a container terminal, not code.
**Options:** acceptance criterion "the output is recorded on #107" (recommended) · amend #107's criterion 8 instead and drop it here.

**Answer:**

## Draft (for approval at step 6)

**Title:** Follow-ups #70, #71, #104 and #107 left: Podman guard, cleanup override, live-signal edge cases, Backlog-option error, and test and wording fixes
**Issue Type:** none (`issue-types` prints nothing) · **Labels:** `bug`, `documentation`

### Description
Four archived workflows left non-blocking findings for triage. They are grouped here as one follow-up; each is small and none breaks a workflow today.

**From #70 (role guard and `/codeo:cleanup`):**
- The role guard recognises a container only by `/.dockerenv` (`role.sh:51`); under Podman (`/run/.containerenv`) the guard is silently off.
- `CODEO_CLEANUP_REMOVAL` is a test override in the production path (`scripts/cleanup.sh:41`); exported by accident it silently replaces the overlay's name, pattern and command.
- Generic text (`skills/cleanup/SKILL.md` description, `docs/skills.md`, the sentence in plan, implement, qc and `docs/handoff.md`) states a project-specific fact, "home container only".
- `/codeo:cleanup` lists every archived issue.

**From #104 (live-session signal):**
- `live.sh` `read_lock` (:116) accepts a lock issue `0` or `0104`; `list` (:189) accepts only `^[1-9][0-9]{0,8}$`.
- `CODEO_LIVE_PUSH_TIMEOUT` is documented as bounding "each push, fetch or REST call"; `live.sh:155` puts one 8 s limit around the whole `github.sh ref put`.
- `github.sh ref delete` counts any `Not Found` as already deleted; GitHub also answers 404 for a write the token may not make. Only `Reference does not exist` should count.
- The signal is cleared only at `SessionEnd`: when `/codeo:close` releases the lock (stash or abandon) while the session continues, the old issue shows `live:` for up to 15 minutes.
- Two containers with the same volume name working one issue write the same ref; the docs do not mention `CODEO_MACHINE`.
- A `beat` in the future counts as age 0; the `SessionEnd` hook's 10 s timeout is shorter than a worst-case `clear` (8 s push plus 8 s REST).

**From #71 (Backlog on filing):**
- `skills/issue/SKILL.md:178-179` says `board.sh set` "prints one line"; with several `board.projects` it prints one per project (`scripts/board.sh:286`).
- A board with no `Backlog` option and no `board.statuses.backlog` fails every filing with `board.sh: no synced project has the option 'Backlog'` (`scripts/board.sh:291`), a message that names no fix.
- `CHANGELOG.md` does not say a filed, never-started issue on `codeo/intake` is now fingerprinted `issue:<N>`, so a ledger holding an `intake:<N>` row asks about it once more.

**From #107 (dev container follow-ups):**
- The `rm -f -- ""; echo "rc=$?"` check (criterion 8's "checked" half) was never recorded.
- The CHANGELOG #107 bullet says `codeo-root.sh` "treats an empty or `false` one as none"; the old filter already did, so it reads as a behaviour change.
- `title_reports_a_failing_container_name_as_one_line` can only catch a reordering: `window-title.sh` dies before the temp file exists.

### Motivation / Context
Each was classified non-blocking by `/codeo:qc` and left for `/codeo:triage`. Left alone, F14 hides a refused ref delete as done, F15 shows a finished issue as live for up to 15 minutes, and the missing-Backlog error gives the engineer no fix to follow on every filing.

### Key Requirements
- Each item above is either fixed or has its limit stated in the docs; `/codeo:plan` decides which, per Q2's answer.
- The Backlog-option failure names the fix (the `board.statuses.backlog` mapping).
- Podman is detected as a container, or the limit is documented.
- `CODEO_CLEANUP_REMOVAL` stops being read in the production path, or is clearly scoped to tests.

### Acceptance Criteria
- [ ] Under a `/run/.containerenv` container, `role.sh` reports the role as it does for `/.dockerenv` (or the docs name the limit).
- [ ] `/codeo:cleanup` with `CODEO_CLEANUP_REMOVAL` exported outside tests does not change what it prints.
- [ ] The cleanup skill description, `docs/skills.md` and the plan/implement/qc/handoff sentence carry no project-specific container claim in generic text.
- [ ] `live.sh` accepts the same lock-issue pattern in `read_lock` and `list`; a test pins it.
- [ ] `github.sh ref delete` treats only `Reference does not exist` as already deleted; a 404 for a refused write is reported as a failure.
- [ ] The `CODEO_LIVE_PUSH_TIMEOUT` documentation (CHANGELOG, `live.sh` header) matches what `live.sh:155` bounds.
- [ ] A stashed or abandoned workflow's `live:` line clears, or the 15-minute lag is documented.
- [ ] The docs name `CODEO_MACHINE` as the way out of the same-volume-name collision.
- [ ] `board.sh` with no Backlog option prints a message that names the `board.statuses.backlog` fix.
- [ ] `skills/issue/SKILL.md` describes `set`'s one-line-per-project output.
- [ ] `CHANGELOG.md` states the `issue:<N>` fingerprint change and corrects the #107 `codeo-root.sh` bullet.
- [ ] `title_reports_a_failing_container_name_as_one_line` can fail for the behaviour it names, or its name says what it guards.
- [ ] The `rm -f -- ""` check output is recorded on #107.
- [ ] `bash tests/run.sh` passes and `CHANGELOG.md` records the change.

### Out of Scope
- #104's web-session label (F3): settles with #112.
- #108's items (`overlap.sh`, `qc-verdict.sh` error handling and test guards).
- #103's triage judging of in-flight workflows.

### Reference
- `.codeo/done/70/qc.md`, `.codeo/done/70/implement.md` (J6-J8)
- `.codeo/done/71/qc.md` (F7-F9)
- `.codeo/done/104/qc.md`, `.codeo/done/104/implement.md` (F3, F5, F7, F10, F13-F16)
- `.codeo/done/107/qc.md` (F1-F3)
- Related: #103, #108, #112; triage run `.codeo/intake/triage/2026-11-16.md` Q1-Q5

## Log

- 2026-11-16 — dossier opened from triage Q1-Q5, Q1-Q3 raised, draft recorded · cost: unavailable
