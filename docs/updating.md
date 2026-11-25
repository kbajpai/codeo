# Updating, replacing and restoring codeo

This page covers what happens when you run the install command again: an update to a newer release, a downgrade, and what a replace does to codeo installs in other projects. The first install is in the [README](../README.md).

## Updating

Run the install command again. With no `--version` it installs the latest release; if that differs from what you have, it removes the codeo marketplace, which uninstalls codeo at every scope on the machine, adds the marketplace back at the new tag, and installs codeo at the scope you asked for. A plain run installs it for you; a run with `--scope project` installs it for the project:

```
install: release v1.0.9
install: superpowers already installed (user scope), left alone
✔ Successfully removed marketplace: codeo
Also uninstalled 1 plugin from this marketplace:
  codeo@codeo
The removal also deletes their saved options, secrets and data where it can.
To use a plugin again, add the marketplace back and reinstall the plugin.
install: codeo v1.0.8 -> v1.0.9 (user scope)
install: done - codeo v1.0.9, user scope, superpowers 7.0.2
install: restart any Claude Code sessions already open to load the plugins
```

To install a release other than the latest, pass `--version` (as in the README). A run that asks for a different version than the one installed replaces it, so this is also how you go back to an older release. Downgrading to `v1.0.8` prints:

```
install: release v1.0.8
install: superpowers already installed (user scope), left alone
✔ Successfully removed marketplace: codeo
Also uninstalled 1 plugin from this marketplace:
  codeo@codeo
The removal also deletes their saved options, secrets and data where it can.
To use a plugin again, add the marketplace back and reinstall the plugin.
install: codeo v1.0.9 -> v1.0.8 (user scope)
install: done - codeo v1.0.8, user scope, superpowers 7.0.2
install: restart any Claude Code sessions already open to load the plugins
```

## What a replace drops

One machine holds one codeo version, so a replace does not keep the other scopes' copies: removing the marketplace uninstalls codeo from every project and every local install on the machine, not only the one you ran the command in. The installer prints one line for each project install and each local install it dropped, with the command that restores it, and it leaves every project's `.claude/settings.json` and `.claude/settings.local.json` as they were, so `git status` stays clean. The project the command runs in is named too, when you ran a plain run inside it. A plain update run from your home folder, with codeo installed for two projects and locally for a third:

```
install: release v1.0.9
install: superpowers already installed (user scope), left alone
✔ Successfully removed marketplace: codeo
Also uninstalled 1 plugin from this marketplace:
  codeo@codeo
The removal also deletes their saved options, secrets and data where it can.
To use a plugin again, add the marketplace back and reinstall the plugin.
install: codeo v1.0.8 -> v1.0.9 (user scope)
install: codeo is no longer installed for /home/you/app (project scope, v1.0.8); its .claude/settings.json was not changed; run claude plugin install codeo@codeo --scope project there to restore it
install: codeo is no longer installed for /home/you/api (project scope, v1.0.8); its .claude/settings.json was not changed; run claude plugin install codeo@codeo --scope project there to restore it
install: codeo is no longer installed for /home/you/loc (local scope, v1.0.8); its .claude/settings.local.json was not changed; run claude plugin install codeo@codeo --scope local there to restore it
install: done - codeo v1.0.9, user scope, superpowers 7.0.2
install: restart any Claude Code sessions already open to load the plugins
```

## Restoring a project or local install

`claude plugin list` shows the machine afterwards: codeo is installed for you at the new release and for no project. To restore a project, run the printed command in that project. For a project-scope install it is `claude plugin install codeo@codeo --scope project`, which installs the release the machine now has, changes no file (the project's committed `ref` stays as the team had it, so `git status` stays clean) and cannot start another replace:

```
$ cd /home/you/app
$ claude plugin install codeo@codeo --scope project
Installing plugin "codeo@codeo"...✔ Successfully installed plugin: codeo@codeo (scope: project)
```

A local install is restored the same way with `--scope local`:

```
$ cd /home/you/loc
$ claude plugin install codeo@codeo --scope local
Installing plugin "codeo@codeo"...✔ Successfully installed plugin: codeo@codeo (scope: local)
```

`claude plugin list` then shows the install again, with its scope and the machine's version. The restore does not move the project's pin. To move it, edit `ref` in the project's `.claude/settings.json` and commit it, as *Moving a project's pin* below describes; `install.sh --scope project` run in a restored project changes nothing, because its install is already at the machine's version. A `--scope project` run rewrites the project's `ref` only when it installs or replaces codeo at project scope (the project has no install, or the machine's codeo is at another release). That run also reinstalls a user-scope copy that existed at the same release and names every other project it dropped:

```
install: release v1.0.9
install: superpowers already installed (project scope), left alone
✔ Successfully removed marketplace: codeo
Also uninstalled 1 plugin from this marketplace:
  codeo@codeo
The removal also deletes their saved options, secrets and data where it can.
To use a plugin again, add the marketplace back and reinstall the plugin.
install: codeo v1.0.8 -> v1.0.9 (project scope)
install: your user-scope codeo moved to v1.0.9 too: one machine holds one codeo version
install: codeo is no longer installed for /home/you/api (project scope, v1.0.8); its .claude/settings.json was not changed; run claude plugin install codeo@codeo --scope project there to restore it
install: done - codeo v1.0.9, project scope, superpowers 7.0.2
install: restart any Claude Code sessions already open to load the plugins
```

## When an update fails

The marketplace is removed before the new one is added, so if a step fails in between (the network drops, say), codeo is left uninstalled. The installer then prints the dropped-install lines, if any, and ends with `install: codeo is no longer installed: <the last line claude printed>; run this again`; running the same command again finishes the job, and the restore commands apply once it has finished, because they need the codeo marketplace. When a `--scope project` update that removed a user-scope copy fails, the line ends `run this again with --scope project, then once without --scope to restore your user-scope copy`. When one scope was reinstalled and the other was not, it prints `install: codeo v1.0.9 is installed at project scope but not at user scope: <the last line claude printed>; run this again with --scope user`. A user-scope copy that was disabled comes back enabled, and the line says so: `install: codeo v1.0.8 -> v1.0.9 (user scope) (it was disabled; it is enabled now)`.

A plain update run from your home folder that fails at the add step, with codeo installed for two projects and locally for a third, prints the dropped installs before the error:

```
install: release v1.0.9
install: superpowers already installed (user scope), left alone
✔ Successfully removed marketplace: codeo
Also uninstalled 1 plugin from this marketplace:
  codeo@codeo
The removal also deletes their saved options, secrets and data where it can.
To use a plugin again, add the marketplace back and reinstall the plugin.
install: codeo is no longer installed for /home/you/app (project scope, v1.0.8); its .claude/settings.json was not changed; run claude plugin install codeo@codeo --scope project there to restore it
install: codeo is no longer installed for /home/you/api (project scope, v1.0.8); its .claude/settings.json was not changed; run claude plugin install codeo@codeo --scope project there to restore it
install: codeo is no longer installed for /home/you/loc (local scope, v1.0.8); its .claude/settings.local.json was not changed; run claude plugin install codeo@codeo --scope local there to restore it
install: codeo is no longer installed: Error: network unreachable; run this again
```

Before you run the install command, read [`CHANGELOG.md`](../CHANGELOG.md) for every release between yours and the new one. Each entry opens with three lines: `Config schema` (a project's `.codeo/config.json` must not be newer than the plugin understands), `Shared state` (what the plugin keeps on GitHub or in `.codeo/` that changed) and `Safe to bump mid-workflow` (`yes`, or what to finish first). Projects whose install the update drops are named in its output (see *What a replace drops*).

## Updating superpowers

superpowers is left alone by the installer when it is already installed. Update it with:

```
$ claude plugin update superpowers@superpowers-marketplace
Checking for updates for plugin "superpowers@superpowers-marketplace"…
✔ superpowers is already at the latest version (7.0.2).
```

## Moving a project's pin

A project's pin lives in its `.claude/settings.json`: edit `ref` under `extraKnownMarketplaces.codeo.source` to the new tag, commit it, and a teammate who trusts the folder gets the new release. To move your own copy to the same release, run the install command with `--version` and that tag, then restart every open Claude Code session.
