# Issue #70 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/70 |
| Branch | `feat/guard-home-only-skills-against` |
| Updated | 2026-11-15 |

## Where this stands

Round 1, done. Q1-Q6 are answered, the plan was approved and written to `docs/plans/2026-11-15-guard-home-only-skills.md`; nothing is open. The next step is `/codeo:implement`.

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

### Footprint

```
files:      .devcontainer/scripts/role.sh, .devcontainer/README.md, .codeo/overlays/**, skills/**, scripts/cleanup.sh, lib/extension-points.tsv, docs/skills.md, docs/skills-inventory.md, docs/extension-points.md, docs/handoff.md, README.md, CHANGELOG.md, tests/**, docs/plans/2026-11-15-guard-home-only-skills.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-15 — Q1-Q6 raised · cost: 4m · fable-5-2 126k in + 1.1M cached / 15k out · sonnet-5-5 181k in + 139k cached / 8k out
- 2026-11-15 — planned: docs/plans/2026-11-15-guard-home-only-skills.md · engineering:architecture and engineering:system-design not loaded, their Options/Decision structure applied directly from Q1-Q3 · cost: 13m · fable-5-2 126k in + 1.1M cached / 15k out · sonnet-5-5 232k in + 2M cached / 39k out
