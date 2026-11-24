# Issue #163 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/163 |
| Branch | `fix/close-152-leftovers-cleanup-overlay` |
| Updated | 2026-11-24 |

## Where this stands

Explored, Q1-Q3 raised, nothing drafted. The draft waits for the three answers.

What I found (read against the code at `2619567`):

- **F13 reads as the finding says.** The pinned v1.0.8 `scripts/cleanup.sh` expands only `{name}` in `command:` and prints three fields; this repository's `scripts/cleanup.sh:104` also expands `{N}` and prints the `fallback:` as a fourth field. So under the pin, `/codeo:cleanup` here prints `codeo rm {N}` and no fallback. `CHANGELOG.md`'s `## Unreleased` bullet says `scripts/cleanup.sh` expands `{N}` and does not say an installed v1.0.8 does not. See Q1.
- **F14 reads as the finding says.** `.codeo/overlays/cleanup.md:12` and `.codeo/overlays/close.md:11` name `docker rm -f` and `docker volume rm`, then say to mark the container, the volume and the image `codeo-dev:<name>` `removed`. Nothing removes the image. `codeo rm` itself does remove it and marks it (`.devcontainer/codeo:721`). `mark` changes a row only when its Host equals this machine's `hostname` (`codeo-track.sh:187`) and the issue's container runs with `--hostname <name>` (`codeo-container.sh:118`), so `mark` run inside a container changes nothing. The cleanup overlay's one `fallback:` line is printed for every proven issue, sandbox or container, and names only `docker`; `.sbx/README.md:47` gives `bash codeo-sandbox.sh end <N>` as the command that ends a sandbox and marks its row. The close overlay's sandbox paragraph has no by-hand sentence at all.
- **F15 is reproduced.** One `codeo-track.sh add 5 container codeo-5` against a stub `gh`, with `TMPDIR` pointing at an empty directory, leaves one `codeo-track.XXXXXX` file there. The cause is `f=$(new_tmp)` at `:137`: `tmp_files+=` runs in the substitution's subshell, so the `EXIT` trap's list is empty.
- **F17 is reproduced** (the dossier had it as "plausible, not run"). A clone named `codeo-home` on `main` with no lock, read as a host (`CODEO_DOCKERENV` and `CODEO_CONTAINERENV` pointed at nothing): with `jq`, `role.sh` prints `home`; with `jq` off `PATH` it prints `stray`, and `--check triage` refuses with "neither the home clone (a folder named codeo-home-home on main …)". `container-name.sh:30` falls back to the folder name as the codename; `role.sh:53` falls back to `main` as the base branch.
- **F16, F18, F19 and the `docs/skills.md` gap read as the findings say**: `README.md:248` ("lists them and asks") against `codeo-container.sh:92-93` (warns and dies); `README.md:219` ("no longer `unguarded`") and the `#152` / `feat/152-example` example at `:223-229`; the host-home list at `README.md:199-202` covers `git pull` and `install.sh` only; `docs/skills.md:248-270` names neither the fourth field nor `fallback:` (`docs/extension-points.md:588-591` does).
- **Tests that pin the text this changes:** `tests/cleanup-skill.test.sh:46-50,93-97` (the overlay's `command:` and `fallback:` lines and the expanded fallback), `tests/close-removal.test.sh:20,36-62` (the close overlay's phrases; the sandbox paragraph must hold no `docker rm`), `tests/track.test.sh` (the tracker, against a stub `gh`).
- The `shell` suite has no `filter`: each task's proof is `bash tests/run.sh <name>` for the file it touches, then the whole `bash tests/run.sh`.
- **In flight:** #161 on two branches, both at `qc` with a clear verdict, waiting on `/codeo:close`, and both list `CHANGELOG.md`: see Q3. #166 (`docs/close-157-leftovers-hosted-web`) is at `init` with nothing changed and no footprint yet, so there is nothing to compare it against.

My calls, stated so they can be corrected (not questions):

- One plan under `docs/plans/`, one pull request, no reference doc: nothing here is a standing decision.
- **F14, where `mark` runs:** the text says to run it on the host that created the container, from a clone of the project there (the home clone), not inside any container.
- **F14, sandbox:** the cleanup overlay's `fallback:` says that for an sbx sandbox the command is `bash codeo-sandbox.sh end {N}` from the folder that holds the script, which checks for unpushed work and marks the row itself, and that `docker rm` does not end a sandbox. The close overlay's sandbox paragraph gains one sentence saying the same. It stays free of `docker rm`, as `tests/close-removal.test.sh:62` requires.
- **F15:** `new_tmp` stops printing the path and sets a variable in the calling shell (`new_tmp || fail_record …; f=$tmp_file`), so the trap's list is filled where the trap runs. A new case in `tests/track.test.sh` gives the script an empty `TMPDIR` and counts `codeo-track.*` there before and after an `add`, a `mark` and a failed `add` (the stub's `fail` file).
- **F16-F19 are README only.** F17 names both reads the guard makes with `jq` (the codename and `baseBranch`) and what each does without it, with the `stray` refusal reproduced above; the guard's code is not changed. F18's example uses an invented issue (`#12`, `feat/12-order-export`), as `docs/dossier.md` does. F19 gets a short "keeping it current" list: `claude update`, `gh auth status` (and `gh auth login` when it fails), `install.sh` for the plugin (pointing at *Updating*), `codeo update` for the host command and its scripts, `git pull` for the clone.
- **`docs/skills.md`:** one sentence in the cleanup section's *Purpose and triggers* names the fourth field and the overlay's `fallback:` line, and the *Extension points* bullet's default is left as it is.
- `skills/cleanup/SKILL.md` and `scripts/cleanup.sh` are not edited unless Q1 is answered B.
- The `engineering` plugin is not installed here; no new component or technology choice is involved, so its structure is not needed.

## Questions

### Q1 — F13, `codeo rm {N}` under the pinned v1.0.8: say so in the CHANGELOG, or make the overlay work under both versions?

**Why it matters:** the criterion allows either. It decides whether the cleanup overlay and two test files change shape, or one CHANGELOG sentence is added.
**Options:**
- **A — the CHANGELOG names the release (my pick).** The `## Unreleased` bullet about `/codeo:cleanup` gains a sentence: `{N}` in `command:` and the `fallback:` line are read from v1.0.9 on; a project whose overlay uses them while its plugin is pinned at v1.0.8 or earlier sees `codeo rm {N}` printed as written and no fallback, until the pin moves. The overlay stays `command: codeo rm {N}`. The window ends when this repository's pin moves to the next release. This assumes the next release is v1.0.9: say so if it is not.
- **B — an overlay that both versions expand.** `name: {N}`, `pattern: ^[0-9]+$`, `command: codeo rm {name}`: v1.0.8 expands `{name}`, so both print `codeo rm 163`. The cost: `name` stops being the container's name, which is what `docs/extension-points.md` says it is, and the pattern no longer rejects `codeo-home`, `codeo-gh` and `codeo-git` (`tests/cleanup-skill.test.sh:93-96` checks that it does). The fallback is still not printed under v1.0.8, so the CHANGELOG sentence is needed for that half anyway.
- **C — both A and B.**

**Answer:**

### Q2 — F14, the image in the by-hand fallback: remove it too, or stop marking it?

**Why it matters:** the criterion allows either. It decides whether the by-hand path leaves the issue's tracking comment the same as `codeo rm` does, or leaves an `active` image row and an image on disk.
**Options:**
- **A — remove it too (my pick).** The fallback names a third command, `docker rmi codeo-dev:<name>`, and keeps the instruction to mark container, volume and image `removed`. This is what `codeo rm` does, so both paths end with the same rows. The fallback sentence grows by one command.
- **B — stop marking it.** The fallback keeps its two docker commands, says to mark the container and the volume only, and says the image `codeo-dev:<name>` is left on disk with its row `active`. Shorter, and the image (a few hundred MB per issue) stays until someone removes it.

**Answer:**

### Q3 — #161 also changes `CHANGELOG.md`: proceed, sequence, or re-scope?

**Why it matters:** #161 is in flight on two branches, `docs/documentation-leftovers-154-146-removal` and `claude/ecstatic-mendel-n3qyzl` (assignee kbajpai, step `qc`, verdict clear, waiting on `/codeo:close`), and both have changed `CHANGELOG.md`. This plan adds to the `## Unreleased` section of `CHANGELOG.md` (one sentence under Q1's A, plus a bullet for the F14 and F15 fixes). Nothing else overlaps: #161's other files (`.devcontainer/README.md`, `docs/release-checklist.md`, `.claude/**`, `tests/live-signal.test.sh`) are not in this plan. The answer decides whether I draft now against today's `CHANGELOG.md` or wait for #161 to merge.
**Options:** *proceed and coordinate* (my pick: #161 is one step from merging and both changes add lines to the same section, so whichever merges second rebases and keeps both sides) · *sequence after #161* (this plan is drafted once #161 has merged) · *re-scope* (say what to leave out of `CHANGELOG.md`).

**Answer:**

## Notes

None yet.

## Outcome

_Pending — written at the hand-off._

## Log
- 2026-11-24 — Q1-Q3 raised; the engineering plugin is not installed and was not needed · cost: 2m · fable-5-2 111k in + 989k cached / 13k out
