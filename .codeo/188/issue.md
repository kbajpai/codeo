# Issue #188 — issue

Filed as #188: Close the #177 QC leftovers (documentation, priority: low). Approved by the engineer.

### Description

#177's QC round 2 left five non-blocking findings (F2-F6) that nobody filed. All are places where a sentence in a doc, skill or overlay is true on one path only, plus one stray comma. This issue closes them in one pull request, as #173, #177, #179 and #185 did for earlier rounds.

### Motivation / Context

`/codeo:triage` run 5 (2026-11-26) found them in `.codeo/done/177/qc.md`, round 2, each classified non-blocking and "`/codeo:implement`'s". F2 sits in `docs/release-checklist.md`, which #182's release follows. No open issue covers them: #179 is #171's, #185 is #173/#176/#170's.

### Key Requirements

- F2: `docs/release-checklist.md:90-92` says the UTC date "can be the day after the engineer's local date". That holds west of UTC only; east of it the UTC date can be the day before. Say it can differ by a day.
- F3: `skills/close/SKILL.md:550-552`. `git ls-remote --heads` prints `<sha>` and `refs/heads/codeo-live/...`, but the allowlist is worded on `codeo-live/<issue>/...`, so a literal reader could skip every line. Say to drop the `refs/heads/` prefix first. "print one ... per branch it printed" also reads against the next clause, which skips names outside the set; say "per branch that passes".
- F4: `.codeo/overlays/cleanup.md:12`, `.codeo/overlays/close.md:11` and `docs/home-checkout.md:66` give "only when `codeo-track.sh` sits beside it" as the condition. `CODEO_TRACK` (`.sbx/codeo-sandbox.sh:22`) also supplies the tracker, and the sandbox sentence in `home-checkout.md` does not say that with no tracker nothing is asked.
- F5: `docs/home-checkout.md:9` says `live.sh` is "skipping the assignee lookup". `assignee_label` still runs `gh` and only the `jq` parse fails, so the lookup yields nothing. It matters only for a web session whose `GET /user` failed.
- F6: `skills/cleanup/SKILL.md:84` says an issue that failed only `name` "gets one" `leftover` line. It gets one only while origin still holds `codeo-live/<N>/*` branches (`scripts/cleanup.sh:13`). Also a stray comma at `CHANGELOG.md:30` ("on record, is listed").

### Acceptance Criteria

- [ ] Each of F2-F6 is corrected as the requirement states, or the pull request names it as dismissed with a reason.
- [ ] `docs/release-checklist.md` no longer says the UTC date is "the day after" local date.
- [ ] `skills/close/SKILL.md` allowlist wording works on the literal `ls-remote` output, and the "per branch" wording agrees with the skip clause.
- [ ] The three tracker-condition lines (F4) name `CODEO_TRACK` as well as `codeo-track.sh`, and say nothing is asked without a tracker.
- [ ] `docs/home-checkout.md:9` and `skills/cleanup/SKILL.md:84` match what `live.sh` and `scripts/cleanup.sh` do.
- [ ] `bash tests/run.sh` ends `all cases passed`.

### Out of Scope

- The #173, #176, #170 findings (#185) and the #171 ones (#179).
- Changing any script's behaviour: the fixes are to the wording, not to `live.sh` or `cleanup.sh`.
- The release #182.

### Reference

- `.codeo/done/177/qc.md`, round 2, F2-F6, on `main`.
- Related: #177 (source), #179 and #185 (other leftover rounds, not overlapping), #182 (the v1.0.10 release).
- Surfaced by `/codeo:triage` run 5, 2026-11-26.
