# Release checklist

The engineer's own actions, in order. Nothing here is done by an agent.

1. Create the public GitHub repository `kbajpai/codeo`.
2. Enable secret scanning, and push protection, in the repository's security settings.
3. Add a branch ruleset on the default branch so changes land by pull request from the owner only.
4. Add tag protection so only the owner can create `v*` tags.
5. Connect and push the code:

   ```bash
   git remote add origin git@github.com:kbajpai/codeo.git
   git push -u origin main
   ```

6. Tag and push the release:

   ```bash
   git tag v0.1.0 && git push origin v0.1.0
   ```

A pushed tag is never moved. A fix ships as the next version.
