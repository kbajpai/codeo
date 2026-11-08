# Issue #41 — issue

Filed from triage 2026-11-08 Q7 (`.codeo/intake/triage/2026-11-08.md`).

## Questions

### Q1 — Approve the draft as written?
**Answer:** approved as recommended.

## Draft

**Title:** Correct `docs/skills.md` for `doctor` and `qc`, and tighten the skills coverage guard

**Type:** none · **Labels:** documentation

### Description
QC of #34 recorded non-blocking inaccuracies in `docs/skills.md` and small defects in its coverage guard:
- `doctor`: the Reads list omits `lib/extension-points.tsv`, the installed-plugins file and the PATH checks, and omits the `ci.requiredChecks` fallback to `tests` and `qc-verdict`.
- `qc`: "its own dossier commits and nothing else" omits the step-2 sync merge commit that `qc`'s Non-goals allow.
- The guard counts fenced lines inside an Extension points part, its missing/extra output order is nondeterministic, and one regex leaves the skill name unescaped.

### Motivation / Context
The page overstates what `doctor` and `qc` read and write; the guard can miscount and print in unstable order.

### Key Requirements
- The `doctor` and `qc` entries match what those skills read and write.
- The guard ignores fenced lines in an Extension points part, prints missing/extra skills in a stable order, and escapes the skill name wherever it is used in a regex.

### Acceptance Criteria
- [ ] `docs/skills.md` `doctor` Reads lists the extension-points file, installed-plugins file, PATH checks and the `ci.requiredChecks` fallback.
- [ ] `docs/skills.md` `qc` mentions the sync merge commit.
- [ ] A test shows fenced lines in an Extension points part are not counted.
- [ ] The guard's output order is identical across runs.
- [ ] A skill name containing regex metacharacters is matched literally.

### Out of Scope
Re-describing the other skills; anything in the skills themselves.

### Reference
Triage 2026-11-08 Q7; qc.md for #34 (F2–F5); `docs/skills.md`; PR #37.
