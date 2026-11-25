# Issue #166 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/166 |
| Branch | `docs/close-157-leftovers-hosted-web` |
| Updated | 2026-11-25 |

## Where this stands

Round 2 is written and the verdict is clear: round 1's F1 and F6 are fixed, all three criteria are met, and the review found no blocking finding. Nothing is open. Next step: `/codeo:close`.

## Questions

None.

## Notes

None.

## Outcome

### Round 1 — 2026-11-25

**Scope.** `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main` (exit 0, nothing to re-check). `overlap.sh 166`: nothing (exit 0). `overlap.sh --outside 166`: nothing (exit 0). `scope.sh origin/main HEAD`, quoted:

```
scope: suite shell needed for unclassified paths:
  .codeo/166/implement.md
  .codeo/166/init.md
  .codeo/166/issue.md
  .codeo/166/plan.md
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line and no `environment` configured, so no environment step. Diff: 17 files, 372 insertions, 19 deletions (`git diff origin/main...HEAD --stat`).

**Build.** The `shell` suite's `build` is `true`: exit 0.

**Suites.** `bash tests/run.sh` (the `shell` suite, whole): `all cases passed`, exit 0.

**Criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| Step 17 of `skills/close/SKILL.md`, for `host: web` and `host: local` with `CLAUDE_CODE_REMOTE=true`, does not say "nothing to remove" while a `codeo-live/<N>/*` branch remains; it names `git push origin --delete codeo-live/<issue>/<machine>`, and a test pins it | met | `skills/close/SKILL.md:537,543` ("no checkout to remove") and `:546-552` (the paragraph, covering `host: web` and any lock when `CLAUDE_CODE_REMOTE` is `true`); pins in `tests/close-skill.test.sh` (`step 17 names the web branch delete command`, `step 17 covers a hosted session whatever the lock's host`, the negative `step 17 still says nothing to remove`) |
| `skills/close/SKILL.md:3` and `docs/skills.md:185` carry the web-session exception, or say nothing the exception contradicts | met | both read "(a hosted web session deletes none: it cannot delete a branch)"; pinned by `the description has no web-session exception` and `docs/skills.md close section has no web-session exception` |
| A test of `scripts/cleanup.sh` with the `name` proof failing and a `codeo-live/<N>/<machine>` branch present on origin expects the `leftover` line | met | `tests/cleanup.test.sh`, case `an issue that failed only the name proof still gets its leftover line`; it fails against the old `scripts/cleanup.sh:134` |

**Documentation.** The plan names `skills/close/SKILL.md`, `.codeo/overlays/close.md`, `skills/cleanup/SKILL.md`, `docs/skills.md`, `docs/skills-inventory.md` and `CHANGELOG.md`; the diff changes each. `grep -rn "nothing to remove"` over `skills`, `docs` (bar the plan), `README.md`, the overlays and `.devcontainer/README.md` finds none left. One page still describes the old behaviour: F1.

**Independent review** (Opus, given the criteria only): no Critical, one Important (F1), five Minor. It ran the five affected test files and they pass, and found the `scripts/cleanup.sh:134` change, the ref-name allowlist, the step-17 text against `scripts/live.sh` (`read_lock`'s web override, `sweep`'s early return) and the test discrimination sound. Its assessment, in plain text: ready to merge with fixes.

**Findings**

- F1 — blocking, `/codeo:implement`'s: `docs/skills.md:252`, the `cleanup` purpose paragraph, still says "an issue that fails a proof is listed with it and no command". An issue that fails only `name` now gets the `leftover` branch delete, which line 254 of the same section says, so the section contradicts itself. The plan's Task 2 named `:252` and `:258`; the change reworded `:254` and `:258` and left this sentence. Fix: "no container command (one that failed only `name` still gets its leftover branch delete)".
- F2 — non-blocking, plan's: `skills/cleanup/SKILL.md` step 4 (the closing block) branches on "something was proven"; a run whose only output is a `leftover` line for a `failed name` issue has a command to run, and the block sends the engineer to `/codeo:triage` instead. The plan did not name step 4.
- F3 — non-blocking, plan's: `skills/close/SKILL.md:549-550` fills in the issue but leaves `<machine>` as written, as the acceptance criterion's wording and the plan's Q1 allow; `/codeo:cleanup` prints the exact name later. Naming where the label is saved (`<git dir>/codeo-live-machine`) would make the command usable at once.
- F4 — non-blocking, plan's: `skills/close/SKILL.md:547-548` says the session's branch "stays on `origin`", true only when a beat ever pushed. The plan accepted this (Global Constraints: the sentence is said in every hosted close).
- F5 — non-blocking, plan's: the `CHANGELOG.md:11` clause "or for an issue that failed only the `name` proof" is #166's behaviour and carries `(#157)`; the new `(#166)` bullet repeats it. The plan's Task 5 wrote both.
- F6 — non-blocking, implement's: `tests/close-skill.test.sh:225` keeps the case label "a local host has nothing to remove" beside the new negative check; the label is stale, the pin it labels is not.

No issue was filed from this pass. F2-F6 stay in this dossier for `/codeo:triage`.

**Verdict: back to `/codeo:implement`.**

### Round 2 — 2026-11-25

**Scope.** `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main` (exit 0). `overlap.sh 166`: nothing (exit 0). `overlap.sh --outside 166`: nothing (exit 0). `scope.sh origin/main HEAD`, quoted:

```
scope: suite shell needed for unclassified paths:
  .codeo/166/implement.md
  .codeo/166/init.md
  .codeo/166/issue.md
  .codeo/166/plan.md
  .codeo/166/qc.md
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line and no environment configured, so no environment step. Diff: 18 files, 463 insertions, 22 deletions.

**Build.** The `shell` suite's `build` is `true`: exit 0.

**Suites.** `bash tests/run.sh` (the `shell` suite, whole): `all cases passed`, exit 0.

**Criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| Step 17 of `skills/close/SKILL.md`, for `host: web` and `host: local` with `CLAUDE_CODE_REMOTE=true`, does not say "nothing to remove" while a `codeo-live/<N>/*` branch remains; it names `git push origin --delete codeo-live/<issue>/<machine>`, and a test pins it | met | `skills/close/SKILL.md:537,543` and `:546-552`; the reviewer ran the `close-skill` pins against the old skill in a scratch worktree and 7 cases failed |
| `skills/close/SKILL.md:3` and `docs/skills.md:185` carry the web-session exception, or say nothing the exception contradicts | met | both read "(a hosted web session deletes none: it cannot delete a branch)", pinned in `tests/close-skill.test.sh`; `docs/handoff.md:173` and step 16 say the same |
| A test of `scripts/cleanup.sh` with the `name` proof failing and a `codeo-live/<N>/<machine>` branch present on origin expects the `leftover` line | met | `tests/cleanup.test.sh`, case `an issue that failed only the name proof still gets its leftover line`; it fails against the old `scripts/cleanup.sh:134` |

**Documentation.** `docs/skills.md:252` now says "an issue that fails a proof is listed with it and no container command (one that failed only `name` still gets its leftover branch delete)", pinned in `tests/cleanup-skill.test.sh`, and agrees with lines 254 and 258. `grep -rn "nothing to remove"` over the skills, docs, README and overlays finds no close or cleanup sentence left that the change contradicts.

**Independent review** (Opus, given the criteria only): no Critical, no Important, four Minor; it re-ran the affected test files and the old-code mutations and they behave as stated. Its assessment, in plain text: ready to merge. Its Minor items are F2, F3 and F4 again, and the cleanup skill's frontmatter description, which names no leftover branch delete and predates this change.

**Findings**

- F1 (blocking in round 1) — fixed by `2b00571`: `docs/skills.md:252` says no container command, with the `leftover` exception.
- F6 — fixed by `2b00571`: the two stale test labels read "no checkout to remove".
- F2 — non-blocking, plan's, carried from round 1 and unchanged: `skills/cleanup/SKILL.md` step 4 branches on "something was proven", so a run whose only output is a `leftover` line for a `failed name` issue is sent to `/codeo:triage` first.
- F3 — non-blocking, plan's, carried: `skills/close/SKILL.md:549-550` leaves `<machine>` as written, as the criterion's wording allows.
- F4 — non-blocking, plan's, carried: `skills/close/SKILL.md:547-548` says the session's branch "stays on `origin`" even when no beat ever pushed.
- F5 — non-blocking, plan's, carried: the `CHANGELOG.md:11` clause for the `name` proof carries `(#157)`, and the `(#166)` bullet repeats it.

No issue was filed from this pass. F2-F5 stay in this dossier for `/codeo:triage`.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-25 — Round 1: build ok; shell suite passed; criteria 1-3 met; review one Important (F1, blocking) and five Minor; verdict back to implement · cost: 7m · opus-5-5 264k in + 2.2M cached / 10k out · sonnet-5-5 190k in + 455k cached / 653 out
- 2026-11-25 — Round 2: build ok; shell suite passed; criteria 1-3 met; round 1's F1 and F6 fixed; review four Minor, none blocking; verdict clear · cost: 7m · opus-5-5 305k in + 1.5M cached / 10k out · sonnet-5-5 22k in + 754k cached / 512 out
