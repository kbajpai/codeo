# Numbered Branch Names Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/codeo:init` cuts `<type>/<N>-<slug>`, finds a workflow already under way by its dossier whatever its branch is called, and the docs, tests and `claim.sh` messages agree.

**Architecture:** `branch-name.sh` prefixes the slug with the issue number, which makes two issues' names differ by construction. `/codeo:init` stops deriving the name to find a resume: it asks `inflight.sh --branches` which branch carries `.codeo/<N>/` and uses the derived name only for a fresh claim, so old-style branches keep resuming. `claim.sh --carries` keeps its "another issue's dossier" refusal but drops the title-collision advice, which no longer describes how the case arises.

**Tech Stack:** bash, the `shell` suite (`bash tests/run.sh [pattern]`).

**Spec:** issue #126 (`.codeo/126/issue.md`) and the answers in `.codeo/126/plan.md` — Q1 A (find the branch by its dossier), Q2 A (keep the refusal, reword the remedy). No separate reference doc: the change moves no standing decision.

## Global Constraints

- **Name shape:** `<type>/<N>-<slug>`. The type and the slug are derived exactly as today (first mapped label → type, else `chore`; leading `[...]` group stripped, stop words dropped, five words kept). A title with no words left still exits 1; there is no `<type>/<N>` fallback.
- **Old branches:** never renamed, never given a command to rename. They resume through their dossier.
- **Out of scope** (from the issue): `labelTypes`, the five-word cap, sandbox and container names.
- **Invariants document:** none configured, so there is nothing to check the plan against.
- **Documentation moved:** `skills/init/SKILL.md` (steps 3 and 6), the branch example in `docs/dossier.md` and `docs/handoff.md`, and `CHANGELOG.md`. No other page under `docs/` describes how the branch is named or found (searched for `branch-name`, `branch name`, `five words`).
- **No shared environment** (`environment.resource` is unset): no task carries `Needs lease:`, and every task is proved in this checkout.
- **Order:** tasks 1-3 are independent in code; task 3's skill text names the shape task 1 produces, so run them in order.

## File Structure

| File | Change |
|---|---|
| `scripts/branch-name.sh` | print `<type>/<N>-<slug>`; header comment |
| `tests/branch-name.test.sh` | new expectations, a same-title case |
| `scripts/claim.sh` | reword the another-issue's-dossier remedy (line 210) and its header comment (lines 26-29) |
| `tests/claim.test.sh` | the case at line 328 |
| `skills/init/SKILL.md` | step 3 exception, step 6 lookup |
| `tests/init-skill.test.sh` | step 3 and step 6 wording |
| `docs/dossier.md`, `docs/handoff.md` | example branch `feat/12-order-export` |
| `CHANGELOG.md` | new `## Unreleased` entry |

## Review Focus

- A title of only stop words: still exits 1 with `no words left`, number or not (task 1 test).
- Two issues with one title: two different names (task 1 test).
- A workflow on an old-style branch whose issue was retitled since: found by dossier, not by name (task 3 wording).
- One issue whose dossier sits on two branches: `init` stops and names both rather than picking one (task 3 wording).
- A hand-pushed branch named `<type>/<N>-<slug>` that carries another issue's dossier: still refused, with the new message (task 2 test).

---

### Task 1: `branch-name.sh` prints the number

**Files:**
- Modify: `scripts/branch-name.sh:5-11` (header), `scripts/branch-name.sh:52` (the final `echo`)
- Test: `tests/branch-name.test.sh`

**Interfaces:**
- Produces: `bash scripts/branch-name.sh <N>` prints `<type>/<N>-<slug>` and exits 0; exits 1 with `branch-name: no words left in the title of #<N>` when no words remain. Tasks 2-3 and the docs rely on this shape.

- [ ] **Step 1: Update `tests/branch-name.test.sh`**: every expected name gains `<N>-` after the type. The cases become `feat/120-work-backlog-pipeline-environment-chores`, `feat/73-refuse-lease-while-environment-carries`, `fix/5-fix-thing`, `docs/6-docs-page`, `chore/7-three-words-only`, `chore/8-fix-thing-now`, `feat/10-add-widget`, `fix/11-add-widget`, `chore/12-add-widget`, `fix/13-handle-x-my-file-sh`, `chore/14-z-x`, and `fix/5-fix-thing` in the quiet-config case. Add, under `case_desc="branch-name.sh"`:

```bash
canned 20 'Same title' enhancement
canned 21 'Same title' enhancement
assert_eq "same title, issue 20" "feat/20-same-title" "$(run_name 20)"
assert_eq "same title, issue 21" "feat/21-same-title" "$(run_name 21)"
```

  The `[Bug] the of a` case still expects exit 1 and `no words left`.

- [ ] **Step 2: Run it and see it fail**

Run: `bash tests/run.sh branch-name`
Expected: exit 1, with `FAIL: branch-name.sh — #120: want [feat/120-work-backlog-pipeline-environment-chores] got [feat/work-backlog-pipeline-environment-chores]`.

- [ ] **Step 3: Implement** — change the last line of `scripts/branch-name.sh` to `echo "$type/$n-$slug"`, and in the header replace `Prints <type>/<slug>` with `Prints <type>/<N>-<slug>` and the sentence `The issue number is never part of it.` with `The issue number follows the type, so two issues with one title derive two names.` (keep `Exits 1 when no words are left in the title.`).

- [ ] **Step 4: Run it and see it pass**

Run: `bash tests/run.sh branch-name`
Expected: `all cases passed`, exit 0.

- [ ] **Step 5: Commit** — `git add scripts/branch-name.sh tests/branch-name.test.sh`, subject `feat: put the issue number in the branch name (#126)`.

### Task 2: `claim.sh` — reword the another-issue's-dossier refusal

**Files:**
- Modify: `scripts/claim.sh:26-29` (header), `scripts/claim.sh:210` (the second `echo`)
- Test: `tests/claim.test.sh:328`

**Interfaces:**
- Produces: `claim.sh --carries <N> <branch> <repo>` on a branch carrying #M's dossier (M ≠ N) still exits 2 with the first line unchanged and the second line, exactly: `claim: <branch> carries #<M>'s dossier, not #<N>'s — rename or delete it on origin (init cuts <type>/<N>-<slug>, so a branch with another issue's dossier under that name was pushed by hand)`. The own-archive, merged-and-left, bare and no-dossier readings are untouched.

- [ ] **Step 1: Update the test** — at `tests/claim.test.sh:328` replace the `remedy` assertion with

```bash
assert_contains "remedy" "claim: feat/c carries #42's dossier, not #43's — rename or delete it on origin" "$out"
assert_not_contains "no title advice" "derives the same branch name" "$out"
```

- [ ] **Step 2: Run it and see it fail**

Run: `bash tests/run.sh claim`
Expected: exit 1, `FAIL: --carries: another issue's dossier is a collision, exit 2, naming #M and the remedy — remedy: want substring [claim: feat/c carries #42's dossier, not #43's …`.

- [ ] **Step 3: Implement** — replace the `echo` at line 210 with the message above (`$branch`, `$other`, `$n` as in the surrounding lines), and in the header's exit-2 paragraph replace `retitle #N or wait for #M` with `rename or delete the branch on origin`.

- [ ] **Step 4: Run it and see it pass**

Run: `bash tests/run.sh claim`
Expected: `all cases passed`, exit 0.

- [ ] **Step 5: Commit** — `git add scripts/claim.sh tests/claim.test.sh`, subject `fix: stop advising a retitle for a hand-pushed branch name (#126)`.

### Task 3: `/codeo:init` finds a resume by its dossier

**Files:**
- Modify: `skills/init/SKILL.md` — step 3 (the paragraph beginning `**Check nobody else has it.**`, lines 85-97) and step 6 (lines 151-170)
- Test: `tests/init-skill.test.sh`

**Interfaces:**
- Consumes: Task 1's name shape; `inflight.sh --branches` (one `N<TAB>branch<TAB>dir` row per workflow, `dir` being `.codeo/<N>` while worked and `.codeo/done/<N>` once close opened the PR; it fetches origin itself).
- Produces: the skill text step 6 follows. It states, in this order:
  1. *Find the branch by its dossier first.* Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/inflight.sh" --branches` and read this issue's rows. One row with `dir` `.codeo/<N>` names `<branch>`, whatever it is called: it is a resume candidate, and the `--carries`, `--stash-live` and resume sub-steps below run on it, with the derivation and `ls-remote` skipped. A row with `dir` `.codeo/done/<N>` is step 3's `(PR open)` stop. More than one row for this issue is a stop that names every branch.
  2. *No row: derive.* `branch-name.sh <N>` prints `<type>/<N>-<slug>`, never chosen by the agent; then the existing `ls-remote` and `--carries` collision checks, unchanged.
- And in step 3: a `(working)` listing of this issue on any branch is the resume step 6 classifies, not a second start; the sentence that stops on "this issue's dossier on a branch of any other name" and the advice to "restore the title" are removed, as is step 6's `There is no issue number in it.` Another assignee and `(PR open)` still stop.

- [ ] **Step 1: Write the failing checks** in `tests/init-skill.test.sh`. Add a helper next to `step_contains`:

```bash
# $1 case, $2 step number, $3 fixed string the step must not contain.
step_lacks() {
    local text
    text=$(step "$2")
    [[ -n $text ]] || { fail "$1 — no step $2 in the skill"; return; }
    ! grep -qF -- "$3" <<<"$text" || fail "$1 — step $2 still has [$3]"
}
```

  then

```bash
step_contains "step 6 finds the branch by its dossier" 6 'scripts/inflight.sh" --branches'
step_contains "step 6 names the new shape" 6 '<type>/<N>-<slug>'
step_contains "step 6 stops on two branches for one issue" 6 'more than one row'
step_lacks "step 6 no longer says the number is absent" 6 'There is no issue number in it.'
step_lacks "step 3 no longer says restore the title" 3 'restore the title'
```

- [ ] **Step 2: Run it and see it fail**

Run: `bash tests/run.sh init-skill`
Expected: exit 1 with five `FAIL:` lines, the first `FAIL: step 6 finds the branch by its dossier — step 6 has no [scripts/inflight.sh" --branches]`.

- [ ] **Step 3: Edit `skills/init/SKILL.md`** as the Produces block says, keeping the surrounding sentences, rule comments and the `--carries` / `--stash-live` / resume sub-steps as they are. Where step 6's exit-2 paragraph says the engineer "retitles the issue or waits for the other to close", change it to say the engineer renames or deletes the branch, matching Task 2's message.

- [ ] **Step 4: Run it and see it pass**

Run: `bash tests/run.sh init`
Expected: `all cases passed`, exit 0 (this runs `init-skill`, `init-overlay` and every other file whose name contains `init`).

- [ ] **Step 5: Commit** — `git add skills/init/SKILL.md tests/init-skill.test.sh`, subject `feat: init finds a workflow by its dossier, not its branch name (#126)`.

### Task 4: Documentation — examples and changelog

**Files:**
- Modify: `docs/dossier.md:158`, `docs/handoff.md:39`, `CHANGELOG.md`

**What each says afterwards:**
- `docs/dossier.md:158` and `docs/handoff.md:39`: the imaginary issue #12's branch reads `feat/12-order-export`, so the examples show the shape `init` cuts. (A `branch:` line in `handoff.md` and a `Branch` row in `dossier.md`; no diagram changes.)
- `CHANGELOG.md`: a new `## Unreleased` section above `## v1.0.7`, with the header lines `Config schema: 1`, `Shared state: new branches are named <type>/<N>-<slug>; branches already cut keep their names and are found by their dossier` and `Safe to bump mid-workflow: yes`, then one bullet: `/codeo:init` cuts `<type>/<N>-<slug>`, so the issue is readable from the branch (`feat/118-live-signal-leftovers-104-refresh`); `branch-name.sh` prints the number, `init` finds a workflow under way by its dossier whatever its branch is called, so a branch cut under the old shape resumes and an issue retitled after its init does too, and `claim.sh` no longer tells you to retitle an issue whose name another issue's dossier holds (#126).

- [ ] **Step 1: Make the three edits above.**
- [ ] **Step 2: Prove the docs and the whole suite agree**

Run: `bash tests/run.sh`
Expected: `all cases passed`, exit 0.

- [ ] **Step 3: Prove the old statement is gone**

Run: `grep -rn "never part of it\|There is no issue number in it\|derives the same branch name" scripts skills docs tests | grep -v "docs/plans\|tests/claim.test.sh"`
Expected: no output (`tests/claim.test.sh` is excluded because its `assert_not_contains` line quotes the old wording on purpose).

- [ ] **Step 4: Commit** — `git add docs/dossier.md docs/handoff.md CHANGELOG.md`, subject `docs: describe the numbered branch name (#126)`.

## Self-review

- **Spec coverage:** criteria 1-2 → Task 1; 3-4 → Task 3 (the fresh-claim path and the dossier lookup); 5 → Task 2; 6 → Tasks 1-4. `tests/run.sh` itself needs no edit: it discovers `*.test.sh`.
- **Gap, stated:** criterion 3 and 4 are skill text, which the repo proves by checking its wording (`tests/init-skill.test.sh`), not by running `init`. `/codeo:qc` judges them against the text and the Task 1 output.
