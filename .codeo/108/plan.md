# Issue #108 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/108 |
| Branch | `feat/follow-ups-97-left-overlap` |
| Updated | 2026-11-19 |

## Where this stands

Exploration is done and no plan is drafted yet. Every item in the issue was checked against `main` at `4a4572e`: six are already met there (listed under `## Notes`), the rest stand. Q1-Q5 are open; the draft starts once they are answered. The calls I made without asking are under `## Notes`, so they can be corrected in the same pass.

## Questions

### Q1 — When `overlap.sh` cannot diff, what should the pair mode (`overlap.sh <N>`) do?

**Why it matters:** a mistyped `--base` or `--head` is already refused on `main` (`overlap: cannot resolve <ref>`, exit 1). What `changes()` still swallows is a diff that fails for another reason: `origin/<base>` not fetched, or two refs with no merge base. In `--outside` mode that is the gate passing on an empty list, and the plan makes it exit 1 with `overlap: cannot diff <base>...<ref>` either way. The open part is the pair mode, whose header promises "Exit 0 always": every skill runs it at every step and reads an empty output as "no overlap". The answer decides whether that contract and the header change, and how many cases `tests/overlap.test.sh` gains.
**Options:**
- **A — fail on this branch's own diff, warn on another's (my pick).** In both modes a failed diff of this branch exits 1 with the `cannot diff` line: nothing can be compared without it. In pair mode a failed diff of another workflow's branch prints `overlap: cannot diff #<M> (<branch>)` on stderr and carries on with that workflow's footprint, exit 0, so one broken branch elsewhere does not stop this one. The header's "Exit 0 always" becomes "exit 1 on a usage error or when this branch cannot be diffed".
- **B — `--outside` only.** Pair mode keeps swallowing every diff failure and its "Exit 0 always"; only the gate mode changes. Smallest change, and the silent "no overlap" stays.
- **C — fail on any failed diff.** Pair mode exits 1 for another workflow's failed diff as well. Strictest, and one unrelated branch with a broken history stops every other workflow's steps.

**Answer:**
A, my pick, as the engineer chose in the session ("Accept all your recommendations", 2026-11-19): a failed diff of this branch exits 1 in both modes; in pair mode another workflow's failed diff warns on stderr and carries on. (Transcribed by the skill from the engineer's chat answer.)

### Q2 — `beyond-50`: a case shaped like two pages, or only a comment that says it cannot page?

**Why it matters:** the `gh` stub prints what `--jq` would have produced, one canned reply per call, so it cannot page; the issue puts a paging stub out of scope. Today half (b) of the case (a card 60th in the rows) passes against the old code. The answer decides whether `tests/board.test.sh` gains a case or only loses a misleading one.
**Options:**
- **A — a two-page-shaped reply (my pick).** With `--paginate` the `--jq` filter runs once per page, so a first page holding none of the owner's items prints the blank row (`<url>` and four empty fields) before the second page's real row. The case feeds exactly that (`blank row`, then the card's row) to `status` and `set` and asserts the card is found, its Status read, and no `item-add` made. That exercises the per-page blank-row path F20 named, which no case reaches today. The comment says plainly that the stub cannot page and that only the `--paginate` and `endCursor` greps prove the request; the 60-row half goes, since it proves nothing. If the new case fails against today's `board.sh`, that is a bug in `set` (it would add a second card), and the plan fixes it in the same task.
- **B — comment only.** Drop the 60-row half, keep the two greps, and say the stub cannot page. Honest, and the blank-row path stays unexercised.

**Answer:**
A, my pick, as the engineer chose in the session. (Transcribed.)

### Q3 — The two CHANGELOG clauses are in the released `## v1.0.7` section. Edit them in place?

**Why it matters:** both clauses sit on `CHANGELOG.md:32`, under `## v1.0.7 — 2026-11-18`, which is tagged. The answer decides whether the plan rewrites a released entry or leaves it and corrects it from `## Unreleased`.
**Options:**
- **A — edit in place (my pick).** The `board.sh` clause becomes "`board.sh set` reads every page of an issue's project items" (the "so an issue on a large board is found" reason goes: `lookup` reads the issue's own `projectItems`, about one per project it is on). The host-task clause becomes "`/codeo:plan`'s rule for tasks the engineer runs on their own host, which v1.0.6 introduced, is now stated consistently: …". The new `## Unreleased` bullet says the two v1.0.7 clauses were corrected. The changelog on `main` then differs from the one in the `v1.0.7` tag by those two clauses.
- **B — leave v1.0.7 as released.** The `## Unreleased` bullet carries the correction ("v1.0.7's entry said …; in fact …") and line 32 is untouched. The acceptance criterion "the two CHANGELOG clauses match the code" is then met only by reading both entries together.

**Answer:**
A, my pick, as the engineer chose in the session: edit the two clauses in place and note the correction under `## Unreleased`. (Transcribed.)

### Q4 — After a `lock: TODO` that follows a taken lock, should `/codeo:init` hand off to `/codeo:plan`?

**Why it matters:** `skills/init/SKILL.md:341,349` says that after any `lock: TODO` line "there is no lock", and withholds the hand-off. `scripts/lock.sh` prints some TODOs after writing the lock (the volume or sandbox name it could not read, an upstream it could not set), and `docs/handoff.md`'s `init — no lock` row already says such a TODO "needs the fix alone". Making the two agree can be done in wording only, or by changing what init does; the issue rules out "changes to the pipeline's behaviour", so this one is yours.
**Options:**
- **A — wording only (my pick).** Init keeps withholding the hand-off after any `lock: TODO` and keeps the no-lock closing block, but stops saying there is no lock: a TODO means the lock step left something undone, and whether a lock exists is told by `lock.sh`'s own `took the lock` or `lock already taken` line. The closing block's first step is the fix the TODO names; then, when the lock was taken, `/codeo:plan`, and otherwise `lock.sh take local` again, as the handoff row says. No behaviour changes; one extra turn in the rare case.
- **B — hand off when the lock was taken.** Init reads the `took the lock` line: with it, a TODO is quoted as a fix to make and `/codeo:plan` runs next in the same session; without it, the no-lock block as today. Matches the handoff row most closely, and it is a behaviour change to init's step 11 and its closing blocks (and their cases in `tests/closing-exits.test.sh` and `tests/init-skill.test.sh`).

**Answer:**
A, my pick, as the engineer chose in the session: wording only. (Transcribed.)

### Q5 — Two neighbours of the listed items: take them in this plan, or leave them for triage?

**Why it matters:** both came up while checking the issue's items, and neither is in its Key Requirements. Each adds files to the footprint, which is what #102 and #122 (both at `init`, no footprint yet) will be compared against.
**Options, per item:**
- **(a) `overlap.sh --outside --head` with a live (non-`done/`) plan path is untested** (#97's implement minors). One case in `tests/overlap.test.sh`, a file this plan already changes. **My pick: take it.**
- **(b) The unanchored `/^## Outcome/` match also sits in `scripts/inflight.sh` (four places) and `scripts/dossier-check.sh` (one).** The issue names `qc-verdict.sh` only. Taking it adds two scripts and two test files to the footprint. **My pick: leave it**, recorded under `## Notes` as later work for `/codeo:triage` to collect.

Answer with *take* or *leave* for each, or "your picks".

**Answer:**
Your picks, as the engineer chose in the session: (a) take it, (b) leave it. (Transcribed.)

## Notes

**Already met on `main` at `4a4572e`** (checked by reading the files; the plan changes none of their text and adds a pin only where the list says none exists):

- `overlap.sh`: a `--base` or `--head` that does not resolve is an error (`overlap: cannot resolve <ref>`, exit 1), with cases in `tests/overlap.test.sh`. So the first half of criterion 1 already holds; `--base ""` still exits 0.
- `overlap.sh`'s header describes `--base` given alone (lines 31-32). No behaviour case covers it; the plan adds one.
- `skills/qc/SKILL.md` step 6 agrees with step 8 about whose finding a footprint gap is (F13), pinned by `tests/qc-skill.test.sh`.
- `skills/qc/SKILL.md` step 6 says how a second plan round is detected, pinned by `tests/qc-skill.test.sh`.
- `skills/close/SKILL.md`'s abandon text is conditioned on the branch being kept (F12); `the last copy` is pinned in `tests/closing-exits.test.sh`. The two summaries (`docs/handoff.md:450`, `docs/skills.md:196`) still drop the exception (F17), and the plan fixes those.
- The issue's line references have moved: `skills/init/SKILL.md:321,329` is now `341,349`; `docs/handoff.md:391` is `450`; `docs/skills.md:190` is `196`; the CHANGELOG clauses are on line 32.

**Calls I made without asking** (say so in any answer to change one):

- One pull request, one plan under `docs/plans/`, no reference doc: nothing here is a standing decision.
- An empty `--base ""` or `--head ""` exits 1 with `overlap: --base needs a ref` (or `--head`), and the usage text becomes two lines so the flags no longer read as valid without `--outside`.
- `qc-verdict.sh` anchors both `## Outcome` matches as `^## Outcome[[:space:]]*$`. The two new cases: a pull request that delivers a round-2 archive and otherwise only adds files under `docs/plans` and `.codeo` passes with no "footprint omits"; a `plan.md` whose `### Round 2` sits outside `## Outcome` is treated as one-round and not checked. A third case pins the anchor (`## Outcomes` is not `## Outcome`). The comment above `touched` gains the clause that only delivered archives are footprint-checked.
- Test guards: `title-read-fails` asserts the exit code the script gives today (the implementer reads it from a run, the plan does not guess it); `case_close_step17_lead` and the `and not blocking by rule:` check match on flattened text; `row_for` matches the whole first cell of a table row; `bites` clears its `RETURN` trap. Each gets a mutation in `bites` (or, for `qc-skill`, a `QC_SKILL` copy) that re-wraps the guarded text and must fail.
- `docs/handoff.md`'s `abandon — finished` row and `docs/skills.md`'s close summary gain the exception: no checkout clean-up when the unmerged branch was deleted, since the checkout is then the last copy. A case in `tests/closing-exits.test.sh` and one in `tests/skills-doc.test.sh` pin them.
- No shared environment, no wiki module, no invariants document and no exclusive resources are configured, so the plan has no lease tasks and `wiki:` and `exclusive:` are `none`. The lock's host is `container`, and no task needs the engineer's host: every proof is `bash tests/run.sh` or one test file.
- The `engineering:system-design` and `engineering:architecture` skills are not installed and not needed: no new component and no technology choice.

**Other workflows in flight** (`inflight.sh --except 108`, 2026-11-19): #102 `feat/codeo-issue-assign-every-filed` and #122 `feat/triage-s-flight-judging-103`, both assigned to kbajpai, both at `init` with plan questions open, `changed: none`. Neither has a footprint yet, so there is nothing to compare beyond that; the check runs again at the hand-off.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-19 — Q1-Q5 raised · cost: 2m · fable-5-2 114k in + 1.2M cached / 11k out
