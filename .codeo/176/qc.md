# Issue #176 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/176 |
| Branch | `feat/176-support-sbx-issue-sandbox-macos` |
| Updated | 2026-11-25 |

## Where this stands

Round 1 is written and routed back to `/codeo:implement`. The build and the full suite pass and six of
the seven criteria are met; criterion 3's `codeo open` clause has no evidence, and a few
documentation and test findings ride along with it. Nothing here needs the engineer's answer before
the verdict, so there are no questions.

## Questions

None.

## Notes

- Reviewed head `c7fda93` against merge base `d097737`. `sync-main.sh --abort-on-conflict`: "the branch
  already contains origin/main". `overlap.sh 176`: nothing printed, exit 0. `overlap.sh --outside 176`:
  nothing printed, exit 0, so every changed path is inside the plan's footprint.
- `scope.sh origin/main HEAD`: `suite.shell=true` (needed for unclassified paths: `CHANGELOG.md` and the
  four `.codeo/176/*.md` files). No environment is configured, so there is no `deploy=` line and no
  environment block.
- The project's QC overlays (`invariants-extra`, `wiki-rules`) are not defined (exit 3); no invariants
  file is configured. The reviewer worked from the acceptance criteria and the diff alone.
- The independent reviewer ran on `opus` with a description starting `QC review:`.

## Outcome

### Round 1 — 2026-11-25

**Commands run, with their real output**

```
$ true                                   # the shell suite's build command
exit 0
$ bash tests/run.sh                      # the shell suite's test command, run whole
all cases passed
suite exit=0
$ grep -rIn 'never macOS' README.md .sbx .devcontainer docs/*.md
(no output, exit 1)
$ bash -n .sbx/codeo-sandbox.sh
(no output, exit 0)
```

The diff touches `tests/sandbox.test.sh` and the sandbox script's behaviour, so the shell suite ran
whole, not through a filter.

| Criterion | Verdict | Settled by |
|---|---|---|
| A recorded check says whether sbx runs on macOS, on what hardware and macOS version, with the install command and what it needs | met | `docs/dev-environment-sbx-evaluation.md` *Host* (macOS 27.2.1, `arm64`, `brew trust docker/tap` and `brew install docker/tap/sbx`, what Docker's page lists) and trial T14; test `docs_evaluation_page_records_the_macos_check` |
| On a Mac with sbx installed, `codeo issue <N> --sandbox` starts a sandbox, takes the lock and adds the `sandbox` row | met | T14: "✓ Created sandbox codeo-176", `lock: took the lock for #176 …`, the sandbox's `.codeo/active` holding `sandbox: codeo-176`, the tracking row `sandbox │ codeo-176 │ mac-studio.lan │ active`. Run through the `--yes` confirmation because #176's own dev container existed; a clean issue was not shown |
| On the same Mac `codeo shell` and `codeo open` open the sandbox, `codeo list` shows it, and `codeo rm` removes it and marks the row `removed` | not met — `codeo open` not shown; `shell` and `list` shown, `rm` shown only by the `removed` row | T14: `list` printed `#176  sandbox  detached`; `shell` printed the sandbox prompt; the row reads `removed` (2026-11-25T20:48) and a later `rm` said "no sandbox codeo-176". `codeo open`'s output was never captured, and the only recorded `open` ran after the removal (F1) |
| `codeo-sandbox.sh` runs under bash 4.3 or later without a Linux-only command; what it needs beyond Linux's requirements is named in the README | met | no GNU-only command in the script (`date -u`, `head`, `tail`, `grep -c`, `tr`, `uname -s`, `xcode-select`), `bash -n` clean, no bash 4-only feature; ran on Homebrew bash 5.3.20 (4.3 itself not run). `.sbx/README.md` *On macOS* names Homebrew bash, `flock`, `code` on `PATH` |
| With `sbx` missing on macOS, the error names where to install sbx | met | `.sbx/codeo-sandbox.sh:80-82`; tests `no_sbx_on_macos_names_the_brew_install`, `no_sbx_off_macos_keeps_the_wsl2_message`, `codeo_sbx_on_macos_skips_the_message`, `a_failing_uname_is_not_macos`; suite passes |
| "never macOS" appears in no README or script comment, and each says what macOS needs | met | the grep above; tests `docs_nothing_says_never_macos`, `docs_sbx_readme_says_what_macos_needs`; `.sbx/README.md`, `.devcontainer/README.md`, the script header and `.devcontainer/codeo`'s header name macOS |
| `bash tests/run.sh` passes, with the sandbox tests updated for the changed message and wording | met | `bash tests/run.sh`: "all cases passed", exit 0 |

**Documentation check.** The plan names `.sbx/README.md`, `.devcontainer/README.md`,
`docs/dev-environment-sbx-evaluation.md` and `CHANGELOG.md`, and the diff changes all four. The claim
that the root `README.md` and `docs/home-checkout.md` need nothing is true: neither mentions a sandbox.
The `#the-keychain-over-ssh-on-macos` anchor resolves to `.devcontainer/README.md:136`. The README text
is accurate to the code and to T14, with the exceptions in F2-F8. `.sbx/README.md`'s one Mermaid change
is a participant label.

**Independent review** (opus, `QC review:`): no Critical issues. Linux and WSL2 behaviour is unchanged
(the macOS branches sit in the final `else` of `pick_sbx` and `launch_code`, and `git_is_usable` reduces
to the old `command -v git` off macOS); the new tests check real behaviour and the macOS cases stub
`uname` and `xcode-select`. The reviewer ran the 17 new and touched cases in a scratch copy: all passed.

**Findings**

- **F1 — blocking — `/codeo:implement`'s.** Criterion 3's `codeo open` clause is not shown. The Mac
  run's `open` output was not captured and the engineer did not say whether VS Code opened; the only
  recorded `codeo open` ran after the sandbox was removed. The docs are honest about it (`.sbx/README.md`
  *On macOS* last bullet, T14 *Not shown*, the CHANGELOG bullet), so nothing is mis-stated; the criterion
  itself is unproven. What it needs is evidence from the Mac: `codeo issue 176 --sandbox --yes`, then
  `codeo open 176 --sandbox`, then `codeo rm 176 --sandbox`, each output pasted, then T14 and the README's
  untried bullet updated from it. If the engineer decides instead to accept the gap, that is their call
  to record in `implement.md`, and the next QC pass judges the criterion with it stated.
- **F2 — non-blocking — `/codeo:implement`'s.** `.sbx/README.md:9`, `:42` and the login bullet describe
  what the trial found, not what the system needs: "the Windows trial and the Linux and WSL2 text used
  v0.53.0; Homebrew installed v0.54.1 on the checked Mac", "macOS was checked with Homebrew bash
  5.3.20 …", "which did not block anything". The old line said "`sbx` v0.53.0"; the new one no longer
  tells a Linux user which version is supported. State the requirement in the present tense and leave
  what was checked to T14.
- **F3 — non-blocking — `/codeo:implement`'s.** On a Mac without the Command Line Tools,
  `ensure_host_clone` runs `git clone` before `git_is_usable` is ever read, so `issue` stops at the
  clone, not at the identity fallback the CHANGELOG bullet describes. Add one line to *On macOS* saying
  git needs the Command Line Tools (`xcode-select --install`; Homebrew installs them), and drop or
  qualify the fallback clause in the CHANGELOG.
- **F4 — non-blocking — `/codeo:implement`'s.** `tests/sandbox.test.sh`,
  `open_on_macos_without_code_is_one_line`: it removes only the `code` stub, but `PATH` keeps `/usr/bin`,
  where a VS Code package installs `/usr/bin/code`; on such a Linux desktop the case runs the real
  `code` and fails. It passes in this container and on a Mac.
- **F5 — non-blocking — `/codeo:implement`'s.** Two *On macOS* bullets are true on every host, not
  only on a Mac: the `--sandbox` flag when a container of the same number exists
  (`.devcontainer/codeo:300`), and the git-identity `TODO`. Listed as macOS additions they read as
  Mac-only; move them to the general text or say "on any host".
- **F6 — non-blocking — `/codeo:implement`'s.** `docs/dev-environment-sbx-evaluation.md`, T14's *Differed
  from the plan* says the commands "were wrong in two ways" and then lists three.
- **F7 — non-blocking — `/codeo:implement`'s.** `CHANGELOG.md:9` says the script "checks for `sbx` and
  `code` there"; it checks for `sbx` on every host and only the message differs on macOS. The
  "macOS 14 or later on Apple silicon" rests on Docker's page; only macOS 27.2.1 on `arm64` was run.
- **F8 — non-blocking — `/codeo:implement`'s.** `.sbx/README.md` *Prerequisites* lists the
  `sbx policy allow network …` step before any policy exists and names `sbx policy init balanced` only
  as a condition; a reader following the list in order meets the 412. Make it a step.

Out of scope, noted once: `.devcontainer/codeo`'s `readlink -f` in `codeo update` predates this change and works
on macOS 12.3 or later; the plan 2026-11-17 keeps "never macOS" as a record.

No issue was filed. The shared environment is not configured, so no lease was checked or released.

**Verdict: back to `/codeo:implement`.**

## Log

- 2026-11-25 — qc round 1: build and suite pass, criteria 1-2 and 4-7 met, criterion 3 not met (codeo open not shown), 8 findings, back to implement · cost: 5m · opus-5-5 446k in + 3.3M cached / 21k out · sonnet-5-5 38k in + 1.5M cached / 918 out
