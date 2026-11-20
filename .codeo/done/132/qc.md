# Issue #132 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/132 |
| Branch | `fix/fix-test-suite-gaps-left` |
| Updated | 2026-11-20 |

## Where this stands

Round 1 is clear. Next step: `/codeo:close`.

## Questions

None.

## Notes

- Non-blocking (F1): `paragraph_contains_flat` (`tests/close-skill.test.sh:100-104`) splits paragraphs with awk's `RS=""`, which only breaks on truly empty lines, so a whitespace-only line between the stash and abandon paragraphs would merge them and let a pin be met by a neighbour again. Nothing in today's skill triggers it, and `awk -v` also interprets backslashes in an anchor (none today). Left for later work; no issue filed.

## Outcome

### Round 1 — 2026-11-20

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `merged origin/main (1 commit(s))`, no `also changed on` lines. `overlap.sh 132` printed nothing; `overlap.sh --outside 132` printed nothing. `git diff origin/main...HEAD --stat`: `tests/close-skill.test.sh` (+14 −2), `tests/role.test.sh` (+4 −2), the plan under `docs/plans/`, and the `.codeo/132/` dossiers. `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/132/implement.md ... plan.md
suite.shell=true
```

**Build and suite.** `shell` build is `true`: rc=0. `bash tests/run.sh`: rc=0, last line `all cases passed`, no `FAIL` line.

**Criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| #116's criterion 13 is checked off or struck, with the reason on the issue | met | `gh issue view 116`: line 50 reads `- [x] The rm -f -- "" check output is recorded on #107.`; #116's last comment gives the reason; #107's last comment holds `rc=0` |
| `both_markers_are_guarded_the_same` fails without the `/run/.containerenv` check, or is renamed | met (renamed) | `tests/role.test.sh:223` is `both_markers_present_is_guarded`, old name has no match in `tests/`; with the check removed in a scratch copy only `containerenv_alone_is_guarded` fails (17 FAIL lines, rc=1) |
| Each stash and abandon pin fails when only the other paragraph carries its text | met | `CLOSE_SKILL=` scratch copies: stash copy fails `a stash clears the signal with the lock`; abandon copy fails `an abandon clears the signal with the lock` |
| With a `.git/codeo-live-beat` present, `bash tests/live.test.sh` passes; with none, as before | met | `bash tests/live.test.sh` → `all cases passed` with `.git/codeo-live-beat` present, and again with it moved aside |
| No stamp assertion tests a relative `--git-path` result against the cwd | met | all three `--git-path` calls (`tests/live.test.sh:229`, `:236`, `:374`) carry `--path-format=absolute`; 0 lack it |
| "no lock", "base" and "clear" cases still fail when the clone's stamp exists / is not deleted | met | scratch `live.sh`: deleting `rm -f "$(stamp)"` fails `stamp gone`; writing the stamp at the top of `beat` fails `no lock: stamp` and `base: stamp` (and `beat_is_throttled_and_force_is_not`) |

**Documentation.** The plan says the change moves no page and no changelog entry. Checked: the diff changes two test files only; no behaviour, interface, key or flow changes, so no page under `docs/` describes anything it alters.

**Review.** Independent reviewer (opus, `QC review:`) given the criteria and the diff only: all six criteria met by its own mutation checks; Critical none, Important none, Minor F1 above.

**Findings.** F1 — non-blocking, `/codeo:implement`'s if ever picked up (a hardening of the helper). No blocking finding. No issue filed.

**Environment.** No shared environment is configured; not applicable.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-20 — qc round 1: build and suite pass, six criteria met, clear · cost: 6m · opus-5-5 231k in + 2.3M cached / 14k out · sonnet-5-5 172k in + 639k cached / 826 out
