# Issue — issue

## Questions

None: the finding and its scope came from /codeo:triage Q1 (engineer chose *file it*).

## Draft

Title: `codeo rm`: close the non-blocking findings #143 left (stale --force hint, relative CODEO_HOME, README and help wording)
Labels: bug. Type: none (user-owned repo).

### Description

Close the non-blocking findings `/codeo:qc` left on #143 (the `codeo` host command's `rm` leftovers), none of which loses unsaved work: a `--force` hint printed when the sandbox is already gone, a relative `CODEO_HOME` that makes `codeo rm <N>` of a sandbox fail, `docker restart` ending shells before the mount check, and README and help text that say less or more than the code does.

### Motivation / Context

#143 (PR #148) merged with QC round 2 clear. Its `qc.md` records F12-F16, and parked F6 and F9 from round 1, as non-blocking and filed no issue. Each is small, but together they leave `codeo rm` printing advice that does not apply and failing on an uncommon setup, and two READMEs that disagree with the code.

### Key Requirements

- **F13:** with `--force`, `codeo rm <N>` does not print `to remove it anyway, discarding whatever it holds: sbx rm --force codeo-<N>` after the script reports the sandbox already removed (`removed codeo-<N>, but could not set aside its refs …`, `.sbx/codeo-sandbox.sh:412`, `:416`) or absent (`no sandbox codeo-<N>`).
- **F14:** a relative `CODEO_HOME` works for `codeo rm <N>` of a sandbox, or is refused with a clear one-line message; today it fails with `mktemp: failed to create file via template '…/rel/rel/.rm-err.XXXXXX'`, exit 1. A test covers it.
- **F6:** when `rm` will refuse without `--force`, `docker restart` has not already ended the engineer's shells and agents.
- **F12:** `.devcontainer/README.md` (around line 202) says only what is true of the script's own `codeo-sandbox: ` messages: it names a remedy for `die_unreadable` and the no-refs refusal, and not for `no clone … nothing removed` (`.sbx/codeo-sandbox.sh:381`) or `could not fetch origin` / `pull-request heads` (`:386`). Either the script names a remedy for those or the README stops claiming one.
- **F15:** the README's "stops with one line when `~/codeo` is a git checkout and `CODEO_HOME` is unset" says which commands it applies to; `codeo rm <N>` of a container does not read the home directory and goes ahead.
- **F16:** `.sbx/README.md` and the help text say that a failed listing warns on stderr and exits 1, as `.devcontainer/README.md` does.
- **F9:** the *Removing a finished container* flowchart shows the `--force` branches, the restart failure and the no-container case, or is reworded as a partial picture.

### Acceptance Criteria
- [ ] With `--force`, none of the three sandbox outputs named under F13 is followed by the `sbx rm --force` hint; a test fails if it comes back.
- [ ] `CODEO_HOME=rel codeo rm <N> --sandbox` either completes or exits with one clear message, and a test covers a relative `CODEO_HOME`.
- [ ] A `codeo rm <N>` that refuses without `--force` does not run `docker restart` first (or the README says it does and why).
- [ ] No README sentence about the script's own message, the home-directory stop, or the failed-listing exit contradicts what the code does for F12, F15 and F16.
- [ ] The flowchart matches the prose, or says it is partial.
- [ ] `bash tests/run.sh` ends `all cases passed`.

### Out of Scope

- Temp files left by an interrupted download or clone, a stale `.lookup.git.part`, and the other round 1 minors recorded in `implement.md`; nothing reads them.
- Any change to what `rm` refuses or removes beyond the messages and ordering above.

### Reference

- `.codeo/done/143/qc.md` on `main`: round 2 F12-F16, round 1 F6 and F9.
- `.devcontainer/codeo` (`cmd_rm`, around lines 507-566), `.devcontainer/README.md`, `.sbx/README.md`, `.sbx/codeo-sandbox.sh`.
- Surfaced by `/codeo:triage` run 12 (`.codeo/intake/triage/2026-11-21-2.md`, Q1). #143, PR #148.
