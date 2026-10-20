---
name: drupal-drush
description: Run the right Drush command for a Drupal task, and know which cache/config/update command a code change requires. Use when the user mentions Drush, clearing cache, exporting or importing config, database updates, cron, user login links, or asks why a Drupal change is not showing up.
---

# Drush

## Find it first

Drush is per-project, not global. In order of preference:

1. `fin drush ...` — if `.docksal/` exists. **Docksal, check this first.**
2. `ddev drush ...` — if `.ddev/` exists.
3. `lando drush ...` — if `.lando.yml` exists.
4. `vendor/bin/drush ...` — plain composer project.
5. `drush ...` — only if the above are absent and it's on PATH.

Check with `ls -d .docksal .ddev .lando.yml vendor/bin/drush 2>/dev/null`
before guessing. If none resolve, give the user the command to run rather than
inventing one.

## Docksal

Docksal runs everything inside the container, so `fin` prefixes the whole
command — not just Drush:

```
fin drush cr
fin composer require drupal/token
fin composer install
fin exec php ...
```

A bare `composer` or `drush` on the host hits the wrong PHP version, or no PHP
at all. When `.docksal/` exists, prefix every Drush *and* Composer command with
`fin`.

Useful Docksal commands:

```
fin start / fin stop / fin restart
fin status                  # container state
fin logs -f
fin db-import <file.sql>
fin db-export
fin bash                    # shell inside the cli container
```

Projects often define custom commands in `.docksal/commands/` — check there
(`ls .docksal/commands`) before assuming a task needs raw Drush. `fin init` is
common and usually rebuilds the whole site.

## "My change isn't showing up"

Almost always a cache or discovery problem. Match the change to the command:

| Changed | Run |
|---|---|
| Routing, services, hooks, plugins, info.yml, Twig | `drush cr` |
| Added an `hook_update_N()` | `drush updb` |
| Config YAML in `config/sync` | `drush cim` |
| Config via the UI, needs committing | `drush cex` |
| Entity/field schema in code | `drush updb` then `drush cr` |
| Nothing above fits | `drush cr` anyway, then look harder |

`drush cr` is a full rebuild and always safe. There is no `drush cc all` in
Drupal 8+.

## Common commands

```
drush st                      # status: core version, db, paths, bootstrap
drush en <module> -y          # enable
drush pmu <module> -y         # uninstall
drush uli                     # one-time login link (admin)
drush uli --name=<user>
drush upwd <user> <password>
drush cron
drush ws --tail               # watchdog log, needs dblog
drush sqlq "SELECT ..."       # raw query
drush sql:dump --result-file=../backup.sql
drush php:eval '...'          # evaluate PHP in a bootstrapped Drupal
drush ev '...'                # same, short form
```

## Config workflow

Export is a whole-site diff, not a per-file write. Review before committing:

```
drush cex -y
git diff config/
```

`drush cim` overwrites the database with the files. On a production-like
environment confirm with the user before running it — unexported UI changes
are lost.

## Destructive — confirm first

`drush sql:drop`, `drush sql:cli` with a write statement, `drush cim` on a
live site, and `drush sqlq` with UPDATE/DELETE all change or destroy data.
Ask before running any of them, and suggest `drush sql:dump` first.

## Updates

Prefix with the project's wrapper (`fin`, `ddev`, `lando`) — Composer included:

```
composer update drupal/core-* --with-all-dependencies
drush updb -y
drush cr
drush cex -y
```

Under Docksal that is `fin composer update ...`, `fin drush updb -y`, and so on.
