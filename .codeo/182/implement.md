# Issue #182 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/182 |
| Branch | `feat/182-release-v1-0-10-once` |
| Updated | 2026-11-26 |

## Where this stands

Tasks 1-13 of `docs/plans/2026-11-26-release-v1-0-10.md` are done. Release PR #189 merged as `d60c26a`; the clean-clone test of that commit ended `all cases passed` (version `1.0.10`, heading `## v1.0.10 — 2026-11-26`). Tag `v1.0.10` is on origin at `d60c26a` (lightweight, you pushed it), and Release `v1.0.10` is published and Latest with the changelog section as its notes (9 bullets). `plugin.ref` in `.codeo/config.json` is `v1.0.10` on this branch; `bash tests/run.sh` ends `all cases passed` with it. `/codeo:close` opens this branch's PR, and criterion 8 is met when that PR merges.

**Waiting for you (Task 14):** rebuild or restart the dev container, start a new Claude Code session, and tell me. I then run `claude plugin list` and expect `codeo@codeo` at `Version: 1.0.10`.

## Questions

None.

## Notes

Rulings and deviations, none of which changed what ships:
- **Task 1 expected counts.** The plan's Step 5 expected `tests/install.test.sh` to hold no `1.0.8` (it holds 2: the older-release tags in the two skipped functions, as designed), the `v1.0.9;x`/`v1.0.9.1` line count to be at least 4 (it is 1 line) and a `refs/tags/v1.0.9` count of 2 (9). Both test files pass, which is the proof that matters; the plan's text is not edited.
- **Task 3 baseline.** `overlap` was already in the README twice (implement and qc steps), not 0; the new text is right.
- **README text checked against the code.** An independent review of every sentence Tasks 2-6 added against the code found three imprecise sentences (the close step's behind-the-base condition and step order, and "the other `lock: TODO` line") and one remedy the code does not state ("install the plugin again"); all four were corrected (`84a5c1d`, `32de182`). `/codeo:close`'s dossier write-up of the `--sandbox` TODO's fix ("give the sandbox a name made of those characters") is inferred from `lock.sh` and `devcontainer-start.sh`, which state the cause and not a remedy.
- **Changelog #170 bullet.** The first draft credited the README with the `flock` and keychain notes; they are in `.devcontainer/README.md` and `docs/home-checkout.md`. Corrected before pushing.
- **Reviews.** Tasks 3-6 were one dispatch of four commits (same file, same kind); one reviewer checked Tasks 2-6 together. Every dispatch passed `model: sonnet`.
- Not done, as planned: the container rebuild and the version check (Task 14).

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-26 — Tasks 1-8 done; release PR #189 open, waiting for the engineer's merge · cost: 15m · sonnet-5-5 374k in + 13.8M cached / 60k out
- 2026-11-26 — release merged (#189, d60c26a), clean-clone test passed, tag v1.0.10 and Release published, pin moved; waiting for the container rebuild · cost: unavailable (see the previous line)
