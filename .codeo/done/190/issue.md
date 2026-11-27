# Issue #190 — issue

| | |
|---|---|
| Updated | 2026-11-26 |

## Where this stands

Q1–Q4 answered; the draft is at the review gate in body.md; nothing is filed.

## Problem as restated

codeo's plugin and workflow are project-agnostic, but the container and sandbox half of the setup (`.devcontainer/`, `.sbx/`, `codeo-container.sh`, `codeo-sandbox.sh`, `codeo-track.sh`, the `codeo` host command) is built for the codeo repo itself: the Dockerfile is a bash/jq/shellcheck image, `devcontainer.json` names `codeo-gh` / `codeo-git` volumes, and the scripts default to `https://github.com/kbajpai/codeo.git` (`.sbx/codeo-sandbox.sh` has 45 codeo/kbajpai references, `codeo-container.sh` 31). An engineer who wants the "full" setup (home container + one container or sbx sandbox per issue) for a different project and stack has to copy and hand-edit these files and cannot tell what is codeo-specific. The goal is the "full" adoption path: audit the assumptions, make the setup parameterized or templatable, and document how another project adopts it.

## Questions

1. **How should a project adopt the full setup?** (a) Copy `.devcontainer/` and `.sbx/` into the project and edit them (the files stay codeo's, made parameterized so the edits are small); (b) the plugin ships a template and a command (for example `/codeo:setup --containers`) that writes the files into the project; (c) the scripts run from the plugin and read only a small project-owned file (Dockerfile plus config keys). Recommendation: (b), with the container and sandbox scripts reading everything project-specific from `.codeo/config.json`. Answer: (b)

2. **Which parts are in scope?** Dev container (VS Code and `codeo-container.sh`), sbx sandbox, the `codeo` host command, the tracking comment, the role guard. Recommendation: all of them, since "full" means the whole thing; the sbx image (`.sbx/claude-image`) included. Answer: everything

3. **What counts as done for the other stack?** Recommendation: the issue does not write Dockerfiles for particular stacks; it ships a stack-neutral base image plus a documented place to add the project's toolchain, and one worked example (name the stack: Node, Python, other). Which example, if any? Answer: my recommendation; the worked example is the monorepo from Q4

4. **Verification.** Recommendation: a test that sets up a throwaway project (not named codeo, different owner) and asserts that no script or default still names `kbajpai/codeo` or `codeo-<N>` where the project's codename should appear. Is that enough, or do you want a real second project run through the full flow before release? Answer: a real run: a monorepo app with a C# backend, an Angular frontend, Kubernetes and dockerized containers.

## Notes

- Hardcoded-name counts above are from `grep -c -E "kbajpai|codeo"` on 2026-11-26; the audit itself is part of the issue.
- Out of scope proposal: a non-GitHub host, Windows-native, changing the workflow skills.
