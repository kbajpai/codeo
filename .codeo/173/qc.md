# Issue #173 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/173 |
| Branch | `docs/173-close-161-leftovers-release-checklist` |
| Updated | 2026-11-25 |

## Where this stands

Round 1 is written: the verdict is back to `/codeo:plan`. Two blocking findings, both the plan's: F1 (the corrected v1.0.8 `Shared state:` line is still untrue for one read in `dossier-check.sh`) and F2 (the stop-failure line is printed on a `--force` removal, where it is false). Five non-blocking findings are recorded. Nothing is open.

## Questions

### Q1 — #176 and `.devcontainer/codeo` overlap: proceed, sequence or re-scope?

`overlap.sh 173` printed `176	.devcontainer/codeo` and `176	glob:.devcontainer/codeo`. #176 is on branch `feat/176-support-sbx-issue-sandbox-macos`, assigned to kbajpai, at step `plan` (working). Its plan's footprint names `.devcontainer/codeo`. So far its branch has changed only its plan doc. This branch changes `stop_started` and the `container_check` header comment, about 10 lines in `.devcontainer/codeo:475-482` and `:516-518`.

**Why it matters:** both branches edit one script. Whichever merges second takes the other's change through `sync-main.sh`. A conflict comes only when both touch the same lines.

**Options:** *proceed and coordinate* (recommended: this change is small and done, while #176 has not started its code, so #176 picks it up at its next `sync-main.sh`) · *sequence after #176* · *re-scope*.

**Answer:**
Proceed and coordinate, as recommended. Given in the session on 2026-11-25 ("go with your picks") and recorded here.

### Q2 — #176 and `.devcontainer/README.md` overlap: proceed, sequence or re-scope?

`overlap.sh 173` printed `176	.devcontainer/README.md` and `176	glob:.devcontainer/README.md`. #176 is on branch `feat/176-support-sbx-issue-sandbox-macos`, assigned to kbajpai, at step `plan` (working). Its footprint names `.devcontainer/README.md`. This branch changes two paragraphs and the removal flowchart in the `codeo rm` section, about 6 lines.

**Why it matters:** same as Q1. #176 is about the sbx sandbox on macOS, so its README edits are likely in other sections.

**Options:** *proceed and coordinate* (recommended, as in Q1) · *sequence after #176* · *re-scope*.

**Answer:**
Proceed and coordinate, as recommended. Given in the session on 2026-11-25 ("go with your picks") and recorded here.

### Q3 — #176 and `CHANGELOG.md` overlap: proceed, sequence or re-scope?

`overlap.sh 173` printed `176	CHANGELOG.md` and `176	glob:CHANGELOG.md`. #176 is on branch `feat/176-support-sbx-issue-sandbox-macos`, assigned to kbajpai, at step `plan` (working). Its footprint names `CHANGELOG.md`. This branch adds three bullets under `## Unreleased` and corrects two released entries in place.

**Why it matters:** both branches will add `## Unreleased` bullets after the same line, which is a small textual conflict for whichever merges second.

**Options:** *proceed and coordinate* (recommended: the second to merge resolves it by keeping both bullets) · *sequence after #176* · *re-scope*.

**Answer:**
Proceed and coordinate, as recommended. Given in the session on 2026-11-25 ("go with your picks") and recorded here.

## Notes

Commands this pass ran so far:

- `role.sh --check qc`: exit 0.
- `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`, exit 0.
- `overlap.sh 173`, exit 0:

  ```
  176	.devcontainer/README.md
  176	.devcontainer/codeo
  176	CHANGELOG.md
  176	glob:.devcontainer/README.md
  176	glob:.devcontainer/codeo
  176	glob:CHANGELOG.md
  ```

- `scope.sh origin/main HEAD`: `suite.shell=true`, with the unclassified paths `.claude/hooks/session-start.sh`, `.claude/settings.json`, `.codeo/173/*`, `CHANGELOG.md` and `CONTRIBUTING.md`.
- `overlap.sh --outside 173`: printed nothing, exit 0.
- Overlay sections `invariants-extra` and `wiki-rules`: exit 3 (none). No invariants file, no shared environment, no `wiki` module.

## Outcome

### Round 1 — 2026-11-25

**Scope.** Q1-Q3 (the overlaps with #176 on `.devcontainer/codeo`, `.devcontainer/README.md` and `CHANGELOG.md`) were answered *proceed and coordinate* and are recorded above. `sync-main.sh --abort-on-conflict` printed `sync-main: the branch already contains origin/main` (exit 0; a first attempt printed `the tree is not clean` because the answers were uncommitted, and the answers were committed and the sync run again). `overlap.sh 173` then printed nothing, exit 0; `overlap.sh --outside 173` printed nothing, exit 0. `git diff origin/main...HEAD --stat`: 15 files, 808 insertions, 21 deletions (the code, tests and pages of the plan's footprint, the plan doc and `.codeo/173/`). `scope.sh origin/main HEAD` printed `scope: suite shell needed for unclassified paths:` (`.claude/hooks/session-start.sh`, `.claude/settings.json`, `.codeo/173/*`, `CHANGELOG.md`, `CONTRIBUTING.md`) and `suite.shell=true`. The `invariants-extra` and `wiki-rules` overlay sections do not exist (exit 3); no invariants file, no shared environment, no `wiki` module, so there is no environment block.

**Build.** The `shell` suite's build is `true`: exit 0.

**Suites.** `bash tests/run.sh`, whole, `shell` suite: last line `all cases passed`, exit 0.

**Criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| `docs/release-checklist.md` step 6 says which examples and stubs move to the release being cut, which move to the one before it, and which do not move | met, with F3 | `docs/release-checklist.md` step 6 has the three groups for `README.md` and `tests/install.test.sh`, as the criterion names them; the version strings were checked against `README.md` and `tests/install.test.sh`. It omits `docs/updating.md`, which also carries release-version examples (F3) |
| `CHANGELOG.md:23` says which script stopped counting which heading, matching `dossier-check.sh`, `inflight.sh` and `qc-verdict.sh` at v1.0.7 | not met | The corrected v1.0.8 `Shared state:` line (`CHANGELOG.md:36`) says `dossier-check.sh` never counted `## Outcomes`. `git show v1.0.7:scripts/dossier-check.sh` has `section_range` matching the name or the name plus a space, but `last_round_clear` (line 473-479, behind `finished-qc-clear` at line 821) reads `/^## Outcome/`, so at v1.0.7 `## Outcomes` did count there (F1) |
| The flowchart edges and the paragraph at `.devcontainer/README.md:186-188` hold when `docker ps -a` fails and `codeo` started the container | met | `.devcontainer/README.md` edges 214-216 and the paragraph at 197, read against `container_check` (`.devcontainer/codeo:522-551`): with no listing `started` stays 0, so the container is restarted and read twice and never stopped on a refusal |
| The `CHANGELOG.md` #154 bullet no longer says a refusal stops the container unconditionally | met | `CHANGELOG.md:30` (the v1.0.9 #154 bullet) now says "a container it knows it started" and that one started when `docker ps -a` failed is left running |
| A refusal after a failed `docker stop` either reports it or is documented as leaving the container running; a test pins whichever is chosen | met, with F2 | `.devcontainer/codeo:477-482` (`stop_started` prints the stderr line); `tests/codeo-command.test.sh` `t_rm_reports_a_failed_stop`. The line is also printed on a `--force` removal, where it is false (F2) |
| The hook's behaviour has a `CHANGELOG.md` bullet | met | `CHANGELOG.md:9`, the hosted-session hook bullet under `## Unreleased` |
| The hook's skip check treats `superpowers@*` and a disabled codeo as `install.sh` does, and the hook does not re-run on `clear` or `compact`, or the page says it does | met | `.claude/hooks/session-start.sh:16-23` (`claude plugin list --json`, user scope, `.enabled != false`, `startswith("superpowers@")`); `.claude/settings.json` matcher `startup\|resume\|fork`; `tests/session-start-hook.test.sh` (12 cases) and the matcher assertion in `tests/live-signal.test.sh` |
| The hook comment and the README agree on when `/codeo:*` commands load in a hosted session | met | Neither claims when they load: `grep -n "so /codeo" .claude/hooks/session-start.sh` prints nothing, and `CONTRIBUTING.md` says to start a new session if the commands are not listed, which restates the README's restart sentence |

**Documentation.** The pages the plan names were read against the code: `.devcontainer/README.md` (flowchart and two paragraphs, against `container_check` and `stop_started`), `CONTRIBUTING.md` `## Hosted sessions` (against the hook and `settings.json`), `CHANGELOG.md` (the three `## Unreleased` bullets and the two corrected entries, against the code and the v1.0.7 tag) and `docs/release-checklist.md`. The pages describe the system in the present tense with no issue number except in the changelog's own bullets. Two pages are wrong or incomplete: the v1.0.8 `Shared state:` line (F1) and step 6's list (F3). The flowchart was not rendered (`mmdc` is not installed); the edits are label text inside the existing double quotes.

**Independent review** (`opus`, given the acceptance criteria and the git range only). Quoted in plain text: "Ready to merge? With fixes. Criteria 3 to 8 are met. Criterion 2's correction is still untrue for `dossier-check.sh`'s `finished-qc-clear` read at v1.0.7. Criterion 1's step 6 leaves out `docs/updating.md`. The new stop-failure line is false on `--force` removals." Each of its three Important findings was checked against the code and the tag by this pass before it was classified.

**Findings.**

- **F1 — blocking — `/codeo:plan`'s.** `CHANGELOG.md:36`: the corrected v1.0.8 `Shared state:` line says `scripts/dossier-check.sh` matches `## Outcome` exactly, "where `## Outcomes` never counted and `## Outcome notes` no longer does". At v1.0.7 that holds only for `section_range`; `last_round_clear`, which backs `finished-qc-clear`, used the prefix `/^## Outcome/`, so `## Outcomes` and `## Outcome notes` both counted there and stopped counting at v1.0.8. The code does what the plan said: the plan prescribed this sentence and verified only `section_range`, so the plan was wrong. The sentence must name each read of `dossier-check.sh` separately.
- **F2 — blocking — `/codeo:plan`'s.** `.devcontainer/codeo:477-482` with `container_check` and `cmd_rm` (about line 640): `container_check` calls `stop_started` on every non-zero result whether or not `--force` was given. A stopped container under `--force` whose fetch fails or whose read is dirty, with a failing `docker stop`, prints `codeo: could not stop codeo-<N> again; it is left running`, then `--force: …`, then removes the container. The line is false there, and the `CHANGELOG.md` bullet and the README scope it to a refused `codeo rm`. The code does what the plan said; the plan did not carve out `--force`. The fix needs a guard so the line (and the stop) happen only when the caller will refuse, and a test with `--force` and `stop_fail` asserting the line is absent.
- **F3 — non-blocking — `/codeo:plan`'s.** `docs/release-checklist.md` step 6: it does not name `docs/updating.md`, which holds release-version examples (`release v1.0.9`, `v1.0.8 -> v1.0.9`, the downgrade to `v1.0.8`, the dropped-install lines at `v1.0.8`) that `tests/install.test.sh` checks against the installer. A maintainer who follows step 6 leaves them at the old versions, and the suite fails after the stubs move. The suite catches it, so the harm is a failed run, not a wrong release.
- **F4 — non-blocking — `/codeo:plan`'s.** `.devcontainer/README.md`, the `docker inspect` paragraph (line 201): it mentions the stop-failure line only for a failed `docker inspect`. The code also prints it on a cannot-check or dirty refusal of a container `codeo` started after a successful inspect (the test's first case). One sentence in "A refusal removes nothing and names `codeo rm <N> --force`" would cover it.
- **F5 — non-blocking — `/codeo:implement`'s.** `.claude/hooks/session-start.sh:19` and its header comment ("as install.sh reads it"): the hook accepts any enabled user-scope `superpowers@*` entry, while `install.sh`'s `installed_entry` judges only the first match. With two such entries and the first disabled, the hook skips where `install.sh` would enable the first. Harmless (an enabled one exists), but the comment is not literally true.
- **F6 — non-blocking — `/codeo:implement`'s.** `.devcontainer/codeo:520-521`: the `container_check` header reads "(a stop that fails is reported) (not after a failed restart: …)", two parentheses in a row.
- **F7 — non-blocking — `/codeo:plan`'s.** `docs/release-checklist.md` step 6 and `tests/install.test.sh:335`: the refused input `'v1.0.9;x'` embeds the current release and fits none of the three groups, so a maintainer cannot tell whether it moves.

Not findings: the hook not replacing an older codeo, and installing at user scope when a project already enables codeo, are the old hook's behaviour and outside the issue; whether "start a new session" loads the plugins in a hosted environment is unverified here and is hedged on the page, as Q3 settled.

No finding needs an issue of its own; the `docs/updating.md` gap noted in `implement.md` is F3.

**Verdict: back to `/codeo:plan`.**

## Log

- 2026-11-25 — Q1-Q3 raised (overlaps with #176) · cost: 0m · opus-5-5 232k in + 282k cached / 629 out
- 2026-11-25 — round 1: suite passed, independent review with fixes, verdict back to /codeo:plan (F1, F2 blocking) · cost: 72m · opus-5-5 332k in + 2.5M cached / 20k out · sonnet-5-5 259k in + 2.2M cached / 12k out
