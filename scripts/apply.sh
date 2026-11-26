#!/usr/bin/env bash
# Usage: apply.sh [-y] <step>...   Reads manifests/<step>.conf for each step (merged, validated together). One directive per line:
#   zip vendor/x.zip | profile profiles/x.ini | enable <uuid> | disable <uuid>
. "$(dirname "$0")/lib.sh"
[[ ${1:-} == -y ]] && { YES=1; shift; }
[[ $# -ge 1 ]] || { echo "usage: apply.sh [-y] <step>..." >&2; exit 2; }
step=$*
mans=()
for st in "$@"; do
  [[ -f $REPO/manifests/$st.conf ]] || { echo "no manifest manifests/$st.conf" >&2; exit 1; }
  mans+=("$REPO/manifests/$st.conf")
done
mapfile -t lines < <(grep -hvE '^\s*(#|$)' "${mans[@]}")

check_profile() { # profiles may only touch tracked paths
  local h re
  re="^(org/gnome/shell|org/gnome/desktop/wm|org/gnome/desktop/interface|org/gnome/mutter|org/gnome/desktop/peripherals/touchpad)(/.*)?$"
  while read -r h; do [[ $h =~ $re ]] || { echo "profile $1 touches untracked path [$h]" >&2; exit 1; }; done \
    < <(grep -oP '^\[\K[^]]+' "$1")
}
check_zip() { # must be pinned in vendor/SHA256SUMS
  (cd "$REPO/vendor" && grep -F " $(basename "$1")" SHA256SUMS | sha256sum -c --quiet -)
}
installed() { local d; for d in ~/.local/share /usr/share /usr/local/share; do [[ -d $d/gnome-shell/extensions/$1 ]] && return 0; done; return 1; }
set_ext() { # enable|disable <uuid>, edits the list without needing the shell to know the extension yet
  python3 -I - "$1" "$2" <<'PY'
import ast, subprocess, sys
act, u = sys.argv[1:]
cur = subprocess.check_output(["gsettings", "get", "org.gnome.shell", "enabled-extensions"], text=True).strip()
l = [x for x in ast.literal_eval(cur.removeprefix("@as ")) if x != u]
if act == "enable": l.append(u)
subprocess.check_call(["gsettings", "set", "org.gnome.shell", "enabled-extensions", repr(l)])
PY
}

echo "Step '$step' will:"; printf '  %s\n' "${lines[@]}"
for l in "${lines[@]}"; do   # validate everything before changing anything
  read -r op arg <<<"$l"
  case $op in
    zip) check_zip "$REPO/$arg" ;;
    profile) check_profile "$REPO/$arg" ;;
    enable|disable) ;;
    *) echo "unknown directive: $l" >&2; exit 1 ;;
  esac
done
confirm
for l in "${lines[@]}"; do
  read -r op arg <<<"$l"
  case $op in
    zip) gnome-extensions install --force "$REPO/$arg" ;;
    profile) dconf load / < "$REPO/$arg" ;;
    enable|disable) set_ext "$op" "$arg"
      if [[ $op == enable ]] && ! installed "$arg"; then echo "WARNING: $arg is not installed; install it (see README prerequisites)"; fi ;;
  esac
done
echo "applied '$step'. Log out and in to load it."
