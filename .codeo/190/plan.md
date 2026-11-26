# Issue #190 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/190 |
| Branch | `docs/190-make-container-sandbox-setup-reusable` |
| Updated | 2026-11-26 |

## Where this stands

Q1-Q7 are answered (engineer, "go with your picks", in the conversation, 2026-11-26: every recommendation). The draft is at the review gate in `.codeo/190/plan-draft.md` (13 tasks); nothing is written under `docs/plans/` until it is approved. One call of mine is flagged in the draft: the host run accepts `fail ruleset` as the only doctor failure (a new repository has no ruleset and codeo never creates one).

What exploration found:
- **The first slice is on this branch.** `74b3afe` was cherry-picked as `c361707` (same patch) and goes to origin with this dossier's push. It adds `templates/containers/`, `scripts/containers.sh`, `setup.sh --codename/--containers`, the doctor `containers` check, `scripts/codeo-init.sh`, `lib/prompt.sh`, `tests/containers.test.sh` and `tests/init.test.sh`. `bash tests/run.sh` on this branch ends `all cases passed`.
- **Criteria the slice already covers in tests:** the throwaway project with another owner and codename (3), the wizard's three refusals and no create call (8), the rerun that keeps the config and seeds (9), and the managed scripts equal to the templates (10, in part; see Q5).
- **Still missing:** the audit list (1), the C# + Angular example and its real run (4, 7), both READMEs (5), `docs/skills.md` and `CHANGELOG.md` entries, and any image built from the neutral Dockerfile.
- **This container has no Docker, `sbx`, `dotnet`, `node` or `kubectl`.** Every image build and container or sandbox start is a task you run on your host; the plan marks each `Runs on: the engineer's host` and gives it one `bash <script>` command.
- **The role guard is copied but not connected.** `containers.sh` copies `.devcontainer/scripts/role.sh` into a project, but writes no `.codeo/overlays/` file, so no skill calls it, and `/codeo:init` there has no `host-workflow` text telling the engineer how to open the issue's container (Q3). `docs/home-checkout.md` still says `role.sh` "is not shipped for other projects".
- **The `codeo` host command downloads its scripts from `https://raw.githubusercontent.com/<owner>/<repo>/main`.** A project must commit `.devcontainer/` and `.sbx/` to its base branch before `codeo issue <N>` works; the README must say so. The branch name `main` is hardcoded there, which the audit will list.
- **`scripts/codeo-init.sh` cannot run alone.** It sources `lib/prompt.sh` and runs `install.sh`, `scripts/setup.sh`, `scripts/containers.sh` and `scripts/doctor.sh` beside it (Q6).
- **`install.sh` and `codeo-init.sh` name `kbajpai/codeo` as the plugin's source.** That is where the plugin lives, not where the project's name belongs, so the audit records it as intended.
- **No other workflow is in flight** (`inflight.sh --except 190`).

## Questions

### Q1 — Which repository is the C# + Angular monorepo for the real run?

**Why it matters:** criteria 4 and 7 need a real GitHub repository that is not codeo's, and codeo never creates one. The answer decides whether the plan writes a sample application or only the toolchain and config for one you already have.

**Options:**
- **A sample in codeo, pushed to a throwaway repository you create.** `examples/csharp-angular/` holds a minimal ASP.NET Core API with one test, a minimal Angular app with one test, a Dockerfile for each, Kubernetes manifests, the toolchain section for the dev image and the `suites` for the config. You create an empty repository (name it in the answer), and a host task copies the sample in, runs `codeo-init.sh --yes --env containers` and starts an issue container.
- **Your own existing monorepo.** `examples/csharp-angular/` holds only the toolchain section and the config suites; the run happens in your repository (name it, and say whether its build needs anything private).
- **Both:** the sample is the documented example, and your monorepo is a second run recorded in the plan's evidence.

*Recommendation:* the sample plus a throwaway repository. Every adopter can repeat it, and the result does not depend on a private codebase.

**Answer:**
A sample in codeo, pushed to a throwaway repository you create (the repository name is supplied at the host run, Task 9) (engineer, "go with your picks", in the conversation, 2026-11-26; recorded here by the skill).

### Q2 — What must Docker and Kubernetes do inside an issue container or sandbox for the example?

**Why it matters:** criterion 4 says the container "runs the project's build and test commands". Tools alone need only the Dockerfile's toolchain section. A working `docker build` inside the container needs the host's Docker socket mounted, which changes `codeo-container.sh` (a managed script every project gets) and `devcontainer.json`. A cluster adds `kind` and a privileged container.

**Options:**
- **Tools only.** The image has the .NET SDK, Node, headless Chrome for `ng test`, the Docker CLI and `kubectl`. The example's suites are `dotnet build` and `dotnet test`, `npm ci`, `ng build` and `ng test`, and `kubectl kustomize` over the manifests, which needs no cluster. The application images are built on the host as a separate check.
- **Tools plus the host's Docker socket,** opt-in through a config key, so `docker build` of the API and web images runs inside the issue container.
- **Tools, socket and a `kind` cluster** the manifests are applied to.

*Recommendation:* tools only. It meets the criterion, and mounting the host's socket gives every issue container control of the host's Docker, which is a security decision for an issue of its own.

**Answer:**
Tools only (engineer, "go with your picks", in the conversation, 2026-11-26; recorded here by the skill).

### Q3 — Does `/codeo:setup --containers` also write the project's overlays (role guard and host workflow)?

**Why it matters:** the issue's Q2 put the role guard in scope. Without `.codeo/overlays/` the copied `role.sh` is never called, and `/codeo:init` does not tell the engineer to open the issue's container, nor `/codeo:close` how to remove it. Writing them adds eight template files and makes `docs/home-checkout.md`'s *Adopting the guard in your project* change from "write your own" to "setup writes it".

**Options:**
- **All of them, as seed files:** a `## role-guard` section for the eight guarded skills, and codeo's `## host-workflow` text for `init`, `close` and `cleanup` with the project's names filled in. Written only when absent, never overwritten, never checked by doctor. codeo's own overlays are held equal to the rendered templates by the same test as its scripts.
- **The role guard only;** the host workflow stays something a project writes.
- **Neither;** the README says how to write them.

*Recommendation:* all of them. A setup that writes containers nobody is directed into is not the "full" path the issue asks for.

**Answer:**
All of them, as seed files (engineer, "go with your picks", in the conversation, 2026-11-26; recorded here by the skill).

### Q4 — Is the one-sentence edit to `skills/setup/SKILL.md` in scope?

**Why it matters:** the issue rules out "changes to the workflow skills themselves", and the first slice edits the setup skill's description and its pass-through sentence for `--codename` and `--containers`. If it is out of scope, the flags work only through `bash scripts/setup.sh` and criterion 2's `/codeo:setup --containers` cannot be met as written.

**Options:** in scope (setup is not one of the workflow steps, and the criterion names it) · out of scope, and criterion 2 is reworded.

*Recommendation:* in scope, limited to that sentence and the description.

**Answer:**
In scope, limited to the description and the one pass-through sentence (engineer, "go with your picks", in the conversation, 2026-11-26; recorded here by the skill).

### Q5 — For criterion 10, what must codeo's own seed files equal?

**Why it matters:** the slice's test holds codeo's managed scripts equal to the templates. The three seed files are exempt, and two differ today: codeo's `Dockerfile` installs `shellcheck` and has no toolchain section, and its `devcontainer.json` lists the `timonwong.shellcheck` extension. The criterion says "checked-in container files equal what the templates render".

**Options:**
- **Seeds equal outside the project's own parts.** codeo's `Dockerfile` becomes the template with `shellcheck` installed in the toolchain section, and the test asserts the two files are identical outside that section, and that `devcontainer.json` is identical apart from the `extensions` list. codeo's image gets one more layer; nothing else about it changes.
- **Managed scripts only,** as the slice has it; the criterion is read as covering the files setup manages.

*Recommendation:* the first. It makes codeo the first project using its own template and catches a template change that codeo's own files miss.

**Answer:**
Seeds equal outside the project's own parts (engineer, "go with your picks", in the conversation, 2026-11-26; recorded here by the skill).

### Q6 — How does a project that has nothing installed yet start `codeo-init.sh`?

**Why it matters:** the issue asks for one command, and the script needs the files beside it. The answer decides whether `install.sh` (and its 470-line test) changes, and what line the README prints.

**Options:**
- **`codeo-init.sh` fetches its own release.** Run through `curl … | bash` or as a lone file, it finds no `lib/prompt.sh` beside it, clones the release tag of `kbajpai/codeo` into a temporary directory and runs itself from there. `install.sh` is untouched. The README line is `curl -fsSL https://raw.githubusercontent.com/kbajpai/codeo/main/scripts/codeo-init.sh | bash -s -- --env containers`.
- **`install.sh --init`** installs the plugins and then runs the wizard from the installed plugin.
- **Two documented commands:** `git clone` codeo at a tag, then `bash codeo/scripts/codeo-init.sh`.

*Recommendation:* the first. One line, and the installer and its tests stay as they are. Prompts read from `/dev/tty` when stdin is the pipe.

**Answer:**
codeo-init.sh fetches its own release (engineer, "go with your picks", in the conversation, 2026-11-26; recorded here by the skill).

### Q7 — One pull request, or two?

**Why it matters:** the work is the templates and wizard (code and tests), and the example, audit and READMEs (documentation plus host runs). One pull request means the documented commands are proved against the code they ship with; two lets the code merge before the host runs are done.

**Options:** one pull request from this branch · two: code first, then example and documentation in a second issue.

*Recommendation:* one. Criterion 5 requires every documented command to have been run, and the host runs are what find the faults in the templates. The branch prefix `docs/` stays as it is.

**Answer:**
One pull request (engineer, "go with your picks", in the conversation, 2026-11-26; recorded here by the skill).

## Notes

### Footprint

```
files:      docs/plans/2026-11-26-container-setup-reusable-190.md, docs/container-templates.md, docs/home-checkout.md, docs/skills.md, README.md, CHANGELOG.md, .devcontainer/**, .sbx/**, .codeo/overlays/**, templates/containers/**, scripts/containers.sh, scripts/codeo-init.sh, scripts/setup.sh, scripts/doctor.sh, lib/prompt.sh, skills/setup/SKILL.md, examples/csharp-angular/**, tests/containers.test.sh, tests/init.test.sh, tests/example.test.sh, tests/readme.test.sh, tests/setup.test.sh, tests/devcontainer.test.sh
wiki:       none
exclusive:  none
sequenced:  none
```

- Plan shape (step 5), stated before drafting: an implementation plan at `docs/plans/2026-11-26-container-setup-reusable-190.md`, with a `**Spec:**` line pointing at a new reference page, `docs/container-templates.md`, that holds the audit list, the managed and seed file kinds and how each name is derived from the config. The audit is a standing reference, so it does not go under `docs/plans/`.
- Host tasks are given as `bash <script in the repository>`: the host already runs bash for `codeo-container.sh`, so no shell question is needed.

## Outcome

_Pending — written at the hand-off._

## Log
- 2026-11-26 — Q1-Q7 raised · cost: 5m · fable-5-2 100k in + 851k cached / 9k out
