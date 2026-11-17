# Issue #103 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/103 |
| Branch | `feat/let-codeo-triage-judge-flight` |
| Updated | 2026-11-17 |

## Where this stands

Q1-Q6 answered ("All as recommended", 2026-11-17). The plan is drafted at `.codeo/103/plan-draft.md` and waits for the engineer's approval; nothing is open.

## Questions

### Q1 — What does a workflow's block look like, and what counts as evidence for the date?

**Why it matters:** it fixes the lines every consumer of the human block sees, and whether `inflight.sh` makes a GitHub call per pull request on every run in init, plan, implement, qc and close.
**Proposal:** two lines always, one more when `qc.md` has a verdict, placed after `changed:` and before any `live:` line (the existing tests pin `assignee`/`step`/`changed` as consecutive lines, and `changed` followed by `live`; I would move that one `live` assertion down a line and change no other):

```
#116  fix/follow-ups-70-71-104
  assignee:  kbajpai
  step:      qc (working)
  files:      …
  changed:    …
  touched:   2026-11-17 (qc.md log), 0 days ago
  waits:     /codeo:implement
  verdict:   round 1 — back to /codeo:implement
  live:      kbajpai on codeo-116 (container), 3m ago
```

The date is the newest of three things read from the pushed branch: the tip commit's committer date, each dossier's `Updated` row, and the last dated line of each dossier's `## Log`. The source in brackets names which one won (`branch tip`, `<step>.md Updated`, `<step>.md log`); on a tie the dossier is named, since it says more than "branch tip". Days are whole calendar days between that date and today.
**Options:**
- **Git only, as proposed (recommended)** — no new network call. For a workflow with a pull request open, review comments do not move the date; triage, which already looks each branch's pull request up, quotes the pull request's state beside it.
- **Also the pull request's last update** — `inflight.sh` looks up the pull request of every workflow whose dossier is archived and takes its `updated_at` as a fourth source. One or two more REST calls per such workflow on every `inflight.sh` run, and `github.sh pr list-for-branch` gains an `updated_at` field (`scripts/github.sh` is in #116's footprint).
- **Something else** — say what.

**Answer:**
Git only, as proposed, as recommended (engineer, in the conversation, 2026-11-17: "All as recommended").

### Q2 — What can `waits:` say, and in what order of precedence?

**Why it matters:** it is the line triage quotes to decide whether a quiet workflow is stuck on the engineer or on nothing, and each value is a detection rule and a test.
**Proposal:** the first that applies:
1. `engineer — plan.md Q3, Q4` — any dossier in the directory has a question whose `**Answer:**` body is empty (the same definition `dossier-check.sh` uses). Every file with one is named, separated by `; `.
2. `resume — stashed (close.md round 2)` or `resume — abandoned (…)` — `close.md` has more stash or abandon rounds than `init.md` has resume lines (the count `claim.sh --stash-live` already makes). The issue does not list this one; without it a deliberately stashed workflow reads `nothing known`.
3. `review — PR open` — the dossier is archived at `.codeo/done/<N>/`.
4. `/codeo:close` after a clear verdict, `/codeo:implement` or `/codeo:plan` after a send-back — from `qc.md`'s last decision span, the pattern `qc-verdict.sh` reads.
5. `nothing known`.

`verdict:` is separate from `waits:` and printed whenever `qc.md` has a decision, so criterion 3 holds even when a question or an open pull request takes precedence.
**Options:** as proposed, with the stash line (recommended) · the issue's four only, no stash line · something else — say what.

**Answer:**
As proposed, with the stash line, as recommended (engineer, in the conversation, 2026-11-17: "All as recommended").

### Q3 — Do the new facts get a machine-readable form?

**Why it matters:** `--tsv` exists so status reporters need not scrape the blocks, and `tests/inflight.test.sh` compares its rows for exact equality. A reader that does `read -r issue branch state step assignee` would get any appended column glued onto `assignee`.
**Options:**
- **Human block only (recommended)** — triage reads the block; `--tsv`, `--branches` and `--live` print byte for byte what they print today. A machine-readable form waits until a reporter asks for one.
- **A new `--facts` listing** — `issue<TAB>touched<TAB>source<TAB>days<TAB>waits<TAB>verdict`, one row per workflow, no `gh` call, as #104 added `--live` and left `--tsv` alone.
- **Append columns to `--tsv`** — the first five keep their order; the equality tests are rewritten, and a five-variable `read` breaks as described.

**Answer:**
Human block only, as recommended (engineer, in the conversation, 2026-11-17: "All as recommended").

### Q4 — How is the parked threshold named and applied?

**Why it matters:** the key is public config once released, and where the comparison happens decides whether a script or the model's arithmetic settles "parked".
**Proposal:** `triage.parkedDays` in `.codeo/config.json`, a whole number of days, default 7, read by the skill with `config.sh get '.triage.parkedDays // 7'`; documented in `lib/env.sh`'s key list and in `docs/skills.md`'s triage section. No schema bump (an absent optional key). `inflight.sh` prints the day count (Q1) and knows nothing of the threshold; triage asks about a workflow when the count is greater than the threshold (7 days exactly is not parked) and quotes `touched:` and the threshold in the question. A workflow within it is listed in the run's `## Outcome` with its `touched:` and `waits:` lines and not asked about. The existing rules stay: a `live:` line means never asked as parked, and an unassigned workflow is still asked about whatever its date. The fingerprint is `parked:<N>:<touched date>`, so a dismissal or deferral holds only until the workflow is touched and goes quiet again.
**Options:** as proposed (recommended) · another key name or default — say which · `inflight.sh` takes the threshold and prints `parked: yes|no` itself, so the decision is a script's and has a script test.

**Answer:**
As proposed, as recommended (engineer, in the conversation, 2026-11-17: "All as recommended").

### Q5 — Which board Statuses count as a mismatch, and what does triage do with one?

**Why it matters:** the issue's example, `In progress` while a pull request is open, is the normal state after a review send-back (`/codeo:close` moves the dossier back to `.codeo/<N>/` and the card back to In progress with the pull request still open), so the rule has to key on where the dossier sits and not only on the pull request.
**Proposal:** triage runs `board.sh status <N>` for each workflow in flight and compares it with this table, naming statuses through `board.statuses` as everywhere else:

| What is pushed | Expected Status |
|---|---|
| dossier at `.codeo/<N>/`, not stashed or abandoned | In progress |
| dossier at `.codeo/<N>/`, last `close.md` round stashed | Ready |
| dossier at `.codeo/<N>/`, last `close.md` round abandoned | Backlog |
| dossier at `.codeo/done/<N>/`, pull request open | In review |
| dossier at `.codeo/done/<N>/`, no pull request or closed unmerged | none fits: always a mismatch |
| pull request merged | Done (the existing `unclosed:<N>` item covers the rest) |

A mismatch is a question of its own, fingerprint `board:<N>:<Status found>`, quoting the `board.sh status` line, the `step:` line and the pull request's state. Options: *fix it* (the `board.sh set <N> <status>` command, named and never run, because triage's own board writes stay Ready and Backlog) · *dismiss (why)* · *defer*. `none` or `unset` is a mismatch too. With no board configured the check is skipped and said once; when the read is `unavailable` (a web session) the run's `## Outcome` says the board comparison was unavailable, per `triage-07`.
**Options:** as proposed (recommended) · list mismatches in the run's `## Outcome` without asking · let triage write the expected Status itself on the engineer's yes (widens its board writes beyond Ready and Backlog, and changes `docs/handoff.md`'s ownership table).

**Answer:**
As proposed, as recommended (engineer, in the conversation, 2026-11-17: "All as recommended").

### Q6 — #116 edits two files this plan will edit; how do the two branches proceed?

**Why it matters:** two branches editing one file merge cleanly only when their hunks are apart.
**What overlaps:** #116, branch `fix/follow-ups-70-71-104`, assignee kbajpai, last finished step `qc` (working). Its footprint and its `changed:` line both name `CHANGELOG.md` and `docs/skills.md` (`glob:CHANGELOG.md`, `glob:docs/skills.md`). This plan adds one bullet to `## Unreleased` and edits the triage section of `docs/skills.md` (what it reads, and the new config key). It also names `scripts/github.sh`, which this plan touches only under Q1's second option. #99 (`feat/make-sbx-issue-sandbox-usable`, kbajpai, at `init`) has no footprint yet and has changed no file, so there is nothing to compare. This plan's other files: `scripts/inflight.sh`, `skills/triage/SKILL.md`, `lib/env.sh`, `docs/handoff.md` only if a sentence there turns out wrong (it is in #116's footprint too: `docs/handoff.md`, `glob:docs/handoff.md`), `tests/inflight.test.sh`, `tests/triage-skill.test.sh`.
**Options:**
- **Proceed and coordinate (recommended)** — the edits are small and apart from #116's; `/codeo:implement` and `/codeo:qc` merge `origin/main` each round, and the changelog and docs tasks re-read the lines they edit first.
- **Sequence after #116** — `/codeo:implement` waits for #116's merge. #116 is at `qc`, so the wait is probably short.
- **Re-scope** — say what to drop.

**Answer:**
Proceed and coordinate, as recommended (engineer, in the conversation, 2026-11-17: "All as recommended").

## Notes

**What exists today.** `inflight.sh` prints one block per workflow from pushed branches: `assignee`, `step` (the last step whose dossier has a non-pending `## Outcome`, with `working` or `PR open` from where the dossier sits), the footprint lines, `changed:` and `live:`. `--tsv` (five columns, compared for equality in the tests), `--branches` (read by `overlap.sh`) and `--live` are the machine forms. Triage step 1.2 reads the human block and has one sentence for parked work: "One whose last step is weeks old, or assigned to nobody, is worth asking about."

**Calls made without a question** (correct any of them in an answer):
- One pull request, one plan under `docs/plans/`, no separate reference doc. The pages that describe the behaviour (`docs/skills.md`, `lib/env.sh`'s key list, `inflight.sh`'s header) get their own task.
- The date is printed as `YYYY-MM-DD`; a commit's date is taken in the committer's own time zone, as git records it.
- An unparseable or missing `Updated` row or log date is skipped, never an error: the branch tip always gives a date.
- New tests go in `tests/inflight.test.sh` (script behaviour) and `tests/triage-skill.test.sh` (the skill's wording), the two existing homes.

**Other workflows in flight** (`inflight.sh --except 103`, 2026-11-17): #116 at `qc`, overlap in Q6; #99 at `init`, no footprint.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-17 — Q1-Q6 raised · cost: 2m · fable-5-2 94k in + 659k cached / 9k out
- 2026-11-17 — Q1-Q6 answered; draft written to .codeo/103/plan-draft.md (engineering plugin unavailable: system-design and architecture structure applied directly) · cost: 11m · fable-5-2 112k in + 1.1M cached / 15k out · opus-5-5 131k in + 956k cached / 18k out
