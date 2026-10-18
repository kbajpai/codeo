# The hand-off protocol

Seven pipeline skills, each with its own artifacts. This file is the authority on who owns what, how they
talk to each other, and what they spend on subagents; each `SKILL.md` states only its own half of
the contract and points here. `dossier.md` is its companion — the same discipline applied to what
a skill asks the *engineer*, and to the file it asks in.

## The rule

**A skill writes only its own artifacts.** It may read anything. It never edits what another skill
owns — not to fix a typo, not to resolve a question it just answered, not to bring a stale line up
to date. If something in another skill's area is wrong, say so and stop.

There are two records, and they answer different questions:

- **`.codeo/<N>/`, the dossiers, record the work** — what was asked, what was decided and why,
  what was built, how it was checked, what it cost. One file per step, committed on the branch,
  archived to `.codeo/done/<N>/` when the workflow closes. This is the only per-issue record there
  is.
- **The project's documentation records the application** — what it does *now*, for the people
  who use it and the people who work on it: the config's `docsDir`, and the pages of the `wiki`
  module when the project's `modules` include it. It is not a log of work and nothing in it is
  keyed to an issue. It lives in the repository so a change and its documentation land in the same
  pull request, reviewed together, and describe what is merged, never what is merely proposed.

Design reasoning sits between them: *why* the application is built the way it is — options
rejected, and the plans under `plansDir`. The documentation says what the system does and links to
the reasoning for why; it does not repeat the reasoning, and the reasoning does not become the user
or developer guide.

## The lock

`/codeo:init` does not merely cut a branch — it **starts a workflow**, and a workflow is bound to
exactly one issue until it is closed or stashed. **Each workflow runs in a checkout of its own**,
and `.codeo/active` in that checkout is the binding:

```
issue:   12
branch:  feat/order-export
started: 2026-03-04
host:    local
```

`bash "${CLAUDE_PLUGIN_ROOT}/scripts/lock.sh" take <container|web|local> [session-id]` writes it,
from the `init.md` that names the branch the checkout has checked out; it never comes from anything
typed by hand, and it never fails its caller — what it could not do it prints as a `TODO` line. On
the base branch it takes no lock. `host` says what kind of checkout took it:

- **`container`** — a dev container; a `volume:` line follows, identifying the container so it can
  be found again.
- **`web`** — a hosted session; a `session:` line follows. It is the only host that checks the
  issue's branch out at bind time, when the session started on another branch, and it refuses —
  taking no lock, with a `TODO` saying how to reconcile — when the two have diverged or a local
  branch of that name holds commits the checkout would discard.
- **`local`** — a plain checkout, with nothing further to identify it.

The lock is gitignored, so it belongs to one checkout — which is the whole of how several workflows
run at once. One engineer holds as many issues as they have checkouts; several engineers each hold
their own. *Parallel workflows* below is what keeps workflows out of each other's way.

By default `/codeo:init` takes the lock itself: after it cuts and checks out the issue's branch and
writes and pushes its `init.md`, it runs `lock.sh take local`, and `plan` follows in the same
session. A project with an `init/host-workflow` overlay section takes the lock as that section
says, in whatever checkout it runs the issue's later steps. `/codeo:close` removes it —
once the pull request has merged and the branch is cleaned up, or on a stash or an abandon. Nothing
else ever writes it. **A workflow whose pull request is open is still running**: review can send it
back, and until the merge the issue is what the pipeline is working on.

**Every path the pipeline writes down or prints is relative to the repository root.** Nothing the
dossiers or the lock record may carry a home directory or any other absolute path: those are one
machine's, and the records travel.

**Every other skill reads it first and stops if it can't.** Three checks, in order — each against
the checkout the session is in:

1. **No `active` file?** No workflow is running *here*. Name `/codeo:init #<N>` as the step that
   was skipped — or, when the project's host workflow binds the lock in another checkout, say to
   run the step there, or that the lock was never taken there, as that workflow describes. Either
   way, stop. Do not proceed from a plan slug or a branch on its own — the pipeline is entered at
   the front or not at all.
2. **`branch` disagrees with `git branch --show-current`?** Hard stop. Either someone switched
   branches mid-flow or the lock is stale, and both are the engineer's to resolve. Never switch
   branches to make the lock true.
3. **An argument naming a different issue than `issue`?** Hard stop, naming both. A workflow is not
   redirected by an argument; it is closed or stashed first.

Because the lock names the issue, **a bare invocation of `plan`, `implement`, `qc` or `close` in the
bound checkout is not ambiguous.** The engineer named the issue when they ran `init`; reading the
lock honors that rather than guessing at it. The rule that a bare invocation stops and asks still
holds whenever no workflow is active — which is exactly when there is no lock to read.

`/codeo:issue` is the exception, as it is to most of this file. It runs before a number exists and
may be called mid-flow by `plan` or `implement` without disturbing the lock: filing an issue is not
starting work on it. `/codeo:triage` is outside the lock for the same reason: it reads across every
issue and branch, writes only its own ledger on the intake branch, and can run in the middle of a
workflow without touching it.

## Parallel workflows

Separate checkouts stop workflows sharing a working tree; they do not stop them colliding on
everything else. These things do, and none of them is a registry someone has to keep up to date —
each is either derived from what is already pushed or taken and released by the step that needs
it.

- **The claim.** The branch push is the claim — create-only
  (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/claim.sh"`), so of two `init`s on one issue exactly one
  succeeds. A resume is claimed the same way: its `resumed:` line in `init.md` is pushed against the
  branch tip it read, so of two resumes exactly one succeeds, and a stash it resumes is spent. The
  assignee and the card follow the push. `/codeo:init` assigns the issue to the engineer running
  it, and refuses one already assigned to someone else, or already started on a pushed branch,
  unless the engineer says otherwise in so many words. The assignee is what the rest of the team
  sees on GitHub. `/codeo:close` unassigns on a stash or an abandon; a merge closes the issue
  anyway.
- **The board.** When the config has a `board`, its Status carries the same claim: `init` starts
  only a **Ready** issue — read on `board.gateProject`, and marked by `/codeo:triage` on the
  engineer's answer — and moves it to **In progress**.
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh"` is the only thing that reads or writes it: `set`
  writes every project the issue is on whose Status has the option, first adding the issue to each
  of `board.projects[]` it is missing from, so the boards stay in step. A status is named by its
  key in `board.statuses` (below), which maps it to the board's own option name; a name that is not
  a key passes through. Every transition moves the card, each write part of its step and never a
  gate on it — a failure is reported with what to do by hand, in the skill's `## Log` line as
  `board: failed — <reason>`, and the step carries on. Where the GraphQL it needs is refused (a
  hosted web session), `set` fails saying to move the card by hand. With no `board` configured,
  every verb prints `board: not configured` and exits 3: the board steps are skipped, and the skill
  says so once.

  | Moment | Skill | Status key |
  |---|---|---|
  | Engineer routes a never-started issue to *mark Ready*, or parked work to *resume* | `triage` | `ready` |
  | Engineer routes a never-started issue to *leave in the backlog* | `triage` | `backlog` |
  | The issue is claimed (a resume included) | `init` | `inProgress` |
  | The PR is opened, or re-readied after review work | `close` | `inReview` |
  | Review feedback or a conflict is sent back to `implement` | `close` | `inProgress` |
  | The workflow is stashed | `close` | `ready` |
  | The workflow is abandoned | `close` | `backlog` |
  | The merge is verified | `close` | `done` |
- **Who else is in flight.** `bash "${CLAUDE_PLUGIN_ROOT}/scripts/inflight.sh" [--except <N>]`
  lists every workflow with a dossier on a pushed branch — its issue, branch, assignee, last
  finished step, its plan's footprint, and the files the branch actually changes. It reads origin,
  so it sees other engineers' work as soon as they push, which every step does. `inflight.sh --tsv`
  and `intake.sh lease list --tsv` are the forms a status reporter reads, and the config's
  `hooks.onLeaseChange` runs after every lease change, since a push to the intake branch is all a
  lease change is. Any such report is a view of what is pushed: a row that looks wrong is fixed by
  pushing, never by editing the report.
- **The footprint.** `/codeo:plan` records what the change will touch — `dossier.md` → *The
  footprint* has the block — and compares it with every other workflow's before its review gate.
  The comparison does not stop there: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlap.sh" <N>` runs at
  every step — `plan`, `implement`, `qc` and `close` — from the branches' actual diffs as well as
  their footprints, and footprint against footprint through the files each glob resolves to. Work
  that has outgrown its plan still shows up that way, and an overlap already raised as a question
  in the issue's dossiers is not raised again. An overlap is a numbered question in `plan.md`,
  answered by the engineer, never a guess: proceed and coordinate, sequence after the other issue,
  or re-scope. An `exclusive` resource — one of the config's `resources[]` — is one where two
  branches cannot both change it and merge cleanly, so for those the plan takes a lock
  (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease take <resource> <N> <purpose>`), refused
  while another issue holds it.
- **Leases and their queue.** Every lock goes through
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease`, and lives on the intake branch, where
  every engineer can see it; every decision is read from origin after a fetch, and with origin
  unreachable every lease verb but `list` fails rather than deciding from a stale ref. Held by
  another issue, a take stops and names the holder. The step records the wait
  (`lease wait <resource> <N>`), and the wait binds: a take by anyone but the waiter whose turn it
  is is refused. Each waiter in turn has right of way for `CODEO_LEASE_GRACE_SECONDS` (default one
  hour), starting at the latest of its wait, the moment the lease freed and the end of the turn of
  the waiter ahead (the clock never runs while the lease is held) — and a take that finds an
  expired wait drops it. A holder's own re-take is exempt, and the rule covers every lock. The step
  stops at that task, never in a loop; everything before it is done and pushed. A background watch
  on `lease list` may resume it, costing nothing while it waits.
- **The environment lease.** When the config has an `environment`, its `resource` — an entry of
  `resources[]` — is the one lock with side effects. Everything before it runs in parallel: each
  checkout builds and runs the suites on its own. The shared environment is where the branch runs
  integrated, and **one issue has it at a time**, from its first task that needs the environment
  until `/codeo:qc` returns a clear verdict. The plan does not declare it in its footprint; the
  later steps take it when they reach that task. What the environment is, and anything a project
  must say about holding it, belongs to the project — its hooks, and its overlay sections such as
  `plan/environment-lease-notes`.
  - `intake.sh lease take <environment.resource> <N> "<purpose>"` takes it. It refuses a branch that
    does not contain `origin/<baseBranch>`, because the environment is about to run the branch, and
    one missing already-merged work would roll it back.
  - It then runs `environment.hooks` in order — `start`, `preflight`, `activate` — each before the
    lease is published; a non-zero exit from any of them refuses the take and publishes nothing.
    Each hook is a shell command run from the project root with `CODEO_ISSUE`, `CODEO_RESOURCE` and
    `CODEO_OVERRIDE` exported; an absent hook is skipped. `revoke` runs whenever a take that began
    running them does not end holding the lease — a hook refused, another issue won the race, the
    push failed, the take was interrupted — and on a release, so it must be safe to run when
    activation never finished or was already given back. A holder's own re-take runs the hooks
    again and keeps the lease, and its activation, whatever they answer.
  - `--override "<reason>"` applies to the environment resource only. The reason is exported to the
    hooks as `CODEO_OVERRIDE` — whether it excuses anything is the hooks' decision — and recorded
    on the lease as its `override:` line; the step repeats it in its `## Log` line. It bypasses no
    hook failure: a hook that exits non-zero refuses the take, override or not.
  - `intake.sh lease check <resource> [N]` exits 0 when the issue holds the lease on origin, 1 when
    it does not (naming the holder), 2 when origin cannot be asked — which is how a project's own
    deploy command refuses a caller whose issue does not hold it.
  - `/codeo:qc` releases it at a clear verdict, after recording what the environment ran and its
    results in `qc.md` — `environment.hooks.deployed` is how `qc` learns what the branch left
    deployed, and it names any workload the plan did not declare. `/codeo:close` releases everything at every exit (`lease release-all <N>`),
    so a finished or parked workflow never keeps the environment, and releases the environment at
    approval only when `qc` could not. A review round that changes what the environment runs —
    `bash "${CLAUDE_PLUGIN_ROOT}/scripts/scope.sh" <the commit it last ran> HEAD` prints
    `deploy=true` — takes the lease again, behind whoever is waiting, and `qc` re-runs its
    environment checks; a round that prints `deploy=false` does not.
  - With no `environment` configured, no lease has side effects and none of this applies.

And one thing only happens because another workflow merged first: a pull request that conflicts
with the base branch. `/codeo:close` checks for it and sends it back to `/codeo:implement`, like any
other change the code needs. Every `implement` and `qc` round starts by merging
`origin/<baseBranch>` (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/sync-main.sh"`, with
`--abort-on-conflict` in `qc`, which resolves nothing), so a conflict surfaces in the round that can
fix it rather than at `close`.

## Who owns what

| Artifact | Owner |
|---|---|
| The GitHub issue | `/codeo:issue` |
| The issue's assignee | `/codeo:init`, cleared by `/codeo:close` on a stash or an abandon |
| The issue's board Status | `ready`: `/codeo:triage`, and `/codeo:close` on a stash; `backlog`: `/codeo:triage`, and `/codeo:close` on an abandon; `inProgress`: `/codeo:init`, and `/codeo:close` on a send-back; `inReview` and `done`: `/codeo:close` |
| The branch | `/codeo:init`; `/codeo:close` deletes it after the merge |
| `<plansDir>/YYYY-MM-DD-<slug>.md` and `<docsDir>/<slug>.md` | `/codeo:plan` |
| Application and test code, and the documentation pages the plan names | `/codeo:implement` |
| The quality verdict on a change | `/codeo:qc` |
| The pull request, and deleting the branch once it has merged | `/codeo:close` |
| `.codeo/<N>/<step>.md` | the one step named in the filename |
| `.codeo/intake/` and the `codeo/intake` branch | `/codeo:issue`; `/codeo:init` only reads it, copying `issue.md` out when it adopts one |
| `.codeo/intake/triage/` — the ledger and run files | `/codeo:triage` |
| `.codeo/intake/leases/` — the locks on exclusive resources and who waits for them | `/codeo:plan` takes those its footprint names; `/codeo:implement` or `/codeo:qc` take `environment.resource`; all record waits, through `intake.sh lease` only; `/codeo:qc` releases `environment.resource`, `/codeo:close` releases the rest |
| `.codeo/active`, the lock, one per issue checkout | `/codeo:init`, taken in the checkout that runs the later steps; cleared by `/codeo:close` |

Documentation is documentation in the same sense code is code: `/codeo:plan` decides which pages
under `docsDir` (and, with the `wiki` module, which wiki pages) a change affects and names them as
tasks, `/codeo:implement` writes them alongside the code they describe, and `/codeo:qc` judges them
against the diff — a page that no longer matches what the code does is a finding like any other.
Nobody else edits those pages inside a workflow. A project's own rules for them are its
`plan/wiki-rules` overlay section.

Each skill owns exactly one dossier file and may read every other. `dossier.md` has the file's
shape, including the two sections that carry a step's result forward: `## Outcome`, written at the
hand-off, and `## Log`.

**The log carries the cost.** Every invocation appends one line to `## Log` in its own dossier,
ending with ` · cost: ` and the output of `bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" <your-step>`
— wall time since this invocation began and tokens per model, subagents included. Model tiers are a
guess until a few issues' worth of these lines say where the time and the money actually go; a line
without it is a data point lost. If the script cannot find the invocation (a resumed session), pass
`--since <ISO-8601>`; if it cannot run at all, write `cost: unavailable` and why, never an estimate.

## A hand-off

The only sanctioned channel between skills. Four parts, in order:

1. **Close your questions.** Nothing in your own dossier may still be open — see `dossier.md` →
   *The gate*. A hand-off that carries an unanswered question hands the next skill a decision
   nobody made.
2. **Write your outcome, and make it durable.** Write your dossier's `## Outcome` and append your
   `## Log` line, then commit the file and push the branch, before announcing anything. A hand-off
   that is only spoken is lost at the next compaction; one that is only local is lost with the
   machine. `dossier.md` → *Durability* has the commit convention.
3. **State it.** Name the next skill, the artifact it should read first, and any decision it must
   not reopen.
4. **Read before acting.** The receiving skill's first move is to read the dossier files of the
   steps before it — their `## Outcome` sections first — rather than re-deriving from the
   conversation or asking the engineer what those already answer.

The order is `/codeo:issue` → `/codeo:init` → `/codeo:plan` → `/codeo:implement` → `/codeo:qc` →
`/codeo:close`. A skill that finds the previous step wrong or missing says so and stops; it does not
do that step's work itself.

## A send-back

Two steps may hand work *backwards*, and everywhere else the flow runs forwards only:

- `/codeo:qc`, to `/codeo:implement` when the code doesn't do what the plan says, or to
  `/codeo:plan` when the code is faithful and the plan was wrong.
- `/codeo:close`, to `/codeo:implement` when review on the pull request asks for changes, or when
  the pull request conflicts with the base branch because a parallel workflow merged first. The fix
  then goes through `/codeo:qc` in full before it returns to `/codeo:close`, and onto the same pull
  request.

A send-back is a hand-off, with the same four parts and one extra rule: **the sender never starts
the fixing.** Naming a finding and then repairing it is doing the receiving step's work, and it
destroys the independence that made the finding worth anything. Write the round, name what must
change, route it, and stop.

The receiving step opens a new round in its own dossier rather than editing the round that was
already answered, so the file shows what the send-back changed. A send-back returns to the sender
once the receiving step is done, and the pass then runs again in full. Re-checking only the part
that changed is how a regression ships.

## What GitHub enforces

What is enforced is what the project's ruleset on the base branch requires — one line each here:

- **Required checks** on every pull request to the base branch, listed in the config's
  `ci.requiredChecks`; `/codeo:doctor`'s `ruleset` check reports any the base branch does not
  actually require. `qc-verdict` is the pipeline's own
  (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/qc-verdict.sh" <base> <head>`), and `scope.sh` decides which
  test suites a change needs, for CI and the local quality gate alike.
- **The live-dossier rule.** A send-back moves the dossier back to `.codeo/<N>/`, and the
  `qc-verdict` check fails closed on a live dossier the head still carries, so the open PR stays
  unmergeable until `/codeo:close` archives it to `done/` again.
- **No bypass.** The ruleset should require the checks and refuse every direct push to the base
  branch, repository admins included. The checks bind only as far as it does.

## A call is not a hand-off

`/codeo:plan`, `/codeo:implement` and `/codeo:triage` may *call* `/codeo:issue` when they turn up
real work belonging in an issue of its own. That is a call, not a hand-off: control returns to the
caller with a number, and the caller — not `/codeo:issue` — records it in its own dossier's
`## Outcome` and `## Log` line. `/codeo:issue` writes nothing into the running workflow's dossiers
even when called mid-flow; its own file lives under `.codeo/intake/`. `/codeo:triage` records the
number in its ledger.

## Spinning out subagents

Every flow delegates some work to subagents, and **every subagent runs on the configured subagent
model** — the config's `models.subagent`, `sonnet` when it is unset — and never on an omitted
`model`, because omitting it inherits the skill's own model. Pass that `model` explicitly on every
`Agent` dispatch, including the ones a `superpowers:*` skill makes on the flow's behalf
(`subagent-driven-development`'s implementers and reviewers, for one): the skill's pinned model is
for the flow's own judgment, not its delegates. A `fork` subagent cannot be held to this — it
ignores `model` and inherits — so use a named type.

**The one exception is `/codeo:qc`'s code reviewer**, which runs on the configured reviewer model
— `models.reviewer`, `opus` when unset — with a `description` that starts `QC review:`. The grader
has to be at least as strong as what it grades, and the review is the one delegated call whose
wrong answer ships.

The plugin enforces both with a `PreToolUse` hook (`hooks/subagent-model.sh`): while
`.codeo/active` exists in the session's checkout, any other dispatch is denied with the reason —
a fork, an omitted model, any model but those two (by name or as `claude-<name>-…`), or the
reviewer model without the `QC review:` description — so a flow that forgets finds out on the call
rather than on the bill. Outside a workflow — a checkout holding no lock — the hook allows
everything, and a missing or unusable config falls back to the defaults rather than breaking the
session.

Two rules that save more than the model choice does:

- **Don't spin an agent at all when a direct tool call answers the question.** An agent costs a
  whole context window to start. A known path is a `Read`; a known symbol is a `grep`. Agents earn
  their cost on open-ended questions, not lookups.
- **Say what you want back.** A subagent told "report in under 200 words" returns under 200 words;
  one told nothing returns everything it saw, and the caller pays for all of it.
