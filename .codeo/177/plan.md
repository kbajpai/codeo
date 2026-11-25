# Issue #177 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/177 |
| Branch | `docs/177-close-163-166-168-leftovers` |
| Updated | 2026-11-25 |

## Where this stands

Round 1. The intake, the three source reports (`.codeo/done/{163,166,168}/qc.md`) and the code behind each finding are read. Q1-Q6 are open; nothing is drafted until they are answered. Q1-Q4 decide what gets written, Q5-Q6 are overlaps with #173 and #176.

What exploration found:

- **The two README sentences moved.** #171 restructured the README after the findings were written. The sentence the issue cites as `README.md:256` is now `docs/home-checkout.md:66`, and `README.md:199` is now `docs/home-checkout.md:9`. The plan edits them there; criterion 1 is read as naming the text, not the old path.
- **`docs/home-checkout.md:66` is half fixed already.** It now says `codeo-container.sh` refuses and that an existing sandbox is reused. What it still lacks: creating a sandbox while a container `codeo-<N>` exists on the host is asked about, not refused (`.sbx/codeo-sandbox.sh:43-52` passes `--local`, and `--yes` answers it). `CHANGELOG.md:24` ("or a local container of its name, is listed and asked about") is true of the sandbox script only; the plan gives it the same clause.
- **`docs/home-checkout.md:9`** still says `/codeo:doctor` reports a missing `jq` first (`scripts/doctor.sh:25-30` reports `config` first, `deps` later) and that `live-signal.sh` exits 0 silently, without saying no signal is published.
- **Line numbers in `CHANGELOG.md` moved** when the v1.0.9 section gained its heading: the issue's `:11` is `:19`, `:20` is `:28`. Both are in the released v1.0.9 section (Q4).
- **#168's `(unstaged)` is at `plan.md:11` and `:54`**, not `:62`; `init.md:26` is in that file's `## Outcome` (Q1).
- **Tests pin some of this wording**: `tests/close-skill.test.sh:229-233` pins the literal `git push origin --delete codeo-live/<issue>/<machine>` (Q2), `tests/close-removal.test.sh:20` and `tests/cleanup-skill.test.sh` pin overlay and skill needles, `tests/readme.test.sh` guards `docs/home-checkout.md`. Each wording fix gets a pin written first, as #163 and #166 did.

My calls, open to correction: one pull request; a bullet under `## Unreleased`; no release; a plan under `docs/plans/` and no reference doc; every task runs in this container, so none is marked for your host unless Q4 adds one.

## Questions

### Q1 — #168's stale lines: mark them historical with a note, or rewrite them?

The lines are `.codeo/done/168/plan.md:11` (`## Where this stands`: "(unstaged)"), `plan.md:54` (`## Outcome`: "(unstaged, approved 2026-11-25)") and `init.md:26` (`## Outcome`: #161 "sit under `## Unreleased`").

**Why it matters:** the dossier protocol says an outcome is written once and a skill writes only its own file, so rewriting a closed issue's outcome is the edit the protocol avoids; a note leaves the record as written but is one more line to read. It decides whether the task edits three lines or adds two notes.
**Options:**
- **A — note only (my pick).** Each file gains one dated line under `## Notes`: the plan was committed in `d71d60f`, and #161 had no bullet under `## Unreleased`; lines above are as written at the time. Nothing already written changes.
- **B — rewrite in place.** The three lines are corrected where they stand.
- **C — mixed.** `plan.md:11` is rewritten (a status line, meant to be rewritten each round); the two `## Outcome` lines get the note.

**Answer:**

### Q2 — How far should `/codeo:close` step 17 go to make the `<machine>` command usable?

Today step 17 prints `git push origin --delete codeo-live/<issue>/<machine>` with the issue filled in and `<machine>` as written, and says the branch "stays on `origin`" whether or not a beat ever pushed. The close runs inside the hosted session, so it can look.

**Why it matters:** A is text only. B and C make step 17 run a command, change the sentence the tests pin (`tests/close-skill.test.sh:229-233`), and change this project's close overlay with it. Only C is true on every path.
**Options:**
- **A — name the file.** Step 17 says the label is in `<git dir>/codeo-live-machine` (`git rev-parse --git-path codeo-live-machine`) and that the branch exists only when a beat pushed. You still assemble the command yourself. Wrong when `CODEO_MACHINE` is set (never saved to the file).
- **B — fill it in from the file.** Step 17 reads the label and prints the full command; with no file it says no branch was published. Same `CODEO_MACHINE` gap, and a failed push leaves a file with no branch.
- **C — ask origin (my pick).** Step 17 runs `git ls-remote --heads origin 'codeo-live/<N>/*'` and prints one `git push origin --delete <exact name>` per branch found, or says none is on origin; when the read fails it falls back to A's sentence. Covers `CODEO_MACHINE`, a failed push and a second machine. No change to `scripts/live.sh`.

**Answer:**

### Q3 — Which date does the changelog heading carry?

`docs/release-checklist.md` step 6 says `## vX.Y.Z — YYYY-MM-DD` and names neither the day nor the timezone. v1.0.9 used the UTC date of the day the release pull request opened (2026-11-25; 2026-11-24 local, -0500).

**Why it matters:** it is the one sentence the task adds to the checklist, and the checklist is yours to follow.
**Options:** the UTC date the release pull request opens (my pick: it is what v1.0.9 did, and it matches GitHub's `createdAt`) · the UTC date the tag is pushed · your local date, with the day named.

**Answer:**

### Q4 — The corrected changelog lines are in the released v1.0.9 section. What about the v1.0.9 GitHub Release?

Criterion 3 changes `CHANGELOG.md:28` ("an invented example issue") and removes the repeated `name`-proof clause from `:19` or `:20`; the plan also touches `:24` (above). The Release's notes were made from that section, so after the merge the two differ in those sentences.

**Why it matters:** B adds a task you run on the host after the merge (the release checklist says an agent does none of it), and I would then need to know which shell you type in; A adds nothing.
**Options:**
- **A — leave the Release as published (my pick).** It is a record of what shipped; the changelog carries the correction, and the plan says so in one line.
- **B — re-sync it.** A last task, marked `Runs on: the engineer's host`: `gh release edit v1.0.9 --notes-file <the section>` after the merge.

**Answer:**

### Q5 — Overlap with #173 on `CHANGELOG.md` and `docs/release-checklist.md`

#173, branch `docs/173-close-161-leftovers-release-checklist`, assignee kbajpai, step `qc` (round 1 sent it back to `/codeo:plan`; it waits on its `issue.md` Q2-Q3). Its footprint and its changed files both list `CHANGELOG.md` and `docs/release-checklist.md`. This plan adds one sentence to step 6 of `docs/release-checklist.md` (Q3) and, in `CHANGELOG.md`, edits three lines of the v1.0.9 section and adds one `## Unreleased` bullet.

**Why it matters:** *sequence after #173* holds this plan's hand-off until #173 merges; *proceed and coordinate* means whoever merges second rebases the two files and keeps both sides; *re-scope* drops the timezone sentence here and leaves it to #173.
**Options:** proceed and coordinate (my pick: the edits are single sentences and bullets, and #173 is back at plan) · sequence after #173 · re-scope.

**Answer:**

### Q6 — Overlap with #176 on `CHANGELOG.md`

#176, branch `feat/176-support-sbx-issue-sandbox-macos`, assignee kbajpai, step `implement` (waits for `/codeo:qc`). Its footprint and its changed files list `CHANGELOG.md`. It also lists `.sbx/codeo-sandbox.sh`, which this plan reads and does not edit; if #176 changes when the sandbox script asks or refuses, the `docs/home-checkout.md:66` clause is checked against it at rebase.

**Why it matters:** as Q5: sequencing holds the hand-off until #176 merges; coordinating means a rebase of `CHANGELOG.md` by whoever merges second.
**Options:** proceed and coordinate (my pick) · sequence after #176 · re-scope.

**Answer:**

## Notes

- #179 (`docs/179-close-171-leftovers-readme-wording`, step `init`) has no footprint yet and has changed nothing, so there is nothing to compare; its title suggests README wording, and it may reach `docs/home-checkout.md`. `overlap.sh` is run again on the written footprint after approval.
- No invariants document, shared environment, wiki module or exclusive resource is configured. The `plan` overlay sets only `role-guard`; `plan-shape`, `proof-of-done` and `wiki-rules` are unset, so the plan follows the recent plans under `docs/plans/` and each task's proof is the `shell` suite's whole `test` command, `bash tests/run.sh` (the suite has no `filter`).
- Out of scope, as the issue says: #168's grep-count deviation (F3), and any redesign of `/codeo:cleanup` or the live signal. Q2's option C adds no code to `scripts/live.sh`.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-25 — Q1-Q6 raised · cost: 2m · fable-5-2 103k in + 714k cached / 9k out
