# Issue #179 — close

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/179 |
| Branch | `docs/179-close-171-leftovers-readme-wording` |
| Updated | 2026-11-26 |

## Where this stands

No pull request is open yet. The branch conflicts with `origin/main` in `tests/readme.test.sh` after #177 merged, so the workflow goes back to `/codeo:implement`, then `/codeo:qc`, then `/codeo:close`.

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

## Log

- 2026-11-26 — conflicts with main: `tests/readme.test.sh` after #177; sent back to implement · cost: 0m · sonnet-5-5 25k in + 1.1M cached / 1k out
