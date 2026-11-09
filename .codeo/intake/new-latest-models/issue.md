# Issue — use the latest Claude models (Fable 5.2, Opus 5.5, Sonnet 5.5; evaluate Haiku 5.5)

## Questions
1. Aliases or pinned IDs? — **Answered: verify the aliases resolve to the latest, keep them.** Update only the version-bearing examples.
2. Haiku 5.5 for low-judgment skills? — **Answered: evaluate**, as an open question, not a requirement.

## Findings
- Skills select models by alias: `model: fable` (plan), `opus` (issue, qc), `sonnet` (close, doctor, implement, init, setup, triage). Config defaults `models.subagent=sonnet`, `models.reviewer=opus` (hooks/subagent-model.sh, skills/*).
- Versions appear only in example text: docs/dossier.md:194 (`fable-5-1`, `sonnet-5`) and tests/fixtures/dossiers/** (`fable-5-1`, `sonnet-5`, `opus-5`). scripts/usage.sh derives model names from transcripts, so it needs no change.
- No existing issue found (searched "model fable", "opus sonnet haiku").
