# Issue #70 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/70 |
| Branch | `feat/guard-home-only-skills-against` |
| Updated | 2026-11-15 |

## Where this stands

Round 5, sent back by QC round 4 (J1: a resumed stash whose container lost its lock is called stashed; J2: an archived dossier whose pull request is still open is called finished). Round 5, done. QC round 4's two blocking findings (J1, J2) and J3, J4, J5, J9 are planned (Tasks 26-29), the plan was approved and written into the plan file, Q14 and Q15 are answered and nothing is open. The next step is `/codeo:implement`.

## Questions

### Q1 — How does a skill know it is in this project's dev container, so a hosted web session or a plain local checkout is left alone?

**Why it matters:** this is the guard's on/off switch. A rule that is too wide locks out the web session and local checkouts the issue exempts; one that is too narrow misses a container opened another way. It changes the role script's first lines and the test cases.
**Options:**
- **(a) Marker rule, recommended:** guarded when `/.dockerenv` exists, `CLAUDE_CODE_REMOTE` is not `true`, and the clone folder is named `<codename>-home` or `<codename>-<digits>` (the shape `.devcontainer/README.md` tells the engineer to use). A container opened with another folder name is not guarded, and `folder-check.sh` already reports it at start.
- **(b) Container only:** `/.dockerenv` or `REMOTE_CONTAINERS=true`, whatever the folder is called. Catches "Reopen in Container", but it then has to call a folder named `codeo` a stale or home container with nothing to go on.
- **(c) Explicit opt-in:** the guard runs only where the start script wrote a marker file (gitignored). Most exact, but a container made before this change has no marker and stays unguarded until it is rebuilt.

**Answer:**
(a) Marker rule. Go with the recommendation (engineer, in the conversation, 2026-11-15).

### Q2 — How do the eight skills reach the guard: an extension point in each skill, a Claude Code hook, or both?

**Why it matters:** codeo's skills are generic and public (`tests/agnostic.test.sh`), and "home container" is this project's concept, so a skill cannot hard-code it. It decides what the criteria's tests pin (a skill's text, or a hook's configuration) and whether a typed `/codeo:init` is stopped as well as one the model calls.
**What I found in the documentation:** a typed slash command **bypasses `PreToolUse`**, so a `PreToolUse` hook on `Skill` stops only a skill the model calls itself. `UserPromptSubmit` and `UserPromptExpansion` do see a typed `/codeo:init #69` and can block it, but they run from the project's `.claude/settings.json`, which a hosted session may not read. The field names of the `Skill` tool input were not documented; they would need testing.
**Options:**
- **(a) Extension point, recommended:** a new registered point on each of the eight skills, `<skill>/role-guard` (registry row, `docs/skills.md` entry, step 0 in the skill: fetch it, follow it, stop on its refusal). The project's overlay for each skill says `bash .devcontainer/scripts/role.sh`, and the skill stops with one line naming the role. A project with no overlay is not guarded, which is also how web and local stay exempt. The "no override" rule is a `<!-- rule -->` marker on the stop itself, so an overlay cannot soften it. A test fails when a skill drops the step.
- **(b) Hook only:** a `UserPromptExpansion` plus `PreToolUse` hook in `.claude/settings.json` running the role script. Nothing in the skills changes, but the guard is not in the skill text, so the criterion "a test fails if a skill stops calling the check" can only pin the settings file, and a session that does not read it is unguarded.
- **(c) Both:** (a) for the rule and (b) so a typed command is stopped before the model starts. Two places to keep in step.

**Answer:**
(a) Extension point in each skill. Go with the recommendation (engineer, in the conversation, 2026-11-15).

### Q3 — Is `/codeo:cleanup` a codeo plugin skill, and where does the container-removal command come from?

**Why it matters:** the proofs (issue closed, pull request merged, branch gone, no live dossier) are generic, but a container named `codeo-<N>` and a volume of the same name are this project's dev container, and the plugin serves projects that have none. This decides whether `skills/cleanup/SKILL.md` carries a `docker` command string and whether it needs its own overlay point.
**Options:**
- **(a) Plugin skill with an overlay point, recommended:** `skills/cleanup/SKILL.md` does the proofs and the listing; a new point `cleanup/removal-command` supplies the command template and the name pattern (here: `docker rm -f codeo-{N}; docker volume rm codeo-{N}`, pattern `^codeo-[0-9]+$`). Default when absent: list the proven issues and print no command. `close/host-workflow` can carry the same text for the final report, so the command is written once in the project's overlay.
- **(b) Plugin skill, command in the skill:** simplest, and puts a Docker command in a skill every project loads.
- **(c) Project skill** under `.claude/skills/cleanup/`: nothing generic in the plugin, but it is outside `docs/skills.md`'s sections, the lint and the inventory, which the issue asks to cover it.

**Answer:**
(a) Plugin skill with an overlay point. Go with the recommendation (engineer, in the conversation, 2026-11-15).

### Q4 — Is a `.codeo/closed` tombstone, written by `/codeo:close`, worth having on top of the folder-and-branch check?

**Why it matters:** with the tombstone, `close` writes one more gitignored file, the role script reads it, and every test and doc gains a case. Without it, the role script decides from three facts it can always read: the lock, the folder name and the branch.
**My recommendation: no tombstone.** `codeo-67` is caught by its folder (`codeo-<digits>` with no lock is `stale:67`), and by its branch (a branch that is not `main`). The only container it would add is a finished one on `main` in a folder named `<codename>-home`, which cannot have been an issue container, because `init` and the start script name the folder after the issue.
**Options:** no tombstone · tombstone written by `close`.

**Answer:**
No tombstone. Go with the recommendation (engineer, in the conversation, 2026-11-15).

### Q5 — Does "every skill stops in a stale container" include `doctor` and `setup`?

**Why it matters:** the criterion says every skill. `doctor` only reports and `setup` only writes `.codeo/` and `docs/plans/`, and a stale container is exactly where an engineer might run `doctor` to see why things look wrong. Including them adds two overlay points and two tests, and takes a diagnostic away from the one place it is wanted.
**My recommendation:** the eight pipeline skills (`issue`, `init`, `triage`, `cleanup`, `plan`, `implement`, `qc`, `close`) guard; `doctor` and `setup` run anywhere and the container README says so ("Where these run": any container).
**Options:** the eight only · all ten.

**Answer:**
The eight only; `doctor` and `setup` run anywhere. Go with the recommendation (engineer, in the conversation, 2026-11-15).

### Q6 — One pull request, or several?

**Why it matters:** the work has three separable parts and the splitting changes the plan's task order and what is mergeable alone: (1) the role script, the `role-guard` points and the eight skill steps, with their docs; (2) the removal commands in `close`'s final report; (3) `/codeo:cleanup`, with its point and docs. Parts 2 and 3 both rely on the command text from Q3, and all three edit `docs/skills.md`, the README table, `docs/skills-inventory.md` and `CHANGELOG.md`.
**Options:** one pull request, recommended (the criteria are written as one change and the shared docs would otherwise conflict three times) · three, in that order.

**Answer:**
One pull request. Go with the recommendation (engineer, in the conversation, 2026-11-15).

### Q7 — Round 2: which of QC round 1's non-blocking findings (F4-F13) does this round fix along with F1 and F2?

**Why it matters:** F1 and F2 are blocking and are fixed either way. Each non-blocking finding taken in adds a step and a test to this round; each one left stays in `qc.md` for `/codeo:triage` after the merge. F9 (Podman detection) and F11 (the `CODEO_CLEANUP_REMOVAL` override in the production path) change script behaviour and tests; F12 rewords generic text; the rest are one-line or wording fixes in files this round already touches.
**Options:** F1, F2 and the cheap ones — F4, F5, F6, F7, F8, F10, F13 (recommended) · F1 and F2 only · everything, F1-F13.

**Answer:**
F1, F2 and the cheap ones (F4, F5, F6, F7, F8, F10, F13); F9, F11 and F12 are left for `/codeo:triage`. Answered with the question tool, in the conversation (engineer, 2026-11-15).

### Q8 — Round 3, G1: how does the stale refusal say the way back without reviving a parked workflow?

**Why it matters:** round 2's wording tells a lock skill in a stale container to re-run the start script, and `lock.sh take` binds from the branch's `init.md` without checking for a stash or an abandon, so the advice revives a parked workflow with no claim and no board move. Detecting the state adds a read of the clone's own dossier to `role.sh` and three test cases; one generic message adds none but is wrong for a live container whose lock was merely lost.
**Options:** detect the state from the clone's dossier — finished, parked (stashed or abandoned), or lock lost — and give each its own way back (recommended) · one generic message naming `/codeo:init #<N>` in the home container.

**Answer:**
Detect the state. Answered with the question tool, in the conversation (engineer, 2026-11-15).

### Q9 — Round 3, G2: besides correcting the untrue caveat, does `cleanup.sh` gain a proof that the workflow ended?

**Why it matters:** a pull request merged on GitHub with automatic branch deletion passes all four proofs even when `/codeo:close` never finished in the container, so leases on the intake branch are still held and removing the volume hides that. A `lease` proof (an issue that holds or waits for any lease in `intake.sh lease list --tsv` is not proven) fails closed and costs one read and one test; it cannot see the lock itself, which lives only in the container. Caveat-only changes no script.
**Options:** add a `lease` proof and correct the caveat (recommended) · correct the caveat only.

**Answer:**
Add the `lease` proof and correct the caveat. Answered with the question tool, in the conversation (engineer, 2026-11-15).

### Q10 — Round 3: which of QC round 2's non-blocking findings (G3-G7) does this round fix as well?

**Why it matters:** each is a one-line or wording fix in a file this round already touches (G3 the close overlay's home-container sentence only for the finished exit, G4 cleanup "never touches any branch other than `codeo/intake`", G5 "nothing is lost" against the `git status` warning in close step 17, G6 `#<M>` in `docs/handoff.md`, G7 a null or empty `head_ref` fails the branch proof); left out, each stays in `qc.md` for `/codeo:triage`.
**Options:** all of G3-G7 (recommended) · G1 and G2 only.

**Answer:**
All of G3-G7. Answered with the question tool, in the conversation (engineer, 2026-11-15).

### Q11 — Round 3: overlap with #97 on `skills/qc/SKILL.md` and `tests/qc-skill.test.sh`: proceed and coordinate, sequence after #97, or re-scope?

**Why it matters:** #97 (branch `docs/docs-skill-wording-test-guard`, assignee kbajpai, step `qc`, working) now lists `skills/qc/SKILL.md` and `tests/qc-skill.test.sh` in its footprint, which the earlier overlap questions on #97 (implement.md Q3) did not cover; this branch already changed both in earlier rounds (the `role-guard` step and rule in the skill, the refused-call sentence in the skill and its test), and round 3 does not touch either. *Proceed* means whichever branch merges second merges `origin/main` and keeps both edits, which `/codeo:implement` and `/codeo:qc` do at the start of every round; *sequence* means this branch waits for #97, which is already at `qc`. The printed overlaps, verbatim: `glob:skills/qc/SKILL.md`, `glob:tests/qc-skill.test.sh`, `skills/qc/SKILL.md`, `tests/qc-skill.test.sh`.
**Options:** proceed and coordinate (recommended: round 3 adds nothing to either file, and #97 is at `qc`) · sequence after #97 · re-scope.

**Answer:**
Proceed and coordinate. Go with the recommendation (engineer, in the conversation, 2026-11-15).

### Q12 — Round 4, H2: after which exits does `/codeo:close` print the container-removal command?

**Why it matters:** the close overlay prints `docker rm -f <volume>; docker volume rm <volume>` at every exit of a container-hosted workflow. After an abandon whose unmerged branch the engineer had deleted, the container holds the only copy of the work, committed, so `git status` is clean and the command destroys it. After a stash or an abandon with the branch kept, the branch on origin carries everything pushed, and a stash's old `codeo-<N>` container must go before `/codeo:init #<N>` can open a new one with that name (QC's H6). "Finished only" is one condition and one test, and matches the issue's criterion ("after a finished workflow"); a stash or an abandon then prints no command and says why, and for a stash says the old container is removed by hand on the host (after `git status`) before the resume, pointing at `.devcontainer/README.md`. "All but the last copy" also prints the command after a stash and after an abandon with the branch kept, which is more convenient and needs three more conditions worded and pinned, in the text that has sent this change back three times.
**Options:** finished close only; a stash or an abandon prints no command and says why (recommended) · every exit except an abandon whose branch was deleted.

**Answer:**
Finished close only; a stash or an abandon prints no command and says why. Answered with the question tool, in the conversation (engineer, 2026-11-15).

### Q13 — Round 4: which of QC round 3's non-blocking findings (H3-H6) does this round fix as well?

**Why it matters:** H3 (`tests/cleanup-skill.test.sh:24` reads `docs/handoff.md` by a relative path) is a one-line fix. H4 (the overlay prints the command for any `volume:` matching `^codeo-[0-9]+$`, not only `codeo-<the lock's issue>`) is one more condition in the overlay sentence this round rewrites anyway, with one test needle. H6 (a stashed container has no removal advice anywhere) is settled by Q12 either way. H5 (`CODEO_CLEANUP_REMOVAL` works outside tests) is round 1's F11, already left for `/codeo:triage` by the answer to Q7. Left out, each stays in `qc.md` for `/codeo:triage`.
**Options:** H3, H4 and H6, leaving H5 for triage (recommended) · H1 and H2 only.

**Answer:**
H3, H4 and H6; H5 stays for `/codeo:triage`. Answered with the question tool, in the conversation (engineer, 2026-11-15).

### Q14 — Round 5, J4: what does the stale refusal say for an abandoned workflow?

**Why it matters:** `role.sh` gives a stashed and an abandoned workflow the same line: "`/codeo:init #<N>` in the home container is the way back". For a stash that is right. For an abandon it is not: `/codeo:init` stops an abandoned workflow unless the engineer takes it up again, and `/codeo:close`'s own rule names no command that resumes one. The container may also hold the only copy of the work (when the branch was deleted at the abandon), which the refusal does not say. "No resume named" makes the abandoned line say the workflow was abandoned, that nothing more runs in this container, and that it may hold the only copy of the work, so check the branch on origin before removing it. "Name init as a deliberate restart" keeps the command but words it as taking the issue up again on purpose. J1 and J2 (the two blocking findings) are fixed either way: a park counts only while parks outnumber the resume lines in `init.md`, as `claim.sh` counts them, and an archived dossier counts as finished only when the base branch carries it.
**Options:** no resume named; say it was abandoned, nothing more runs here, and the container may hold the only copy (recommended) · name `/codeo:init #<N>` as a deliberate restart.

**Answer:**
No resume named: the abandoned line says the workflow was abandoned, nothing more runs here, and the container may hold the only copy of the work. Answered with the question tool, in the conversation (engineer, 2026-11-15).

### Q15 — Round 5: which of QC round 4's non-blocking findings (J3-J9) does this round fix as well?

**Why it matters:** J3 (in `codeo-home` on a branch other than the base, the refusal says "run it in the home container" to someone already in it), J4 (Q14) and J5 (the stash refusal does not say to remove this container before the resume opens a new one) are all in the refusal text this round rewrites, each one sentence and one test needle. J9 (`docs/skills.md` says cleanup never touches any branch, though it commits to `codeo/intake`) is a one-line page fix. J6 (Podman) and J7 (`CODEO_CLEANUP_REMOVAL` outside tests) are round 1's F9 and F11, already left for `/codeo:triage`. J8 (`cleanup.sh` lists every issue ever archived on every run) is a change to what cleanup prints, a design of its own. Left out, each stays in `qc.md` for `/codeo:triage`.
**Options:** J3, J4, J5 and J9, leaving J6-J8 for triage (recommended) · J1 and J2 only.

**Answer:**
J3, J4, J5 and J9; J6, J7 and J8 stay for `/codeo:triage`. Answered with the question tool, in the conversation (engineer, 2026-11-15).

## Notes

What exploration found, so the plan does not re-ask it:

- **Role script.** `.devcontainer/scripts/container-name.sh` already reads the codename (`--codename`) and the lock's issue number with one pattern; `folder-check.sh` reads `baseBranch` from `.codeo/config.json` (fixed in #57, merged) and treats a folder `<codename>-<digits>` off the base branch as a failed lock. The role script is new, sits next to them in `.devcontainer/scripts/`, calls `container-name.sh` for both, and reads the base the way `folder-check.sh` does. It does not call or change `folder-check.sh`, which stays the start script's check of the folder against the lock. My call: it lives with the project's dev container scripts, not in the plugin's `scripts/`, because "home container" is this project's concept.
- **Roles.** `home` (clone on the base branch, folder `<codename>-home`, no lock), `issue:<N>` (a lock naming `<N>`), `stale:<N>` (no lock; folder `<codename>-<N>` or branch not the base), and, for a clone with no lock on the base branch in some other folder, a fourth answer the issue does not name: my call is `unknown`, which the guard treats as not-home for the four home-only skills and as allowed for the rest.
- **The lock's folder check.** For `plan`, `implement`, `qc` and `close`, the role script prints `issue:<N>` only when the folder is `<codename>-<N>` for the lock's `<N>`; a folder that disagrees prints `mismatch:<N>:<folder>`, so the guard can stop on it.
- **`close` step 17.** It already reads `volume:` before step 16 deletes the lock and fetches `close/host-workflow`. The default for `host: container` becomes the removal command with `<N>` from the `volume:` line, plus "run on the host, not in this container" and "check `git status` first"; PowerShell and bash both accept `;`, so one line serves both. This repository's own overlay for it would carry the `docker` text if Q3 is (a).
- **Cleanup's proofs** use `github.sh` (issue state, pull request `merged_at`, `git ls-remote --heads` for the branch) and `git grep` for a live `.codeo/<N>` on any pushed branch; finished issues come from `.codeo/done/<N>` on `origin/main`. It records what it printed under `.codeo/intake/cleanup/` through `intake.sh commit cleanup`, as `triage` does. It cannot see unpushed work in a clone, and says so.
- **Dev container constraints.** `tests/devcontainer.test.sh` pins `devcontainer.json` and the Dockerfile exactly, so nothing here touches either file; the home container has no container engine, so `/codeo:cleanup` only prints.
- **Tests that enumerate skills** and so move with a new skill: `tests/skills-doc.test.sh` (a `## cleanup` section with its four sub-headings), `tests/inventory.test.sh` (its table of rule counts), `tests/skills.test.sh` lint and `tests/closing-block.test.sh` (the closing-block citation). New tests: the role script's cases, a guard test for the eight skills, and `close` and `cleanup` text pins.
- **Documentation the change moves:** `docs/skills.md`, README's Skills table, `docs/skills-inventory.md`, `docs/extension-points.md` (the new points), `.devcontainer/README.md` (the roles and the "Where these run" row), `docs/handoff.md` (the lock section gains the roles) and `CHANGELOG.md`. No invariants document, wiki module, shared environment or `resources[]` is configured.
- **Sequencing.** #69, which the issue says to follow, is closed and merged, so `skills/close/SKILL.md` and `docs/handoff.md` are free to edit.
- **Documentation lookup (hooks).** Read only for Q2: a typed `/skill` bypasses `PreToolUse`, while `UserPromptSubmit` and `UserPromptExpansion` see it; hooks fire in the terminal, the VS Code extension and cloud sessions alike, but whether a hosted session reads the project's `.claude/settings.json` was not confirmed.

## Outcome

2026-11-15

**Plan:** `docs/plans/2026-11-15-guard-home-only-skills.md`, a scoped executable plan (ten tasks, one pull request) under `docs/plans/`, approved by the engineer and left unstaged. No reference doc under `docs/`: no standing decision beyond the extension-point and dev container docs the plan updates.

**Decisions (Q1-Q6, all the recommendations).** Q1 the guard applies only when `/.dockerenv` exists, `CLAUDE_CODE_REMOTE` is not `true` and the folder is `<codename>-home` or `<codename>-<digits>`; anything else is `unguarded`. Q2 a registered `<skill>/role-guard` extension point in each of eight skills (`issue`, `init`, `triage`, `cleanup`, `plan`, `implement`, `qc`, `close`), the project's overlay running `role.sh --check <skill>`, and a `rule` marker so there is no override. Q3 `/codeo:cleanup` is a plugin skill backed by `scripts/cleanup.sh`, with the name, pattern and command from a new overlay point `cleanup/removal-command`. Q4 no `.codeo/closed` tombstone. Q5 `doctor` and `setup` are not guarded. Q6 one pull request.

**Calls made in the plan.** The role script lives in `.devcontainer/scripts/` and reuses `container-name.sh`, not `folder-check.sh`; there is no `unknown` role (an unshaped folder is `unguarded`); a no-lock clone in the home folder off the base branch is `stale:?`. Task 4 is the plan's own call, shown at the gate and approved: because the guard is strict, a skill in an issue container that would call `/codeo:issue` records the finding in its own dossier and says to file it from the home container.

**Rejected.** A Claude Code hook as the guard (a typed slash command bypasses `PreToolUse`, and a hosted session may not read the project's settings); a hook as well as the point; the removal command written into the skill; a project-only cleanup skill; a tombstone; three pull requests.

**Documentation.** `.devcontainer/README.md`, `docs/skills.md`, `docs/extension-points.md`, `docs/skills-inventory.md`, `docs/handoff.md`, `README.md`, `CHANGELOG.md`. No intake question was resolved here beyond the four `init.md` left open (all settled by Q1-Q4 and the calls above).

### Round 2 — 2026-11-15
(send-back from qc.md round 1)

**Plan:** the same file, `docs/plans/2026-11-15-guard-home-only-skills.md`, with a `## Round 2` section (Tasks 11-16), approved by the engineer and left unstaged. Shape unchanged: one executable plan, one pull request.

**What QC found.** F1 (blocking, the plan's): a finished `/codeo:close` names `/codeo:triage` as its first step in a container that has just become stale, where the guard refuses it. F2 (blocking, the plan's): a finding the guard refuses to file was "recorded in the dossier" in no stated form, while triage collects only some forms. F3-F13 non-blocking.

**Decisions.** Q7 = F1, F2 and the cheap ones (F4, F5, F6, F7, F8, F10, F13), answered with the question tool: Task 11 (F1, F7) the finished close names the checkout the follow-up skills run in, generically "the checkout the project's host workflow names" and in this repository's overlay the home container, with the overlay applying only to `host: container`; Task 12 (F2) the refused-finding sentence names the form, a `## Notes` line promising later work with no issue number; Task 13 (F4, F5, F13) the `github.sh` usage line, `cleanup.sh` stopping on an unreadable issue, the `<M>` placeholder; Task 14 (F6, F10) the stale refusal covers a stashed or abandoned workflow and names the recovery, and the overlays cover any other exit; Task 15 (F1, F8) the README and CHANGELOG. F3 → the footprint gains `scripts/github.sh`. Rejected: fixing F1/F2 only; everything F1-F13 (F9 Podman, F11 the override in the production path and F12 generic wording are left in `qc.md` for `/codeo:triage`).

**Documentation the round moves.** `.devcontainer/README.md`, `docs/extension-points.md`, `docs/handoff.md`, `CHANGELOG.md`. `docs/skills.md`, `docs/skills-inventory.md` and `README.md` need nothing.

**Filed through `/codeo:issue`:** none.
### Round 3 — 2026-11-15
(send-back from qc.md round 2)

**Plan:** the same file, `docs/plans/2026-11-15-guard-home-only-skills.md`, with a `## Round 3` section (Tasks 17-21), approved by the engineer and left unstaged. Shape unchanged: one executable plan, one pull request.

**What QC found.** G1 (blocking, the plan's): round 2's stale refusal tells a lock skill to re-run the start script, which `lock.sh take` would honour for a stashed or abandoned workflow, binding it with no claim and no board move. G2 (blocking, the plan's): the cleanup skill's caveat "close.md having recorded a clean tree" names a record that never reaches `origin/<base>`, and `cleanup.sh` lists as proven an issue whose `/codeo:close` never finished and whose leases are still held. G3-G7 non-blocking; round 1's F9, F11 and F12 stay for `/codeo:triage`.

**Decisions.** Q8 = detect the state: Task 17 `role.sh`'s stale refusal reads the clone's own dossier (finished: `.codeo/done/<N>/`; parked: `close.md`'s last round `— stashed` or `— abandoned`, way back `/codeo:init #<N>` in the home container, never the start script; lock lost: a live `.codeo/<N>/`, re-run the start script; unknown: a generic line). Q9 = add the proof: Task 18 `cleanup.sh` gains a fifth proof, `lease` (an issue that holds or waits for any lease is not proven), a missing `head_ref` fails the branch proof, and the untrue caveat is replaced by what is true. Q10 = all of G3-G7: Task 19 close's last report agrees with itself (the overlay's home-container step applies to a finished close only, step 17 stops saying "nothing is lost either way", `docs/handoff.md` uses `#<M>`), G4 in Task 18. Task 20 documents it, Task 21 is the whole check. Q11 = proceed and coordinate on #97's overlap with `skills/qc/SKILL.md` and `tests/qc-skill.test.sh`; round 3 touches neither. Rejected: one generic stale message; caveat-only for cleanup; G1 and G2 only.

**Documentation the round moves.** `.devcontainer/README.md`, `docs/skills.md`, `docs/handoff.md`, `CHANGELOG.md`, and `README.md` only where it counts proofs. `docs/extension-points.md` and `docs/skills-inventory.md` need nothing: no point and no rule changes.

**Filed through `/codeo:issue`:** none.

### Round 4 — 2026-11-15
(send-back from qc.md round 3)

**Plan:** the same file, `docs/plans/2026-11-15-guard-home-only-skills.md`, with a `## Round 4` section (Tasks 22-25), approved by the engineer and left unstaged. Shape unchanged: one executable plan, one pull request.

**What QC found.** H1 (blocking, the plan's): after an abandon in a container the lock is gone and the role is `stale:<N>`, yet the abandon closing block's first step is `/codeo:triage` with no checkout named, and round 3's overlay told the model to keep that block; the stash-completed block has the same hole with `/codeo:init #<N>`. H2 (blocking, the plan's): the close overlay prints the removal command at every exit, so after an abandon whose unmerged branch was deleted it hands over the command that destroys the only copy of the work, with a clean `git status`. H3-H6 non-blocking.

**Decisions.** Q12 = finished close only: Task 22 the overlay's `## host-workflow` has one paragraph per exit; the removal command appears only after a finished close and only when the lock's `volume:` is `codeo-<the lock's issue>` (H4); a stash and an abandon print no command and say why, each names the home container for its next skill, a stash says the old container is removed by hand before the resume (H6), an abandon with the branch deleted says the container holds the only copy; `tests/close-removal.test.sh` pins the command to the finished paragraph, with a mutation self-check. Task 23 the stash-completed and abandon-finished closing blocks in `skills/close/SKILL.md` and their two rows in `docs/handoff.md` gain the finished block's clause naming the checkout the project's host workflow gives (H1), pinned in `tests/closing-exits.test.sh`; `tests/cleanup-skill.test.sh` reads `docs/handoff.md` through the repository root (H3). Q13 = H3, H4 and H6; H5 (`CODEO_CLEANUP_REMOVAL`, round 1's F11) stays with `/codeo:triage`. Task 24 documentation, Task 25 the whole check. No script changes.

**Rejected.** Printing the command after a stash and after an abandon with the branch kept (more convenient, three more conditions to word and pin in the text that has come back three times); leaving the overlay unconditional and warning in prose (the warning cannot see committed work).

**Documentation the round moves.** `.devcontainer/README.md`, `docs/handoff.md`, `docs/extension-points.md`, `CHANGELOG.md`; `docs/skills.md` only if it says the commands print at every exit. `docs/skills-inventory.md` needs nothing: no rule and no point changes.

**Filed through `/codeo:issue`:** none.

### Round 5 — 2026-11-15
(send-back from qc.md round 4)

**Plan:** the same file, `docs/plans/2026-11-15-guard-home-only-skills.md`, with a `## Round 5` section (Tasks 26-29), approved by the engineer and left unstaged. Shape unchanged: one executable plan, one pull request.

**What QC found.** J1 (blocking, the plan's): `role.sh` calls a workflow parked from the last `### Round` heading of `close.md` alone, so a resumed stash whose new container failed to take the lock is told it "was stashed" and to use `/codeo:init #<N>`, never the start script. J2 (blocking, the plan's): `role.sh` calls a workflow finished as soon as `.codeo/done/<N>` exists, though close archives it when the pull request is opened, so a container that loses its lock while the pull request awaits review is told it is finished and pointed at removal. J3-J9 non-blocking.

**Decisions.** Q14 = no resume named for an abandon. Q15 = J3, J4, J5 and J9; J6 (Podman), J7 (`CODEO_CLEANUP_REMOVAL`, round 1's F11 and round 3's H5) and J8 (cleanup lists every archived issue) stay with `/codeo:triage`. Task 26 `role.sh` reads the state as the scripts that own it do: finished only when the base branch carries `.codeo/done/<N>` (`origin/<base>` when that ref exists, else the local base, as `lock.sh` does, without its fetch), an archive the base lacks is lock-lost; parked only while parks in `close.md` outnumber resume lines in `init.md`, counted as `claim.sh --stash-live` counts them, the last park heading giving the kind (J1, J2). Task 27 the refusal lines: a stash says to remove this container before `/codeo:init #<N>` opens the new one (J5); an abandon names no resume and says the container may hold the only copy of the work (J4); the home container off its base branch says to switch back to the base branch (J3). Task 28 documents it and corrects `docs/skills.md`'s cleanup non-goal (J9). Task 29 the whole check. Only `role.sh` changes among the scripts. Calls made in the plan: `role.sh` does not fetch; the park count follows `claim.sh` exactly, so a stash followed by a later close round with no resume line reads as stashed (round 3 read it as lock-lost).

**Rejected.** A fetch in the guard (it runs before every skill); naming `/codeo:init #<N>` for an abandon as a deliberate restart; J1 and J2 only.

**Documentation the round moves.** `.devcontainer/README.md`, `docs/skills.md`, `CHANGELOG.md`. `docs/extension-points.md`, `docs/handoff.md` and `docs/skills-inventory.md` need nothing: no point, rule or closing block changes.

**Filed through `/codeo:issue`:** none.

### Footprint

```
files:      .devcontainer/scripts/role.sh, .devcontainer/README.md, .codeo/overlays/**, skills/**, scripts/cleanup.sh, scripts/github.sh, lib/extension-points.tsv, docs/skills.md, docs/skills-inventory.md, docs/extension-points.md, docs/handoff.md, README.md, CHANGELOG.md, tests/**, docs/plans/2026-11-15-guard-home-only-skills.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-15 — Q1-Q6 raised · cost: 4m · fable-5-2 126k in + 1.1M cached / 15k out · sonnet-5-5 181k in + 139k cached / 8k out
- 2026-11-15 — planned: docs/plans/2026-11-15-guard-home-only-skills.md · engineering:architecture and engineering:system-design not loaded, their Options/Decision structure applied directly from Q1-Q3 · cost: 13m · fable-5-2 126k in + 1.1M cached / 15k out · sonnet-5-5 232k in + 2M cached / 39k out
- 2026-11-15 — round 2 after qc round 1: Q7 raised and answered with the question tool; draft at the review gate · cost: 2m · fable-5-2 423k in + 1.8M cached / 10k out
- 2026-11-15 — planned round 2: docs/plans/2026-11-15-guard-home-only-skills.md (Tasks 11-16) · engineering:architecture and engineering:system-design not loaded, the structure applied directly · cost: 13m · fable-5-2 424k in + 2.2M cached / 11k out · sonnet-5-5 26k in + 1.3M cached / 4k out
- 2026-11-15 — round 3 after qc round 2: Q8-Q10 raised and answered with the question tool; draft at the review gate · cost: 3m · fable-5-2 539k in + 2.8M cached / 10k out
- 2026-11-15 — round 3: Round 3 (Tasks 21 total) written into the plan file after approval; Q11 raised on a new overlap with #97 · cost: 5m · fable-5-2 539k in + 3.4M cached / 11k out · sonnet-5-5 27k in + 2.8M cached / 4k out
- 2026-11-15 — planned round 3: docs/plans/2026-11-15-guard-home-only-skills.md (Tasks 17-21); Q11 answered · engineering:architecture and engineering:system-design not loaded, the structure applied directly · cost: 19m · fable-5-2 539k in + 3.4M cached / 11k out · sonnet-5-5 31k in + 4.5M cached / 7k out
- 2026-11-15 — planned round 4: docs/plans/2026-11-15-guard-home-only-skills.md (Tasks 22-25); Q12-Q13 answered · engineering:architecture and engineering:system-design not loaded, the structure applied directly · cost: 4m · fable-5-2 172k in + 1.9M cached / 14k out · sonnet-5-5 171k in + 817k cached / 3k out
- 2026-11-15 — round 5 after qc round 4: Q14-Q15 raised and answered with the question tool; draft at the review gate · cost: 3m · fable-5-2 170k in + 1.6M cached / 15k out
- 2026-11-15 — planned round 5: docs/plans/2026-11-15-guard-home-only-skills.md (Tasks 26-29); Q14-Q15 answered · engineering:architecture and engineering:system-design not loaded, the structure applied directly · cost: 5m · fable-5-2 171k in + 1.8M cached / 16k out · sonnet-5-5 165k in + 415k cached / 2k out
