# Issue #179 — close

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/179 |
| Branch | `docs/179-close-171-leftovers-readme-wording` |
| Updated | 2026-11-26 |

## Where this stands

Pull request #187 is open and waiting for review. The workflow stays open until it merges; run `/codeo:close` again after the merge.

## Questions

None.

## Notes

- The lookup sees only the newest pull request for the branch; none exists.

## Outcome

### Round 1 — conflicts with main

2026-11-26

`git merge-tree --write-tree --name-only origin/main HEAD` exits 1:

- `tests/readme.test.sh` — content conflict. The change on `main` that touched it: `3a36e47 docs: close the #163, #166 and #168 leftovers: home-checkout jq and sandbox wording, overlay order, cleanup closing block, close step 17, changelog and checklist (#177) (#186)`. It also changed `docs/home-checkout.md`, which merged without a conflict. This is the overlap raised and answered at plan (`plan.md` Q7, proceed and coordinate).

qc round at review: 3

### Round 2 — pull request opened

2026-11-26

#187 https://github.com/kbajpai/codeo/pull/187

Went out on `qc.md` round 4: **Verdict: clear — forward to `/codeo:close`.** The `qc round at review` of round 1 was 3, so round 4 is newer. No override.

## Log

- 2026-11-26 — conflicts with main: `tests/readme.test.sh` after #177; sent back to implement · cost: 0m · sonnet-5-5 25k in + 1.1M cached / 1k out
- 2026-11-26 — opened PR #187 on qc round 4 (clear), archived the dossier · board.sh: #179 In review → In review on #3 Codeo · cost: 0m · sonnet-5-5 23k in + 877k cached / 3k out
