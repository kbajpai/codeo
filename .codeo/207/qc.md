# Issue #207 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/207 |
| Branch | `feat/207-stop-parallel-issues-colliding-shared` |
| Updated | 2026-11-28 |

## Where this stands

Round 2 stopped at step 2: `overlap.sh 207` found a new overlap with #217 (Q2). Round 1 stands as written; the pass resumes from step 2 once Q2 is answered.

## Questions

### Q1 — #217 overlaps on `skills/init/SKILL.md`, `tests/init-skill.test.sh`, `docs/skills-inventory.md`, `tests/fixtures/skills-inventory.rules.sha256`, `README.md`, `docs/skills.md` and `docs/release-checklist.md`: proceed, sequence, or re-scope?

**Why it matters:** `overlap.sh 207` printed, for #217 (branch `feat/217-add-codeo-go-codeo-done`, assignee kbajpai, step `plan (working)`, waiting on `/codeo:implement`; its branch has changed only its plan file so far):

```
217	README.md
217	docs/release-checklist.md
217	docs/skills-inventory.md
217	docs/skills.md
217	glob:README.md
217	glob:docs/release-checklist.md
217	glob:docs/skills-inventory.md
217	glob:docs/skills.md
217	glob:skills/init/SKILL.md
217	glob:tests/fixtures/skills-inventory.rules.sha256
217	glob:tests/init-skill.test.sh
217	skills/init/SKILL.md
217	tests/fixtures/skills-inventory.rules.sha256
217	tests/init-skill.test.sh
```

Both change the `init` skill, which is the case this issue's `skill` lease exists for; #217's footprint says `exclusive: none` because the resource is only on this branch. Its footprint also lists `CHANGELOG.md`, which this branch replaces with fragments.

- Proceed and coordinate: this branch is built and in QC; it merges first, and #217 merges `main` at its next `/codeo:implement` round. The pin file then conflicts only line by line, and #217 writes `changelog.d/217.md` instead of editing `CHANGELOG.md`.
- Sequence after #217: this pull request waits for #217, which has not started implementing.
- Re-scope: this branch cannot avoid `skills/init/SKILL.md` (Task 8) without dropping a planned task.

I recommend proceed and coordinate, #207 merging first.

**Options:** proceed and coordinate (recommended) · sequence after #217 · re-scope.

**Answer:**
Proceed and coordinate, as recommended; #207 merges first. Given in the conversation: "go with your pick".

### Q2 — #217 now changes `tests/inventory.test.sh`: proceed, sequence, or re-scope?

**Why it matters:** `overlap.sh 207` printed `217	tests/inventory.test.sh`. #217 (branch `feat/217-add-codeo-go-codeo-done`, assignee kbajpai, step `qc (working)`, its QC round 1 sent it back to `/codeo:implement`, waiting on its `implement.md` Q1) adds rule `init-12`: it raises `init` to 12 in `tests/inventory.test.sh`'s `want` table, adds the bullet to `docs/skills-inventory.md` and rewrites the single-hash pin. This branch removed that `want` table, separates rule bullets with blank lines and makes the pin one line per rule. Q1 already covers `docs/skills-inventory.md` and the pin; this is the one new path.

- Proceed and coordinate: this branch merges first; #217's next `/codeo:implement` round merges `main` and resolves mechanically: drop its `want` edit (the table is gone), put a blank line before its `init-12` bullet, run `bash tests/inventory.test.sh --update`, which overwrites the pin, and write its changelog entry as `changelog.d/217.md`. This is the recovery `CONTRIBUTING.md` describes.
- Sequence after #217: this pull request waits until #217 merges, and this branch then resolves the same three files against #217's rule.
- Re-scope: not possible without undoing Task 3 of round 1.

I recommend proceed and coordinate, #207 merging first: it is the change that makes the next such conflict mechanical.

**Options:** proceed and coordinate (recommended) · sequence after #217 · re-scope.

**Answer:**
Proceed and coordinate, as recommended; #207 merges first. Given in the conversation: "proceed & coordinate".

## Notes

Round 1 so far (step 2):
- `sync-main.sh --abort-on-conflict` → `sync-main: merged origin/main (1 commit(s))`, `sync-main: also changed on main: .codeo/config.json` (the pin moved to `v1.0.11`; the branch's `resources` entry for `skill` is intact: `[{"name":"skill","paths":["skills/**","tests/*-skill.test.sh"],"parameterised":true}]`).
- Base graded this round, if it continues on this merge: `origin/main` at 13ac02c.
- `overlap.sh 207` → the lines quoted in Q1 (exit 0).

## Outcome

### Round 1 — 2026-11-28

Graded base: 13ac02c52f10b9b597c77bf8a67968e10319634f
Behind: merged 1 commit(s) from origin/main before grading

**Commands run** (this pass, tree merged with `origin/main` at `13ac02c`):
- `role.sh --check qc` → exit 0; lock `issue: 207`, branch `feat/207-stop-parallel-issues-colliding-shared`.
- `sync-main.sh --abort-on-conflict` → `sync-main: merged origin/main (1 commit(s))`, `sync-main: also changed on main: .codeo/config.json`; re-checked after Q1: the branch contains `origin/main`.
- `overlap.sh 207` → the #217 lines quoted in Q1 (answered *proceed and coordinate*); `overlap.sh --outside 207` → nothing, so every changed path is in the plan's footprint.
- `scope.sh origin/main HEAD` → `suite.shell=true` (unclassified paths: `.codeo/207/*.md`, `.codeo/config.json`, `CONTRIBUTING.md`, `README.md`, `changelog.d/207.md`, `tools/changelog.sh`).
- `qc/invariants-extra` and `qc/wiki-rules` are not configured; no invariants file, environment or `wiki` module; no environment step.
- Build: the `shell` suite's `build` is `true` → exit 0.
- Suite: `bash tests/run.sh` → exit 0, last line `all cases passed` (about 66 s).
- Per criterion: `bash tests/run.sh changelog`, `inventory-pin`, `inventory`, `overlap`, `intake-lease`, `base-moved`, `qc-skill`, `close-skill`, `plan-skill`, `init-skill` and `skills` each → `all cases passed`.
- Reproduced (F2): in a scratch repository, branch a rewords `plan-01` and branch b rewords `plan-02`, each running `bash tests/inventory.test.sh --update` and committing; `git merge a` → `CONFLICT (content): Merge conflict in tests/fixtures/skills-inventory.rules.sha256`. With `plan-05` in place of `plan-02` the merge succeeded.

**Criteria** (`init.md`):

| Criterion | Verdict | Settled by |
|---|---|---|
| Two branches that each add a changelog entry merge without a conflict in `CHANGELOG.md`, and the release step produces the same entries | met | `tests/changelog.test.sh` `two_branches_merge_without_a_conflict`, `assemble_matches_the_hand_written_section`; `changelog.d/207.md` is this issue's entry (see the documentation check) |
| Two branches that each change an inventory rule merge, and one script run afterwards produces a correct pin; a test pins it | not met — F2 | `tests/inventory-pin.test.sh` pins rules far apart (`plan-01`, `qc-01`); adjacent rules still conflict in the fixture and in `docs/skills-inventory.md`, and the documentation says they merge |
| A second issue whose footprint overlaps an in-flight issue's on a skill file names that issue and the files, and the footprint records `sequenced:` or `exclusive:`; a test pins it | met, with F4 and F5 | `tests/overlap.test.sh` (names the issue, `exclusive:skill:close`, `glob:skills/close/SKILL.md`); `tests/intake-lease.test.sh` `skill_resource_serialises_one_skill`; `tests/plan-skill.test.sh` pins plan-11 |
| `/codeo:qc` on a branch behind `origin/main` does not grade until synced, or reports that it is behind; a test pins it | met, with F1 and F3 | `skills/qc/SKILL.md` step 2 (sync before the diff, `Behind:` line), `tests/qc-skill.test.sh`; this round's `Behind:` line is the evidence. F1 and F3 are about `/codeo:close`'s follow-up, not QC's own check |
| `README.md`, `docs/skills.md` and `CHANGELOG.md` describe the new behaviour; the full suite passes | not met — F1, F2, F5 | the suite passes (`bash tests/run.sh` → `all cases passed`); `CHANGELOG.md` is deliberately unedited and the entry is the fragment `changelog.d/207.md`, which I accept as the mechanism this issue asks for; `README.md`, `docs/skills.md` and the fragment state three things that are untrue (F1, F2, F5) |

**Documentation check.** The pages changed (`README.md`, `docs/skills.md`, `docs/dossier.md`, `docs/handoff.md`, `docs/release-checklist.md`, `CONTRIBUTING.md`) are present tense, with no issue numbers and no history words (a scan of the added lines found none). Untrue statements: `CONTRIBUTING.md` and `changelog.d/207.md` say two changes to different rules merge without a conflict (F2); `README.md` and `docs/skills.md` say `/codeo:close` stops and routes to `/codeo:qc` with nothing written, which cannot work on an archived dossier (F1); `skills/init/SKILL.md`, `README.md`, `docs/skills.md` and the fragment say `#<M> holds <resources>` for what is only a footprint (F5).

**Independent review** (opus, handed the criteria and the diff only): ready to merge with fixes, for C1 and C2 and three Important points; quoted in plain text, its findings are classified here. I reproduced C2 (above) and read the text for C1, I1 and I3.

**Findings**

- **F1 — blocking, `/codeo:plan`'s.** `/codeo:close` step 9's exit-3 route to `/codeo:qc` cannot work (`skills/close/SKILL.md:404-405`, rule close-18). Step 9 runs while a pull request is open, when the dossier is archived under `.codeo/done/<N>/`; `/codeo:qc` reads and writes `.codeo/<N>/` only, so it finds no criteria or creates a stray live dossier beside the archive, and close step 2's `qc round at review: <k>` comparison has nothing to compare against. The code does what the plan says (write nothing, stop, route); the plan's design was wrong. Cause: the route skips what a conflict's send-back does at step 11 (un-archive, a `close.md` round with `qc round at review: <k>`, the card back to In progress). The fix is a new close round form, which needs `docs/dossier.md`, probably `scripts/dossier-check.sh` (outside the footprint), and its tests.
- **F2 — blocking, `/codeo:plan`'s.** The pin merges only rules that are not adjacent; the documentation claims all different rules (`CONTRIBUTING.md` section on the pin, `changelog.d/207.md` bullet 2), and the test covers only far-apart rules (`tests/inventory-pin.test.sh`). Rules in a skill sit on consecutive lines and a new rule is appended after the last one, so adjacency is the common case. Reproduced above. The plan assumed any two rules merge and never tested adjacency. Needed: say which merges are clean, document the recovery (resolve `docs/skills-inventory.md`, then `--update` overwrites the fixture), pin it with an adjacent-rules case, and consider a `.gitattributes` driver for the always-regenerated fixture.
- **F3 — blocking, `/codeo:plan`'s.** An *Update branch* merge made on GitHub skips close-18's check (`skills/close/SKILL.md:391-392`: "If the pull above already brought in the engineer's *Update branch* merge, it is done"; the same for step 3's pull on a return from review). A base that changed graded files then reaches the merge without a new QC round, which close-18 exists to stop. Same design as F1; the re-plan decides the check against the merged-in base.
- **F4 — blocking, `/codeo:plan`'s.** Rule plan-11 gives no clause for a *re-scope* answer or for an exclusive overlap settled by the lease wait, yet forbids `none` whenever an overlap was raised (`skills/plan/SKILL.md:260,303,321-323`, `docs/dossier.md:274-277`; `skills/plan/SKILL.md:341,351` say a lock replaces *sequence after*). The rule contradicts itself for those answers. The re-plan defines the clauses (for example `rescoped from #M …`, and what `sequenced:` holds when the lock settled it).
- **F5 — blocking, `/codeo:plan`'s.** `/codeo:init` prints `#<M> holds <resources>` from a footprint's `exclusive:` line (`skills/init/SKILL.md:117-121`, `README.md:206`, `docs/skills.md:343`, `changelog.d/207.md` bullet 3), but a footprint names what a plan intends to lease; the lease is taken at the hand-off, and a plan waiting on a lease lists the resource without holding it. The line can be false. The plan wrote `holds`; the re-plan chooses: read `intake.sh lease list` for real holders, or say "names".
- **F6 — non-blocking, `/codeo:plan`'s** (carried by the re-plan's tasks). `tools/changelog.sh:117-123` refuses two fragments whose `Safe to bump mid-workflow:` values differ (`no — <a>` against `no — <b>`, or `yes` against `no — …`), where the hand process let `no` win and joined the reasons; `tools/changelog.sh:151-163` inserts below a leftover `## Unreleased` heading from a branch made under the old process (the release checklist should say so); `tools/changelog.sh:135` keeps a fragment's trailing blank lines between bullets; `tests/intake-lease.test.sh:106` takes the repository's own `resources` into the expected "configured:" text, so a config change breaks it.
- **Carried from `implement.md`, non-blocking:** CRLF fragments keep `\r`; a version section that already exists is not refused; no case for an added rule (`rule <id> is not pinned`); `tests/close-skill.test.sh` pins the exit-3 route against the whole `BEHIND` bullet; `tests/inventory-pin.test.sh` case 1 does not assert both rewords are present.
- **Declined to judge by the reviewer:** semantic conflicts, other engineers' shared state (#194, #198), rebase against merge, the per-rule `sha256sum` cost, the history wording of the fragment, odd skill-suffix paths, an empty `changelog.d/` after release, and whether bullet order counts as the same entries — each set aside as out of scope or a judgement call, and I agree.

No `/codeo:issue` was filed. F1, F3 and F4 touch the same rules and docs as the plan, so one re-plan round covers them.

**Routing.** F1, F3, F4 and F5 are the plan's: the design of close-18 (the route and the *Update branch* path), plan-11 and the `holds` line has to change, and F1 needs a new close round form and `scripts/dossier-check.sh` in the footprint. F2 is the plan's too: its claim and its test assumed adjacency never happens. F6 and the carried items ride with the re-plan.

**Verdict: back to `/codeo:plan`.**

## Log

- 2026-11-28 — Q1 raised (overlap with #217 found at step 2) · cost: 0m · opus-5-5 329k in + 379k cached / 763 out
- 2026-11-28 — round 1: back to /codeo:plan (F1-F5 blocking) · cost: 8m · opus-5-5 439k in + 2.3M cached / 19k out · sonnet-5-5 35k in + 3.2M cached / 8k out
- 2026-11-28 — re-invoked with nothing new to judge (no plan or implement round since round 1; HEAD 0c0ead8, contains origin/main); round 1 stands: back to /codeo:plan · cost: 0m · opus-5-5 372k in + 29k cached / 447 out
- 2026-11-28 — round 2: Q2 raised (new overlap with #217 on tests/inventory.test.sh, found at step 2) · cost: 0m · opus-5-5 535k in + 593k cached / 813 out
