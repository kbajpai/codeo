# Init — #206

| | |
|---|---|
| Issue | #206 |
| Step | init |

## Where this stands

Approved. Branch `fix/206-codeo-cleanup-prints-codeo-rm` off `main` at `d9345429b1f0d2758fc0d5db0c46c31e73e484cc`, claimed with the create-only push. Next: `/codeo:plan`, in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/206 — /codeo:cleanup prints `codeo rm {N}` unexpanded and lists issues again after their containers were removed |
| State | open · labels `bug`, `priority: medium` |
| Branch | `fix/206-codeo-cleanup-prints-codeo-rm` off `main` at `d9345429b1f0d2758fc0d5db0c46c31e73e484cc` |
| Board | Ready → In progress |

**Problem.** `scripts/cleanup.sh` prints the project's removal command with `{N}` unexpanded, because the overlay's `command: codeo rm {N}` uses a placeholder the script does not expand in `command` (only `{name}`), so the printed line cannot be run. It also rebuilds its list from every `.codeo/done/<N>` and the `origin` proofs each run and never reads earlier removal records, so issues already removed print as proven again and the list grows with every merge.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] With the project's current overlay, no printed line contains `{` or `}`.
- [ ] An overlay whose command keeps a placeholder the script does not expand makes the script exit non-zero with a `cleanup:` line, or the placeholder is expanded; a test pins it.
- [ ] After an issue's removal is recorded, a later run does not list it as proven or not proven.
- [ ] An issue whose proof fails is listed as not proven whether or not a removal was recorded.
- [ ] Two engineers recording removals do not lose each other's entries on merge.
- [ ] `skills/cleanup/SKILL.md`, `docs/skills.md` and the README describe how to record a removal.
- [ ] The full suite passes.

**Out of scope.** Running or building a removal command in the skill; detecting whether a container still exists on a host; the old finding about the overlay's `{N}` wording closed in #163.

**Open at intake.** None. Whether the placeholder fix lives in the script or the overlay text is left to `/codeo:plan`. The issue's dossier is adopted at `.codeo/206/issue.md`.

## Log

- 2026-11-27 — initialized: branch fix/206-codeo-cleanup-prints-codeo-rm off main at d9345429b1f0d2758fc0d5db0c46c31e73e484cc · cost: 0m · sonnet-5-5 16k in + 337k cached / 2k out
