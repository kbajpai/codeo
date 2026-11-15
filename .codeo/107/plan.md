# Issue #107 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/107 |
| Branch | `feat/dev-container-follow-ups-96` |
| Updated | 2026-11-15 |

## Where this stands

Explored `devcontainer-start.sh`, `codeo-root.sh`, `window-title.sh`, `tests/devcontainer.test.sh`, `tests/codeo-root.test.sh`, the CHANGELOG, the README and #96's QC findings. Most of the design is settled (see Notes). Four questions are open: one behaviour choice (Q1), one command only the engineer can run (Q2) and two footprint overlaps (Q3, Q4). No draft is written until they are answered.

## Questions

### Q1 — When `core.fileMode=false` comes from a scope that outranks the clone's config, what should the start script do?

`GIT_CONFIG_COUNT`, `GIT_CONFIG_PARAMETERS` (the `command` scope) and a `worktree` config outrank `.git/config`, so the script's `git config core.fileMode true` changes nothing: git still reads `false`. Today the script then prints both "this clone's config now overrides it with true" and "set it to true for this clone"; both are false. The issue requires only that the "overrode" line goes.

**Why it matters:** decides what the script prints, whether `ready` can appear in that state, and what the test and the README bullet assert.
**Options:**
- **A (recommended)** — after writing the local `true`, read the effective value back. If it is still `false`: print neither line, and list one TODO naming the scope (`core.fileMode is still false from the <scope> config, which outranks this clone's: unset it there, or stage each new script with git update-index --chmod=+x <file>`). The modes are still restored and the local `true` stays (it takes effect once the outranking value is gone). `ready` is not printed, as in every other case where `core.fileMode` stays false.
- **B** — as A, but a plain line on stdout and no TODO, so `ready` can still appear.
- **C** — detect the scope first and do nothing at all (no restore, no local `true`), with the TODO.

**Answer:**

### Q2 — Would you run the `rm` check in the container's terminal and paste the output?

Criterion 8 wants `rm -f -- ""` checked on the image's coreutils. This session's safety check refuses that command (it cannot resolve an empty operand), so neither I nor `/codeo:implement` can run it. What I could establish without it: in this container (Ubuntu 26.04.1) `/usr/bin/rm` is owned by `coreutils-from-uutils` but is a symlink to `gnurm`, which is GNU coreutils 9.7 (`gnu-coreutils`); `mktemp` is the Rust one. So `rm` here is GNU `rm`, which #96's QC already saw stay silent. In an issue container's terminal, run:

```
rm --version | head -1
rm -f -- ""; echo "rc=$?"
```

**Why it matters:** the output is what `/codeo:implement` records on #107 for criterion 8. Whatever it shows, the plan guards the trap so it never runs `rm` with an empty operand; if `rm` complains, the CHANGELOG bullet also says a stray line on every start is fixed.

**Answer:**

### Q3 — #70 overlaps this plan on `CHANGELOG.md`, `.devcontainer/README.md` and `glob:tests/**`: proceed, sequence or re-scope?

#70 is on branch `feat/guard-home-only-skills-against`, assignee kbajpai, at step `qc` (working). Its footprint lists `CHANGELOG.md`, `.devcontainer/README.md` and `tests/**`. This plan changes `CHANGELOG.md` (a new bullet, and the #96 bullet reworded), `.devcontainer/README.md` (the `core.fileMode` bullet under *What the start script does*) and, under `glob:tests/**`, `tests/devcontainer.test.sh` and `tests/codeo-root.test.sh`. #70's branch has changed neither of those two test files so far; in the README it adds text about `role.sh`.

**Why it matters:** sequencing adds a `sequenced:` line and this workflow waits for #70 to merge before `/codeo:implement`; proceeding means whichever merges second resolves a CHANGELOG conflict (two bullets under `## Unreleased`) and possibly a README one.
**Options:** proceed and coordinate (recommended: different bullets, different README lines, different test files) · sequence after #70 · re-scope.

**Answer:**

### Q4 — #71 overlaps this plan on `CHANGELOG.md`: proceed, sequence or re-scope?

#71 is on branch `feat/file-new-issues-straight-board`, assignee kbajpai, at step `plan` (working). Its footprint lists `CHANGELOG.md`; nothing else of it overlaps. This plan adds one bullet under `## Unreleased` and rewords the #96 bullet.

**Why it matters:** as Q3: a `sequenced:` line and a wait, or a possible conflict between two new bullets for whichever merges second.
**Options:** proceed and coordinate (recommended) · sequence after #71 · re-scope.

**Answer:**

## Notes

Decisions already made from the issue and the code; they will appear in the draft for review.

- **Shape.** One plan under `docs/plans/`, one pull request, no reference doc. No overlay for `plan-shape`, `proof-of-done` or `wiki-rules` (exit 3), so the generic shapes apply. Suite: `shell` (`bash tests/run.sh`, no `filter`); each task's proof is the test file it touches, run whole.
- **F16.** The changelog test searches the whole of `CHANGELOG.md` for the `(#52)` bullet and `my project`, not one section.
- **F3.** The script remembers whether the `safe.directory` entry existed or the add succeeded, and the bind-mount TODO carries "git is already told to trust the clone" only then. The test makes the add fail with a stub `git` first on `PATH`. That this TODO never clears under rootless Docker is not in the issue and stays as it is.
- **F17.** `mktemp`'s stderr is captured into `list_err` (and never into `modes_list`, which the trap removes). The test puts a stub `mktemp` on `PATH` that fails only for `modes.XXXXXX`.
- **F7.** `codeo-root.sh` prints the two fields raw, joined by a tab, in place of `@tsv`, so a backslash is compared as written. An empty or `false` `projectPath` stays "no `projectPath`" (eligible only as the fallback), and the header comment says so. Tests go in `tests/codeo-root.test.sh`. A path holding a tab or newline is still not supported; the header says that too.
- **F14.** By construction, with no change to the script: the case's own stub `stat` appends the next piece of the host file on each settle-stamp read, so no two consecutive reads match until the email is written. No `sleep` remains in the case. Rejected: a settle-interval variable only tests would set; 20 runs under `nice`, which shows little.
- **F5, F6, F10.** F5 counts occurrences (`grep -o … | wc -l`). F6 asserts that `.vscode` does not exist after the failure, which fails if the script writes anything before it has a name. F10: the stub `claude` drops a marker file in its working directory and the case asserts none is in the clone. Each task names the mutation that must turn it red.
- **F13.** The interrupt case runs inside `{ …; } 2>/dev/null`, which swallows bash's `Terminated` job message (checked in a scratch script: the message goes, the exit status stays 143).
- **F15.** The trap becomes `[[ -z ${modes_list:-} ]] || rm -f -- "$modes_list"`; a test with a stub `rm` sees no call with an empty operand. See Q2 for the check itself.
- **F18.** `shellcheck --include=SC2016 tests/devcontainer.test.sh` reports lines 82, 792 and 2195 today; line 82 is the one #96 introduced and the one the issue names. The task fixes 82 only.
- **F11, F12.** Text only: the #96 bullet names `docs/release-checklist.md` step 8 and the issues it closed, and says `start_trusts_the_clone_once` pins existing behaviour; the test header names `codeo-gh` and `codeo-git`.
- **Documentation moved.** `.devcontainer/README.md`, the `core.fileMode` bullet (per Q1), and `CHANGELOG.md`. No page under `docs/` changes.
- **Other workflows.** #104 (`feat/publish-live-session-signal-so`) is at `init`: it has no footprint yet and has changed no file, so nothing can be compared. #100 (the release the first item would break) is not in flight.
- No invariants document, no shared environment and no `wiki` module are configured; `resources` is empty, so `exclusive:` is `none`.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-15 — Q1-Q4 raised · cost: 3m · fable-5-2 106k in + 1M cached / 15k out
