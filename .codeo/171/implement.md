# Issue #171 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/171 |
| Branch | `docs/make-readme-complete-easy-follow` |
| Updated | 2026-11-25 |

## Where this stands

Implemented: all eight tasks of `docs/plans/2026-11-25-readme-complete-guide-171.md` are done, reviewed and committed (`a427f86`..`b3270bb`), and the build ran. Next step: `/codeo:qc`.

## Questions

None.

## Notes

- **Overlap:** `overlap.sh 171` printed nothing at the start of the round; `sync-main.sh` merged one `origin/main` commit (`ffb2104`, the v1.0.9 pin and #168's archived dossier), which touches none of this plan's files.
- **Task 7 was dispatched in two parts** (7a Configuration, 7b Troubleshooting) because one dispatch would have been too large; the plan's text and proof are unchanged.

## Outcome

**Built**, one commit per task plus fix rounds after each review that found something:

| Task | What | Commits |
|---|---|---|
| 1 | `tests/readme.test.sh`: checks the README's commands, paths, links (with anchors), config keys, headings, Start here, walk-through and troubleshooting entries | `a427f86` |
| 2 | update, replace and restore walk-throughs and their installer output moved to `docs/updating.md`; the install pins in `tests/install.test.sh` read both files | `270cb15` |
| 3 | home checkout, guard and tracking comment moved word for word to `docs/home-checkout.md` | `ebe34fe` |
| 4 | README summary, contents, Start here, Requirements, Installing with `### Options`; the thirteen `##` headings and `t_readme_sections` | `6b2d886`, repair `6572b8a` |
| 5 | Setting a project up as three numbered steps | `9aac1cb` |
| 6 | Your first workflow: six sub-sections, a Mermaid flowchart; corrected when the dossier moves and what close hands off to | `9bf842f`, `03b9d46` |
| 7 | Configuration table of 43 keys with two examples; Troubleshooting for a workflow (four entries) beside the doctor entries | `398e6d7`, `0b14b19`, `2862433`, `779af42` |
| 8 | Updating, More documentation, CHANGELOG `## Unreleased`; final-review fixes (ruleset note for a new repository, Updating wording, the guard test scans every page) | `a2690ec`, `b3270bb` |

**Documentation pages changed:** `README.md`, `docs/updating.md` (new), `docs/home-checkout.md` (new), `CHANGELOG.md`. No wiki module.

**Build:** the `shell` suite's `build` is `true`: exit 0. (The implementers also ran `bash tests/run.sh` before each commit; the whole suite passed at `b3270bb`. Grading it is `/codeo:qc`'s.)

**Deviations from the plan, and why:**

- `t_readme_sections` and the thirteen headings landed in Task 4, not Task 8, with `## Configuration` and `## More documentation` as one-line placeholders until Tasks 7 and 8, so the install suite stayed green after every task (ruling R2).
- The README's `--version` output block lives only in `docs/updating.md`; the README keeps the command, one sentence and a link (ruling R1).
- `t_readme_links_resolve` now resolves each link relative to its own file's folder, because `docs/updating.md` links `../README.md`; README links resolve as before.
- The README documents that a brand-new repository fails doctor's `ruleset` check until its base branch requires `tests` and `qc-verdict`: the starter output block is what a project with that ruleset sees. Not in the plan; found by the final review.
- Task reviews found and fixed, in the README: a corrupted Installing splice (Task 4), the dossier moving at pull-request time rather than after the merge (Task 6), eight inaccurate defaults and doctor-coverage statements (Task 7a), a misleading lock example and container-only advice stated generally (Task 7b).

**Parked, minor:** list and code-block indentation in Setting a project up renders awkwardly in strict Markdown; `tests/readme.test.sh`'s `paths` check skips backticked tokens with a space, so `bash <path>` forms are not checked, and its generic-key grep is weak by design (the known-keys comparison is the real guard).

**Not in this plan, to file** (promised in `plan.md`'s `## Notes`): `docs/handoff.md:3` says "Seven pipeline skills" where `docs/skills.md` says six; how another project adopts the role guard.

**Deployed revision:** none; no shared environment.

## Log

- 2026-11-25 — implemented: plan docs/plans/2026-11-25-readme-complete-guide-171.md, tasks 1-8, build exit 0 · cost: 35m · sonnet-5-5 945k in + 25.9M cached / 150k out
