# Issue #34 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/34 |
| Branch | `chore/describe-every-codeo-skill-docs` |
| Updated | 2026-11-07 |

## Where this stands

Round 1 complete: no blocking finding. Verdict: clear, forward to `/codeo:close`. Next: `/codeo:close`.

## Questions

None.

## Outcome

### Round 1 — 2026-11-07

**Commands and output.**
- `sync-main.sh --abort-on-conflict`: "the branch already contains origin/main". `overlap.sh 34`: nothing. `overlap.sh --outside 34`: nothing.
- `scope.sh origin/main HEAD`: `suite.shell=true` (unclassified paths: docs, README, CHANGELOG, workflow records).
- Build, suite `shell`: `true` — exit 0.
- `bash tests/skills-doc.test.sh`: `all cases passed`. `bash tests/run.sh skills`: `all cases passed`.
- `bash tests/run.sh` on the branch (7291a24): exit 1, `failed: board.test.sh branch-name.test.sh claim.test.sh close-skill.test.sh dossier-check.test.sh env.test.sh github.test.sh intake-lease.test.sh intake.test.sh overlap.test.sh overlay.test.sh replay.test.sh scope.test.sh`.
- Same command on a detached worktree of `origin/main`: exit 1, the identical list of 13 files. The change adds no failure. The diff touches no script, hook or `lib/` file, and the failures are the Windows CRLF ones.
- Negative proof, on a temp copy of the repo with `skills/zzz/SKILL.md` added: `bash tests/run.sh skills-doc` printed `FAIL missing-section: zzz`, exit 1.

**Criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| `docs/skills.md` has a section for each of the nine skills | met | `tests/skills-doc.test.sh` passes against the real doc; nine `## ` headings |
| Each section states purpose and triggers, reads and writes, hand-offs and non-goals, extension points | met | guard enforces the four `###` parts per section; reviewer spot-checked content against the SKILL.md files and scripts |
| Extension points match the `point:` markers and `docs/extension-points.md` | met | guard compares each section to `lib/extension-points.tsv`; `tests/skills.test.sh` check 4 pins the registry to the markers and headings; anchors resolve |
| README links to `docs/skills.md` from its Skills section | met | `README.md:13` and nine `docs/skills.md#` links |
| README no longer calls the pipeline "six steps" in a way that conflicts with its table | met | Skills section separates the six pipeline skills from `triage`, `setup` and `doctor` (`README.md:13`) |
| `setup` summary mentions `docs/plans/`; `doctor` summary names its checks or says it checks the whole setup and links | met | `README.md:25-26` |
| A skill directory with no section makes `bash tests/run.sh` fail | met | negative run above |
| `bash tests/run.sh` passes | not yet checkable — fails locally on 13 files identically on main (Windows CRLF); CI on the pull request is the verdict | both full runs above |

**Documentation check.** `docs/skills.md` is new and `README.md`'s Skills section is changed; both match the code and scripts they describe. `docs/extension-points.md` and `docs/skills-inventory.md` are untouched, as scoped. No wiki module.

**Independent review** (opus). Plain-text assessment: ready to merge, no Critical or Important findings.

**Findings.**
- F1 non-blocking — `README.md:27`: the `doctor` list reads as exhaustive but omits `schema` and `codename`. Implement's. Routed: recorded.
- F2 non-blocking — `docs/skills.md` (doctor, Reads and writes): the reads list omits `lib/extension-points.tsv`, the installed-plugins file and the PATH checks. Implement's. Routed: recorded.
- F3 non-blocking — `docs/skills.md` (doctor): omits the `ci.requiredChecks` fallback to `tests` and `qc-verdict`. Implement's. Routed: recorded.
- F4 non-blocking — `docs/skills.md` (qc): "its own dossier commits and nothing else" omits the sync merge commit. Implement's. Routed: recorded.
- F5 non-blocking — the guard counts fenced lines inside an Extension points part, its missing/extra output order is nondeterministic, and one regex leaves the skill name unescaped. Implement's. Routed: recorded.
- No footprint finding; no issue filed.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-07 — round 1, clear · cost: 73m · opus-5-5 325k in + 2.7M cached / 14k out · sonnet-5-5 33k in + 1.9M cached / 4k out
