# Release checklist

The engineer's own actions, in order. Nothing here is done by an agent. The first release followed
exactly these steps.

Rulesets come after the first push: a pull-request rule on the default branch would otherwise block
the very push that creates it. Both rulesets let a repository admin (role id 5) bypass them, so they
constrain other people and accidents, not the owner.

1. Create the public repository, empty:

   ```bash
   gh repo create kbajpai/codeo --public --description "Agent workflow pipeline for Claude Code"
   ```

2. Enable secret scanning and push protection before any code goes up:

   ```bash
   gh api -X PATCH repos/kbajpai/codeo \
     -f 'security_and_analysis[secret_scanning][status]=enabled' \
     -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'
   ```

3. Connect and push over HTTPS (a dev container has no SSH key for GitHub; `gh` supplies the credentials):

   ```bash
   gh auth setup-git
   git remote add origin https://github.com/kbajpai/codeo.git
   git push -u origin main
   ```

4. Add the default-branch ruleset: pull request required, no force-push, no deletion.

   ```bash
   gh api -X POST repos/kbajpai/codeo/rulesets --input - <<'JSON'
   {
     "name": "default branch: PR only, no force-push, no delete",
     "target": "branch",
     "enforcement": "active",
     "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
     "rules": [
       {"type": "pull_request", "parameters": {
         "required_approving_review_count": 0,
         "dismiss_stale_reviews_on_push": false,
         "require_code_owner_review": false,
         "require_last_push_approval": false,
         "required_review_thread_resolution": false}},
       {"type": "non_fast_forward"},
       {"type": "deletion"}
     ],
     "bypass_actors": [{"actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always"}]
   }
   JSON
   ```

5. Add the tag ruleset, so only an admin can create, move or delete `v*` tags:

   ```bash
   gh api -X POST repos/kbajpai/codeo/rulesets --input - <<'JSON'
   {
     "name": "release tags: owner only",
     "target": "tag",
     "enforcement": "active",
     "conditions": {"ref_name": {"include": ["refs/tags/v*"], "exclude": []}},
     "rules": [{"type": "creation"}, {"type": "update"}, {"type": "deletion"}],
     "bypass_actors": [{"actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always"}]
   }
   JSON
   gh ruleset list -R kbajpai/codeo
   ```

   The list must show both rulesets as `active` before the next step.

6. Before tagging, set the release's version where it is written:
   - **move to the release being cut:** `.claude-plugin/plugin.json`'s version; in `README.md`, the
     installer transcripts, the `ref` in the settings example and the `marketplace add` example; in
     `tests/install.test.sh`, the stubs that stand for the latest release; in `docs/updating.md`,
     every version that stands for the latest release;
   - **move to the release before it:** in `README.md`, the `--version` example and the left side of
     the `codeo vA -> vB` replace line; in `tests/install.test.sh`, the stubs that stand for an older
     release that is installed, pinned or asked for; in `docs/updating.md`, every version that
     stands for the release before it (the installed side of the update transcripts, the
     downgrade's target and the dropped-install lines);
   - **do not move:** the test's stubs that only order tags or are refused (`v1.0.5`, `v1.0.10`,
     `v1.0.9.1`, `v2.0.0-rc1`, `v9.9.9`, `v1.0`, and `v1.0.9;x`, which stays refused whatever the
     release), unless the release being cut is one of them, in which case that stub takes the next
     higher version.

   (`.claude-plugin/marketplace.json` carries no version.) Also retitle `CHANGELOG.md`'s
   `## Unreleased` as `## vX.Y.Z — YYYY-MM-DD`, through a pull request like any other change. The date is the
   UTC date the release pull request opens (`gh pr view --json createdAt`), which can differ by a day from the
   engineer's local date. Once that pull request merges, test the merged commit — the one the tag will name — from a clean clone:

   ```bash
   dir=$(mktemp -d) && git clone https://github.com/kbajpai/codeo.git "$dir" && cd "$dir"
   bash tests/run.sh
   ```

   It must end `all cases passed`.

   When a project keeps a golden directory of finished dossiers, replay it too:

   ```bash
   CODEO_GOLDEN_DIR=<the project's golden directory> bash tests/replay.test.sh
   ```

   It must end `all as expected`.

   The changelog's `Shared state:` line must name every dossier convention a script or a skill
   reads back — today `qc round at review: <k>`, `### Round <n> — stashed|abandoned` and the forms the dossier checker reads — since a
   project mid-workflow carries dossiers written to them.

7. Tag and push the release, then check it from a clean clone:

   ```bash
   git tag vX.Y.Z && git push origin vX.Y.Z
   git ls-remote --tags origin
   ```

8. Create the GitHub Release from the changelog section only, with its notes in a file and no
   generated notes. Put the lines between the `## vX.Y.Z` heading and the next version's heading
   in a file (without the heading), then:

   ```bash
   gh release create vX.Y.Z --verify-tag --title vX.Y.Z --notes-file <the section>
   ```

   Never pass `--generate-notes`. A Release that was created with generated notes is repaired with:

   ```bash
   gh release edit vX.Y.Z --notes-file <the section>
   ```

A pushed tag is never moved. A fix ships as the next version. The tag ruleset's admin bypass would
let the owner move one by mistake, so this rule is a convention that GitHub does not enforce.
