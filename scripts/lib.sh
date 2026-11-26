# Shared by all scripts. Acts on the current user only.
set -euo pipefail
# From a TTY there is no session bus and dconf/gsettings writes would silently go nowhere: re-run under one.
if [[ -z ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then exec dbus-run-session -- "$0" "$@"; fi
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PATHS=(/org/gnome/shell/ /org/gnome/desktop/wm/ /org/gnome/desktop/interface/ /org/gnome/mutter/ /org/gnome/desktop/peripherals/touchpad/)
# Snapshots live in ~/.local/state, outside the repo.
SNAPDIRS=("${XDG_STATE_HOME:-$HOME/.local/state}/ricing/snapshots")

slug() { local s=${1#/}; echo "${s%/}" | tr / -; }

snap_write_dir() { echo "${SNAPDIRS[0]}"; }

dump_all() { # $1 = target dir
  mkdir -p "$1"
  for p in "${PATHS[@]}"; do dconf dump "$p" > "$1/$(slug "$p").ini"; done
  gsettings get org.gnome.shell enabled-extensions > "$1/enabled-extensions.txt"
}

load_all() { # $1 = dir of per-path dumps; $2 = "reset" to wipe each path first
  for p in "${PATHS[@]}"; do
    [[ ${2:-} == reset ]] && dconf reset -f "$p"
    dconf load "$p" < "$1/$(slug "$p").ini"
  done
}

confirm() {
  [[ ${YES:-} == 1 ]] && return 0
  read -r -p "Proceed? [y/N] " a </dev/tty 2>/dev/null || { echo "no terminal to ask on; re-run with -y to skip the prompt" >&2; exit 1; }
  [[ $a == y ]] || { echo aborted; exit 1; }
}
