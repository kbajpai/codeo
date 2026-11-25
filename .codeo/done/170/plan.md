# Issue #170 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/170 |
| Branch | `docs/docs-say-codeo-host-command` |
| Updated | 2026-11-25 |

## Where this stands

Round 2 planned and approved; the plan is `docs/plans/2026-11-25-codeo-host-command-docs-170.md`, modified and unstaged for the engineer to commit. Next step: `/codeo:implement`.

## Questions

### Q1 — Where does the keychain note live?

**Why it matters:** it decides which file the task edits and what the README sentence says. `codeo home` and the Docker build are documented in `.devcontainer/README.md`; the macOS paragraph is in `README.md` (*The home checkout*, line 212).
**Options:** (a) the full note in `.devcontainer/README.md`, beside *Installing the `codeo` command*, and one sentence in the README's macOS paragraph that points to it — my recommendation, because that is the page a Mac user is on when the build fails · (b) the full note in the README's macOS paragraph only · (c) the full note in both.

**Answer:**
(a) Full note in `.devcontainer/README.md`, one pointer sentence in the README's macOS paragraph. The engineer said "go with your picks" in the conversation.

### Q2 — What is the error text to quote?

**Why it matters:** the criterion asks for "the keychain error text", and the issue quotes it with an ellipsis: `error getting credentials ... keychain cannot be accessed because the current session does not allow user interaction`. I cannot reproduce it here (Linux container), and the part before the ellipsis differs between Docker versions.
**Options:** (a) quote only the stable part, `keychain cannot be accessed because the current session does not allow user interaction`, and say it follows `error getting credentials` — my recommendation · (b) quote the whole line: paste it here as your terminal printed it.

**Answer:**
(a) Quote only the stable part and say it follows `error getting credentials`. The engineer said "go with your picks" in the conversation.

### Q3 — Does the note also offer dropping `credsStore` from `~/.docker/config.json`?

**Why it matters:** the issue's *Key Requirements* name it ("with its trade-off"), the acceptance criteria do not, and *Out of Scope* excludes macOS behaviour not yet verified. With it, the note gains a second remedy and a sentence on the trade-off (registry logins are then kept unencrypted in `config.json`); without it, the note is the unlock command alone.
**Options:** (a) include it — say so only if you ran it and the build then passed · (b) leave it out; the unlock command is the one documented remedy — my recommendation unless you verified it.

**Answer:**
(b) Leave `credsStore` out; the unlock command is the one documented remedy. The engineer said "go with your picks" in the conversation.

### Q4 — Is the "host is Linux" sentence in `.devcontainer/README.md` corrected here?

**Why it matters:** the new README line links to *Installing the `codeo` command*, whose first paragraph (line 96) says "The host is Linux with bash 4.3 or later, `curl`, `git` and `flock` (util-linux)". The README says the command works on macOS. A Mac user who follows the new link reads that their host is not supported. Fixing it adds one task: the sentence names Linux and macOS, and Homebrew for bash and `flock` on macOS (sandboxes stay Linux and WSL2 only, as `.sbx/README.md` says).
**Options:** (a) correct it in this issue — my recommendation · (b) leave it; I record it under `## Notes` for `/codeo:triage` to file.

**Answer:**
(a) Correct the "host is Linux" sentence in this issue. The engineer said "go with your picks" in the conversation.

### Q5 — Are the new sentences pinned by a test?

**Why it matters:** no test pins the README's macOS paragraph or the *Installing* prose today, so "doc-pin tests updated" is met by changing none. A pin adds one task and a case in `tests/install.test.sh`: the README names `brew install flock`, the unlock command, and a link whose target heading exists in `.devcontainer/README.md`. Without one, each task's proof is a `grep` the task names plus `bash tests/run.sh`.
**Options:** (a) add the pin case — my recommendation; it is how this repository keeps a README claim from drifting, and it checks the link's anchor · (b) no new test.

**Answer:**
(a) Add the pin case in `tests/install.test.sh`. The engineer said "go with your picks" in the conversation.

### Q6 — #171 moved the macOS paragraph out of `README.md`; where does `brew install flock` go?

**Why it matters:** criterion 2 says "the README's macOS paragraph", and that paragraph is at `docs/home-checkout.md:22` since #171 merged. It decides whether Task 2 edits `docs/home-checkout.md`, `README.md`'s *Requirements*, or both.
**Options:** `docs/home-checkout.md` only, reading criterion 2 as that paragraph (recommended) · both pages · `README.md` *Requirements* only.

**Answer:**
`docs/home-checkout.md` only. The engineer chose it with the question tool in the conversation.

## Notes

- Verified in the repo: `install.sh` installs the two plugins only; `.devcontainer/codeo` calls `flock` (line 159) and prints the `PATH` line from `codeo help`; the install line for the command is at `.devcontainer/README.md:101`.
- `security -v unlock-keychain ~/Library/Keychains/login.keychain-db` is the command from the issue; it is written as the issue gives it.

## Outcome

Plan: `docs/plans/2026-11-25-codeo-host-command-docs-170.md` (approved by the engineer; left unstaged).

**Shape.** A scoped, executable plan under `$PLANS`; no reference doc, because there is no architectural choice to keep.

**Decisions** (Q1-Q5, all answered "go with your picks"): the full keychain note lives in `.devcontainer/README.md` with one pointer sentence in the README's macOS paragraph; the error text is quoted from the stable part only; no `credsStore` remedy (not verified); the "host is Linux" sentence of *Installing the `codeo` command* is corrected in this issue; one new pin case in `tests/install.test.sh`.

**Rejected:** the full note in the README only, or in both pages; quoting the whole error line with its Docker-version-dependent prefix; the `credsStore` remedy; leaving the Linux-only sentence for triage; no test pin.

**Documentation the plan changes:** `README.md` (*Installing*, *The home checkout* macOS paragraph) and `.devcontainer/README.md` (*Installing the `codeo` command*, new *The keychain over SSH on macOS*). No `CHANGELOG.md` entry (no Unreleased block; #168 owns the release notes). No intake question was resolved here, and no `/codeo:issue` was filed.


### Round 2
2026-11-25

Plan: `docs/plans/2026-11-25-codeo-host-command-docs-170.md`, rewritten in place before any task ran (approved by the engineer; the file stays as `git diff` shows it). `/codeo:implement` stopped at its first step: its base merge brought in #171, which moved the macOS paragraph to `docs/home-checkout.md` and added `tests/readme.test.sh`.

**Decisions:** Q6 (answered in conversation): `brew install flock` and the keychain pointer go in `docs/home-checkout.md` only, and criterion 2 is read as that paragraph. The pin moves from `tests/install.test.sh` to a new `host-command` check in `tests/readme.test.sh`. `README.md` gains only the *Installing* paragraph; `.devcontainer/README.md` is unchanged from round 1 (host sentence, new keychain subsection).

**Rejected:** editing `README.md`'s *Requirements* as well, or instead.

**Documentation the plan changes:** `README.md` (*Installing*), `docs/home-checkout.md` (*The home checkout*), `.devcontainer/README.md`. No intake question was resolved and no `/codeo:issue` was filed.

### Footprint

```
files:      README.md, docs/home-checkout.md, .devcontainer/README.md, tests/readme.test.sh, docs/plans/2026-11-25-codeo-host-command-docs-170.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-25 — Q1-Q5 raised · cost: 1m · fable-5-2 65k in + 455k cached / 3k out
- 2026-11-25 — planned: docs/plans/2026-11-25-codeo-host-command-docs-170.md · cost: 5m · fable-5-2 75k in + 643k cached / 7k out · sonnet-5-5 91k in + 686k cached / 10k out
- 2026-11-25 — re-planned after #171 moved the macOS paragraph: docs/plans/2026-11-25-codeo-host-command-docs-170.md · cost: 4m · fable-5-2 139k in + 830k cached / 9k out · sonnet-5-5 26k in + 138k cached / 950 out
