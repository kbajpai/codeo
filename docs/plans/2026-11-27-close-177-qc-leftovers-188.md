# Close the #177 QC leftovers (F2-F6) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct five sentences (and one comma) that are true on one path only, as #177's QC round 2 recorded them, so the docs, skills and overlays match what the scripts do.

**Architecture:** Wording only, in six tasks, one per finding plus the changelog. Each fix that a test already pins moves the pin first (red), then the wording (green); the ones no test covers get a `grep` check with its expected count. No script changes.

**Tech Stack:** Markdown, bash test files under `tests/`, run by `bash tests/run.sh [pattern]`.

**Spec:** `.codeo/188/issue.md` (Key Requirements F2-F6) and `.codeo/done/177/qc.md`, round 2, F2-F6. No separate reference doc: nothing here is a standing decision.

## Global Constraints

- **Wording only.** `scripts/live.sh`, `scripts/cleanup.sh`, `.sbx/codeo-sandbox.sh` and `.devcontainer/codeo-container.sh` are read, never edited. The `note: codeo-track.sh is not beside this script` text they print is script output and stays.
- **Overlays and their templates change together.** `tests/containers.test.sh` (`codeos_own_overlays_equal_the_render`) fails when `.codeo/overlays/{cleanup,close}.md` differ from `templates/containers/.codeo/overlays/` after substitution, so every overlay edit is made in both files, byte for byte.
- **Engineer's answers (dossier Q1-Q4).** "Nothing is asked without a tracker" goes into `docs/home-checkout.md` only; the overlays gain `CODEO_TRACK` and nothing about asking, because `codeo-sandbox.sh end` never asks. Overlaps with #195, #204 and #206 are accepted: proceed and coordinate.
- **Documentation this change moves:** the pages *are* the tasks (`docs/release-checklist.md`, `docs/home-checkout.md`, `skills/close/SKILL.md`, `skills/cleanup/SKILL.md`, the overlays). No other page under `docs/` describes the five corrected sentences (checked with `grep -rn` for each phrase), so nothing else is documented. No diagram changes.
- **Invariants:** none configured. **Shared environment:** none, so no task needs a lease and every task is proved in this checkout.
- **Proof of done.** The `shell` suite has no single-test `filter`, so each task's proof is `bash tests/run.sh`, which must end with `all cases passed`. During red and green, `bash tests/run.sh <pattern>` runs one file, printing `all cases passed` or `=== FAIL: <file>`.
- **Commits** are one per task, staged by name; the plan document itself stays unstaged until the engineer asks.

## Review Focus

- A literal reader skipping every `ls-remote` line because of the `refs/heads/` prefix: Task 2 pins the prefix-dropping sentence.
- An overlay edited without its template: Task 3's proof is the whole suite, which includes the template-equality test.
- A fixed sentence that becomes untrue again when #195, #204 or #206 land: Task 2, 5 and the Global Constraints name each; the second workflow to merge re-reads the sentence.

---

## File Structure

| File | Change |
|---|---|
| `docs/release-checklist.md:91-92` | F2 wording |
| `CHANGELOG.md:40` | stray comma; `## Unreleased` gains one line |
| `skills/close/SKILL.md:550-552` | F3 wording |
| `tests/close-skill.test.sh:232` | F3 pin |
| `.codeo/overlays/cleanup.md:12`, `.codeo/overlays/close.md:11` and the two `templates/containers/.codeo/overlays/` copies | F4 wording |
| `tests/cleanup-skill.test.sh:111`, `tests/close-removal.test.sh:32` | F4 pins |
| `docs/home-checkout.md:9` and `:132` | F5 wording; F4 tracker sentence |
| `skills/cleanup/SKILL.md:84` | F6 wording |
| `tests/cleanup-skill.test.sh` | F6 pin |
| `docs/plans/2026-11-27-close-177-qc-leftovers-188.md` | this plan |

## Tasks

### Task 1: F2 — the UTC date can differ by a day; the stray comma

**Files:**
- Modify: `docs/release-checklist.md:91-92`
- Modify: `CHANGELOG.md:40`

- [ ] **Step 1: Run the failing check.** `grep -c 'the day after' docs/release-checklist.md; grep -c 'on record, is listed' CHANGELOG.md`
  Expected: `1` then `1` (both defects present).
- [ ] **Step 2: Reword F2.** Replace "which can be the day after the engineer's local date" with "which can differ by a day from the engineer's local date" (west of UTC the UTC date is ahead, east of it behind). Keep the line wrapped as it is.
- [ ] **Step 3: Remove the comma.** In the v1.0.9 section, "on record, is listed" becomes "on record is listed".
- [ ] **Step 4: Proof.** The same `grep -c` pair now prints `0` then `0`, and `grep -c 'differ by a day from the engineer' docs/release-checklist.md` prints `1`. Then `bash tests/run.sh` ends `all cases passed`.
- [ ] **Step 5: Commit** `git add docs/release-checklist.md CHANGELOG.md` · `docs: the release date can differ by a day from local; drop a stray comma (#188)`.

### Task 2: F3 — the `ls-remote` allowlist works on the literal output

**Files:**
- Modify: `skills/close/SKILL.md:550-552` (step 17, hosted-web paragraph)
- Test: `tests/close-skill.test.sh:232`

- [ ] **Step 1: Write the failing pins.** Replace the `per branch it printed` `step_contains` line with two, in the file's style:
  `step_contains "step 17 drops the refs/heads prefix before the allowlist" 17 'drop the `refs/heads/` prefix'` and
  `step_contains "step 17 prints one delete per branch that passes" 17 'one `git push origin --delete <branch>` per branch that passes'`.
- [ ] **Step 2: Run it to see it fail.** `bash tests/run.sh close-skill` — Expected: `=== FAIL: close-skill.test.sh`, naming both new pins.
- [ ] **Step 3: Reword the paragraph.** Say each line `ls-remote` prints is `<sha>`, a tab, then `refs/heads/<branch>`; to drop the `refs/heads/` prefix first; then, for each name that is `codeo-live/<issue>/` followed only by letters, digits, `.`, `_` or `-`, to say it stays on `origin` and print one `git push origin --delete <branch>` per branch that passes, with that exact name, run outside the hosted session. The clauses for no output, a name outside the set, and a failed read stay as they are.
- [ ] **Step 4: Proof.** `bash tests/run.sh` ends `all cases passed`.
- [ ] **Step 5: Commit** `git add skills/close/SKILL.md tests/close-skill.test.sh` · `docs: step 17's allowlist reads the literal ls-remote output (#188)`.

### Task 3: F4 — the overlays name `CODEO_TRACK`

**Files:**
- Modify: `.codeo/overlays/cleanup.md:12`, `.codeo/overlays/close.md:11`, `templates/containers/.codeo/overlays/cleanup.md`, `templates/containers/.codeo/overlays/close.md` (same line in each)
- Test: `tests/cleanup-skill.test.sh:111`, `tests/close-removal.test.sh:32`

- [ ] **Step 1: Write the failing pins.** In both files, replace the needle `'when codeo-track.sh sits beside'` with `'else codeo-track.sh sits beside'` and add the needle `'CODEO_TRACK names it'`.
- [ ] **Step 2: Run to see it fail.** `bash tests/run.sh cleanup-skill; bash tests/run.sh close-removal` — Expected: both print `=== FAIL`, lacking the new needles.
- [ ] **Step 3: Reword the condition** in all four files, identically: "which marks its row itself only when it finds the tracker (`CODEO_TRACK` names it, else codeo-track.sh sits beside it)". The rest of the sentence (the `note:`, "records nothing", marking by hand) is unchanged, and so is everything about asking: `end` asks nothing (Q1).
- [ ] **Step 4: Proof.** `bash tests/run.sh` ends `all cases passed` — which includes `containers.test.sh`'s overlay-equals-template check.
- [ ] **Step 5: Commit** the four overlay files and two tests · `docs: the overlays say CODEO_TRACK also supplies the tracker (#188)`.

### Task 4: F4 and F5 — `docs/home-checkout.md`

**Files:**
- Modify: `docs/home-checkout.md:9` (F5) and `:132` (F4; the tracking-comment section, since the cited `:66` states no tracker condition)

- [ ] **Step 1: Run the failing checks.** `grep -c 'skipping the assignee lookup' docs/home-checkout.md` → `1`; `grep -c 'CODEO_TRACK' docs/home-checkout.md` → `0`.
- [ ] **Step 2: F5.** Replace "skipping the assignee lookup" with "getting nothing from the assignee lookup (`gh` still runs, but parsing its answer needs `jq`)". It matters only for a web session whose `GET /user` failed; do not widen the claim.
- [ ] **Step 3: F4.** End the paragraph at `:132` with one sentence: the tracker is `CODEO_TRACK` when set, else `codeo-track.sh` beside the script; with neither, the scripts print one `note:` line, record nothing, and ask nothing, the question above included.
- [ ] **Step 4: Proof.** The first two greps print `0` and `1` or more; `bash tests/run.sh` ends `all cases passed`.
- [ ] **Step 5: Commit** `git add docs/home-checkout.md` · `docs: home-checkout's assignee lookup and tracker sentences are exact (#188)`.

### Task 5: F6 — a `name`-only failure gets a `leftover` line only while origin holds branches

**Files:**
- Modify: `skills/cleanup/SKILL.md:84`
- Test: `tests/cleanup-skill.test.sh`

- [ ] **Step 1: Write the failing pin** in the file's `check_fail` style: the skill's text must contain `'while origin still holds'`: `[[ $(<"$skill") == *'while origin still holds'* ]] || check_fail "step 4 does not say a failed-name issue gets a leftover line only while origin holds its branches"`.
- [ ] **Step 2: Run to see it fail.** `bash tests/run.sh cleanup-skill` — Expected: `=== FAIL: cleanup-skill.test.sh` with that message.
- [ ] **Step 3: Reword the parenthesis** to "(an issue that failed only `name` gets one while origin still holds its `codeo-live/<N>/*` branches)". `tests/cleanup.test.sh:160-170` already shows both cases and is not edited.
- [ ] **Step 4: Proof.** `bash tests/run.sh` ends `all cases passed`.
- [ ] **Step 5: Commit** `git add skills/cleanup/SKILL.md tests/cleanup-skill.test.sh` · `docs: cleanup's leftover line depends on origin still holding branches (#188)`.

### Task 6: Changelog line and the final check

**Files:**
- Modify: `CHANGELOG.md` (`## Unreleased`)

- [ ] **Step 1: Add one bullet** after the existing two, in their style: documentation leftovers from #177's QC round 2 (F2-F6) — the release date can differ by a day, step 17 drops `refs/heads/`, the overlays and `docs/home-checkout.md` say `CODEO_TRACK` supplies the tracker, `live.sh`'s assignee lookup and `cleanup`'s `leftover` line are described as they behave; no script changes. Leave the `Config schema`, `Shared state` and `Safe to bump` lines as they are.
- [ ] **Step 2: Proof.** `bash tests/run.sh` ends `all cases passed`, and `git diff --stat main -- scripts lib hooks .sbx .devcontainer` prints nothing (no script changed).
- [ ] **Step 3: Commit** `git add CHANGELOG.md` · `docs: changelog line for the #177 leftovers (#188)`.

## Self-review

- **Spec coverage:** F2 → Task 1; F3 → 2; F4 → 3 and 4; F5 → 4; F6 → 5; the comma → 1; the criteria's last line → every proof. Each acceptance criterion of `init.md` has a task.
- **Dismissed:** none. The only departure is where F4's "nothing is asked" lands (`home-checkout.md`, not the overlays), by the engineer's answer to Q1; the pull request says so.
- **Cited line numbers** are those found at planning time; `:66` in the issue is not where `home-checkout.md` states the condition, and `CHANGELOG.md:30` is `:40`.

### Footprint

```
files:      docs/release-checklist.md, CHANGELOG.md, skills/close/SKILL.md, skills/cleanup/SKILL.md, docs/home-checkout.md, .codeo/overlays/cleanup.md, .codeo/overlays/close.md, templates/containers/.codeo/overlays/cleanup.md, templates/containers/.codeo/overlays/close.md, tests/close-skill.test.sh, tests/cleanup-skill.test.sh, tests/close-removal.test.sh, docs/plans/2026-11-27-close-177-qc-leftovers-188.md
wiki:       none
exclusive:  none
sequenced:  none
```

---

## Round 2 — after QC round 1

> Appended to `docs/plans/2026-11-27-close-177-qc-leftovers-188.md`. Tasks 1-6 above are done and stay as written. The banner, Global Constraints and proof-of-done rule at the top of the plan bind these tasks too.

**Why:** QC round 1 found that Task 4's F5 sentence is untrue (its F1, blocking). The plan took "`gh` still runs" from the issue; in fact `assignee_label` calls `scripts/github.sh`, which reads `.repo.owner` at load (`scripts/github.sh:27`) through `jq empty` on the config (`lib/env.sh:86`) and stops with `config.json: invalid JSON` before any `gh` call. Reproduced with no `jq` on `PATH` and a logging `gh` stub: exit 1, no `gh` call.

**In this round (engineer's answer, dossier Q8):** QC's F1, F2, F3 and F5. **Not in this round:** F4 (pins for the docs sentences); it stays in `qc.md` for `/codeo:triage`.

**Global Constraints, added:** still wording only — no script is edited. All three tasks stay inside the footprint; no new file. Documentation moved: `docs/home-checkout.md` and `skills/cleanup/SKILL.md` again, nothing else.

### Task 7: `docs/home-checkout.md` — the assignee lookup stops before `gh`; "when that file is missing"

**Files:**
- Modify: `docs/home-checkout.md:9` (QC F1) and `:132` (QC F2)

- [ ] **Step 1: Run the failing checks.** `grep -c 'gh` still runs' docs/home-checkout.md` → `1`; `grep -c 'with neither, the scripts' docs/home-checkout.md` → `1`.
- [ ] **Step 2: F1.** Replace the parenthetical "(`gh` still runs, but parsing its answer needs `jq`)" with "(its `github.sh` call reads `.codeo/config.json` with `jq` and stops before it reaches `gh`)". Keep "getting nothing from the assignee lookup" in front of it.
- [ ] **Step 3: F2.** In the tracker sentence at `:132`, replace "with neither, the scripts print" with "when that file is missing, the scripts print". The rest of the sentence stays: one `note:` line, record nothing, ask nothing, the question above included. (`CODEO_TRACK` set to a missing path does not fall back to the script beside it, `.sbx/codeo-sandbox.sh:22`.)
- [ ] **Step 4: Proof.** Both greps print `0`; `grep -c 'stops before it reaches' docs/home-checkout.md` and `grep -c 'when that file is missing, the scripts' docs/home-checkout.md` each print `1`. Then `bash tests/run.sh` ends `all cases passed`.
- [ ] **Step 5: Commit** `git add docs/home-checkout.md` · `docs: home-checkout says the assignee lookup stops before gh without jq (#188)`.

### Task 8: `skills/cleanup/SKILL.md` — a validly named branch; the pin reads step 4

**Files:**
- Modify: `skills/cleanup/SKILL.md:84` (QC F3)
- Test: `tests/cleanup-skill.test.sh:27` and after `:38` (QC F5, second half)

- [ ] **Step 1: Write the failing pin.** Delete the line-27 check (`grep -qF 'while origin still holds' "$skill"`), which reads the whole file. After the two existing `<<<"$step4"` checks (`:37-38`), add, in the same style: `grep -qF 'while origin still holds a validly named' <<<"$step4" || check_fail "step 4 does not say a failed-name issue gets a leftover line only while origin holds a validly named branch"`.
- [ ] **Step 2: Run it to see it fail.** `bash tests/run.sh cleanup-skill` — Expected: `=== FAIL: cleanup-skill.test.sh` with that message.
- [ ] **Step 3: Reword the parenthesis** to "(an issue that failed only `name` gets one while origin still holds a validly named `codeo-live/<N>/*` branch)". `scripts/cleanup.sh:115-123` counts only names of letters, digits, `.`, `_` and `-`.
- [ ] **Step 4: Proof.** `bash tests/run.sh` ends `all cases passed`.
- [ ] **Step 5: Commit** `git add skills/cleanup/SKILL.md tests/cleanup-skill.test.sh` · `docs: cleanup's leftover line needs a validly named branch; the pin reads step 4 (#188)`.

### Task 9: `CHANGELOG.md` — the bullet carries its issue number

**Files:**
- Modify: `CHANGELOG.md` (`## Unreleased`, the bullet Task 6 added)

- [ ] **Step 1: Run the failing check.** `grep -c '(#188)' CHANGELOG.md` → `0`.
- [ ] **Step 2: End the bullet** the way its neighbours end theirs (`… (#190).`): "… No script changed (#188)." Read the bullet once more against Task 7: it must not say `gh` runs. As written ("described as they behave") it needs no other change.
- [ ] **Step 3: Proof.** The grep prints `1`; `bash tests/run.sh` ends `all cases passed`; `git diff --stat origin/main -- scripts lib hooks .sbx .devcontainer` prints nothing.
- [ ] **Step 4: Commit** `git add CHANGELOG.md` · `docs: the changelog line names its issue (#188)`.

---

## Round 3 — after QC round 3

> Appended to `docs/plans/2026-11-27-close-177-qc-leftovers-188.md`. Tasks 1-9 above are done and stay as written. The banner, Global Constraints and proof-of-done rule at the top of the plan bind these tasks too.

**Why:** QC round 3's F8 (blocking). `docs/home-checkout.md:9` says `live.sh`, without `jq`, publishes the signal "getting nothing from the assignee lookup". That lookup exists only for a hosted web session: `user_label` (`scripts/live.sh:158-165`) calls `assignee_label` only when `$host` is `web`, and the paragraph is about running on the host. Task 7 wrote the sentence from the issue's F5 text and did not carry the issue's own "it matters only for a web session".

**Observed, not inferred.** `user_label` was run from `scripts/live.sh` with `jq` off `PATH` and a logging `gh` stub: with `host=container` the label was the `git config user.name` value; with `host=web` it was `unknown`; `gh` was called 0 times in both. `bash scripts/github.sh user login` printed `codeo: config.json: invalid JSON in …/.codeo/config.json` and exited 1.

**In this round:** QC's F8, and its non-blocking F9 (two parentheticals back to back in the cleanup overlay), a one-phrase change in two files already in the footprint. **Not in this round:** F4, F6 and F7, which stay in `qc.md` for `/codeo:triage` (F4 by the engineer's answer at Q8).

**Global Constraints, added:** still wording only, no script edited; both tasks stay inside the footprint; documentation moved: `docs/home-checkout.md` and the cleanup overlay with its template, nothing else.

### Task 10: `docs/home-checkout.md:9` — who the signal's user is without `jq`

**Files:**
- Modify: `docs/home-checkout.md:9` (QC round 3, F8)

- [ ] **Step 1: Run the failing check.** `grep -c 'getting nothing from the assignee lookup' docs/home-checkout.md` → `1`; `grep -c 'git config user.name' docs/home-checkout.md` → note the number it prints (the page may already name it elsewhere).
- [ ] **Step 2: Reword the end of the bullet.** Replace exactly
  "reading the base branch as empty and getting nothing from the assignee lookup (its `github.sh` call reads `.codeo/config.json` with `jq` and stops before it reaches `gh`)."
  with
  "reading the base branch as empty and taking the signal's user from `git config user.name`: its `github.sh` calls read `.codeo/config.json` with `jq` and stop before they reach `gh`, so the login lookup yields nothing. A hosted web session is the only place `live.sh` asks for the issue's assignee; there, without `jq`, that lookup yields nothing as well and the user reads `unknown`."
  Keep everything before "reading the base branch as empty" as it is, including "`live.sh` publishes the signal without `jq`", which `tests/readme.test.sh:340` pins.
- [ ] **Step 3: Proof.** `grep -c 'getting nothing from the assignee lookup' docs/home-checkout.md` prints `0`; `grep -c 'taking the signal'"'"'s user from' docs/home-checkout.md` prints `1`; `grep -c 'is the only place `live.sh` asks for the issue'"'"'s assignee' docs/home-checkout.md` prints `1`. Then `bash tests/run.sh` ends `all cases passed`.
- [ ] **Step 4: Commit** `git add docs/home-checkout.md` · `docs: home-checkout says where live.sh gets the signal's user without jq (#188)`.

### Task 11: the cleanup overlay — one parenthesis, not two

**Files:**
- Modify: `.codeo/overlays/cleanup.md:12` and `templates/containers/.codeo/overlays/cleanup.md:12`, identically (QC round 3, F9)

- [ ] **Step 1: Run the failing check.** `grep -c 'sits beside it) (otherwise it prints' .codeo/overlays/cleanup.md templates/containers/.codeo/overlays/cleanup.md` → `1` for each file.
- [ ] **Step 2: Join the two parentheticals** in both files: "sits beside it) (otherwise it prints a note: and records nothing, and you mark the row by hand)" becomes "sits beside it; otherwise it prints a note: and records nothing, and you mark the row by hand)". Nothing else on the line changes; the pins `else codeo-track.sh sits beside`, `CODEO_TRACK names it`, `records nothing` in `tests/cleanup-skill.test.sh:112` still match. `close.md` already reads ", and otherwise" and is not touched.
- [ ] **Step 3: Proof.** The Step 1 grep prints `0` for each file and `grep -c 'sits beside it; otherwise it prints' …` prints `1` for each. Then `bash tests/run.sh` ends `all cases passed` (it includes `containers.test.sh`'s overlay-equals-template check and `cleanup-skill`), and `git diff --stat origin/main -- scripts lib hooks .sbx .devcontainer` prints nothing.
- [ ] **Step 4: Commit** the two overlay files · `docs: the cleanup overlay's tracker clause is one parenthesis (#188)`.
