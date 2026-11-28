# Issue #181 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/181 |
| Branch | `feat/181-session-title-prefix-session-id` |
| Updated | 2026-11-28 |

## Where this stands

Round 1, done. The build and the full suite pass, every acceptance criterion is met, and nothing blocks the merge. Four non-blocking findings are recorded below. Next step: `/codeo:close`.

## Questions

None.

## Notes

- Non-blocking, to be filed once the dossier is archived (`/codeo:triage` collects them): tighten `seq_file` in `.devcontainer/scripts/session-title.sh` (its relative-path fallback joins the work-tree root to a path that `git -C <scripts dir> rev-parse --git-path` gives relative to `.devcontainer/scripts`, and `--path-format=absolute` needs git 2.31); reword the README, the changelog bullet and the header so they say the old shape is the fallback only for a session that carries no number of its own.

## Outcome

### Round 1 — 2026-11-28

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 181`: nothing printed, exit 0. `overlap.sh --outside 181`: nothing printed, exit 0 (every changed path is inside the footprint). `git diff origin/main...HEAD --stat`: 8 files, 749 insertions, 37 deletions (`.codeo/181/*`, `.devcontainer/README.md`, `.devcontainer/scripts/session-title.sh`, `CHANGELOG.md`, the plan, `tests/devcontainer.test.sh`). `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/181/implement.md
  .codeo/181/init.md
  .codeo/181/plan.md
  CHANGELOG.md
suite.shell=true
```

No environment is configured, so there is no `deploy=` line and no `#### Environment` block.

**Build.** Suite `shell`, build command `true`: exit 0.

**Tests.** Suite `shell`, `bash tests/run.sh` (the whole suite; it has no single-test filter): `all cases passed`, `test exit=0`, 1m10s, no `SKIP` line.

**Acceptance criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| A new session is titled `<window title> · <NN>-<id8>`, and the next new session gets `<NN>` plus one | met | `session_title_names_home_and_the_id`, `session_title_numbers_sessions_in_order` (`00`, `01`, `02`); `.devcontainer/scripts/session-title.sh:124-131` |
| `/clear` and a fork each take the next number, and `claude --resume` keeps its number | met — see finding F1 for the one caveat | `session_title_clear_and_fork_take_the_next_number`, `session_title_on_a_prompt_after_clear`, `session_title_resume_keeps_its_number`, `session_title_resume_does_not_reuse_a_number`, `session_title_keeps_a_sessions_number` |
| After `FF`, the next session gets `00` | met | `session_title_wraps_after_ff`; `session-title.sh:71` (`% 256`) |
| The count carries over a container restart; `codeo-home` and `codeo-<N>` count independently | met — no test restarts a container, but every test run is a new process reading the ledger on disk | `session_title_counts_per_clone`, `session_title_trims_the_ledger`; ledger path `session-title.sh:33` (the clone's git directory) |
| A lock change retitles `codeo [home] · <NN>-<id8>` to `codeo [#<N>] · <NN>-<id8>` with the same `<NN>` | met | `session_title_lock_change_keeps_the_number`, `session_title_replaces_its_own_title_when_the_lock_changes` |
| A `/rename`d title is never changed; an old-shape `codeo [home] · <id8>` title is retitled to the new shape | met | `session_title_keeps_a_renamed_title` (five silent cases, and no ledger is created), `session_title_moves_an_old_shape_title` |
| Two sessions started at once in one container get different numbers | met | `session_title_concurrent_starts_get_different_numbers` (eight parallel runs, `00`-`07`); `flock -w 2` at `session-title.sh:52-53` |
| `CHANGELOG.md` and `.devcontainer/README.md` describe the new shape, and `bash tests/run.sh` passes with `tests/devcontainer.test.sh` covering the cases above | met | `.devcontainer/README.md:84`, `CHANGELOG.md:3-9`; the suite run above; one test per case above |

**Documentation.** The behaviour that changed is the session title. `.devcontainer/README.md` (the session-title bullet) and the `## Unreleased` section of `CHANGELOG.md` describe it, in present tense; the README carries no issue number, "now" or history, and the plan's claim that `docs/container-templates.md` does not move holds (it lists `session-title.sh` only as a file copied as it is). The one gap is F2 below. The project has no documentation overlay and no wiki module.

**Independent review.** `QC review:` dispatch on opus with the criteria alone. Its assessment, in plain text: "Ready to merge? With fixes", with no Critical finding and one Important finding, which this round rules on at F1. It reproduced a case by hand in a scratch repository and found nothing else that fails a criterion.

**Findings.**

- **F1 — non-blocking, `/codeo:implement`'s.** `session-title.sh:120`: a `SessionStart` with `source: "resume"` and a new session id keeps the number in the inherited title, so a session forked under `source: "resume"` would repeat its parent's number (reproduced by the reviewer with a hand-made input). The reviewer rated it Important on the belief that `--fork-session` sends `resume`. The hooks reference says otherwise: `source` is `"fork"` for "`--fork-session` with `--resume` or `--continue`, the `/fork` background copy, `/branch`", and `"resume"` is `--resume`, `--continue` or `/resume`; the suite covers `source: "fork"` (`session_title_clear_and_fork_take_the_next_number`). The page does not say whether a plain resume keeps the session id; if it does, the `source == resume` rule is never reached and is harmless, and if it does not, the rule is what makes a resume keep its number. Evidence was read through a fetch that returned the first part of the page verbatim and the rest as a summary. Not blocking because the documented behaviour matches the code; a future change to `source` values would show up as a repeated number, never a crash or a stderr line.
- **F2 — non-blocking, `/codeo:implement`'s.** `.devcontainer/README.md:84` and `CHANGELOG.md:9` say that when the counter cannot be used the title is the old shape. The code keeps a session's own number when its title already carries one (`session-title.sh:121`, `nn=$(seq_take …) || nn=$own_nn`; `session_title_falls_back_to_the_old_shape` relies on it). The sentence needs "unless the session already carries its own number".
- **F3 — non-blocking, `/codeo:implement`'s.** `session-title.sh:31-40` (`seq_file`): the relative-path branch joins `--show-toplevel` to a path git gives relative to `.devcontainer/scripts`, and `--path-format=absolute` needs git 2.31. The image has git 2.53 (`git version 2.53.0` here), where the output is always absolute and the branch is not reached, so nothing fails today.
- **F4 — non-blocking, `/codeo:implement`'s.** `session-title.sh:22`: the header says the next fresh session "still follows the highest number"; after a wrap it follows the last number given out.

Left alone from the build round, already recorded in `implement.md`: no test holds the lock for over 2 seconds, a ledger path that is a directory falls back through a later failure, and `<id8>` is not defined in the README or changelog prose.

No issue was filed by this pass.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-28 — qc round 1: clear, 4 non-blocking findings · cost: 3m · opus-5-5 284k in + 2.2M cached / 16k out · sonnet-5-5 236k in + 506k cached / 2k out
