# Issue #154 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/154 |
| Branch | `fix/close-149-145-leftovers-codeo` |
| Updated | 2026-11-22 |

## Where this stands

Initialized: branch `fix/close-149-145-leftovers-codeo` cut off `origin/main` at `ee0c02069817ffffde4a884c420ded16b76ee4f2`, and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/154 — Close the #149 and #145 leftovers: `codeo rm` remedies and wording, a refused `rm` that leaves a container running, and triage and inflight text and test pins |
| State | open · labels `bug` |
| Branch | `fix/close-149-145-leftovers-codeo` off `main` at `ee0c020` |
| Board | Ready → In progress |

**Problem.** `/codeo:qc` passed #149 and #145 with non-blocking findings that have no issue. They are a README remedy that cannot work for a missing clone or `no sandbox` refusal (F12), a refusal naming `end <N> --force`, which a `codeo` user cannot type (F13), a refused `codeo rm` that leaves a stopped container running when `docker inspect` fails (F7), README, CHANGELOG, comment and flowchart lines that say more or less than the code does (F14, F16, F17, F18, #145 F1, F3), and test pins that pass whether or not the thing they name changes (F15, #145 F2).

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] For `no sandbox codeo-<N>` and a missing clone, the README states a remedy that works (or says there is none to run), and the `end <N> --force` refusal names a command a `codeo` user can type, or the README says it cannot be typed as it stands.
- [ ] F7 is reproduced (a test or a recorded run) and a refused `codeo rm` with `docker inspect` failing and no `--force` leaves a stopped container stopped; or the reproduction shows it does not happen and the issue records that.
- [ ] The flowchart's removal-failure edges, the `--force` hint's conditions (including no `sbx` installed), the home-directory list (including `open` of a container) and the CHANGELOG's `CODEO_HOME` sentence match the code.
- [ ] `must_precede` in both skill tests pins both sentences (the `overlap: skipping …` sentence cannot move before "The step stops until it is answered" unseen), and a mutation of each shows the test fails.
- [ ] `skills/triage/SKILL.md` names step 1's branch bullet for the `pr list-for-branch` lookup; the `inflight.sh` comments name the check that exits 0 or 4 with no output; the #29 case has a tip commit date newer than the dossier's `Updated` row and fails when the wrapper stops applying.
- [ ] The full `bash tests/run.sh` passes.

**Out of scope.** #149's F2, F3-F6 and F8-F11 (already fixed or recorded as plan decisions); #145's F4-and-later items and #102 F3 (`docs/skills.md:34`); changing what the scripts' own messages say beyond what F13 needs.

**Open at intake.** None.

## Log

- 2026-11-22 — initialized: branch fix/close-149-145-leftovers-codeo off main at ee0c020 · cost: 0m · sonnet-5-5 17k in + 575k cached / 3k out
