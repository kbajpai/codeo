# Issue #188 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/188 |
| Branch | `docs/188-close-177-qc-leftovers-utc` |
| Updated | 2026-11-27 |

## Where this stands

Round 5 is written and the verdict is clear: round 3's F8 and round 4's F10 are fixed, the build and the whole `shell` suite pass on the tree merged with #195, #204, #206 and #211, all six criteria are met, and the independent review found no Critical or Important issue. F4, F6, F7 and the new F11 are non-blocking and recorded for `/codeo:triage`. Nothing is open. Next step: `/codeo:close`.

## Questions

### Q1 — #195: proceed and coordinate on `tests/cleanup-skill.test.sh` and `tests/close-removal.test.sh`?

**Why it matters:** `overlap.sh 188` printed both paths for #195 (branch `feat/195-identify-acting-user-strictly-verify`, assignee kbajpai, step plan). This branch changes one needle in each. *Proceed and coordinate* leaves the change as it is; *sequence after #195* holds it; *re-scope* drops the pin changes.
**Options:** proceed and coordinate (recommended) · sequence after #195 · re-scope.

**Answer:**
Proceed and coordinate. (The engineer, through the question tool, 2026-11-27.)

### Q2 — #204: proceed and coordinate on `tests/cleanup-skill.test.sh` and `tests/close-removal.test.sh`?

**Why it matters:** `overlap.sh 188` printed both paths for #204 (branch `chore/204-fix-codeo-close-opens-pr`, assignee kbajpai, step init). This branch changes one needle in each. *Proceed and coordinate* leaves the change as it is; *sequence after #204* holds it; *re-scope* drops the pin changes.
**Options:** proceed and coordinate (recommended) · sequence after #204 · re-scope.

**Answer:**
Proceed and coordinate. (The engineer, through the question tool, 2026-11-27.)

## Notes

- Step 2 sync: `sync-main: the branch already contains origin/main`. `overlap.sh --outside 188` printed nothing: the branch stays inside its footprint.
- `scope.sh origin/main HEAD` printed `suite.shell=true`, from `scope: suite shell needed for unclassified paths:` for `.codeo/188/{implement,init,issue,plan}.md`, `CHANGELOG.md` and the two `templates/containers/.codeo/overlays/` files. No `deploy=` line: no shared environment is configured, so there is no environment step.
- The project has no invariants file and its overlay has no further QC rules (`invariants-extra` and `wiki-rules` both exit 3), so the documentation check uses the conventions of the existing pages.
- The F5 premise came from the issue and QC round 2 of #177, which both say `assignee_label` "still runs `gh`". The plan inherited it; nothing in the issue's text is edited here.
- Out of scope, not filed: without `jq`, `user_label`'s own `github.sh user login` call fails the same way, so a web session without `CODEO_GITHUB_LOGIN` and without `jq` always reaches `assignee_label`, not only after a failed `GET /user`. Script behaviour, outside this change.
- Round 2, recorded for `/codeo:triage`, not findings of this change: `skills/cleanup/SKILL.md:52` says an issue whose only failed proof is `name` "still gets its `leftover` line (below)", with no condition, where line 46 and the corrected `:84` state it; the line predates this branch and is not in the diff. And without `jq`, `live.sh`'s `github.sh user login` call stops the same way as the assignee lookup, so a web session with no `CODEO_GITHUB_LOGIN` always reads `unknown`; `docs/home-checkout.md:9` names only the assignee lookup. Neither is filed here: the role-check form of filing is the engineer's call in the home checkout.

## Outcome

### Round 1 — 2026-11-27

Sync, overlap (Q1-Q2 answered), scope, build: `scope.sh` printed `suite.shell=true`; the `shell` suite's `build` is `true` and exited 0.

**Suite:** `bash tests/run.sh` exited 0 and printed `all cases passed` (real time about 1m43s).

| Criterion | Verdict | Settled by |
|---|---|---|
| Each of F2-F6 is corrected as the requirement states, or the pull request names it as dismissed with a reason | not met — F5 is corrected in the way the requirement states, but the sentence it produces is untrue (F1) | `docs/home-checkout.md:9` |
| `docs/release-checklist.md` no longer says the UTC date is "the day after" local date | met | `grep -c 'the day after' docs/release-checklist.md` prints `0`; `:91-92` read "can differ by a day from the engineer's local date" |
| `skills/close/SKILL.md` allowlist wording works on the literal `ls-remote` output, and the "per branch" wording agrees with the skip clause | met | `skills/close/SKILL.md:550-553` ("`<sha>`, a tab, then `refs/heads/<branch>`; drop the `refs/heads/` prefix first … per branch that passes"); pinned at `tests/close-skill.test.sh:232-233` |
| The three tracker-condition lines (F4) name `CODEO_TRACK` as well as `codeo-track.sh`, and say nothing is asked without a tracker | met | `.codeo/overlays/cleanup.md:12`, `.codeo/overlays/close.md:11` and their templates (equal after substitution, reviewer diffed all 8); `docs/home-checkout.md:132` ("record nothing, and ask nothing"), true of both scripts: `track_confirm` returns 0 when `track_present` fails (`.sbx/codeo-sandbox.sh:44`, `.devcontainer/codeo-container.sh:63`) |
| `docs/home-checkout.md:9` and `skills/cleanup/SKILL.md:84` match what `live.sh` and `scripts/cleanup.sh` do | not met — `skills/cleanup/SKILL.md:84` matches `scripts/cleanup.sh:13`; `docs/home-checkout.md:9` does not match `live.sh` (F1) | `scripts/live.sh:153-154`, `scripts/github.sh:27`, `lib/env.sh:86`; reproduced below |
| `bash tests/run.sh` ends `all cases passed` | met | this round's run, above |

**Findings**

- **F1 — blocking, `/codeo:plan`'s.** `docs/home-checkout.md:9` says that, without `jq`, `live.sh` gets "nothing from the assignee lookup (`gh` still runs, but parsing its answer needs `jq`)", and the `CHANGELOG.md` Unreleased line says the lookup is "described as they behave". `gh` does not run. `assignee_label` calls `bash scripts/github.sh issue view`, and `github.sh` reads `.repo.owner` through `codeo_cfg_required` at load (`scripts/github.sh:27`), which runs `jq empty` on the config (`lib/env.sh:86`) and stops with `config.json: invalid JSON` first. Reproduced: with a `PATH` holding no `jq` and a `gh` stub that logs its calls, `bash scripts/github.sh issue view 188` printed `codeo: config.json: invalid JSON in …/.codeo/config.json`, exited 1, and the stub was never called. The implementer wrote what the plan said; the plan took "still runs `gh`" from the issue's F5, which took it from #177's QC round 2. Fix: keep "getting nothing from the assignee lookup" and say why truthfully, for example "(its `github.sh` call reads `.codeo/config.json` with `jq` and stops before it reaches `gh`)"; adjust the `CHANGELOG.md` line if it repeats the claim.
- **F2 — non-blocking, `/codeo:plan`'s.** `docs/home-checkout.md:132`: "with neither" reads as if the scripts try both. When `CODEO_TRACK` names a path that does not exist, they do not fall back to the `codeo-track.sh` beside them (`.sbx/codeo-sandbox.sh:22-24`). Say "when that file is missing".
- **F3 — non-blocking, `/codeo:plan`'s.** `skills/cleanup/SKILL.md:84`: "while origin still holds its `codeo-live/<N>/*` branches" is slightly broad, because `leftover_proof` counts only names matching `^codeo-live/<N>/[A-Za-z0-9._-]+$` (`scripts/cleanup.sh:115-123`). Say "with a valid name" if exactness is wanted.
- **F4 — non-blocking, `/codeo:plan`'s.** Three changed sentences have no test pin: `docs/release-checklist.md:92`, `docs/home-checkout.md:9` and `docs/home-checkout.md:132`. A revert of any of them passes the suite; the other fixes are pinned.
- **F5 — non-blocking, `/codeo:implement`'s.** The `CHANGELOG.md` bullet under `## Unreleased` has no `(#188)` suffix, though the neighbouring bullets end with theirs (#190, #192). Also deferred by `implement.md` along with a pin that greps all of `skills/cleanup/SKILL.md` rather than step 4 (`tests/cleanup-skill.test.sh`); both minor.

**Independent review** (opus, `QC review:`, given the criteria and no account of the change): plain-text verdict "With fixes"; one Important (F1, which I reproduced above), four Minor (F2-F5). It confirmed F2, F3, F4 and F6 against the scripts, all 8 overlays equal to their templates, and that the changed pins match their text and would catch a revert. Its declined-to-judge list: the sandbox's `note:` wording when `CODEO_TRACK` names a missing file, whether `live.sh` should work without `jq`, wording outside the diff, and style; each is script behaviour or outside the change.

**Footprint:** `overlap.sh --outside 188` printed nothing. **Documentation check:** every page the diff touches describes the system in the present tense with no issue number and no "now", apart from F1.

**Verdict: back to `/codeo:plan`.** Correct the F5 sentence in the plan's Task 4 (and the changelog bullet in Task 6) to say that `github.sh` stops on its config read before `gh` runs; fold in F2 and F3 if you want them, then `/codeo:implement` redoes those two tasks.


### Round 2 — 2026-11-27

Round 1's send-back was answered by `/codeo:plan` round 2 and `/codeo:implement` round 2 (`44f7c5b`, `19e36d8`, `92e7d92`). The whole pass ran again from step 0.

**Sync, overlap, scope, build.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 188` printed nothing (Q1-Q2 from round 1 stand). `scope.sh origin/main HEAD` printed `suite.shell=true` (its `unclassified paths` list: `.codeo/188/{implement,init,issue,plan,qc}.md`, `CHANGELOG.md` and the two `templates/containers/.codeo/overlays/` files); it printed no `deploy=` line, and no shared environment is configured, so there is no environment step. The `shell` suite's `build` is `true` and exited 0.

**Suite.** `bash tests/run.sh` exited 0 and printed `all cases passed` (real time 3m56s, the machine being busy).

| Criterion | Verdict | Settled by |
|---|---|---|
| Each of F2-F6 is corrected as the requirement states, or the pull request names it as dismissed with a reason | met | F2 `docs/release-checklist.md:91-92`; F3 `skills/close/SKILL.md:550-553`; F4 overlays, templates and `docs/home-checkout.md:132`; F5 `docs/home-checkout.md:9` (now true: with `jq` off `PATH` and a logging `gh` stub, `bash scripts/github.sh issue view 188` printed `codeo: config.json: invalid JSON in …/.codeo/config.json` and the stub was called 0 times); F6 `skills/cleanup/SKILL.md:84`; the comma: `grep -c 'on record, is listed' CHANGELOG.md` prints `0`. F5's premise in the issue ("`gh` still runs") was wrong about the code, so the sentence follows the code, and the pull request says so |
| `docs/release-checklist.md` no longer says the UTC date is "the day after" local date | met | `grep -c 'the day after' docs/release-checklist.md` prints `0`; `grep -c 'differ by a day from the'` prints `1` |
| `skills/close/SKILL.md` allowlist wording works on the literal `ls-remote` output, and the "per branch" wording agrees with the skip clause | met | `skills/close/SKILL.md:550-553` (`<sha>`, a tab, then `refs/heads/<branch>`; "drop the `refs/heads/` prefix first"; "per branch that passes"); `per branch it printed` is gone (`grep -c` prints `0`); pinned at `tests/close-skill.test.sh:232-233` |
| The three tracker-condition lines (F4) name `CODEO_TRACK` as well as `codeo-track.sh`, and say nothing is asked without a tracker | met | `.codeo/overlays/cleanup.md:12`, `.codeo/overlays/close.md:11` and their templates carry "CODEO_TRACK names it, else codeo-track.sh sits beside it" (`grep -c` prints `1` in each of the four; both overlays are byte-equal to their templates after the `@…@` substitution); `docs/home-checkout.md:132` says "when that file is missing, the scripts print one `note:` line, record nothing, and ask nothing, the question above included", true of both scripts (`track_confirm` returns 0 when `track_present` fails, `.sbx/codeo-sandbox.sh:44`, `.devcontainer/codeo-container.sh:63`). The two overlay lines describe `end`, which asks nothing in any case; the "nothing is asked" half applies to the `home-checkout.md` sentence, as the engineer settled in `plan.md` Q1 |
| `docs/home-checkout.md:9` and `skills/cleanup/SKILL.md:84` match what `live.sh` and `scripts/cleanup.sh` do | met | `docs/home-checkout.md:9` against `scripts/live.sh:153-155`, `scripts/github.sh:27`, `lib/env.sh:86` and the experiment above; `skills/cleanup/SKILL.md:84` against `scripts/cleanup.sh:115-123` (a `leftover` line only for names matching `^codeo-live/<N>/[A-Za-z0-9._-]+$`) |
| `bash tests/run.sh` ends `all cases passed` | met | this round's run, above |

**Findings**

- F1 (blocking in round 1) — fixed by `44f7c5b`: `docs/home-checkout.md:9` now says the assignee lookup stops at `github.sh`'s `jq` read of the config, before `gh`; the experiment above confirms it.
- F2 (non-blocking in round 1) — fixed by `44f7c5b`: "when that file is missing".
- F3 (non-blocking in round 1) — fixed by `19e36d8`: "a validly named `codeo-live/<N>/*` branch".
- F5 (non-blocking in round 1) — fixed by `19e36d8` and `92e7d92`: the pin reads step 4, and the changelog bullet ends `(#188)`.
- F4 (non-blocking in round 1) — still open, by the engineer's answer (`plan.md` Q8): the three docs sentences have no test pin. Left for `/codeo:triage`.
- F6 — non-blocking, `/codeo:plan`'s. `skills/cleanup/SKILL.md:84`: "a validly named" is not defined anywhere in the skill; the name rule (letters, digits, `.`, `_`, `-` after `codeo-live/<N>/`) lives in `scripts/cleanup.sh:115-123`. The sentence is true; naming the rule would make it checkable.
- F7 — non-blocking, `/codeo:plan`'s. `skills/close/SKILL.md:550`: "drop the `refs/heads/` prefix first" follows "Each line it prints is `<sha>`, a tab, then `refs/heads/<branch>`", so a very literal reader could strip the prefix from a line that starts with the `<sha>`. Saying "take the part after the tab" would close it.

**Independent review** (opus, `QC review:`, given the criteria, told the issue's own wording may be wrong about the code, and given no account of the change): plain-text verdict "Ready to merge: Yes"; no Critical, no Important, four Minor. It reproduced the no-`jq` experiment, confirmed all six criteria's texts against the scripts, all overlays equal to their templates, and that every changed pin is a substring of the new text and would fail on a revert; it ran `cleanup-skill`, `close-removal` and `close-skill` and each ended `all cases passed`. Its Minors are F6 and F7 above, plus two recorded in Notes. Its declined-to-judge list (script `note:` wording when `CODEO_TRACK` names a missing file, behaviour changes to `live.sh`, wording outside the diff, line numbers the issue cites) is outside this change.

**Footprint:** `overlap.sh --outside 188` printed nothing. **Documentation check:** every page and skill sentence the diff touches describes the system in the present tense; none carries an issue number or "now" (`grep` over the added lines prints `0`); the one `(#188)` is the changelog bullet, where it belongs. No page the diff should have touched was left alone.

**Verdict: clear — forward to `/codeo:close`.**


### Round 3 — 2026-11-27

This is the full pass again after `/codeo:close` round 2 sent the branch back: pull request #209 conflicted with `main` in `CHANGELOG.md` after #195 merged, and `/codeo:implement` round 3 merged `origin/main` (`887beb2`) and kept both bullets.

**Sync, overlap, scope, build.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 188` printed nothing. `scope.sh origin/main HEAD` printed `suite.shell=true` (its `unclassified paths` list: the `.codeo/188/` dossiers, `CHANGELOG.md` and the two `templates/containers/.codeo/overlays/` files) and no `deploy=` line; no shared environment is configured, so there is no environment step. The `shell` suite's `build` is `true` and exited 0. `overlap.sh --outside 188` printed nothing.

**Also changed on `main`** (from #195, `c7505a9`, re-checked against this branch's sentences): `scripts/live.sh` (`user_label` no longer reads `CODEO_GITHUB_LOGIN`; `assignee_label` unchanged), `scripts/github.sh`, `lib/env.sh`, `skills/close/SKILL.md` and `tests/close-skill.test.sh` (the step 17 wording and its two pins are intact), `docs/handoff.md`, `docs/skills.md`, `README.md` and the `skills/{init,plan,implement,qc}/SKILL.md` files, none of which holds a sentence this branch changed.

**Suite.** `bash tests/run.sh` exited 0 and printed `all cases passed` (real time 4m4s, the machine being busy).

| Criterion | Verdict | Settled by |
|---|---|---|
| Each of F2-F6 is corrected as the requirement states, or the pull request names it as dismissed with a reason | not met — F2, F3, F4 and F6 are corrected, but F5's sentence still misplaces the lookup (F8) | `docs/release-checklist.md:74-75`; `skills/close/SKILL.md:556-559`; the overlays and `docs/home-checkout.md:132`; `skills/cleanup/SKILL.md:87`; the comma: `grep -c 'on record, is listed' CHANGELOG.md` prints `0`; F5 `docs/home-checkout.md:9` against `scripts/live.sh:158-165` |
| `docs/release-checklist.md` no longer says the UTC date is "the day after" local date | met | `grep -c 'the day after' docs/release-checklist.md` prints `0`; `grep -c 'differ by a day from the'` prints `1` |
| `skills/close/SKILL.md` allowlist wording works on the literal `ls-remote` output, and the "per branch" wording agrees with the skip clause | met | `skills/close/SKILL.md:556-559` ("drop the `refs/heads/` prefix first", "per branch that passes"); `per branch it printed` is gone (`grep -c` prints `0`); pinned at `tests/close-skill.test.sh:232-233` |
| The three tracker-condition lines (F4) name `CODEO_TRACK` as well as `codeo-track.sh`, and say nothing is asked without a tracker | met | the four overlay files each carry "CODEO_TRACK names it, else codeo-track.sh sits beside it" (`grep -c` prints `1` in each); both overlays are byte-equal to their templates after the `@…@` substitution; `docs/home-checkout.md:132` says "when that file is missing, the scripts print one `note:` line, record nothing, and ask nothing", true of both scripts (`track_confirm` returns 0 when `track_present` fails); the overlay lines describe `end`, which asks nothing, as the engineer settled in `plan.md` Q1 |
| `docs/home-checkout.md:9` and `skills/cleanup/SKILL.md:84` match what `live.sh` and `scripts/cleanup.sh` do | not met — `skills/cleanup/SKILL.md` matches `scripts/cleanup.sh:115-123`; `docs/home-checkout.md:9` does not match `live.sh` on the host (F8) | `scripts/live.sh:158-165` (read below); `scripts/cleanup.sh:115-123` |
| `bash tests/run.sh` ends `all cases passed` | met | this round's run, above |

**Findings**

- F1 (blocking in round 1) — fixed by `44f7c5b`: the sentence no longer says `gh` runs without `jq`. With `jq` off `PATH` and a logging `gh` stub, `bash scripts/github.sh issue view 188` printed `codeo: config.json: invalid JSON in …/.codeo/config.json` and the stub was called 0 times, as the sentence now says.
- F8 — blocking, `/codeo:plan`'s. `docs/home-checkout.md:9` says `live.sh`, without `jq`, publishes the signal "getting nothing from the assignee lookup (its `github.sh` call reads `.codeo/config.json` with `jq` and stops before it reaches `gh`)". The parenthetical is true, but the paragraph is under "To run it on the host you need", and on the host that lookup is never made: `user_label` (`scripts/live.sh:158-165`) calls `assignee_label` only when `$host` is `web` (`[[ -n $name || $host != web ]] || name=$(assignee_label)`, line 161), and a lock's host is `web` only for a hosted session (`CLAUDE_CODE_REMOTE=true`, `scripts/live.sh:176`). On a `local` or `container` host without `jq`, `github.sh user login` fails the same way, nothing asks for the assignee, and the label comes from `git config user.name` (line 162). So the sentence tells a host reader a lookup runs and yields nothing, and leaves out what actually happens; the code does what Task 7 told it to, because the issue's F5 wording ("`assignee_label` still runs … the lookup yields nothing") carried the same gap and its own last sentence ("it matters only for a web session") was not carried into the page. What the sentence must say instead: without `jq`, the signal's user comes from `git config user.name` on the host; only a hosted web session asks for the assignee, and there, with `jq` missing, the lookup stops at `github.sh`'s config read and the label reads `unknown`.
- F9 — non-blocking, `/codeo:plan`'s. `.codeo/overlays/cleanup.md:12` and its template read "only when it finds the tracker (CODEO_TRACK names it, else codeo-track.sh sits beside it) (otherwise it prints a note: …)", two parentheticals back to back. Not wrong, and the pins still match; a "; otherwise" would read better.
- F4 (non-blocking in round 1) — still open, by the engineer's answer (`plan.md` Q8): the F2, F4 and F5 docs sentences have no test pin (`tests/readme.test.sh` already guards `home-checkout.md`). F6 and F7 (non-blocking in round 2), the cleanup parenthesis not naming the name rule and step 17's "prefix" wording, are also still open. All three are for `/codeo:triage`.

**Independent review** (opus, `QC review:`, given the criteria and told the issue's own wording may be wrong about the code): plain-text verdict "With fixes"; no Critical, one Important (F8), two Minor (F4's missing pins and F9). It re-read #195's changes to `scripts/live.sh`, `scripts/github.sh` and `skills/close/SKILL.md` rather than assuming, confirmed F2, F3, F4 and F6 against the scripts, all 8 overlays equal to their templates, that every changed pin matches its text and would fail on a revert (the three pin files each ended `all cases passed`), and that the `CHANGELOG.md` resolution against `origin/main` differs only by the one added bullet and the comma fix, with all of main's Unreleased entries intact. I confirmed the last point myself: main's three Unreleased bullets are all present and its header lines are identical. Its declined-to-judge list (the scripts' `note:` text when `CODEO_TRACK` names a missing file, `${CODEO_TRACK:-…}` treating an empty value as unset, the unchanged rest of `home-checkout.md:9`, the order of bullets in Unreleased) is outside this change.

**Footprint:** `overlap.sh --outside 188` printed nothing. **Documentation check:** every sentence the diff adds to a page or skill is in the present tense with no issue number and no "now" (`grep` over the added lines, with `docs/plans` left out, prints `0`); the one `(#188)` is the changelog bullet.

**Verdict: back to `/codeo:plan`.** Correct the F5 sentence at `docs/home-checkout.md:9` in a new plan round (its Task 7 text) so it says what `live.sh` does on the host and in a hosted session as F8 describes, and fold in F9 if you want it; then `/codeo:implement` redoes that one task and `/codeo:close` brings the pull request up to date.


### Round 4 — 2026-11-27

This is the full pass after `/codeo:plan` round 3 and `/codeo:implement` round 4 (`55eb82e`, `17fef72`). It stopped at step 2.

**Sync.** `sync-main.sh --abort-on-conflict` printed `sync-main: conflict: CHANGELOG.md` and exited 2; the merge was aborted and the tree is as it was (`git status --porcelain` prints nothing). `main` moved after round 3's merge: `9b11696 ci: run the test files in parallel and cancel superseded pull request runs (#211)`, `e8fb549 fix: archive the dossier before /codeo:close opens the pull request (#204) (#210)` and `3b1279b fix: print runnable cleanup commands, record removals, and stop intake commits deleting files (#206) (#212)`. `git merge-tree --write-tree --name-only origin/main HEAD` names one conflicting file:

- `CHANGELOG.md` — changed on `main` by `e8fb549` (#204) and `3b1279b` (#206), which both add bullets under `## Unreleased` next to this branch's.

`main` also changed four more files this branch edits. git merges them without a conflict, but the sentences and pins this branch changed in them must be re-read on the merged tree:

- `skills/cleanup/SKILL.md` — `3b1279b` (#206) rewrote the cleanup skill. On `main`, step 4 still reads "(an issue that failed only `name` gets one)", at about line 96, where this branch's F6 wording ("gets one while origin still holds a validly named `codeo-live/<N>/*` branch") must survive.
- `tests/cleanup-skill.test.sh` — on `main`, the `step4=` line is at line 35, and the tracker needles at line 130 still read `'when codeo-track.sh sits beside'`. This branch changes that needle to `'else codeo-track.sh sits beside'` and adds `'CODEO_TRACK names it'` and a `step4` pin.
- `skills/close/SKILL.md` and `tests/close-skill.test.sh` — on `main`, `e8fb549` (#204) reordered the close skill. Step 17's pins sit at about line 266 on `main` and still name step 17. This branch's "drop the `refs/heads/` prefix first" and "per branch that passes", with their two pins, must land in the step that holds that paragraph after the merge.

`overlap.sh 188` printed nothing: #204 and #206 are merged, not in flight. The rest of the pass did not run on a tree that a merge would replace. `scope.sh origin/main HEAD` printed `suite.shell=true`, and the `shell` suite's `build` (`true`) exited 0 on the unmerged tree, but the suite was not run.

| Criterion | Verdict | Settled by |
|---|---|---|
| Each of F2-F6 is corrected as the requirement states, or the pull request names it as dismissed with a reason | not yet checkable — pass stopped at step 2 | — |
| `docs/release-checklist.md` no longer says the UTC date is "the day after" local date | not yet checkable — pass stopped at step 2 | — |
| `skills/close/SKILL.md` allowlist wording works on the literal `ls-remote` output, and the "per branch" wording agrees with the skip clause | not yet checkable — pass stopped at step 2 | — |
| The three tracker-condition lines (F4) name `CODEO_TRACK` as well as `codeo-track.sh`, and say nothing is asked without a tracker | not yet checkable — pass stopped at step 2 | — |
| `docs/home-checkout.md:9` and `skills/cleanup/SKILL.md:84` match what `live.sh` and `scripts/cleanup.sh` do | not yet checkable — pass stopped at step 2 | — |
| `bash tests/run.sh` ends `all cases passed` | not yet checkable — pass stopped at step 2 | — |

**Findings**

- F8 (blocking in round 3) — fixed by `55eb82e`, by the change's own account. It is not judged here: the pass stopped before step 5, and the next round judges it on the merged tree.
- F10 — blocking, `/codeo:implement`'s: the branch conflicts with `main` in `CHANGELOG.md`. Merge `origin/main`, keep every side's `## Unreleased` bullet, and re-read the four files above on the merged tree.

**Verdict: back to `/codeo:implement`.** Merge `origin/main` (with #204, #206 and #211), resolve `CHANGELOG.md` by keeping every `## Unreleased` entry, and confirm that this branch's F3 wording and pins in `skills/close/SKILL.md` and `tests/close-skill.test.sh`, and its F4 and F6 wording and pins in `skills/cleanup/SKILL.md` and `tests/cleanup-skill.test.sh`, survive the merge where #204 and #206 rewrote those files. Then run `/codeo:qc` again.


### Round 5 — 2026-11-27

This is the full pass after `/codeo:implement` round 5 merged `origin/main` (with #204, #206 and #211) into the branch (`fa2fccd`) and resolved the `CHANGELOG.md` conflict that stopped round 4.

**Sync, overlap, scope, build.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`, so there are no `also changed on` lines this round (round 5's merge was `fa2fccd`). `overlap.sh 188` printed nothing. `scope.sh origin/main HEAD` printed `suite.shell=true` (its `unclassified paths` list: the `.codeo/188/` dossiers, `CHANGELOG.md` and the two `templates/containers/.codeo/overlays/` files) and no `deploy=` line; no shared environment is configured, so there is no environment step. The `shell` suite's `build` is `true` and exited 0. `overlap.sh --outside 188` printed nothing. `git diff origin/main...HEAD --stat` outside the dossiers and plan: 12 files, 18 insertions, 14 deletions.

**Suite.** `bash tests/run.sh` exited 0 and printed `all cases passed` (real time 1m6s).

| Criterion | Verdict | Settled by |
|---|---|---|
| Each of F2-F6 is corrected as the requirement states, or the pull request names it as dismissed with a reason | met | F2 `docs/release-checklist.md` (`grep -c 'differ by a day from the'` prints `1`); F3 `skills/close/SKILL.md` step 17; F4 the overlays and `docs/home-checkout.md:132`; F5 `docs/home-checkout.md:9`; F6 `skills/cleanup/SKILL.md:96`; the comma (`grep -c 'on record, is listed' CHANGELOG.md` prints `0`). F5 follows the code where the issue's premise ("`gh` still runs") was wrong about it, which the pull request body says |
| `docs/release-checklist.md` no longer says the UTC date is "the day after" local date | met | `grep -c 'the day after' docs/release-checklist.md` prints `0` |
| `skills/close/SKILL.md` allowlist wording works on the literal `ls-remote` output, and the "per branch" wording agrees with the skip clause | met | step 17 says each line is `<sha>`, a tab, then `refs/heads/<branch>`, to "drop the `refs/heads/` prefix first", and to print one delete "per branch that passes" (`grep -c` prints `1` for each phrase; `per branch it printed` prints `0`); pinned at `tests/close-skill.test.sh:266-267` |
| The three tracker-condition lines (F4) name `CODEO_TRACK` as well as `codeo-track.sh`, and say nothing is asked without a tracker | met | "CODEO_TRACK names it, else codeo-track.sh sits beside it" is in all four overlay files (`grep -c` prints `1` in each) and both overlays are byte-equal to their templates after the `@…@` substitution; `docs/home-checkout.md:132` says "when that file is missing, the scripts print one `note:` line, record nothing, and ask nothing, the question above included", true of both scripts (`track_confirm` returns 0 when `track_present` fails). The overlay lines describe `end`, which asks nothing, as the engineer settled in `plan.md` Q1 |
| `docs/home-checkout.md:9` and `skills/cleanup/SKILL.md:84` match what `live.sh` and `scripts/cleanup.sh` do | met | `docs/home-checkout.md:9` against `scripts/live.sh:158-165`: running `user_label` from `scripts/live.sh` with `jq` off `PATH` and a logging `gh` stub gave `Test Person` (the `git config user.name` value) for `host=container` and `host=local`, `unknown` for `host=web`, and `gh` was called 0 times, which is what the sentence says; `skills/cleanup/SKILL.md:96` against `scripts/cleanup.sh:173-181` (`leftover_proof` counts only names matching `^codeo-live/<N>/[A-Za-z0-9._-]+$`) |
| `bash tests/run.sh` ends `all cases passed` | met | this round's run, above |

**Findings**

- F8 (blocking in round 3) — fixed by `55eb82e`: `docs/home-checkout.md:9` now says where the signal's user comes from on the host and that only a hosted web session asks for the assignee; the experiment above confirms both host kinds and the hosted one.
- F9 (non-blocking in round 3) — fixed by `17fef72`: the cleanup overlay's tracker clause is one parenthesis, and its pins still match.
- F10 (blocking in round 4) — fixed by `fa2fccd`: `main`'s `## Unreleased` bullets all survive (compared by their first 60 characters, none missing; the section's header lines are identical to `main`), and `git diff origin/main -- CHANGELOG.md` shows only this branch's bullet and the removed comma; this branch's wording and pins survive in the files #204 and #206 rewrote.
- F4 (non-blocking in round 1) — still open, by the engineer's answer (`plan.md` Q8): the F2, F4 and F5 docs sentences have no test pin (`tests/readme.test.sh` pins only "`live.sh` publishes the signal without `jq`").
- F6 and F7 (non-blocking in round 2) — still open: the cleanup parenthesis does not spell out the name rule, and step 17's "drop the `refs/heads/` prefix" could say "take the field after the tab and drop its prefix".
- F11 — non-blocking, `/codeo:plan`'s. `docs/home-checkout.md:132`: "The tracker is `CODEO_TRACK` when set" is slightly loose, since the scripts use `${CODEO_TRACK:-…}` and a set-but-empty value falls back to the default; "when set and non-empty" would be exact.

**Independent review** (opus, `QC review:`, given the criteria, told the issue's own wording may be wrong about the code, and given no account of the change): plain-text verdict "Ready to merge: Yes"; no Critical, no Important, four Minor (F7's wording, F4's missing pins, F11, and the pre-existing note below). It reproduced the `user_label` experiment itself on a local and a web host and with `jq` on `PATH` (the stub login, one `gh` call), confirmed F2, F3, F4 and F6 against `scripts/live.sh`, `scripts/github.sh`, `scripts/cleanup.sh`, `.sbx/codeo-sandbox.sh` and `.devcontainer/codeo-container.sh`, all eight overlays equal to their templates, every new pin matching its text and failing on a revert, and the `CHANGELOG.md` diff against `origin/main`; it ran `cleanup-skill`, `close-removal` and `close-skill` and each exited 0. Its declined-to-judge list (the scripts' `note:` text when `CODEO_TRACK` names a missing file, whether `live.sh` should fall back in a web session without `jq`, the unchanged parts of `home-checkout.md:9`, the alone-`leftover` case #206 added, the order of the new bullet) is outside this change.

**Recorded for `/codeo:triage`, not findings of this change:** `docs/skills.md:257` (written by #206, not in this diff) says an issue "that failed only `name` still gets its leftover branch delete" without the condition that origin still holds a validly named branch, the same imprecision F6 fixed in the cleanup skill; `skills/cleanup/SKILL.md:52` carries the same unconditional wording (noted in round 2); and without `jq`, a hosted session with no `CODEO_GITHUB_LOGIN` has its user read `unknown` because `github.sh user login` also stops at the config read (the new `home-checkout.md:9` sentence now says so).

**Footprint:** `overlap.sh --outside 188` printed nothing. **Documentation check:** every sentence the diff adds to a page or skill is in the present tense with no issue number and no "now" (`grep` over the added lines, with `docs/plans` left out, prints `0`); the one `(#188)` is the changelog bullet, where it belongs. No page the diff should have touched was left alone.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-27 — Q1-Q2 raised and answered through the question tool; qc round 1: suite passed, build passed, 4 of 6 criteria met, F1 blocking (plan's), F2-F5 non-blocking; back to /codeo:plan · cost: 5m · opus-5-5 270k in + 2.4M cached / 14k out · sonnet-5-5 188k in + 244k cached / 1k out
- 2026-11-27 — qc round 2: suite passed, build passed, 6 of 6 criteria met, F1 fixed, review no Critical or Important, F6-F7 non-blocking; clear, forward to /codeo:close · cost: 5m · opus-5-5 330k in + 2M cached / 11k out · sonnet-5-5 28k in + 1.5M cached / 1k out
- 2026-11-27 — qc round 3 (full pass after close.md round 2's conflict send-back): suite passed, build passed, 4 of 6 criteria met, F1 fixed, F8 blocking (plan's), F9 non-blocking; back to /codeo:plan · cost: 5m · opus-5-5 446k in + 2.7M cached / 14k out · sonnet-5-5 32k in + 2.4M cached / 4k out
- 2026-11-27 — qc round 4: stopped at step 2 (sync-main: conflict: CHANGELOG.md, after #204, #206 and #211 merged); criteria not yet checkable; back to /codeo:implement · cost: 1m · opus-5-5 457k in + 989k cached / 2k out
- 2026-11-27 — qc round 5 (full pass on the tree merged with #195, #204, #206 and #211): suite passed, build passed, 6 of 6 criteria met, F8 and F10 fixed, review no Critical or Important, F11 non-blocking; clear, forward to /codeo:close · cost: 2m · opus-5-5 583k in + 2.6M cached / 13k out · sonnet-5-5 25k in + 1.6M cached / 966 out
