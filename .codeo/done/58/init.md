# Issue #58 — init

| | |
|---|---|
| Skill | init |
| Issue | #58 |

## Where this stands

Initialized. Branch `feat/run-record-host-checks-55` off `main` at `b92f9e0543cec4d148b198e29e39c86a6c6e04d0`, pushed.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/58 — Run and record the host checks for #55's Docker acceptance criteria |
| State | open · labels `enhancement` |
| Branch | `feat/run-record-host-checks-55` off `main` at `b92f9e0543cec4d148b198e29e39c86a6c6e04d0` |
| Board | Ready → In progress |

**Problem.** `/codeo:qc` for #55 marked criteria 1-5, 7 and 8 "untestable here — host check": the dev container has no `docker` and `/codeo:init` cannot run under the suite. #55 merged with those unproven, and #51 changes the same `devcontainer-start.sh`. The engineer runs the checks on the host and records, per criterion, the command run and what it printed; the result is recorded in the issue.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] Criterion 1: `/codeo:init #<N>` from the home container pushes the branch, assigns the issue and moves the card, writes no `.codeo/active` and leaves the checkout on `main`.
- [ ] Criterion 2: it prints the clone instructions with the branch URL and `codeo-<N>` filled in, and does not launch `claude --cloud`.
- [ ] Criterion 3: `/codeo:init` inside an issue container stops and says to run it in the home container.
- [ ] Criterion 4: the issue container's start prints `lock: took the lock for #<N>` and `.codeo/active` names the issue and branch.
- [ ] Criterion 5: `docker ps` and the window title show `codeo-home` / `codeo [home]` and `codeo-<N>` / `codeo [#<N>]`; the home start takes no lock.
- [ ] Criterion 7: each odd folder name starts with a valid name or a stated reason.
- [ ] Criterion 8: both containers run at once without touching each other's lock.
- [ ] Any criterion that does not hold is filed as its own issue.

**Out of scope.** Fixing what the checks find (each becomes its own issue); the non-blocking follow-ups from #55 (filed separately); automating the checks.

**Open at intake.** Q1 (who runs the checks, where recorded) was answered at filing: the engineer runs them, results in the issue.

## Log

- 2026-11-11 — initialized: branch feat/run-record-host-checks-55 off main at b92f9e0543cec4d148b198e29e39c86a6c6e04d0 · cost: 5m · sonnet-5-5 15k in + 266k cached / 2k out
