#!/usr/bin/env bash
# Lints edited PHP/module files with the project's phpcs, if it has one.
# Silent no-op when phpcs isn't installed or the file isn't Drupal PHP.
set -uo pipefail

file=$(jq -r '.tool_input.file_path // empty')
case "$file" in
  *.php|*.module|*.inc|*.install|*.theme|*.profile) ;;
  *) exit 0 ;;
esac

root="${CLAUDE_PROJECT_DIR:-.}"
[ -x "$root/vendor/bin/phpcs" ] || exit 0

# Containerized environments need their wrapper; the host has no PHP.
if [ -d "$root/.docksal" ] && command -v fin >/dev/null; then
  run=(fin exec vendor/bin/phpcs)
  file="${file#"$root"/}"   # fin runs relative to the project root
elif [ -d "$root/.ddev" ] && command -v ddev >/dev/null; then
  run=(ddev exec vendor/bin/phpcs)
  file="${file#"$root"/}"
else
  run=("$root/vendor/bin/phpcs")
fi

out=$(cd "$root" && "${run[@]}" --standard=Drupal,DrupalPractice "$file" 2>&1) || {
  echo "phpcs findings in $file:" >&2
  echo "$out" >&2
  exit 2
}
exit 0
