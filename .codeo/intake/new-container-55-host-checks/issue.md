# Issue (new) — issue

## Where this stands

Draft B of two issues from triage run 2026-11-11-2 (Q7).

## Questions

### Q1 — Who runs the host checks, and where is the result recorded?

**Why it matters.** The criteria need Docker and VS Code, which the dev container does not have, so the engineer runs them. The criterion differs: "recorded in the issue" versus "recorded in a doc".

**Options.** *engineer runs, results in the issue's closing comment* · *engineer runs, results in a doc under `docs/`*.

**Answer:** engineer runs, result in the issue (recommendation accepted at triage)

## Draft

**Title:** Run and record the host checks for #55's Docker acceptance criteria

**Type:** none (no Issue Types). **Labels:** `enhancement`.

### Description

Run, on the host, the checks for the acceptance criteria of #55 that the dev container could not prove, and record what each showed.

### Motivation / Context

`/codeo:qc` for #55 recorded criteria 1-5, 7 and 8 as `untestable here — host check`: the container has no `docker` and `/codeo:init` cannot run under the suite. The merge happened with those unproven. #51 changes the same `devcontainer-start.sh`, so a regression here would hide behind it.

### Key Requirements

- Rebuild the dev container, open the home container (`codeo-home`) and run `/codeo:init #<N>` on a real issue.
- Clone the pushed branch into `codeo-<N>` through "Dev Containers: Clone Repository in Named Container Volume…" and open it.
- Open the home and an issue container at once in separate windows.
- Try clone folders with a space, `+`, `@`, a non-ASCII character and a leading `.` or `_`.
- Record, for each criterion, the command run and what it printed.

### Acceptance Criteria

- [ ] Criterion 1: `/codeo:init #<N>` from the home container pushes the branch, assigns the issue and moves the card, writes no `.codeo/active` and leaves the checkout on `main`.
- [ ] Criterion 2: it prints the clone instructions with the branch URL and `codeo-<N>` filled in, and does not launch `claude --cloud`.
- [ ] Criterion 3: `/codeo:init` inside an issue container stops and says to run it in the home container.
- [ ] Criterion 4: the issue container's start prints `lock: took the lock for #<N>` and `.codeo/active` names the issue and branch.
- [ ] Criterion 5: `docker ps` and the window title show `codeo-home` / `codeo [home]` and `codeo-<N>` / `codeo [#<N>]`; the home start takes no lock.
- [ ] Criterion 7: each odd folder name starts with a valid name or a stated reason.
- [ ] Criterion 8: both containers run at once without touching each other's lock.
- [ ] Any criterion that does not hold is filed as its own issue.

### Out of Scope

- Fixing what the checks find (each becomes its own issue).
- The non-blocking follow-ups from #55 (filed separately).
- Automating the checks.

### Reference

- Issue #55 and PR #56; `.codeo/done/55/qc.md` round 1, criteria table.
- `.devcontainer/README.md`, "Opening a container".
- Triage dossier `2026-11-11-2.md`, Q7.
