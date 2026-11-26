# Issue #200 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/200 |
| Branch | none |
| Updated | 2026-11-26 |

## Where this stands

Filed as #200.

## Problem as restated

Multi-user safety gap found by a read-only audit of the whole repository (scripts, skills, containers, repo policy); details in the draft below. Parent tracker: #194.

## Questions

None open. The engineer chose to file all twelve groups, then asked to merge them into fewer issues.

## Draft

**Title:** Detect and report codeo version skew between engineers and the repository state

**Type:** none (user-owned repository). **Labels:** enhancement, priority label as filed.

#### Description
Detect and report version skew between engineers' codeo installs and the repository state they share.

#### Motivation / Context
Unknown config keys are silently ignored, so a misspelt guard key does nothing; the dossier does not record the codeo version that wrote it; only the config schema is checked, not the installed plugin version against `plugin.ref`; dossier regexes can change between versions (D10). `install.sh` installs the highest release tag and ignores `plugin.ref`, `doctor.sh` does not compare the installed plugin to the pin, and host scripts refresh only on a manual `codeo update` (C7). Mixed versions fail quietly (for example "malformed row, left untouched, nothing recorded").

#### Key Requirements
- The dossier and lock record the codeo version that wrote them; a reader older than the writer says so.
- `doctor` compares the installed plugin to `plugin.ref` and reports a mismatch.
- Unknown keys in `.codeo/config.json` are reported by `doctor`.
- A malformed dossier or tracker row is reported, not skipped silently.

#### Acceptance Criteria
- [ ] An older codeo reading a newer dossier prints one `codeo:` line.
- [ ] `doctor` fails on a plugin/pin mismatch and on an unknown config key.
- [ ] Tests cover each case.

#### Out of Scope
Automatic upgrades.

#### Reference
Parent #194. Audit findings D10, C7.
