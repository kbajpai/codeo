# Issue #207 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/207 |
| Branch | `feat/207-stop-parallel-issues-colliding-shared` |
| Updated | 2026-11-28 |

## Where this stands

Round 3, done: clear — forward to `/codeo:close`. No question is open. Non-blocking findings F12-F17 and the carried items are for `/codeo:triage`. Rounds 1 and 2 stand as written.

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


### Round 2 — 2026-11-28

Graded base: 13ac02c52f10b9b597c77bf8a67968e10319634f

**Commands run** (this pass, HEAD `9b78a98`):
- `role.sh --check qc` → exit 0; lock `issue: 207`, branch `feat/207-stop-parallel-issues-colliding-shared`; clean tree.
- `sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main` (twice: at the start and after Q2); no `Behind:` line.
- `overlap.sh 207` → `217	tests/inventory.test.sh`, raised as Q2 and answered *proceed and coordinate*; `overlap.sh --outside 207` → nothing, so every changed path is in the plan's round-2 footprint.
- `scope.sh origin/main HEAD` → `suite.shell=true` (unclassified paths: `.codeo/207/*.md`, `.codeo/config.json`, `CONTRIBUTING.md`, `README.md`, `changelog.d/207.md`, `tools/changelog.sh`).
- `qc/invariants-extra` and `qc/wiki-rules` → exit 3 each (none); no invariants file, environment or `wiki` module; no environment step.
- Build: the `shell` suite's `build` is `true` → exit 0.
- Suite: `bash tests/run.sh` → exit 0, last line `all cases passed` (about 77 s).
- Per criterion: `bash tests/run.sh` with `changelog`, `inventory-pin`, `inventory`, `overlap`, `intake-lease`, `base-moved`, `qc-skill`, `close-skill`, `plan-skill`, `init-skill`, `implement-skill`, `dossier-check`, `inflight`, `skills`, `readme` and `skills-doc` → each `all cases passed`.
- Reproduced by hand: adjacent rules `plan-01` and `plan-02` reworded on two branches in a scratch repository, each running `bash tests/inventory.test.sh --update`: `git merge --no-edit` merged with no conflict (2 files changed) and the merged tree's `bash tests/inventory.test.sh` ended `all cases passed`. Reproduced F9 below with two fragments (`yes, with one step: run codeo update` and `yes, after you restart sessions`): the assembled section kept only the first. Read F8 at `scripts/base-moved.sh:33`.
- File modes: `git diff --summary origin/main...HEAD` shows only `scripts/base-moved.sh`, `tests/base-moved.test.sh` and `tools/changelog.sh` as new executables.

**Criteria** (`init.md`):

| Criterion | Verdict | Settled by |
|---|---|---|
| Two branches that each add a changelog entry merge without a conflict in `CHANGELOG.md`, and the release step produces the same entries | met, with F9 | `tests/changelog.test.sh` (`two_branches_merge_without_a_conflict`, `assemble_matches_the_hand_written_section`); the entry is the fragment `changelog.d/207.md`; F9: a second "yes, with a step" caveat is dropped |
| Two branches that each change an inventory rule merge, and one script run afterwards produces a correct pin; a test pins it | met | `tests/inventory-pin.test.sh` `adjacent_rules_merge_cleanly` and the different-rules case; the hand merge above (round 1's F2, fixed) |
| A second issue whose footprint overlaps an in-flight issue's on a skill file names that issue and the files, and the footprint records `sequenced:` or `exclusive:`; a test pins it | met | `tests/overlap.test.sh`, `tests/intake-lease.test.sh` `skill_resource_serialises_one_skill`, `tests/plan-skill.test.sh` (plan-11, four clauses) |
| `/codeo:qc` on a branch behind `origin/main` does not grade until synced, or reports that it is behind; a test pins it | met, with F7 and F8 | `skills/qc/SKILL.md` step 2 and `tests/qc-skill.test.sh`; this round's sync said the branch already contains `origin/main`. F7 and F8 are about the recorded `Graded base:` line that close reads afterwards, not about QC's own sync |
| `README.md`, `docs/skills.md` and `CHANGELOG.md` describe the new behaviour; the full suite passes | met — by decision | the suite passes (`bash tests/run.sh` → `all cases passed`); `README.md` and `docs/skills.md` describe it and a scan of the added lines found no history wording or issue numbers; `CHANGELOG.md` stays unedited by design and the entry is `changelog.d/207.md`, which is what the engineer chose at `plan.md` Q1-Q2 and what the issue's first requirement asks; it becomes `CHANGELOG.md` text at the release's `tools/changelog.sh assemble` |

**Documentation check.** The pages changed (`README.md`, `docs/skills.md`, `docs/dossier.md`, `docs/handoff.md`, `docs/release-checklist.md`, `CONTRIBUTING.md`) agree with the skill text and the scripts on the `— base moved` round, the `holds` and `waits for` lines, the four `sequenced:` clauses and the blank-separated pin; they are present tense with no issue numbers. Two statements are made untrue by F7 and F9 once those are read against the code (the recorded sha, and "produces the same entries").

**Independent review** (opus, handed the criteria and the diff only): ready to merge with fixes, for four Important points; quoted in plain text, its findings are classified here. The controller read F8 in the code and reproduced F9; F7 follows from the text of `skills/qc/SKILL.md` qc-16.

**Findings**

- **F1-F5 (blocking in round 1) — fixed:** F1 and F3 by `bf1ac48` (a `— base moved` send-back, also when the branch holds the base), F2 by `f0a43af` and `93f7772`, F4 by `b2fed65` and `e29475a`, F5 by `7f6ac0c`; F6 by `2c9699f` and `f1e3eed`.
- **F7 — blocking, `/codeo:plan`'s.** `Graded base:` can name a commit QC never merged (`skills/qc/SKILL.md` qc-16, line ~100; `scripts/base-moved.sh` reads it). qc-16 takes the sha from `git rev-parse origin/<base>` without saying when; the same pass fetches again (the scope fallback, step 9's stale-base re-run) and `inflight.sh` fetches too, so the ref can move after the sync. The recorded sha is then newer than what was graded and `base-moved.sh` never sees the changes in between: a silent false negative in the guard this issue adds. The code does what the plan says; the plan's design is the flaw. Needed: record `git merge-base HEAD origin/<base>` (the base commit the graded tree contains), or capture the sha straight after the sync, and guard the reader the same way.
- **F8 — blocking, `/codeo:plan`'s.** A slightly mis-formatted `Graded base:` line switches the check off without a warning (`scripts/base-moved.sh:33` matches `^Graded base:` only). Written as a list item (`- Graded base: …`) or in backticks, it gives exit 4, close merges and says only that the round predates the line, and `dossier-check.sh` deliberately does not check it. Needed: accept an optional `- ` and backticks as `inflight.sh` does for `qc round at review`, and/or have `dossier-check.sh` flag a graded round without the bare line.
- **F9 — blocking, `/codeo:plan`'s.** `tools/changelog.sh assemble` drops a second "yes, with a step" caveat (`tools/changelog.sh`, the `safe=$v` first-yes rule). Reproduced: `yes, with one step: run codeo update` and `yes, after you restart sessions` assemble to the first only. The history has such lines (v1.0.9: "yes, with one step: …"), so an instruction to adopters is lost and the release does not "produce the same entries the current process does". Needed: join the distinct `yes…` values that carry text after `yes` with `; `, with a test (the existing "Yes with a note" case has no note).
- **F10 — non-blocking, `/codeo:plan`'s.** `Config schema:` defaults to a hard-coded `1 (unchanged)` (`tools/changelog.sh`): after a future schema bump a fragment that forgets the header gets an untrue line. Take it from the previous section, or refuse when no fragment says it.
- **F11 — non-blocking, `/codeo:plan`'s** (carried by the re-plan): extra blank lines after a fragment's header leak into the body (reproduced by the reviewer); `assemble` does not check the shape of the version or date; `skills/close/SKILL.md` step 9 exit 1 names no remedy (a shallow clone may lack the graded sha: `git fetch --unshallow` or run `/codeo:qc` again); step 11 does not say which heading wins when review feedback and a moved base arrive in the same pass; plan-11 gives no separator for several clauses on one `sequenced:` line; a file directly under `skills/` gives the suffix `README.md`; `tests/base-moved.test.sh` has no case for the *Update branch* state (HEAD already holds the new base), which close-18 relies on (confirmed by hand by the reviewer).
- **Carried from `implement.md`, non-blocking:** long unwrapped lines in `skills/close/SKILL.md` step 11; the init text lists "no resources configured" as a failure of the lease read though it prints nothing and exits 0; the inflight test asserts only the `/codeo:implement` leg; a stripped caution reason can keep stray punctuation (`No.`); two non-`no` cautions joined are not pinned; the README does not repeat close's one-line note for exit 4.
- **Declined to judge by the reviewer, and I agree:** semantic conflicts, other engineers' shared state (#194, #198), fragment order by issue number, the churn of one send-back per base change in a busy repository (the design chosen at plan Q6), the `; ` join of `Shared state:`, existing `overlap.sh` behaviour, a comment that says "seven skill headings", and whether the `skill` lease slows parallel work.

No `/codeo:issue` was filed.

**Routing.** F7, F8 and F9 are blocking and are the plan's: the recorded sha, the reader's tolerance and the safe-to-bump join are design choices the code follows. F10 and F11 and the carried minors ride with the re-plan.

**Verdict: back to `/codeo:plan`.**

### Round 3 — 2026-11-28

Graded base: 1d28d45aa98ce40ce31599d128fadddcff4a84b3

**Commands run** (this pass, HEAD `bb12eaf`):
- `role.sh --check qc` → exit 0; lock `issue: 207`, branch `feat/207-stop-parallel-issues-colliding-shared`; clean tree.
- `sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main`; no `Behind:` line. `git merge-base HEAD origin/main` → `1d28d45`, the tip of `origin/main`.
- `overlap.sh 207` → nothing (the #217 pairs were answered at Q1 and Q2); `overlap.sh --outside 207` → nothing, so every changed path is in the plan's round-3 footprint.
- `scope.sh origin/main HEAD` → `suite.shell=true` (unclassified paths: `.codeo/207/*.md`, `.codeo/config.json`, `CONTRIBUTING.md`, `README.md`, `changelog.d/207.md`, `tools/changelog.sh`).
- `qc/invariants-extra` and `qc/wiki-rules` → exit 3 each (none); no invariants file, environment or `wiki` module; no environment step.
- Build: the `shell` suite's `build` is `true` → exit 0.
- Suite: `bash tests/run.sh` → exit 0, last line `all cases passed`.
- Reproduced by the reviewer (opus, handed the criteria and the diff only): the full suite, the assemble of a `yes, with one step` fragment beside a `no — …` fragment, an inventory-pin merge of an appended rule against a reworded `qc-16` (clean, merged tree passes). The controller read `skills/close/SKILL.md` step 9 and `tools/changelog.sh` for I1 and I2 below.
- Round 2's F7-F11 re-checked in this pass: `bash tests/run.sh` with `base-moved`, `qc-skill`, `changelog`, `close-skill`, `plan-skill`, `init-skill` are part of the full run above; the implementer's hand run of F9 in a scratch copy is not relied on here.

**Criteria** (`init.md`):

| Criterion | Verdict | Settled by |
|---|---|---|
| Two branches that each add a changelog entry merge without a conflict in `CHANGELOG.md`, and the release step produces the same entries | met | `tests/changelog.test.sh` (`two_branches_merge_without_a_conflict`, `assemble_matches_the_hand_written_section`, `yes_notes_are_all_kept`); the entry is the fragment `changelog.d/207.md` (plan Q11); F9, F10 and F11 of round 2 fixed |
| Two branches that each change an inventory rule merge, and one script run afterwards produces a correct pin; a test pins it | met | `tests/inventory-pin.test.sh`; the reviewer's appended-rule against reworded-`qc-16` merge was clean |
| A second issue whose footprint overlaps an in-flight issue's on a skill file names that issue and the files, and the footprint records `sequenced:` or `exclusive:`; a test pins it | met | `tests/overlap.test.sh`, `tests/intake-lease.test.sh` `skill_resource_serialises_one_skill`, `tests/plan-skill.test.sh` (plan-11) |
| `/codeo:qc` on a branch behind `origin/main` does not grade until synced, or reports that it is behind; a test pins it | met | `skills/qc/SKILL.md` step 2 and qc-16 and `tests/qc-skill.test.sh`; this pass's sync said the branch already contains `origin/main`; `Graded base:` is now `git merge-base HEAD origin/<base>` (F7, F8 fixed, `tests/base-moved.test.sh`) |
| `README.md`, `docs/skills.md` and `CHANGELOG.md` describe the new behaviour; the full suite passes | met — by decision | the suite passes; `README.md` and `docs/skills.md` describe it; `CHANGELOG.md` stays unedited by design and the entry is `changelog.d/207.md` (plan Q11), which becomes `CHANGELOG.md` text at the release's `assemble` |

**Documentation check.** `README.md`, `docs/skills.md`, `docs/dossier.md`, `CONTRIBUTING.md` and `docs/release-checklist.md` agree with `skills/qc/SKILL.md` qc-16, `scripts/base-moved.sh` and `tools/changelog.sh` on the merge-base `Graded base:`, the exit-4 note, the `yes` join, the `Config schema:` default and the `assemble` exit codes; the added lines are present tense with no issue numbers or history words. One sentence overstates a behaviour (I1 below).

**Findings**

- **F7-F9 (blocking in round 2) — fixed:** F7 and F8 by `fda6c00` (the merge-base record, the tolerant reader, the *Update branch* cases), F9 by `99fb54e`. F10 and F11 (non-blocking in round 2) by `99fb54e` and `80cea44`.
- **F12 — non-blocking, `/codeo:plan`'s.** The moved-base check runs only at step 9 of `skills/close/SKILL.md`, which is the waiting phase. Phase 1 (steps 2-8) opens the pull request without it, and step 8 tells the engineer to merge and run `/codeo:close` again, so a merge that skips the waiting phase reaches `main` without `base-moved.sh` having run; nothing runs between pull request and merge in any case. The code does what the plan says (plan Q6); `README.md` and `docs/skills.md` say "on every pass", which reads wider than "every pass of the waiting phase". The acceptance criterion about QC is met, so this does not block. Needed, if wanted: run the check in step 3 too, or say "every pass of the waiting phase".
- **F13 — non-blocking, `/codeo:plan`'s.** A `yes, with one step: …` note is dropped when another fragment says `no — …` (`tools/changelog.sh` safe-to-bump handling, `CONTRIBUTING.md`: any caution beats every yes). Reproduced by the reviewer. The plan chose "a caution wins"; an adopter step can disappear from the release text when the two are mixed. Needed, if wanted: append the yes notes to the caution, or refuse the mix.
- **F14 — non-blocking.** `none (…)` shared-state values are kept and joined (only an exact `none` is dropped), so an assembled line can lead with `none (…)` while listing real changes (`tools/changelog.sh`).
- **F15 — non-blocking, a decision already taken (plan Q11).** main's `## Unreleased` section (#181) stays in `CHANGELOG.md`, so the first `assemble` after this merge refuses until it is folded into `changelog.d/181.md`, and `CONTRIBUTING.md`'s "edited only by `assemble`" is not true of `main` until then.
- **F16 — non-blocking.** A `Graded base:` line in a form the reader does not match (`- **Graded base:** <sha>`) gives exit 4 and close carries on with a one-line note; `dossier-check.sh` does not check it by design.
- **F17 — non-blocking, design.** Any shared path counts as moved, so a pull request that merges first can send a later one back through a round; the docs do not warn of it.
- **Carried from `implement.md`, non-blocking:** `scripts/base-moved.sh` header and close step 9 say close "compares the graded commit with `origin/<base>`" though the script starts from the merge base; an empty `Graded base:` value reads as exit 4; a schema value like `1 → 2` defaults to `1 (unchanged)`; long lines in qc-16 and `docs/dossier.md`; the diff error in `base-moved.sh` names `$sha`; the `yes` dedupe is case-sensitive; whole-file pins in the close and plan skill tests; the first fragment bullet does not mention the `yes` join.
- **Declined to judge by the reviewer, and I agree:** ordering bullets by issue number, the livelock risk of repeated base-moved rounds on a busy base, `lease list` from a stale fetch at init (code that predates this change), several engineers' shared state (#194, #198).

No `/codeo:issue` was filed.

**Routing.** No finding is blocking: round 2's F7-F9 are fixed and tested, the suite passes, and F12-F17 and the carried items are non-blocking. They go to `/codeo:triage` after the merge.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-28 — Q1 raised (overlap with #217 found at step 2) · cost: 0m · opus-5-5 329k in + 379k cached / 763 out
- 2026-11-28 — round 1: back to /codeo:plan (F1-F5 blocking) · cost: 8m · opus-5-5 439k in + 2.3M cached / 19k out · sonnet-5-5 35k in + 3.2M cached / 8k out
- 2026-11-28 — re-invoked with nothing new to judge (no plan or implement round since round 1; HEAD 0c0ead8, contains origin/main); round 1 stands: back to /codeo:plan · cost: 0m · opus-5-5 372k in + 29k cached / 447 out
- 2026-11-28 — round 2: Q2 raised (new overlap with #217 on tests/inventory.test.sh, found at step 2) · cost: 0m · opus-5-5 535k in + 593k cached / 813 out
- 2026-11-28 — round 2: back to /codeo:plan (F7-F9 blocking) · cost: 15m · opus-5-5 700k in + 5.6M cached / 31k out · sonnet-5-5 31k in + 3.4M cached / 6k out
- 2026-11-28 — round 3: clear, forward to /codeo:close (no blocking finding; F12-F17 non-blocking) · cost: 6m · opus-5-5 291k in + 4M cached / 26k out · sonnet-5-5 31k in + 717k cached / 1k out
