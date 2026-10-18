# The dossier protocol

Every skill in the pipeline writes one file the engineer reads, answers in, and hands back. This
file is the authority on where those files live, what they look like, and the rule that stops a
skill from moving on while a question is still open. `handoff.md` is the companion: that one
governs what the skills say to *each other*, this one governs what they say to the *engineer*.

## Where

`.codeo/<issue-number>/` at the repo root, one file per step. A local checkout, a dev container and
a hosted session write the same dossier files at the same paths.

```
.codeo/
  .gitignore          # two lines: `active` and `intake/`
  active              # the lock — see handoff.md
  intake/             # /codeo:issue's working copies — see *Intake* below
    new-order-export/
      issue.md        # being drafted; no number yet
    13/
      issue.md        # filed, waiting for /codeo:init
    triage/           # /codeo:triage's ledger.md and one file per run
    leases/           # one <resource>.md per held lock; waiting/<resource>-<N>.md per issue queued
  12/
    issue.md          # only when /codeo:issue ran
    init.md
    plan.md
    implement.md
    qc.md
    close.md
  done/
    9/                # a finished issue, archived by /codeo:close
```

The first skill to touch `.codeo/` creates the directory and writes a `.gitignore` holding the
lines `active` and `intake/` if one is not already there (`setup.sh` does the same). Keeping that
local means the project's root `.gitignore` never needs a line about agent tooling.

**The dossiers are tracked; the lock is not.** They are committed and pushed continuously, as
`## Durability` below describes, so an in-flight workflow is never bound to one machine.
`.codeo/active` stays ignored: it is per-checkout state, and committing it would conflict on every
merge between two engineers on two branches, and would silently reassign the active issue whenever
someone checked out a branch. `.gitignore` itself **is** committed — it has to be, or `active` is
not ignored on the second machine.

Every workflow has its own checkout (`handoff.md` → *The lock*), so each sees its own
`.codeo/<N>/` and nothing of another's until it is pushed. `.codeo/intake/` is per clone too,
being ignored; that is harmless, because the intake branch is the authoritative copy and
`intake.sh restore` fills in whatever a clone lacks.

The dossiers are the whole per-issue record — there is no other. Each file holds both where a
decision got *made*, at full fidelity with the dead ends left in (`## Questions`, `## Notes`), and
what the decision *was* (`## Outcome`), so a reader after the fact reads the outcomes top to bottom
and drops into the questions only for the why. What the *application* does is a different record
with a different reader: the project's documentation (`docsDir` in the config, and the optional
`wiki` module's pages), which `handoff.md` describes.

`/codeo:issue` runs before the issue has a number, so it writes `.codeo/intake/new-<slug>/` and
renames the directory to `.codeo/intake/<N>/` once the issue is filed. `/codeo:init` adopts that
`issue.md` into `.codeo/<N>/` on the branch it cuts, rather than objecting that it already exists.

There is always an `<N>` to key on, because `/codeo:init` is the only way into the flow and it
binds each workflow — each issue checkout — to one issue: `.codeo/active` alongside these
directories is that lock, and `handoff.md` governs it. A skill that finds no lock has not found a
dossier to degrade to; it has found that no workflow is running, and it stops.

`/codeo:close` moves an issue's directory to `.codeo/done/<N>/` when it opens the pull request, so
the archive merges with the change — nothing is committed to the base branch after the merge. A
review send-back or a stash moves it back to `.codeo/<N>/`; where the directory sits is how `close`
tells an open PR that is waiting from one whose review work is in flight. What sits at the top
level is work someone is actively changing. Nothing is ever deleted — a closed issue's dossier is
the best record of why it closed the way it did.

## Durability

`## Outcome` is only written at a hand-off, once the step's questions have closed. Everything
between hand-offs — a plan stopped on five open questions — is questions and notes, and it is just
as worth keeping:

**Any turn in which a skill writes its dossier file ends with that file committed and the branch
pushed.** Both moments count: stopping with questions open, and writing `## Outcome` at a
hand-off. The first matters more, because that is the one that hands control back to a human for
an indefinite stretch.

- Subject line `docs(codeo): <step> dossier for #<N>`, optionally with a short clause —
  `— Q1-Q5 raised`, `— round 2`. The scope names the tooling, apart from the project's own
  commit scopes.
- **Stage explicit paths.** The dossier file, and nothing else, ever. Never `git add -A`: a skill
  that sweeps unrelated work into its own commit has stolen it. Other changes in the tree stay
  unstaged and are not this skill's business.
- `.codeo/active` is gitignored and never appears in one of these commits.
- **A failed push is loud but not fatal.** The commit survives locally, so say plainly that
  continuing on another machine will not work until the push lands — then carry on rather than
  unwinding work over it.

This does not contradict `/codeo:plan` leaving the plan file (under `plansDir`) unstaged for
review. A plan is an artifact awaiting the engineer's approval, and committing it would presume
that approval. A dossier is the record of an exchange the engineer already took part in; there is
nothing in it left to approve.

`/codeo:issue` cannot do this on a feature branch — it runs before one exists, and nothing here
ever commits to the base branch. It commits to the intake branch instead, below.

## Intake

`/codeo:issue`'s dossiers live on their own branch, `codeo/intake`, which holds nothing but
`.codeo/intake/` and never gets a pull request. `/codeo:triage` keeps its ledger and run files
there too, under `triage/`, through the same script, for the same reasons. Committing them to
whatever happens to be checked out would put one issue's dossier into another issue's PR; leaving
them untracked would lose a draft stopped on open questions with the machine it was on, and would
leave every other branch's `git status` cluttered — enough to stop `/codeo:init`'s clean-tree
preflight.

- **The working copy is ignored everywhere.** `.codeo/intake/` is in `.codeo/.gitignore`, so the
  engineer answers in place exactly as in any dossier, and no branch but the intake branch ever
  sees the file.
- **`bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" commit <dir> <message>`** is the commit. It
  builds the commit in a throwaway index and pushes it, so it never checks the intake branch out,
  never touches the real index, and works from any branch, dirty or clean. `--drop new-<slug>`
  records the rename to `<N>` in the same commit. Same subject convention as above, with the slug
  standing in for the number until there is one.
- **`bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" restore <dir>`** brings a dossier to a clone
  that lacks it — the second machine. It writes only files that are missing, never one that is
  present, because a present file may hold answers that have not been committed yet.
- **Several engineers push here at once.** A push that loses the race is rebuilt on origin's new
  tip and retried, which is safe because every writer owns a directory no other writer touches.
  The one shared file, `triage/ledger.md`, is merged row by row on fingerprint rather than
  overwritten. A local branch carrying unpushed commits for some *other* directory is the one
  thing the script will not paper over; it stops and names the path.
- **`intake.sh lease take|wait|release|release-all|check|list`** is how a step claims a lock on an
  exclusive resource — one the config's `resources[]` lists, or the `environment.resource` —
  `handoff.md` → *Parallel workflows*. The lease is `leases/<resource>.md` (`:` spelled `_`, so a
  parameterised resource `migrations:Orders` is `leases/migrations_Orders.md`), naming the issue,
  branch, engineer, time and purpose (an `environment.resource` lease taken with `--override` also
  carries an `override:` line with the reason); each issue waiting for it has its own
  `leases/waiting/<resource>-<N>.md`, so waiters never write the same file. Both are read from the
  branch, never from a local copy, and the push is the compare-and-swap.
- **Nothing is removed from the intake branch** except a `new-<slug>/` directory at its rename,
  the lease at its release, and a wait when its issue takes the lease or closes.
  After `/codeo:init` adopts a dossier, the copy on the feature branch is the live one and the
  intake copy is the record of it at filing.

## Ownership

**A skill writes one dossier file — its own — and may read all of them.** Same rule as every other
artifact in `handoff.md`, for the same reason. A skill that disagrees with what another one wrote
says so and stops.

## The shape of a file

```markdown
# Issue #12 — plan

| | |
|---|---|
| Issue | https://example.com/acme/shop/issues/12 |
| Branch | `feat/order-export` |
| Updated | 2026-03-04 |

## Where this stands

Round 2, after a send-back from `/codeo:qc`. The plan's task 3 assumed the export could read
orders directly; it cannot. Tasks 3-4 get rewritten once Q2 is answered.

## Questions

### Q1 — Export every order, or only the paid ones?

**Why it matters:** exporting every order adds a status column and a filter flag to task 2;
paid-only needs neither.
**Options:** every order · paid only · no preference, you pick.

**Answer:**
Paid only. Finance has asked for nothing else.

### Q2 — Which account should the export job read under?

**Why it matters:** decides whether the job needs a read-only role of its own or reuses the
service's.

**Answer:**

## Notes

Anything worth keeping that is neither a question nor part of the outcome yet.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-03-04 — Q1-Q2 raised · cost: 14m · fable-5-1 96k in + 1.2M cached / 18k out · sonnet-5 41k in + 380k cached / 4k out
```

- `## Where this stands` is rewritten each round; it is the skill's own summary of what it has
  done and what it is blocked on.
- `## Questions` only ever grows.
- `## Outcome` is the step's result, condensed for a reader who was in none of the conversations
  — what each skill puts there is in its own `SKILL.md`. It is written once, at the hand-off, and
  a later round after a send-back adds a dated `### Round <n>` beneath the first rather than
  rewriting it: how many rounds a change took is worth more to that reader than a tidy result.
- `## Log` gets one line per invocation, appended and never edited: the date, what the invocation
  did, then ` · cost: ` and the output of `bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" <skill>`
  — elapsed minutes, then one `<model> <fresh> in + <cached> cached / <out> out` group per model,
  all separated by ` · ` — or `cost: unavailable` when the script cannot run. `handoff.md` has the rule.

## The footprint

`plan.md`'s `## Outcome` ends with a `### Footprint`, the one block in any dossier written for a
script as well as a reader: `inflight.sh` prints it for every other workflow and `overlap.sh`
compares it, which is how two plans find out they touch the same thing. While `plan`'s pass is
still open the block sits under `## Notes` — both scripts read it wherever it is in the file — and
it moves to the end of `## Outcome` at the hand-off. Keys at the start of a line, values
comma-separated, inside a fence:

````markdown
### Footprint

```
files:      src/export/**, src/orders/**, docs/export.md
wiki:       Order-export, Home
exclusive:  migrations:Orders
sequenced:  after #7 — both add an Orders migration (Q6)
```
````

- `files` — globs, drawn from the plan's own File Structure; coarse is fine, missing is not.
- `wiki` — the page names the plan's documentation tasks change; read only when the project's
  `modules` include `wiki`, and inert otherwise.
- `exclusive` — names from the config's `resources[]` (a parameterised resource is written
  `<name>:<suffix>`). The shared environment resource is not declared here: the later steps lease
  it from the first environment task. Each is something two
  branches cannot both change and merge cleanly, and each is a lock `intake.sh lease` takes, one
  file per resource (`:` spelled `_`).
- `sequenced` — only when an overlap question was answered that way: which issue this waits for,
  why, and the question that decided it.

A key with nothing under it says `none` rather than disappearing, so a missing line means the
plan never looked, not that it found nothing.

## Questions, and the cycle

- **A question with an empty `**Answer:**` body is open.** That is the only definition of open
  there is: no status field, no checkbox, nothing for the engineer to maintain in two places. A
  `Status: OPEN` line is a protocol nobody implements.
- The skill never writes under `**Answer:**` and never edits an answer. It also never deletes or
  renumbers a question — numbers are unique within a file forever, so a later round starts at the
  next free one.
- An answered question stays where it is, with its answer. The Q&A *is* the reasoning;
  `## Outcome` carries only its conclusion.
- **Ask only the question that changes something.** `**Why it matters:**` is required, and it has
  to name what the skill would do differently either way. A question whose answer changes nothing
  is noise the engineer pays for.
- **State options when there are real options**, and say plainly when there are not.

## The gate

**No skill writes its `## Outcome` or hands off while a question in its own dossier is open.**

The cycle: write the questions, commit and push the file, print its path and the numbers still
open, and stop — the commit comes before the report, so what you are told about is what is
already safe. The engineer answers in the file. Re-invoking the skill resumes *from the file* — it
re-reads, picks up the answers, and either asks follow-ups as new numbers or proceeds. It does not
re-ask what the file already answers, and it does not carry on from a conversation that may have
been compacted away.

Rounds repeat until nothing is open. Then, in this order: write `## Outcome`, then hand off.
Publishing an outcome while a question is open publishes half a decision.

## Asking in the conversation instead

A question with two to four predetermined answers may go straight to the engineer with the
question tool — that is faster than a file round-trip and the answer is no less real. Record it
in the dossier once it comes back.

Everything else goes in the file: anything whose answer is a sentence of prose, and any batch of
more than about three questions at once.

The test is whether losing this conversation would lose the answer. If it would, it belongs in
the file.

## Intake questions are not dossier questions

The *Open at intake* list in `init.md`'s `## Outcome` is `/codeo:init`'s record of what the issue
left unresolved when the work started. It is history, and it is frozen: those are not questions
for the engineer, and `init` does not block on them.

A later skill that actually needs one of those answered raises it as a numbered question in its
*own* dossier and gets it answered there. `init.md` goes on saying the question was open at
intake, because it was; the later dossier's questions and `## Outcome` carry what it turned into.
