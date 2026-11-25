# Issue #176 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/176 |
| Branch | `feat/176-support-sbx-issue-sandbox-macos` |
| Updated | 2026-11-25 |

## Where this stands

Round 1. The code, the READMEs, the tests and the sbx evaluation are read, and Docker's install
page was read again today. It now lists macOS, so the first of intake's two open points is answered
on paper (see Notes). The second, whether `codeo-sandbox.sh` works on a Mac, can only be answered on
a Mac, and this session runs in a Linux container. Nothing is drafted until Q1-Q3 are answered: they
decide whether the plan fixes failures a trial has shown or failures it guesses at.

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

### Q3 — Which issue number does the trial sandbox use?

**Why it matters:** `codeo issue <N> --sandbox` adds a `sandbox` row to issue N's tracking comment
and takes the workflow lock in the sandbox's own clone. On #176 it finds this issue's container
already on record and asks before going on, which is itself one of the paths to check, and the row
lands on the issue it belongs to. On a scratch issue nothing touches #176, but the branch must hold
`.codeo/<N>/init.md` on origin for `codeo` to find it, so a scratch issue needs `/codeo:init` first.
**Options:** #176 itself, answering yes when it asks (recommended) · a scratch issue you name · no
preference, you pick.

**Answer:**

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

**Other workflows in flight:** #173 (`docs/173-close-161-leftovers-release-checklist`, kbajpai) is
at `init` with no footprint and no changed files yet, so there is nothing to compare until it plans.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-25 — Q1-Q3 raised · cost: 1m · fable-5-2 87k in + 585k cached / 7k out · sonnet-5-5 13k in + 5k cached / 2k out
