# Issue #122 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/122 |
| Branch | `feat/triage-s-flight-judging-103` |
| Updated | 2026-11-19 |

## Where this stands

Initialized: branch `feat/triage-s-flight-judging-103` cut off `origin/main` at `4a4572e9624bad14b5753a3f455190a31789b290` and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/122 — Triage's in-flight judging from #103: unstable fingerprint, resume through Ready, wrong waits line |
| State | open |
| Branch | `feat/triage-s-flight-judging-103` off `main` at `4a4572e` |
| Board | Ready → In progress |

**Problem.** `/codeo:triage`'s in-flight judgement (from #103) asks again or undoes a choice in two cases: an unassigned workflow's `parked:<N>:<touched date>` fingerprint changes with every push so a dismissal never holds (F14), and a resumed abandon passes through Ready so triage proposes a `board.sh set <N> backlog` fix that would undo the resume (F18). `inflight.sh` also prints `step: close (working)` / `waits: nothing known` for a resumed stash still planning (F19). The rest is wording: what *resume* names when `waits:` has no step (F13), `docs/handoff.md` and `docs/skills.md` out of step with the script (F20, F21), and two small robustness notes in `inflight.sh` (F22, F23).

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] Dismissing an unassigned workflow's question, then pushing to its branch, does not raise it again (or the stated limit is in the docs).
- [ ] With a live abandon at Ready, triage raises no `board:<N>:Ready` question that proposes `board.sh set <N> backlog`.
- [ ] `inflight.sh` on a resumed stash still in planning prints `/codeo:plan` as what it waits on.
- [ ] *Resume*'s wording covers each `waits:` value that carries no step.
- [ ] `docs/handoff.md` lists `nothing known`; `docs/skills.md:224` describes the `/codeo:close` case.

**Out of scope.** F15 (a live stash not seen in a project kept in a subdirectory; the limit is in `claim.sh`), F16 and F17 (older or hand-edited dossiers only, CR handling), and findings #103's rounds fixed.

**Open at intake.** How long a dismissal of an unassigned-workflow question lasts was left open at #103's Q4; the issue accepts either a fix that holds across pushes or a documented limit, so `/codeo:plan` picks one. Main moved since filing (#133 merged), so re-check line references (`skills/triage/SKILL.md:134`, `scripts/inflight.sh:279-284`, `docs/skills.md:224`).

## Log

- 2026-11-19 — initialized: branch feat/triage-s-flight-judging-103 off main at 4a4572e · cost: 4m · sonnet-5-5 16k in + 332k cached / 2k out
