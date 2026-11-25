# Issue #179 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/179 |
| Branch | `docs/179-close-171-leftovers-readme-wording` |
| Updated | 2026-11-25 |

## Where this stands

Planned: the plan is approved and saved at `docs/plans/2026-11-25-close-171-leftovers-179.md` (unstaged). Q1-Q7 are answered, `overlap.sh` prints nothing and no lock is needed. Next step: review and commit the plan, then `/codeo:implement`.

What I found (read at `92bbe45`):

- **Six of the nine items need no decision.** They are wording or a test edit whose content the code already fixes:
  - **H2**, `README.md:27`: step 6 says to merge the pull request and then run `/codeo:close` again, which is what finishes the workflow (as `README.md:302-304` already says).
  - **H3**, `README.md:429`: the lock entry splits the `lock: TODO` lines of `scripts/lock.sh` into those `/codeo:init #<N>` fixes (`no single init.md names branch …`, `#<N> is stashed or abandoned: no lock taken`) and those that say to reconcile by hand and re-run (`local <branch> holds commits … lacks`, `… have diverged`), which `/codeo:init` does not fix.
  - **H4**, `tests/readme.test.sh` `slugs()`: a second and third heading with the same text get `-1` and `-2`, as GitHub does.
  - **H5**, the same file's header: it names `docs/plans/` and `.codeo/config.json` as paths that resolve only because codeo uses itself.
  - **H6**, `docs/updating.md` "Updating superpowers": one sentence, restart every open Claude Code session after the update.
  - **Skill count**, `docs/handoff.md:3`: "Seven pipeline skills" becomes "Six", the count `docs/skills.md:5` and `README.md:596` give (`issue`, `init`, `plan`, `implement`, `qc`, `close`).
- **Three items carry a choice:** where the role-guard page goes and how much it promises (Q1, Q2), how "Setting a project up" is repaired (Q3), and where the two non-doctor entries go (Q4).
- **No Markdown renderer is installed here** (no `cmark`, `pandoc`, `python3` or `node`), so "renders as intended in a strict Markdown renderer" is proved by a structural check in `tests/readme.test.sh`, not by rendering. Q3's options differ in what that check is.
- **`.devcontainer/scripts/role.sh` is not standalone.** It calls `container-name.sh` beside it, reads `baseBranch` and `codename` from `.codeo/config.json`, and assumes the `<codename>-home` and `<codename>-<N>` folder names. `tests/role.test.sh` covers it in this repository's layout only. That bears on Q2.
- **In flight:** #173 (`qc`, sent back to plan) and #176 (`implement`) both change `CHANGELOG.md` and `.devcontainer/README.md`; #177 is at `init` with no footprint and no changed files, so there is nothing of its to compare yet. This plan touches neither file (see my calls), so I expect no overlap; `overlap.sh` decides once the footprint is committed.

My calls, stated so they can be corrected (not questions):

- **One plan under `docs/plans/`, one pull request, no reference doc.** No `engineering` skill applies: there is no component or technology choice.
- **Tests first.** Each README or docs fix that a check can pin gets its check in `tests/readme.test.sh` before the wording changes: step 6 names `/codeo:close` again, the lock entry names both groups, "Updating superpowers" says restart, the two skill counts agree, the adoption section exists and is linked. H4 is pinned by a self-check in the same file that feeds `slugs` a scratch file with a repeated heading and expects `x`, `x-1`, `x-2`.
- **No `CHANGELOG.md` line.** The `## Unreleased` entry from #171 already describes the README; these are corrections to it. That also keeps this branch out of the file #173 and #176 both change.
- **`.devcontainer/README.md` is not edited.** The adoption text links to its *Roles and the guard* section; it does not move or change it.
- **Proof of done** is `bash tests/run.sh readme` per task and `bash tests/run.sh` at the end, the second also in a clean worktree (`git worktree add`), which is the last acceptance criterion. The `shell` suite has no `filter`, so a pattern argument to `tests/run.sh` is the single-file form, as in the #170 plan.

## Questions

### Q1 — Which page tells another project how to adopt the role guard?

**Why it matters:** the criterion is "a page tells another project how". Today three pages each hold a piece: `docs/home-checkout.md` (*The guard*: what codeo's own guard does), `.devcontainer/README.md` (*Roles and the guard*: the roles in full) and `docs/extension-points.md` (the eight `<skill>/role-guard` points, each with a `scripts/role-check.sh` example). None says "to add a guard to your project, do this".
**Options:**
- **A — a new section `## Adopting the guard in your project` in `docs/home-checkout.md`, after *The guard* (my pick).** It is where the README's role-guard troubleshooting entry and *Running on the host* already send a reader, and `tests/readme.test.sh` already checks that page's links and paths. `docs/extension-points.md` (*Adding a project overlay*) and the README entry each gain one link to it.
- **B — a section in `docs/extension-points.md`, before *The points*.** It sits with the overlay mechanics, but that page is a reference for overlay authors and is outside the readme test's pages, so its links are unchecked unless the test grows a page.
- **C — a new page `docs/role-guard.md`.** Cleanest to link to, but it splits the guard across four pages and adds a row to *More documentation*.

**Answer:**
A — a new section in `docs/home-checkout.md`, after *The guard*. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

### Q2 — How much does the adoption text promise?

**Why it matters:** `role.sh` is this repository's script, tested only in its own layout, and it needs `container-name.sh` and the `<codename>-home` naming. Saying "copy these files" makes that a supported path someone can report bugs against; saying only what a guard must do leaves the script to the project.
**Options:**
- **A — the contract, with codeo's own guard as the worked example (my pick).** The section says: add a `## role-guard` section to `.codeo/overlays/<skill>.md` for each of the eight guarded skills; the section's text runs the project's check and tells the skill what each exit means (0 go on, 1 print the one line and stop, anything else report and go on); the check is any script the project writes; `/codeo:doctor`'s `overlays` check confirms the section names. It then names codeo's own `.codeo/overlays/plan.md` and `.devcontainer/scripts/role.sh` as an example to read, and says plainly that the script assumes codeo's folder names and is not shipped for other projects.
- **B — A, plus a copy recipe.** It lists the files to copy (`role.sh`, `container-name.sh`, the eight overlay sections), what to set (`codename`, `baseBranch`) and the folder names it then expects. More useful on day one, but it documents a path no test runs outside this repository.

**Answer:**
A — the contract, with codeo's own guard as the worked example. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

### Q3 — "Setting a project up": how are the three steps repaired?

**Why it matters:** today each numbered step is followed by a code fence at column 0, which ends the list; step 2 and step 3 then start new lists, and the paragraphs indented three spaces after a fence belong to nothing. GitHub shows it acceptably; a strict renderer can restart the numbering or indent unevenly. The two repairs differ in what else they touch.
**Options:**
- **A — turn the three steps into `###` headings, as *Your first workflow* does (my pick).** `### 1. Run /codeo:setup`, `### 2. Edit .codeo/config.json`, `### 3. Run /codeo:doctor`, each followed by ordinary paragraphs and column-0 fences. Nothing is nested, so every renderer agrees. The check: the section has those three `###` headings before *Running on the host*, and no line in it starts with spaces followed by text outside a fence. No test's fence detection changes.
- **B — keep the numbered list and indent each fence and continuation paragraph three spaces under its item.** This is the standard form and keeps the look. But `tests/readme.test.sh` (`prose`) and four `awk` filters in `tests/install.test.sh` detect a fence only at column 0 (`/^```/`), so an indented fence's contents would be read as prose; both tests would need their fence detection widened in the same change.

**Answer:**
A — `###` headings for the three steps. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

### Q4 — The two entries that are not doctor checks: where do they go?

**Why it matters:** `its source doesn't match its extraKnownMarketplaces entry` and *A hand-edited `ref` does not take effect* sit under *Checks from /codeo:doctor*, whose intro says each entry is one doctor check. Both are `claude plugin` and `install.sh` problems.
**Options:**
- **A — a third group with its own heading, `### Installing and the pin`, after *Checks from /codeo:doctor* (my pick).** The Troubleshooting intro says three groups; the doctor intro stays true as written. A new check pins it: every bold lead under *Checks from /codeo:doctor* is one of the check names `scripts/doctor.sh` prints, and the two entries sit under the new heading. The `##` headings do not change, so the `sections` pins hold.
- **B — leave them where they are, and reword the doctor intro** to say the last two entries are not doctor checks, labelling each. One heading fewer, but the group's name stays wrong for two of its entries.

**Answer:**
A — a third group with its own heading, `### Installing and the pin`. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

### Q5 — Overlap with #177 on `glob:docs/handoff.md`: proceed, sequence, or re-scope?

**Why it matters:** `overlap.sh` reads this plan's footprint against every other pushed branch. #177 (`docs/177-close-163-166-168-leftovers`, assignee kbajpai, step `plan`, waiting for `/codeo:implement`) lists `glob:docs/handoff.md` in its footprint, and a second branch editing the same file merges with conflicts or silently reverts a line. #177 edits `docs/handoff.md` only "where it states the old behaviour" (its plan's *Documentation pages the plan changes*); this plan changes line 3 alone.
**Options:**
- **A — proceed and coordinate (my pick).** Different passages: this plan edits line 3 ("Six pipeline skills"); #177 edits the passages about close and cleanup behaviour. Git merges both without a conflict.
- **B — sequence after #177.** This plan waits until #177 merges, then is rebased; `sequenced:` in the footprint then reads `177`.
- **C — re-scope.** Drop the one-line skill-count fix from this plan and hand it to #177's author. That leaves criterion 6 of #179 unmet here.

**Answer:**
A — proceed and coordinate. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

### Q6 — Overlap with #177 on `glob:docs/home-checkout.md`: proceed, sequence, or re-scope?

**Why it matters:** `overlap.sh` reads this plan's footprint against every other pushed branch. #177 (`docs/177-close-163-166-168-leftovers`, assignee kbajpai, step `plan`, waiting for `/codeo:implement`) lists `glob:docs/home-checkout.md` in its footprint, and a second branch editing the same file merges with conflicts or silently reverts a line. #177 edits `docs/home-checkout.md` lines 9 and 66 (the `jq` and `live-signal.sh` sentence, and the sandbox-versus-container sentence); this plan adds a new section after *The guard*, below both.
**Options:**
- **A — proceed and coordinate (my pick).** Different regions: #177 edits *The home checkout*; this plan adds `## Adopting the guard in your project` after *The guard*. Whichever merges second rebases without touching the other's lines.
- **B — sequence after #177.** This plan waits until #177 merges, then is rebased; `sequenced:` in the footprint then reads `177`.
- **C — re-scope.** Move the adoption section to `docs/extension-points.md` (Q1 option B), which #177 does not touch. That moves it out of the page `tests/readme.test.sh` already checks.

**Answer:**
A — proceed and coordinate. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

### Q7 — Overlap with #177 on `glob:tests/readme.test.sh`: proceed, sequence, or re-scope?

**Why it matters:** `overlap.sh` reads this plan's footprint against every other pushed branch. #177 (`docs/177-close-163-166-168-leftovers`, assignee kbajpai, step `plan`, waiting for `/codeo:implement`) lists `glob:tests/readme.test.sh` in its footprint, and a second branch editing the same file merges with conflicts or silently reverts a line. #177 adds pins to `tests/readme.test.sh` for its home-checkout wording (its plan: "Each wording fix gets a pin written first"); this plan adds seven checks and changes `slugs()` and the header.
**Options:**
- **A — proceed and coordinate (my pick).** Different hunks: this plan changes `slugs()`, the header comment and appends checks after `host-command`; #177's pins land in the same block, so the second to merge has a trivial conflict at the end of the file, resolved by keeping both.
- **B — sequence after #177.** This plan waits until #177 merges, then is rebased; `sequenced:` in the footprint then reads `177`.
- **C — re-scope.** Split this plan's test changes out of the file, which loses the tests-first order Task 1 relies on.

**Answer:**
A — proceed and coordinate. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

## Notes

None.


## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-25-close-171-leftovers-179.md` (approved 2026-11-25, unstaged) |
| Shape | one plan under `docs/plans/`, four tasks, tests first; no reference doc, no `engineering` skill (no component or technology choice) |

**Decisions.**
- **Q1:** the role-guard adoption text is a new `## Adopting the guard in your project` in `docs/home-checkout.md`, after *The guard*, linked from the README's role-guard entry and from `docs/extension-points.md`.
- **Q2:** it states the contract (a `## role-guard` section per guarded skill, the three exits, `/codeo:doctor`'s `overlays` check) with codeo's own overlay and `role.sh` as the example, and says `role.sh` is not shipped for other projects.
- **Q3:** "Setting a project up" becomes three `###` steps with fences at column 0; pinned by a structural check, since no Markdown renderer is installed.
- **Q4:** the two non-doctor entries move under a new `### Installing and the pin`; the doctor group's intro stays true.
- **Q5-Q7:** proceed and coordinate with #177 on `docs/handoff.md`, `docs/home-checkout.md` and `tests/readme.test.sh`; the edits are in different passages.
- Also decided: no `CHANGELOG.md` entry, `.devcontainer/README.md` linked and not edited, `slugs()` fixed with a self-check.

**Rejected:** the adoption text in `docs/extension-points.md` or a new page (Q1); a copy recipe for `role.sh` (Q2); indenting fences under a numbered list, which would widen fence detection in two tests (Q3); rewording the doctor intro instead of a third group (Q4); sequencing after, or splitting from, #177 (Q5-Q7).

**Documentation pages the plan changes:** `README.md`, `docs/home-checkout.md`, `docs/extension-points.md`, `docs/updating.md`, `docs/handoff.md`; guarded by `tests/readme.test.sh`. No wiki module. No intake question was resolved by this skill; no issue was filed; the `engineering` skills were not used.

### Footprint
files: tests/readme.test.sh, README.md, docs/home-checkout.md, docs/extension-points.md, docs/updating.md, docs/handoff.md, docs/plans/2026-11-25-close-171-leftovers-179.md, .codeo/179/**
wiki: none
exclusive: none
sequenced: none

## Log

- 2026-11-25 — explored at `92bbe45`; Q1-Q4 raised · cost: 2m · fable-5-2 103k in + 728k cached / 12k out
- 2026-11-25 — Q1-Q4 answered (the picks); draft written to .codeo/179/plan-draft.md, awaiting approval · cost: 13m · fable-5-2 108k in + 990k cached / 13k out · sonnet-5-5 109k in + 156k cached / 9k out
- 2026-11-25 — plan approved and written; footprint committed; overlap with #177 raised as Q5-Q7 · cost: 34m · fable-5-2 108k in + 990k cached / 13k out · sonnet-5-5 122k in + 1.2M cached / 14k out
- 2026-11-25 — planned: docs/plans/2026-11-25-close-171-leftovers-179.md · cost: 44m · fable-5-2 108k in + 990k cached / 13k out · sonnet-5-5 123k in + 1.6M cached / 15k out
