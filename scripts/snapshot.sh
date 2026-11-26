#!/usr/bin/env bash
# Usage: snapshot.sh <label>   Read-only dump of tracked dconf paths + enabled extensions.
. "$(dirname "$0")/lib.sh"
label=${1:?usage: snapshot.sh <label>}
[[ $label =~ ^[A-Za-z0-9._-]+$ ]] || { echo "label: letters, digits, . _ - only" >&2; exit 2; }
dir=$(snap_write_dir)/$(date +%Y%m%d-%H%M%S)-$label
echo "Will write snapshot to $dir (read-only on dconf)"
dump_all "$dir"
echo "done: $dir"
