#!/usr/bin/env bash
# One-shot installer.
#   curl -fsSL https://raw.githubusercontent.com/shaheeranser/gnome-rice/main/install.sh | bash -s -- -y
#   or, from a clone:  ./install.sh [-y] [--super] [--drop-redundant] [--extras] [--app-menus]
# Clones (or updates) the repo into ~/.local/share/gnome-rice, snapshots your GNOME settings, then applies the setup.
# All options except --app-menus are passed to scripts/apply-all.sh; --app-menus then runs scripts/app-menus.sh.
set -euo pipefail
REPO_URL=${RICE_REPO:-https://github.com/shaheeranser/gnome-rice.git}
DEST=${RICE_DIR:-$HOME/.local/share/gnome-rice}

for c in git gnome-shell gnome-extensions dconf gsettings python3 unzip; do
  command -v "$c" >/dev/null || { echo "missing required tool: $c (see README, Requirements)" >&2; exit 1; }
done
ver=$(gnome-shell --version | grep -oE '[0-9]+' | head -n1)
[[ $ver == 50 ]] || echo "WARNING: GNOME Shell $ver found; the bundled extensions are pinned for GNOME 50 and may not load" >&2
[[ ${XDG_SESSION_TYPE:-} == wayland ]] || echo "WARNING: not a Wayland session; the touchpad gestures are Wayland-only" >&2

if [[ -d $DEST/.git ]]; then git -C "$DEST" pull --ff-only; else git clone --depth 1 "$REPO_URL" "$DEST"; fi

app_menus=0; args=()
for a in "$@"; do [[ $a == --app-menus ]] && app_menus=1 || args+=("$a"); done
"$DEST/scripts/apply-all.sh" "${args[@]}"
[[ $app_menus == 1 ]] && "$DEST/scripts/app-menus.sh"
echo "Done. Log out and back in to load the extensions. Undo: $DEST/scripts/rollback.sh before-all"
