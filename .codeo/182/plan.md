# Issue #182 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/182 |
| Branch | `feat/182-release-v1-0-10-once` |
| Updated | 2026-11-26 |

## Where this stands

Q1-Q3 are answered. The plan is drafted at `.codeo/182/plan-draft.md` and waits at the review gate; nothing is open in this file.

What exploration found:
- **The gate is met.** `origin/main` is at `89789dd`, 8 commits past `v1.0.9` (`6e66283`): #175 (pin), #178 (#171), #180 (#170), #184 (#173), #183 (#176), #186 (#177), #187 (#179). `inflight.sh --except 182` prints `no other workflow in flight`.
- **The release PR is the v1.0.9 shape, plus `docs/updating.md`.** `.claude-plugin/plugin.json`, the `CHANGELOG.md` heading, and the version numbers in `README.md`, `tests/install.test.sh` and now `docs/updating.md` (checklist step 6 lists it; #168's release did not have the file). Dry-run on `89789dd` in a scratch clone: `1.0.9`→`1.0.10` then `1.0.8`→`1.0.9` on those three files, with `t_latest_installed_without_version` and `t_bad_version_usage` skipped and the one ordering stub `v1.0.10` in `t_latest_is_highest_release` taken to `v1.0.11` (checklist: "that stub takes the next higher version"). `bash tests/install.test.sh` and `bash tests/readme.test.sh` both ended `all cases passed`.
- **`## Unreleased` has four bullets (#176, #171, #173 twice, #177) and none for #179 or #170.** Criterion 3 requires an entry for each gating issue that merged work: #179 merged work (#187) and has none.
- **README audit.** Three read-only agents compared all 638 lines with the code; I verified each finding. Two real mismatches, both in *Your first workflow* step 4 (`/codeo:implement`, `README.md` lines 287-288). The Configuration table, the doctor entries, the install and update transcripts and the lock and role-guard text matched. The rest are omissions (Q1).
- **Dry-run is not the whole test.** `bash tests/run.sh` has not been run on the bumped tree; Task 1 runs it in the worktree.

## Questions

### Q1 — The README audit found two mismatches and a list of omissions. What does the release PR fix?

**Why it matters:** criterion 2 says "every mismatch found between `README.md` and the code" is fixed in the release PR, and a mismatch is a statement the code contradicts; an omission is a true README that says less than the code does. Fixing omissions grows a "four files" release PR into prose edits that no test guards, and this issue's own out-of-scope list rules out new work.

**The two mismatches (both `/codeo:implement`):**
1. Line 287, "It asks: only in the dossier … and only when the plan looks wrong or unclear". `skills/implement/SKILL.md` step 2 stops and asks the engineer *in the conversation* when the plan is uncommitted or only staged, and step 2a puts `overlap.sh` hits to the dossier as numbered questions (proceed and coordinate / sequence after / re-scope), which are not about the plan being wrong.
2. Line 288, "an `## Outcome` of what was built and the commit for each task". Step 8 records what was built, the documentation pages changed, the build result, `Deployed revision:` and deviations from the plan; no skill rule asks for a commit per task.

**The omissions** (all true statements the README leaves out): `priority-labels`, a twelfth doctor check printed only when `issue.priority` is true; the installer's `--help` and exit statuses; `TODO-set-me` values make `/codeo:doctor` fail `config`; two overlays failure messages; `/codeo:close` moving the card to In review, In progress and Done, and merging `origin/<base>` into a BEHIND PR; `sync-main.sh` at the start of an implement and a qc round; `/codeo:init` assigning the engineer; `resources[].paths` doing nothing for deploy detection when no suites are configured; `environment.hooks.start` re-running in qc; `/codeo:plan` writing `plan-draft.md`, taking exclusive leases and raising overlap questions.

**Options:**
- **Mismatches only.** Fix lines 287-288 (no new test: the check would pin prose). File the omissions as one issue through `/codeo:issue` for the next release.
- **Mismatches plus the omissions in the three places users meet them** (the doctor entries, the close step, the implement step).
- **Mismatches plus every omission.**

*Recommendation:* mismatches only, and file the omissions as one new issue. The criterion is about mismatches; `README.md` is the one page every adopter reads, and each omission edit is a claim the next audit must re-check. The new issue ships in a later release.

**Answer:**
Mismatches plus every omission (engineer, in the conversation, 2026-11-26; recorded here by the skill). The two mismatches and every omission listed above are fixed in the release PR; nothing is filed for later.

### Q2 — Which entries does the `## v1.0.10` changelog section get beyond the four bullets already under `## Unreleased`?

**Why it matters:** criterion 3 asks for an entry per gating issue that merged work. #173, #176 and #177 have bullets; #179 (#187: README wording, two test guards, the handoff and role-guard docs, `docs/home-checkout.md`'s "Adopting the guard in your project") has none, and its plan said "no `CHANGELOG.md` entry" because #182 owns the release notes. #170 (#180) is not a gating issue but merged after v1.0.9 with no bullet either, and the Release notes are this section only. #171's bullet already exists.

**Options:** bullets for #179 and #170 · a bullet for #179 only · none, and edit criterion 3.

*Recommendation:* both. #179 is required; #170 changed what the README and `.devcontainer/README.md` tell a Mac user, so a release note that omits it is wrong for the reader. Each bullet is one sentence and ends `Nothing the plugin does changes (#N).` where that is true. The README fix from Q1 gets one line of its own, so the notes name it.

**Answer:**
Go with the recommendation: bullets for #179 and #170, and one line for the README corrections (engineer, in the conversation, 2026-11-26; recorded here by the skill).

### Q3 — Does the release go out as two pull requests, as v1.0.9 did?

**Why it matters:** `qc-verdict` fails a pull request whose head carries a live dossier, so the release PR cannot come from this branch. The v1.0.9 and v1.0.8 releases cut `release/v1.0.10` from `origin/main` in a worktree for the four-file PR, and used this workflow branch for the pin, plan and dossier, which `/codeo:close` opens after the tag exists.

**Options:** two PRs, `release/v1.0.10` for the release and this branch for the pin · one PR from this branch (fails `qc-verdict`; rejected) · pin first (rejected: `plugins.sh` checks the pin on GitHub before replacing codeo, so the tag must exist).

*Recommendation:* two PRs, as before. Your own steps are the merges, the tag push (`git tag v1.0.10 <SHA>`, lightweight, as `v1.0.5`–`v1.0.9`) and the container rebuild; the agent runs the clean-clone test and publishes the Release on your say-so.

**Answer:**
Two PRs (engineer, in the conversation, 2026-11-26; recorded here by the skill).

## Notes

`superpowers:brainstorming` ran before these questions. The role check (`role.sh --check plan`) exited 0. The overlays `plan-shape`, `proof-of-done` and `wiki-rules` are not set (exit 3), so the generic shape and the default proof apply. No invariants document, no shared environment, no `wiki` module and no exclusive resources are configured, so no task carries `Needs lease:` and nothing is leased. The lock's host is `container`, so the engineer-host tasks (merges, tag push, rebuild) need no shell question: each command is a single neutral command. Steps 6 and 7 (`engineering:system-design`, `engineering:architecture`) do not apply: no new component and no technology choice.

Calls I made without a question: the release date is the UTC date the release PR opens; the `Config schema: 1 (unchanged)` line holds (no config key changed since v1.0.9); the `Shared state:` and `Safe to bump mid-workflow:` lines are re-read against the diff since `v1.0.9` of `scripts/` when the PR is cut, not assumed; `tests/replay.test.sh` is not run (no golden directory).

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-26 — Q1-Q3 raised · cost: unavailable
- 2026-11-26 — Q1-Q3 answered; draft written to plan-draft.md for review · cost: unavailable
