# Issue #207 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/207 |
| Branch | `feat/207-stop-parallel-issues-colliding-shared` |
| Updated | 2026-11-28 |

## Where this stands

Round 2, done, after the send-back from `qc.md` round 1 (F1-F6): all 7 tasks of `docs/plans/2026-11-28-parallel-issue-collisions-207-round-2.md` are built and reviewed, the build passes and the whole suite ends `all cases passed`. Next step: `/codeo:qc`.

## Questions

None.

## Notes

- Nothing out of scope was found that needed `/codeo:issue`.
- Deferred, non-blocking minors from the task reviews (for `/codeo:qc` to weigh): `tools/changelog.sh` keeps `\r` in CRLF fragments, leaves a blank line for a fragment with a trailing blank line, and does not refuse a version section that already exists; the inventory test has no case for an added rule (`rule <id> is not pinned`); `tests/close-skill.test.sh`'s exit-3 pin checks the whole `BEHIND` bullet, not its own sub-bullet; `tests/inventory-pin.test.sh` case 1 does not assert both rewords are present.
- Reach: this repository runs the plugin pinned at v1.0.10, so the new skill text (plan, init, qc, close) applies here after the next release and pin bump, both separate issues.
- Overlap with #213 (pull request #216, the v1.0.11 pin) on `README.md` and `.codeo/config.json` was answered *proceed and coordinate* at `plan.md` Q7; `scripts/overlap.sh 207` printed nothing at this round's start.

## Outcome

**Built.**
- Changelog fragments: `tools/changelog.sh` (`assemble vX.Y.Z YYYY-MM-DD`, `cat`) and `tests/changelog.test.sh`; `changelog.d/207.md` is this issue's entry; the convention is in `CONTRIBUTING.md` and release checklist step 6 uses `assemble`. A release assembled from the v1.0.11 bullets split into fragments gave the same bullet set (order is by issue number by design).
- Inventory pin: `tests/fixtures/skills-inventory.rules.sha256` is one `<id><TAB><sha256>` line per rule, written by `bash tests/inventory.test.sh --update`; `tests/inventory-pin.test.sh` merges two branches that each change a different rule with no conflict (and shows the same rule still conflicts).
- Overlap rule: a parameterised `skill` resource in `.codeo/config.json`; `/codeo:plan` lists `exclusive: skill:<dir>` and records every answered overlap question in `sequenced:` (rule `plan-11`); `/codeo:init` names the workflows holding a lease; `tests/overlap.test.sh` and `tests/intake-lease.test.sh` pin it (`overlap.sh` was not changed).
- QC and close: `/codeo:qc` records `Graded base: <sha>` after a clean sync and `Behind:` when it merged (rule `qc-16`); `scripts/base-moved.sh` names graded files the base changed since (it sees renames; stdout is paths only, diagnostics on stderr); `/codeo:close` step 9 runs it before merging a moved base and sends the engineer to `/codeo:qc` on exit 3 (rule `close-18`).

**Documentation pages changed:** `README.md`, `docs/skills.md`, `docs/dossier.md`, `docs/handoff.md`, `docs/release-checklist.md`, `CONTRIBUTING.md`, `docs/skills-inventory.md` (the three rules). `CHANGELOG.md` is not edited by design: the entry is the fragment.

**Build result:** the `shell` suite's `build` is `true` and passed; `bash tests/run.sh` ends `all cases passed`; `bash scripts/overlap.sh --outside 207` prints nothing.

**Deviations from the plan.**
- Task 2: the planned `## plan-shape` section of `.codeo/overlays/plan.md` was dropped. `templates/containers/.codeo/overlays/plan.md` renders into other projects and `tests/containers.test.sh` pins codeo's overlays to the templates; the convention lives in `CONTRIBUTING.md` and the suffix rule in `skills/plan/SKILL.md` instead. The footprint still lists `.codeo/overlays/plan.md` and `scripts/overlap.sh`; neither was changed.
- Task 6: the printed token for a literal `files:` entry nobody has written is `glob:<path>`, not the bare path; the test asserts that.
- Task 9: `--no-renames` on both diffs and stderr diagnostics were added after review (a base rename of a graded file was missed).
- Task 12: one pin in `tests/plan-skill.test.sh` and two sentences in `skills/plan/SKILL.md` were aligned with rule `plan-11` (`sequenced:` reads `none` only when no overlap was raised); `tests/init-skill.test.sh` and `skills/init/SKILL.md` gained two clarifications; the `Graded base:` line is written only after a sync that exits 0 (final review).
- Review: every task had a task review; tasks 1, 2, 9 and 12 went through a fix round, and a final whole-branch review found two Importants, fixed in one wave and re-reviewed. Tasks 12's last fix round and 13 had no separate re-review (their diffs are a few lines; the final review covered 13).


### Round 2

2026-11-28
(send-back from qc.md round 1)

**Built.**
- F2: `docs/skills-inventory.md` and the pin file separate rules by one blank line (rule texts and hashes unchanged); `tests/inventory.test.sh` fails a rule bullet that directly follows another and ignores blank lines in a pin; `tests/inventory-pin.test.sh` merges two branches that reword adjacent rules (`plan-01`, `plan-02`) with no conflict, and shows two rules appended after the same rule still conflict in the page.
- F4: rule `plan-11` gains `rescoped — <what was dropped> because of #M (Q<k>)` and `locked — <resource> behind #M (Q<k>)` (written for any exclusive overlap the lock answers, whether the lease is free or waited for).
- F5: `/codeo:init` reads `intake.sh lease list --tsv` and prints `#<M> holds <resource>` and `#<M> waits for <resource>`; it no longer reads footprints for this.
- F1 and F3: `/codeo:close` step 9 runs `base-moved.sh` on every pass after the pull, also when the branch already holds the base; exit 3 is a send-back through step 11 as a `### Round <n> — base moved` round (paths, `qc round at review: <k>`, un-archive, card back) to `/codeo:implement`, which re-checks the named files before `/codeo:qc`; `scripts/inflight.sh` and `scripts/dossier-check.sh` know the round; two dossier fixtures; rule `close-18` reworded.
- F6: `tools/changelog.sh` — any `Safe to bump mid-workflow:` value that does not begin with the whole word `yes` is a caution that wins, joined with `; `; `assemble` refuses an existing version section and a leftover `## Unreleased`; CRLF and trailing blank lines are tidied. `tests/intake-lease.test.sh` hard-codes the `skill` entry.

**Documentation pages changed:** `README.md`, `docs/skills.md`, `docs/dossier.md`, `docs/handoff.md`, `docs/release-checklist.md`, `CONTRIBUTING.md`, `docs/skills-inventory.md` (`plan-11`, `close-18`), `changelog.d/207.md` (rewritten).

**Build result:** the `shell` suite's `build` is `true` and passed; `bash tests/run.sh` ends `all cases passed`; `bash scripts/overlap.sh --outside 207` prints nothing. The adjacent-rules merge was reproduced by hand in a scratch repository: exit 0, no conflict.

**Deviations from the plan.**
- Task 4 also added `— base moved` to the step 1 phase-table rows, close-03's text, step 3's pull note, the skill description and the Non-goals hand-off bullet, so the round reads the same everywhere.
- Task 5: a safe-to-bump value that is neither `yes` nor `no` is treated as a caution (the plan said `no` wins); the first `yes` value is kept verbatim when no caution exists, so `Yes — fine` is written as written.
- Task 6 and 7: the fragment's wording was corrected once (`no longer`).
- Review: every task had a task review; tasks 1, 2, 4 (none), 5 went through fix rounds; the final whole-round review found no Critical or Important issue.

**Deferred, non-blocking (for `/codeo:qc` to weigh):** long unwrapped lines in `skills/close/SKILL.md` step 11; `skills/init/SKILL.md` lists "no resources configured" as a failure of the lease read though it prints nothing and exits 0; the inflight test asserts only the `/codeo:implement` leg; a stripped caution reason can keep stray punctuation (`No.` → `no — .`); two non-`no` cautions joined are not pinned; the README does not repeat close's one-line note for exit 4.

### Round 3

2026-11-28
(after plan.md round 3)

**Built.**
- F7, F8: `/codeo:qc` records `git merge-base HEAD origin/<base>` as a bare `Graded base:` line (rule `qc-16`, text and pin updated); `scripts/base-moved.sh` reads the last `Graded base:` line as a bare line, list item or in backticks, and compares from `git merge-base <sha> HEAD`; new cases cover the three forms, a sha newer than the graded tree, and the *Update branch* state; `docs/dossier.md` carries the same definition. One existing case ("an earlier Graded base line is ignored when a later one exists") now merges the later commit first, because an unmerged later sha is the false record the new rule compares from the merge base.
- F9, F10, F11: `tools/changelog.sh assemble` keeps every distinct `yes` note joined with `; `, defaults `Config schema:` to the newest section's number plus ` (unchanged)` (and refuses when it cannot read one), drops blank lines after a fragment's header, validates `vX.Y.Z` and `YYYY-MM-DD` (exit 2) and reports a missing `CHANGELOG.md` (exit 1).
- Text: close step 9 names the way on from exit 1 and step 11 the heading when review feedback and a moved base arrive together; plan and `docs/dossier.md` give the `; ` separator; the plan skill says a file with no directory segment where a wildcard stands names no lease; init's failure wording drops "no resources configured".

**Documentation pages changed:** `README.md`, `docs/skills.md`, `CONTRIBUTING.md`, `docs/release-checklist.md`, `docs/dossier.md`, `changelog.d/207.md`, `docs/skills-inventory.md` (`qc-16`).

**Build result:** the `shell` suite's `build` is `true` and passed; `bash tests/run.sh` ends `all cases passed`; `bash scripts/overlap.sh --outside 207` prints nothing; no file mode changed. F9 reproduced by hand in a scratch copy: two `yes` notes both appear in the assembled `Safe to bump mid-workflow:` line. The step 2a sync merged `origin/main` cleanly (1 commit); `also changed on main:` `.devcontainer/README.md`, `.devcontainer/scripts/session-title.sh`, `CHANGELOG.md`, `tests/devcontainer.test.sh`, `docs/plans/2026-11-28-session-title-sequence-181.md`, `.codeo/done/181/*` — none is a file this branch changed.

**Deviations from the plan.**
- Task 4 also reworded the `/codeo:close` exit-4 note in both pages and added the `assemble` exit-2 and `Config schema:` check lines to `CONTRIBUTING.md` and the release checklist (the plan listed them).
- Task 5: the whole-round review ran its suite once with a single failure in `overlay.test.sh` ("plan.md is not readable") that did not repeat alone or on rerun; this round changes nothing under overlay.
- Review: every task had a task review with no Critical or Important finding; the whole-round review (sonnet, per rule implement-06) found none either.

**Deferred, non-blocking (for `/codeo:qc` to weigh):** `scripts/base-moved.sh:7` and close step 9 say close "compares the graded commit with origin/<base>" though the script starts from the merge base (the header says so); an empty `Graded base:` value reads as exit 4 ("no Graded base line"); the schema default of a value like `1 → 2` is `1 (unchanged)`; long lines in qc-16 and `docs/dossier.md`; the diff error in `base-moved.sh` names `$sha`; the `yes` dedupe is case-sensitive; the close and plan skill pins are whole-file; the first fragment bullet does not mention the `yes` join.

## Log

- 2026-11-28 — implemented: all 13 tasks, build and suite pass · cost: 55m · sonnet-5-5 1.2M in + 39.7M cached / 191k out
- 2026-11-28 — round 2 implemented: all 7 tasks, build and suite pass · cost: 36m · sonnet-5-5 698k in + 35.5M cached / 127k out
- 2026-11-28 — round 3 implemented: all 5 tasks, build and suite pass · cost: 12m · sonnet-5-5 473k in + 7.9M cached / 53k out
