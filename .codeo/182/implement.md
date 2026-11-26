# Issue #182 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/182 |
| Branch | `feat/182-release-v1-0-10-once` |
| Updated | 2026-11-26 |

## Where this stands

Tasks 1-8 of `docs/plans/2026-11-26-release-v1-0-10.md` are done. The release PR is **#189** (https://github.com/kbajpai/codeo/pull/189), from `release/v1.0.10` (worktree `../codeo-182-release`), five files, at `3c361c6`. `bash tests/run.sh` and `bash tests/readme.test.sh` end `all cases passed` there; `tests` and `qc-verdict` were pending on GitHub when this was written. The heading's date is `2026-11-26`, the UTC date #189 opened.

**Waiting for you (Task 9):** merge #189. Then tell me, and I run Task 10 (the clean-clone test of the merge commit), you tag and push (Task 11), I publish the Release (Task 12), I move `plugin.ref` on this branch (Task 13), and you rebuild the container (Task 14).

## Questions

None.

## Notes

Rulings and deviations, none of which changed what ships:
- **Task 1 expected counts.** The plan's Step 5 expected `tests/install.test.sh` to hold no `1.0.8` (it holds 2: the older-release tags in the two skipped functions, as designed), the `v1.0.9;x`/`v1.0.9.1` line count to be at least 4 (it is 1 line) and a `refs/tags/v1.0.9` count of 2 (9). Both test files pass, which is the proof that matters; the plan's text is not edited.
- **Task 3 baseline.** `overlap` was already in the README twice (implement and qc steps), not 0; the new text is right.
- **README text checked against the code.** An independent review of every sentence Tasks 2-6 added against the code found three imprecise sentences (the close step's behind-the-base condition and step order, and "the other `lock: TODO` line") and one remedy the code does not state ("install the plugin again"); all four were corrected (`84a5c1d`, `32de182`). `/codeo:close`'s dossier write-up of the `--sandbox` TODO's fix ("give the sandbox a name made of those characters") is inferred from `lock.sh` and `devcontainer-start.sh`, which state the cause and not a remedy.
- **Changelog #170 bullet.** The first draft credited the README with the `flock` and keychain notes; they are in `.devcontainer/README.md` and `docs/home-checkout.md`. Corrected before pushing.
- **Reviews.** Tasks 3-6 were one dispatch of four commits (same file, same kind); one reviewer checked Tasks 2-6 together. Every dispatch passed `model: sonnet`.
- Not done, as planned: no merge, no tag, no Release, no pin; those are Tasks 9-14.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-26 — Tasks 1-8 done; release PR #189 open, waiting for the engineer's merge · cost: 15m · sonnet-5-5 374k in + 13.8M cached / 60k out
