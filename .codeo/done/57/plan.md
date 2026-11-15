# Issue #57 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/57 |
| Branch | `feat/dev-container-follow-ups-55` |
| Updated | 2026-11-14 |

## Where this stands

Round 1. Q1-Q5 are answered (the engineer accepted every recommendation in the conversation, and the answers are recorded under each). The plan was approved and is written, unstaged, to `docs/plans/2026-11-14-dev-container-follow-ups.md`. The footprint is under `## Notes`. Q6 restated the overlap with #76 in the form `overlap.sh` reads and is answered; `overlap.sh 57` prints nothing. `## Outcome` is written and the next step is `/codeo:implement`.

Two things the drafting turned up, both reflected in the draft:
- **F2 does not reproduce as `qc.md` states it.** On a project whose base is `develop`, the home clone in the folder `codeo-home` already gets no TODO today. The real defects are the ones next to it: the folder `codeo-12` on the home clone is silent, and a wrong folder gets the issue-or-home wording and not the home wording. Task 1 fixes those and still pins the criterion's case.
- **No CHANGELOG sentence says "all three names come from `container-name.sh`".** The F5 claim is in the script's header only. Q4's edit therefore makes line 42's description of `container-name.sh` say what it does (the names; the Docker name comes from the folder through `runArgs`), and the Unreleased bullet states the correction.

Settled without a question (say so under any answer if one is wrong):

- **F2.** `folder-check.sh` reads the base branch from `.codeo/config.json` (`baseBranch`, else `main`), as `devcontainer-start.sh` does, and its TODO names that branch instead of `main`.
- **F5, F7.** The header of `container-name.sh` says the Docker name comes from the clone folder through `runArgs` and that `--docker` prints what it should be. `.devcontainer/README.md` names `.devcontainer/scripts/devcontainer-start.sh`.
- **Deferred minors: all five are fixed, none dismissed.**
  - Header wording in `container-name.sh`: the same edit as F5.
  - `window-title.sh` no longer captures `container-name.sh` with `2>&1`, so a warning on stderr cannot end up in the title; the error text is still reported on failure.
  - A new case in `tests/folder-check.test.sh`: the folder `codeo-home` on a branch that is not the base, with no lock, gets no TODO.
  - When `lock.sh` exits non-zero, the start script puts its output in the one failure TODO and does not also print it line by line.
  - `tests/init-overlay.test.sh` looks for `This skill does not write` followed by `.codeo/active`, not the bare path.
- **Shape.** One plan under `docs/plans/`, one PR. No reference doc: nothing here is a standing decision beyond what `.devcontainer/README.md` already holds.
- **Nothing under `scripts/`, `lib/`, `hooks/` or `skills/` changes.** The container runs the pinned plugin, so a fix to this repository's own `scripts/lock.sh` would not reach it until the next pin bump.

## Questions

### Q1 — F4, two checkouts with the same folder name: document the limit, or make them run at once?

**Why it matters:** the two answers are different tasks. *Document* is two paragraphs (README and CHANGELOG) and no code. *Fix* changes `runArgs` in `devcontainer.json`, which changes every container's Docker name again and needs a rebuild of each, as #50 and #55 did.

What I found: the clash only happens when a folder on the host is opened in a container (**Dev Containers: Reopen in Container**), because the Docker name is the folder's name. The documented way in (**Clone Repository in Named Container Volume…**) uses the folders `codeo-home` and `codeo-<N>`, which never clash. A host folder named `codeo` already gets a wrong-folder TODO from `folder-check.sh`, so that way in is tolerated and not supported. The only fix I can see is to put `-${devcontainerId}` back on the name, which undoes #55's point: `docker ps` would show `codeo-57-<52 characters>` instead of `codeo-57`.

**Options:**
- *Document only* (recommended): `.devcontainer/README.md` and the CHANGELOG say that the Docker name is the folder name, so two containers whose folders share a name cannot run at once, that Docker reports "name already in use" for this as well as for a leftover container, and that the fix is to give one checkout another folder name (or use the named-volume flow).
- *Fix*: `--name=${containerWorkspaceFolderBasename}-${devcontainerId}`; names get long again and every container is rebuilt once.

**Answer:**
Document only. Go with the recommendation (engineer, in the conversation, 2026-11-14).

### Q2 — F6, an empty `.codeo/active`: remove it and take the lock, or leave it and print a TODO?

**Why it matters:** it decides what step 3a of `devcontainer-start.sh` does and what the new test asserts (a lock taken, or a `todo:` line). Today the start script treats the empty file as no lock and calls `lock.sh`, which sees the file, prints `lock already taken:` with nothing after it and takes nothing.

**Options:**
- *Remove it and carry on* (recommended): a zero-byte file holds no lock, so the script deletes it, prints `devcontainer-start: .codeo/active was empty and held no lock: removed it`, and then does what it does for a clone with no lock (takes the lock on an issue branch, nothing on the base branch). The container ends up usable with no step for you.
- *TODO only*: the script touches nothing and lists `TODO — .codeo/active is empty, so it holds no lock and blocks taking one: remove it, then re-run this script`.

Either way only a zero-byte file is covered. A file with content that names no issue is left as it is today (it reads as a held lock); I would file that separately if you want it handled.

**Answer:**
Remove it and carry on. Go with the recommendation (engineer, in the conversation, 2026-11-14).

### Q3 — F3, which registry entry is "this project's" codeo, and what happens when none is?

**Why it matters:** it is the selection rule `codeo-root.sh` gets and the cases the test covers. The registry (`installed_plugins.json`) lists entries for `codeo@codeo` with a `scope`, and the project-scoped ones carry a `projectPath`. In this container it holds two: `scope: user` (what `plugins.sh` installs) and `scope: project` with `projectPath: /workspaces/codeo-57`.

**Proposed rule** (recommended): take the first entry that passes, in this order, and never an entry whose `projectPath` is another project:
1. an entry whose `projectPath` is this clone's root;
2. an entry with no `projectPath` (user scope, or an older registry without the field).

If neither exists, or the chosen entry has no `scripts/lock.sh`, the script fails as it does today and the start script lists its "codeo is not installed" TODO. It does not fall back to another project's entry: the script's own header says no path is ever guessed.

**Options:** *the proposed rule* · *the user-scope entry first, then this project's* · *something else (say what)*.

**Answer:**
The proposed rule. Go with the recommendation (engineer, in the conversation, 2026-11-14).

### Q4 — The wrong CHANGELOG sentence is in the released v1.0.4 section. Edit it there, or correct it under Unreleased?

**Why it matters:** it decides which CHANGELOG lines the documentation task touches. The #55 bullet under `## v1.0.4` lists `container-name.sh` among the new scripts without saying the Docker name comes from the folder; criterion 5 says "the CHANGELOG line … match the code". Editing a released section changes what v1.0.4's notes say after the fact; I found no earlier case of that in this file.

**Options:**
- *Edit the v1.0.4 bullet in place and say so under Unreleased* (recommended): the old bullet gets the correct sentence, and the new Unreleased bullet for #57 notes that it was corrected. A reader of either section gets the right account.
- *Leave v1.0.4 as released*: only the Unreleased bullet states the correction.

**Answer:**
Edit the v1.0.4 bullet in place and say so under Unreleased. Go with the recommendation (engineer, in the conversation, 2026-11-14).

### Q5 — #76 also plans to edit `CHANGELOG.md`. Proceed and coordinate, sequence after #76, or re-scope?

**Why it matters:** both branches add a bullet under `## Unreleased`, so whichever merges second gets a conflict there, and `overlap.sh` reports the pair until a question names it. The other workflow is #76, branch `feat/trial-doctor-setup-haiku-5`, assignee kbajpai, step `plan` (working); its footprint lists `CHANGELOG.md` and its branch has not changed the file yet. What overlaps is the path `CHANGELOG.md` and nothing else. (#73 is also in flight and shares nothing with this plan.)

**Options:**
- *Proceed and coordinate* (recommended): both carry on; the second to merge resolves a one-line conflict by keeping both bullets, which `/codeo:close` routes back through `/codeo:implement`. With Q4's first option this plan also edits one line under `## v1.0.4`, which #76 does not touch.
- *Sequence after #76*: this plan waits until #76 merges.
- *Re-scope*: this plan leaves `CHANGELOG.md` alone, which fails criteria 5 and 7.

**Answer:**
Proceed and coordinate. Go with the recommendation (engineer, in the conversation, 2026-11-14).

### Q6 — Overlap with #76 on `glob:CHANGELOG.md`: proceed and coordinate, sequence after #76, or re-scope?

**Why it matters:** this is Q5's overlap restated in the form `overlap.sh` reads. After the plan was approved and its footprint written, `overlap.sh 57` printed `76<TAB>glob:CHANGELOG.md`, and it counts a pair as raised only when a `### Q` block quotes `#M` and that exact token; Q5 named the file but not the token, so the hand-off stays blocked until this is answered. Nothing else changes: your answer to Q5 stands and my recommendation is the same.

The other workflow is #76, branch `feat/trial-doctor-setup-haiku-5`, assignee kbajpai, step `plan` (working). What overlaps is `glob:CHANGELOG.md` and nothing else.

**Options:** *proceed and coordinate* (recommended) · *sequence after #76* · *re-scope*.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-15).

## Notes

Read for this pass: `.codeo/57/init.md`, `.codeo/57/issue.md`, `.codeo/done/55/qc.md` (F2-F8), `.codeo/done/55/implement.md` (deferred minors), every script under `.devcontainer/scripts/`, `.devcontainer/README.md`, `.devcontainer/devcontainer.json`, `scripts/lock.sh` (`take`), `tests/codeo-root.test.sh`, `tests/folder-check.test.sh`, `tests/init-overlay.test.sh`, the lock cases of `tests/devcontainer.test.sh`, `CHANGELOG.md`, and `docs/plans/2026-11-14-seed-dev-container-git-identity.md` for the house shape.

Config: one suite, `shell` (`bash tests/run.sh`, no `filter`, so each task's proof is the whole suite). No invariants document, no shared environment, no `wiki` module, no `resources`. Overlays `plan/plan-shape`, `plan/proof-of-done` and `plan/wiki-rules`: none (exit 3).

Where each finding lives:
- F2: `.devcontainer/scripts/folder-check.sh:42-44`.
- F3: `.devcontainer/scripts/codeo-root.sh:24`.
- F6: `.devcontainer/scripts/devcontainer-start.sh:154` (`-s`) against `scripts/lock.sh:107` (`-f`).
- F5: `.devcontainer/scripts/container-name.sh:2-7`; F7: `.devcontainer/README.md:25`.
- Minors: `.devcontainer/scripts/window-title.sh:22`; `.devcontainer/scripts/devcontainer-start.sh:162-169`; `tests/init-overlay.test.sh:18`.

## Outcome

**Plan:** `docs/plans/2026-11-14-dev-container-follow-ups.md` (approved, unstaged), five tasks, each proved by `bash tests/run.sh`.

**Shape:** an executable plan under `docs/plans/`; no reference doc, because nothing here is a standing decision beyond what `.devcontainer/README.md` already holds.

**Decisions** (Q1-Q6 answered by accepting each recommendation):
- Q1, F4: document the shared-folder-name limit and its fix; `runArgs` does not change, so no container is rebuilt. Rejected: putting `-${devcontainerId}` back on the name, which undoes #55's short `docker ps` name.
- Q2, F6: a zero-byte `.codeo/active` is removed with a printed line and the script carries on as for a clone with no lock. Rejected: a TODO only. A file with content that names no issue is left as it is.
- Q3, F3: `codeo-root.sh` takes the first `codeo@codeo` entry whose `projectPath` is this clone, else the first with no `projectPath`, and never another project's. Rejected: user scope first.
- Q4: the `## v1.0.4` bullet for #55 is edited in place and `## Unreleased` says so. Rejected: leaving the released section as is.
- Q5, Q6: proceed and coordinate with #76 on `CHANGELOG.md`; the second branch to merge keeps both bullets. Rejected: sequencing after #76, re-scoping.
- F2, F5, F7 and all five deferred minors were settled without a question: all fixed, none dismissed.

**Two findings from planning:** F2 does not reproduce as `qc.md` states it (the home clone in `codeo-home` on a non-`main` base gets no TODO today; the real defects are `codeo-12` being silent there and the wrong-folder text), and no CHANGELOG sentence repeats the F5 claim (it is only in the `container-name.sh` header), so Task 5's CHANGELOG edit clarifies what the v1.0.4 bullet says `container-name.sh` does.

**Intake questions resolved here:** the issue's choice for F4 (run side by side, or document why not) is resolved by Q1: document.

**Documentation the plan changes:** `.devcontainer/README.md` (Task 5). No page under `docs/` moves.

**Issues filed:** none.

### Footprint

```
files:      .devcontainer/scripts/folder-check.sh, .devcontainer/scripts/codeo-root.sh, .devcontainer/scripts/devcontainer-start.sh, .devcontainer/scripts/window-title.sh, .devcontainer/scripts/container-name.sh, .devcontainer/README.md, tests/folder-check.test.sh, tests/codeo-root.test.sh, tests/devcontainer.test.sh, tests/init-overlay.test.sh, CHANGELOG.md, docs/plans/2026-11-14-dev-container-follow-ups.md
wiki:       none
exclusive:  none
sequenced:  none — CHANGELOG.md overlaps #76; proceed and coordinate (Q5, Q6)
```

## Log

- 2026-11-14 — Q1-Q5 raised · cost: 2m · fable-5-2 108k in + 517k cached / 7k out
- 2026-11-15 — planned: docs/plans/2026-11-14-dev-container-follow-ups.md · cost: 61m · fable-5-2 118k in + 930k cached / 13k out · sonnet-5-5 154k in + 1.8M cached / 24k out
