---
description: Rebuild Drupal caches using whatever Drush wrapper this project uses.
---

Detect the project's Drush and rebuild caches:

1. Check for `.docksal/`, `.ddev/`, `.lando.yml`, `vendor/bin/drush` in that
   order.
2. Run the cache rebuild with the first one found: `fin drush cr`,
   `ddev drush cr`, `lando drush cr`, or `vendor/bin/drush cr`.
3. If none are found, tell the user and stop — don't guess at a global `drush`.

Report the result in one line.
