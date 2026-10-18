# Moving the seven skills into codeo — design (plan 2 of 4)

Status: draft for review. **[call]** marks a decision the author made that the engineer has not yet
confirmed. Builds on `2026-10-18-workflow-plugin-extraction-design.md` (the overall design) and on
plan 1, which shipped codeo v0.1.0 (scripts, config, hooks, `/codeo:setup`, `/codeo:doctor`).

## Intent

codeo v0.1.0 has the engine but none of the pipeline: the skills that people actually run
(`issue`, `init`, `plan`, `implement`, `qc`, `close`, `triage`) are still RoadMaster's, under
`.agentskills/skills/`, full of RoadMaster's paths, tools and rules. This plan moves them into codeo
as `/codeo:*` so a new project can run the whole pipeline, without losing the rules the skills
encode, and without RoadMaster's specifics leaking into other projects.

## Goals

- The seven skills live in the codeo repo, run as `/codeo:<name>`, call scripts through
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/<x>.sh"` (verified working in a `SKILL.md` line by the
  `/codeo:doctor` run), and name nothing that belongs to one project.
- Every hard-won generic rule survives. The inventory found 8 to 13 per skill (for example "QC never
  fixes what it finds", "check the PR URL, not the exit code", "the create-only push is the claim").
- Project specifics reach a skill through exactly three channels: the config
  (`.codeo/config.json`), the project's `invariants` file, and overlay files.
- RoadMaster can run the pipeline on the new skills with no loss, proved by a replay of its finished
  dossiers (plan 3 then proves it on a live issue).

## Non-goals

- The Gemini/`agy` reviewers, the dev-container and web-session host tooling, and the wiki-and-diagrams
  module. They stay in RoadMaster and move later as modules.
- Stack packs for Xcode/Gradle/Python. The skills need only the suite vocabulary the config already has.
- A deploy/put-back framework. Those stay prose in a project's overlay.
- Migrating RoadMaster itself (plan 4).

## Anti-goals

- A "generic" skill that is the RoadMaster text with names swapped, where the swap corrupts the
  meaning. The inventory ranks the risky places; they are rewritten by hand.
- Config keys invented for prose-shaped rules, so that the config grows into a second, worse language.
- A rewrite that quietly drops an edge case because it looked RoadMaster-specific.

## Constraints

- Frontmatter per skill: `name`, `description` with trigger phrases, `model`. Models as today
  (`plan` on fable; `issue` and `qc` on opus; `init`, `implement`, `close`, `triage` on sonnet), taken
  from the existing skills' frontmatter, not changed. The config's `models` block is for the subagent
  hook and is not read by skills.
- Hard dependency on `superpowers:*` skills stays (accepted for v1).
- Renames: `/roadmaster:` → `/codeo:`, `.roadmaster/` → `.codeo/`, `roadmaster/intake` →
  `codeo/intake`, `ROADMASTER_GITHUB_LOGIN` → `CODEO_GITHUB_LOGIN`. These are safe as mechanical
  edits. Everything else in the inventory's "needs judgment" list is by hand.
- `${CLAUDE_PLUGIN_ROOT}` is used in every script call, and every call is `bash "..."`, never relying on
  an executable bit.
- Quoted evidence changes shape: `scope.sh` prints `suite.<name>=true|false` and `deploy=`, not
  `dotnet=false`; skills quote the new form.

## Decisions the engineer made

- **Overlays, not config keys, for prose-shaped project rules.** A skill has a few named extension
  points; each reads an optional project file and skips the step when it is absent.
- **Three plans, in order:** 2a, 2b, 2c below.
- Gemini/agy, host tooling and the wiki module stay in RoadMaster for now.

## The overlay mechanism **[call: details]**

- A project file `.codeo/overlays/<skill>.md` holds sections headed `## <extension-point>`. A skill's
  prose marks each point: "**Extension point `environment-evidence`:** if the overlay has this
  section, follow it here; otherwise skip this step."
- The plugin publishes the list of points in `docs/extension-points.md`: for each, the skill, the
  position in its flow, what the section may rely on (variables, outputs of earlier steps), and what
  the skill expects back.
- The overlay is read verbatim and followed as the project's instruction. It cannot override a
  generic rule the skill marks as a hard rule (the ones in the inventory's "must survive" lists).
  **[call]** a skill states that precedence once, at the top.
- `/codeo:doctor` gains an `overlays` check: every `## <name>` section in every overlay file names a
  known extension point of that skill, so a typo is a visible `fail`, not a silent skip.
- Initial points, from the inventory: `plan-shape` (exemplar paths, plan conventions),
  `proof-of-done`, `environment-lease-notes` (plan/implement), `environment-evidence` and
  `qc-invariants-extra` (qc), `wiki-rules` (plan, implement, qc), `put-back` and `ci-publish-check`
  (close), `todo-excludes` (triage). The builder may add or merge points; each one must be listed in
  the extension-points doc.
- The project's `invariants` file (a path in the config) is given to the QC reviewer verbatim; the
  skill no longer counts or names "the three invariants".

## Config additions **[call]**

Each key arrives with the phase that reads it, and is documented in `lib/env.sh`'s header and read
through `codeo_cfg`/`codeo_cfg_required` in the same change that adds it.

- **2a:** `docsDir` and `plansDir` (defaults `docs` and `docs/plans`, matching the strict paths).
- **2b:** suite field `parallel` (bool); environment hooks `deployed` (prints tab-separated name, tag,
  state, one line per workload, for QC's evidence step; its contract is written down in 2b) and
  `deploy` (run by `implement` after the environment lease is held; a non-zero exit is a failed task,
  not a lease refusal; the lease-then-deploy ordering stays in the generic prose, and
  project-specific notes about it go in the `environment-lease-notes` point).

`putback` is deliberately **not** a key: put-back is an overlay (`put-back`).

## Calls the author made after the builder check **[call]**

- **The inventory.** The generic half (the rules each skill must keep, the riskiest places, the config
  gaps) is `docs/skills-inventory.md` in this repo. The per-line map of RoadMaster-specific passages
  names private internals, so it lives in RoadMaster's private repository
  (`Docs/plans/2026-10-18-skills-prose-inventory.md`); the builder works from both.
- **Scope of one plan.** Each of 2a, 2b and 2c gets its own plan, written when the previous one is
  built. Planning 2a covers the overlay mechanism, the extension-points document and the config keys
  it reads; contracts for 2b's keys land with 2b as above.
- **Absent overlays.** Every extension point documents the default behaviour of its skill when the
  point is absent; none is "refuse". Defaults are conservative (for example no `put-back` section means
  `close` says plainly that it knows of no irreversible environment change to put back and asks the
  engineer once; no `proof-of-done` section means the suites' `test` command is the proof). The doctor
  `overlays` check validates names, not required-ness.
- **Scripts with no codeo port.** `dev-scope.sh` and `changed-scope.sh` are fully replaced by
  `scope.sh` (`deploy=` and `suite.<name>=`), and the paragraphs that quoted them are rewritten around
  those lines, not turned into overlays. The Gemini/`agy` reviewer steps are removed from the generic
  skills with no extension point; they return with a module. Plan 1's scripts keep the command-line
  interfaces they were ported with.
- **`init` with no host overlay.** The generic `init` validates the issue and the Ready gate, claims the
  branch with the create-only push, writes the dossier, pushes it, and hands off to `plan` in the same
  session. The home-container versus issue-container split (and any lock-taking by a second
  environment) is the `host-workflow` point's content.
- **The replay's data stays private.** RoadMaster's repository is private and codeo is public, so the
  real dossiers and RoadMaster's overlay files are never copied into codeo. The replay reads them from
  a directory named by `CODEO_GOLDEN_DIR` and skips, saying so, when it is unset; codeo's own tests use
  small synthetic dossiers of the same shapes. RoadMaster's overlay drafts live in RoadMaster and are
  first used by plan 3's parallel run.
- **Doctor and `superpowers`.** Doctor gains a check that the `superpowers` skills the pipeline calls
  are installed, as a `fail` with the install command; the detection mechanism is the builder's.

## Phases

**2a — mechanism and the light skills.** The overlay mechanism, `docs/extension-points.md`, the doctor
`overlays` check, the `config` additions, and the skills `issue`, `init`, `triage`, `plan`. These
have the least stack text. Includes the mechanical renames, script calls through
`${CLAUDE_PLUGIN_ROOT}`, repo/owner/board constants read from the config, and the removal of
RoadMaster-only references (`wf:*` labels, `docs(roadmaster):` commit scope, container naming).
`init`'s home-container/issue-container logic is host tooling and stays, behind a clearly marked
extension point `host-workflow`, with RoadMaster's text in its overlay.

**2b — the stack-bound skills.** `implement`, `qc`, `close`. Riskiest places first, rewritten by hand
(ranked in the inventory): the dev-scope paragraph, the DEV-evidence block, the scope→build→suites
block, the put-back section, the lease-refusal kinds (a hook refusal is not a queue wait), the plan's
proof-of-done and lease ordering, the wiki rules, the invariants feed to the reviewer. The
`deployed` hook's output contract is specified here.

**2c — the golden replay.** A script, with synthetic fixtures of its own, that replays RoadMaster's finished dossiers (chosen:
#159, a clear verdict after one send-back; #91, a plan send-back then an implement send-back then
clear; and one with a DEV block, #146, #150 or #182) and check mechanically: round order, the last
bold `**Verdict:**`/`**Routing:**` per round and that its route is one of close, implement or plan,
the cross-file round links, the dossier skeleton, the log-line format, and acceptance-criteria row
counts. Normalisers map codeo's new strings (`.codeo/`, `suite.x=`). A human judges the rest.
Known drifts in the golden data (a missing cost on one log line, a wrong model name, an unset-flag
sentence the skill forbids) are recorded as expected findings, not failures. The real dossiers and
RoadMaster's overlay files stay in RoadMaster (see the calls above); the replay reads them from
`CODEO_GOLDEN_DIR`.

## What is left to the builder

How the mechanical renames are applied and reviewed; the overlay file's exact section grammar; the
exact wording of the precedence statement; how 2c normalises and compares; whether 2a/2b/2c are
one repo branch each; frontmatter test for the skills (the source has `skill-frontmatter.test.sh`).

## Risks

1. Interleaved generic and RoadMaster text (the inventory's top eight): a substitution that reads
   fine but changes a rule. Mitigation: those are rewritten by hand and covered by the replay where
   the dossiers allow.
2. The replay checks structure, not judgment; a real behavioural regression in the prose is caught
   only by plan 3's live run.
3. Overlays can drift from the skill that reads them; the doctor `overlays` check catches names only.
