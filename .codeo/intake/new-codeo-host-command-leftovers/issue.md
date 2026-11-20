# New issue — issue

Called from `/codeo:triage` (run 10, 2026-11-20, Q1): the engineer answered *file it* and asked to consolidate. Problem as understood: `.devcontainer/codeo` (the host command from #133, PR #136, merged) shipped with `qc.md` findings F2-F32 recorded as non-blocking and 11 review threads from the Copilot reviewer left unresolved; `codeo rm` deletes containers, volumes and sandboxes, so the ones that can remove unsaved work or print false advice are worth an issue of their own. No open issue covers it (`issue search` found only closed #133, #131, #123, #125).

I read `.devcontainer/codeo` as it stands on `origin/main` before asking. Already fixed there, so they would not go in the issue: F26 / thread …636750 (`sbx_prog` honours `CODEO_SBX`), thread …636595 (`remote set-url origin "$repo_url"` before every lookup fetch), thread …636654 (`rev-parse` replaced `cat-file -e`). Still present: F29 (`:501`), F30 (`:533`), the shared `$name.part` download file (`:98-106`), the shared `.lookup.git.part` (`:119-124`), `git fetch origin` in the container check without `--prune` (`:448`), `git status --porcelain` without an explicit untracked setting (`:452`). The rest I have not re-checked; `/codeo:plan` does that.

## Questions

1. **Leave out what is already fixed?** — F26 and the two threads above look fixed on `origin/main`. Proposed: the issue lists them under *Reference* as "reported, appear fixed, confirm and drop in `/codeo:plan`", not as requirements. Yes, or keep them as requirements?

2. **What does "done" mean for the long tail?** — F3, F4, F7, F8, F10-F13, F20, F27, F28 and the seven *outdated* review threads are small or may be fixed already. Proposed: every item is either fixed or ruled out with a reason recorded in `/codeo:plan`'s dossier, the five that can lose work or print false advice (F19, F29, F30, the write-after-check race, the stale-ref/untracked checks) are acceptance criteria of their own, and the rest share one criterion. Or: only the five, and the tail dismissed?

3. **Consolidate with the #133 wording leftovers?** — triage Q9 (F5/F16, F14, F15, F6/F31, F17, F22, F23, F21) is the same file and README, and you asked to consolidate, but you did not answer Q9. Proposed: fold them in as one acceptance criterion ("the README, help text and changelog match what the command does"). Fold in, or keep them out (they stay deferred in the ledger)?

## Outcome

Open: Q1-Q3. The draft is held until they are answered.

## Log

2026-11-20 — questions raised · cost: unavailable
