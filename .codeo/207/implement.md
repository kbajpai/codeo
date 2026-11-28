# Issue #207 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/207 |
| Branch | `feat/207-stop-parallel-issues-colliding-shared` |
| Updated | 2026-11-28 |

## Where this stands

Round 1, done. All 13 tasks of `docs/plans/2026-11-28-parallel-issue-collisions-207.md` are built and reviewed, the build passes and the whole suite ends `all cases passed`. Next step: `/codeo:qc`.

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

## Log

- 2026-11-28 — implemented: all 13 tasks, build and suite pass · cost: 55m · sonnet-5-5 1.2M in + 39.7M cached / 191k out
