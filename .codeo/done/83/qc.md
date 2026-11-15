# Issue #83 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/83 |
| Branch | `feat/re-run-haiku-5-5` |
| Updated | 2026-11-15 |

## Where this stands

Round 1 is written. No blocking finding; the verdict is clear and the next step is `/codeo:close`. Nothing is open.

## Questions

None.

## Notes

No invariants document, no shared environment, no wiki module and no overlay rules are configured, so steps 6 (overlay part) and 9 do not apply. `overlap.sh 83` and `overlap.sh --outside 83` printed nothing.

## Outcome

### Round 1 — 2026-11-15

**Scope.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main` (exit 0; nothing new on `main`). Diff `origin/main...HEAD`: 9 files, 470 insertions, 2 deletions. Code under review: `skills/doctor/SKILL.md`, `skills/setup/SKILL.md`, `tests/closing-block.test.sh`, `CHANGELOG.md`; the rest is `.codeo/83/*` and the plan. `scope.sh origin/main HEAD` printed `suite.shell=true`, with `.codeo/83/*` and `CHANGELOG.md` listed as unclassified paths that need the suite.

**Build.** The `shell` suite's build `true` exited 0.

**Suites.** `bash tests/run.sh`: `all cases passed`, exit 0. `bash tests/closing-block.test.sh` alone, run by the reviewer: `all cases passed`.

**Acceptance criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| `skills/doctor/SKILL.md` and `skills/setup/SKILL.md` each tell the model to read the closing-block template with the Read tool | met | both files carry `Read the template with the Read tool, not with a Bash command.` at line 12 (`git show 2fc456e`); `tests/closing-block.test.sh:25-28` pins it for both and passed |
| A Haiku run and a Sonnet run are compared for each skill, naming what was compared and the result, and recorded on this issue | met | the comment https://github.com/kbajpai/codeo/issues/83#issuecomment-6887963022: six items, four cases, three runs per model, a per-case table, and the result; the reviewer checked its counts against each other and against #76's |
| A skill whose Haiku runs all matched has `model: haiku`; a skill with any miss keeps `model: sonnet`, and the issue says how it differed | met | `grep '^model:'` shows `sonnet` in both skills; each has a Haiku miss that is not the template read (`doctor-fail` run 3 item 5; `setup-refuse` run 1 item 1), and the comment says how each differed |
| `bash tests/run.sh` passes | met | `all cases passed`, exit 0, this round |
| `CHANGELOG.md` records the change, or the trial's result when nothing switched | met | `CHANGELOG.md:13` records the sentence, the guard test, the trial's result and the comment's link; its figures agree with the comment (finding F1 is about one clause of it) |

**Documentation.** The change moves no page under `docs/`, as the plan says: `docs/skills.md`'s `doctor` and `setup` sections say what each skill reports and do not name the tool that reads the template or the model, and stay true. `docs/handoff.md` is the template itself and is unchanged. `CHANGELOG.md` is the one page the change moves, and it states what the repository does (no "now", the issue number only in the closing parenthesis, as its other bullets do).

**Independent review** (Opus, `QC review:`, given the criteria and the range only). Plain-text verdict: ready to merge with fixes; no Critical or Important issue; two Minor findings, both on `CHANGELOG.md:13`, below as F1 and F2. It listed what it set aside: whether `doctor-fail` item 5 is a sound item, whether the rule should compare Haiku to Sonnet, whether the scorer should have excluded the `EXIT CODE`/`pwd` lines, the mangled `cd`, the raw streams, and the header comment of the test file; each is outside these criteria and was set by #76 and the issue.

**Findings**

- **F1 — non-blocking, `/codeo:implement`'s.** `CHANGELOG.md:13` says both skills stay on `sonnet` "because Haiku missed other items that Sonnet did not". For `setup` that holds; for `doctor` it does not, since the only real Haiku miss there (`doctor-fail` item 5) is one Sonnet missed in 2 of its 3 runs, as the same sentence's parenthesis says. The reason is also not the rule's: any Haiku miss keeps a skill on `sonnet`, whatever Sonnet did (the comment on #83 words it that way: "Haiku missed another checklist item in both skills"). The figures are right and the decision is unaffected; the clause should read "because Haiku missed other checklist items".
- **F2 — non-blocking, `/codeo:implement`'s.** `CHANGELOG.md:13` names the `setup-refuse` run 1 miss only as "two Bash calls"; that run also missed item 2, which makes four Haiku item-2 misses in all against the "three more" the bullet counts as artifacts. Nothing stated is false, and the comment and its table carry the full count.
- Footprint: `overlap.sh --outside 83` printed nothing; every changed path is inside the plan's footprint.
- Pre-existing, not a finding: `sync-main.sh` printed two `comm: … not in sorted order` warnings and exited 1 in the implement round (recorded in `implement.md`). Not part of this diff, and not filed by this pass.

No issue was filed by this pass.

The two findings are one-clause wording in a release note whose numbers are right, so neither blocks the merge; the engineer may fix them in this branch before `/codeo:close` opens the pull request, or let them go.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-15 — qc round 1: clear, two non-blocking findings (CHANGELOG.md:13 wording) · cost: 3m · opus-5-5 228k in + 1.1M cached / 9k out · sonnet-5-5 26k in + 638k cached / 1k out
