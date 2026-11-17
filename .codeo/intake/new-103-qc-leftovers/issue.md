# Issue — issue

## Questions

**Q1. Scope.** From /codeo:triage run 2026-11-17-4 Q2: #103's non-blocking F13, F14, F18-F23 become one new issue.
**Answer:** engineer: "file both".

## Draft

**Title:** Triage's in-flight judging from #103: unstable fingerprint, resume through Ready, wrong `waits:` for a resumed stash, and doc gaps

**Labels:** `enhancement`

### Description

`/codeo:triage`'s in-flight judgement (from #103, merged as #120) has two behaviours that make it ask again or undo a choice, one wrong `waits:` line, and several wording gaps. #103's QC recorded them as non-blocking.

### Motivation / Context

From `.codeo/done/103/qc.md` (on `origin/main`), rounds 2-3:

- **F14** — "An unassigned workflow is asked about whatever its date, and its fingerprint `parked:<N>:<touched date>` changes with every push. So an active, unassigned workflow is asked about again after each touch, and a dismissal does not hold." How long a dismissal lasts was left open at Q4.
- **F18** — "an abandoned workflow being resumed passes through Ready while the abandon is still live. In that window, the next triage run asks a `board:<N>:Ready` question whose *fix it* (`board.sh set <N> backlog`) would undo the engineer's choice." Triage only names the command and the question can be dismissed, so nothing is lost; the table (`skills/triage/SKILL.md:134`) should expect Ready, or either, for an abandon about to be resumed.
- **F19** — "a resumed stash still in the middle of planning printed `step: close (working)` and `waits: nothing known`, when `/codeo:plan` is owed." The step fallback (`scripts/inflight.sh:279-284`) has no next step for `close`; it should "look past a stashed `close.md` round to the step before it".
- **F13** — *resume* says to "name the step its `waits:` line shows", which has no step to name when `waits:` is `engineer — …`, `review — dossier archived` or `nothing known`, or for an unassigned workflow with no stash that is not over the threshold.
- **F20** — `docs/handoff.md` (*Who else is in flight*) lists the `waits:` values with `review — dossier archived` last and omits `nothing known`.
- **F21** — `docs/skills.md:224` says a board mismatch is named "with its `board.sh set` command"; with no PR, or a PR closed unmerged, it names `/codeo:close` in that checkout instead.
- **F22** — `touched_of` returns early when the branch tip's date does not parse, before reading the dossier dates; git's `%cs` always parses, so this cannot be reached today.
- **F23** — `close_send_back`'s `/^## Outcome/` is a prefix match (consistent with `last_qc_round`) and the comment above it does not say rounds are read only inside `## Outcome`.

### Key Requirements

- A dismissal of an unassigned-workflow question holds across pushes, or the docs state how long it lasts.
- A resumed abandon does not raise a `board:<N>:Ready` question whose fix undoes the resume.
- A resumed stash that is still planning reports the step that is owed, not `nothing known`.
- *Resume* for a quiet workflow says what to name when `waits:` has no step.
- `docs/handoff.md` and `docs/skills.md` match what the script and the skill do (F20, F21); F22 and F23 are fixed or noted in a comment.

### Acceptance Criteria

- [ ] Dismissing an unassigned workflow's question, then pushing to its branch, does not raise it again (or the stated limit is in the docs).
- [ ] With a live abandon at Ready, triage raises no `board:<N>:Ready` question that proposes `board.sh set <N> backlog`.
- [ ] `inflight.sh` on a resumed stash still in planning prints `/codeo:plan` as what it waits on.
- [ ] *Resume*'s wording covers each `waits:` value that carries no step.
- [ ] `docs/handoff.md` lists `nothing known`; `docs/skills.md:224` describes the `/codeo:close` case.

### Out of Scope

- F15 (a live stash is not seen in a project kept in a subdirectory: the limit is in `claim.sh` and predates #103), F16 and F17 (older or hand-edited dossiers only, CR handling): not in this issue.
- Findings #103's rounds fixed.

### Reference

- `.codeo/done/103/qc.md`, rounds 2-3, F13, F14, F18-F23 (on `origin/main`)
- `skills/triage/SKILL.md`, `scripts/inflight.sh`, `docs/handoff.md`, `docs/skills.md`
- `/codeo:triage` run 2026-11-17-4, Q2
