# Issue — issue (draft, no number yet)

| | |
|---|---|
| Working title | The dev container start script reports a `.codeo/active` that names no issue |
| Source | `/codeo:triage` run 2026-11-15-2, Q1 (`qc:57:F2`); engineer chose "file it" |
| Updated | 2026-11-15 |

## Where this stands

Restated: in a dev container, a `.codeo/active` that has content but no `issue:` line (a single newline, or any text) is treated by `devcontainer-start.sh` as a held lock, because it tests the file with `-s`. The start script then neither takes a lock nor says anything, `container-name.sh` names the container "home", and `folder-check.sh` reports nothing — the same silent no-lock state #57 fixed for a zero-byte file. Two questions are open; the draft is written once they are answered.

Checked, not assumed:
- **No duplicate.** An issue search found nothing on this; #57 (closed) handled only the zero-byte file, and #54 is the title-hook and container-name edges from #47 and #50.
- **Reproduced** in a scratch clone with the real scripts: `.codeo/active` holding one newline (size 1) and holding `garbage` (size 7) both give `-s` true, `container-name.sh --docker` → `codeo-home`, and `folder-check.sh codeo-home` → no output. A real lock reads `issue:   <N>` and `branch:  <name>` (that is what `lock.sh take` writes), and `container-name.sh` finds the number with `^issue:[[:space:]]*#*[0-9]+`.
- **Out of the repository's reach:** the lock is written by codeo's own `lock.sh`, which the container runs from the pinned plugin, so a fix to that script would not reach containers until the next pin bump; the report is the start script's.

## Questions

### Q1 — What should the start script do with a `.codeo/active` that names no issue?

**Why it matters:** the two answers are different behaviour and different tests. #57 removed the zero-byte file because it held nothing to lose; a file with other content might be a lock someone wrote by hand or a half-written one, and deleting it destroys that.

**Options:**
- *Report it and leave it* (recommended): one `devcontainer-start: TODO — .codeo/active names no issue, so it holds no usable lock: look at it, remove it if it is not yours, then re-run this script`; no lock is taken, nothing is deleted.
- *Remove it and carry on*, as for an empty file: it is replaced by the lock on an issue branch, with the removal reported. Simpler for the engineer; loses the content.
- *Something else* (say what).

**Answer:**
Report it and leave it. Go with the recommendation (engineer, in the conversation, 2026-11-15).

### Q2 — Is the start script the only place that should notice?

**Why it matters:** it sets how much this issue touches. `container-name.sh` and `folder-check.sh` read the same file; if only the start script reports, a later `window-title.sh` run still says "home" quietly (as it does today for a missing lock, deliberately). Reporting in all three means a shared check and three test files.

**Options:**
- *Start script only* (recommended): it runs once when the container is created, which is when the engineer can still act on a TODO; the titles keep reading the file as they do.
- *Also `folder-check.sh`*, so a re-run of the folder check names it too.
- *Something else* (say what).

**Answer:**
Start script only. Go with the recommendation (engineer, in the conversation, 2026-11-15).

## Draft

**Title:** The dev container start script reports a `.codeo/active` that names no issue

**Type:** none (user-owned repository, no Issue Types). **Labels:** `bug`.

### Description

When a dev container starts, `.devcontainer/scripts/devcontainer-start.sh` treats any non-empty `.codeo/active` as a held lock. A file that holds only a newline, or text with no `issue:` line, therefore counts as a lock: the script takes none and prints nothing, `container-name.sh` names the container "home", and `folder-check.sh` reports nothing. Report such a file with one `todo:` line and leave it where it is.

### Motivation / Context

#57 fixed the same silent state for a zero-byte `.codeo/active` (the script now removes it and takes the lock). It was found by `/codeo:qc` as finding F2 of #57, left out of that issue because the criteria named only the empty file, and brought here by `/codeo:triage` (run 2026-11-15-2, item `qc:57:F2`).

Reproduced in a scratch clone with the real scripts: a `.codeo/active` holding one newline, and one holding `garbage`, each tests true for `-s`, give `container-name.sh --docker` → `codeo-home`, and give `folder-check.sh codeo-home` → no output. A real lock reads `issue:   <N>` and `branch:  <name>`, as `lock.sh take` writes it. The container looks started, has no lock, and says nothing.

### Key Requirements

- A `.codeo/active` that is not empty and has no `issue:` line naming an issue is reported with one `todo:` line that names the file and says what to do: look at it, remove it if it is not yours, then re-run the script. "Names an issue" is the rule `container-name.sh` already uses to read the number: `issue:` at the start of a line, then optional spaces, tabs or `#`, then digits.
- Nothing is deleted, rewritten or locked over: the file is left exactly as it is, and `lock.sh` is not called for it. (An empty file is still removed, as #57 does.)
- This holds on any branch, the base branch included, since a stray file with content is as unexpected in the home container as in an issue container.
- A `.codeo/active` that does name an issue keeps today's behaviour: no second lock, no new TODO.
- Only the start script changes; the titles keep reading the file as they do, and `folder-check.sh` and `container-name.sh` are unchanged. The lock script is codeo's own and runs from the pinned plugin, so it is not touched.

### Acceptance Criteria

- [ ] A test starts a container on an issue branch with a `.codeo/active` holding only a newline, and another with one holding text with no `issue:` line: each prints one TODO that names `.codeo/active`, no lock is taken, and the file is unchanged afterwards.
- [ ] The same file on the base branch prints the same TODO and is unchanged.
- [ ] A `.codeo/active` with an `issue:` line (`issue:   55`, `issue: #55`) prints no such TODO and takes no second lock; a zero-byte one is still removed, as before.
- [ ] `.devcontainer/README.md` states the behaviour in its list of what the start script does.
- [ ] `bash tests/run.sh` passes and `CHANGELOG.md` records the change.

### Out of Scope

- `lock.sh`, and anything under `scripts/`, `lib/`, `hooks/` or `skills/`.
- `container-name.sh`, `folder-check.sh` and `window-title.sh`: the titles and the folder check keep reading the file as they do.
- A `.codeo/active` that is a directory (it predates #57 and is not a lock file).
- Repairing a half-written lock for the engineer.

### Reference

- #57 (closed) and its archived dossier, `.codeo/done/57/qc.md` round 2, finding F2: "`devcontainer-start.sh` tests `.codeo/active` with `-s`, so a file holding only a newline or text with no `issue:` line still counts as a held lock … Outside the criteria; left for `/codeo:triage`."
- `.devcontainer/scripts/devcontainer-start.sh` (step 3a), `.devcontainer/scripts/container-name.sh` (the `issue:` rule), `tests/devcontainer.test.sh` (the `start_*lock_file*` cases).
- Related, not duplicate: #54 (title-hook and container-name edges).

## Log

- 2026-11-15 — dossier started from triage item `qc:57:F2`: Q1-Q2 raised
- 2026-11-15 — Q1-Q2 answered (recommendations accepted); draft written, awaiting approval
