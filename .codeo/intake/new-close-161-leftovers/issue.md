# Issue new-close-161-leftovers — issue

Filed from `/codeo:triage` 2026-11-25 Q1 (`qc:161:F4-F7-preexisting`). Duplicate search for `stop_started` finds only closed #154; #163, #166, #168 do not cover these. Claims re-checked against `main`: the `stop_started` comment and body (`.devcontainer/codeo:474-479`, "a failing stop is ignored"), README `:187` and flowchart `:205-206`, the CHANGELOG `## Unreleased` bullet at `:18`, and `docs/release-checklist.md:74-76` are all still as quoted.

## Questions

### Q1. One issue or two?
Six of the seven items are wording (release checklist, CHANGELOG ×2, README ×2 paragraph/flowchart); `stop_started` ignoring a failing `docker stop` is a behaviour gap.
Recommend one issue, with the `stop_started` requirement stated as "a refusal never leaves a container codeo started running without saying so", leaving the fix (report vs retry vs fail the stop) to `/codeo:plan`. Alternative: two issues, so the wording fixes can ship without waiting on a code decision.

**Answer:**

### Q2. For `stop_started`, is a documentation-only fix acceptable?
Either the code reports (or fails on) a failed `docker stop`, or the README and CHANGELOG say plainly that a refusal can leave a container running. Recommend: leave the choice to `/codeo:plan`, with the acceptance criterion true either way.

**Answer:**

### Q3. Priority
Recommend `priority: low` — rubric line "polish, cleanup, or a follow-up nobody is waiting on". No Issue Type is proposed: `issue-types` printed nothing. Labels: `documentation`.

**Answer:**

## Draft

**Title:** Close the #161 leftovers: release-checklist and CHANGELOG wording, `codeo rm` README text on a failed `docker ps -a`, and a refusal that ignores a failing `docker stop`

**Labels:** `documentation`, `priority: low`

```markdown
### Description

Close the non-blocking findings `/codeo:qc` recorded for #161 and the pre-existing gaps it found in the same text, none of which has an issue.

### Motivation / Context

Each statement below is true on the main path and untrue on a path the code takes, so a reader who trusts the text is misled.

- `docs/release-checklist.md:74-76` says the installer examples and `tests/install.test.sh` stubs "move to the latest release". The README's `--version v1.0.7` example and the older-tag stubs move to the release before it, and the `v1.0.9`/`v1.0.10`/`v2.0.0-rc1` ordering stubs do not move.
- `CHANGELOG.md:23` says the three scripts match `## Outcome` exactly "so `## Outcomes` and `## Outcome notes` no longer count". At v1.0.7 `scripts/dossier-check.sh:131` already ignored `## Outcomes`, so for that script only `## Outcome notes` stopped counting; `inflight.sh` and `qc-verdict.sh` had a bare `/^## Outcome/`, so both forms stopped counting there.
- The `.devcontainer/README.md` flowchart edges `clean, was running, inspect failed, no --force: no restart` and `clean, was running, inspect ok or --force`, and the paragraph at `:186-188` ("A container that `codeo` started itself is read once"), call a container "was running" when `docker ps -a` failed and `codeo` may have started a stopped one (`started=0`).
- The `CHANGELOG.md` `## Unreleased` #154 bullet says a refused `codeo rm` "stops a container it started for the read", the over-claim #161 removed from the README.
- `stop_started` (`.devcontainer/codeo:477-478`) ignores a failing `docker stop`, so a refusal can still leave a container `codeo` knew it started running.

### Key Requirements

- Each statement above is true on every path the code takes, or the code changes so it is.
- A refused `codeo rm` never leaves a container `codeo` started running without saying so.

### Acceptance Criteria
- [ ] `docs/release-checklist.md` step 6 says which examples and stubs move to the release being cut, which move to the one before it, and which do not move.
- [ ] `CHANGELOG.md:23` says which script stopped counting which heading, matching `dossier-check.sh`, `inflight.sh` and `qc-verdict.sh` at v1.0.7.
- [ ] The flowchart edges and the paragraph at `.devcontainer/README.md:186-188` hold when `docker ps -a` fails and `codeo` started the container.
- [ ] The `CHANGELOG.md` #154 bullet no longer says a refusal stops the container unconditionally.
- [ ] A refusal after a failed `docker stop` either reports it or is documented as leaving the container running; a test pins whichever is chosen.

### Out of Scope

- Redesigning the `codeo rm` check or its restart.
- The `SessionStart` hook findings from #161 (F5, F6, F8).

### Reference

- `.codeo/done/161/qc.md`, round 3 non-blocking findings F4 and F7, and its list of pre-existing items.
- `.devcontainer/codeo:474-479`, `.devcontainer/README.md:186-188, 205-206`, `CHANGELOG.md:18, 23`, `docs/release-checklist.md:74-76`.
- #154, #161.
```
