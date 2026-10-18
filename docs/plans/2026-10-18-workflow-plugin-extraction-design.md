# Extracting the workflow pipeline into a reusable plugin — design

Status: draft for review. Written from a brainstorm; **[call]** marks a decision the author made
that the engineer has not yet confirmed.

## Name

The plugin is called **codeo** (chosen by the engineer). Commands are `/codeo:issue`, `/codeo:plan`
and so on; the state directory is `.codeo/`, the intake branch `codeo/intake`, the environment
variables `CODEO_*`, and the secrets directory `~/.codeo-secrets`. The repository is
`<engineer's account>/codeo`; the bare `codeo` GitHub account belongs to someone else. Similar names
exist (SYSGO's CODEO IDE, GoCodeo), so the README says plainly what this is.

## Intent

The `/roadmaster:*` pipeline (`issue → init → plan → implement → qc → close`, plus `triage`) is
mature. The engineer wants to run it on every project they start — the next is a social media app —
not only on RoadMaster. Today it cannot move: it lives inside this repo at `.agentskills/`, and its
RoadMaster specifics are woven through the skills' prose, not held in data.

The goal is one plugin, versioned in its own GitHub repository, that any project installs at a pinned
version and configures with one file.

## Goals

- One plugin, in its own repository, released as tags (`v1.0.0`, `v1.2.0`). Each project pins the
  version it uses; two projects may pin different versions.
- Technology agnostic. Target stacks: .NET and Python backends, GCP infrastructure, Angular, Xcode
  and Android frontends. The core knows no build tool.
- A project adopts the plugin by adding a config file, not by editing the plugin.
- RoadMaster is the first project migrated, and must lose nothing it has today.
- The plugin repository runs the pipeline on itself, pinned to its previous release **[call]**
  (building N with N-1, so a broken release can still be fixed through a working pipeline).

## Non-goals

- Imposing a source layout. `src/` is not mandated; Xcode, Gradle and Angular each own theirs, and
  moving RoadMaster's service folders is churn unrelated to extraction.
- Several plugins. Optional capabilities are modules inside the one plugin, switched on in config.
- Building the social app, and writing the iOS/Android environment story, in this round.

## Anti-goals

- A "generic" plugin whose skills are `dotnet`-flavoured prose with the word swapped out.
- A release that silently misreads an older project's config or shared state.
- A branch that can change the pipeline a project is currently running on.

## What is already generic

The dossiers and the hand-off / send-back protocol (`HANDOFF.md`, `DOSSIER.md`); the workflow lock
and atomic claim; the intake branch and ledger; the lease queue; footprint and overlap checks between
in-flight workflows; board gating; the subagent model policy hook; cost logging; the `qc-verdict`
check; per-round sync with the base branch; the phase-from-facts close; triage fingerprints; the
optional external reviewer (the last stays in RoadMaster for v1). The rest move into the core largely as they are.

## What is RoadMaster-specific

Grouped by how much work each is. Counts and locations are from a read of `.agentskills/`.

1. **Plugin location** (about 150 references). Skills call `bash .agentskills/scripts/…` from the repo
   root, and `plugins.sh` installs from `./.agentskills`. A marketplace-installed plugin lives in a
   cache, so every call must resolve through `${CLAUDE_PLUGIN_ROOT}`. Hard-coded names also need
   parameterising: `/roadmaster:*`, `.roadmaster/`, branch `roadmaster/intake`, `ROADMASTER_*`
   variables, `~/.roadmaster-secrets`.
2. **Stack knowledge written as prose.** `dotnet build RoadMaster.slnx`, `dotnet test --filter`,
   `ng test`, "all five projects"; the QC invariants (`TransactionId`, `BaseResponse<T>`, no trailing
   newline in `.cs`); the Wiki and draw.io rules; the plan-shape conventions. This is the largest
   piece of work, and the shell test suite cannot cover it.
3. **Scope detection.** `changed-scope.sh` and `dev-scope.sh` hold path regexes; the same rule is
   pasted verbatim into `HANDOFF.md` and the `implement` skill.
4. **Lock names.** A closed list (`dev`, `terraform`, `postman`, `slnx`, `k8s-base`,
   `migrations:<Service>`) hard-coded in `intake.sh`, `DOSSIER.md` and `HANDOFF.md`.
5. **The DEV environment lease.** `intake.sh lease take dev` fuses the queue with GCP activation,
   cluster start, a migration schema check and override semantics; `qc` and `close` then depend on
   the `dev-deployed` tag semantics.
6. **Repository, owner, board.** Constants in `github.sh`, `inflight.sh`, `workflow-status.sh`,
   `board.sh` (including project numbers and the org-level Issue Types API) and prose in several skills.
7. **Host tooling.** Dev-container-per-issue, web-session bootstrap, container naming, the `agy` and
   `gemini` integrations, the superpowers install.
8. **Hidden assumptions.** `main` is the only base branch; `gh` with REST; CI checks named exactly
   `tests` and `qc-verdict`; model names in the hook (`sonnet`, and `opus` only for a description
   starting `QC review:`); `plan` on `fable`; a hard dependency on `superpowers:*`; Claude transcripts
   at `~/.claude/projects/*/<sid>.jsonl` for cost logging; bash 4 and `jq`.

Mixed scripts that must be split: `intake.sh` (lease engine vs `gcp_*`), `board.sh` (engine vs the
two-board policy), `devcontainer-start.sh`, `plugins.sh`, `workflow-status.sh`, and the scope scripts
(mechanism vs the repo's regexes). About twelve test files cover code outside the plugin
(`Manager/*.sh`, `render.sh`) and move with it.

## Design

### Shape

```
plugin repository (tagged releases)
  core            skills, protocol docs, lock / claim / intake / lease engine,
                  footprint + overlap, board, qc-verdict, model hook, usage
  modules         opt-in, enabled in config
                  environment-lease · wiki-and-diagrams  (dev-container host and external reviewer: after v1)
  stack packs     defaults for suites and scopes: dotnet · angular · xcode · gradle · python
```

A project holds only its config and its pipeline artifacts. Everything else is the plugin.

### Strict paths — the pipeline's own artifacts only

| Path | Holds |
|---|---|
| `.codeo/` | per-issue dossiers, the `active` lock, the intake ledger, `done/` archive, and the config file |
| `docs/` | design reasoning; `docs/plans/` for plans |
| `wiki/` | wiki source, when the module is on |

Source layout is the project's own, described by globs in the config. **[call]** the names above; the
engineer asked for strict paths and left the names to the author. RoadMaster's `Docs/`, `Wiki/` and
`.roadmaster/` rename to these.

### Config (one file, versioned)

The config carries the schema version it was written for. It names: repository and owner; base branch;
board and status names; label → branch-type map; docs, plans and wiki directories; the **suites** (name,
path-scope globs, build command, test command, single-test filter template, whether it runs in
parallel); the **exclusive resources** (name, path globs, parameter form such as `migrations:<X>`) and
which one is the environment lease; the QC invariants (a pointer to a file, ideally the repo's own
`CLAUDE.md` section); model tiers; and which modules are on.

Skills then read "run the configured build for the suites in scope" instead of naming a tool. The
prose of `plan`, `implement` and `qc` is rewritten against that vocabulary, keeping the edge cases
those steps encode today.

### Versioning and shared state

- A project pins a tag. The plugin repo never changes what a pinned tag does.
- The dossier layout, lock files and intake ledger are shared, durable state. A release that changes
  any of them ships a migration, or states that a project may bump its pin only between workflows
  **[call]**; a config with a newer schema than the plugin is refused with a clear message.
- CI's `qc-verdict` check fetches the script at the pinned tag, so CI and the local pipeline run the
  same version. The consuming repo carries workflow and ruleset scaffolding that the plugin provides.
- Self-hosting is gone for consuming projects: a branch can no longer run its own edited pipeline.
  Pipeline changes are made in the plugin repo and reach a project when it bumps its pin.
- The plugin repo is the exception **[call]**: it runs the pipeline on itself, pinned to the previous
  release, with its own config, `.codeo/`, board and `qc-verdict` CI. No release precedes the
  first, so `v1.0.0` is cut from RoadMaster's `.agentskills/` as extracted, and the plugin repo pins
  it from then on.

### Setup and health: `/codeo:setup` and `/codeo:doctor`

`/codeo:setup` scaffolds a new project: the config, `.codeo/`, the CI files and the ruleset
requirements. `/codeo:doctor` checks an existing one and reports what is wrong: the config is valid
and its schema matches the pinned version, `gh` has the scopes it needs, the board and required checks
exist, and each suite's commands run. A new project (the social app is the first) meets missing setup
in one report, not one failed skill at a time.

### Releases

Every release has a changelog with an upgrade note: what changed in the config schema or the shared
state, and whether the pin may be bumped mid-workflow.

### Testing the prose

The shell suite cannot reach the skills' prose. The dossiers recorded in the RoadMaster parallel run
become golden examples. Each release replays a set of scripted scenarios against them and compares the
verdicts, hand-offs and routing, to catch regressions in the edge cases the skills encode today. The
set needs to be enough for that, not exhaustive.

### Environment lease (module)

The queueing engine (grace, right-of-way, push as compare-and-swap) is core. What happens on take and
release — activate a deployer, start a stopped cluster, check the schema, report what is deployed, put
back a stash — becomes hooks the project names in config. GCP/k8s is the first implementation, the one
RoadMaster uses. A project with no shared environment turns the module off. The interface for iOS and
Android (TestFlight, emulators) is out of scope here beyond not blocking it.

## Order of work

1. Extract the core and config; introduce `${CLAUDE_PLUGIN_ROOT}` paths; parameterise names.
2. Split the mixed scripts; move RoadMaster's specifics into its config and the environment-lease module.
3. Rewrite the `plan`, `implement`, `qc`, `close` prose against the config vocabulary.
4. Parallel run: old and new pipelines side by side on one real RoadMaster issue; compare the
   dossiers, QC verdicts and hand-offs, and fix the differences.
5. Migrate RoadMaster to the pinned plugin and the strict paths; remove `.agentskills/`.
6. Later, each its own round: stack packs for other stacks, the iOS/Android environment story, the
   social app.

## Author's calls (settled without the engineer; confirm or overrule)

- **Renames.** Done in step 5, when no workflow is in flight, in two commits (`Docs`→`docs-tmp`→`docs`)
  so a case-insensitive checkout survives. `CLAUDE.md`, the wiki mirror workflow, links and the
  `.roadmaster/done/<N>` citations in code comments are rewritten by script in the same change.
- **Shared-state migration.** v1 has no migration framework. A project bumps its pin only between
  workflows; the config schema version is checked on every run. RoadMaster's `.roadmaster/` →
  `.codeo/` move is a one-off script.
- **Dev-container host module (after v1).** When it is built, it ships the start script and its checks, not the Dockerfile or image
  tools, which are stack-specific and stay in each project.
- **Lease hooks.** Shell commands named in config with an exit-code contract (0 ok, non-zero refuse),
  printing what `qc` and `close` need (the deployed tag, the schema result) on stdout. Designed
  against RoadMaster only; a mobile case is not designed for, only not blocked.
- **CI check names.** `tests` and `qc-verdict` stay for RoadMaster and become configurable. The
  ruleset must have no gap during cutover, so `qc-verdict` switches to the pinned-tag fetch in a
  staged change that keeps the old path until the new one is green.
- **Hidden assumptions.** Documented, not made configurable, except model tiers. The `superpowers:*`
  dependency, `gh` with REST, bash 4 and `jq` are accepted for v1.
- **Board.** Core requires GitHub Issues and a Projects board in v1. A board-less path (skipping the
  Ready gate) is deferred; the org-specific two-board policy and Issue Types move into the board
  config.
- **Delivery.** The pin is recorded in the project's config file; `devcontainer-start.sh` and the
  web-session `SessionStart` hook install that tag from the plugin repo.

## Decided by the engineer

- **Parallel run before cutover.** RoadMaster proves "lost nothing" by running the old pipeline
  (`.agentskills/`) and the new pinned plugin side by side on a real issue; `.agentskills/` is removed
  only after the two agree. The order of work gains a phase for it, between steps 3 and 4.
- **The plugin repo is public, holds no secrets, and only the engineer can push to it.** Containers
  and web sessions fetch a pinned tag anonymously, so no credential is provisioned for that. Secrets
  stay outside the plugin (today's `~/.roadmaster-secrets` equivalent is read from the user's home,
  never from the repo), and the repo enables secret scanning. Writes are restricted by branch and tag
  protection **[call on mechanism]**: changes land by pull request from the engineer, release tags can
  be created only by the engineer, and a tag, once pushed, is never moved, since projects pin them.
  Pull requests from forks may be opened but get no secrets in CI.

## Also decided by the engineer

- **The social app's environment story is settled early.** Before the lease hook interface is
  finalised, the engineer says what the social app needs (anywhere from no shared environment to a
  per-branch preview), so the interface is sketched against two cases, not only RoadMaster's DEV.
- **Multi-engineer behaviour is recorded as untested outside RoadMaster.** Assignees, leases and
  overlap checks assume several engineers; codeo's docs say they have been exercised only on
  RoadMaster.

- **Host tooling is out of v1, bar the pinned install.** The start scripts fetching the pinned tag are
  in v1. The `agy` and `gemini` integrations and the web-session bootstrap stay in RoadMaster until
  the core is stable, then move over as a module, because they are heavily RoadMaster-shaped and
  splitting them is work v1 does not need.

## Left to the builder

Config file format and name; how the plugin repo is laid out; the migration mechanism for shared
state; the test strategy for the rewritten prose (the shell suite cannot reach it); how the CI scaffold
is delivered (reusable workflow, action, or vendored copy).

## Risks

1. The prose rewrite loses hard-won edge cases, and nothing automatic catches it.
2. The environment-lease interface is designed for one implementation and may not fit mobile.
3. Without self-hosting, a release gets less real-world exercise before projects adopt it.
