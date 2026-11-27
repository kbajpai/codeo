# Issue #188 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/188 |
| Branch | `docs/188-close-177-qc-leftovers-utc` |
| Updated | 2026-11-27 |

## Where this stands

Round 1 is written: back to `/codeo:plan`. One blocking finding (F1): the F5 sentence in `docs/home-checkout.md:9` says `gh` still runs without `jq`, and it does not. The plan wrote that sentence from the issue's own premise, so it is the plan's. Five non-blocking findings are recorded. Nothing is open.

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

## Log

- 2026-11-27 — Q1-Q2 raised and answered through the question tool; qc round 1: suite passed, build passed, 4 of 6 criteria met, F1 blocking (plan's), F2-F5 non-blocking; back to /codeo:plan · cost: 5m · opus-5-5 270k in + 2.4M cached / 14k out · sonnet-5-5 188k in + 244k cached / 1k out
