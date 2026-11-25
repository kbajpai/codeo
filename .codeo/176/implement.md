# Issue #176 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/176 |
| Branch | `feat/176-support-sbx-issue-sandbox-macos` |
| Updated | 2026-11-25 |

## Where this stands

Round 2, after a send-back from `/codeo:qc` round 1. Nothing is built yet: Q6 (#177 also changes
`CHANGELOG.md`) and Q7 (prove `codeo open` with VS Code, or accept it as shown to stop cleanly) are
open. Once they are answered this round fixes qc findings F2-F8 (README wording, the Command Line
Tools note, one non-hermetic test, the T14 count, the CHANGELOG bullet, the policy-init step order)
and records the new Mac evidence in trial T14 and the README.

## Questions

### Q1 — What did Task 1's preflight print on the Mac?

**Why it matters:** if `ProductVersion` is below 14 or `uname -m` is not `arm64`, Docker does not list
this Mac, and the plan stops here and goes back to `/codeo:plan` for the refusal-only version;
otherwise Tasks 2-4 are built in this checkout and Task 5 waits for the pushed branch.
**Options:** the pasted output below · the Mac is below the minimum, so re-plan.

Run these over SSH on the Mac, one command at a time, and paste what each prints. `sbx login` opens
a browser for Docker's sign-in: say what it printed and did over SSH (a URL, a code, or a failure).

```
sw_vers
uname -m
bash --version
brew --version
brew trust docker/tap
brew install docker/tap/sbx
sbx version
sbx login
```

**Answer:**
Pasted by the engineer in conversation, 2026-11-25, trimmed to the lines that matter:

```
arm64
GNU bash, version 5.3.20(1)-release (aarch64-apple-darwin27.0.0)
Homebrew 7.0.16
Trusted tap: docker/tap
✔︎ Cask sbx (0.54.1)
🍺  sbx was successfully installed!
  sbx version v0.54.1 3df896d5784200e8dfe6dca28ebd7102fe064169
  Your one-time device confirmation code is: TMKF-PDJT
  Open this URL to sign in: https://login.docker.com/activate?user_code=TMKF-PDJT
  error: signed in to Docker, but SBX could not save the credentials because macOS Keychain denied access; unlock the login keychain in Keychain Access or allow SBX access, then run 'sbx login' again
kbajpai@mac-studio:~$ security -v unlock-keychain ~/Library/Keychains/login.keychain-db
  (prompted for the login password)
kbajpai@mac-studio:~$ sbx login
  Open this URL to sign in: https://login.docker.com/activate?user_code=HKPB-BGNF
  Signed in as kbajpai.
  warning: schedule credential exchange failed: the schedule service could not verify your Docker sign-in
```

The `sw_vers` output was not in the paste.

### Q2 — What did Task 5's full route print on the Mac?

**Why it matters:** this is the plan's only proof that `codeo issue 176 --sandbox`, `codeo list`,
`codeo open` and `codeo rm` work on a Mac, and it settles the acceptance criteria that no test here
can: the sandbox starts, takes the lock and adds the `sandbox` row; `codeo rm` removes it and marks
the row `removed`. Task 5 writes trial T14 and the `## On macOS` section from what you paste. A step
that fails beyond what Tasks 2-3 fixed is not patched here: it is recorded as it happened and sent
back to `/codeo:plan`.
**Options:** the pasted output below · a step failed, say which and what it printed.

Tasks 2-4 are committed and pushed (`86fc0bf`), so the Mac can fetch them. Over SSH on the Mac, one
command at a time, paste what each prints. The first replaces `codeo` and its three scripts in
`~/codeo` with this branch's; run plain `codeo update` afterwards to go back to `main`'s. The
sandbox is for #176, so its lock and tracking row appear on this same issue; answer yes if
`codeo issue` asks about the existing container (`--yes` does).

```
env CODEO_RAW_URL=https://raw.githubusercontent.com/kbajpai/codeo/feat/176-support-sbx-issue-sandbox-macos codeo update
sbx secret set github --command "gh auth token"
sbx setup ssh
sbx policy allow network "*.gallery.vsassets.io,*.gallerycdn.vsassets.io"
codeo issue 176 --sandbox --yes
sbx exec codeo-176 cat .codeo/active
gh issue view 176 --comments
codeo list
codeo open 176
codeo rm 176
gh issue view 176 --comments
```

Unlock the login keychain first in the session if a step stops on a keychain error
(`security -v unlock-keychain ~/Library/Keychains/login.keychain-db`). `codeo open 176` starts VS
Code on the Mac itself: say whether a window opened there; if it did not over SSH, run it at the
Mac's screen. Before `codeo rm 176`, run `codeo shell 176` once at the Mac, check it opens a shell
in the sandbox, and exit it.

**Answer:**
Pasted by the engineer in conversation, 2026-11-25, trimmed to the lines that matter (the sandbox
banner and the clone's progress lines are left out):

```
$ env CODEO_RAW_URL=…/feat/176-support-sbx-issue-sandbox-macos codeo update
updated codeo and its three scripts
$ sbx secret set github --command "gh auth token"
  ✓ command resolved successfully
  Saved command secret github (global)
$ sbx setup ssh
    Status:  ● enabled · signed in as kbajpai
    Access:  *.sbx -> sandboxd.sock (no port · login-gated)
  warning: Could not pre-trust host key yet (open …/sandboxd/docker_sandboxes_ssh_ed25519: no such file or directory); first connect will trust on use.
$ sbx policy allow network "*.gallery.vsassets.io,*.gallerycdn.vsassets.io"
  error: allow network rule: request failed: 412 Precondition Failed: global network policy has not been initialized; run: sbx policy init <allow-all|balanced|deny-all>
$ codeo issue 176 --sandbox --yes
Issue #176 already has containers on record:
  - container `codeo-176` on host mac-studio.lan, created 2026-11-25T18:55:41Z, status active
  - a container codeo-176 exists on this host
A row on another host is not proof the container still exists.
Cloning into 'codeo-176'...
  Choose the network policy for sandboxes … Choice [1-3, default 2]: 2
  Set network policy Balanced
  SANDBOX
    Name:       codeo-176
    Agent:      claude
    Kit:        docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332
    Workspace:  ~/codeo/codeo-176 (rw)
    Image:      docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332
    CPU:        2
    Memory:     4g
    ✓ Created sandbox codeo-176
plugins: installed superpowers
plugins: installed codeo v1.0.9
lock: took the lock for #176 on feat/176-support-sbx-issue-sandbox-macos
devcontainer-start: TODO — the GitHub token lacks the project scope: run gh auth refresh -s project
devcontainer-start: TODO — git identity is not set (missing: user.name, user.email; tried ~/.gitconfig, then GIT_AUTHOR_NAME / GIT_AUTHOR_EMAIL): run git config --global user.name 'Your Name' and git config --global user.email you@example.com
devcontainer-start: TODO — Claude Code is not logged in: run claude auth login
    ✓ sandbox codeo-176 — running detached
$ sbx exec codeo-176 cat .codeo/active
issue:   176
branch:  feat/176-support-sbx-issue-sandbox-macos
started: 2026-11-25
host:    container
sandbox: codeo-176
$ gh issue view 176 --comments
failed to run git: fatal: not a git repository (or any of the parent directories): .git
$ codeo list
#170  container  running  docs/docs-say-codeo-host-command
#173  container  running  docs/173-close-161-leftovers-release-checklist
#176  container  running  feat/176-support-sbx-issue-sandbox-macos
#176  sandbox  detached  feat/176-support-sbx-issue-sandbox-macos
$ codeo open 176
codeo: both a container and a sandbox codeo-176 exist; add --container or --sandbox to pick one
$ codeo rm 176
codeo: both a container and a sandbox codeo-176 exist; add --container or --sandbox to pick one
$ gh issue view 176 --comments
failed to run git: fatal: not a git repository (or any of the parent directories): .git
```

### Q3 — What do the steps that did not run, and the git identity, print on the Mac?

**Why it matters:** Q2 settled that the sandbox starts, takes the lock (the sandbox's own
`.codeo/active` holds `sandbox: codeo-176`) and shows in `codeo list`. It did not settle the rest of
the acceptance criteria, for reasons that are the plan's command errors, not Mac failures: `codeo
open` and `codeo rm` stopped because #176 also has its dev container, so they need `--sandbox`
(Q3's choice of #176 in `plan.md` made the clash); and `gh issue view` ran outside a checkout, so it
could not name the repository, which leaves the tracking comment's `sandbox` row unseen. The
network-policy rule failed because the Mac had no policy yet (`sbx policy init` comes first; the
create step then asked and `2` was chosen), so the VS Code extension rule has to be run again before
`open`. The identity TODO decides whether `codeo-sandbox.sh` has a macOS defect: `git config
--global user.name` on the Mac says whether the host had an identity to pass, and `xcode-select -p`
says whether `git_is_usable` counted its git as usable. If the host has an identity and the
sandbox still lacks it, that is a defect and goes back to `/codeo:plan`; if it has none, it is not.
These commands are corrections to the plan's Task 5 command list, which is not edited; the outcome
records the deviation.
**Options:** the pasted output below · a step failed, say which and what it printed.

Over SSH on the Mac, one command at a time, paste what each prints (the sandbox from Q2 is still
there; `codeo shell` is interactive, so type `exit` in it):

```
git config --global user.name
git config --global user.email
xcode-select -p
sbx policy allow network "*.gallery.vsassets.io,*.gallerycdn.vsassets.io"
gh issue view 176 --repo kbajpai/codeo --comments
codeo shell 176 --sandbox
codeo open 176 --sandbox
codeo rm 176 --sandbox
gh issue view 176 --repo kbajpai/codeo --comments
```

`codeo open 176 --sandbox` starts VS Code on the Mac itself: say whether a window opened there (run
it at the Mac's screen if it did not over SSH). If `codeo rm` refuses over unpushed or uncommitted
work, paste what it printed and stop there; do not add `--force`. Afterwards, plain `codeo update`
puts `main`'s scripts back.

**Answer:**
Pasted by the engineer in conversation, 2026-11-25, trimmed (the issue body is left out):

```
$ git config --global user.name
$ git config --global user.email
  (both printed nothing)
$ xcode-select -p
/Library/Developer/CommandLineTools
$ sbx policy allow network "*.gallery.vsassets.io,*.gallerycdn.vsassets.io"
  Added rule 42ff739f-35fe-41a1-ac04-7ad5a7783ed6 to policy local (scope: global): *.gallery.vsassets.io [tcp]
  Added rule 2be98cb1-850e-4092-b1d7-f0fd4b322353 to policy local (scope: global): *.gallerycdn.vsassets.io [tcp]
$ gh issue view 176 --repo kbajpai/codeo --comments
  … Codeo tracking for #176: branches, containers and their removal.
   branch    │ feat/176-support-sbx-issue-sandbox-macos │                │ active │ 2026-11-25T18:53:13Z
   image     │ codeo-dev:codeo-176                      │ mac-studio.lan │ active │ 2026-11-25T18:55:39Z
   container │ codeo-176                                │ mac-studio.lan │ active │ 2026-11-25T18:55:41Z
   volume    │ codeo-176                                │ mac-studio.lan │ active │ 2026-11-25T18:55:42Z
   sandbox   │ codeo-176                                │ mac-studio.lan │ active │ 2026-11-25T20:44:45Z
$ codeo shell 176 --sandbox
✓ agent@codeo-176:/Users/kbajpai/codeo/codeo-176$
```

The paste ends at the sandbox shell's prompt: the lines after `codeo shell` (`codeo open`,
`codeo rm`, the second `gh issue view`) printed nothing in it, so they did not run on the Mac.

### Q4 — What do `codeo open`, `codeo rm` and the second tracking view print on the Mac?

**Why it matters:** Q3 settled the identity and the tracking row. The Mac has no global git
identity (`user.name` and `user.email` printed nothing), so the start script's identity TODO is the
right answer there, not a defect in `codeo-sandbox.sh`; `xcode-select -p` is
`/Library/Developer/CommandLineTools`, so `git_is_usable` counted git as usable. The `sandbox`
row is on the issue, `active`. `codeo shell 176 --sandbox` opened the sandbox's shell. What is still
unshown is the end of criterion 3: that `codeo open` opens the sandbox and that `codeo rm` removes
it and marks the row `removed`. T14 and the README are written from the whole run, so they wait for
this.
**Options:** the pasted output below · `open` skipped, said so (T14 then records it as not tried
over SSH; `rm` is the one that has to run) · a step failed, say which and what it printed.

Type `exit` to leave the sandbox shell first, then over SSH on the Mac, one command at a time,
paste what each prints. Close any VS Code window `codeo open` opened before `codeo rm`: the removal
cuts it off.

```
exit
codeo open 176 --sandbox
codeo rm 176 --sandbox
gh issue view 176 --repo kbajpai/codeo --comments
```

If `codeo rm` refuses over unpushed or uncommitted work, paste what it printed and stop there. Plain
`codeo update` afterwards puts `main`'s scripts back.

**Answer:**
Pasted by the engineer in conversation, 2026-11-25, trimmed (the issue body is left out):

```
$ codeo open 176 --sandbox
codeo-sandbox: codeo-176 does not exist: create it with codeo-sandbox.sh issue 176 <branch>
$ codeo rm 176 --sandbox
codeo-sandbox: no sandbox codeo-176
$ gh issue view 176 --repo kbajpai/codeo --comments
  … Codeo tracking for #176 …
   sandbox   │ codeo-176 │ mac-studio.lan │ removed │ 2026-11-25T20:44:45Z │ 2026-11-25T20:48:4…
```

Read: the sandbox was already gone when these ran. Its row says `removed` at 20:48, four minutes after
it was created at 20:44:45, so the `codeo open` and `codeo rm` lines in the Q3 paste, which ran
after the engineer left the sandbox shell, did run, and `codeo rm` removed the sandbox and marked
the row. What they printed was not captured, and `codeo open`'s result is not known.

### Q5 — Did `codeo open 176 --sandbox` open VS Code on the Mac when it ran in the Q3 paste?

**Why it matters:** `codeo open` opening the sandbox is the one clause of criterion 3 with no
evidence yet (`list`, `shell`, `rm` and the `removed` row are shown). T14 records it as shown or as
not shown, and the `## On macOS` text says what `codeo open` does on a Mac over SSH only if it was
seen; a "not shown" here goes to `/codeo:qc` as a criterion it cannot check. The sandbox no longer
exists, so a new run means `codeo issue 176 --sandbox --yes` again (a couple of minutes), then
`codeo open 176 --sandbox`, then `codeo rm 176 --sandbox`.
**Options:** yes, a window opened on the Mac and connected to `codeo-176.sbx` · a window opened but
did not connect (say what it showed) · nothing opened, or not looked · run the three commands again
and paste what they print.

**Answer:**
The engineer pasted the same terminal output as in Q4 (the `codeo open` and `codeo rm` "does not
exist" lines and the tracking view with the `removed` row), 2026-11-25, and said nothing about a
window opening.

My reading, labelled as mine: `codeo open`'s result is not shown. T14 records it as not shown and not
tried over SSH, and the outcome says criterion 3's `open` clause is unchecked, so `/codeo:qc` can
route it. It can go back as a later round if the engineer re-runs it or says what happened.

### Q6 — #177 also changes `CHANGELOG.md`: proceed and coordinate, sequence after it, or re-scope?

**Why it matters:** #177 (branch `docs/177-close-163-166-168-leftovers`, assignee kbajpai, step
`init`) lists `CHANGELOG.md` in its footprint, and `overlap.sh` prints `177	CHANGELOG.md` and
`177	glob:CHANGELOG.md`. This round rewrites the one bullet this branch added under `## Unreleased`
(qc round 1, F7: the bullet overstates what the script checks, and F3 asks it to drop the
Command Line Tools fallback clause). Two branches editing under the same heading merge by keeping
both, the way #173's identical overlap was settled (proceed and coordinate); sequencing after #177
would hold the reword until it merges, and re-scoping would leave the overstated bullet as it is.
**Options:** proceed and coordinate (recommended) · sequence after #177 · re-scope: leave the
CHANGELOG bullet unchanged and fix the rest.

**Answer:**
Proceed and coordinate (the engineer, in conversation, 2026-11-25).

### Q7 — Prove `codeo open` with VS Code on the Mac, or accept it as shown to stop cleanly?

**Why it matters:** qc round 1 (F1) found acceptance criterion 3's `codeo open` clause unproven, and
only you can settle how: it needs VS Code on the Mac. What the Mac has shown since (see *Evidence
after qc round 1* in `## Notes`): with `main`'s script `codeo open` fails with `line 290: code:
command not found`; with this branch's script it prints `window-title: codeo [#176]` and then
`codeo-sandbox: code is not on PATH: in VS Code run "Shell Command: Install 'code' command in
PATH", or set CODEO_CODE to the VS Code program`, which is Task 3's check working on a real Mac.
VS Code has not opened on the sandbox from the Mac, and `codeo rm`'s own output was never
captured (the sandbox is running again after the second `codeo issue`). If you prove it, T14 and the
README record a window opening; if you accept it, they record the clean stop and say opening VS
Code over SSH is untried, your decision stands in this dossier, and the next `/codeo:qc` judges
criterion 3 with it.
**Options:** prove it (recommended when VS Code is on the Mac: install its `code` command, run
`codeo open 176 --sandbox` at the Mac's screen, say whether a window opened and connected to
`codeo-176.sbx`, then `codeo rm 176 --sandbox`, and paste both) · accept the gap, and still paste
`codeo rm 176 --sandbox` so its output is on record · no preference, you pick.

**Answer:**
Yes, I was able to open code. I had to install "code" command for VS Code (the engineer, in conversation, 2026-11-25).

My reading, labelled as mine: with VS Code's `code` command on `PATH`, `codeo open 176 --sandbox` opened VS Code on the Mac, so the `open` clause of criterion 3 is shown. The engineer did not say whether the window connected to `codeo-176.sbx` or where it opened (at the Mac's screen or from the SSH session), and `codeo rm`'s own output was still not pasted; T14 and the README state exactly that and no more.

## Notes

- **Task 1 gate: passed.** `uname -m` is `arm64`, and the bash triple `aarch64-apple-darwin27.0.0`
  is Darwin 27, newer than Darwin 23 (macOS 14). `sw_vers`, pasted by the engineer afterwards, prints
  `ProductName: macOS`, `ProductVersion: 27.2.1`, `BuildVersion: 26B131`; T14 quotes it.
- **What Task 1 showed, for Tasks 4 and 5:** Homebrew installed `sbx` v0.54.1 (the Windows trial
  and `.sbx/README.md` say v0.53.0, so the macOS text must not claim the same version). Over SSH,
  `sbx login` failed to save its credentials with `macOS Keychain denied access` until
  `security -v unlock-keychain ~/Library/Keychains/login.keychain-db` was run, after which it
  signed in with the device-code flow (a URL and a code, no browser opened from the shell) and
  printed the same `schedule credential exchange failed` warning as on Windows. Brew's bash 5.3.20
  is the Mac's `bash`. These are tried, not untried, in Task 4's `## On macOS`.
- **Evidence after qc round 1** (pasted by the engineer in conversation, 2026-11-25, trimmed):

  ```
  $ codeo issue 176 --sandbox --yes          (a second time, after the earlier rm)
  plugins: superpowers, codeo v1.0.9
  devcontainer-start: TODO — the GitHub token lacks the project scope: …
  devcontainer-start: TODO — git identity is not set (missing: user.name, user.email; …)
  devcontainer-start: TODO — Claude Code is not logged in: run claude auth login
  $ codeo open 176 --sandbox                 (with main's scripts, after a plain codeo update)
  window-title: codeo [#176]
  /Users/kbajpai/codeo/codeo-sandbox.sh: line 290: code: command not found
  codeo-sandbox: could not start VS Code
  $ env CODEO_RAW_URL=…/feat/176-support-sbx-issue-sandbox-macos codeo update
  updated codeo and its three scripts
  $ codeo open 176 --sandbox                 (with this branch's scripts)
  window-title: codeo [#176]
  codeo-sandbox: code is not on PATH: in VS Code run "Shell Command: Install 'code' command in PATH", or set CODEO_CODE to the VS Code program
  ```

  Line 290 of `main`'s `.sbx/codeo-sandbox.sh` is `code --folder-uri "$1"`; on this branch that line is
  304, behind the new check, so the first `open` ran `main`'s copy. The second `codeo issue` printed no
  `lock:` line, because the clone from the first run still holds its lock.
- **qc round 1 findings, checked against the code (receiving-code-review):** F2-F8 hold. F3 in
  particular: `cmd_issue` runs `ensure_host_clone` (`git clone`) before `run_start` reads
  `git_is_usable`, so on a Mac without the Command Line Tools `issue` stops at the clone and the
  identity fallback is only reached when a clone already exists. F1 is the engineer's to settle (Q7).
  Nothing was pushed back.

## Outcome

2026-11-25

**Built** (plan `docs/plans/2026-11-25-sbx-sandbox-macos-176.md`, five tasks):

| Task | Result | Commits |
|---|---|---|
| 1. Preflight on the Mac | passed: macOS 27.2.1, `arm64`, Homebrew 7.0.16, `sbx` v0.54.1, bash 5.3.20 (Q1, engineer's paste) | none |
| 2. Missing `sbx` on macOS | `host_is_macos`; `pick_sbx` names `brew trust docker/tap`, `brew install docker/tap/sbx`, `sbx login`, macOS 14 and Apple silicon, and `codeo issue <N> --container`; the Linux and WSL2 message is unchanged | `537af9d` |
| 3. Git and VS Code on macOS | `git_is_usable` needs `xcode-select -p` on macOS; a missing `code` is one line naming *Shell Command: Install 'code' command in PATH* and `CODEO_CODE` | `4b60010` |
| 4. Docs | "never macOS" gone from `README.md`, `.sbx`, `.devcontainer`, `docs/*.md`; `.sbx/README.md` has `## On macOS`; host sentences name macOS; one `CHANGELOG.md` bullet | `86fc0bf` |
| 5. The route on the Mac, recorded | trial T14 and a macOS part of *Host* in `docs/dev-environment-sbx-evaluation.md`; `## On macOS` rewritten from the run | `701f464` |
| Fix wave after the final review | CHANGELOG claim corrected, one macOS test made hermetic, one case and one assertion added, README wording tightened | `193bed8` |

**Documentation pages changed:** `.sbx/README.md` (*Prerequisites*, the diagram's participant, `## On macOS`), `.devcontainer/README.md` (the host sentence), `docs/dev-environment-sbx-evaluation.md` (*Host*, T14, the banner), `CHANGELOG.md`. The root `README.md` and `docs/home-checkout.md` are unchanged, as the plan says.

**Build result:** the `shell` suite's build command is `true` and exits 0; `bash tests/run.sh` exits 0 at `193bed8` ("all cases passed"). Full suites and the criteria are `/codeo:qc`'s.

**What the Mac showed** (Q1-Q5, trial T14): `codeo issue 176 --sandbox --yes` created the sandbox, took the lock (`lock: took the lock for #176 …`, and the sandbox's `.codeo/active` holds `sandbox: codeo-176`), and added the `sandbox` row to the issue's tracking comment; `codeo list` showed `#176  sandbox  detached`; `codeo shell 176 --sandbox` opened a shell; `codeo rm 176 --sandbox` ran and the row reads `removed` (2026-11-25T20:48). **Not shown:** `codeo open`'s result (its output was never captured and the engineer did not say whether a window opened; Q5), the first `codeo rm`'s own output, and running `sbx` without Docker Desktop. QC should mark the `codeo open` clause of acceptance criterion 3 as not shown rather than met.

**Deviations from the plan, and why:**
- Task 5's command list was wrong in three places and the plan text was not edited: `codeo open`, `codeo shell` and `codeo rm` need `--sandbox` because #176's own dev container shares the number; `gh issue view` needs `--repo kbajpai/codeo` outside a checkout; `sbx policy init` must come before the gallery rule. Q3 and Q4 carried the corrected commands.
- `.sbx/README.md` gained a statement the plan did not name, that a host with no global policy refuses the gallery rule (412) until `sbx policy init balanced` has run. It documents what T14 showed and also holds for Linux and WSL2.
- The macOS README text states `sbx login`, `sbx secret set` and `sbx setup ssh` as tried (Q1, Q2) where the plan expected them marked untried until Task 5; only `codeo open` over SSH stays untried.
- The test helper `sb_gitcfg_macos` was added to share setup across the three identity cases; trial T14's title line stands alone so a test can match it exactly.
- The engineer's Mac still has this branch's scripts installed by `codeo update` (`CODEO_RAW_URL`), and the clone `~/codeo/codeo-176`; `codeo update` restores `main`'s scripts.

**Found and left alone:** `git_is_usable` on macOS treats a working Homebrew git with no Command Line Tools as unusable, so the identity then comes from `GIT_AUTHOR_*` only; it fails safe, and `CODEO_CODE` covers a `code` that is not on `PATH`. The Mac has no global git identity, so the start script's identity TODO there is correct, not a defect.

**Rulings** (made without waiting, each with its cost if wrong):
- Task 4 states what Task 1 showed as tried and does not claim v0.53.0 for macOS: a wording fix if wrong.
- Q1, Q3 and the Q5 reading are the controller's: the Mac trial is the plan's first task, the trial sandbox is #176 itself, and a pasted output that does not say a window opened is "not shown": a later round if the engineer re-runs `codeo open`.
- The Task 5 review's one Important finding (the image digest, 2 CPUs and 4g in T14) was a trimmed paste, not an invented value: the lines were restored in Q2's answer; nothing in T14 changed.
- The whole-branch review and one scoped re-review ran on the subagent model (`sonnet`), as this skill requires, not the most capable model.

No `Deployed revision:` (no shared environment is configured). No `/codeo:issue` was filed.

## Log

- 2026-11-25 — Q1 raised, waiting on Task 1's output from the Mac · cost: 2m · sonnet-5-5 12k in + 610k cached / 1k out
- 2026-11-25 — Task 1 gate passed (Q1 answered); Tasks 2-4 built, each reviewed clean and pushed; Q2 raised for Task 5 on the Mac · cost: 27m · sonnet-5-5 262k in + 8.2M cached / 40k out
- 2026-11-25 — Q2 answered: sandbox starts, takes the lock, lists on the Mac; open, rm and the tracking row did not run as planned, Q3 raised with corrected commands · cost: 74m · sonnet-5-5 310k in + 9.3M cached / 44k out
- 2026-11-25 — Q3 answered: tracking row, identity and shell shown; open and rm still unrun, Q4 raised · cost: 76m · sonnet-5-5 320k in + 10.2M cached / 53k out
- 2026-11-25 — Q4 answered: the sandbox row reads removed; codeo open's result not captured, Q5 raised · cost: 79m · sonnet-5-5 328k in + 11M cached / 57k out
- 2026-11-25 — implemented: Tasks 2-5 built and reviewed, final review and one fix wave, pushed at 193bed8; criterion 3's codeo open not shown · cost: 98m · sonnet-5-5 616k in + 18.9M cached / 108k out
- 2026-11-25 — round 2 started: qc round 1 read and its findings checked; Q6 (overlap with #177 on CHANGELOG.md) and Q7 (codeo open) raised · cost: 1m · sonnet-5-5 19k in + 806k cached / 5k out
