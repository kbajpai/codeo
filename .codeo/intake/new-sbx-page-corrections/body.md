### Description

The evaluation page `docs/dev-environment-sbx-evaluation.md` (merged in #93, for #73) and the follow-up #86 carry a few claims that are stronger than, or disagree with, the evidence the page quotes, and one untested tension that bears on the case for moving issue work to a sandbox. This issue corrects them. It changes the page and #86's text; it changes no code and no `.devcontainer/` file.

### Motivation / Context

QC round 4 of #73 recorded these as non-blocking findings (`.codeo/done/73/qc.md`, F32-F36):
- **Image digest (F32).** #86 states that the `docker.io/sbx/claude:latest` image changed digest between two creates (T10). The page says the printed kit digest differed and "whether the base image changed was not checked", and quotes no `Image:` line. The recorded T3, T8 and T10 output has an `Image:` line carrying the same digest as the `Kit:` line, so the page can show it.
- **Credentials (F33).** D1 and "Why not stay" cite "credentials stay outside the VM" as Docker's design (cited). T6 shows `gh` inside a sandbox "Logged in … (GH_TOKEN)" with `delete_repo` among its scopes. Whether that token is the real one or a placeholder was never tested, and neither #85 nor #86 covers it.
- **Wording (F34-F36).** The Recommendation's naming sentence says "no volume or folder-naming rule" twice and ends by contradicting itself; the page's follow-up list leaves out U6, U8 and U14, which #85 and #86 do cover; #86 cites trials "T5 to T12" in one place and "T8 to T12" in another; "1m47s (image pull)" in D3 infers the pull from a later "(cached)" line; the U4 claim about file modes is checked for `tests/run.sh` only; one sentence repeats "was not tried"; the Trials introduction still carries planning instructions ("Paste every output…").

### Key Requirements

- The page quotes the `Image:` lines from the T3, T8 and T10 output, says whether the image digest changed between creates, and drops "not checked" where the quote settles it. #86 and the page then say the same thing.
- One trial, run by the engineer on their Windows + WSL2 host inside a sandbox, shows whether the token that `gh` uses is the host's real token or a placeholder (for example whether `GH_TOKEN` is set in the sandbox's environment and what it holds, masked). Its output is pasted into the page as a new trial, and D1, "Why not stay" and the Credentials bullet say what it showed. If the trial cannot be run, the page says so instead of citing the isolation as gained.
- The naming sentence, the follow-up mapping (U6, U8 under #85; U14 under #86), #86's trial range and the inferred or leftover wording (F36) are corrected so that each claim names only what the quoted output shows.
- Counts on the page (28 rows, tried and cited) and the #73 comment stay true after the edits, or the comment is updated with them.

### Acceptance Criteria
- [ ] The page quotes the `Image:` lines from the creates it cites and states whether the digest changed; #86's sentence agrees with it.
- [ ] A trial (T13) on the engineer's host settles whether the sandbox's `gh` token is the real token or a placeholder, and D1, the Recommendation and the Credentials bullet cite it.
- [ ] The Recommendation's naming sentence no longer repeats itself or contradicts its own conclusion.
- [ ] The follow-up section maps U6 and U8 to #85 and U14 to #86; #86 cites one trial range, matching the trials it uses.
- [ ] "1m47s (image pull)", the U4 file-mode claim and the doubled "was not tried" read as exactly what the output shows; the Trials introduction no longer instructs the reader to run or paste anything.
- [ ] `bash tests/run.sh` still passes, and `git diff --stat main -- .devcontainer skills` is empty.

### Out of Scope

- Changing the recommendation (hybrid), or doing any part of #85 or #86.
- `sync-main.sh` exiting 1 after a clean merge (#92).
- Anything about how projects that use codeo run it.

### Reference
- `docs/dev-environment-sbx-evaluation.md`, rows D1, D3, U4, U6, U8, U14, the Recommendation and Follow-up issues sections, and trial T6.
- #73 (the evaluation), PR #93, and follow-ups #85 and #86.
- `.codeo/done/73/qc.md`, round 4, findings F32-F36 (F17 for the `Image:` line); surfaced by `/codeo:triage` run 6 (`.codeo/intake/triage/2026-11-15-6.md`).
