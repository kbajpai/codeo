# Issue #149 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/149 |
| Branch | `fix/close-non-blocking-findings-143` |
| Updated | 2026-11-21 |

## Where this stands

Initialized: branch `fix/close-non-blocking-findings-143` cut off `origin/main` at `56598d3c7a5c83e357a5f8218f85050cc06568c8` and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/149 — Close the non-blocking findings #143 and #144 left: `codeo rm` messages and ordering, a relative CODEO_HOME, skill wording and test pins |
| State | open · labels `bug` |
| Branch | `fix/close-non-blocking-findings-143` off `main` at `56598d3` |
| Board | Ready → In progress |

**Problem.** #143 and #144 merged with QC clear and left non-blocking findings unfiled. In `codeo rm`: a `--force` hint printed when the sandbox is already gone (F13), a relative `CODEO_HOME` that breaks `rm` of a sandbox (F14), `docker restart` before the mount check (F6), and README and help text that disagree with the code (F12, F15, F16, F9). From #144: "it" in two skills reads as the skip warning (F4), a test commit claims to pin every `## Outcome` reader but does not pin `qc-verdict.sh:134` (F3), and a few wording nits (F5).

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] With `--force`, none of the three sandbox outputs named under F13 is followed by the `sbx rm --force` hint; a test fails if it comes back.
- [ ] `CODEO_HOME=rel codeo rm <N> --sandbox` either completes or exits with one clear message, and a test covers a relative `CODEO_HOME`.
- [ ] A `codeo rm <N>` that refuses without `--force` does not run `docker restart` first (or the README says it does, and why).
- [ ] No README or help sentence about the script's own message, the home-directory stop or the failed-listing exit contradicts the code (F12, F15, F16); the flowchart matches the prose or says it is partial.
- [ ] The two skill sentences under #144 F4 sit after "The step stops until it is answered".
- [ ] `qc-verdict.sh:134` is pinned by a case in `tests/outcome-heading.test.sh`, or the claim is corrected; each #144 F5 item is done or dismissed in writing.
- [ ] `bash tests/run.sh` ends `all cases passed`.

**Out of scope.** Temp files left by an interrupted download or clone, a stale `.lookup.git.part`, and the other round 1 minors in `.codeo/done/143/implement.md`; any change to what `rm` refuses or removes beyond the messages and ordering above; #144's F2 (`docs/skills.md` outside the plan's footprint).

**Open at intake.** Nothing the issue leaves unresolved. Note: #145 is in flight (plan step) and touches `skills/triage`, `skills/issue`, `docs/handoff.md`, `docs/skills.md` and `CHANGELOG.md`; this issue's `CHANGELOG.md` entry may overlap, so `/codeo:plan` runs `overlap.sh` before settling its footprint.

## Log
- 2026-11-21 — initialized: branch fix/close-non-blocking-findings-143 off main at 56598d3 · cost: 1m · sonnet-5-5 20k in + 734k cached / 4k out
