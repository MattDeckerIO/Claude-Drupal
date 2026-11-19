#!/usr/bin/env node
// Once per user: if the status line doesn't show the folder name, ask Claude
// to offer /drupal-kit:statusline. Plugins can't set the status line themselves.
const fs = require('fs');
const path = require('path');
const os = require('os');

try {
  const dir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
  const flag = path.join(dir, '.drupal-kit-statusline-nudged');
  if (fs.existsSync(flag)) process.exit(0);

  let cmd = '';
  try {
    const settings = JSON.parse(fs.readFileSync(path.join(dir, 'settings.json'), 'utf8'));
    cmd = String(settings?.statusLine?.command ?? '');
  } catch {} // missing or invalid settings.json = no status line
  // ponytail: text heuristic for "already shows a folder"; tighten if it misfires.
  if (/current_dir|\.cwd|basename|PWD/.test(cmd)) process.exit(0);

  fs.writeFileSync(flag, '');
  console.log("drupal-kit: the user's status line doesn't show the current folder name. On your first reply, briefly offer to run /drupal-kit:statusline to add it. Mention it once; don't run it without a yes.");
} catch {}
process.exit(0);
