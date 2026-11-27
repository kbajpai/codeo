# Init — #204

| | |
|---|---|
| Issue | #204 |
| Step | init |

## Where this stands

Approved. Branch `chore/204-fix-codeo-close-opens-pr` off `main` at `d9345429b1f0d2758fc0d5db0c46c31e73e484cc`, claimed with the create-only push. Next: `/codeo:plan`, in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/204 — fix: /codeo:close opens the PR before archiving the dossier, so every PR's first qc-verdict run fails |
| State | open · labels `priority: medium` |
| Branch | `chore/204-fix-codeo-close-opens-pr` off `main` at `d9345429b1f0d2758fc0d5db0c46c31e73e484cc` |
| Board | Ready → In progress |

**Problem.** `/codeo:close` opens the PR (Phase 1 step 4) while the dossier is still live at `.codeo/<N>/`, and archives it to `.codeo/done/<N>/` only afterwards (steps 6-7). `scripts/qc-verdict.sh` fails closed on a live dossier on the PR head, so the first CI run on every PR is red and sends a failure email; the archive commit's run passes. The red run hides real failures.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] The first CI run on a PR opened by `/codeo:close` passes qc-verdict.
- [ ] `close.md` in `.codeo/done/<N>/` still records the PR number and URL.
- [ ] A review send-back still makes qc-verdict fail until the dossier is archived again.
- [ ] Close fixtures and tests (`tests/role.test.sh`, `tests/fixtures/dossiers/*/close.md`, `tests/fixtures/golden/case-a/close.md`) and `docs/dossier.md` match the new order.

**Out of scope.** qc-verdict failures from review send-backs (intended); PRs opened outside `/codeo:close`, such as #165; the flaky `tests/readme.test.sh` failures (fixed in 638c20d).

**Open at intake.** None. Key requirements: archive and push the dossier before opening the PR; record the PR number and URL in `.codeo/done/<N>/close.md` in a follow-up commit; keep send-back un-archiving as it is.

## Log

- 2026-11-27 — initialized: branch chore/204-fix-codeo-close-opens-pr off main at d9345429b1f0d2758fc0d5db0c46c31e73e484cc · cost: 0m · sonnet-5-5 18k in + 476k cached / 2k out
