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

### Q2 — Is the start script the only place that should notice?

**Why it matters:** it sets how much this issue touches. `container-name.sh` and `folder-check.sh` read the same file; if only the start script reports, a later `window-title.sh` run still says "home" quietly (as it does today for a missing lock, deliberately). Reporting in all three means a shared check and three test files.

**Options:**
- *Start script only* (recommended): it runs once when the container is created, which is when the engineer can still act on a TODO; the titles keep reading the file as they do.
- *Also `folder-check.sh`*, so a re-run of the folder check names it too.
- *Something else* (say what).

**Answer:**

## Draft

_Written after Q1-Q2 are answered._

## Log

- 2026-11-15 — dossier started from triage item `qc:57:F2`: Q1-Q2 raised
