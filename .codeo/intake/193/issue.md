# Issue #193 — issue

## Draft (review gate)

**Title:** Close the #179 and #182 QC leftovers: lock-entry and README wording, three test guards, doctor-skip wording and the changelog
**Type:** none (user-owned repo). **Labels:** documentation, priority: low (follow-up nobody is waiting on).

### Description

`/codeo:qc` left twelve non-blocking findings on #179 and #182 with no issue number. Each is a small inaccuracy or weakness in README or docs wording, or in a test guard. Nothing is false or broken at runtime. This issue closes them in one pass, as #185 and #188 do for earlier issues.

### Motivation / Context

`/codeo:triage` collected them on 2026-11-26 and the engineer chose to file them as a single issue. They are listed below with where they surfaced.

### Key Requirements

From `.codeo/done/179/qc.md`:

- **H1, I2** — The README lock entry says "the branch and `origin/<branch>` have diverged" and "two issues' dossiers". `scripts/lock.sh:121` prints `$current and origin/$dossier_branch have diverged`, where `$current` is the branch HEAD is on, and `find_issue` (`scripts/lock.sh:43-52`) counts any number of `init.md` files naming the branch, archives included. The README wording should match.
- **H2** — `README.md:27` says "the workflow finishes on that second run". That is incomplete after a review send-back, or when the engineer accepts `/codeo:close`'s background watch (`skills/close/SKILL.md:307-317`).
- **H3** — The `lock-entry` assertion `grep -qF '/codeo:init #<N>'` in `tests/readme.test.sh` already held before the change, so it cannot fail on the "init fixes it" group.
- **G4** — The `setup-steps` check misses tab-indented and lazy-continuation lines.
- **I1** — The README *Updating* superpowers sentence (`README.md:549`) lacks the "restart open sessions" line that `docs/updating.md` has.
- **J1** — The `pipefail-safe` guard (`tests/readme.test.sh:328`, regex `[|] *grep -[a-zA-Z]*q`) is narrower than its header. It misses a split `producer |` / `grep -q x` on the next line, `| grep -F -q x`, `| grep --quiet x`, `| head -1` and `| grep -m1`. It also flags correct code: `a || grep -q x f`, and a `| grep -q` inside a quoted string or comment.
- **J2** — `docs/home-checkout.md:49` says "on any other exit it reports what the check printed", which includes exit 0. It should say "on any exit other than 0 and 1".
- **J3** — `tests/readme.test.sh:221`: `sed 's/\. /.\n/g'` relies on GNU sed. BSD sed on macOS does not turn `\n` into a newline, so the lock-entry "reconcile by hand" / "diverged" check can pass vacuously there.

From `.codeo/done/182/qc.md`:

- **F1** — `README.md` lines 173 and 466 say an unusable config skips `ruleset`. `scripts/doctor.sh` lines 48, 83, 101 and 171 show `codename`, `gh-scopes`, `board` and `suites` also print "skipped: config is unusable".
- **F2** — `tests/install.test.sh` `t_latest_installed_without_version` (lines 518-523) still uses v1.0.9 as the latest release.
- **F3** — The #182 changelog bullet omits the `/codeo:qc` round-start change and the `/codeo:doctor` summary rewrite. It is incomplete, not untrue; the Release notes carry the same text.

### Acceptance Criteria

- [ ] Each finding above is fixed, or recorded in the dossier with the reason it is not.
- [ ] The README lock entry's wording agrees with what `scripts/lock.sh` prints and counts.
- [ ] `README.md:27` is true after a review send-back and with the background watch.
- [ ] The README skip wording for an unusable config names every check `scripts/doctor.sh` skips.
- [ ] `docs/home-checkout.md:49` reads "on any exit other than 0 and 1".
- [ ] The `pipefail-safe` guard catches the forms in J1 and no longer flags the correct code listed there.
- [ ] The lock-entry check does not depend on GNU sed's `\n`.
- [ ] `t_latest_installed_without_version` no longer treats v1.0.9 as the latest release.
- [ ] The test suite passes.

### Out of Scope

- Changing what `scripts/lock.sh` prints or counts; the docs follow the script.
- Findings from other issues' QC; #185 covers #173, #176 and #170, and #188 covers #177.

### Reference

- `.codeo/done/179/qc.md` (rounds 3-5, H1-H3, I1-I3, J1-J3, G4) and `.codeo/done/182/qc.md` (round 1, F1-F3), on `main`.
- Surfaced by `/codeo:triage`, run 2026-11-26.

## Log

2026-11-26 — drafted from /codeo:triage; engineer asked to consolidate; filed as one issue · cost: unavailable
