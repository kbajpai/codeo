# Issue new-190-192-leftovers — issue

## Where this stands

Triage run 12 (Q1 and Q2) asked to file the #192 guard gaps and the #190 fixes. The engineer then said "Try to consolidate issues", so both go into one issue, as #193 did for #179 and #182. The draft is below and waits for approval. No question is open.

## Questions

### Q1 — Which findings does the consolidated issue take, and what stays out?

**What:** In: #192 F15-F19 (and F5/F13 as an open question); #190 N1-N5, K2-K8, L2-L9, M2-M6 as listed in `.codeo/done/190/qc.md`. Out: #190's promised design work (triage Q3, deferred).

**Options:** approve as drafted · change the scope

**Answer:**

## Draft

**Title:** Close the #190 and #192 QC leftovers: home-checkout guard bypasses, wizard rerun and requirement gaps, and doc slips

**Issue Type:** none (the repository has no Issue Types). **Labels:** `bug`. **Priority** (`issue.priority` is on): `priority: medium`, because the effect is limited (a guard that an engineer must evade on purpose, and a rerun with a workaround) and no committed work depends on it.

### Description
Collect the non-blocking findings `/codeo:qc` left on #190 (container and sandbox setup, PR #202) and #192 (home-checkout guard, PR #203) so they are fixed or ruled out rather than staying in two archived dossiers.

### Motivation / Context
`.codeo/done/192/qc.md` Notes and `.codeo/done/190/qc.md` / `implement.md` (rounds 6-8) name these as "left for `/codeo:triage`". Triage run 12 found no issue carrying them. Two guard bypasses are reproduced, so the guard's page says "always refused" for commands it allows.

### Key Requirements
Home-checkout guard (#192):
- `git commit --am` (git accepts it as `--amend`) is refused in a home clone, as `--amend` and `--ame` already are (F15).
- A quoted `git -C` or `cd` target holding a space, `~` or `$VAR` is judged, or the page lists it as unseen (F16).
- The staged-set check sees a rename's source as well as its destination (F17).
- Writes the guard neither refuses nor lists (`git stage`, `update-index`, `update-ref`, `notes`, `sparse-checkout`, `checkout -- <path>`, and the rest F18 names) are refused or listed on the page.
- The per-call cost the reviewer measured (three `jq` runs per Bash call; `normalize_cmd` for any command containing the letters `git`) is reduced, or accepted in writing (F19).
- Open question for the engineer: whether `git clean -fdx` and `git branch -f` belong in the guard (round 1 F5, round 2 F13); until decided the page keeps saying they are allowed.

Setup wizard and container templates (#190):
- A rerun uses the kept config's `codename` as the default and does not fail or ask when the repository name gives no codename (N1, M2, K2, K7, L9).
- A codename change after adoption is reported: either doctor flags seeds still on the old name, or the `codename` row and `docs/container-templates.md` say to re-seed (N2).
- `perl` is listed as a host requirement, or the render no longer needs it (N3).
- A refusal comes before any write: a kept config with an invalid `codename`, a non-object `repo`, or `baseBranch: TODO-set-me` does not get the pin or codename written first (K3, L8, J7).
- `containers.sh --force` does not write through a symlink at a managed path (K8).
- Wording: README step 2 on `codename` and `plugin` (N4), the Dockerfile seed's `examples/csharp-angular` path (N5), the README sample's host requirements (M3), the `codeo update` sentence (M4), the `codeo-track.sh` row (M5), the temporary-path refresh hint under `curl | bash` (M6), doctor's containers entry causes and pin message (L2-L4, K4), and the wizard-note and managed-script header wording (K5, K6).

### Acceptance Criteria
- [ ] `git commit --am -m x` in a home clone with only `.codeo/` staged is refused, with a test.
- [ ] A quoted `-C` or `cd` target with a space in the home path is refused from an issue checkout, or appears in the page's not-seen list, with a test.
- [ ] A rename into `.codeo/` that removes a tracked source file is refused, with a test.
- [ ] Every command F18 names is refused or on the page's list.
- [ ] A rerun of the wizard on a repository whose name gives no codename succeeds using the kept config's codename.
- [ ] After a codename change, doctor or the docs say the seeds must be re-seeded.
- [ ] `perl` is on the requirements list, or `scripts/containers.sh` renders without it.
- [ ] With an invalid kept `codename`, a non-object `repo`, or `baseBranch: TODO-set-me`, the wizard and `setup.sh --containers` refuse before writing the pin or codename.
- [ ] `containers.sh --force` leaves a symlink's target untouched.
- [ ] Each wording slip listed above is corrected, or the issue says why it was dropped.
- [ ] The full suite passes.

### Out of Scope
- #190's promised design work: one `codeo` command per machine, a project's own toolchain in the sbx sandbox, `sort -V` before macOS 13, private repositories, a per-project command name, and pinning the rendering plugin's own version (deferred in triage run 12).
- Whether `git clean -fdx` and `git branch -f` belong in the guard, until the engineer decides.
- F14 (`flock` missing on stock macOS), which predates #190.

### Reference
- `.codeo/done/192/qc.md` (Notes; rounds 1-3 F3-F19) and `.codeo/done/190/qc.md` (rounds 4-8: J, K, L, M, N findings) on `origin/main`
- `.codeo/done/190/implement.md` rounds 6-8, "Left for `/codeo:triage`"
- PRs #202 and #203; issues #190, #192; the same pattern as #193

## Outcome

Pending approval.

## Log

2026-11-27 — draft written from triage run 12 Q1 and Q2, consolidated into one issue at the engineer's request
