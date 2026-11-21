# Issue #149 — issue

## Questions

None: the findings came from /codeo:triage Q1 and Q2 (engineer chose *file it* for both, then asked for one issue).

## Draft

Title: Close the non-blocking findings #143 and #144 left: `codeo rm` messages and ordering, a relative CODEO_HOME, skill wording and test pins
Labels: bug. Type: none (user-owned repo).

### Description

Close the non-blocking findings `/codeo:qc` left on #143 (the `codeo` host command's `rm`) and on #144 (the `## Outcome` heading and init closing-block change). None loses unsaved work. For #143: a `--force` hint printed when the sandbox is already gone, a relative `CODEO_HOME` that makes `codeo rm <N>` of a sandbox fail, `docker restart` ending shells before the mount check, and README and help text that say less or more than the code does. For #144: a sentence in two skills that reads as waiting on the wrong thing, a test commit that claims more than it pins, and a few wording nits.

### Motivation / Context

#143 (PR #148) and #144 (PR #147) merged with QC round 2 clear. Their `qc.md` files record #143 F12-F16 (with F6 and F9 parked from round 1) and #144 F3-F5 as non-blocking, and no issue was filed. Each is small; together they leave `codeo rm` printing advice that does not apply and failing on an uncommon setup, two READMEs that disagree with the code, and skill text with a misleading pronoun.

### Key Requirements

**From #143**
- **F13:** with `--force`, `codeo rm <N>` does not print `to remove it anyway, discarding whatever it holds: sbx rm --force codeo-<N>` after the script reports the sandbox already removed (`removed codeo-<N>, but could not set aside its refs …`, `.sbx/codeo-sandbox.sh:412`, `:416`) or absent (`no sandbox codeo-<N>`).
- **F14:** a relative `CODEO_HOME` works for `codeo rm <N>` of a sandbox, or is refused with one clear message; today it fails with `mktemp: failed to create file via template '…/rel/rel/.rm-err.XXXXXX'`, exit 1. A test covers it.
- **F6:** when `rm` will refuse without `--force`, `docker restart` has not already ended the engineer's shells and agents.
- **F12:** `.devcontainer/README.md` (around line 202) claims the script's own `codeo-sandbox: ` message always says what to do; it does not for `no clone … nothing removed` (`.sbx/codeo-sandbox.sh:381`) or `could not fetch origin` / `pull-request heads` (`:386`). Either the script names a remedy or the README stops claiming one.
- **F15:** the README's "stops with one line when `~/codeo` is a git checkout and `CODEO_HOME` is unset" says which commands it covers; `codeo rm <N>` of a container never reads the home directory and goes ahead.
- **F16:** `.sbx/README.md` and the help text say a failed listing warns on stderr and exits 1, as `.devcontainer/README.md` does.
- **F9:** the *Removing a finished container* flowchart shows the `--force` branches, the restart failure and the no-container case, or is reworded as a partial picture.

**From #144**
- **F4:** in `skills/implement/SKILL.md:89-92` and `skills/close/SKILL.md:220-224` the new sentences come after "The step stops until it is answered" (as in `skills/qc/SKILL.md`), so "it" is not read as the skip warning.
- **F3:** a case in `tests/outcome-heading.test.sh` commits a `plan.md` with the heading varied and a `### Round 2`, so `qc-verdict.sh:134` is pinned there, or the commit's claim that it pins every reader is corrected (`tests/qc-verdict.test.sh` already guards the line).
- **F5 (nits):** `skills/init/SKILL.md` says "end the turn … do not hand off" for the lock-taken TODO case as well as the no-lock case; the stop rule also names a non-zero exit with neither the `cannot diff` nor the `cannot resolve` line; `inflight_send_back` separates the trailing-space direction of `inflight.sh:209`. Each is done or left out in writing.

### Acceptance Criteria
- [ ] With `--force`, none of the three sandbox outputs named under F13 is followed by the `sbx rm --force` hint; a test fails if it comes back.
- [ ] `CODEO_HOME=rel codeo rm <N> --sandbox` either completes or exits with one clear message, and a test covers a relative `CODEO_HOME`.
- [ ] A `codeo rm <N>` that refuses without `--force` does not run `docker restart` first (or the README says it does, and why).
- [ ] No README or help sentence about the script's own message, the home-directory stop or the failed-listing exit contradicts the code (F12, F15, F16); the flowchart matches the prose or says it is partial.
- [ ] The two skill sentences under #144 F4 sit after "The step stops until it is answered".
- [ ] `qc-verdict.sh:134` is pinned by a case in `tests/outcome-heading.test.sh`, or the claim is corrected; each #144 F5 item is done or dismissed in writing.
- [ ] `bash tests/run.sh` ends `all cases passed`.

### Out of Scope

- Temp files left by an interrupted download or clone, a stale `.lookup.git.part`, and the other round 1 minors in `.codeo/done/143/implement.md`; nothing reads them.
- Any change to what `rm` refuses or removes beyond the messages and ordering above.
- #144's F2 (`docs/skills.md` outside the plan's footprint), already answered in its `implement.md`.

### Reference

- `.codeo/done/143/qc.md` on `main`: round 2 F12-F16, round 1 F6 and F9. `.codeo/done/144/qc.md`: round 2 F3-F5.
- `.devcontainer/codeo` (`cmd_rm`, around lines 507-566), `.devcontainer/README.md`, `.sbx/README.md`, `.sbx/codeo-sandbox.sh`, `skills/implement/SKILL.md`, `skills/close/SKILL.md`, `skills/init/SKILL.md`, `tests/outcome-heading.test.sh`.
- Surfaced by `/codeo:triage` run 12 (`.codeo/intake/triage/2026-11-21-2.md`, Q1 and Q2, consolidated at the engineer's request). #143 (PR #148), #144 (PR #147).
