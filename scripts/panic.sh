#!/usr/bin/env bash
# Disable all user extensions. Works from a TTY (Ctrl+Alt+F3): no session bus there, so start one.
set -euo pipefail
cmd=(gsettings set org.gnome.shell disable-user-extensions true)
if [[ -z ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then dbus-run-session -- "${cmd[@]}"; else "${cmd[@]}"; fi
echo "User extensions disabled. Restart GDM or reboot, then log in."
