---
name: drupal-security-update
description: Apply outstanding Drupal security updates with the smallest version bump that fixes them - patch, then minor, then major only as a last resort. Use when the user asks about security updates, drush pm:security, vulnerable modules, CVEs or SAs in a Drupal site, or asks to update Drupal core or contrib for security.
---

# Drupal security updates

Six phases, in order. Do not skip phase 1 — a dirty config state makes the
post-update export unreadable.

Every `drush` and `composer` call below needs the project's wrapper (`fin`,
`ddev`, `lando`, `vendor/bin`). See the `drupal-drush` skill. Under Docksal
that means `fin composer ...` too, not just Drush.

## 1. Clean the config state first

```
git status --porcelain
drush cex --diff
```

- Uncommitted changes under `config/` → ask the user to commit or stash them.
- `cex --diff` shows pending exports → the database holds UI changes nobody
  captured. Run `drush cex -y`, review, and commit as its own
  "Capture outstanding config changes" commit **before** touching composer.

Both must be clean. Otherwise phase 4's export mixes somebody's unrelated UI
tinkering into the security commit and nobody can tell which is which.

## 2. Find what's vulnerable

```
drush pm:security
drush pm:security --format=json   # when parsing
```

Exit code 0 and "no outstanding security updates" means stop — report it and
do nothing else. Non-zero means there is work.

Also run `drush pm:security-php` for vulnerable non-Drupal composer packages
if the site has it; same rules apply.

Record for each package: current version, the version Drush says fixes it.

## 3. Update with the smallest bump that works

Per package, climb only as far as needed. Stop at the first rung that
resolves:

| Rung | Command |
|---|---|
| Patch | `composer update drupal/<name> --with-dependencies` |
| Minor | `composer require drupal/<name>:^<cur_major>.<next_minor> -W` |
| Major | `composer require drupal/<name>:^<next_major> -W` |

Use `composer why-not drupal/<name> <version>` when a bump refuses to move —
usually another package's constraint, not the package itself.

Rules:

- Re-run `drush pm:security` after each rung. If the SA is gone, stop.
- Core is `drupal/core-*`: `composer update "drupal/core-*" -W`.
- **A major bump needs the user's say-so before it runs.** Majors carry
  breaking API changes, removed hooks, and often a required core version.
  Say which package, from what to what, and what the release notes flag.
- `--with-all-dependencies` (`-W`) is near-always required; without it
  Composer silently refuses the bump and reports nothing to update.

Then finish the update:

```
drush updb -y
drush cr
```

## 4. Capture resulting config

```
drush cex -y
git diff config/
```

Module updates add, rename, and remove config keys. This export is what the
update actually did to the site's config.

## 5. Review the config diff for breaking changes

Read `git diff config/` and flag, specifically:

| Pattern in the diff | Why it matters |
|---|---|
| Removed keys in `field.*` / `core.entity_*` | Field or display settings dropped — content or layout loss |
| `core.extension.yml` module removed | A dependency was dropped, not just updated |
| Changed `dependencies:` blocks | New module requirements, possible install order problems |
| View/display handler or plugin id renamed | Plugin moved or was deprecated; stale references break the view |
| `_core: default_config_hash` churn **only** | Noise. Not a breaking change. Say so and move on. |
| Permission machine names changed | Roles silently lose access |
| Deleted config entities (whole files) | Something was removed, not migrated — confirm it was intentional |

Report findings as: file, what changed, what breaks. If the diff is only hash
churn and version bumps, say that plainly rather than manufacturing concerns.

Also check `drush ws --severity=Error --count=20` after `drush cr` for
deprecation or missing-plugin errors the config diff won't show.

## 6. Propose commit messages

Propose, do not commit, unless the user asked you to commit.

Short (the subject line):

```
Security update: <pkg> <old> -> <new>, <pkg2> <old> -> <new>
```

Two or more packages, keep the subject under ~72 chars by collapsing:
`Security update: core and 3 contrib modules`.

Extended body:

```
Security update: drupal/core 10.3.1 -> 10.3.6

Resolves:
- SA-CORE-2025-001 (critical) - drupal/core 10.3.1 -> 10.3.6
- SA-CONTRIB-2025-042 (moderate) - drupal/webform 6.2.2 -> 6.2.9

Bump scope: patch only, except drupal/webform (minor - no patch release
fixes SA-CONTRIB-2025-042).

Config changes: field.storage.node.field_foo picked up a new
`cardinality_container` key; the rest is default_config_hash churn.

Breaking changes: none identified. Webform 6.2.9 deprecates
WebformSubmissionForm::getCustomForm(); no call sites in this codebase.
```

Say "Breaking changes: none identified" only after actually doing phase 5.

## Never

- Never run `drush cim` as part of this flow. The database is the source of
  truth for what the update produced; importing would undo it.
- Never bump a major version without asking.
- Never bundle unrelated feature config into the security commit — that was
  phase 1's job.
