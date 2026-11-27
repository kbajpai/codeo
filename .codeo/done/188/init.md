# Init — #188

| | |
|---|---|
| Issue | #188 |
| Step | init |

## Where this stands

Approved. Branch `docs/188-close-177-qc-leftovers-utc` off `main` at `d9345429b1f0d2758fc0d5db0c46c31e73e484cc`. Next: `/codeo:plan`, in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/188 — Close the #177 QC leftovers: UTC-date, ls-remote allowlist, tracker-condition, assignee-lookup and cleanup-line wording |
| State | open · labels `documentation`, `priority: low` |
| Branch | `docs/188-close-177-qc-leftovers-utc` off `main` at `d9345429b1f0d2758fc0d5db0c46c31e73e484cc` |
| Board | Ready → In progress |

**Problem.** #177's QC round 2 left five non-blocking findings (F2-F6): sentences in docs, skills or overlays true on one path only, plus a stray comma. Wording fixes only.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] Each of F2-F6 is corrected as the requirement states, or the pull request names it as dismissed with a reason.
- [ ] `docs/release-checklist.md` no longer says the UTC date is "the day after" local date.
- [ ] `skills/close/SKILL.md` allowlist wording works on the literal `ls-remote` output, and the "per branch" wording agrees with the skip clause.
- [ ] The three tracker-condition lines (F4) name `CODEO_TRACK` as well as `codeo-track.sh`, and say nothing is asked without a tracker.
- [ ] `docs/home-checkout.md:9` and `skills/cleanup/SKILL.md:84` match what `live.sh` and `scripts/cleanup.sh` do.
- [ ] `bash tests/run.sh` ends `all cases passed`.

**Out of scope.** The #173, #176, #170 findings (#185) and the #171 ones (#179); changing any script's behaviour; the release #182.

**Open at intake.** None.

## Log

- 2026-11-27 — initialized: branch docs/188-close-177-qc-leftovers-utc off main at d9345429b1f0d2758fc0d5db0c46c31e73e484cc · cost: 1m · sonnet-5-5 19k in + 552k cached / 2k out
