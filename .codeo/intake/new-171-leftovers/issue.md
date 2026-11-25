# Issue (new) — issue

| | |
|---|---|
| Issue | not filed yet |
| Source | `/codeo:triage` run 2026-11-25-2, Q1 (`qc:171:H1-H6`), answered *file it* |
| Updated | 2026-11-25 |

## Where this stands

Claims re-checked on `origin/main` (README.md:27, :429, :447; `docs/handoff.md:3` "Seven pipeline skills" against `docs/skills.md:5` "Six skills"; `docs/updating.md` has no restart line in "Updating superpowers"; `tests/readme.test.sh:52-56`, `:72-81`). No open issue covers them (search printed nothing; #170, #173, #176, #177 read earlier). Three questions open before the draft goes to the review gate.

## Questions

### Q1. Scope: the three items the #171 plan promised but that are not H1-H6
**What:** `implement.md` also lists "how another project adopts the role guard" (undocumented), the "Seven pipeline skills" miscount, and the awkward list/code indentation in README "Setting a project up". The draft below includes all three.
**Why it matters:** the role-guard item is a writing task with a decision in it (which page), unlike the one-line fixes.
**Options:** (a) all in one issue, as drafted (recommended) · (b) drop the role-guard item to its own issue · (c) drop the three extras
**Answer:**

### Q2. Priority
**What:** `issue.priority` is on. Proposed `priority: low` — "polish, cleanup, or a follow-up nobody is waiting on" (rubric line 4). Nothing breaks if it waits.
**Options:** low · medium · other
**Answer:**

### Q3. Type and labels
**What:** this repository has no Issue Types, so none is set. Proposed label: `documentation`.
**Options:** as proposed · change
**Answer:**

## Draft

**Title:** Close the #171 leftovers: README wording, two test guards, and the handoff and role-guard docs

### Description
Close the non-blocking findings `/codeo:qc` recorded for #171 (H1-H6) and the three items its plan promised to file. None has an issue.

### Motivation / Context
Each is a place where the docs say something that is untrue on one path, or a test guard that cannot fail the way its header suggests.

### Key Requirements
- H1: README.md "Checks from /codeo:doctor": the last two entries (the `extraKnownMarketplaces` source mismatch, a hand-edited `ref`) are `claude plugin` and `install.sh` problems `scripts/doctor.sh` does not check; give them their own heading or reword the intro.
- H2: README.md "Start here" step 6 says to merge the pull request "and see the workflow finish"; the workflow finishes only when `/codeo:close` is run again after the merge, as README.md's walkthrough says.
- H3: README.md's `lock: TODO` advice to run `/codeo:init #<N>` also catches the diverged and stale-local TODOs of `scripts/lock.sh:94,103,115`, which say to reconcile by hand and re-run; say so.
- H4: `tests/readme.test.sh` heading slugs lack GitHub's `-1` suffix for a repeated heading, so a link to one would fail falsely.
- H5: `tests/readme.test.sh` path checks for a user's project (`docs/plans/`, `.codeo/config.json`) pass only because codeo uses itself; the header should say so.
- H6: `docs/updating.md` "Updating superpowers" gives no advice to restart open Claude Code sessions after `claude plugin update superpowers@…`.
- `docs/handoff.md:3` says "Seven pipeline skills"; `docs/skills.md:5` says six.
- How another project adopts the role guard is not documented.
- List and code-block indentation in README "Setting a project up" renders awkwardly in strict Markdown.

### Acceptance Criteria
- [ ] The doctor-checks intro in README.md describes only what `scripts/doctor.sh` checks, and the two non-doctor entries sit under their own heading or are labelled as such.
- [ ] README.md "Start here" step 6 says the workflow finishes on the second `/codeo:close`.
- [ ] The README lock entry separates the TODOs a fresh `/codeo:init` fixes from the ones that say to reconcile by hand.
- [ ] A repeated heading's link resolves in `tests/readme.test.sh`, and the header names which path checks hold only because codeo uses itself.
- [ ] `docs/updating.md` "Updating superpowers" says to restart open sessions.
- [ ] `docs/handoff.md` and `docs/skills.md` give the same skill count.
- [ ] A page tells another project how to adopt the role guard.
- [ ] "Setting a project up" renders as intended in a strict Markdown renderer.
- [ ] `bash tests/run.sh` passes, in a clean worktree too.

### Out of Scope
Changing doctor, the lock script or the installer. Findings already in #173, #177 or #170.

### Reference
`.codeo/done/171/qc.md` round 3 (H1-H6); `.codeo/done/171/implement.md` ("Not in this plan, to file", "Parked, minor"); PR #178; surfaced by `/codeo:triage` run 2026-11-25-2, Q1.

## Log

2026-11-25 — claims verified on origin/main; draft and Q1-Q3 written
