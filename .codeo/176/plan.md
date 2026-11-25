# Issue #176 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/176 |
| Branch | `feat/176-support-sbx-issue-sandbox-macos` |
| Updated | 2026-11-25 |

## Where this stands

Round 1. The plan is approved and written to `docs/plans/2026-11-25-sbx-sandbox-macos-176.md`
(unstaged): five tasks, two of them run by the engineer on the Mac over SSH (a preflight, then the
full route recorded as trial T14). The footprint is committed. Q5 is open only because Q4 did not
quote the overlaps in the form `overlap.sh` matches; the outcome is written once it is answered.

## Questions

### Q1 — Run the macOS trial now, before the plan is drafted, or as the plan's first task?

**Why it matters:** the issue is "check, then fix what fails", and what fails is not known yet.
With the trial first, the plan lists the real failures as tasks with tests, and the evaluation page
gets written from real output. With the trial as Task 1, every task after it is a guess: the plan
carries the fixes that can be read from the code (Notes), and anything else the trial shows comes
back to `/codeo:plan` as a second round.
**Options:** trial now, output pasted under this answer (recommended) · trial as the plan's first
task, re-plan if it shows more · no preference, you pick.

The trial, on the Mac, with the `codeo` command already installed there (each line is one command;
paste what each prints, or say where it stopped):

```
sw_vers
uname -m
bash --version
brew trust docker/tap
brew install docker/tap/sbx
sbx version
sbx login
sbx secret set github --command 'gh auth token'
sbx setup ssh
sbx policy allow network "*.gallery.vsassets.io,*.gallerycdn.vsassets.io"
codeo issue <N> --sandbox
codeo list
codeo shell <N>
codeo open <N>
codeo rm <N>
```

`<N>` is the issue Q3 settles. After `codeo issue`, the issue's tracking comment should show a
`sandbox` row, and after `codeo rm` the row should read `removed`: say whether each did. Inside
`codeo shell <N>`, `cat .codeo/active` shows the lock; paste it.

**Answer:**
Your pick (the engineer, in conversation, 2026-11-25).

My pick: the trial is the plan's first task, run by the engineer on the Mac, and the plan carries the
fixes readable from the code around it. Reason: the engineer answered without trial output, so a
trial "now" would stall planning again; Task 1 records `sw_vers` and `uname -m` first and the plan
stops there when the Mac is not on Sonoma 14 or later with Apple silicon, and whatever the trial
shows beyond the planned fixes comes back as a second planning round.

### Q2 — Which Mac is this, and do you run these commands at its screen or over SSH?

**Why it matters:** Docker lists macOS 14 (Sonoma) or later on Apple silicon only. An older macOS or
an Intel Mac means the plan is the fallback instead: a one-line refusal on macOS that names
`codeo issue <N>`, and docs that say why. SSH changes three steps. `sbx login` opens a browser for
Docker's sign-in, `sbx secret set github --command 'gh auth token'` may read the keychain (which
#170 documented as locked over SSH), and `codeo open` starts VS Code on the Mac's own screen, not on
the machine you sit at. If you work over SSH, the plan adds a README section for what must be done
at the Mac's screen once, and the acceptance check for `codeo open` is run there.
**Options:** none to pick from: the chip (or model and year), the macOS version, and "at the
screen", "over SSH from <what machine>", or "both".

**Answer:**
Over SSH (the engineer, in conversation, 2026-11-25). No chip or macOS version was given; Task 1
records both and is where the plan stops if the Mac is below Docker's minimum.

### Q3 — Which issue number does the trial sandbox use?

**Why it matters:** `codeo issue <N> --sandbox` adds a `sandbox` row to issue N's tracking comment
and takes the workflow lock in the sandbox's own clone. On #176 it finds this issue's container
already on record and asks before going on, which is itself one of the paths to check, and the row
lands on the issue it belongs to. On a scratch issue nothing touches #176, but the branch must hold
`.codeo/<N>/init.md` on origin for `codeo` to find it, so a scratch issue needs `/codeo:init` first.
**Options:** #176 itself, answering yes when it asks (recommended) · a scratch issue you name · no
preference, you pick.

**Answer:**
Your pick (the engineer, in conversation, 2026-11-25).

My pick: #176 itself, answering yes when `codeo issue` asks about the existing container.

### Q4 — #173 changes three files this plan changes: proceed, sequence after it, or re-scope?

**Why it matters:** #173 (branch `docs/173-close-161-leftovers-release-checklist`, assignee
kbajpai, step `plan`) lists `.devcontainer/codeo`, `.devcontainer/README.md` and `CHANGELOG.md` in
its footprint; this plan's Task 4 edits the first line of the `.devcontainer/codeo` header comment
(`Needs bash 4.3 or later on Linux` → `on Linux or macOS`), one sentence of
`.devcontainer/README.md`'s *Installing the `codeo` command* (the host sentence), and adds one bullet
under `CHANGELOG.md`'s `## Unreleased`. Three small edits in different lines merge cleanly unless
#173 edits the same lines; the `CHANGELOG.md` bullet is the likeliest to conflict, because both
branches append under the same heading. Sequencing after #173 would hold Task 4 until it merges;
re-scoping would drop the `.devcontainer/codeo` header edit (it is a comment only) and leave the
README sentence and the changelog bullet.
**Options:** proceed and coordinate (recommended: whichever merges second resolves the changelog
bullets by keeping both) · sequence after #173 · re-scope: drop the `.devcontainer/codeo` header
edit.

**Answer:**
Proceed and coordinate (the engineer, in conversation, 2026-11-25).

### Q5 — Does "proceed and coordinate" (Q4) stand for #173's overlaps, as `overlap.sh` prints them?

**Why it matters:** `overlap.sh` compares this plan's committed footprint with #173's
(branch `docs/173-close-161-leftovers-release-checklist`, assignee kbajpai, step `plan`) and prints
`173	glob:.devcontainer/README.md`, `173	glob:.devcontainer/codeo` and
`173	glob:CHANGELOG.md`. It treats a pair as raised only when a question quotes `#173` and the token
verbatim, which Q4 did not; Q4's answer was proceed and coordinate. If it stands, the plan's
outcome is written now with `sequenced:` left `none`; if you would rather sequence after #173 or
drop the `.devcontainer/codeo` header edit, Task 4 and the footprint change.
**Options:** proceed and coordinate, as Q4 (recommended) · sequence after #173 · re-scope: drop the
`.devcontainer/codeo` header edit.

**Answer:**
Your pick (the engineer, in conversation, 2026-11-25).

My pick: proceed and coordinate, as Q4. `sequenced:` stays `none`.

## Notes

**What Docker's install page says today** (https://docs.docker.com/ai/sandboxes/install/, read
2026-11-25; the evaluation read it on 2026-11-14 as Windows and Linux only):

- macOS: "macOS Sonoma version 14 or later", "Apple silicon". Intel Macs are not listed. No
  hypervisor step is named for macOS. "You don't need Docker Desktop or Docker Engine to use `sbx`."
- Install: `brew trust docker/tap`, then `brew install docker/tap/sbx`, then `sbx login`.
- Linux is Ubuntu 24.04 or later with KVM; Windows is Windows 11 on Intel or AMD with Windows
  Hypervisor Platform. Both as the evaluation recorded.
- The page says nothing about `sbx setup ssh` or the `*.sbx` hosts on any platform.

**What the code shows without a trial** (these go into the plan whatever the trial finds; they are
my calls, to be corrected at the review gate):

- `pick_sbx` (`.sbx/codeo-sandbox.sh:68-78`) gives one message on every platform. On Darwin it will
  name `brew install docker/tap/sbx` and the macOS 14, Apple silicon requirement; on Linux and WSL2
  the message stays as it is. `sbx_prog` in `.devcontainer/codeo` only reports absence and needs no
  change.
- `git_is_usable` in `codeo-sandbox.sh:205` says "a Mac stub" in its comment but does not check for
  one. `codeo-container.sh:147` does (`xcode-select -p` on Darwin). The sandbox script gets the same
  check, so reading the git identity never opens the Command Line Tools installer.
- The script calls nothing GNU-only: `date -u +%Y%m%dT%H%M%SZ`, `head -n`, `tail -n +2`, `grep -c`,
  `tr -d` are all in macOS's base system. It does not call `flock`; `codeo` does, and that is
  already documented for macOS (#170). `codeo update` calls `readlink -f`, which macOS has had since
  12.3, below sbx's own minimum.
- "never macOS" is in two places only: `.sbx/README.md:7` and `.sbx/codeo-sandbox.sh:3`.
  `.devcontainer/README.md:96` says "a sandbox needs Linux or WSL2", `.sbx/README.md`'s sequence
  diagram names "Linux or WSL2 bash", `tests/sandbox.test.sh:3` says "a Linux or WSL2 host", and
  `.devcontainer/codeo:4` says "on Linux". Each gets macOS added. The root `README.md` no longer has
  a macOS paragraph or any sandbox text (#171 rewrote it), so the issue's `README.md:204` reference
  is stale and the root README is left alone unless the trial shows it must say something.
- The recorded check goes into `docs/dev-environment-sbx-evaluation.md` as a macOS part of its
  `## Host` section and a new trial under `## Trials`, in the form the page already uses.
- One pull request. No shared environment and no exclusive resource is involved.

**Other workflows in flight:** #173 (`docs/173-close-161-leftovers-release-checklist`, kbajpai) was
at `init` when Q1-Q3 were raised and has since planned; its footprint overlaps this plan's on three
files, raised as Q4. No exclusive resource is configured, so none can overlap.

**The draft's decisions** (for the review gate; the file is `.codeo/176/plan-draft.md`):

- *Shape:* an executable plan under `docs/plans/`, no reference doc: nothing here is a standing
  decision. Rejected: a bash-version guard in the script, a refusal on Intel Macs when `sbx` is
  present, an `open -a` fallback for VS Code (each is untried or already covered by documentation).

## Outcome

2026-11-25

| | |
|---|---|
| Plan | `docs/plans/2026-11-25-sbx-sandbox-macos-176.md` (unstaged until the engineer commits it) |
| Shape | an executable plan under `docs/plans/`; no reference doc, since nothing here is a standing decision |
| Tasks | 5: engineer's preflight on the Mac (stops the plan below macOS 14 or off Apple silicon) · a macOS message for a missing `sbx` · git and `code` checks on macOS · the docs and "never macOS" removed · the full route on the Mac, recorded as trial T14 |

**Decisions.**
- Docker's install page now lists macOS 14 or later on Apple silicon, installed with `brew install docker/tap/sbx`, so the work is a check plus small fixes, not a port.
- The Mac trial is the plan's first task, not run before drafting (Q1, the engineer's pick left to this skill): the engineer answered without trial output. A failure the full-route trial shows beyond the planned fixes returns to `/codeo:plan` as a second round.
- The engineer works over SSH (Q2); the chip and macOS version are recorded by Task 1, and the docs mark each SSH statement untried until Task 5 replaces the mark with what T14 showed.
- The trial uses #176 itself (Q3, the engineer's pick left to this skill).
- Overlap with #173 on `.devcontainer/codeo`, `.devcontainer/README.md` and `CHANGELOG.md`: proceed and coordinate (Q4, Q5); `sequenced:` is `none`.

**Rejected.** A bash-version guard in the script (the README names bash 4.3, as `codeo` and `install.sh` do); a refusal on Intel Macs when `sbx` is present (`sbx` says so itself); an `open -a` fallback for VS Code (untried).

**Documentation the plan changes.** `.sbx/README.md` (*Prerequisites*, the diagram's participant, a new `## On macOS`), `.devcontainer/README.md` (the host sentence), `docs/dev-environment-sbx-evaluation.md` (*Host*, T14, the banner), `CHANGELOG.md`. The root `README.md` and `docs/home-checkout.md` carry no sandbox text and are deliberately unchanged.

**Intake questions resolved.** Whether sbx is available on macOS: Docker's install page lists it (macOS 14 or later, Apple silicon, no Docker Desktop), read 2026-11-25; whether it works there is Task 1 and Task 5's to show. Whether `codeo-sandbox.sh` works on a Mac: nothing in it is Linux-only by reading, and T14 is where it is run.

No `/codeo:issue` was filed. The `engineering` plugin's skills were not needed.

### Footprint

```
files:      .sbx/codeo-sandbox.sh, .sbx/README.md, .devcontainer/codeo, .devcontainer/README.md, tests/sandbox.test.sh, docs/dev-environment-sbx-evaluation.md, CHANGELOG.md, docs/plans/2026-11-25-sbx-sandbox-macos-176.md, .codeo/176/**
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-25 — Q1-Q3 raised · cost: 1m · fable-5-2 87k in + 585k cached / 7k out · sonnet-5-5 13k in + 5k cached / 2k out
- 2026-11-25 — plan drafted (not committed) and Q4 raised, the overlap with #173 · cost: 5m · fable-5-2 13k in + 258k cached / 759 out · sonnet-5-5 140k in + 932k cached / 25k out
- 2026-11-25 — plan approved and written, footprint committed, Q5 raised (the overlap with #173 as overlap.sh prints it) · cost: 1m · fable-5-2 6k in + 120k cached / 2k out
- 2026-11-25 — planned: docs/plans/2026-11-25-sbx-sandbox-macos-176.md · cost: 30m · fable-5-2 13k in + 258k cached / 759 out · sonnet-5-5 163k in + 3.3M cached / 35k out
