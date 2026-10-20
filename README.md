# drupal-kit

Drupal 10/11 agents, skills, and commands for [Claude Code](https://claude.com/claude-code),
packaged as a plugin.

## Install

```
/plugin marketplace add mdecker/claude-drupal
/plugin install drupal-kit@drupal-kit
```

The repo path and the plugin name differ on purpose: `claude-drupal` is the
repo, `drupal-kit` is the plugin (Claude Code reserves the `claude-` prefix).
Replace the repo path with wherever you actually push this.

To use it from a local checkout while developing:

```
/plugin marketplace add /path/to/claude-drupal
```

## What's in it

| Component | Does |
|---|---|
| `agents/drupal-specialist.md` | Drupal/PHP subagent — modules, themes, hooks, services, routing |
| `skills/drupal-module-scaffold/` | Scaffolds a custom module with only the files the feature needs |
| `skills/drupal-drush/` | Picks the right Drush wrapper and the right cache/config command |
| `commands/drupal-cr.md` | `/drupal-kit:drupal-cr` — rebuild caches |
| `hooks/phpcs-check.sh` | Lints edited PHP with the project's phpcs, if installed |

Skills are invoked as `/drupal-kit:<skill-name>`, or picked up automatically
when the task matches their description.

## Layout

```
.claude-plugin/
  plugin.json          plugin manifest
  marketplace.json     makes this repo its own marketplace
agents/*.md            subagents (name + description frontmatter required)
skills/<name>/SKILL.md skills; put long content in references/ beside it
commands/*.md          slash commands
hooks/hooks.json       hook config; scripts beside it
```

Everything except `plugin.json` and `marketplace.json` lives at the repo root
and is auto-discovered — no need to list files in the manifest.

## Adding to it

New agent: drop a `.md` in `agents/` with `name` and `description` frontmatter.
Write the description so it says *when* to use the agent, not just what it is —
that's what Claude matches against.

New skill: `skills/<kebab-name>/SKILL.md`. Keep the body short and move
templates or long reference material into `references/` next to it, linked from
the body. The skill body loads into context; references load only when read.

Validate before committing:

```
claude plugin validate .
```

## Hook note

The phpcs hook is a no-op unless `vendor/bin/phpcs` exists in the project. It
requires `jq`. It detects Docksal (`.docksal/` → `fin exec`) and DDEV, falling
back to the host binary, so it works where PHP only exists inside the
container. It runs on every Write/Edit in any project with the plugin enabled —
remove `hooks/hooks.json` if you don't want that.
