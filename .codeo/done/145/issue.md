# Issue #145 — issue

Called by `/codeo:triage` run 11 (2026-11-21). The engineer chose *file it* for #102 (F1, F2, F5), #126 (F1-F3) and #122 (F1-F5) and asked for one consolidated issue. Label `bug`. No Issue Type (`issue-types` prints nothing). `issue.priority` is not set in the config, so no priority label.

## Questions

1. **F4 of #122: where is the comment now?**
   The finding cites `scripts/inflight.sh:285`, "a `close` outcome that no rule above took". On `origin/main` that exact text is not at a line I can match (`grep` finds only the "looking past a spent stash or abandon" comments at lines 22 and 236). The behaviour (steps past any `close` outcome no earlier rule took) is in `waits_of`, lines 280-290.
   *Resolved as content:* the issue cites the finding and `waits_of`, not a line number, and asks `/codeo:plan` to locate the comment. Open question in the draft, blocks nothing.

2. **Scope of #122 F5.**
   `qc.md` says "Arguably intended; the skill does not say so." The issue therefore asks for a decision (re-ask until assigned, or stop on *resume*), not a fix direction.
   *Resolved as content:* an open question in the draft.

## Verified on origin/main (2e02100)

- #102 F1: `scripts/doctor.sh` tests `.issue.priority == true` (a bool); `skills/issue/SKILL.md` uses the printed `true` string. Confirmed. F2: SKILL.md step 7 adds one `priority:` label on top of the approved labels with no rule against two. F5: doctor.sh builds `bash $CODEO_PLUGIN_ROOT/scripts/github.sh label create '$l'` unquoted. Confirmed.
- #126 F1-F3: `scripts/claim.sh` header lines 41-45 "Known limit … retitling is the right remedy"; line 221 ends "or retitle #$n"; line 211 "was pushed by hand". Confirmed.
- #122 F1: `inflight.sh:251` prints `review — dossier archived` for any `state_token` other than the listed ones; `skills/triage/SKILL.md:315` and `docs/handoff.md:155` say it names the PR awaiting review. F2: `CHANGELOG.md:21` "(or the step before the park)". F3: `touched_of` (`inflight.sh:99`) has no test under `tests/`. F5: `skills/triage/SKILL.md:120` "a dismissal of it holds", no word on *resume*. Confirmed. Line numbers have drifted from the QC's; the issue cites file and quoted text.

## Outcome

Questions 1 and 2 are content. Draft recorded below; awaiting approval at the review gate.

## Draft

**Title:** Close the #102, #126 and #122 leftovers: priority-setting disagreements, stale `claim.sh` text, and triage's `review — dossier archived` label

(body presented in the conversation)

## Log

2026-11-21 — draft written for review gate
2026-11-21 — approved and filed as #145
