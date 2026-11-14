# Issue #52 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/52 |
| Branch | `feat/run-codeo-latest-claude-models` |
| Updated | 2026-11-14 |

## Where this stands

Draft, waiting for the engineer's approval. Branch `feat/run-codeo-latest-claude-models` would be cut off `main` at 91894c1. Nothing is open; the next step is `/codeo:plan`.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/52 — Run codeo on the latest Claude models (Fable 5.2, Opus 5.5, Sonnet 5.5) and evaluate Haiku 5.5 |
| State | open · labels `enhancement` |
| Branch | `feat/run-codeo-latest-claude-models` off `main` at `91894c1` |
| Board | Ready → In progress |

**Problem.** codeo picks models by alias (`fable`, `opus`, `sonnet`) in its skills' frontmatter and in the subagent and QC-reviewer defaults. With Fable 5.2, Opus 5.5, Sonnet 5.5 and Haiku 5.5 launched, each alias has to be shown to resolve to the latest model in current Claude Code, or the gap recorded. The example text and test fixtures in `docs/dossier.md` and `tests/fixtures/dossiers/**` still name `fable-5-1`, `sonnet-5` and `opus-5` and must move to the current versions, with the suite still passing and `CHANGELOG.md` recording the result. Haiku is used nowhere; whether the low-judgment skills could run on it is an evaluation for `/codeo:plan`, not a requirement.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] The issue records which model each alias resolves to, for `fable`, `opus` and `sonnet`.
- [ ] No `fable-5-1`, `sonnet-5` or `opus-5` remains in `docs/` or `tests/fixtures/`.
- [ ] `bash tests/run.sh` passes.
- [ ] `CHANGELOG.md` records the change.

**Out of scope.** Pinning explicit model IDs in place of aliases; changing which skill runs on which model, other than the Haiku evaluation; changes to `scripts/usage.sh`.

**Open at intake.** Could the low-judgment skills (`init`, `close`, `doctor`, `setup`, `triage`) or the subagent default run on Haiku 5.5 without losing quality? This is an evaluation for `/codeo:plan`, not a requirement.

## Log

- 2026-11-14 — draft, not yet initialized
