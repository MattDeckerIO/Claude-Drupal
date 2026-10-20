---
name: drupal-module-scaffold
description: Scaffold a new Drupal 10/11 custom module with the minimum set of files that actually work - info.yml plus only the files the requested feature needs. Use when the user asks to create, generate, or scaffold a Drupal module, or add a service, route, controller, form, plugin, or hook to a custom module.
---

# Drupal module scaffold

Create only the files the requested feature needs. A module that just
implements a hook needs two files, not twelve.

## Location

`web/modules/custom/<machine_name>/` — or `modules/custom/` if the project has
no `web/` docroot. Check first.

Machine name: lowercase, underscores, not a reserved core/contrib name.

## Always

`<machine_name>.info.yml`:

```yaml
name: Human Readable Name
type: module
description: 'One sentence on what it does.'
package: Custom
core_version_requirement: ^10 || ^11
```

Add `dependencies:` only for modules actually used, as `drupal:node`,
`paragraphs:paragraphs`.

## Add only when needed

| Need | File |
|---|---|
| Hook implementations | `<name>.module` |
| Schema/update hooks | `<name>.install` |
| Injected service | `<name>.services.yml` + `src/<Thing>.php` |
| Route | `<name>.routing.yml` + `src/Controller/<Name>Controller.php` |
| Settings form | `<name>.routing.yml` + `src/Form/<Name>SettingsForm.php` + `config/schema/<name>.schema.yml` |
| Permissions | `<name>.permissions.yml` |
| Menu/local task links | `<name>.links.menu.yml` / `<name>.links.task.yml` |
| Plugin (block, field, etc.) | `src/Plugin/<Type>/<Name>.php` with its attribute |
| CSS/JS | `<name>.libraries.yml` + `css/` / `js/` |

Namespace is always `Drupal\<machine_name>\...`, PSR-4 under `src/`.

## Drupal 11 note

Plugins use PHP attributes (`#[Block(...)]`), not annotations. Annotations still
work in D10 but are deprecated — use attributes unless the project targets D9.

## Reference

Full file templates with working code: `references/templates.md`.

## After scaffolding

`drush en <machine_name>` then `drush cr`. Tell the user; don't assume a Drush
environment exists.
