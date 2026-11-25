# Issue #161 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/161 |
| Branch | `docs/documentation-leftovers-154-146-removal` |
| Updated | 2026-11-24 |

## Where this stands

Initialized: branch `docs/documentation-leftovers-154-146-removal` cut off `origin/main` at `393a255eb626afbe682e16415aadc6bae5dbe41a`, and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/161 — Documentation leftovers from #154 and #146: removal flowchart and README wording, the v1.0.8 Shared state line, and release checklist step 6 |
| State | open · labels `documentation` |
| Branch | `docs/documentation-leftovers-154-146-removal` off `main` at `393a255` |
| Board | Ready → In progress |

**Problem.** `/codeo:qc` passed #154 and #146 with non-blocking documentation findings that have no issue: the README removal flowchart and two paragraphs say more than `.devcontainer/codeo` and `.sbx/codeo-sandbox.sh` do (#154 F1-F5), the v1.0.8 `Shared state:` changelog line omits two shipped dossier-reading changes (#146 F1), and `docs/release-checklist.md` step 6 omits the README installer examples and `tests/install.test.sh` stubs a release also moves (#146 F2).

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] The flowchart edge from `G` names the failed follow-up `docker ps -a` listing under `--force`, and the `H` edge no longer carries a `--force` parenthesis.
- [ ] The sandbox paragraph no longer says the script stops "before it reads `--force`" and still names `sbx rm --force codeo-<N>` as the way out.
- [ ] The inspect paragraph no longer says a container `codeo` "had to start" is always stopped again.
- [ ] Node `Q`'s label is true for every edge that reaches it.
- [ ] `CHANGELOG.md`'s v1.0.8 `Shared state:` line names the exact `## Outcome` match in `dossier-check.sh`, `inflight.sh` and `qc-verdict.sh` and the `### Round <n> — stashed|abandoned` reader in `lock.sh`.
- [ ] `docs/release-checklist.md` step 6 names the README installer examples and `tests/install.test.sh` stubs as files a release also moves.

**Out of scope.** #154 F6 (soft-wrap, a vague CHANGELOG sentence, early-wrapped `inflight.sh` comments); #146 F3 (`plan.md`'s "two files" note in an archived dossier); moving or re-tagging `v1.0.8`.

**Open at intake.** None; the issue left nothing unresolved.

## Log

- 2026-11-24 — initialized: branch docs/documentation-leftovers-154-146-removal off main at 393a255 · cost: 0m · sonnet-5-5 160k in + 393k cached / 2k out
