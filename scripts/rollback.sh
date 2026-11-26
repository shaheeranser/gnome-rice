#!/usr/bin/env bash
# Usage: rollback.sh [-y] <label|snapshot-dir>   Restore a snapshot exactly (newest match for a label).
. "$(dirname "$0")/lib.sh"
[[ ${1:-} == -y ]] && { YES=1; shift; }
arg=${1:?usage: rollback.sh [-y] <label|snapshot-dir>}
if [[ -d $arg ]]; then dir=$arg
else
  dir=$(for d in "${SNAPDIRS[@]}"; do compgen -G "$d/*-$arg" || true; done | awk -F/ '{print $NF" "$0}' | sort | tail -n1 | cut -d' ' -f2-)
  [[ -n $dir ]] || { echo "no snapshot matching '$arg'" >&2; exit 1; }
fi
echo "Will RESET then reload these dconf paths from $dir:"; printf '  %s\n' "${PATHS[@]}"
echo "and set enabled-extensions to: $(cat "$dir/enabled-extensions.txt")"
confirm
load_all "$dir" reset
gsettings set org.gnome.shell enabled-extensions "$(cat "$dir/enabled-extensions.txt")"
echo "restored. Log out and in to reload the shell."
