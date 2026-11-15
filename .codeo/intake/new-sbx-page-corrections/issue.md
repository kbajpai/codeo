# Issue new-sbx-page-corrections — issue

## Questions

1. **F33 — how to settle the credentials tension.** The page cites "credentials stay outside the VM" (Docker's design, `cited`) while T6 shows `gh` inside a sandbox "Logged in … (GH_TOKEN)". Settling it needs one more command on the engineer's host (is the token in the sandbox's environment the real one or a placeholder). **Options:** (A) the issue asks for that trial and then states the result on the page; (B) the issue only rewords the page to say the tension is untested.
   **Answer:** _open_

2. **F32 — which side of the image-digest disagreement moves.** #86 says the image changed digest between two creates (T10); the page says the base image was not checked, and quotes no `Image:` line. `.codeo/done/73/qc.md` F17 records that the `Image:` lines carried the same digest as the `Kit:` lines. **Options:** (A) the page quotes the `Image:` lines and drops "not checked"; (B) #86 is softened to the page's wording.
   **Answer:** _open_

3. **Scope.** One issue covers F32-F36 and F33 (the engineer asked to consolidate). Out of scope: `sync-main.sh` (#92) and `/codeo:plan`'s footprint key (issue B).

## Notes

Called from `/codeo:triage` run 6 (`.codeo/intake/triage/2026-11-15-6.md`). Duplicate search (`sbx page corrections`, `sandbox image digest`, `credentials sandbox token`, `dev-environment-sbx-evaluation`): only #85 and #86, the follow-ups the corrections touch; no duplicate. Verified on `origin/main`: the page still has the double "no volume or folder-naming rule" sentence, "1m47s (image pull)" and the planning text in the Trials intro; #86 still says "T5 to T12" and "T8 to T12".

## Outcome

_Pending._

## Log

- 2026-11-15 — questions raised · cost: unavailable
