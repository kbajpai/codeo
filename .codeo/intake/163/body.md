### Description

`/codeo:qc` passed #152 (the host home role, its strict guard and the tracking comment) with non-blocking findings that were recorded for triage and have no issue. This issue closes them: a cleanup overlay that prints a placeholder until a plugin release lands, a by-hand removal fallback that tells the engineer to do something that changes nothing, a temporary file `codeo-track.sh` leaks on every `add` and `mark`, README sentences that say more or less than the code does, and a missing page of upkeep.

### Motivation / Context

- **#152 F13:** `.codeo/overlays/cleanup.md:11` prints `codeo rm {N}` and relies on `scripts/cleanup.sh` expanding `{N}` in `command:`. The `origin/main` `cleanup.sh` expands only `{name}` there and the project pins the plugin at `ref` `v1.0.8`, so until a release carrying the new `cleanup.sh` is installed `/codeo:cleanup` prints `codeo rm {N}` literally and drops the `fallback:` line. The CHANGELOG does not say so. The window closes with the project's own next release.
- **#152 F14:** the by-hand fallback (`.codeo/overlays/cleanup.md:12`, `.codeo/overlays/close.md:11`) tells the engineer to mark the image `codeo-dev:<name>` `removed`, but its two docker commands never remove an image, so the comment would show a `removed` image that still exists. It does not say where to run `bash .devcontainer/codeo-track.sh mark …`: `mark` changes only rows whose Host equals `hostname` (`codeo-track.sh:187`) and the issue container runs with `--hostname <name>` (`codeo-container.sh:118`), so run inside a container it prints its no-match note and changes nothing. It also names `docker rm` for a sandbox, which does not end one (the reviewer's claim from `.sbx/README.md`, not re-read in the dossier).
- **#152 F15:** `.devcontainer/codeo-track.sh:54,137`: `save` calls `f=$(new_tmp)`, so `tmp_files+=("$f")` runs in the command substitution's subshell and the `EXIT` trap never removes the file. Each `add` or `mark` leaves a `codeo-track.XXXXXX` file holding the comment body in `$TMPDIR` (the reviewer counted 348 left by the test runs).
- **#152 F16:** `README.md:248` says a local container of that name "lists them and asks before it creates another"; `codeo-container.sh:92-93` warns and refuses outright. `.devcontainer/README.md` describes it correctly.
- **#152 F17:** `README.md:199` says `jq` is needed for `baseBranch` and the guard falls back to `main` without it. `container-name.sh:30-31` also reads the codename with `jq` and falls back to the folder name, so without `jq` a `codeo-home` folder gives the codename `codeo-home` and the home clone can read as `stray` (plausible from the code read, not run).
- **#152 F18:** `README.md:219` says "A host checkout is no longer `unguarded`", which describes the change rather than the system; the example comment at `README.md:227` uses #152's number and the branch `feat/152-example`.
- **#152 F19:** the criterion said "install and upkeep"; the README's host-home section covers the clone (`git pull`) and the plugin through `install.sh`, and says nothing about keeping Claude Code or the `gh` login current.
- **#152 plan gap:** `docs/skills.md`'s `/codeo:cleanup` section does not mention the overlay's fourth field or the `fallback:` line (`.codeo/done/152/implement.md`); nothing there is false.

### Key Requirements

- `/codeo:cleanup`'s output is right both before and after the release that carries the new `cleanup.sh`, or the CHANGELOG names the release that makes the overlay and the script agree.
- The by-hand removal fallback does only things that work: it names where `mark` is run, does not mark an image removed that still exists, and names the sandbox's own removal command.
- `codeo-track.sh` leaves no temporary file behind.
- The READMEs and `docs/skills.md` say what the code does in the cases above.

### Acceptance Criteria
- [ ] Run against the pinned plugin version and against the new `cleanup.sh`, `/codeo:cleanup` prints a removal command with `{N}` replaced by the issue number, or the CHANGELOG names the release from which it does.
- [ ] The by-hand fallback in `.codeo/overlays/cleanup.md` and `.codeo/overlays/close.md` does not mark the `codeo-dev:<name>` image `removed` unless it removes it, says where `bash .devcontainer/codeo-track.sh mark …` is run so that it changes a row, and names a command that ends a sandbox.
- [ ] After `codeo-track.sh add` and `mark`, no `codeo-track.*` file remains in `$TMPDIR` (a test counts them before and after).
- [ ] `README.md` says a local container of that name is refused (F16), names every use of `jq` and what happens without it (F17), describes the host guard without "no longer" and gives an example comment that does not use #152's number (F18), and says how to keep Claude Code, `gh` and the plugin current (F19).
- [ ] `docs/skills.md`'s `/codeo:cleanup` section names the overlay's fourth field and the `fallback:` line.

### Out of Scope

- #152 F20: macOS `hostname` following the network, an image row left untracked after a failed `docker run`, a finished sandbox read as `stray` with a message that does not explain it, and two simultaneous first creations leaving two tracking comments.
- Making `mark` match rows from another host.

### Reference

- `.codeo/done/152/qc.md` round 2 (F13-F20) and its `## Notes`; `.codeo/done/152/implement.md` (the `docs/skills.md` plan gap).
- `.codeo/overlays/cleanup.md`, `.codeo/overlays/close.md`, `.devcontainer/codeo-track.sh`, `.devcontainer/codeo-container.sh`, `README.md`, `docs/skills.md`, `CHANGELOG.md`.
- Surfaced in `/codeo:triage` run 21 (`qc:152:F13-F20`).
