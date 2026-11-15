# Issue #70 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/70 |
| Branch | `feat/guard-home-only-skills-against` |
| Updated | 2026-11-15 |

## Where this stands

Round 1. All ten tasks of `docs/plans/2026-11-15-guard-home-only-skills.md` are built and committed (`7840b47` to `5976610`), each task and the whole branch reviewed, and `bash tests/run.sh` prints `all cases passed` at the head (`5976610`); the build (`true`, the `shell` suite's `build`) is ok. The branch already contains `origin/main`.

Stopped before the hand-off on Q1-Q4: `overlap.sh 70` printed overlaps with four workflows that began after the plan was approved (#71, #96, #97, #98). The code is finished; these decide only how the four pull requests merge. The hand-off to `/codeo:qc` waits for them.

## Questions

### Q1 — Overlap with #71 on `CHANGELOG.md`, `docs/handoff.md`, `docs/skills.md`, `docs/skills-inventory.md`, `skills/issue/SKILL.md`, `skills/triage/SKILL.md`, `tests/inventory.test.sh`, `tests/fixtures/skills-inventory.rules.sha256` and more: proceed and coordinate, sequence after #71, or re-scope?

**Why it matters:** #71 (branch `feat/file-new-issues-straight-board`, assignee kbajpai, step `plan`, working) plans to change the same files, and two of them are pinned: both branches add rule bullets to `docs/skills-inventory.md`, so both change `tests/fixtures/skills-inventory.rules.sha256` and the counts in `tests/inventory.test.sh`, and whichever merges second must re-run `bash tests/inventory.test.sh --update` and recount, not just resolve a text conflict. *Proceed* means the later branch merges `origin/main`, keeps both sets of bullets and regenerates the fixture; *sequence* means this branch merges first (it is already built) and #71 rebases; *re-scope* has no sensible form here, since every file is needed. The printed overlaps, verbatim: `CHANGELOG.md`, `docs/handoff.md`, `docs/skills-inventory.md`, `docs/skills.md`, `glob:CHANGELOG.md`, `glob:docs/handoff.md`, `glob:docs/skills-inventory.md`, `glob:docs/skills.md`, `glob:skills/issue/SKILL.md`, `glob:skills/triage/SKILL.md`, `glob:tests/board.test.sh`, `glob:tests/closing-exits.test.sh`, `glob:tests/fixtures/skills-inventory.rules.sha256`, `glob:tests/inventory.test.sh`, `glob:tests/issue-skill.test.sh`, `glob:tests/triage-skill.test.sh`, `skills/issue/SKILL.md`, `skills/triage/SKILL.md`, `tests/fixtures/skills-inventory.rules.sha256`, `tests/inventory.test.sh`.
**Options:** proceed and coordinate · sequence after #71 (recommended: this branch is built and reviewed; #71 is still at `plan`) · re-scope.

**Answer:**

### Q2 — Overlap with #96 on `.devcontainer/README.md` and `CHANGELOG.md`: proceed and coordinate, sequence after #96, or re-scope?

**Why it matters:** #96 (branch `feat/dev-container-follow-ups-40`, assignee kbajpai, step `plan`, working) plans to change `.devcontainer/README.md` and `CHANGELOG.md`, and its footprint also names `tests/devcontainer.test.sh`, `tests/codeo-root.test.sh` and `tests/env.test.sh`. Here the README gains two sections and a changed table row, and `CHANGELOG.md` one bullet. *Proceed* means a text merge in each; *sequence* means one waits. This branch does not touch `devcontainer.json`, any `.devcontainer` start script or those tests. The printed overlaps, verbatim: `.devcontainer/README.md`, `CHANGELOG.md`, `glob:.devcontainer/README.md`, `glob:CHANGELOG.md`, `glob:tests/codeo-root.test.sh`, `glob:tests/devcontainer.test.sh`, `glob:tests/env.test.sh`.
**Options:** proceed and coordinate (recommended: the README edits are in separate sections) · sequence after #96 · re-scope.

**Answer:**

### Q3 — Overlap with #97 on `docs/skills.md`, `docs/handoff.md`, `skills/close/SKILL.md`, `skills/plan/SKILL.md`, `skills/triage/SKILL.md`, `CHANGELOG.md` and more: proceed and coordinate, sequence after #97, or re-scope?

**Why it matters:** #97 (branch `docs/docs-skill-wording-test-guard`, assignee kbajpai, step `init`, working: it has no plan of its own yet, so only its footprint is known) lists `docs/skills.md` and `tests/skills-doc.test.sh`, which pin the exact shape of `docs/skills.md` that this branch also changes (a new `## cleanup` section, a `role-guard` bullet in every skill's *Extension points*). A wording guard added there could fail on text this branch adds, or the reverse. *Proceed* means whichever merges second reruns `bash tests/run.sh` and adjusts; *sequence* means this branch goes first. The printed overlaps, verbatim: `CHANGELOG.md`, `docs/handoff.md`, `docs/skills.md`, `glob:CHANGELOG.md`, `glob:docs/handoff.md`, `glob:docs/skills.md`, `glob:skills/close/SKILL.md`, `glob:skills/plan/SKILL.md`, `glob:skills/triage/SKILL.md`, `glob:tests/board.test.sh`, `glob:tests/close-skill.test.sh`, `glob:tests/closing-exits.test.sh`, `glob:tests/overlap.test.sh`, `glob:tests/plan-skill.test.sh`, `glob:tests/qc-verdict.test.sh`, `glob:tests/skills-doc.test.sh`, `skills/close/SKILL.md`, `skills/plan/SKILL.md`, `skills/triage/SKILL.md`, `tests/plan-skill.test.sh`.
**Options:** sequence after #97 is not recommended (it has not planned yet) · proceed and coordinate (recommended: this branch merges first, #97 plans against `origin/main` and sees the new text) · re-scope.

**Answer:**

### Q4 — Overlap with #98 on `skills/plan/SKILL.md`, `tests/plan-skill.test.sh` and `CHANGELOG.md`: proceed and coordinate, sequence after #98, or re-scope?

**Why it matters:** #98 (branch `fix/fix-sync-main-sh-exiting`, assignee kbajpai, step `qc`, working) has already changed `skills/plan/SKILL.md`, `tests/plan-skill.test.sh` and `CHANGELOG.md` on its branch, and `scripts/sync-main.sh` and `tests/sync-main.test.sh` too. This branch adds a `role-guard` paragraph and a refused-call sentence to `skills/plan/SKILL.md`, and two assertions to `tests/plan-skill.test.sh`. #98 is at `qc`, so it is likely to merge first; *proceed* then means this branch merges `origin/main` (as `/codeo:implement` does at the start of every round) and keeps both. The printed overlaps, verbatim: `CHANGELOG.md`, `glob:CHANGELOG.md`, `glob:skills/plan/SKILL.md`, `glob:tests/plan-skill.test.sh`, `glob:tests/sync-main.test.sh`, `skills/plan/SKILL.md`, `tests/plan-skill.test.sh`, `tests/sync-main.test.sh`. (`tests/sync-main.test.sh` appears only because #98's footprint names it as a glob; this branch does not touch it.)
**Options:** proceed and coordinate (recommended: #98 is nearly through and the later branch merges `origin/main`) · sequence after #98 · re-scope.

**Answer:**

## Notes

**What was built**, one commit per plan task (task numbers as in the plan): Task 1 `7840b47` the role script and its test · Tasks 2, 3 and 5 `e46fa9e`, `252c97e` the `role-guard` point, rule and step in seven skills, their overlays and the pin test · Task 4 `35a2f43` callers record a finding the guard refuses to file · Task 6 `27c6f11`, `ea6eb62` `scripts/cleanup.sh` (plus a fix for a fail-open branch proof) · Task 7 `9323ef4` the `/codeo:cleanup` skill, its overlay point and inventory section · Task 8 `ba0bb09`, `1103fb7` `/codeo:close`'s host removal commands (plus a fix: the overlay path now carries "not inside this container" and `git status` first) · Task 9 `b22a7a7` documentation · final-review fix wave `5976610` (stale refusals say the issue is finished; `cleanup.sh` refuses a clone whose fetch refspec does not cover every branch; literal-safe name replacement). Task 10 was run by hand: the suite, `doctor.sh` (all ok), no change to `.devcontainer/Dockerfile` or `devcontainer.json`, and `role.sh` in this container (`issue:70`; `--check init` exits 1; with `CLAUDE_CODE_REMOTE=true` it exits 0).

**Deviations from the plan.**
1. `scripts/github.sh` gained a verb `pr get <n>` (state, `merged_at`, `head_ref`) and `tests/github.test.sh` one case. The plan assumed `pr view` returned those fields; it returns only the merge state. The engineer approved the new verb in the conversation. `overlap.sh --outside 70` prints `scripts/github.sh`: the plan's footprint does not list it.
2. Task 2's test was committed with Task 5's overlays, not with Task 3, and lists seven skills until Task 7 added `cleanup`, so that the suite is green at every commit.
3. Task 7 registers the overlay point `cleanup/removal-command` and its docs example uses a neutral command (`remove-container {name}`), so `docs/` names no container engine.
4. The overlays' `role-guard` text keeps "exit 2: report its `role:` line and go on": a fault in the project's own check disables the guard instead of blocking every skill. A stale container cannot reach exit 2. Ruled by the controller; the reviewer called it acceptable.

**Deferred minors** (not fixed, none blocks): `tests/role.test.sh` mode and thin matrix coverage; `-A3` window in the role-guard test; cleanup's issue-view failure reads as `failed issue`, and one unreadable PR aborts the whole report; no test for an invalid overlay regex or an `origin/HEAD` symref; skill description and `docs/skills.md` intro say "home container only" in generic text; the closing block's first step is "run the printed commands" even when every command is `-`; wording of the stale row and of the removal section in `.devcontainer/README.md` (partly fixed); `docs/skills-inventory.md` intro wording.

**Rulings taken while building** are in the controller's ledger, not repeated here; the one that changes behaviour is item 4 above.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-15 — built Tasks 1-10 and the final-review fix wave; Q1-Q4 raised on overlaps with #71, #96, #97, #98 · cost: 97m · sonnet-5-5 1.2M in + 35M cached / 196k out
