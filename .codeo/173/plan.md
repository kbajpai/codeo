# Issue #173 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/173 |
| Branch | `docs/173-close-161-leftovers-release-checklist` |
| Updated | 2026-11-25 |

## Where this stands

Round 1. The code and text the issue names are read (line numbers below are today's; the README restructure of #171 moved the issue's). Three choices change what the plan's tasks are, Q1-Q3; nothing is drafted until they are answered. No other workflow is in flight (`inflight.sh --except 173`), so there is no overlap to ask about yet.

## Questions

### Q1 — When `docker stop` fails after a refusal, does `codeo rm` say so, or is it only documented?

**Why it matters:** it decides whether `.devcontainer/codeo` changes. Today `stop_started` (`.devcontainer/codeo:477-480`) discards a failing `docker stop`, so a refused `codeo rm` can leave a container it started running and print nothing about it. The issue's key requirement reads "never leaves a container `codeo` started running without saying so", and intake Q2 left the choice to this step.

**Options:**
- **report (recommended)** — `stop_started` prints one line on stderr when the stop fails, `codeo: could not stop codeo-<N> again; it is left running`, before the refusal's own line. The exit status and the refusal text do not change (stderr, because `container_check`'s stdout is the captured report). A new case in `tests/codeo-command.test.sh` makes the `docker stop` stub fail and pins the line; the README paragraph and the v1.0.9 #154 bullet then say "stops it again, and says so when the stop fails". About five lines of code.
- **document only** — no code change; the README and the #154 bullet say a failing stop is ignored and the container may be left running, and a test pins that silence. Cheaper, but it meets the acceptance criterion while missing the key requirement's "without saying so".
- **fail harder** — a failed stop changes the exit status or the message of the refusal. I would not: the command already exits non-zero on a refusal, and "Redesigning the `codeo rm` check" is out of scope.

**Answer:**
Report it, as recommended. Given in the session's question dialog on 2026-11-25 and recorded here.

### Q2 — Should the install hook stop running on `clear` and `compact`, or should the page say it runs there?

**Why it matters:** it decides whether `.claude/settings.json` changes and what `tests/live-signal.test.sh` asserts about the second `SessionStart` group. The group has no `matcher` today, so the hook runs on every `SessionStart` source; with the plugins present it exits at the skip check, without them it runs `install.sh` (up to the 300-second timeout) in the middle of a `/clear` or a compaction.

**Options:**
- **add a matcher (recommended)** — give the group `"matcher": "startup|resume|fork"`, the same value the session-title group beside it carries, so one file has one spelling. The test asserts the matcher.
- **`startup` only** — the narrowest: a resumed or forked cloud session whose plugins went missing is not repaired until the next new session.
- **leave it and document it** — no settings change; the page says the hook also runs on `clear` and `compact` and is a no-op there once both plugins are installed.

Either way the skip check itself is fixed (that part of the criterion has no "or"): it reads `claude plugin list --json` with `jq`, as `install.sh` does, skips only when `codeo@codeo` and some `superpowers@*` are both installed *and enabled* at user scope, and otherwise runs `install.sh`, which enables a disabled one. A new test case runs the hook against a stubbed `claude` for: both present, `superpowers` from another marketplace, codeo disabled, one missing, and `CLAUDE_CODE_REMOTE` unset. My call, unless you object: the hook is described in `CONTRIBUTING.md` (it is this repository's own session setup, not something the plugin ships to adopters), with a `CHANGELOG.md` bullet under `## Unreleased`.

**Answer:**
`"matcher": "startup|resume|fork"`, as recommended. Given in the session's question dialog on 2026-11-25 and recorded here. No objection was raised to describing the hook in `CONTRIBUTING.md`.

### Q3 — In a hosted session, do `/codeo:*` commands load in the same session the hook installs them in?

**Why it matters:** the hook's comment says it installs the plugins "so /codeo:* commands load", and `README.md:48` says sessions already open need a restart. QC recorded this (F8) as "plausible, not verified at runtime", and I cannot verify it here: this session runs in a container, not a hosted one. The answer is the sentence the comment and `CONTRIBUTING.md` will carry.

**Options:**
- **you have seen it: they load in the same session** — the comment and the page say a `SessionStart` hook finishes before the session lists its commands, so the first session has them; the README's restart sentence is narrowed to sessions that were open *before* the install.
- **you have seen it: they load only in the next session** — the comment and the page say the first hosted session of a fresh environment installs the plugins and the commands appear from the next session (or after a resume).
- **not known, word it without the claim (my pick if you have not seen either)** — the comment says only what the hook does ("installs both plugins when either is missing or disabled") and points at the README; the page says that if `/codeo:*` commands are not listed after the hook ran, start a new session. Both texts then agree and neither asserts what nobody checked.
- **verify first** — the plan gains a task you run in a fresh hosted session (`Runs on:` a web session) and the wording follows its result; the work waits for that run.

**Answer:**
Not known; word it without the claim. Given in the session's question dialog on 2026-11-25 and recorded here.

## Notes

**Decided without a question** (say so under any answer if one is wrong):

- **Shape.** One plan under `docs/plans/`, one pull request; no reference doc, since nothing here is a standing decision. No overlay sets a plan shape, so it follows `docs/plans/2026-11-24-documentation-leftovers-154-146-161.md`.
- **Released changelog sections are corrected in place.** The #154 bullet now sits under `## v1.0.9` (`CHANGELOG.md:27`) and the `## Outcome` sentence in the v1.0.8 `Shared state:` line (`:33`); both shipped since the issue was written. They are edited where they stand, and a `## Unreleased` bullet says they were corrected, as v1.0.8's #108 bullet did for v1.0.7. The GitHub release notes and the tags are not touched, as in #161.
- **The v1.0.8 line's correction**, checked against the tags: at v1.0.7 `dossier-check.sh` matched the heading or the heading plus a space (`$3 == name || index($3, name " ") == 1`), so only `## Outcome notes` stopped counting there; `inflight.sh` and `qc-verdict.sh` had `/^## Outcome/`, so `## Outcomes` and `## Outcome notes` both stopped counting there.
- **Release checklist step 6**, from `tests/install.test.sh` and `README.md` today: the `v1.0.9` examples and stubs move to the release being cut; the `--version v1.0.8` example (`README.md:101-104`), the `v1.0.8 -> v1.0.9` replace line (`:534`) and the older-tag stubs (`v1.0.8`) move to the one before it; the ordering stubs (`v1.0.5`, `v1.0.10`, `v1.0.9.1`, `v2.0.0-rc1`, `v9.9.9`) do not move. The implementer confirms each group against the test before writing the sentence.
- **README flowchart and paragraph** (`.devcontainer/README.md:197, 214-216`): "was running" becomes "not started by `codeo` as far as it knows (running, or `docker ps -a` failed)", and "A container that `codeo` started itself is read once" becomes "knows it started", since with no listing `started` stays 0 and the container is restarted and read twice.
- **Proof of done** for every task is the `shell` suite (`bash tests/run.sh`; it has no single-test filter).

### Footprint

```
files:      .devcontainer/codeo, .devcontainer/README.md, .claude/hooks/session-start.sh, .claude/settings.json, tests/codeo-command.test.sh, tests/session-start-hook.test.sh, tests/live-signal.test.sh, CONTRIBUTING.md, CHANGELOG.md, docs/release-checklist.md, docs/plans/2026-11-25-close-161-leftovers-173.md, .codeo/173/**
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-25 — Q1-Q3 raised · cost: 1m · fable-5-2 72k in + 382k cached / 4k out
