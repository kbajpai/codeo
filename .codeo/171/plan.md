# Issue #171 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/171 |
| Branch | `docs/make-readme-complete-easy-follow` |
| Updated | 2026-11-25 |

## Where this stands

Q1-Q5 are answered, all as recommended. The plan is drafted at `.codeo/171/plan-draft.md` and awaits the engineer's approval; nothing under `docs/plans/` is written before it. Next step: approve, change or reject the draft.

What I found (read at `d93369c`):

- **The README is 518 lines and nine `##` sections**, and `tests/install.test.sh` pins it hard: `t_readme_sections` (`:1445`) requires exactly those nine headings in order; `t_readme_install_blocks_match_the_script` (`:1617`) requires at least 8 fenced `install: release` output blocks in `README.md` and compares each with a stubbed run of `install.sh`; `t_project_scope_writes_the_readme_snippet` (`:1401`) uses the README's first ```` ```json ```` block; `t_readme_links_resolve` (`:1463`) resolves every relative link; `t_readme_names_the_restore_command` and `t_readme_restore_blocks_do_not_replace` (`:1674`, `:1690`) pin the restore wording. Any restructure edits these pins (criterion 7 allows it).
- **What takes the space.** *Installing* (lines 15-145) and *Updating* (296-392) are mostly captured installer output; *The home checkout*, *The guard* and *The tracking comment* (193-258, about 65 lines) are host-and-container detail inside *Setting a project up*, ahead of *Your first workflow* (260). A first-time reader meets container roles before the six steps.
- **Config keys the plugin reads** (inventory from the code, not the docs; none of it is described together today). Required by `config.sh validate`: `schema` (integer, at most 1), `repo.owner`, `repo.name`, `baseBranch`. Optional: `codename`, `plugin.repo`/`plugin.ref`, `suites[]` (`name`, `paths[]`, `build`, `test`, `filter`, `parallel`), `skipGlobs[]`, `resources[]` (`name`, `paths[]`, `parameterised`), `environment.resource`, `environment.hooks.{start,preflight,activate,revoke,deploy,deployed}`, top-level `hooks.onLeaseChange`, `board.{owner,gateProject,projects[]}`, `board.statuses.{backlog,ready,inProgress,inReview,done}`, `issue.priority`, `labelTypes`, `docsDir`, `plansDir`, `invariants`, `modules[]` (only `wiki` means anything), `models.{subagent,reviewer}`, `triage.parkedDays`, `ci.requiredChecks[]`. `/codeo:setup --stack <name>` writes `stacks[]`, which nothing reads. `/codeo:doctor` validates only `schema`, `codename`, the board, `issue.priority` labels, `ci.requiredChecks` (the ruleset) and each suite's `build` and `test`; unknown keys are ignored silently, and there is no schema file.
- **The failure situations have no fixed message for two of the four.** The role guard prints exact lines (`role.sh`, one per role and skill kind). A foreign or wrong-branch lock, and a card that is not Ready, are skill instructions with no template: the skill "stops, naming what it printed". `lock.sh` prints `lock: …` lines, and `board.sh status` prints one word (`none`, `unset`, a column name, `unavailable`). The README can quote those and the skill wording, not an invented message.
- **The role guard is this repository's, not the plugin's.** `.devcontainer/scripts/role.sh` and the `## role-guard` overlays live in this repo; `/codeo:setup` writes no overlay and no `role.sh`. In a new project every skill is unguarded (`overlay.sh` exits 3), and a first-time user there never sees a refusal. The guard table now in the README is therefore not part of a new project's path.
- **Recovery text that exists:** run the step again (`/codeo:close` is safe to repeat; `/codeo:close --stash`); retake a missing lock with `lock.sh take local`; the start script's "remove it if it is not yours" for a lock file naming no issue. No document says to delete `.codeo/active` by hand, or to resolve a lock whose branch disagrees other than "the engineer's to resolve; never switch branches to make the lock true".
- **`docs/handoff.md:3` says "Seven pipeline skills"** while `docs/skills.md:5` and the README say six plus triage, cleanup, setup and doctor. The README follows `docs/skills.md`; the `handoff.md` line is outside this issue (see Notes).
- **In flight:** #170 (`docs/docs-say-codeo-host-command`, kbajpai, step `init`) has no footprint and has changed nothing yet, so there is nothing to compare; the issue says it edits the README. #168 (named in `init.md`) has merged (`4bbf8a5`), so the version tags in the install examples are already v1.0.9. `overlap.sh` runs once the footprint is committed, after these answers.

My calls, stated so they can be corrected (not questions):

- **One plan under `docs/plans/`, one pull request, no reference doc.** It is documentation plus test pins; no `engineering` skill applies (no component or technology choice).
- **New order of the root README:** title and a three-line summary; a table of contents; *Start here* (install, set up, first issue to merged pull request, each as a numbered step linking to its section); *Requirements*; *Installing* (the common install only); *Setting a project up*; *Your first workflow* (six sub-sections, one per step); *Configuration* (Q3); *Troubleshooting*; *Updating, replacing and restoring*; *Uninstalling*; *The skills*; *More documentation*; *Contributing*.
- **The worked example stays issue #143**, the archive the README already points at (`.codeo/done/143/`, six files that exist), so each step's file can be opened. The walk-through gets the same five facts per step: the command with its argument, what it asks and where, the file it writes, what it commits, and the command that comes next.
- **Command forms come from the skills' `argument-hint` lines**, and the closing block's format is quoted from `docs/handoff.md`. `${CLAUDE_PLUGIN_ROOT}` is never typed by the reader, so a README command that needs a plugin script says to run the slash command instead.
- **Every claim is checked by a task's proof**, not by eye: a new test in `tests/` that checks each backticked path, each `/codeo:` command and each `config.json` key named in the README against the repo (criterion 6). Its form is Q-free; the details go in the plan.
- **Out of scope stays out:** the `codeo` host command and macOS notes (#170), #163's wording (already merged in `24577ac`), `.devcontainer/README.md` and `docs/skills.md` beyond links.

## Questions

### Q1 — Install and update output samples: keep them in the README, or move them to a `docs/` page?

**Why it matters:** the README's eight-plus captured installer outputs are most of why *Installing* and *Updating* are hard to read, but `tests/install.test.sh` requires at least 8 of them in `README.md` and compares them with a stubbed run. Moving them means retargeting those pins at a new file; keeping them means they stay, with only the order and the prose around them changed.
**Options:**
- **A — move the replace-and-restore detail, keep the common install (my pick).** The README shows the one-line install, one output sample, the `--version` and `--scope project` forms with a sentence each, and a link. A new `docs/updating.md` takes the update, replace, restore and failure samples, and the pins that check them follow that file (the `README`-specific ones keep checking the README for what remains, at least the plain install, the rerun and the project snippet).
- **B — keep every sample in the README, reorder only.** *Installing* shows the common path first and every other form under sub-headings; *Updating* keeps its samples. No test retargeting, but the README stays long.
- **C — keep the samples in the README but fold them into collapsed `<details>` blocks.** The common path reads clean and the pins keep passing; the blocks are hidden on GitHub until opened and the README's length is unchanged.

**Answer:**
A — move the replace-and-restore detail to `docs/updating.md`; the pins follow. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

### Q2 — *The home checkout*, *The guard* and *The tracking comment*: leave in the README, or move to `docs/`?

**Why it matters:** these three are about 65 lines on running on the host, the roles and the issue's tracking comment, ahead of *Your first workflow*. They matter to a team that uses `.devcontainer/` but not to the first-time user in a new project. Moving them changes what the README links to and which text `tests/` pins for them.
**Options:**
- **A — move to a new `docs/home-checkout.md`, with a two-sentence summary and a link in the README (my pick).** The README keeps what a new project needs; the full tables and the tracking-comment example stay one click away, unchanged. The `.devcontainer/README.md` link stays as it is.
- **B — keep them in the README, after *Troubleshooting*, under an "Advanced: running on the host" section.** Nothing moves between files; the first-time path is clear because they sit last.
- **C — delete the tracking-comment section from the README and link `.devcontainer/README.md#the-tracking-comment`**, which already carries one, and move only the home-checkout and guard text.

**Answer:**
A — move them to `docs/home-checkout.md`, with a two-sentence summary and a link in the README. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

### Q3 — The configuration section: one table of every key in the README, or a short README section and the full reference in `docs/`?

**Why it matters:** criterion 4 asks for a section describing every key the plugin reads, which are optional, and an example. The inventory is about 45 keys (several are nested under `suites[]`, `resources[]`, `environment.hooks`, `board` and `models`), so the README grows by 80 to 120 lines if the whole table lives there.
**Options:**
- **A — the README carries the full table and the example (my pick).** One table: key, required or optional, default, what it does; grouped as *Required*, *Project and suites*, *Board and issues*, *Environment and leases*, *Models, paths and other*. A second example shows a fuller config than the starter. It satisfies the criterion literally, and the reader finds a key without leaving the page.
- **B — a short README section (the four required keys, `suites` and `board` with examples, and a pointer) and the full table in a new `docs/configuration.md`.** The README stays short; the criterion's "a section describes every key" is met by the linked page, which is a reading of it the engineer may not intend.

**Answer:**
A — the full table and a fuller example in the README. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

### Q4 — The role guard is not part of a new project: how should the README say so?

**Why it matters:** the troubleshooting entry for a role-guard refusal is a required criterion, but a project set up with `/codeo:setup` has no `role.sh` and no `## role-guard` overlays, so its skills are never refused. The entry would otherwise suggest every project has a guard. No document tells another project how to adopt one, and adding that would be new documentation of behavior, not a README fix.
**Options:**
- **A — write the entry for projects that have the guard, say so in its first sentence, and file the adoption gap as its own issue (my pick).** "Only in a project whose `.codeo/overlays/<skill>.md` has a `role-guard` section, such as codeo's own; a project set up with `/codeo:setup` has none and is never refused." The entry quotes the refusal forms (home-only skill in an issue checkout, lock skill in a home checkout, `stale:` with its causes, `stray`), their cause and the fix (the checkout the message names). The gap, "how another project adopts the guard", is filed through `/codeo:issue` when the plan is written.
- **B — the same entry, with a short "adopting the guard" paragraph written from the extension-point documentation** (`docs/extension-points.md` shows a generic `scripts/role-check.sh` example). It tells a project what to put in the overlay, but it describes something the repo itself has no tested example of outside this project.
- **C — the same entry, with no issue filed.** The entry says the guard is the project's own and stops there.

**Answer:**
A — write the entry for projects that have the guard, say so in its first sentence, and file the adoption gap as its own issue (promised under `## Notes`, since `/codeo:issue` is refused in this checkout). (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

### Q5 — A stuck or foreign lock: document only what the repo documents, or also say how to clear one by hand?

**Why it matters:** the repo documents re-running `/codeo:close` (or `--stash`), retaking a missing lock with `lock.sh take local`, and, for the start script, removing a lock file that names no issue. It documents no way to clear a lock whose branch disagrees or that names another issue, only that it is "the engineer's to resolve" and that the branch must not be switched to make it true. A README entry that tells the reader to delete `.codeo/active` is advice the skills do not give, and the close skill pushes and deletes branches, so a wrong deletion is costly.
**Options:**
- **A — only the documented recovery, plus a diagnosis that does not delete anything (my pick).** The entry has three symptoms: no lock (run `/codeo:init #<N>`, or `lock.sh take local` when the lock was lost), a lock whose `branch` differs from `git branch --show-current` (switch back to that branch yourself, or finish it with `/codeo:close` or `/codeo:close --stash` there; never edit the file to match), and a lock naming another issue (finish or stash that workflow first, in its own checkout). It states that the file is gitignored and belongs to one checkout, and that `/codeo:close` is the only thing that removes it.
- **B — A, plus "if you are sure no workflow of yours is running, delete `.codeo/active`".** It unblocks someone with a lock file left by a crash, but it is the one step the repo never recommends and the file is what stops the wrong branch shipping.

**Answer:**
A — only the documented recovery, plus a diagnosis that deletes nothing. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

## Notes

- **Out of scope, to file once the plan is approved:** `docs/handoff.md:3` says "Seven pipeline skills" where `docs/skills.md:5` says six. The README will say six. (Promised, no issue number yet.)
- **Out of scope, to file once the plan is approved:** how another project adopts the role guard (Q4, option A).

### Footprint

```
files:      README.md, docs/updating.md, docs/home-checkout.md, tests/install.test.sh, tests/readme.test.sh, CHANGELOG.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-25 — Q1-Q5 raised · cost: 5m · fable-5-2 81k in + 593k cached / 5k out · sonnet-5-5 411k in + 5.4M cached / 47k out
