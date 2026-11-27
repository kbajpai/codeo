# Issue #188 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/188 |
| Branch | `docs/188-close-177-qc-leftovers-utc` |
| Updated | 2026-11-27 |

## Where this stands

Round 2 is written and the verdict is clear: round 1's F1 is fixed in `44f7c5b`, the build and the whole `shell` suite pass, all six criteria are met, and the independent review found no Critical or Important issue. Two new non-blocking findings (F6, F7) and round 1's F4 are recorded for `/codeo:triage`. Nothing is open. Next step: `/codeo:close`.

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

## Log

- 2026-11-27 — Q1-Q2 raised and answered through the question tool; qc round 1: suite passed, build passed, 4 of 6 criteria met, F1 blocking (plan's), F2-F5 non-blocking; back to /codeo:plan · cost: 5m · opus-5-5 270k in + 2.4M cached / 14k out · sonnet-5-5 188k in + 244k cached / 1k out
- 2026-11-27 — qc round 2: suite passed, build passed, 6 of 6 criteria met, F1 fixed, review no Critical or Important, F6-F7 non-blocking; clear, forward to /codeo:close · cost: 5m · opus-5-5 330k in + 2M cached / 11k out · sonnet-5-5 28k in + 1.5M cached / 1k out
