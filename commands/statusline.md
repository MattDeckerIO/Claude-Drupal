---
description: Show the current folder name at the start of the Claude Code status line
---

Add the current folder name to the user's Claude Code status line, so they can tell sessions apart.

1. Read `~/.claude/settings.json`. If it doesn't exist, create it with `{}`.
2. If it has no `statusLine`, add exactly:

   ```json
   "statusLine": {
     "type": "command",
     "command": "jq -r '\"\\u001b[1;36m\" + ((.workspace.current_dir // .cwd) | split(\"/\") | last) + \"\\u001b[0m\"'"
   }
   ```

3. If it already has a `statusLine` command that doesn't show the folder, keep it and put the folder in front. Use `input=$(cat)`, print the folder with the jq expression above, then a space, then pipe `$input` into the existing command.
4. Merge into the file. Don't touch other keys. Check the result with `jq -e .statusLine ~/.claude/settings.json`.
5. Tell the user it needs `jq` and shows up in new sessions.
