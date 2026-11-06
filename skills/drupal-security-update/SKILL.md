---
name: drupal-security-update
description: Apply outstanding Drupal security updates with the smallest version bump that fixes them - patch, then minor, then major only as a last resort. Use when the user asks about security updates, drush pm:security, vulnerable modules, CVEs or SAs in a Drupal site, or asks to update Drupal core or contrib for security.
---

# Drupal security updates

Seven phases, in order. Do not skip phase 1 — a dirty config state makes the
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

Both must be clean. Otherwise phase 5's export mixes somebody's unrelated UI
tinkering into the security commit and nobody can tell which is which.

## 2. Find what's vulnerable

```
composer audit                    # security advisories (Drupal SAs + Packagist)
composer audit --abandoned=report # abandoned packages
```

Exit code 0 means no advisories. Do not stop there — phase 3 still runs.
Non-zero means there is work.

Record for each package: current version, the version the advisory says
fixes it.

## 3. Find unsupported releases

`composer audit` does not flag a release that is merely unsupported. Check:

```
drush php:eval '
\Drupal::moduleHandler()->loadInclude("update","inc","update.compare");
$p = update_calculate_project_data(update_get_available(TRUE));
foreach ($p as $n => $x) if (in_array($x["status"], [2, 3]))  // REVOKED, NOT_SUPPORTED
  echo "$n {$x["existing_version"]}\n";'
```

For each hit, read the supported branches from
`https://updates.drupal.org/release-history/<project>/current` (the
`<supported_branches>` element).

Rules for each hit:

- A supported branch exists in the same major → use the normal minor bump
  in phase 4. No permission needed.
- The only supported branch is a newer major → treat it like any major
  bump. Stop and report the package, its current version, the target
  branch, the release notes, and any companion modules that have to move
  with it (for example `imagemagick` with `image_effects`). Wait for
  approval.
- Never treat an alpha, beta or dev branch as the fix unless it's the only
  supported branch, and say so if it is.

If phases 2 and 3 both come back clean, stop — report it and do nothing
else.

## 4. Update with the smallest bump that works

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

- Re-run `composer audit` after each rung. If the SA is gone, stop.
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

## 5. Capture resulting config

```
drush cex -y
git diff config/
```

Module updates add, rename, and remove config keys. This export is what the
update actually did to the site's config.

## 6. Review the config diff for breaking changes

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

## 7. Propose commit messages

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

Unsupported releases:
- drupal/imagemagick 3.x -> 4.x (major, approved; image_effects moved
  with it)

Breaking changes: none identified. Webform 6.2.9 deprecates
WebformSubmissionForm::getCustomForm(); no call sites in this codebase.
```

Report unsupported releases in their own section, separate from security
advisories, so they aren't missed when the audit comes back clean. Leave
the section out only if phase 3 found nothing.

Say "Breaking changes: none identified" only after actually doing phase 6.

## Never

- Never run `drush cim` as part of this flow. The database is the source of
  truth for what the update produced; importing would undo it.
- Never bump a major version without asking.
- Never bundle unrelated feature config into the security commit — that was
  phase 1's job.
