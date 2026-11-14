# Issue #69 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/69 |
| Branch | `feat/fix-closing-blocks-that-name` |
| Updated | 2026-11-14 |

## Where this stands

Q1-Q3 answered as recommended. The plan is drafted in `.codeo/69/plan-draft.md` and waits for the
engineer's approval; nothing is open.

## Questions

### Q1 — Where does the rule "name only a command that can run in the state this exit leaves" live?

**Why it matters:** intake left this to the plan. It decides whether the fix is four independent
wording edits or one rule the four exits are instances of, and what the new test reads.
`docs/handoff.md → Closing block` already says "a skill with several exits states the one it
took", but says nothing about the named command having to be runnable, and its default-next-goal
table gives `init → /codeo:plan` and `issue → /codeo:init #<N>` with no exceptions. Today's
`tests/closing-block.test.sh` checks only that each skill cites the section.
**Options:**
- **A — the rule once in `docs/handoff.md`, the exits in the skills (recommended).** The
  *Closing block* section gains one bullet stating the rule, and its table gains the exception
  rows (lock kept, stash interrupted, `lock: TODO`, not Ready). Each of the four skills states its
  block per exit and cites the rule. The test checks the bullet exists, and for each of the four
  exits that the step's text names the command that can run and does not name the one that
  cannot. A fifth skill that later grows a failing exit has a rule to be held to.
- **B — four edits to four skills, nothing in `docs/handoff.md`.** Smallest diff; the test
  checks the four exits only. The rule stays unwritten, so the next skill can repeat the fault.

**Answer:**
A — the rule once in `docs/handoff.md`, the exits in the skills (answered in the conversation: "as recommended for all three").

### Q2 — What does `/codeo:issue`'s closing block say when it cannot read the new issue's board Status?

**Why it matters:** intake left this to the plan. `/codeo:issue` can read the Status itself:
`board.sh status <N>` needs only the config and `gh`, both of which the skill already uses, and
holds no lock. The clear cases follow from the acceptance criteria: no board (`config.sh get
.board` exits 1) makes no call and names `/codeo:init #<N>` as today; the Ready status names
`/codeo:init #<N>`; `none`, `unset` or any other column names `/codeo:triage` first, then
`/codeo:init #<N>`. Two outcomes are not covered by the criteria:
- `unavailable` (a hosted web session, where the proxy refuses GraphQL). `/codeo:init` treats
  this as a pass and continues (rule init-06), so `/codeo:init #<N>` can run.
- a script failure, most likely the `gh` token lacking the `project` scope. `/codeo:init` stops
  on it, and so would `/codeo:triage`'s *mark Ready*.

**Options:**
- **A — mirror what `/codeo:init` would do (recommended).** `unavailable`: name
  `/codeo:init #<N>`, and say above the block that the Status could not be read. A script
  failure: quote the script's line, make its fix (for example `gh auth refresh -s project`) the
  first step, then `/codeo:triage`, then `/codeo:init #<N>`. Every named command can run.
- **B — anything but a read of the Ready status names `/codeo:triage` first.** One rule, simpler
  to test, but in a web session it sends the engineer to a *mark Ready* that `board.sh set`
  refuses there, and after a script failure to a triage that fails the same way.

**Answer:**
A — mirror what `/codeo:init` would do (answered in the conversation: "as recommended for all three").

### Q3 — How does `/codeo:plan` decide what shell a host-run command is written for?

**Why it matters:** #67's Task 3 was `docker run --rm -v "$PWD":/src:ro … safe.directory "*" …`,
written for bash, and failed in your PowerShell. The plan skill has no notion of a task the
engineer runs on their own host, so nothing told it to check. The session cannot see your host:
this lock says `host: container`, and a container or web session's shell says nothing about the
machine you type the command on. Only a `host: local` session shares your shell. The answer
decides whether this is skill text and a test, or also a config key.
**Options:**
- **A — a rule in `skills/plan/SKILL.md`, no config (recommended).** A task the engineer runs
  outside the session's checkout starts with `Runs on: the engineer's host`. Its command is
  written shell-neutral: no shell variable or substitution (`$PWD`, `$(…)`), no nested quotes, no
  `&&` or line continuation, anything longer moved into a script in the repository and run as one
  command. Where a command cannot be made neutral, the plan asks which shell you use as a
  numbered question in `plan.md` and labels the command `Shell: <name>`. With `host: local` the
  session's own shell is the answer and no question is asked. Costs one question in the rare plan
  that needs it; `tests/plan-skill.test.sh` pins the wording.
- **B — a `hostShell` key in `.codeo/config.json`.** Asked once and never again, but the config is
  the project's, not one engineer's: on a team with both shells it is wrong for someone, and it
  adds a key to the config schema for a rare case.
- **C — every host command given twice, labelled `bash` and `PowerShell`.** Never asks, but
  doubles each host task, and the variant nobody ran is unproved.

**Answer:**
A — a rule in `skills/plan/SKILL.md`, no config (answered in the conversation: "as recommended for all three").

## Notes

- Decided by the plan, as intake delegated it: **one pull request.** A codeo workflow is one
  issue, one branch and one pull request, so a split would need a second issue; the dev container
  wording is three sentences, and both parts write the same `CHANGELOG.md` `## Unreleased` entry.
- Shape: a plan under `docs/plans/` (a scoped, executable body of work). No overlay for
  `plan-shape`, `proof-of-done` or `wiki-rules`, so the generic shape and the `shell` suite's
  `bash tests/run.sh` apply (the suite has no `filter`). No invariants document, no shared
  environment, no `wiki` module, no exclusive resources.
- `inflight.sh --except 69`: no other workflow in flight.
- What the exploration found, for the draft:
  - `skills/close/SKILL.md` step 16 keeps the lock when step 14's release or deletion fails, but
    step 17's block is the same on every exit (`/codeo:triage`, then the checkout clean-up). The
    stash's block names `/codeo:init #<N>` although the paragraph above it keeps `.codeo/active`
    when a release or a push failed; a failed board move is written to `close.md` and never
    reaches the block.
  - `skills/init/SKILL.md` step 11 says "quote the line and stop rather than hand off", then
    "Either way, end with the closing block … the first step `/codeo:plan`".
  - `skills/issue/SKILL.md` step 8 names `/codeo:init #<N>` unconditionally and never reads the
    board.
  - Pages that restate these and move with the change: `docs/handoff.md` (*Closing block* and its
    table), `docs/skills.md` (the `issue`, `init` and `close` sections).
  - The skill wording tests (`tests/close-skill.test.sh`, `init-skill.test.sh`,
    `issue-skill.test.sh`, `plan-skill.test.sh`) share a `must_contain` / `step_contains` /
    `text_order` form the new cases can follow.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — explored, Q1-Q3 raised · cost: 2m · fable-5-2 91k in + 576k cached / 10k out
- 2026-11-14 — Q1-Q3 answered as recommended, plan drafted in plan-draft.md, awaiting approval · cost: 8m · fable-5-2 95k in + 693k cached / 10k out · sonnet-5-5 106k in + 399k cached / 14k out
