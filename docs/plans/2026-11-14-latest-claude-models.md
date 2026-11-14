# Run codeo on the Latest Claude Models Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show that codeo's model aliases (`fable`, `opus`, `sonnet`) already resolve to Fable 5.2, Opus 5.5 and Sonnet 5.5, move the old model names out of the examples and fixtures, record the Haiku 5.5 evaluation, and note it all in the changelog.

**Architecture:** No skill, hook or default changes: the aliases already resolve to the latest models, so the upgrade is example text and test data. One rename pass moves `docs/dossier.md` and the fixtures together with the `sed` in `tests/replay.test.sh` that matches one of them. A second pass moves three model IDs used as test input. The alias record and the Haiku evaluation go on the issue as one comment, the Haiku trial becomes its own issue, and the changelog entry goes last because it waits for #51.

**Tech Stack:** bash, perl (for the rename), `gh`, `claude -p`, `bash tests/run.sh`.

**Spec:** `.codeo/52/init.md` (`## Outcome`: the four acceptance criteria); plan Q1-Q5 of `.codeo/52/plan.md`.

## Global Constraints

- **Criterion 2 is read as** `grep -rnE 'fable-5-1|sonnet-5([^-]|$)|opus-5([^-]|$)' docs tests/fixtures` printing nothing: the bare substrings `sonnet-5` and `opus-5` sit inside the new `sonnet-5-5` and `opus-5-5`. The mapping is `fable-5-1` → `fable-5-2`, `sonnet-5` → `sonnet-5-5`, `opus-5` → `opus-5-5`. A dry run of it in a throwaway worktree changed 82 lines in 70 files and left `bash tests/run.sh` at `all cases passed`.
- **Aliases stay** (issue Q1): no `model:` line, no `models.subagent` or `models.reviewer` default changes, and `scripts/usage.sh` is untouched. `docs/skills.md` says "the strongest model available" and names no version, so it stays.
- **History stays as written:** `.codeo/done/**` holds real cost lines, `fable-5-1` among them.
- **Haiku (plan Q2 = A):** the evaluation is recorded and nothing switches to `model: haiku` here. The evaluation: `doctor` and `setup` run one script and report its output, so they are the candidates; `init`, `close` and `triage` are long, rule-heavy flows that push branches, move cards and judge duplicates, and the subagent default writes the code in `/codeo:implement`, so they stay on Sonnet.
- **Ordering and #51 (plan Q5 = sequence after #51):** Tasks 1-4 touch nothing #51 touches. Task 5 changes `CHANGELOG.md`, which #51 also changes, so it is last and does not start until #51 has merged to `main`.
- **Documentation:** the one page this change moves is `docs/dossier.md`, whose example log line is Task 1. No other page under `docs/` names a model version. There is no wiki, no invariants document and no shared environment, so no task carries `Needs lease:`.
- The `shell` suite has no `filter`, so a task's proof is the whole `bash tests/run.sh`. Tasks 3 and 4 are not code: their proof is a `gh` command that must print the record.

## Review Focus

- The rename must not touch `sonnet-5-5` or `opus-5-5`, which already exist in `tests/usage.test.sh` and in real dossiers. The perl patterns use a lookahead for that.
- `tests/replay.test.sh` deletes a cost string from a golden fixture by exact match. If it is not changed with the fixture, the "extra finding" case stops failing the way it must.
- The record of the aliases is evidence for `/codeo:qc`, so the comment must name the Claude Code version and the command, not only the table.

---

### Task 1: Move the old model names in `docs/` and `tests/fixtures/`

**Files:**
- Modify: `docs/dossier.md` (line 194)
- Modify: 66 files under `tests/fixtures/dossiers/` and `tests/fixtures/golden/`
- Modify: `tests/replay.test.sh` (line 188)

- [ ] **Step 1: Show the failing check.** Run `grep -rnE 'fable-5-1|sonnet-5([^-]|$)|opus-5([^-]|$)' docs tests/fixtures | wc -l`. Expected: `79` or more lines, not 0.
- [ ] **Step 2: Rename.** From the repository root:

  ```bash
  grep -rlE 'fable-5-1|sonnet-5([^-]|$)|opus-5([^-]|$)' docs tests/fixtures \
    | xargs perl -pi -e 's/fable-5-1/fable-5-2/g; s/\bsonnet-5(?![-\w])/sonnet-5-5/g; s/\bopus-5(?![-\w])/opus-5-5/g'
  perl -pi -e 's/\bsonnet-5(?![-\w])/sonnet-5-5/g' tests/replay.test.sh
  ```

- [ ] **Step 3: Prove it.** Run `grep -rnE 'fable-5-1|sonnet-5([^-]|$)|opus-5([^-]|$)' docs tests/fixtures tests/replay.test.sh`. Expected: no output. Then run `bash tests/run.sh`. Expected: `all cases passed`.
- [ ] **Step 4: Commit** `docs: move the model names in the examples and fixtures to Fable 5.2, Opus 5.5 and Sonnet 5.5 (#52)`.

**Proof of done:** the `grep` prints nothing and `bash tests/run.sh` prints `all cases passed`.

### Task 2: Move the model IDs the tests use as input

**Files:**
- Modify: `tests/usage.test.sh` (lines 50 and 55)
- Modify: `tests/subagent-model.test.sh` (line 97)

- [ ] **Step 1: Edit.** In `tests/usage.test.sh` change `claude-opus-4-7` to `claude-opus-5-5` and the expected `opus-4-7 3k in` to `opus-5-5 3k in`. In `tests/subagent-model.test.sh` change `claude-haiku-4-5` to `claude-haiku-5-5`.
- [ ] **Step 2: Prove it.** Run `grep -rnE 'opus-4-7|haiku-4-5' tests`. Expected: no output. Then `bash tests/run.sh`. Expected: `all cases passed`.
- [ ] **Step 3: Commit** `test: use the current model IDs as test input (#52)`.

**Proof of done:** the `grep` prints nothing and `bash tests/run.sh` prints `all cases passed`.

### Task 3: Record the alias resolution and the Haiku evaluation on #52

**Files:** none; the record is a comment on issue #52.

- [ ] **Step 1: Re-run the check** for each of the four aliases and read the model keys:

  ```bash
  claude --version
  for a in fable opus sonnet haiku; do
    claude -p --model "$a" --output-format json "Reply with the single word: ok" | jq -c --arg a "$a" '{alias:$a, models:(.modelUsage|keys)}'
  done
  ```

  Expected: `fable` → `claude-fable-5-2`, `opus` → `claude-opus-5-5`, `sonnet` → `claude-sonnet-5-5`, `haiku` → `claude-haiku-5-5` (each run also lists `claude-haiku-5-5`, Claude Code's own background model). If an alias resolves to anything else, stop and raise it as a question in `implement.md`.
- [ ] **Step 2: Post one comment** with `gh issue comment 52 --body-file <file>`: the Claude Code version, the command, the table (alias, model, skills that use it, including the `models.subagent` and `models.reviewer` defaults), and the Haiku evaluation from Global Constraints.
- [ ] **Step 3: Prove it.** Run `gh issue view 52 --comments --json comments -q '.comments[].body' | grep -E 'claude-(fable-5-2|opus-5-5|sonnet-5-5)'`. Expected: three matching lines.

**Proof of done:** the command in step 3 prints the three model IDs.

### Task 4: File the Haiku trial as its own issue

**Files:** none; the record is a new issue.

- [ ] **Step 1: Call `/codeo:issue`** with: try `doctor` and `setup` on `model: haiku` (Haiku 5.5), judged on real runs against their current Sonnet output; `init`, `close`, `triage` and the subagent default stay on Sonnet; context is #52's comment from Task 3. Record the number it returns in `implement.md`.
- [ ] **Step 2: Prove it.** Run `gh issue view <number> --json state,title -q '.state + " " + .title'`. Expected: `OPEN` and a title naming Haiku.

**Proof of done:** the command in step 2 prints `OPEN` and the title.

### Task 5: Record the change in `CHANGELOG.md`, after #51 has merged

**Files:**
- Modify: `CHANGELOG.md` (under `## Unreleased`)

- [ ] **Step 1: Wait for #51.** Run `gh issue view 51 --json state -q .state`. Expected: `CLOSED`. If it is `OPEN`, stop and tell the engineer the changelog task is waiting on #51 (plan Q5); do not skip ahead.
- [ ] **Step 2: Bring `main` in.** `git fetch origin && git merge origin/main`, and resolve any conflict in `CHANGELOG.md` by keeping both bullets.
- [ ] **Step 3: Add one bullet** under `## Unreleased`, after the existing ones, saying: the aliases `fable`, `opus` and `sonnet` resolve to Fable 5.2, Opus 5.5 and Sonnet 5.5 in Claude Code 2.1.325 (the record is on #52); the model names in `docs/dossier.md` and `tests/fixtures/` and the test input IDs now name the current versions; the Haiku 5.5 evaluation found `doctor` and `setup` worth a trial, filed as #`<Task 4's number>`; no skill, hook or default changes (#52).
- [ ] **Step 4: Prove it.** Run `grep -n '#52' CHANGELOG.md`. Expected: one line under `## Unreleased`. Then `bash tests/run.sh`. Expected: `all cases passed`.
- [ ] **Step 5: Commit** `docs: changelog entry for the latest-models check (#52)`.

**Proof of done:** the `grep` prints the bullet and `bash tests/run.sh` prints `all cases passed`.
