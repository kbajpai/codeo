# Issue #173 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/173 |
| Branch | `docs/173-close-161-leftovers-release-checklist` |
| Updated | 2026-11-25 |

## Where this stands

Branch `docs/173-close-161-leftovers-release-checklist` cut off `main` at d097737 and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/173 — Close the #161 leftovers: release-checklist and CHANGELOG wording, `codeo rm` README text on a failed `docker ps -a`, `stop_started`, and the `SessionStart` hook |
| State | open |
| Branch | `docs/173-close-161-leftovers-release-checklist` off `main` at d097737 |
| Board | Ready → In progress |

**Problem.** Statements #161 left in `docs/release-checklist.md`, `CHANGELOG.md` and `.devcontainer/README.md` are untrue on a path the code takes; `stop_started` ignores a failing `docker stop`, so a refused `codeo rm` can leave a container running; and the `SessionStart` hook #161 added is undocumented and its skip check disagrees with `install.sh`.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] `docs/release-checklist.md` step 6 says which examples and stubs move to the release being cut, which move to the one before it, and which do not move.
- [ ] `CHANGELOG.md:23` says which script stopped counting which heading, matching `dossier-check.sh`, `inflight.sh` and `qc-verdict.sh` at v1.0.7.
- [ ] The flowchart edges and the paragraph at `.devcontainer/README.md:186-188` hold when `docker ps -a` fails and `codeo` started the container.
- [ ] The `CHANGELOG.md` #154 bullet no longer says a refusal stops the container unconditionally.
- [ ] A refusal after a failed `docker stop` either reports it or is documented as leaving the container running; a test pins whichever is chosen.
- [ ] The hook's behaviour has a `CHANGELOG.md` bullet.
- [ ] The hook's skip check treats `superpowers@*` and a disabled codeo as `install.sh` does, and the hook does not re-run on `clear` or `compact`, or the page says it does.
- [ ] The hook comment and the README agree on when `/codeo:*` commands load in a hosted session.

**Out of scope.** Redesigning the `codeo rm` check or its restart. Removing the hook; whether it stays is not in question here.

**Open at intake.** F8 (whether `/codeo:*` commands load in the same session) is "plausible, not verified at runtime".

## Log

- 2026-11-25 — initialized: branch docs/173-close-161-leftovers-release-checklist off main at d097737 · cost: 1m · sonnet-5-5 18k in + 599k cached / 3k out
