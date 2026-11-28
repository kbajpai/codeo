# Issue #207 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/207 |
| Branch | `feat/207-stop-parallel-issues-colliding-shared` |
| Updated | 2026-11-28 |

## Where this stands

Round 1. Q1-Q7 are answered (the recommended picks, given in the conversation). The draft is at `.codeo/207/plan-draft.md`, waiting for the engineer's review.

## Questions

### Q1 — Is the changelog-fragment mechanism this repository's own tooling, or a feature the plugin gives adopters?

**Why it matters:** it decides where the assembling script lives, what the README says, and whether a skill changes. No skill or script reads or writes a changelog today (`git grep -i changelog -- skills scripts lib hooks` finds nothing); `CHANGELOG.md` is edited by hand on each branch under `## Unreleased`, and `docs/release-checklist.md` step 6 retitles that heading.

- This repository only. A script outside the shipped `scripts/` contract (I would put it at `tests/changelog.sh`, beside `tests/run.sh`, or under a new `tools/`), `CONTRIBUTING.md` and `docs/release-checklist.md` describe it, and no skill changes. The README gains nothing for this part.
- A plugin feature. A config key (say `changelog.fragments`), `scripts/changelog.sh`, and `/codeo:implement` or `/codeo:close` writing the fragment. This is a new adopter-facing surface with its own README, config-table and `doctor` work, and it roughly doubles this part of the plan.

I recommend this repository only: the issue's evidence is codeo's own `CHANGELOG.md`, and an adopter's changelog convention is theirs.

**Options:** this repository only (recommended) · a plugin feature · no preference, you pick.

**Answer:**
This repository only, as recommended. Given in the conversation: "go with your picks".

### Q2 — What does a fragment hold, and how do the three header lines reach the release section?

**Why it matters:** a release section is more than bullets. It opens with `Config schema:`, `Shared state:` and `Safe to bump mid-workflow:`, and branches edit those too (v1.0.11's `Shared state:` line was written by #195 and #206 together). If only the bullets move to fragments, that line stays a shared edit and still conflicts. Thirteen tests also grep `CHANGELOG.md` for a bullet (for example `tests/sandbox.test.sh` `docs_changelog_names_the_macos_sandbox`), and would fail on a branch whose bullet is in a fragment until the release assembles it.

- One file per issue, `changelog.d/<N>.md`: bullets, plus optional first lines `Config schema:`, `Shared state:` and `Safe to bump mid-workflow:` holding only that issue's contribution. The script's `assemble vX.Y.Z` writes the section: the bullets in issue-number order, `Shared state:` as the contributions joined with `; ` (`none` when no fragment has one), `Config schema: 1 (unchanged)` and `Safe to bump mid-workflow: yes` unless a fragment says otherwise (two fragments that disagree stop the script, for the engineer to write the line), then deletes the fragments. The tests that look for a bullet read `CHANGELOG.md` and `changelog.d/*.md` together through one helper. A test builds two branches that each add a fragment, merges them, assembles, and compares the section with a fixture written the way the current process writes it.
- Bullets only in the fragment; the three header lines are written by hand at release, from the merged pull requests. Smaller script, but the release author reconstructs `Shared state:` from memory, which the checklist says a project mid-workflow depends on.

I recommend the first. One point for you to check: assembled bullets come out in issue-number order, while today's order is whatever the branches chose (v1.0.11 runs #206, #190, #192, #188, #204, #211, #195). I read "the same entries" in the first acceptance criterion as the same set of bullets and header lines, not the same order; say if order matters and I will add an optional sort key.

**Options:** per-issue file with header contributions, bullets in issue order (recommended) · bullets only, header lines by hand · something else, described in the answer.

**Answer:**
One file per issue with header contributions, bullets in issue-number order, as recommended. Given in the conversation: "go with your picks".

### Q3 — What form does the committed inventory pin take, so two rule changes merge?

**Why it matters:** `tests/fixtures/skills-inventory.rules.sha256` is one hash over all 87 rules, so any two branches that each change a rule conflict on its one line. `bash tests/inventory.test.sh --update` already regenerates it; what is missing is a merge that does not conflict. `tests/inventory.test.sh` also hard-codes the rule count per skill (`[close]=17 …`), a second line two rule-adding branches both edit.

- One line per rule. The file becomes `<skill>-NN<TAB><sha256 of that rule's text>`, 87 lines, written only by `--update`. Two branches that change different rules merge with no conflict and the merged file is already correct, on GitHub too; `--update` after the merge is a no-op that the test proves. Two branches that change the same rule, or both append the next ID to one skill, still conflict, and that conflict is real: `docs/skills-inventory.md` conflicts on the same line. `--update` overwrites the file whole, conflict markers included, once the inventory page is resolved. The per-skill counts are read from the pin, so the hard-coded table goes. A failing test names the rule that changed, which the single hash cannot.
- Keep the single hash, add `tests/fixtures/skills-inventory.rules.sha256 merge=union` to `.gitattributes`. A local merge then keeps both lines without a conflict and `--update` rewrites it. But a merge made by GitHub's button would leave `main` holding a two-line pin and a failing suite until someone regenerates, and I have not verified that GitHub applies `merge=union` server-side.
- Stop committing a pin. No conflict, and no check that a rule was not reworded by accident, which is what the pin is for.

I recommend one line per rule. The file keeps its name unless you want it renamed.

**Options:** one line per rule (recommended) · single hash with `merge=union` · no committed pin.

**Answer:**
One line per rule, as recommended. Given in the conversation: "go with your picks".

### Q4 — What should "act on an overlap" mean for the shared skill files?

**Why it matters:** this is the centre of the issue and the two answers build different things. The check already exists and already asks: `overlap.sh` ran at every step of #188, #195, #204 and #206 and raised about twenty overlap questions between them. Every one was recommended *proceed and coordinate* and every one was answered that way ("go with your picks"), so every footprint ended `sequenced: none` and three plans were sent back at QC. The step that is missing is a rule for what to recommend and a record of what was decided.

- Make each skill an exclusive resource in codeo's own config. `.codeo/config.json` gains a parameterised resource `skill` with `paths: ["skills/**"]`; a plan that changes `skills/close/SKILL.md` writes `exclusive: skill:close`, and `/codeo:plan` step 10 takes the lease through `intake.sh lease`, which refuses while another issue holds it and names the holder. The second issue's hand-off waits until the first closes. This is the plugin's existing machinery (rule `plan-05` already says to recommend sequencing for an exclusive overlap), so the plugin change is small: the plan skill states how a parameterised suffix is derived from a path, and the lease refusal names the overlapping files. The cost is real serial work: #188, #195 and #204 all changed `skills/close/SKILL.md` and would have run one after another. The engineer's way round a lock is `intake.sh lease`'s existing override, recorded in the dossier.
- A recommendation rule, no lock. A new config key (say `sequencePaths`, globs) names the files where an overlap is recommended *sequence after #M* instead of *proceed and coordinate*; the engineer still chooses, and the footprint's `sequenced:` line records the choice either way (`after #M …` or `none — proceeds beside #M (Q<k>)`). Nothing blocks. The risk is the one already observed: a recommendation accepted by habit.
- Both: the lock for `skills/**`, and the recorded decision for every other overlap.

I recommend both. The lock is the only option that changes what happened on 2026-11-27, and recording a *proceed* decision in `sequenced:` costs one line and makes the footprint say what was decided. The tests of each skill (`tests/<skill>-skill.test.sh`) would fall under the same resource as the skill.

**Options:** both (recommended) · exclusive resource per skill only · recommendation rule only.

**Answer:**
Both: an exclusive `skill` resource with a lock, and every overlap decision recorded in `sequenced:`, as recommended. Given in the conversation: "go with your picks".

### Q5 — Does `/codeo:init` take part, or is `/codeo:plan` the only gate?

**Why it matters:** the issue says "`/codeo:plan` or `/codeo:init`", and the third acceptance criterion says "starting a second issue". At `init` an issue has no branch and no footprint, and `skills/init/SKILL.md` step 3 says so on purpose ("`overlap.sh` has nothing to compare yet … so `init`'s check is `inflight.sh` alone, deliberately"). `init` cannot know which files the issue will change without planning it.

- `/codeo:plan` is the gate; `init` informs. After it cuts the branch, `init` prints each in-flight workflow's `exclusive:` leases and `sequenced:` line from `inflight.sh` (one line per workflow, nothing when none holds a lease), so the engineer sees what is locked before planning starts. It asks nothing and blocks nothing. The acceptance criterion is pinned at `/codeo:plan`, in a scratch repository with two workflows.
- `init` asks. It shows the in-flight footprints and asks the engineer whether this issue will touch any of them, recording the answer in `init.md`. This is a guess made before any exploration, and `/codeo:plan` asks again with the real footprint.
- `/codeo:plan` only; `init` unchanged.

I recommend the first.

**Options:** plan is the gate and init informs (recommended) · init asks · plan only.

**Answer:**
`/codeo:plan` is the gate and `init` informs, as recommended. Given in the conversation: "go with your picks".

### Q6 — `/codeo:qc` already merges `origin/main` at the start of every round. What should change?

**Why it matters:** as written, the fourth acceptance criterion is close to met today, and I do not want to plan a change that is already there. `skills/qc/SKILL.md` step 2 runs `sync-main.sh --abort-on-conflict` before anything is graded: a clean merge continues on the merged tree, a conflict is a send-back to `/codeo:implement`. It is a merge and never a rebase, by `sync-main.sh`'s stated design (the branch is pushed and `/codeo:close` never force-pushes). `tests/sync-main.test.sh` covers the script; no test pins that the skill runs it before grading. What I can see that is not covered is the time after the verdict: when `main` moves after a clear round, `/codeo:close` step 9 (`BEHIND`) merges it and pushes with no new QC round, so the merged tree was never graded.

- Pin what exists, keep the merge. A test pins that step 2 syncs before the diff is scoped and that a conflict routes back without grading; the skill and README say "merged with", never "rebased onto". No behaviour changes.
- Pin it, and close the gap after the verdict. QC records the base commit it graded (`Graded at: origin/main <sha>` in the round), and when `/codeo:close` brings in a base that has moved, it compares the files the new base commits changed with the files this branch changes: no file in common, it carries on as today; any in common, it routes back to `/codeo:qc` for a round on the merged tree. `sync-main.sh` already prints exactly that list (`also changed on main: <path>`).
- Rebase in place of the merge. It needs a force-push on a pushed branch with an open pull request, which the pipeline rules out everywhere else.

I recommend the second. If the gap you saw on 2026-11-27 was something else (for example a QC round run in a checkout whose `sync-main.sh` did not run, or failed), say what happened and I will plan for that.

**Options:** pin and close the after-verdict gap (recommended) · pin only · rebase.

**Answer:**
Pin what exists and close the after-verdict gap, as recommended. Given in the conversation: "go with your picks".

### Q7 — #213 overlaps on `glob:CHANGELOG.md` and `glob:README.md`: how to proceed?

**Why it matters:** #213 (branch `feat/213-release-v1-0-11-main`, assignee kbajpai, step `close (PR open)`, pull request #216 "chore: pin codeo to v1.0.11") declares `CHANGELOG.md`, `README.md`, `docs/updating.md`, `tests/install.test.sh`, `.claude-plugin/plugin.json` and `.codeo/config.json` in its footprint; its branch has changed only its plan file so far. This plan changes `CHANGELOG.md`, `README.md` and, if Q4 is answered with the lock, `.codeo/config.json` (`exclusive` resources beside #213's `plugin.ref`). No exclusive resource is configured, so there is no lock to take. `overlap.sh` reads only a committed footprint, so the tokens above are the form I expect it to print; if it prints others after the footprint is committed, I restate this question with them.

- Proceed and coordinate: #213 is waiting on review and will merge long before this branch has code; this branch picks it up at its first `sync-main.sh`.
- Sequence after #213: this plan's hand-off waits for pull request #216 to merge.
- Re-scope: nothing here can avoid `CHANGELOG.md` and `README.md`.

I recommend proceed and coordinate: #213 is one review away from merged, and the shared lines are a version pin and a release heading this plan does not edit.

**Options:** proceed and coordinate (recommended) · sequence after #213 · re-scope.

**Answer:**
Proceed and coordinate, as recommended. Given in the conversation: "go with your picks".

## Notes

**What exists today (read 2026-11-28, `main` at `00de557`).**

- `scripts/overlap.sh <N>` compares this branch's footprint and diff with every other in-flight workflow's and prints `M<TAB>what`; `/codeo:plan`, `/codeo:implement`, `/codeo:qc` and `/codeo:close` each run it and raise a question per line. `/codeo:init` runs `inflight.sh` only.
- `exclusive:` takes names from the config's `resources[]` (`paths`, `parameterised`); this repository configures none, which is why every footprint says `exclusive: none`.
- `scripts/sync-main.sh` merges `origin/<base>` at the start of every implement and qc round.
- `tests/inventory.test.sh --update` rewrites the single-hash pin.
- This repository runs the plugin pinned at v1.0.10, so skill changes made here take effect in this repository after the next release and pin bump, which are separate issues by this project's convention.

**My calls (corrected at the review gate if wrong).**

- One plan and one pull request for the four mechanisms, tasks grouped by mechanism and ordered changelog → inventory pin → overlap rule → QC, so each group is provable alone.
- This issue's own changelog entry is written as a fragment, the first one.
- The optional `engineering:system-design` and `engineering:architecture` skills are not installed here; their structure is applied directly.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-28 — Q1-Q7 raised (scope of the four mechanisms; overlap with #213) · cost: 3m · fable-5-2 96k in + 1.4M cached / 11k out
