# Issue #54 — issue

## Where this stands

Called by `/codeo:triage` (2026-11-10, Q1-Q3: *file it*, consolidated into one issue). Problem as I read it: #47 and #50 each closed with non-blocking QC findings and deferred minors that nobody tracks — all in the dev container's start script, session-title scripts, container naming and their tests. Searched existing issues: #40 (closed-form follow-ups of #36) already owns the *duplicate* `safe.directory` entry; nothing covers the rest. No Issue Types are defined for this repository. Label proposed: `enhancement`.

## Questions

### Q1 — F29: `safe.directory` entries pile up in the shared volume

QC F29: "`safe.directory` entries now accumulate in the shared `codeo-git` volume, one per clone path ever created, unpruned. Harmless." #40 already asks that two runs leave *one* entry per path, not that stale paths be pruned.

**Options.** *leave it out, #40 covers the neighbouring part* · *include pruning here*.

**Answer:** leave it out, #40 covers the neighbouring part (engineer accepted the recommendation, 2026-11-10).

### Q2 — F1: what should a clone folder Docker rejects do?

QC F1: Docker accepts only `[a-zA-Z0-9][a-zA-Z0-9_.-]+`, and the container is now named from `${localWorkspaceFolderBasename}`, so a folder with a space, `+`, `@`, non-ASCII or a leading `.`/`_` fails to start where it used to work. I state the requirement; how is `/codeo:plan`'s.

**Options.** *start must still work for any folder name (the name falls back to something valid)* · *document the limit in the CHANGELOG and README only* · *both: document it and give a clear failure message*.

**Answer:** start must still work for any folder name, the name falling back to something valid (first option; engineer accepted "all recommendations", 2026-11-10).

### Q3 — Which small items are in, which are recorded and left?

Proposed **in**: F24 (mode-change message), F25 (`touch` on every prompt), F27 (wording for a directory/unreadable `settings.json`), F28 (message does not say it overrode a global `false`), F2 of #50 (exact `runArgs` test), the `implement.md` minors (discarded stderr of a failed `git diff`, no both-mode-and-content test, leftover `modes.*` temp file).
Proposed **recorded in Out of Scope, not done**: F26 (unwritable `info/exclude` skips the title — pinned on purpose by `title_reports_an_unwritable_exclude`), F20 (leading digits of the lock line), F21 (owner and hard links of `settings.json`), F23 (linked worktrees) — no concrete failure shown.

**Options.** *as proposed* · *move these: …* · *everything in*.

**Answer:** as proposed (engineer accepted the recommendation, 2026-11-10).

## Draft (approved and filed as #54)

**Title:** Dev container follow-ups from #47 and #50: mode-change message, title-hook edges, container-name limits

**Type:** none defined. **Labels:** `enhancement`.

### Description

Close the non-blocking findings the QC passes for #47 and #50 left behind in the dev container: the start script's `core.fileMode` message, the session-title scripts, and the container name derived from the clone folder.

### Motivation / Context

Each finding was classified non-blocking and recorded in an archived dossier (`.codeo/done/47/qc.md`, `.codeo/done/47/implement.md`, `.codeo/done/50/qc.md`), where nothing downstream reads it. Together they mean a silent set of mode changes a later `git add -A` would commit, a hook that rewrites a file's mtime on every prompt, error text that names the wrong cause, and a clone in a folder Docker rejects that no longer starts.

### Key Requirements

- When the start script turns `core.fileMode` on, files executable on disk but recorded `100644` are counted and named in its output (or a TODO), so the resulting `mode change` lines are explained. (QC #47 F24.)
- `window-title.sh` does not touch `info/exclude` when the line is already present, so `session-title.sh`'s "no-op when current" is true. (F25.)
- A `settings.json` path that is a directory or unreadable is reported as that, not as "not valid JSON". (F27.)
- The `core.fileMode` step says when it overrode a `false` set in a wider scope. (F28.)
- A clone folder name Docker rejects: the container name falls back to a valid one, so start works for any clone folder name. (QC #50 F1.)
- `run_args_cap_memory_and_cpus` pins the exact `runArgs` array so an extra or duplicate entry is caught. (QC #50 F2.)
- The failed `git diff` listing's stderr reaches the TODO; a test covers a file differing in both mode and content; no `modes.*` temp file survives an interrupted run. (`implement.md` #47.)

### Acceptance Criteria

- [ ] A tracked file executable on disk and recorded `100644` is named in the start script's output after `core.fileMode` goes on.
- [ ] Calling `window-title.sh` twice leaves `info/exclude`'s mtime unchanged on the second call.
- [ ] A `settings.json` that is a directory is reported as not a regular file, not as invalid JSON.
- [ ] With `core.fileMode=false` set globally, the start script's message says it overrode that value.
- [ ] A dev container for a clone in a folder named `my project` or `_x` starts, with a valid container name.
- [ ] A second `--memory` or `--cpus` entry in `runArgs` fails `tests/devcontainer.test.sh`.
- [ ] A failed mode listing's reason appears in the TODO; the both-changed case has a test; an interrupted run leaves no `modes.*` file.
- [ ] `bash tests/run.sh` passes and `CHANGELOG.md` records the change.

### Out of Scope

- Pruning or deduplicating `safe.directory` entries (the duplicate entry is #40).
- Findings recorded and left : F26 (title skipped when `info/exclude` is unwritable, pinned by a test on purpose), F20, F21, F23.
- Any change under `scripts/`, `lib/`, `hooks/` or `skills/`.

### Reference

- `.codeo/done/47/qc.md` (F20-F29), `.codeo/done/47/implement.md` (deferred minors), `.codeo/done/50/qc.md` (F1-F3), triage dossier `.codeo/intake/triage/2026-11-10.md` (Q1-Q3); #40, #47, #50.

## Outcome

Filed as #54 (https://github.com/kbajpai/codeo/issues/54), engineer approved 2026-11-10.

## Log

- 2026-11-10 — issue dossier drafted, Q1-Q3 raised
- 2026-11-10 — approved and filed as #54
