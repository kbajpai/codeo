# Issue #154 — issue

Called from `/codeo:triage` (run 15, 2026-11-21, Q1 and Q2): the engineer answered *file it* for both and asked to consolidate them into one issue. Problem as understood: #149 (PR #153) and #145 (PR #150) merged with non-blocking QC findings recorded for triage in their archived dossiers (`.codeo/done/149/qc.md`, `.codeo/done/145/qc.md`); none has an issue. No open issue covers them (`issue search` found only #146, the release).

Re-checked against `origin/main` (aa135d5) before drafting: F12, F13, F14, F15, F17, F18 (#149) and F1, F3 (#145) are all still present as described. F16 is partly present: `.sbx/README.md:78` says the hint "is printed when `sbx ls` cannot list" but neither README says it also prints when no `sbx` program is installed. #145 F2 (test date ordering) I have not re-read in `tests/inflight.test.sh`; `/codeo:plan` does that.

## Questions

1. **Answered: keep it in.** Is F7 (a refused `rm` leaves a stopped container started) in this issue or its own?** It is the only behaviour defect here: with `docker inspect` failing and no `--force`, the refusal is known before the check, yet a stopped container is started, fetched and read, then left running (`qc.md` F7, "pre-existing", never reproduced). Everything else is wording or a test pin. I drafted it in, as one acceptance criterion that starts with reproducing it. Options: *keep it in* · *its own issue* · *drop it*.

## Draft

**Title:** Close the #149 and #145 leftovers: `codeo rm` remedies and wording, a refused `rm` that leaves a container running, and triage and inflight text and test pins

**Labels:** `bug` (no Issue Types exist). **Type:** none.

### Description

`/codeo:qc` passed #149 (`codeo rm` messages and ordering) and #145 (priority-setting, `claim.sh` and triage/inflight wording) with non-blocking findings that were recorded for triage and have no issue. This issue closes them: a README that sends a user to a remedy that cannot work, a refusal that names a command a `codeo` user cannot type, one case where a refused `codeo rm` leaves a stopped container running, and wording and test pins that say more than they check.

### Motivation / Context

- **#149 F12:** `.devcontainer/README.md:217` says the refusals for `no sandbox codeo-<N>` and a missing clone "name no command: the remedy is to fix what failed and run it again". For a missing clone (`.sbx/codeo-sandbox.sh`, which dies before `--force` is read) running it again fails the same way; the only way out is `sbx rm --force codeo-<N>`.
- **#149 F13:** the one refusal `--force` passes (no branches, `.sbx/codeo-sandbox.sh:390`) names `end <N> --force`, which a `codeo` user cannot type; `codeo rm <N>` adds no `codeo rm <N> --force` line after it.
- **#149 F7 (pre-existing):** with `docker inspect` failing and no `--force`, the refusal is known before the check, yet a stopped container is started, fetched and read, then left running because `rc` is 0 and `stop_started` does not run.
- **#149 F14:** the flowchart edge `G -- "docker rm -f or volume rm failed"` (`.devcontainer/README.md:211`) is unconditional; the code errors on a failed `docker volume rm` only when the volume still exists, and with `--force` a container already gone is no error.
- **#149 F15:** `must_precede` in `tests/close-skill.test.sh:443` and `tests/implement-skill.test.sh:115` pins only the first of the two sentences after "The step stops until it is answered"; the second could move back before it and both tests would pass.
- **#149 F16:** both READMEs say the `--force` hint prints when `sbx ls` "cannot list"; it also prints when no `sbx` program is installed.
- **#149 F17:** the README's list of what never reads the home directory names `rm` of a container; `open` of a container also goes ahead and fails with "is a container".
- **#149 F18:** the `CHANGELOG.md` entry says `codeo rm` makes a relative `CODEO_HOME` absolute; `main` does it for every command.
- **#145 F1:** `skills/triage/SKILL.md:318` says "the state step 2 read with `pr list-for-branch`". Top-level step 2 is "Drop what is already decided" and reads no pull requests; the lookup is in step 1's branch bullet.
- **#145 F2:** `tests/inflight.test.sh` (the #29 case): the tip commit date is older than the dossier's `Updated` row, so the expected line reads the same whether the tip is skipped or read.
- **#145 F3:** the `scripts/inflight.sh` comments (header line 25 and above `waits_of`, line 241) list what falls through as "a spent stash or abandon, or a live one whose `claim.sh --stash-live` check failed", which omits a check that exits 0 or 4 and prints nothing.

### Key Requirements

- The remedy a README or message names for each refusal works for that refusal, and every command a message names is one the user can type.
- A refused `codeo rm` leaves the container in the state it found it in.
- Each README sentence, flowchart edge, CHANGELOG line, test label and comment listed above says what the code does, no more and no less.
- A test pin fails when the thing it names changes (F2, F15).
- Backward compatibility: no change to what `codeo rm` removes or refuses, other than F7's leaving the container as it was.

### Acceptance Criteria
- [ ] For `no sandbox codeo-<N>` and a missing clone, the README states a remedy that works (or says there is none to run), and the `end <N> --force` refusal names a command a `codeo` user can type, or the README says it cannot be typed as it stands.
- [ ] F7 is reproduced (a test or a recorded run) and a refused `codeo rm` with `docker inspect` failing and no `--force` leaves a stopped container stopped; or the reproduction shows it does not happen and the issue records that.
- [ ] The flowchart's removal-failure edges, the `--force` hint's conditions (including no `sbx` installed), the home-directory list (including `open` of a container) and the CHANGELOG's `CODEO_HOME` sentence match the code.
- [ ] `must_precede` in both skill tests pins both sentences (the `overlap: skipping …` sentence cannot move before "The step stops until it is answered" unseen), and a mutation of each shows the test fails.
- [ ] `skills/triage/SKILL.md` names step 1's branch bullet for the `pr list-for-branch` lookup; the `inflight.sh` comments name the check that exits 0 or 4 with no output; the #29 case has a tip commit date newer than the dossier's `Updated` row and fails when the wrapper stops applying.
- [ ] The full `bash tests/run.sh` passes.

### Out of Scope

- #149's F2, F3-F6 and F8-F11: already fixed or recorded as plan decisions (Q3 and Q4 answered by the engineer).
- #145's F4-and-later items, if any, and #102 F3 (`docs/skills.md:34`), already listed out of scope there.
- Changing what the scripts' own messages say beyond what F13 needs; Q4 of #149 kept them.

### Reference

- `.codeo/done/149/qc.md` (round 3, F7, F12-F18) and `.codeo/done/145/qc.md` (F1-F3) on `main`.
- PR #153 (#149), PR #150 (#145); triage run 15, `.codeo/intake/triage/2026-11-21-5.md`, Q1 and Q2.
- `.devcontainer/README.md`, `.sbx/README.md`, `.sbx/codeo-sandbox.sh`, `.devcontainer/codeo`, `skills/triage/SKILL.md`, `scripts/inflight.sh`, `tests/inflight.test.sh`, `tests/close-skill.test.sh`, `tests/implement-skill.test.sh`.

## Outcome

Filed as #154 (https://github.com/kbajpai/codeo/issues/154), label `bug`.

## Log

2026-11-21 — Q1 answered (keep F7 in), approved, filed as #154
