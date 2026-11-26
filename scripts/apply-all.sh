#!/usr/bin/env bash
# Usage: apply-all.sh [-y] [--super] [--drop-redundant] [--extras]
# Snapshots (label before-all), then applies the planned setup in ONE go. Log out and in afterwards.
#   -y                 skip the confirmation prompt (needed when there is no terminal, e.g. run via Claude's ! prefix)
#   default            swipe-windows + arcmenu + global-menu + places
#   --super            also make Super open ArcMenu (arcmenu-super)
#   --drop-redundant   also disable Fedora's apps-menu (places-menu is kept)
#   --extras           also apply settings for Dash to Dock, Blur My Shell, Just Perfection, AppIndicator and enable Continuum (install them first, see README)
# Undo: scripts/rollback.sh before-all   (works from a TTY too)
. "$(dirname "$0")/lib.sh"
steps=(swipe-windows arcmenu global-menu places)
for a in "$@"; do
  case $a in
    -y) export YES=1 ;;
    --super) steps+=(arcmenu-super) ;;
    --drop-redundant) steps+=(drop-redundant) ;;
    --extras) steps+=(extras) ;;
    *) echo "unknown option $a" >&2; exit 2 ;;
  esac
done
"$REPO/scripts/snapshot.sh" before-all
exec "$REPO/scripts/apply.sh" "${steps[@]}"
