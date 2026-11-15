# Issue #70 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/70 |
| Branch | `feat/guard-home-only-skills-against` |
| Updated | 2026-11-15 |

## Where this stands

Round 4, done. QC round 3's two blocking findings (H1, H2) and H3, H4, H6 are fixed and committed (`310dccb` to `3256788`), reviewed, and `bash tests/run.sh` prints `all cases passed`. Nothing is open. The next step is `/codeo:qc`.

## Questions

### Q1 — Overlap with #71 on `CHANGELOG.md`, `docs/handoff.md`, `docs/skills.md`, `docs/skills-inventory.md`, `skills/issue/SKILL.md`, `skills/triage/SKILL.md`, `tests/inventory.test.sh`, `tests/fixtures/skills-inventory.rules.sha256` and more: proceed and coordinate, sequence after #71, or re-scope?

**Why it matters:** #71 (branch `feat/file-new-issues-straight-board`, assignee kbajpai, step `plan`, working) plans to change the same files, and two of them are pinned: both branches add rule bullets to `docs/skills-inventory.md`, so both change `tests/fixtures/skills-inventory.rules.sha256` and the counts in `tests/inventory.test.sh`, and whichever merges second must re-run `bash tests/inventory.test.sh --update` and recount, not just resolve a text conflict. *Proceed* means the later branch merges `origin/main`, keeps both sets of bullets and regenerates the fixture; *sequence* means this branch merges first (it is already built) and #71 rebases; *re-scope* has no sensible form here, since every file is needed. The printed overlaps, verbatim: `CHANGELOG.md`, `docs/handoff.md`, `docs/skills-inventory.md`, `docs/skills.md`, `glob:CHANGELOG.md`, `glob:docs/handoff.md`, `glob:docs/skills-inventory.md`, `glob:docs/skills.md`, `glob:skills/issue/SKILL.md`, `glob:skills/triage/SKILL.md`, `glob:tests/board.test.sh`, `glob:tests/closing-exits.test.sh`, `glob:tests/fixtures/skills-inventory.rules.sha256`, `glob:tests/inventory.test.sh`, `glob:tests/issue-skill.test.sh`, `glob:tests/triage-skill.test.sh`, `skills/issue/SKILL.md`, `skills/triage/SKILL.md`, `tests/fixtures/skills-inventory.rules.sha256`, `tests/inventory.test.sh`.
**Options:** proceed and coordinate · sequence after #71 (recommended: this branch is built and reviewed; #71 is still at `plan`) · re-scope.

**Answer:**
Sequence, as the question defines it: this branch merges first and #71 rebases onto it, regenerating the inventory fixture. Go with the recommendation (engineer, in the conversation, 2026-11-15).

### Q2 — Overlap with #96 on `.devcontainer/README.md` and `CHANGELOG.md`: proceed and coordinate, sequence after #96, or re-scope?

**Why it matters:** #96 (branch `feat/dev-container-follow-ups-40`, assignee kbajpai, step `plan`, working) plans to change `.devcontainer/README.md` and `CHANGELOG.md`, and its footprint also names `tests/devcontainer.test.sh`, `tests/codeo-root.test.sh` and `tests/env.test.sh`. Here the README gains two sections and a changed table row, and `CHANGELOG.md` one bullet. *Proceed* means a text merge in each; *sequence* means one waits. This branch does not touch `devcontainer.json`, any `.devcontainer` start script or those tests. The printed overlaps, verbatim: `.devcontainer/README.md`, `CHANGELOG.md`, `glob:.devcontainer/README.md`, `glob:CHANGELOG.md`, `glob:tests/codeo-root.test.sh`, `glob:tests/devcontainer.test.sh`, `glob:tests/env.test.sh`.
**Options:** proceed and coordinate (recommended: the README edits are in separate sections) · sequence after #96 · re-scope.

**Answer:**
Proceed and coordinate. Go with the recommendation (engineer, in the conversation, 2026-11-15).

### Q3 — Overlap with #97 on `docs/skills.md`, `docs/handoff.md`, `skills/close/SKILL.md`, `skills/plan/SKILL.md`, `skills/triage/SKILL.md`, `CHANGELOG.md` and more: proceed and coordinate, sequence after #97, or re-scope?

**Why it matters:** #97 (branch `docs/docs-skill-wording-test-guard`, assignee kbajpai, step `init`, working: it has no plan of its own yet, so only its footprint is known) lists `docs/skills.md` and `tests/skills-doc.test.sh`, which pin the exact shape of `docs/skills.md` that this branch also changes (a new `## cleanup` section, a `role-guard` bullet in every skill's *Extension points*). A wording guard added there could fail on text this branch adds, or the reverse. *Proceed* means whichever merges second reruns `bash tests/run.sh` and adjusts; *sequence* means this branch goes first. The printed overlaps, verbatim: `CHANGELOG.md`, `docs/handoff.md`, `docs/skills.md`, `glob:CHANGELOG.md`, `glob:docs/handoff.md`, `glob:docs/skills.md`, `glob:skills/close/SKILL.md`, `glob:skills/plan/SKILL.md`, `glob:skills/triage/SKILL.md`, `glob:tests/board.test.sh`, `glob:tests/close-skill.test.sh`, `glob:tests/closing-exits.test.sh`, `glob:tests/overlap.test.sh`, `glob:tests/plan-skill.test.sh`, `glob:tests/qc-verdict.test.sh`, `glob:tests/skills-doc.test.sh`, `skills/close/SKILL.md`, `skills/plan/SKILL.md`, `skills/triage/SKILL.md`, `tests/plan-skill.test.sh`.
**Options:** sequence after #97 is not recommended (it has not planned yet) · proceed and coordinate (recommended: this branch merges first, #97 plans against `origin/main` and sees the new text) · re-scope.

**Answer:**
Proceed and coordinate; this branch merges first. Go with the recommendation (engineer, in the conversation, 2026-11-15).

### Q4 — Overlap with #98 on `skills/plan/SKILL.md`, `tests/plan-skill.test.sh` and `CHANGELOG.md`: proceed and coordinate, sequence after #98, or re-scope?

**Why it matters:** #98 (branch `fix/fix-sync-main-sh-exiting`, assignee kbajpai, step `qc`, working) has already changed `skills/plan/SKILL.md`, `tests/plan-skill.test.sh` and `CHANGELOG.md` on its branch, and `scripts/sync-main.sh` and `tests/sync-main.test.sh` too. This branch adds a `role-guard` paragraph and a refused-call sentence to `skills/plan/SKILL.md`, and two assertions to `tests/plan-skill.test.sh`. #98 is at `qc`, so it is likely to merge first; *proceed* then means this branch merges `origin/main` (as `/codeo:implement` does at the start of every round) and keeps both. The printed overlaps, verbatim: `CHANGELOG.md`, `glob:CHANGELOG.md`, `glob:skills/plan/SKILL.md`, `glob:tests/plan-skill.test.sh`, `glob:tests/sync-main.test.sh`, `skills/plan/SKILL.md`, `tests/plan-skill.test.sh`, `tests/sync-main.test.sh`. (`tests/sync-main.test.sh` appears only because #98's footprint names it as a glob; this branch does not touch it.)
**Options:** proceed and coordinate (recommended: #98 is nearly through and the later branch merges `origin/main`) · sequence after #98 · re-scope.

**Answer:**
Proceed and coordinate. Go with the recommendation (engineer, in the conversation, 2026-11-15).

## Notes

**What was built**, one commit per plan task (task numbers as in the plan): Task 1 `7840b47` the role script and its test · Tasks 2, 3 and 5 `e46fa9e`, `252c97e` the `role-guard` point, rule and step in seven skills, their overlays and the pin test · Task 4 `35a2f43` callers record a finding the guard refuses to file · Task 6 `27c6f11`, `ea6eb62` `scripts/cleanup.sh` (plus a fix for a fail-open branch proof) · Task 7 `9323ef4` the `/codeo:cleanup` skill, its overlay point and inventory section · Task 8 `ba0bb09`, `1103fb7` `/codeo:close`'s host removal commands (plus a fix: the overlay path now carries "not inside this container" and `git status` first) · Task 9 `b22a7a7` documentation · final-review fix wave `5976610` (stale refusals say the issue is finished; `cleanup.sh` refuses a clone whose fetch refspec does not cover every branch; literal-safe name replacement). Task 10 was run by hand: the suite, `doctor.sh` (all ok), no change to `.devcontainer/Dockerfile` or `devcontainer.json`, and `role.sh` in this container (`issue:70`; `--check init` exits 1; with `CLAUDE_CODE_REMOTE=true` it exits 0).

**Deviations from the plan.**
1. `scripts/github.sh` gained a verb `pr get <n>` (state, `merged_at`, `head_ref`) and `tests/github.test.sh` one case. The plan assumed `pr view` returned those fields; it returns only the merge state. The engineer approved the new verb in the conversation. `overlap.sh --outside 70` prints `scripts/github.sh`: the plan's footprint does not list it.
2. Task 2's test was committed with Task 5's overlays, not with Task 3, and lists seven skills until Task 7 added `cleanup`, so that the suite is green at every commit.
3. Task 7 registers the overlay point `cleanup/removal-command` and its docs example uses a neutral command (`remove-container {name}`), so `docs/` names no container engine.
4. The overlays' `role-guard` text keeps "exit 2: report its `role:` line and go on": a fault in the project's own check disables the guard instead of blocking every skill. A stale container cannot reach exit 2. Ruled by the controller; the reviewer called it acceptable.

**Deferred minors** (not fixed, none blocks): `tests/role.test.sh` mode and thin matrix coverage; `-A3` window in the role-guard test; cleanup's issue-view failure reads as `failed issue`, and one unreadable PR aborts the whole report; no test for an invalid overlay regex or an `origin/HEAD` symref; skill description and `docs/skills.md` intro say "home container only" in generic text; the closing block's first step is "run the printed commands" even when every command is `-`; wording of the stale row and of the removal section in `.devcontainer/README.md` (partly fixed); `docs/skills-inventory.md` intro wording.

**Rulings taken while building** are in the controller's ledger, not repeated here; the one that changes behaviour is item 4 above.

## Outcome

2026-11-15

**Plan built:** `docs/plans/2026-11-15-guard-home-only-skills.md`, all ten tasks, one commit per task (a fix commit after a review where one was needed), `7840b47` to `5976610`; each task and the whole branch were reviewed. Overlaps raised at the hand-off (Q1-Q4, #71 #96 #97 #98) are answered: this branch merges first, the others proceed and coordinate.

**What was built.** `.devcontainer/scripts/role.sh` (roles `home`, `issue:<N>`, `stale:<N>`/`stale:?`, `mismatch:<N>:<folder>`, `unguarded`; `--check <skill>`); a `role-guard` extension point, rule and step in eight skills (`issue init triage cleanup plan implement qc close`) with this repository's overlays running `role.sh --check`; callers record a finding the guard refuses to file; `scripts/cleanup.sh` and the `/codeo:cleanup` skill with the overlay point `cleanup/removal-command`; `/codeo:close`'s final report carries the host removal commands through the overlay `close/host-workflow`; `github.sh pr get`.

**Documentation changed.** `.devcontainer/README.md`, `docs/skills.md`, `docs/extension-points.md`, `docs/skills-inventory.md`, `docs/handoff.md`, `README.md`, `CHANGELOG.md`. The plan named all of them; none was added.

**Build result.** The `shell` suite's `build` (`true`) ran ok; `bash tests/run.sh` prints `all cases passed` at `5976610` (full run, after the last fix); `bash scripts/doctor.sh` all ok; `git diff origin/main -- .devcontainer/Dockerfile .devcontainer/devcontainer.json` is empty.

**Deviations from the plan.**
1. `scripts/github.sh` gained `pr get <n>` (state, `merged_at`, `head_ref`) and `tests/github.test.sh` one case, because `pr view` prints only the merge state. Approved by the engineer in the conversation. The plan's footprint does not list `scripts/github.sh` (`overlap.sh --outside 70` prints it).
2. `tests/role-guard.test.sh` was committed with the overlays (Task 5), not with Task 3, and began with seven skills; Task 7 added `cleanup`: the suite is green at every commit.
3. The docs example for `cleanup/removal-command` is neutral (`remove-container {name}`), so `docs/` names no container engine.
4. Two reviewer findings changed the plan's text: the close overlay now carries "not inside this container" and `git status` first (the skill's default bullet is dead text when an overlay exists), and `cleanup.sh` dies unless the clone's fetch refspec covers every branch, since its branch and dossier proofs read the fetched refs.
5. The overlays' `role-guard` text keeps "exit 2: report its `role:` line and go on". A fault in the project's own check disables the guard instead of blocking every skill; a stale container cannot reach exit 2.

**Rulings taken while building** (subagent-driven execution; each with what it costs if wrong): (1) tasks 2, 3 and 5 ran as one dispatch with the pin test committed last, so the suite is never red at a commit: costs that three tasks were reviewed together. (2) The docs example for `cleanup/removal-command` is neutral: costs nothing. (3) Reviewers and the final whole-branch review ran on sonnet, not a stronger model, because codeo's subagent hook allows only the configured subagent model: costs a weaker review; `/codeo:qc` grades independently. (4) Task 10 (verification) ran inline. (5) Item 5 above. (6) `pr get` was added after the engineer's approval (item 1).

**Deferred minors**, none blocking: `tests/role.test.sh` mode 100644 and thin `--check` coverage for some roles; the role-guard test's `-A3` window; cleanup's issue-view failure reads as `failed issue` and one unreadable PR aborts the whole report; no test for an invalid overlay regex or an `origin/HEAD` symref; the skill description and `docs/skills.md` intro say "home container only" while the registry default is "runs wherever invoked"; the cleanup closing block's first step is "run the printed commands" even when every command is `-`; wording nits in `.devcontainer/README.md` and the inventory intro.

### Round 2 — 2026-11-15
(send-back from qc.md round 1)

**Plan built:** round 2 of `docs/plans/2026-11-15-guard-home-only-skills.md` (Tasks 11-16), commits `b40172e` to `0252bf7`, on top of a merge of `origin/main` (`be16d5b`, one conflict in `CHANGELOG.md` resolved by keeping both bullets: this branch's and #98's). Each task pair was reviewed; a closing review read the whole round.

**What was built, against QC round 1's findings.**
- F1, F7 (Task 11, `b40172e`): a finished close names the checkout its follow-up skills run in. Generic skill text: the finished closing block's first step is `/codeo:triage` "in the checkout the project's host workflow names for it, when it names one". This repository's close overlay applies only to `host: container`, says the container holds no lock now so `/codeo:triage` and `/codeo:cleanup` are refused there, names the home container as the first step, and says there is nothing to remove for any other host. `docs/extension-points.md` extended; `tests/close-removal.test.sh` and `tests/closing-exits.test.sh` pin it.
- F2 (Task 12, `fda7a3e`): the sentence in `skills/plan`, `skills/implement`, `skills/qc` and `docs/handoff.md` now names the form: a line under `## Notes` that promises the later work and carries no issue number, which is what `/codeo:triage` collects from an archived dossier.
- F4, F5, F13 (Task 13, `5f8255a`): the `github.sh` usage line lists `pr get`; `cleanup.sh` stops with `cleanup: could not read issue #<N>` (no result line, non-zero exit) when the issue cannot be read; the cleanup closing block says `/codeo:init #<M>`, `<M>` the next issue to start.
- F6, F10 (Task 14, `e9ed7b1`): the stale refusal says the workflow "has ended (finished, stashed or abandoned), or its start script took no lock" and, for a lock skill, to re-run `bash .devcontainer/scripts/devcontainer-start.sh` when it is still the issue's container; all eight overlays add "Any other exit (the script is missing, or failed): report what it printed and go on."; the `.devcontainer/README.md` `stale` row matches.
- F1, F8 (Task 15, `0252bf7`): `.devcontainer/README.md` says where the follow-up skills run after a close and that a container whose clone predates the guard is not guarded; the existing `## Unreleased` bullet in `CHANGELOG.md` is extended in place.
- F3 is settled by the plan's footprint (`scripts/github.sh` added). F9 (Podman), F11 (`CODEO_CLEANUP_REMOVAL`) and F12 (generic "home container" wording) were left, by the engineer's answer to plan Q7, in `qc.md` for `/codeo:triage`.

**Documentation changed.** `.devcontainer/README.md`, `docs/extension-points.md`, `docs/handoff.md`, `CHANGELOG.md`, as the plan's round 2 names.

**Build result.** The `shell` suite's `build` (`true`) ran ok; `bash tests/run.sh` prints `all cases passed` at `0252bf7` (3m17s); `bash scripts/doctor.sh` (this repository's) all ok, overlays ok with 11 sections in 8 files; `git diff origin/main -- .devcontainer/Dockerfile .devcontainer/devcontainer.json` is empty; `role.sh --check triage` in this container exits 1 with one line naming `issue:70`; `overlap.sh 70` and `overlap.sh --outside 70` print nothing; the branch contains `origin/main`.

**Deviations from the plan.** None beyond round 1's. One note for `/codeo:qc`: the installed, pinned plugin (v1.0.6) does not know the `<skill>/role-guard` or `cleanup/removal-command` points, so its own `doctor.sh` reports this repository's overlays as unknown sections and its `overlay.sh` exits 2 for them (the skills then "report and go on"): the guard takes effect in a project once it runs a plugin version that carries the new points. This repository's own scripts and tests do not have that limit.

**Rulings taken while building round 2** (each with what it costs if wrong): (1) the tasks ran as three dispatches (Tasks 11+12, 13+14, 15) with Task 16 inline, one commit per task and one review per dispatch: costs that tasks were reviewed in pairs. (2) Reviewers and the closing review ran on sonnet, not a stronger model, because codeo's subagent hook allows only the configured subagent model: costs a weaker review; `/codeo:qc` grades independently on opus. (3) The merge of `origin/main` kept both CHANGELOG bullets verbatim: costs nothing unless the two bullets conflict in meaning (they do not).

**Deferred minors**, none blocking: the close overlay's home-container paragraph is not scoped to `host: container` in its wording; Task 12's skill assertions grep the whole file and `docs/handoff.md` has no wording test; `stale:?` lock-skill wording says "an issue's container" for a home clone; `cleanup.sh` hides `github.sh`'s stderr behind its one `cleanup:` line; the README's "Both only print" now follows a paragraph not about printing.

### Round 3 — 2026-11-15
(send-back from qc.md round 2)

**Plan built:** round 3 of `docs/plans/2026-11-15-guard-home-only-skills.md` (Tasks 17-21), commits `53d0234` to `e5bffbf`, on a branch that already contained `origin/main` (no merge needed, no conflict). Each task pair was reviewed; a closing review read the whole round.

**What was built, against QC round 2's findings.**
- G1 (Task 17, `53d0234`): `role.sh`'s stale refusal reads the clone's own dossier and gives each state its own way back: finished (`.codeo/done/<N>/`, the container is done, `/codeo:cleanup` in the home container prints how to remove it), parked (the last `### Round` of `.codeo/<N>/close.md` is `— stashed` or `— abandoned`, same pattern `claim.sh --stash-live` uses, way back `/codeo:init #<N>` in the home container, "never the start script"), lock lost (a live dossier with no park: re-run the start script) and unknown. A park followed by a later `— pull request opened` round reads as lock lost. The README `stale` row already matched.
- G2, G4, G7 (Task 18, `f96f877`): `cleanup.sh` gains a fifth proof, `lease` (an issue that holds or waits for any lease in `intake.sh lease list --tsv` is not proven; an unreadable list stops the script with `cleanup: could not read the leases`); an empty or `null` `head_ref` fails the branch proof; the cleanup skill's untrue caveat is replaced by what is true ("the lock lives only in that clone") and its Hand-off says "any branch other than `codeo/intake`".
- G3, G5, G6 (Task 19, `1d30948`): the close overlay's home-container step opens "After a finished close" and ends "On a stash or an abandon, keep the closing block the skill gives for that exit."; step 17's "nothing is lost either way" is replaced; `docs/handoff.md`'s `cleanup` row names `/codeo:init #<M>`.
- Task 20 (`e5bffbf`): `.devcontainer/README.md`, `docs/skills.md` and the existing `CHANGELOG.md` bullet describe the four-state refusal and the fifth proof; no "four proofs" is left outside `docs/plans/` and `.codeo/`.
- Left, as the engineer chose at plan Q7 and recorded in `qc.md`: F9 (Podman), F11 (`CODEO_CLEANUP_REMOVAL`), F12 (generic "home container" wording) for `/codeo:triage`.

**Documentation changed.** `.devcontainer/README.md`, `docs/skills.md`, `docs/handoff.md`, `CHANGELOG.md`; `README.md`, `docs/extension-points.md` and `docs/skills-inventory.md` need nothing.

**Build result.** The `shell` suite's `build` (`true`) ran ok; `bash tests/run.sh` prints `all cases passed` at `e5bffbf` (3m21s); `bash scripts/doctor.sh` (this repository's) all ok, 11 checks; `git diff origin/main -- .devcontainer/Dockerfile .devcontainer/devcontainer.json` is empty; by hand, in a scratch `codeo-67` clone whose `close.md` ends `### Round 2 — stashed`, `role.sh` prints `stale:67`, `--check plan` exits 1 with the `/codeo:init #67 in the home container … never the start script` line and `--check triage` exits 1 with the home-container line; `overlap.sh 70` and `overlap.sh --outside 70` print nothing.

**Deviations from the plan.** None. The `name` check stays the guard on a printed command and is not counted as a proof: "five proofs" are issue, pull-request, branch, dossier and lease, as the plan says; the skill's step 1 lists six failure names.

**Rulings taken while building round 3** (each with what it costs if wrong): (1) the tasks ran as two dispatches (17+18, 19+20) with Task 21 inline, one commit per task and one review per dispatch: costs that tasks were reviewed in pairs. (2) The reviews, including the closing one, ran on sonnet, not a stronger model, because codeo's subagent hook allows only the configured subagent model: costs a weaker review; `/codeo:qc` grades independently on opus. (3) Four small findings of the reviews were left as minor rather than opening a fix round (see below): costs that `/codeo:qc` may raise them again.

**Deferred minors**, none blocking: the cleanup skill's frontmatter `description` lists four proofs and omits the lease; the unknown-state stale refusal names the role but no `#<N>` and its test skips that check; the finished lock-skill line says `/codeo:cleanup` "prints how to remove it" although it prints a command only for a proven issue; `docs/skills.md` writes `/codeo:close` without backticks in the new cleanup sentence, and the new step-17 sentence wraps unevenly.

### Round 4 — 2026-11-15
(send-back from qc.md round 3)

**Plan built:** round 4 of `docs/plans/2026-11-15-guard-home-only-skills.md` (Tasks 22-25), commits `310dccb` to `3256788`, on a branch that already contained `origin/main` (no merge needed, no conflict). Tasks 22+23 ran as one dispatch, Task 24 as its own, Task 25 inline; each dispatch was reviewed, and a closing review read the whole round.

**What was built, against QC round 3's findings.**
- H2, H4, H6 and the overlay's half of H1 (Task 22, `310dccb`): `.codeo/overlays/close.md`'s `## host-workflow` has one paragraph per exit. The removal command appears only under "After a finished close", and only when the lock's `volume:` matches `^codeo-[0-9]+$` and its number is the lock's `issue`. After a stash it prints none, names `/codeo:init #<N>` in the home container, and says the old container is removed by hand on the host first. After an abandon it prints none, names `/codeo:triage` in the home container, and says that with the branch deleted the container holds the only copy. `tests/close-removal.test.sh` pins the command to the finished paragraph, with three real mutants (the command copied into the stash paragraph, into the abandon paragraph, deleted from the finished paragraph), each asserted on its own failure message.
- H1, H3 (Task 23, `6afc189`, fix `8430550`): the stash-completed and abandon-finished closing blocks in `skills/close/SKILL.md` and their two rows in `docs/handoff.md` name the checkout the project's host workflow gives for the next skill; for the stash the clause covers both the board-failed and the other branch. `tests/closing-exits.test.sh` pins both, with mutations; `tests/cleanup-skill.test.sh` reads `docs/handoff.md` through the repository root.
- Closing review's finding (`3256788`): the stash and abandon prose now fetch `close/host-workflow` as step 17 does before naming the checkout, pinned by a `host-workflow-fetch` case with a mutation; the abandon paragraph of the overlay points at `.devcontainer/README.md`, and its test checks `the only copy` and that pointer inside that paragraph only.
- Task 24 (`64ec875`): `.devcontainer/README.md` says what close prints at each exit and how a stashed or abandoned container is removed by hand; `docs/extension-points.md` says the host-workflow text may differ by exit; the existing `CHANGELOG.md` bullet is extended in place. `docs/skills.md` says nothing about when the commands print and is unchanged.
- Left, as the engineer chose at plan Q13: H5 (`CODEO_CLEANUP_REMOVAL` outside tests, round 1's F11) for `/codeo:triage`.

**Documentation changed.** `.devcontainer/README.md`, `docs/handoff.md`, `docs/extension-points.md`, `CHANGELOG.md`.

**Build result.** The `shell` suite's `build` (`true`) ran ok; `bash tests/run.sh` prints `all cases passed` at `3256788` (3m20s); `bash scripts/doctor.sh` (this repository's) all ok; `git diff origin/main...HEAD -- .devcontainer/Dockerfile .devcontainer/devcontainer.json` is empty; `bash scripts/overlay.sh close host-workflow` read as each ending (finished, stash, abandon with the branch kept, abandon with it deleted) names one next step in the home container and a removal command only for the finished close; `overlap.sh 70` and `overlap.sh --outside 70` print nothing.

**Deviations from the plan.** One addition: the closing review found that stash and abandon never said to fetch the overlay point, so Task 23's clause could name a checkout with nothing fetched; the fetch sentence and its test were added in `3256788`. Otherwise none.

**Rulings taken while building round 4** (each with what it costs if wrong): (1) Tasks 22+23 ran as one dispatch with one reviewer: costs that two tasks were reviewed together. (2) All reviews ran on sonnet, because codeo's subagent hook allows only the configured subagent model: costs a weaker review; `/codeo:qc` grades independently on opus. (3) "On any machine" stays in the stash-completed block next to the new clause, because the plan says it stays: costs two adjacent phrases that read slightly at odds, which QC may raise. (4) Four small review findings were left as minor rather than opening a second fix wave (see below): costs that QC may raise them again.

**Deferred minors**, none blocking: the `docs/handoff.md` abandon row's clause reads as qualifying the clean-up rather than `/codeo:triage`; the overlay's stash paragraph says two containers cannot share the name even when the `volume:` is not `codeo-<N>`; the README's abandon paragraph omits "after `git status`" for the kept-branch removal; the README's "Both only print." sits three paragraphs from what it refers to; the stash section of `case_host_workflow_fetch` has no mutation of its own. Round 3's minors stand as recorded there.

## Log

- 2026-11-15 — built Tasks 1-10 and the final-review fix wave; Q1-Q4 raised on overlaps with #71, #96, #97, #98 · cost: 97m · sonnet-5-5 1.2M in + 35M cached / 196k out
- 2026-11-15 — Q1-Q4 answered; outcome written, handed off to qc · cost: 100m · sonnet-5-5 1.2M in + 37.2M cached / 205k out
- 2026-11-15 — round 2 after qc round 1: built Tasks 11-16, merged origin/main, handed off to qc · cost: 33m · sonnet-5-5 311k in + 14.1M cached / 56k out
- 2026-11-15 — round 3 after qc round 2: built Tasks 17-21, handed off to qc · cost: 28m · sonnet-5-5 292k in + 11M cached / 53k out
- 2026-11-15 — round 4 after qc round 3: built Tasks 22-25, handed off to qc · cost: 31m · sonnet-5-5 434k in + 12.3M cached / 65k out
