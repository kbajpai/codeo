# Guard the home-only skills, print removal commands at close, add /codeo:cleanup — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A skill that belongs in the home container refuses to run anywhere else, `/codeo:close` prints the host commands that remove its finished container, and a print-only `/codeo:cleanup` lists them for every finished issue.

**Architecture:** One project script, `.devcontainer/scripts/role.sh`, decides a clone's role (`home`, `issue:<N>`, `stale:<N>`, `mismatch:<N>:<folder>`, or `unguarded` outside this project's dev container). Eight skills each gain a registered extension point `<skill>/role-guard`; the project's overlay for each runs `role.sh --check <skill>` and the skill stops on a refusal, which a `rule` marker makes final. `/codeo:cleanup` is a plugin skill backed by `scripts/cleanup.sh`, which proves each finished issue on GitHub and takes the container name and removal command from a new overlay point, `cleanup/removal-command`. `/codeo:close`'s final report carries the same command through `close/host-workflow`.

**Tech Stack:** bash, jq, git, `github.sh`; tests are `tests/*.test.sh` run by `bash tests/run.sh` (the `shell` suite, no single-test filter).

**Spec:** `.codeo/70/issue.md` (the issue's Key Requirements and acceptance criteria) and `.codeo/70/plan.md` Q1-Q6 (the engineer's decisions). No reference doc under `docs/`: nothing here is a standing decision beyond what `docs/extension-points.md` and `.devcontainer/README.md` will say.

## Global Constraints

- **Decisions, not to be reopened.** Q1 marker rule · Q2 per-skill extension point (no hook) · Q3 plugin skill with overlay point `cleanup/removal-command` · Q4 no tombstone · Q5 eight skills guarded, `doctor` and `setup` not · Q6 one pull request.
- **Q1 rule, exactly:** guarded only when `/.dockerenv` exists, `CLAUDE_CODE_REMOTE` is not `true`, and the clone folder is `<codename>-home` or `<codename>-<digits>`. Anything else prints `unguarded`.
- **No override.** The refusal in each skill is a `<!-- rule: <skill>-NN -->` rule; nothing in the skill or an overlay lets the engineer's words skip it.
- **codeo is public and project-agnostic** (`tests/agnostic.test.sh`): no skill, script or doc under `skills/`, `scripts/`, `lib/` or `docs/` names `codeo-home`, `codeo-gh`, `codeo-git` or the `docker` command. Those live only in `.codeo/overlays/` and `.devcontainer/`.
- **`.devcontainer/Dockerfile` and `.devcontainer/devcontainer.json` do not change**: no container engine, no bind mount, no secret, no Docker socket (`tests/devcontainer.test.sh` stays green). `/codeo:cleanup` and `scripts/cleanup.sh` run no Docker command.
- **Every printed command runs unmodified in PowerShell and bash**: one line, `;` between commands, no variables or substitutions.
- **Pinned rule text.** `docs/skills-inventory.md` rule bullets are pinned by `tests/fixtures/skills-inventory.rules.sha256`: adding bullets means `bash tests/inventory.test.sh --update` and saying so in the commit message.
- **Invariants.** No invariants document is configured, so there is nothing to check this plan against. No shared environment, no `wiki` module and no `resources[]`: no task carries a lease marker, and every task is proved in this checkout.
- **Documentation moved** (written in Tasks 3, 7 and 9): `.devcontainer/README.md`, `docs/skills.md`, `docs/extension-points.md`, `docs/skills-inventory.md`, `docs/handoff.md`, `README.md`, `CHANGELOG.md`.
- **Task proof.** Each task names its test file, run alone, then `bash tests/run.sh` (the suite has no `filter`, so the whole `test` command is the proof); both must print `all cases passed`. A red-first step names the expected failure.

## Review Focus

- A container opened with **Reopen in Container** from a host folder named `codeo` (or anything unshaped): must be `unguarded`, never refused. Pinned in Task 1.
- **A hosted web session whose workspace sits in a folder named `codeo-70`**: `CLAUDE_CODE_REMOTE=true` must win over the folder. Pinned in Task 1.
- **A `.codeo/active` that names no issue** in a `codeo-<N>` folder on `main`: reads as no lock, so `stale:<N>`; the start script already reports the file. Pinned in Task 1.
- **A skill called by another skill from an issue container** (`/codeo:plan` calling `/codeo:issue`): the guard refuses it. Tasks 3 and 4 make the caller record the finding instead of filing it.
- **`cleanup.sh` handed a template that expands to `codeo-home`, `codeo-gh` or `codeo-git`, or to no pattern at all**: no command is printed, only the failed proof `name`. Pinned in Task 6.
- **An issue whose `close.md` records no pull request line**: listed as failed proof `pull-request`, no command. Pinned in Task 6.

---

### Task 1: The role script

**Files:**
- Create: `.devcontainer/scripts/role.sh`
- Test: `tests/role.test.sh`

**Interfaces:**
- Consumes: `.devcontainer/scripts/container-name.sh` (`--codename`, `--docker`); `.codeo/config.json` `baseBranch` (default `main`), read the way `folder-check.sh` reads it.
- Produces: `role.sh [dir]` prints exactly one line: `unguarded` | `home` | `issue:<N>` | `stale:<N>` | `stale:?` | `mismatch:<N>:<folder>`. `role.sh --check <skill> [dir]` exits 0 printing nothing when the skill may run here, exits 1 printing one refusal line when it may not, exits 2 with one `role:` line on stderr for an unknown skill or a non-repository. `CODEO_DOCKERENV` (default `/.dockerenv`) names the file whose presence means "in a container", so tests can run anywhere.

Roles: with a lock for `<N>`, `issue:<N>` when the folder is `<codename>-<N>`, else `mismatch:<N>:<folder>`; no lock, on the base branch, folder `<codename>-home` → `home`; no lock otherwise → `stale:<N>` when the folder is `<codename>-<N>`, else `stale:?`.

`--check` table: the home-only skills are `issue init triage cleanup`, the lock skills are `plan implement qc close`. Home-only runs on `unguarded` and `home`; lock skills run on `unguarded`, `issue:<N>` **and `home`** (their own step 0 already refuses with no lock, naming `/codeo:init`). Every other role refuses. The refusal line is one sentence that names the role, and for `stale:<N>` and `mismatch:<N>:…` names issue `#<N>`, and says where the skill runs (the home container, or the issue's container).

- [ ] **Step 1: Write the failing test** `tests/role.test.sh`. It builds scratch git clones in directories named per case, each with `.codeo/config.json` (`codename: "codeo"`, `baseBranch: "main"`) and a stub `CODEO_DOCKERENV` file. Cases, each asserting the exact output of `role.sh` (and of `--check` for each of the eight skills and each role: exit code, and for a refusal that the line is one line and names the role and, where there is one, `#<N>`):
  - `home`: folder `codeo-home`, on `main`, no lock.
  - `issue:70`: folder `codeo-70`, lock `issue:   70`, on a feature branch.
  - `stale:67`: folder `codeo-67`, no lock, on `main`; and the same on a feature branch.
  - `stale:?`: folder `codeo-home`, no lock, on a feature branch.
  - `mismatch:70:codeo-home`: folder `codeo-home` with a lock for 70; and `mismatch:70:codeo-71`.
  - `.codeo/active` with content but no `issue:` line, folder `codeo-67`, on `main`: `stale:67`.
  - `unguarded`: no dockerenv file; `CLAUDE_CODE_REMOTE=true` in a folder `codeo-70`; folder `codeo` with the dockerenv file; folder `other-70`.
  - `--check`: every skill exits 0 on `unguarded`; the four home-only skills exit 0 on `home` and 1 on `issue:70`, `stale:67`, `mismatch:…`; the four lock skills exit 0 on `issue:70` and `home` and 1 on `stale:67` and `mismatch:…`; `doctor` and `setup` exit 2.
- [ ] **Step 2: Run it to verify it fails.** `bash tests/role.test.sh` → fails with `role.sh: No such file` (the first case).
- [ ] **Step 3: Implement `.devcontainer/scripts/role.sh`** with the header-comment style of `container-name.sh`. Take the codename and the lock's number from `container-name.sh` (`--codename`, and `--docker` minus the codename prefix), never re-parse `.codeo/active`.
- [ ] **Step 4: Run it to verify it passes.** `bash tests/role.test.sh` → `all cases passed`; then `bash tests/run.sh` → `all cases passed`.
- [ ] **Step 5: Commit** `feat: add role.sh, the dev container's role check (#70)`; stage `.devcontainer/scripts/role.sh tests/role.test.sh`.

### Task 2: The guard's pin, written red

**Files:**
- Create: `tests/role-guard.test.sh`

**Interfaces:**
- Consumes: `lib/extension-points.tsv`, `skills/<skill>/SKILL.md`, `.codeo/overlays/<skill>.md`.
- Produces: the test the engineer's "a test fails if any of the four stops declaring or calling the check" asks for.

For each of `issue init triage cleanup plan implement qc close` it asserts: the registry has a `<skill>	role-guard` row; the skill carries `<!-- point: <skill>/role-guard -->` exactly once and one `<!-- rule: <skill>-NN -->` marker whose paragraph says there is no override; `bash scripts/overlay.sh <skill> role-guard` exits 0 and its text contains `role.sh --check <skill>`; and the text ends the skill's step when the check exits 1 (contains `stop`). For `doctor` and `setup` it asserts the opposite: no `role-guard` row, no marker. A scratch-copy case deletes the marker from a copy of `skills/issue/SKILL.md` and checks the test's own function reports it.

- [ ] **Step 1: Write the test** as above.
- [ ] **Step 2: Run it to verify it fails.** `bash tests/role-guard.test.sh` → fails first on `issue: no role-guard row in lib/extension-points.tsv`. It stays red until Tasks 3, 5 and 7 are done; do not run `tests/run.sh` as a proof for this task, and do not commit it alone: it is committed with Task 3.

### Task 3: The guard in the seven existing skills

**Files:**
- Modify: `lib/extension-points.tsv`, `skills/{issue,init,triage,plan,implement,qc,close}/SKILL.md`, `docs/extension-points.md`, `docs/skills.md` (each skill's `### Extension points`), `docs/skills-inventory.md`, `tests/inventory.test.sh` (the `want` counts: issue 8, init 10, plan 9, implement 10, qc 14, close 14, triage 10), `tests/fixtures/skills-inventory.rules.sha256`
- Test: `tests/skills.test.sh`, `tests/skills-doc.test.sh`, `tests/inventory.test.sh`

**Interfaces:**
- Consumes: Task 2's test.
- Produces: registry rows `<skill>	role-guard	None; the skill runs wherever it is invoked.` for the seven skills; in each skill a step `0`-adjacent paragraph that fetches the point, and the rules `issue-08 init-10 triage-10 plan-09 implement-10 qc-14 close-14`.

The step goes in the skill's step 0 (`issue`, `init`, `triage`) or immediately before it (`plan`, `implement`, `qc`, `close`, whose step 0 reads the lock, so the role check runs first). Its text, the same in all seven with the skill's name filled in: fetch `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" <skill> role-guard`; on exit 0 follow the printed text, which runs the project's role check; when the check refuses, print its one line and stop, with no override and nothing else done; on exit 3 there is no guard and the step runs as it did; on exit 1, 2 or 4 report the one `codeo:` line and carry on unguarded. The rule paragraph under the `rule` marker: "A refusal from the role check ends the step. The engineer's words do not lift it; the way forward is the container the message names." In `docs/extension-points.md` each point has the standard sections (**Where**, **May rely on**, **Expected back**, **Default when absent**, **Example**); *Expected back* is "text that runs the project's role check for this skill and tells the skill to stop on its refusal".

- [ ] **Step 1: Run the red tests.** `bash tests/skills.test.sh` and `bash tests/role-guard.test.sh` → the latter still fails (no overlays yet); the former passes before the edits.
- [ ] **Step 2: Add the registry rows, the `docs/extension-points.md` sections and the `docs/skills.md` bullets** (`- \`<skill>/role-guard\` — None; the skill runs wherever it is invoked. ([detail](extension-points.md#<skill>role-guard))`).
- [ ] **Step 3: Add the step, marker and rule paragraph to each of the seven skills,** and one bullet `- [<skill>-NN] A refusal from the role check ends the step; no override.` at the end of each skill's section in `docs/skills-inventory.md`; update the `want` counts in `tests/inventory.test.sh`; run `bash tests/inventory.test.sh --update`.
- [ ] **Step 4: Run.** `bash tests/skills.test.sh`, `bash tests/skills-doc.test.sh`, `bash tests/inventory.test.sh` → each `all cases passed`. `bash tests/role-guard.test.sh` still fails, now on the missing overlay text only.
- [ ] **Step 5: Commit** `feat: a role-guard point in the seven skills that need one (#70)`, naming in the body that the inventory fixture changed because seven rules were added; stage by name, including Task 2's test.

### Task 4: A call to `/codeo:issue` from an issue container

**Files:**
- Modify: `skills/plan/SKILL.md` (the `plan-03` paragraph), `skills/implement/SKILL.md`, `skills/qc/SKILL.md` (each place that "calls `/codeo:issue`"), `docs/handoff.md` → *A call is not a hand-off*
- Test: `tests/plan-skill.test.sh`, `tests/implement-skill.test.sh`, `tests/qc-skill.test.sh`

**Interfaces:**
- Produces: the sentence each caller carries — **"When the project's role check refuses the call (the skill is running in an issue container), record the finding in this skill's own dossier and say to file it with `/codeo:issue` in the home container; `/codeo:triage` finds recorded findings later."** — and the same sentence in `docs/handoff.md`.

This is a call made by the plan, not an engineer decision: the guard is strict (Q2), so an issue container cannot file. It is flagged here so the engineer sees it at the approval gate.

- [ ] **Step 1: Write the failing test** in each of the three skill tests: the skill text contains `record the finding in this skill's own dossier` and `in the home container`. Run `bash tests/plan-skill.test.sh` → fails with that needle missing.
- [ ] **Step 2: Add the sentence** to the three skills and to `docs/handoff.md` (after "A call is not a hand-off"'s first paragraph).
- [ ] **Step 3: Run** the three tests, then `bash tests/run.sh` → `all cases passed`.
- [ ] **Step 4: Commit** `feat: callers record a finding the home-only guard refuses to file (#70)`.

### Task 5: This repository's overlays for the guard

**Files:**
- Create: `.codeo/overlays/{issue,triage,plan,implement,qc,close}.md`
- Modify: `.codeo/overlays/init.md`

**Interfaces:**
- Consumes: Task 1's `role.sh --check`; Task 3's points.
- Produces: in each overlay a section `## role-guard` whose body is, with `<skill>` filled in: "Run `bash .devcontainer/scripts/role.sh --check <skill>` from the project root. Exit 0: go on. Exit 1: print its one line to the engineer and stop; that is the whole answer and nothing in this session lifts it. Exit 2: report its `role:` line and go on." Each new file starts with the precedence sentence as a comment, as `init.md` does. `init.md` keeps its `host-workflow` section and gains this one after it.

- [ ] **Step 1: Run the red test.** `bash tests/role-guard.test.sh` → fails on the first overlay (`issue: overlay.sh issue role-guard exited 3`).
- [ ] **Step 2: Write the six files and add the section to `init.md`.**
- [ ] **Step 3: Run.** `bash tests/role-guard.test.sh` still fails, now only on `cleanup`; `bash tests/init-overlay.test.sh` and `bash tests/overlay.test.sh` pass; `bash scripts/doctor.sh` reports `overlays` ok.
- [ ] **Step 4: Commit** `feat: the project's role-guard overlays (#70)`.

### Task 6: The cleanup script

**Files:**
- Create: `scripts/cleanup.sh`
- Test: `tests/cleanup.test.sh`

**Interfaces:**
- Consumes: `scripts/github.sh issue view|pr view`, `scripts/overlay.sh cleanup removal-command`, `git ls-tree`, `git ls-remote`, `git for-each-ref`.
- Produces: `cleanup.sh` fetches `origin` with `--prune`, lists the `.codeo/done/<N>` directories on `origin/<baseBranch>` in ascending `N`, and prints one tab-separated line per issue: `<N>\tproven\t<command>` (`<command>` is `-` when the overlay gives none) or `<N>\tfailed\t<proof>`, where `<proof>` is the first that failed, in this order: `issue` (state is not `closed`) · `pull-request` (`close.md` records no `#<number> <url>` line, or the PR's `merged_at` is empty) · `branch` (the PR's head branch is still on `origin`) · `dossier` (any `refs/remotes/origin/*` ref other than `HEAD` still has a `.codeo/<N>/` directory; `.codeo/done/<N>/` does not count) · `name` (the overlay's name template, pattern or command is missing, or the expanded name does not match the pattern). It runs no `docker` command. The overlay body is three lines: `name: <template with {N}>`, `pattern: <extended regex>`, `command: <template with {name}>`.

- [ ] **Step 1: Write the failing test** `tests/cleanup.test.sh`, on a scratch `origin` bare repo plus clone and a stubbed `gh` as `tests/github.test.sh` does. Cases, each asserting the exact lines printed: an issue passing all four proofs prints `proven` with `docker rm -f codeo-12; docker volume rm codeo-12` (the overlay in the fixture supplies the three lines); one case per proof failing, each printing `failed` with that proof's name and no command, the earlier proofs passing; `close.md` without a pull request line → `failed pull-request`; a template expanding to `codeo-home`, `codeo-gh` and `codeo-git` in turn → `failed name` and no command; an overlay with no `pattern:` line → `failed name`; no overlay at all (exit 3) → `proven` with `-`; a stub `docker` on `PATH` that writes a marker file, asserting the marker is never written; output lines are in ascending `N`.
- [ ] **Step 2: Run it to verify it fails.** `bash tests/cleanup.test.sh` → fails with `scripts/cleanup.sh: No such file`.
- [ ] **Step 3: Implement `scripts/cleanup.sh`** in the style of `scripts/inflight.sh` (header comment, `source lib/env.sh`, one `die`). The name check is the last proof and the only place a command is built.
- [ ] **Step 4: Run.** `bash tests/cleanup.test.sh` and then `bash tests/run.sh` → `all cases passed`.
- [ ] **Step 5: Commit** `feat: scripts/cleanup.sh proves finished issues and prints, never runs (#70)`.

### Task 7: The `/codeo:cleanup` skill

**Files:**
- Create: `skills/cleanup/SKILL.md`, `.codeo/overlays/cleanup.md`
- Modify: `lib/extension-points.tsv` (`cleanup	role-guard` and `cleanup	removal-command	None; the proven issues are listed and no command is printed.`), `docs/extension-points.md`, `docs/skills.md` (a `## cleanup` section with the four sub-headings, the intro paragraph, the Mermaid chart), `docs/skills-inventory.md` (a `## cleanup` section, `cleanup-01`…`cleanup-04`), `tests/inventory.test.sh` (add `cleanup` to the `want` map as 4, to the loop and to the awk heading regex), `tests/fixtures/skills-inventory.rules.sha256`, `docs/handoff.md` (the closing-block table row for `cleanup`)
- Test: `tests/skills.test.sh`, `tests/skills-doc.test.sh`, `tests/inventory.test.sh`, `tests/closing-block.test.sh`, `tests/role-guard.test.sh`, `tests/cleanup-skill.test.sh`

**Interfaces:**
- Consumes: `scripts/cleanup.sh` (Task 6), the `role-guard` point.
- Produces: the skill (frontmatter `model: sonnet`, description starting "Print the commands that remove finished issues' dev containers…", triggers "clean up containers", "what can I remove", "cleanup") with this workflow: `0` role guard (`cleanup-01`, no override) · `1` run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup.sh"` and relay its lines verbatim as two lists, *proven* with the command and *not proven* with the failed proof and no command · `2` always say that unpushed work in a clone is invisible from here, that the commands rely on `close.md` having recorded a clean tree with the tip equal to the pull request's head, and that the commands run on the host, in a shell, after `git status` in that clone · `3` record what was printed under `.codeo/intake/cleanup/<YYYY-MM-DD>.md` through `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" commit cleanup "<message>"` · `4` the closing block. Rules: `cleanup-02` print a removal command only for an issue the script proved · `cleanup-03` never run a container command, and never mount or ask for the Docker socket · `cleanup-04` print only what the script printed, never build a name or a command in the skill. `.codeo/overlays/cleanup.md` carries `## role-guard` (as Task 5) and `## removal-command` with `name: codeo-{N}`, `pattern: ^codeo-[0-9]+$`, `command: docker rm -f {name}; docker volume rm {name}`.

- [ ] **Step 1: Write the failing test** `tests/cleanup-skill.test.sh`: the skill text contains `cleanup.sh`, `git status`, `unpushed work`, `intake.sh" commit cleanup`; it contains no `docker` anywhere in `skills/cleanup/SKILL.md`; the overlay's `removal-command` text, run through `scripts/cleanup.sh`'s name check, rejects `codeo-home`, `codeo-gh`, `codeo-git` and `codeo-` and accepts `codeo-70`. Run `bash tests/cleanup-skill.test.sh` → fails: `skills/cleanup/SKILL.md: No such file`.
- [ ] **Step 2: Write the skill, the overlay, the registry rows and the docs entries** above.
- [ ] **Step 3: Run.** `bash tests/cleanup-skill.test.sh tests/role-guard.test.sh tests/skills.test.sh tests/skills-doc.test.sh tests/inventory.test.sh tests/closing-block.test.sh` one by one, each `all cases passed`; then `bash tests/run.sh`.
- [ ] **Step 4: Commit** `feat: /codeo:cleanup, a print-only skill (#70)`, naming the changed inventory fixture.

### Task 8: `/codeo:close` prints the removal commands

**Files:**
- Modify: `skills/close/SKILL.md` (step 17, the `host: container` default), `.codeo/overlays/close.md` (a `## host-workflow` section)
- Test: `tests/close-removal.test.sh`

**Interfaces:**
- Consumes: the lock's `volume:` line; the overlay point `close/host-workflow`, already registered.
- Produces: the generic default for `host: container` says the container's commands run **on the host, not inside this container**, and to run `git status` in that clone first; the overlay's body is: "Print `docker rm -f <volume>; docker volume rm <volume>`, with `<volume>` the lock's `volume:` line, only when that line matches `^codeo-[0-9]+$`; for any other value, including `unknown`, print no command and say to find the container with `docker ps` on the host."

- [ ] **Step 1: Write the failing test** `tests/close-removal.test.sh`: `bash scripts/overlay.sh close host-workflow` exits 0 and contains `docker rm -f <volume>; docker volume rm <volume>`, `^codeo-[0-9]+$`, `unknown`; `skills/close/SKILL.md` contains `on the host` and `git status`. Run it → fails with `overlay.sh close host-workflow exited 3`.
- [ ] **Step 2: Edit** the skill's `host: container` bullet and write the overlay section.
- [ ] **Step 3: Run** `bash tests/close-removal.test.sh`, `bash tests/close-skill.test.sh`, `bash tests/closing-exits.test.sh`, then `bash tests/run.sh`.
- [ ] **Step 4: Commit** `feat: /codeo:close prints the host commands that remove its container (#70)`.

### Task 9: Documentation

**Files:**
- Modify: `.devcontainer/README.md`, `docs/handoff.md`, `README.md`, `CHANGELOG.md`, `docs/skills-inventory.md` (the intro, which names "the seven skills")
- Test: `tests/devcontainer.test.sh`, `tests/skills-doc.test.sh`

What each must say afterwards:
- `.devcontainer/README.md`: the table's last row reads `/codeo:issue`, `/codeo:init`, `/codeo:triage`, `/codeo:cleanup` for home and `/codeo:plan` through `/codeo:close` for an issue container, with a line that `doctor` and `setup` run in either. A new section **Roles and the guard** with the roles table from Task 1, the Q1 rule (when the guard applies and when it does not), the refusal each role gets, and that `role.sh --check` is what each skill's overlay runs. A **Removing a finished container** section: what `/codeo:close` prints, that `/codeo:cleanup` lists the rest, that both only print and run on the host after `git status`.
- `docs/handoff.md`: *The lock* gains a paragraph on the roles and the guard, stating the guard is the project's and applies only in its dev container; the closing-block table has the `cleanup` row (next goal: the removal commands run on the host, then the next issue, `/codeo:init #<N>`).
- `README.md`: the Skills table row for `/codeo:cleanup`; the sentence that lists which skills run where.
- `docs/skills-inventory.md`: the intro names eight skills.
- `CHANGELOG.md`: a bullet under `## Unreleased`, "Nothing in `lib/`, `hooks/` changes; `scripts/` gains `cleanup.sh`; `skills/` gains `cleanup` and a `role-guard` step in eight skills (#70)", stating the shared-state and config-schema lines remain unchanged. Merge `origin/main` first and keep every existing bullet.

- [ ] **Step 1: Write the edits.**
- [ ] **Step 2: Run** `bash tests/devcontainer.test.sh` (proves the Dockerfile and `devcontainer.json` are untouched: `git diff --stat origin/main -- .devcontainer/Dockerfile .devcontainer/devcontainer.json` prints nothing), `bash tests/skills-doc.test.sh`, then `bash tests/run.sh` → `all cases passed`.
- [ ] **Step 3: Commit** `docs: the roles, the guard and the removal commands (#70)`.

### Task 10: The whole check

**Files:** none.

- [ ] **Step 1: Run** `bash tests/run.sh` → `all cases passed`; `bash scripts/doctor.sh` → every line `ok`; `git diff --stat origin/main -- .devcontainer/Dockerfile .devcontainer/devcontainer.json` → empty; `grep -rn 'codeo-home\|codeo-gh\|codeo-git\|docker ' skills scripts lib docs` → matches only in prose that says what *not* to do (none expected in `skills/` and `scripts/`).
- [ ] **Step 2: Try the guard by hand** in this container: `bash .devcontainer/scripts/role.sh` prints `issue:70`; `bash .devcontainer/scripts/role.sh --check init; echo $?` prints a refusal line and `1`; `CLAUDE_CODE_REMOTE=true bash .devcontainer/scripts/role.sh --check init; echo $?` prints `0`.

---

## Self-review

- **Spec coverage:** criterion 1 → Task 1 · 2 → Tasks 2, 3, 5, 7 · 3 → Tasks 1, 3, 5 · 4 → Task 1 (`unguarded`) · 5 → Task 8 · 6 → Tasks 6, 7 · 7 → Tasks 6, 7, 9 (`tests/devcontainer.test.sh`) · 8 → Tasks 3, 7, 9, 10. Key Requirement "records what it printed in a dossier on the intake branch" → Task 7 step 3.
- **Consistency:** `role.sh --check <skill>` and the eight skill names are the same in Tasks 1, 2, 5 and 7; the overlay body keys `name:` `pattern:` `command:` are the same in Tasks 6 and 7; rule IDs are `<skill>-NN` with the NN the next free number (issue-08, init-10, triage-10, plan-09, implement-10, qc-14, close-14, cleanup-01 to 04).
- **Proportion:** ten tasks, one pull request (Q6). Tasks 3 and 7 are the largest; each is one deliverable (a lint-green set of skills).

## Documentation the change moves

`.devcontainer/README.md`, `docs/skills.md`, `docs/extension-points.md`, `docs/skills-inventory.md`, `docs/handoff.md`, `README.md`, `CHANGELOG.md` — all in Tasks 3, 7 and 9.

---

## Round 2 — send-back from QC round 1

QC round 1 (`.codeo/70/qc.md`) found every acceptance criterion met and the suite green, and two blocking findings in the plan itself: **F1**, a finished `/codeo:close` names `/codeo:triage` as its first step in a container that has just become stale, where the guard refuses it; **F2**, a finding the guard refuses to file is "recorded in the dossier" in no stated form, while `/codeo:triage` collects only certain forms. The engineer's answer to Q7 takes in the cheap non-blocking findings too: F4, F5, F6, F7, F8, F10, F13. F9 (Podman), F11 (`CODEO_CLEANUP_REMOVAL` in the production path) and F12 (generic text saying "home container") are left for `/codeo:triage`.

Round 1's Global Constraints still bind, in particular: no `docker`, `codeo-home`, `codeo-gh` or `codeo-git` under `skills/`, `scripts/`, `lib/` or `docs/`; no text under a `<!-- rule -->` marker changes; `.devcontainer/Dockerfile` and `devcontainer.json` do not change; each task's proof is its test file, then `bash tests/run.sh`, both printing `all cases passed`. The existing fail-open ruling stands: when the role check cannot answer, the skill reports and carries on.

### Task 11: Where a finished close sends the engineer (F1, F7)

**Files:**
- Modify: `skills/close/SKILL.md` (step 17: the `/codeo:triage` suggestion and **Closing block — finished**), `.codeo/overlays/close.md` (`## host-workflow`), `docs/extension-points.md` (`close/host-workflow`, *Expected back*)
- Test: `tests/close-removal.test.sh`, `tests/closing-exits.test.sh`

**Interfaces:**
- Produces, in the skill (generic): the finished exit's first step is `/codeo:triage` **run in the checkout the project's host workflow names for it, when it names one** — this checkout holds no lock any more, and a project's role check may refuse the skill here. With no host workflow, the step is `/codeo:triage` as before.
- Produces, in this repository's overlay: the section opens "When the lock's `host` is `container`:" and keeps the three existing paragraphs under it; adds "For any other host there is nothing to remove: say so."; and adds, for the container case: "This container holds no lock now, so `/codeo:triage` and `/codeo:cleanup` are refused here. Tell the engineer to run them in the home container, `codeo-home`, and make that the closing block's first step."
- `docs/extension-points.md` → `close/host-workflow` → *Expected back* gains: "and, when this checkout can no longer run the follow-up skills, the checkout they run in".

- [ ] **Step 1: Write the failing assertions.** In `tests/close-removal.test.sh`: the overlay output contains `When the lock's \`host\` is \`container\``, `nothing to remove`, `/codeo:triage`, `/codeo:cleanup` and `home container`; the skill's **Closing block — finished** paragraph contains `the checkout the project's host workflow names`. In `tests/closing-exits.test.sh`, keep the existing finished-exit assertions (`/codeo:triage` present) and add the same needle for the paragraph it already slices.
- [ ] **Step 2: Run** `bash tests/close-removal.test.sh` → fails with `overlay output lacks: When the lock's`.
- [ ] **Step 3: Edit** the skill, the overlay and the docs section.
- [ ] **Step 4: Run** `bash tests/close-removal.test.sh`, `bash tests/closing-exits.test.sh`, `bash tests/close-skill.test.sh`, `bash tests/skills.test.sh close`, `bash tests/skills-doc.test.sh`, then `bash tests/run.sh`.
- [ ] **Step 5: Commit** `fix: a finished close names the checkout its follow-up skills run in (#70)`.

### Task 12: A refused finding is recorded where triage looks (F2)

**Files:**
- Modify: `skills/plan/SKILL.md`, `skills/implement/SKILL.md`, `skills/qc/SKILL.md`, `docs/handoff.md` (the one sentence round 1's Task 4 added, in each)
- Test: `tests/plan-skill.test.sh`, `tests/implement-skill.test.sh`, `tests/qc-skill.test.sh`

**Interfaces:**
- Produces: the sentence, replacing the round-1 one in all four places, verbatim: **"When the project's role check refuses the call (the skill is running in an issue container), record the finding in this skill's own dossier as a line under `## Notes` that promises the later work and carries no issue number — the form `/codeo:triage` collects once the dossier is archived — and say to file it with `/codeo:issue` in the home container."**

Why this form: `skills/triage/SKILL.md` collects, from `.codeo/done/*/` on the base branch, "any `## Outcome` or `## Notes` line promising later work without an issue number next to it". `qc.md` findings and `implement.md` deviations are collected anyway; the `## Notes` line is the one form that works in all three dossiers, `plan.md` included.

- [ ] **Step 1: Write the failing assertions**: each of the three skill tests requires `as a line under \`## Notes\`` and `carries no issue number`, beside the two needles they already have.
- [ ] **Step 2: Run** `bash tests/plan-skill.test.sh` → fails on the new needle.
- [ ] **Step 3: Replace the sentence** in the three skills and `docs/handoff.md`; no text under a `rule` marker changes.
- [ ] **Step 4: Run** the three tests and `bash tests/inventory.test.sh` (the pinned hash must be unchanged), then `bash tests/run.sh`.
- [ ] **Step 5: Commit** `fix: a finding the guard refuses to file is recorded as a Notes line triage collects (#70)`.

### Task 13: Small script and skill corrections (F4, F5, F13)

**Files:**
- Modify: `scripts/github.sh` (the usage line at the end), `scripts/cleanup.sh` (the issue proof), `skills/cleanup/SKILL.md` (step 4)
- Test: `tests/github.test.sh`, `tests/cleanup.test.sh`, `tests/cleanup-skill.test.sh`

**Interfaces:**
- `github.sh`'s usage message lists `pr list-for-branch|view|get|reviews|…`, as its header does.
- `cleanup.sh`: a failed `github.sh issue view <N>` stops the script with `cleanup: could not read issue #<N>`, exit non-zero, as a failed `pr get` already does; an issue that is read and is not `closed` still prints `<N>\tfailed\tissue`.
- `skills/cleanup/SKILL.md` step 4: "step 2 `/codeo:init #<M>`, `<M>` being the next issue to start" (`<N>` stays the finished issue everywhere else in the skill).

- [ ] **Step 1: Write the failing tests**: `tests/github.test.sh`, an unknown verb's usage line contains `view|get|reviews`; `tests/cleanup.test.sh`, a case where the stubbed `gh` fails the issue read: exit non-zero, stderr `cleanup: could not read issue #12`, no `proven` and no `failed` line on stdout; `tests/cleanup-skill.test.sh`, the skill contains `/codeo:init #<M>` and no `/codeo:init #<N>`.
- [ ] **Step 2: Run** `bash tests/cleanup.test.sh` → fails: the case prints `12\tfailed\tissue`.
- [ ] **Step 3: Implement** the three changes.
- [ ] **Step 4: Run** the three tests, `bash tests/skills.test.sh cleanup`, then `bash tests/run.sh`.
- [ ] **Step 5: Commit** `fix: cleanup stops on an unreadable issue, github.sh usage names pr get (#70)`.

### Task 14: What the guard says, and what it does on any other exit (F6, F10)

**Files:**
- Modify: `.devcontainer/scripts/role.sh` (the two `stale:*` refusal lines), `.codeo/overlays/{issue,init,triage,cleanup,plan,implement,qc,close}.md` (`## role-guard`), `.devcontainer/README.md` (the `stale` row of the roles table, and the line on `--check`'s exits)
- Test: `tests/role.test.sh`, `tests/role-guard.test.sh`

**Interfaces:**
- `stale:<N>` refusal, one line: `/codeo:<skill> can't run here: this container's workflow for issue #<N> has ended (finished, stashed or abandoned), or its start script took no lock (role stale:<N>); <where>.` `<where>` for a home-only skill: `run it in the home container`. For a lock skill: `if this is still issue #<N>'s container, re-run bash .devcontainer/scripts/devcontainer-start.sh to take the lock; otherwise it is done, and the skill runs in the container of the issue it is for`.
- `stale:?` refusal: same shape without the number (`this clone is on a branch other than the base branch with no lock, so its workflow has ended (finished, stashed or abandoned) or never took a lock (role stale:?)`).
- Both lines keep the word `finished`, the role, and `#<N>` where there is one (criterion 3 and the existing needles).
- Each overlay's `## role-guard` body ends, after the exit 2 sentence: "Any other exit (the script is missing, or failed): report what it printed and go on."

- [ ] **Step 1: Write the failing assertions**: `tests/role.test.sh`, the stale refusals contain `stashed or abandoned`, and for a lock skill `devcontainer-start.sh`, for a home-only skill `home container`; `tests/role-guard.test.sh`, each overlay's text contains `Any other exit`.
- [ ] **Step 2: Run** `bash tests/role.test.sh` → fails on `stashed or abandoned`.
- [ ] **Step 3: Implement** the script lines, the eight overlay sentences and the README row.
- [ ] **Step 4: Run** `bash tests/role.test.sh`, `bash tests/role-guard.test.sh`, `bash tests/devcontainer.test.sh`, `bash scripts/doctor.sh` (overlays ok), then `bash tests/run.sh`.
- [ ] **Step 5: Commit** `fix: the stale refusal covers a stashed workflow and names the recovery (#70)`.

### Task 15: Documentation (F1, F8)

**Files:**
- Modify: `.devcontainer/README.md`, `CHANGELOG.md`
- Test: `tests/devcontainer.test.sh`, `tests/agnostic.test.sh`

What each says afterwards:
- `.devcontainer/README.md`, *Removing a finished container*: after `/codeo:close` finishes, the container holds no lock and is `stale`, so `/codeo:triage` and `/codeo:cleanup` run in the home container; the removal commands are printed only for a container-hosted workflow. *Roles and the guard*: a container whose clone lacks the role script and the overlays (one created from a branch cut before the guard existed) is not guarded; it runs every skill as before until it is removed.
- `CHANGELOG.md`: the `## Unreleased` bullet for this change gains the same two facts (where the follow-up skills run after a close; older containers stay unguarded) and "a refused finding is recorded as a `## Notes` line". No other bullet changes.

- [ ] **Step 1: Write the edits** (present tense, no issue numbers in the README).
- [ ] **Step 2: Run** `bash tests/devcontainer.test.sh`, `bash tests/agnostic.test.sh`, then `bash tests/run.sh`; `git diff --stat origin/main -- .devcontainer/Dockerfile .devcontainer/devcontainer.json` prints nothing.
- [ ] **Step 3: Commit** `docs: where the follow-up skills run after a close, and which containers the guard covers (#70)`.

### Task 16: The whole check

- [ ] **Step 1: Run** `bash tests/run.sh` → `all cases passed`; `bash scripts/doctor.sh` → every line `ok`.
- [ ] **Step 2: By hand, in this container:** `bash .devcontainer/scripts/role.sh --check triage` exits 1 naming `issue:70`; `bash scripts/overlay.sh close host-workflow` prints the home-container sentence.

### Round 2 self-review

- **Coverage.** F1 → Tasks 11 and 15 · F2 → Task 12 · F4, F5, F13 → Task 13 · F6, F10 → Task 14 · F7 → Task 11 · F8 → Task 15. F3 (`scripts/github.sh` outside the footprint) → the footprint gains `scripts/github.sh`. F9, F11, F12 → left in `qc.md` for `/codeo:triage`.
- **Documentation the round moves.** `.devcontainer/README.md`, `docs/extension-points.md`, `docs/handoff.md`, `CHANGELOG.md`. `docs/skills.md`, `docs/skills-inventory.md` and `README.md` need nothing: none states the sentences or rows changed here.
- **Consistency.** The F2 sentence is identical in four files; the "Any other exit" sentence is identical in eight overlays; no rule text and no inventory bullet changes, so the pinned hash stays.

---

## Round 3 — send-back from QC round 2

QC round 2 (`.codeo/70/qc.md`) found round 2's fixes in place, the suite green and every criterion met, and two new blocking findings in the plan's own wording. **G1:** round 2's Task 14 made the stale refusal tell a lock skill to re-run the start script, and `lock.sh take` binds from the branch's `init.md` without looking for a stash or an abandon, so the advice revives a parked workflow with no claim and no board move. **G2:** `skills/cleanup/SKILL.md` says its commands rely on `close.md` having recorded a clean tree, a record that never reaches `origin/<base>`, and `cleanup.sh` lists as proven an issue whose `/codeo:close` never finished. The engineer's answers: Q8 detect the state from the clone's dossier; Q9 add a `lease` proof and correct the caveat; Q10 fix all of G3-G7 too.

Rounds 1 and 2's Global Constraints still bind: no `docker`, `codeo-home`, `codeo-gh` or `codeo-git` under `skills/`, `scripts/`, `lib/` or `docs/`; no text under a `<!-- rule -->` marker changes unless a task says so; `.devcontainer/Dockerfile` and `devcontainer.json` do not change; each task's proof is its test file, then `bash tests/run.sh`, both printing `all cases passed`. The roles `role.sh` prints do not change (criterion 1); only the refusal lines do.

### Task 17: The stale refusal reads the clone's own dossier (G1)

**Files:**
- Modify: `.devcontainer/scripts/role.sh` (the `stale:*` refusal), `.devcontainer/README.md` (the `stale` row of the roles table)
- Test: `tests/role.test.sh`

**Interfaces:**
- For `stale:<N>`, `--check` decides one of four states from the clone, in this order, reading `.codeo/` under the clone's root (the state directory is `.codeo`, as `container-name.sh` assumes):
  1. **finished** — `.codeo/done/<N>/` exists.
  2. **parked** — `.codeo/<N>/close.md` exists and its last `### Round <n> — …` heading contains `stashed` or `abandoned` (the headings `claim.sh --stash-live` reads); the word found is used in the message.
  3. **lock lost** — `.codeo/<N>/` exists (a live dossier, no park).
  4. **unknown** — none of the above; also every `stale:?`.
- The one-line refusals, `<skill>` and `<N>` filled in, each ending with the role in the form `(role stale:<N>)`:
  - finished, home-only skill: `/codeo:<skill> can't run here: issue #<N> is finished and this container is done (role stale:<N>); run it in the home container.`
  - finished, lock skill: `/codeo:<skill> can't run here: issue #<N> is finished and this container is done (role stale:<N>); nothing more runs here, and /codeo:cleanup in the home container prints how to remove it.`
  - parked, home-only: `/codeo:<skill> can't run here: issue #<N>'s workflow was <stashed|abandoned> and this container holds no lock (role stale:<N>); run it in the home container.`
  - parked, lock skill: `/codeo:<skill> can't run here: issue #<N>'s workflow was <stashed|abandoned> and this container holds no lock (role stale:<N>); /codeo:init #<N> in the home container is the way back, never the start script.`
  - lock lost, home-only: `/codeo:<skill> can't run here: this is issue #<N>'s container and it holds no lock (role stale:<N>); run it in the home container.`
  - lock lost, lock skill: `/codeo:<skill> can't run here: this is issue #<N>'s container, its workflow is live and it holds no lock (role stale:<N>); re-run bash .devcontainer/scripts/devcontainer-start.sh to take the lock.`
  - unknown and `stale:?`, home-only: `/codeo:<skill> can't run here: this clone holds no lock and no dossier says why (role <role>); run it in the home container.`
  - unknown and `stale:?`, lock skill: `/codeo:<skill> can't run here: this clone holds no lock and no dossier says why (role <role>); the skill runs in the container of the issue it is for.`
- `issue:`, `mismatch:` and `home` refusals do not change. Exit codes do not change.

- [ ] **Step 1: Write the failing cases** in `tests/role.test.sh`, each a `codeo-67` clone with no lock: with `.codeo/done/67/` → both kinds of skill get `is finished`, a lock skill gets `/codeo:cleanup` and no `devcontainer-start.sh`; with `.codeo/67/close.md` ending `### Round 2 — stashed` → `was stashed`, a lock skill gets `/codeo:init #67` and `never the start script`, and no `re-run`; the same with `— abandoned` → `was abandoned`; with `.codeo/67/init.md` only → a lock skill gets `re-run bash .devcontainer/scripts/devcontainer-start.sh`, and the line does not contain `finished`; with no dossier, and for `stale:?` → `no dossier says why`. A `close.md` whose last round is `— pull request opened` after an earlier `— stashed` round is **lock lost**, not parked. Every refusal is one line and names the role. Replace the round-2 needles (`finished` on every stale refusal, `stashed or abandoned`) with these.
- [ ] **Step 2: Run** `bash tests/role.test.sh` → fails on the first new case (`is finished` missing).
- [ ] **Step 3: Implement** the state detection and the eight lines; update the README's `stale` row to say that the refusal names what happened to the workflow (finished, stashed, abandoned, or a lost lock) and the way back for each.
- [ ] **Step 4: Run** `bash tests/role.test.sh`, `bash tests/role-guard.test.sh`, `bash tests/devcontainer.test.sh`, then `bash tests/run.sh`.
- [ ] **Step 5: Commit** `fix: the stale refusal reads the dossier and never offers the start script for a parked workflow (#70)`.

### Task 18: Cleanup proves the workflow let go of its leases, and says what it cannot see (G2, G4, G7)

**Files:**
- Modify: `scripts/cleanup.sh`, `skills/cleanup/SKILL.md` (step 1's list of proofs, step 2's caveats, the Hand-off's "never touches" line)
- Test: `tests/cleanup.test.sh`, `tests/cleanup-skill.test.sh`

**Interfaces:**
- A fifth proof, `lease`, after `dossier` and before `name`: `cleanup.sh` runs `intake.sh lease list --tsv` once, after the fetch; a failure stops the script with `cleanup: could not read the leases`. An issue whose number is the third field of any line (`held` or `waiting`) prints `<N>\tfailed\tlease`. Proof order: `issue` · `pull-request` · `branch` · `dossier` · `lease` · `name`.
- The `branch` proof fails (`<N>\tfailed\tbranch`) when the pull request's `head_ref` is empty or `null`.
- The skill's step 1 lists the five proofs. Step 2's third caveat is replaced, verbatim, by: **"Nothing `origin` holds records whether a clone was left clean, or whether `/codeo:close` ran to its end there: the lock lives only in that clone. A lease the issue still holds is the one trace this proof can see, and it lists the issue as not proven."** The sentence about `close.md` having recorded a clean tree is removed. The Hand-off line reads "any branch other than `codeo/intake`".

- [ ] **Step 1: Write the failing cases** in `tests/cleanup.test.sh`: a lease held by issue 12 on the scratch intake branch → `12\tfailed\tlease`; a wait recorded for issue 12 → the same; no intake branch at all → the issue is still `proven`; a pull request whose stubbed `head.ref` is `null` → `12\tfailed\tbranch`. In `tests/cleanup-skill.test.sh`: the skill contains `the lock lives only in that clone` and `any branch other than \`codeo/intake\``, and does not contain `recorded a clean tree`.
- [ ] **Step 2: Run** `bash tests/cleanup.test.sh` → fails: the lease case prints `12\tproven\t…`.
- [ ] **Step 3: Implement.** Build the scratch lease the way `tests/intake-lease.test.sh` does, or by committing `.codeo/intake/leases/<resource>.md` on the scratch origin's `codeo/intake` branch.
- [ ] **Step 4: Run** the two tests, `bash tests/skills.test.sh cleanup`, then `bash tests/run.sh`.
- [ ] **Step 5: Commit** `fix: cleanup lists an issue that still holds a lease as not proven, and drops a caveat that was untrue (#70)`.

### Task 19: Close's last report agrees with itself (G3, G5, G6)

**Files:**
- Modify: `.codeo/overlays/close.md` (`## host-workflow`), `skills/close/SKILL.md` (step 17, the "nothing is lost" sentence), `docs/handoff.md` (the `cleanup` row of the closing-block table)
- Test: `tests/close-removal.test.sh`, `tests/cleanup-skill.test.sh`

**Interfaces:**
- Overlay: the home-container paragraph begins "After a finished close (the pull request merged), …" and ends "On a stash or an abandon, keep the closing block the skill gives for that exit."
- Skill, step 17, replacing "everything in it is merged or on origin, so nothing is lost either way": **"everything the workflow committed is merged or on origin; anything left uncommitted or unpushed in the checkout is not, which is why the host workflow's clean-up asks for `git status` first."** No text under a `rule` marker changes.
- `docs/handoff.md`: the `cleanup` row's next goal names `/codeo:init #<M>`, as the skill does.

- [ ] **Step 1: Write the failing assertions**: `tests/close-removal.test.sh`, the overlay output contains `After a finished close` and `On a stash or an abandon`, and the skill does not contain `nothing is lost either way`; `tests/cleanup-skill.test.sh`, the `cleanup` row of `docs/handoff.md` contains `#<M>` and no `#<N>`.
- [ ] **Step 2: Run** `bash tests/close-removal.test.sh` → fails on `After a finished close`.
- [ ] **Step 3: Edit** the three files.
- [ ] **Step 4: Run** the two tests, `bash tests/closing-exits.test.sh`, `bash tests/close-skill.test.sh`, `bash tests/closing-block.test.sh`, then `bash tests/run.sh`.
- [ ] **Step 5: Commit** `fix: close's last report says what is and is not safe, and the overlay's next step is for a finished close only (#70)`.

### Task 20: Documentation

**Files:**
- Modify: `.devcontainer/README.md`, `docs/skills.md` (the `## cleanup` section), `README.md` (only if it states the number of proofs), `CHANGELOG.md`
- Test: `tests/skills-doc.test.sh`, `tests/devcontainer.test.sh`, `tests/agnostic.test.sh`

What each says afterwards:
- `.devcontainer/README.md`, *Roles and the guard*: a stale container's refusal says what happened to its workflow and the way back: a finished one is done and is removed; a stashed or abandoned one is resumed through `/codeo:init #<N>` in the home container, never by re-running the start script; a live one that lost its lock re-runs the start script. *Removing a finished container*: `/codeo:cleanup` proves five things, the fifth being that the issue holds no lease.
- `docs/skills.md`, `## cleanup`: five proofs, named; what the proof cannot see, as Task 18's sentence says it.
- `CHANGELOG.md`: the existing `## Unreleased` bullet for this change, extended in place: the stale refusal's three ways back; the `lease` proof; a missing head branch name fails the branch proof.
- Every place in the tree outside `docs/plans/` and `.codeo/` that says "four proofs" says five (`grep -rn 'four proofs'`).

- [ ] **Step 1: Write the edits** (present tense, no issue numbers outside the CHANGELOG).
- [ ] **Step 2: Run** the three tests, then `bash tests/run.sh`; `git diff --stat origin/main -- .devcontainer/Dockerfile .devcontainer/devcontainer.json` prints nothing.
- [ ] **Step 3: Commit** `docs: a stale container's ways back, and cleanup's fifth proof (#70)`.

### Task 21: The whole check

- [ ] **Step 1: Run** `bash tests/run.sh` → `all cases passed`; `bash scripts/doctor.sh` → every line `ok`.
- [ ] **Step 2: By hand:** in a scratch clone named `codeo-67` with a `close.md` ending `— stashed` and `CODEO_DOCKERENV` pointing at an existing file, `role.sh --check plan` prints the `/codeo:init #67` line and exits 1.

### Round 3 self-review

- **Coverage.** G1 → Tasks 17 and 20 · G2 → Tasks 18 and 20 · G3, G5, G6 → Task 19 · G4, G7 → Task 18. G8 (round 1's F9, F11, F12) stays with `/codeo:triage`, as answered at Q7.
- **Criteria.** Criterion 3 asks for "a message naming the finished issue" in a stale container: the finished state says `issue #<N> is finished`; a parked or lock-lost container is not a finished issue, and its line names the issue and what did happen. Criterion 6 says "all four proofs": the four stay, and a fifth is added; a command is still printed only when every proof passes.
- **Documentation the round moves.** `.devcontainer/README.md`, `docs/skills.md`, `docs/handoff.md`, `CHANGELOG.md`, and `README.md` only where it counts the proofs. `docs/extension-points.md` and `docs/skills-inventory.md` need nothing: no point and no rule changes.
- **Footprint.** Unchanged from round 2.
