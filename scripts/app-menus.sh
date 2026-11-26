#!/usr/bin/env bash
# Usage: app-menus.sh [apply|restore]   (default apply)
# Hides the apps' own in-window menu bars so the global menu (Orbit) is the only menu. Orbit has shortcut menus for these apps.
# Only touches apps that are installed (config file exists), backs up each file first to
#   ~/.local/state/ricing/app-config/<time>/ , and skips Electron apps that are running.
# restore: puts the files from the newest backup back.
set -euo pipefail
mode=${1:-apply}
root=${XDG_STATE_HOME:-$HOME/.local/state}/ricing/app-config

if [[ $mode == restore ]]; then
  b=$(ls -d "$root"/*/ 2>/dev/null | sort | tail -n1 || true); [[ -n $b ]] || { echo "no backup in $root" >&2; exit 1; }
  while IFS=$'\t' read -r orig rel; do cp -p "$b/$rel" "$orig" && echo "restored $orig"; done < "$b/manifest.tsv"
  exit 0
fi
[[ $mode == apply ]] || { echo "usage: app-menus.sh [apply|restore]" >&2; exit 2; }

b=$root/$(date +%Y%m%d-%H%M%S); mkdir -p "$b"; : > "$b/manifest.tsv"; n=0
backup() { n=$((n+1)); cp -p "$1" "$b/$n.bak"; printf '%s\t%s\n' "$1" "$n.bak" >> "$b/manifest.tsv"; }

# VS Code and forks: window.menuBarVisibility = hidden (live, no restart needed)
for d in Code Cursor Antigravity Kiro Qoder Windsurf VSCodium; do
  f=$HOME/.config/$d/User/settings.json
  [[ -f $f ]] || continue
  grep -qE '"(editor|workbench|window)\.' "$f" || { echo "skip $d: settings.json does not look like VS Code settings"; continue; }
  backup "$f"
  python3 -I - "$f" <<'PY' && echo "ok   $d: window.menuBarVisibility=hidden" || { echo "FAIL $d (file left unchanged)"; exit 1; }
import json, re, sys
p = sys.argv[1]; s = open(p).read()
try: json.loads(s); strict = True
except ValueError: strict = False          # JSONC: can't validate, edit is textual only
pat = re.compile(r'("window\.menuBarVisibility"\s*:\s*)"[^"]*"')
if pat.search(s):
    t = pat.sub(r'\1"hidden"', s)
else:
    i = s.index('{') + 1
    empty = s[i:].strip().startswith('}')
    t = s[:i] + '\n    "window.menuBarVisibility": "hidden"' + ('' if empty else ',') + s[i:]
if strict: json.loads(t)                    # never write something that no longer parses
if t != s: open(p, 'w').write(t)
PY
done

# Slack (Flatpak): autoHideMenuBar=true in its saved window state. Slack rewrites this file on exit, so it must be closed.
f=$HOME/.var/app/com.slack.Slack/config/Slack/storage/root-state.json
if [[ -f $f ]]; then
  if flatpak ps --columns=application 2>/dev/null | grep -qx com.slack.Slack; then echo "skip Slack: it is running; close it and re-run"
  else
    backup "$f"
    python3 -I - "$f" <<'PY' && echo "ok   Slack: autoHideMenuBar=true (menu appears only while Alt is held)" || { echo "FAIL Slack (file left unchanged)"; exit 1; }
import json, sys
p = sys.argv[1]; d = json.load(open(p))
def walk(x):
    if isinstance(x, dict):
        for k, v in x.items():
            if k == 'autoHideMenuBar': x[k] = True
            else: walk(v)
    elif isinstance(x, list):
        for v in x: walk(v)
walk(d)
open(p, 'w').write(json.dumps(d, separators=(',', ':')))
PY
  fi
fi

echo "Nothing known to change for: Firefox, Thunderbird (menu bar already hidden by default), Discord, Obsidian, Telegram, Steam, Claude (no menu-bar setting found)."
echo "backup: $b   (undo: scripts/app-menus.sh restore)"
