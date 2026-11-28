# Issue #217 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/217 |
| Updated | 2026-11-28 |

## Where this stands

The engineer answered every question in conversation before the skill ran. Draft is below, waiting at the review gate.

## Questions

### Q1 — What does the engineer want, and why?

**Answer:** One interface step to start an issue (mark Ready, init, create the container, no commands typed), work in Claude Desktop, then close and have cleanup happen automatically. A full web app was judged overkill; two host commands plus `--version` and a more verbose `update` instead.

### Q2 — Out of scope?

**Answer:** The web page/dashboard. Automatic removal anywhere other than `codeo done`. Verifying the macOS path on a real Mac. How Claude Desktop attaches to a container volume (unverified, separate).

### Q3 — macOS constraint?

**Answer:** The Mac terminal needs keychain access: `claude -p` and Docker's credential helper both read the login keychain. Check before changing anything.

## Notes

Open (nobody can answer yet, goes into the issue as content): whether `claude -p` runs `/codeo:init` as a slash command non-interactively; how `codeo go` finds the home clone from the host.
Related: #200 (version skew, writes versions into dossier/lock; this issue only gives the host command its own version), #213 (v1.0.11 release; the new constant joins the release checklist).

## Outcome

_Pending — written at the hand-off._
