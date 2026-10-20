#!/usr/bin/env bash
# Lints edited PHP/module files with the project's phpcs, if it has one.
# Silent no-op when phpcs isn't installed or the file isn't Drupal PHP.
set -uo pipefail

file=$(jq -r '.tool_input.file_path // empty')
case "$file" in
  *.php|*.module|*.inc|*.install|*.theme|*.profile) ;;
  *) exit 0 ;;
esac

phpcs="${CLAUDE_PROJECT_DIR:-.}/vendor/bin/phpcs"
[ -x "$phpcs" ] || exit 0

out=$("$phpcs" --standard=Drupal,DrupalPractice "$file" 2>&1) || {
  echo "phpcs findings in $file:" >&2
  echo "$out" >&2
  exit 2
}
exit 0
