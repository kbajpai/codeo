# Issue #145 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/145 |
| Branch | `fix/close-102-126-122-leftovers` |
| Updated | 2026-11-21 |

## Where this stands

Explored `scripts/doctor.sh`, `scripts/claim.sh`, `scripts/inflight.sh`, `skills/issue/SKILL.md`, `skills/triage/SKILL.md`, `docs/handoff.md`, `CHANGELOG.md`, the three archived `qc.md` files and the tests that pin each (`tests/doctor.test.sh`, `tests/issue-skill.test.sh`, `tests/claim.test.sh`, `tests/inflight.test.sh`, `tests/triage-skill.test.sh`). Five choices change what gets built and are raised as Q1-Q5. Everything else is settled and listed under `## Notes` as the calls the draft will make. Q1-Q5 answered as recommended; the draft is at `.codeo/145/plan-draft.md` for the review gate.

## Questions

### Q1 — `review — dossier archived`: correct the pages, or change what `inflight.sh` prints (#122 F1)?

**Why it matters:** the acceptance criterion accepts either, and they are different pieces of work. Correcting the pages is three wording edits and their checks. Changing the script means `waits_of` has to learn the pull request's state, and its header says the `touched:`, `waits:` and `verdict:` lines are read from the pushed branch only, with no network call.
**What is there now:** `inflight.sh` prints `review — dossier archived` for every dossier under `.codeo/done/<N>/` on a branch whose archive is not yet on the base branch (its internal token is `pr-open`, but nothing checks for a pull request). `skills/triage/SKILL.md` step 5 and `docs/handoff.md` say the line means a pull request is awaiting review. Triage already reads the pull request's state itself (`pr list-for-branch`, for the board comparison), and its board table already sends "no pull request, or closed unmerged" to `/codeo:close`.
**Options:**
- Correct the pages (recommended). `docs/handoff.md` and the `inflight.sh` header say the line means "the dossier is archived and the archive is not on the base branch yet", whether or not a pull request is open. Triage's *resume* for this value names the pull request to review when one is open, and `/codeo:close` in that issue's checkout when there is none or it was closed unmerged, using the state it already read. `inflight.sh` prints what it prints today.
- Change the script. `waits_of` asks GitHub for the branch's pull request and prints `review — dossier archived` only when one is open, and something else (`/codeo:close`) otherwise. This makes the human block of `inflight.sh` depend on `gh` and the network, and needs a rule for when the call fails.

**Answer:**
Correct the pages, as recommended (engineer, in the conversation, 2026-11-21: "I accept all your recommendations").

### Q2 — A *resume* answer on an unassigned workflow: keep asking each run, or stop (#122 F5)?

**Why it matters:** it decides whether the plan adds one sentence to `skills/triage/SKILL.md` or changes which answers triage's ledger treats as final, with the wording checks and `docs/skills.md` line that go with that.
**What is there now:** a workflow with no assignee is asked about with the fingerprint `unassigned:<N>`. *Dismiss* holds for good. *Resume* names the step to run and records nothing that stops the question, so it is asked again on every run until someone is assigned. The skill does not say this.
**Options:**
- State it as intended (recommended). One sentence: *resume* on an unassigned workflow names the step and does not assign anyone, so the question returns each run until the workflow has an assignee; *dismiss* is the answer that stops it. No behaviour change. This matches *fix it* on a board mismatch, which also returns while the mismatch persists.
- Stop on *resume*. Triage records `unassigned:<N>` → `resume` and does not ask again. The cost: a workflow nobody owns stops being reported after one answer, even if nobody ever takes it up.

**Answer:**
State it as intended, as recommended (engineer, in the conversation, 2026-11-21: "I accept all your recommendations").

### Q3 — What counts as "a test covers `touched_of`" (#122 F3)?

**Why it matters:** `tests/inflight.test.sh` already has nine `touched_*` cases that run `touched_of` through the `touched:` line. What has no test is the one branch #122 added: the dossier dates are still read when the branch tip's date does not parse. The #122 plan left it untested on purpose because git's `%cs` always parses, so the branch cannot be reached with a real repository. The answer decides whether the plan adds a test that fakes git, or records the criterion as met by the existing cases.
**Options:**
- Add a case with a fake `git` (recommended). The test puts a small `git` wrapper first on `PATH` that prints `not-a-date` for `log -1 --format=%cs` and passes every other call to the real git, then asserts the `touched:` line names the dossier date and source. The proof includes a mutation: restoring the old early return must make the case fail. About 20 lines in `tests/inflight.test.sh`; no change to `inflight.sh`.
- Record it as already covered. The plan names the nine existing cases against the criterion and adds no test. The unparsable-tip branch stays unpinned.

**Answer:**
Add a case with a fake `git`, as recommended (engineer, in the conversation, 2026-11-21: "I accept all your recommendations").

### Q4 — The engineer names a priority outside the four at the gate: what does `/codeo:issue` do (#102 F5)?

**Why it matters:** `skills/issue/SKILL.md` step 6 gets one new sentence, and the sentence differs by option. Step 7 only files a `priority:` label that `label list` printed, so today an outside name ends up as an issue with no priority label and a "missing label" report, which is not what the engineer asked for.
**Options:**
- Ask again, naming the four (recommended). The skill says only `blocker`, `high`, `medium` and `low` are accepted and asks which. Same shape as the existing rule for "no priority": say why, ask again.
- Accept any existing `priority:` label. If the repository has, say, `priority: urgent`, file with it; otherwise ask again. `doctor.sh` would still check only the four.

**Answer:**
Ask again, naming the four, as recommended (engineer, in the conversation, 2026-11-21: "I accept all your recommendations").

### Q5 — `docs/handoff.md` and `scripts/inflight.sh` are also in #144's scope. How do the two changes share them?

**Why it matters:** #144 (`fix/close-108-leftovers-overlap-sh`, assigned to kbajpai, at `init` with its `plan.md` waiting on Q1-Q2, a live session on it) has no footprint yet and its branch has changed nothing, so there is no printed overlap to compare. Intake recorded that #144 will edit `docs/handoff.md` and `scripts/inflight.sh`. This plan edits both: in `docs/handoff.md` the "Who else is in flight" paragraph, and in `scripts/inflight.sh` only comments (the header's `waits:` description and the comment above `waits_of`). The answer sets the footprint's `sequenced:` line and whether implementation waits for #144 to merge.
**Options:** proceed and coordinate · sequence after #144 · re-scope.
**Recommendation:** sequence after #144, as intake noted. This plan's edits to both files are wording and comments, so rebasing them onto #144's result is cheap, and #144 changes the script's code. If #144 is expected to sit for a while, *proceed and coordinate* is also safe: the last task runs `bash scripts/sync-main.sh` first and keeps both sides on a conflict.
**Not yet knowable:** #143 (`fix/codeo-host-command-close-leftovers`, at `init`, waiting on its Q1-Q6) has no footprint either. Both it and #144 will very likely add a `CHANGELOG.md` bullet, as this plan does. `overlap.sh` will print that once they have footprints, and it is raised then as its own question.

**Answer:**
Sequence after #144, as recommended (engineer, in the conversation, 2026-11-21: "I accept all your recommendations").

## Notes

Calls the draft will make, none of which needs an answer (say so in any answer above if one is wrong):

- **One plan, one pull request.** The engineer asked triage for one consolidated issue. Shape: a plan under `docs/plans/`, no reference doc; nothing here is a standing decision.
- **#102 F1: a string `"true"` is off in both places.** The #102 plan's Global Constraints already say a string is off, and `doctor.sh` implements that. `skills/issue/SKILL.md` step 5 changes to read `config.sh get '.issue.priority == true'` and act on `true`, as the QC proposed. `doctor.sh` does not change for F1.
- **#102 F2:** one sentence in step 5: with the setting on, the general label pass proposes no `priority:` label, so the priority pass's one label is the only one. Step 7 says the call carries exactly one `priority:` label.
- **#102 F5 (quoting):** `doctor.sh` prints `bash "<plugin root>/scripts/github.sh" label create '<label>'`, the path in double quotes. A new `tests/doctor.test.sh` case runs doctor from a plugin root whose path has a space and executes the printed command against the `gh` stub.
- **#126 F1:** the header's sentence about another issue's merged-and-left branch "whose title derives N's name" is reworded for what can still happen (a branch pushed under #N's name by hand) and its remedy becomes rename or delete, with no retitling.
- **#126 F2:** the last message becomes `… is not a pipeline branch — rename or delete it on origin`, matching the header. The three messages that say "retitle #N only for an issue reopened after its merge" stay: they are about a reopened issue, not a branch `init` cut, and `tests/claim.test.sh` and `skills/init/SKILL.md` pin them.
- **#126 F3:** the "was pushed by hand" clause goes; the message says what the code can show (the branch carries #M's dossier and not #N's) and keeps the remedy. `tests/claim.test.sh:328` pins only the part that stays.
- **#122 F2:** `CHANGELOG.md`'s `## Unreleased` bullet for #122 is edited in place: "(or the step before the park)" becomes the step after the last one finished before the park. A new bullet for #145 is added.
- **#122 F4, located.** The comment the QC cites is above `waits_of` (`scripts/inflight.sh:236-237`): "looking past a spent stash or abandon (a `close` outcome that no rule above took)". It presents the two as the same thing. The code steps past *any* `close` outcome no earlier rule took, which also covers a live stash whose `claim.sh --stash-live` check failed. The comment, the header's line 22 and `docs/handoff.md`'s "looking past a spent stash or abandon" are reworded to say so. No code change.
- **Out of scope, as the issue says:** #126 F4 and F5, #102 F3 and F4, #131's leftovers.
- **No environment, no lease, no host tasks, no invariants, no wiki module.** The lock's host is `container`; every task is proved by `bash tests/run.sh` or one test file.
- `engineering:system-design` and `engineering:architecture` are not installed here and not needed: no new component or architectural choice.

### Footprint

```
files: scripts/doctor.sh, scripts/claim.sh, scripts/inflight.sh, skills/issue/SKILL.md, skills/triage/SKILL.md, docs/handoff.md, docs/skills.md, CHANGELOG.md, tests/doctor.test.sh, tests/claim.test.sh, tests/inflight.test.sh, tests/issue-skill.test.sh, tests/triage-skill.test.sh, docs/plans/2026-11-21-close-102-126-122-leftovers-145.md
wiki: none
exclusive: none
sequenced: #144
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-21 — Q1-Q5 raised · cost: 1m · fable-5-2 84k in + 542k cached / 8k out
