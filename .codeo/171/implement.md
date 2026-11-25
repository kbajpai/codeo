# Issue #171 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/171 |
| Branch | `docs/make-readme-complete-easy-follow` |
| Updated | 2026-11-25 |

## Where this stands

Round 3 is done: the findings of `qc.md` round 2 are fixed in `078331a` and the build ran. Next step: `/codeo:qc`.

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


### Round 2 — 2026-11-25
(send-back from qc.md round 1)

I read each finding against the code before acting (F1-F3 were checked against `scripts/doctor.sh`, `scripts/lock.sh` and the old README). All ten held. The edits were small, so I made them directly rather than dispatching a subagent; they are all in `ca7f2f3`.

- **F1:** README "Requirements" now says the installer checks all five tools and `/codeo:doctor` checks bash, `jq`, `git` and `gh`, never `claude`.
- **F2:** the lock entry separates what you may do (`git switch` to the lock's branch) from what you may not (edit `.codeo/active` to match a branch); the `lock: TODO` volume example is named as the one case of a by-hand edit, and a TODO that says no lock was taken is fixed with `/codeo:init #<N>`.
- **F3:** the `git ls-remote` tag lookup, the trusted-folder sentence and the replace-drops-the-install sentence are back beside the hand-written settings example.
- **F4, F5:** "Restart …" moved to the end of the `--version` step under Moving a project's pin; "Before you run it" now says "the install command" in README and docs/updating.md.
- **F6, F7:** `tests/readme.test.sh` states that its key check is weak and its list hand-kept, and it fails with `FAIL pages: <page> is missing` when either docs page is absent (checked by moving one away).
- **F8:** "which is still supported" removed from docs/home-checkout.md.
- **F9, F10:** the lock sentence names the dev container start script's removal of an empty lock; `hooks` is in doctor's unchecked list.

**Build:** `true` (suite `shell`): exit 0. `bash tests/run.sh` also ran and ended `all cases passed`; grading it is `/codeo:qc`'s.

No deployment: no shared environment is configured.


### Round 3 — 2026-11-25
(send-back from qc.md round 2)

I read each finding against the code before acting. G1 I reproduced in a clean worktree before the fix (`FAIL paths: README.md: \`.codeo/active\` does not exist`, exit 1) and again after (exit 0). The edits were small, so I made them directly, all in `078331a`.

- **G1:** `tests/readme.test.sh` allows `.codeo/active` and `.codeo/intake` by name, as gitignored runtime paths, instead of looking them up. A clean worktree of the new tree passes.
- **G2:** the `paths` check now reads every path-shaped word inside a backticked span, so `bash scripts/dossier-check.sh …`, `bash .devcontainer/scripts/devcontainer-start.sh` and `.devcontainer/scripts/role.sh --check <skill>` are checked. Renaming `dossier-check.sh` in a copy of the README now fails with `FAIL paths: … scripts/dosier-check.sh does not exist`. The header comment says what it checks.
- **G3:** the `resources[].paths` row also says `/codeo:plan` uses them for a footprint's `exclusive:` line.
- **G4:** README.md:38 reads "The installer installs none of them".
- **G5:** Setting a project up says `/codeo:setup --stack <name>` also writes `stacks`.

**Build:** `true` (suite `shell`): exit 0. `bash tests/run.sh` also ran and ended `all cases passed`; grading it is `/codeo:qc`'s.

No deployment: no shared environment is configured.

## Log

- 2026-11-25 — implemented: plan docs/plans/2026-11-25-readme-complete-guide-171.md, tasks 1-8, build exit 0 · cost: 35m · sonnet-5-5 945k in + 25.9M cached / 150k out
- 2026-11-25 — implemented round 2 (send-back from qc round 1): F1-F10 fixed in ca7f2f3, build exit 0 · cost: 5m · sonnet-5-5 24k in + 1.5M cached / 6k out
- 2026-11-25 — implemented round 3 (send-back from qc round 2): G1-G5 fixed in 078331a, build exit 0 · cost: 4m · sonnet-5-5 17k in + 1.4M cached / 4k out
