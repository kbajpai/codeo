# Close the #152 leftovers: the cleanup overlay, the by-hand removal fallback, a temporary-file leak and README wording Implementation Plan (#163)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `codeo-track.sh add` and `mark` leave no `codeo-track.*` file in `$TMPDIR`; the by-hand removal fallback in both overlays removes what it marks, says where `mark` runs, and names the command that ends a sandbox; the CHANGELOG says what an installed v1.0.8 prints for the cleanup overlay; `README.md` and `docs/skills.md` say what the code does in the cases #163 names; and `bash tests/run.sh` ends `all cases passed`.

**Architecture:** one small code change (Task 1, test first) in `.devcontainer/codeo-track.sh`; then the two overlay texts with their test pins (Task 2); then prose: CHANGELOG (Task 3), README (Task 4), `docs/skills.md` (Task 5). `scripts/cleanup.sh`, `skills/**` and the guard scripts are not edited.

**Tech Stack:** bash, git, awk, grep; the `shell` suite (`bash tests/run.sh`, or one file with `bash tests/run.sh <name>`, the name matched as a substring of the file name).

**Spec:** `.codeo/163/init.md` `## Outcome` (the issue's acceptance criteria) and `.codeo/163/plan.md` Q1-Q3, whose answers are the design. Reference doc: none; nothing here is a standing decision.

## Global Constraints

- **Q1 (A): the CHANGELOG names the release; the overlay stays `command: codeo rm {N}`.** The pinned v1.0.8 `scripts/cleanup.sh` expands only `{name}` in `command:` and prints no fallback; this repository's `scripts/cleanup.sh` (`:104-109`) expands `{N}` and prints it as the fourth field. The `## Unreleased` cleanup bullet gains the sentence in Task 3. It assumes the next release is v1.0.9; if the release is numbered otherwise, the sentence changes with it.
- **Q2 (A): the fallback removes the image too.** Its docker commands are `docker rm -f {name}`, `docker volume rm {name}` and `docker rmi codeo-dev:{name}`, as `codeo rm` does (`.devcontainer/codeo:721`), so the rows it tells the engineer to mark `removed` are rows of things it removed.
- **Q3: proceed and coordinate with #161** (two branches, both at `qc`, clear verdict, waiting on `/codeo:close`; both changed `CHANGELOG.md`). This plan edits only `## Unreleased` of `CHANGELOG.md`, adding to the cleanup bullet and one new bullet; whoever merges second rebases and keeps both sides. #161's other files are not in this plan. #166 is at `init` with no footprint: nothing to compare.
- **`mark` runs on the host that created the container, in a clone of the project, never inside a container.** `mark` changes a non-branch row only when its Host equals `hostname` (`codeo-track.sh:187`), and the issue container runs with `--hostname <name>` (`codeo-container.sh:118`), so inside it the command prints its no-match note and changes nothing.
- **A sandbox is ended by `bash codeo-sandbox.sh end <N>`**, run from the folder that holds the script (`.sbx/README.md:47`): it refuses over unpushed or uncommitted work and marks its row `removed` itself. `docker rm` does not end a sandbox. The cleanup overlay's one `fallback:` line serves both kinds of issue, so it names both. The close overlay's fallback sits in its `container` paragraph, so the sandbox sentence goes there as a parenthesis; its `sandbox:` paragraph is not edited, because `tests/close-removal.test.sh` checks e and g (`:57-66`) require it to hold no `docker rm` and no `codeo-sandbox.sh end`.
- **F15's cause and fix.** `f=$(new_tmp)` runs `tmp_files+=` in the command substitution's subshell, so the `EXIT` trap's list stays empty. `new_tmp` sets `tmp_file` in the calling shell instead of printing it.
- **F17 is documented, not changed.** Without `jq`, `role.sh` reads no `baseBranch` (falls back to `main`) and `container-name.sh` reads no `codename` (falls back to the folder name), so a clone named `codeo-home` reads as `stray` and every guarded skill refuses it; reproduced at plan time. The README states this; the guard is out of scope.
- **Out of scope** (the issue's): #152 F20, and making `mark` match rows from another host.
- **A mutation is a proof.** Where a step says "mutate", change the file, run the stated command, see the stated failure, and revert with `git checkout -- <file>` straight after; no mutation is committed.
- **Documentation moves**, one task each: `CHANGELOG.md` (Task 3), `README.md` (Task 4), `docs/skills.md` (Task 5). The overlays (Task 2) are the project's own instructions, not documentation pages. `docs/extension-points.md` already describes the fourth field and `fallback:` and is not edited. No wiki module.
- **No environment, no lease, no host tasks.** No shared environment, wiki module, invariants document or exclusive resource is configured and the lock's host is `container`: every task runs in this checkout and none carries `Needs lease:` or `Runs on:`.
- **Invariants:** none configured.

## Review Focus

- Task 1: the new case must fail before the fix and pass after, for `add` creating, `add` editing, `mark`, and a failed save.
- Task 2: the overlay `fallback:` stays one line (`cleanup.sh` reads the first line of the key), and `tests/close-removal.test.sh` passes **untouched**: its checks e and g are why the sandbox paragraph is not edited.
- Tasks 3-5 are wording: read each new sentence against the code line it cites.

---

## File Structure

| File | Change |
|---|---|
| `.devcontainer/codeo-track.sh` | `new_tmp` sets `tmp_file` instead of printing; `save` uses it |
| `tests/track.test.sh` | case `no_temp_file_left` |
| `.codeo/overlays/cleanup.md` | the `fallback:` line |
| `.codeo/overlays/close.md` | the finished-close sentence for a `container` lock |
| `tests/cleanup-skill.test.sh` | pins for the new fallback text |
| `tests/close-removal.test.sh` | two new needles |
| `CHANGELOG.md` | one sentence on the cleanup bullet; one new bullet |
| `README.md` | the host-home requirements list, the guard sentence, the example comment, the creation paragraph |
| `docs/skills.md` | the `/codeo:cleanup` section |

---

### Task 1: `codeo-track.sh` leaves no temporary file (F15)

**Files:**
- Modify: `tests/track.test.sh` (new case before the final `if ((failures))`)
- Modify: `.devcontainer/codeo-track.sh:51-54,137`

- [ ] **Step 1: write the failing case.** After `mark_without_comment_prints_a_note`:

```bash
case_desc=no_temp_file_left
reset; fixture 77 '| container | `c1` | box1 | active | 2026-11-01T00:00:00Z | |'
tdir=$work/tmp; rm -rf "$tdir"; mkdir -p "$tdir"
export TMPDIR=$tdir
run add 152 container codeo-152; assert_eq add_edit_rc 0 "$rc"
run mark 152 container c1 removed; assert_eq mark_rc 0 "$rc"
reset; run add 152 container codeo-152; assert_eq add_create_rc 0 "$rc"
reset; fixture 77 '| container | `c1` | box1 | active | 2026-11-01T00:00:00Z | |'; touch "$state/fail"
run add 152 container codeo-152; assert_eq failed_save_rc 3 "$rc"
unset TMPDIR
assert_eq "files left in TMPDIR" "0" "$(find "$tdir" -name 'codeo-track.*' | wc -l | tr -d ' ')"
```

- [ ] **Step 2: see it fail.** `bash tests/run.sh track` — expected failure: `FAIL: no_temp_file_left - files left in TMPDIR: want [0] got [3]` (one per saved write; the failed-save run saves nothing because the stub's `fail` file also fails the read first, so the count may read 3 or 4 — any non-zero count is the failure).

- [ ] **Step 3: fix it.** In `.devcontainer/codeo-track.sh`, replace `new_tmp` with

```bash
tmp_file=
new_tmp() { tmp_file=$(mktemp "${TMPDIR:-/tmp}/codeo-track.XXXXXX") || return 1; tmp_files+=("$tmp_file"); }
```

and in `save`, replace `f=$(new_tmp) || fail_record "could not write a temporary file; $hint"` with `new_tmp || fail_record "could not write a temporary file; $hint"` followed by `f=$tmp_file`.

- [ ] **Step 4: proof of done.** `bash tests/run.sh track` prints `all cases passed` for `track.test.sh`. Mutate before committing: in `save`, put back `f=$(new_tmp)`, run the same command, see `no_temp_file_left` fail again, then restore the fix; the file is committed only in its fixed form.
- [ ] **Step 5: commit** `fix: codeo-track.sh removes its temporary file (#163)`.

### Task 2: the by-hand fallback removes what it marks, says where `mark` runs, ends a sandbox

**Files:**
- Modify: `tests/cleanup-skill.test.sh` (after `:97`), `tests/close-removal.test.sh` (`:20`)
- Modify: `.codeo/overlays/cleanup.md` (the `fallback:` line), `.codeo/overlays/close.md` (the finished-close `container` sentence)

- [ ] **Step 1: write the failing pins.** In `tests/cleanup-skill.test.sh`, after the line that checks `$fb` at `:97`, add:

```bash
for needle in 'docker rmi codeo-dev:codeo-70' 'codeo-sandbox.sh end 70' 'docker rm does not end a sandbox' 'on the host that created the container' 'not inside a container' 'mark 70 image codeo-dev:codeo-70 removed'; do
    [[ $fb == *"$needle"* ]] || check_fail "the overlay's fallback lacks: $needle"
done
```

In `tests/close-removal.test.sh:20` add the needles `'docker rmi codeo-dev:codeo-<N>'`, `'on the host that created the container'`, `'bash codeo-sandbox.sh end <N>'` and `'does not end a sandbox'` to the `for needle in` list.

- [ ] **Step 2: see them fail.** `bash tests/run.sh cleanup-skill` fails with `the overlay's fallback lacks: docker rmi codeo-dev:codeo-70`; `bash tests/run.sh close-removal` fails with `overlay output lacks: docker rmi codeo-dev:codeo-<N>`.

- [ ] **Step 3: write the texts.** `.codeo/overlays/cleanup.md`, one line:

```
fallback: if codeo is not installed on the host, run docker rm -f {name}, then docker volume rm {name}, then docker rmi codeo-dev:{name}, once git status in that clone shows nothing unpushed (docker rm does not check for unpushed work); for an issue run in an sbx sandbox run bash codeo-sandbox.sh end {N} from the folder that holds the script instead, which refuses over unpushed work and marks its row itself, because docker rm does not end a sandbox; the issue's rows stay active in its tracking comment until you mark them, on the host that created the container and not inside a container, from a clone of the project, with bash .devcontainer/codeo-track.sh mark {N} container {name} removed (and the same for volume {name} and for image codeo-dev:{name}, as in mark {N} image codeo-dev:{name} removed)
```

`.codeo/overlays/close.md`, the finished-close `container` paragraph: replace the sentence that begins `Add one sentence for an engineer without` with one that says, in this order: without `codeo` on the host, run `docker rm -f codeo-<N>`, then `docker volume rm codeo-<N>`, then `docker rmi codeo-dev:codeo-<N>`; the issue's tracking-comment rows then stay `active` until marked, on the host that created the container and not inside a container, from a clone of the project, with `bash .devcontainer/codeo-track.sh mark <N> container codeo-<N> removed`, and the same for the volume and for the image `codeo-dev:codeo-<N>`; `docker rm` does not check for unpushed work; and (in a parenthesis) a sandbox is ended with `bash codeo-sandbox.sh end <N>` on the host, since `docker rm` does not end a sandbox. Leave the `sandbox:` paragraph as it is.

- [ ] **Step 4: proof of done.** `bash tests/run.sh cleanup-skill`, `bash tests/run.sh close-removal` and `bash tests/run.sh cleanup` each print `all cases passed`. The `fb` assertion at `:97` (`docker rm -f codeo-70`, `docker volume rm codeo-70`, `codeo-track.sh mark 70 container codeo-70 removed`, `unpushed`, no `{`) passes untouched.
- [ ] **Step 5: commit** `fix: the by-hand removal fallback removes the image, says where mark runs and ends a sandbox (#163)`.

### Task 3: CHANGELOG (F13, and what Tasks 1-2 change)

**Files:** Modify `CHANGELOG.md` (`## Unreleased`).

- [ ] **Step 1: edit.** Append to the bullet that begins `` `/codeo:cleanup` and `/codeo:close` print `codeo rm <N>` ``: ` A project whose plugin is pinned at v1.0.8 or earlier prints `codeo rm {N}` as written and no fallback line from the cleanup overlay, because those versions of `scripts/cleanup.sh` expand only `{name}` and print three fields; the pin has to reach the release that carries this script (v1.0.9) first.` Add one new bullet: the by-hand fallback in both overlays now removes the image `codeo-dev:<name>`, says `mark` runs on the host that created the container and not inside it, and names `bash codeo-sandbox.sh end <N>` for a sandbox; `codeo-track.sh add` and `mark` no longer leave a `codeo-track.*` file in `$TMPDIR`; the README and `docs/skills.md` corrections (#163).
- [ ] **Step 2: proof of done.** `grep -c 'pinned at v1.0.8 or earlier' CHANGELOG.md` prints `1`, `grep -c '(#163)' CHANGELOG.md` prints `1`, and `bash tests/run.sh` ends `all cases passed`.
- [ ] **Step 3: commit** `docs: CHANGELOG for the #152 leftovers (#163)`.

### Task 4: `README.md` (F16-F19)

**Files:** Modify `README.md` (`:199`, `:219`, `:227-231`, `:248`, and `:202` area).

- [ ] **Step 1: F16.** Rewrite the paragraph at `:248` so it says: creating a container or sandbox for an issue that already has an `active` container or sandbox row lists the rows and asks before it creates another (`codeo issue <N> --yes` answers yes; without a terminal and without `--yes` it stops); a container of that name already on this host is refused whatever `--yes` says (`codeo-container.sh:92-93` warns and stops), and the message names the ways out (enter it, `--rebuild`, or remove it). Check the sandbox half against `.sbx/codeo-sandbox.sh` before writing it, and match `.devcontainer/README.md`, which already describes this correctly.
- [ ] **Step 2: F17.** Replace the parenthesis at `:199` with a sentence that names every use of `jq` on the host and what happens without it. Find them with `grep -l jq scripts/*.sh lib/*.sh hooks/*.sh install.sh .devcontainer/scripts/*.sh`, and run `role.sh` and `codeo-root.sh` with `jq` off `PATH` to state each outcome rather than guess: the plugin's scripts read `.codeo/config.json` and the GitHub responses with it and stop without it (`install.sh` and `/codeo:doctor` report it missing first); the guard reads `baseBranch` (falls back to `main`) and `codename` (falls back to the folder's name, so a clone named `codeo-home` becomes `codeo-home-home` in the guard's eyes and reads as `stray`, and every guarded skill refuses it). State that `jq` is therefore required, not optional.
- [ ] **Step 3: F18.** At `:219` rewrite `A host checkout is no longer `unguarded`: it is `home`, `issue:<N>` or `stray`.` as a sentence that describes the system: a host checkout is `home`, `issue:<N>` or `stray`; only a hosted web session and a container in an unrelated folder are `unguarded`. In the example comment (`:227-231`) use an invented issue: `#12`, branch `feat/12-order-export`, rows `codeo-12` and `codeo-dev:codeo-12`.
- [ ] **Step 4: F19.** After the requirements list at `:199-202` add a short "Keeping it current" list: Claude Code (`claude update`), the `gh` login (`gh auth status`, `gh auth login` when it fails; `/codeo:doctor` checks it), the plugin (`install.sh`, see *Updating*), the `codeo` command and its scripts (`codeo update`), and the clone (`git pull` on the base branch). Read each command against `README.md`'s *Updating* section and `codeo help`; name no flag you have not seen printed.
- [ ] **Step 5: proof of done.** `grep -c 'no longer `unguarded`' README.md` prints `0`; `grep -c '152' README.md` prints `0`; `grep -c 'claude update' README.md` prints at least `1`; and `bash tests/run.sh` ends `all cases passed`.
- [ ] **Step 6: commit** `docs: README corrections for the host home role (#163)`.

### Task 5: `docs/skills.md`'s `/codeo:cleanup` section

**Files:** Modify `docs/skills.md` (the section at `:248-270`, *Purpose and triggers*).

- [ ] **Step 1: edit.** After the sentence that says the command is printed only when the name matches the overlay's pattern, add one: the overlay's body is three lines and an optional fourth (`name:`, `pattern:`, `command:` and `fallback:`); `scripts/cleanup.sh` prints the expanded `fallback:` as a fourth tab-separated field on every proven line (`-` when there is none) and the skill shows it beneath the command, for an engineer who cannot run it. Link `extension-points.md#cleanupremoval-command`.
- [ ] **Step 2: proof of done.** `grep -c 'fallback:' docs/skills.md` prints at least `1` inside the cleanup section (`awk '/^## cleanup$/{f=1} /^## setup$/{f=0} f' docs/skills.md | grep -c 'fallback:'` prints `1`), `bash tests/run.sh skills` ends `all cases passed` (it checks the page's structure and must pass untouched), and `bash tests/run.sh` ends `all cases passed`.
- [ ] **Step 3: commit** `docs: skills.md names the cleanup overlay's fourth field (#163)`.
