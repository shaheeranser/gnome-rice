# gnome-rice

A small, reversible GNOME Shell setup, applied with one command:

- **Swipe between apps** on a single workspace: three fingers left/right switch the focused window, three fingers up opens the Overview, four fingers left/right switch workspace ([Touchpad Gesture Customization](https://extensions.gnome.org/extension/7850/touchpad-gesture-customization/)).
- **A real app launcher** that lists every app, independent of the dock ([ArcMenu](https://extensions.gnome.org/extension/3628/arcmenu/)). Super is left alone unless you ask (`--super`).
- **A global menu** in the top bar: the focused app's menu (File, Edit, ...) ([Orbit Global Menu](https://extensions.gnome.org/extension/11414/global-menu/)), plus the Places menu.
- Optional: hide apps' own in-window menu bars (VS Code and forks, Slack), and apply settings for Dash to Dock, Blur My Shell, Just Perfection and AppIndicator.

Every change is snapshotted first and can be rolled back.

## Install

```
curl -fsSL https://raw.githubusercontent.com/shaheeranser/gnome-rice/main/install.sh | bash -s -- -y
```

Or from a clone: `./install.sh`. Without `-y` it prints what it will do and asks first (needs a terminal). Then **log out and back in**.

| Option | Effect |
|---|---|
| `--super` | Super opens ArcMenu instead of the Overview |
| `--drop-redundant` | disable Fedora's old Applications menu (ArcMenu replaces it) |
| `--extras` | apply settings for Dash to Dock, Blur My Shell, Just Perfection, AppIndicator; enable Continuum |
| `--app-menus` | hide in-window menu bars of VS Code, Cursor, Antigravity and Slack (backed up; `scripts/app-menus.sh restore` undoes it) |

The repo is cloned to `~/.local/share/gnome-rice` (override with `RICE_DIR`).

## Requirements

- **GNOME Shell 50 on Wayland.** The bundled extensions are pinned for it (Touchpad Gesture Customization: 49-51, ArcMenu: 45-51, Orbit: 48-51). The installer warns on other versions.
- A touchpad that reports three- and four-finger gestures (libinput).
- Tools: `git`, `python3`, `unzip`, `dconf`, `gsettings`, `gnome-extensions` (ships with `gnome-shell`), plus `curl` for the one-liner. Fedora: `sudo dnf install git python3 unzip dconf`.
- No root is needed to run the setup; nothing outside your home directory is touched.

## Prerequisites you install yourself

Shipped in `vendor/` and installed for you: Touchpad Gesture Customization 28, ArcMenu 74, Orbit Global Menu 5 (each keeps its own license; see its project page).

Not shipped, install from your distro or [extensions.gnome.org](https://extensions.gnome.org/):

| Extension | Needed for | Fedora package |
|---|---|---|
| Places Status Indicator | the Places menu (always) | `gnome-shell-extension-places-menu` (Debian/Ubuntu/Arch: `gnome-shell-extensions`) |
| Dash to Dock | `--extras` | `gnome-shell-extension-dash-to-dock` |
| Blur My Shell | `--extras` | `gnome-shell-extension-blur-my-shell` |
| Just Perfection | `--extras` | `gnome-shell-extension-just-perfection` |
| AppIndicator and KStatusNotifierItem Support | `--extras` | `gnome-shell-extension-appindicator` |
| [Continuum](https://github.com/sharjeelmazhar/continuum) | `--extras`; shows your Android phone in Quick Settings and only works with the Continuum phone app installed | from its repository |

The installer warns when something it enables is missing; it never fails on that.

## Notes and limits

- **Global menu coverage.** Orbit builds menus from keyboard shortcuts for about 290 apps. Apps that publish a real menu (GTK menubar apps, LibreOffice) show it. Qt, Electron, Chromium and Firefox only do so under XWayland with Orbit's optional companion daemon, which this repo does not install. Apps without a menu just show the generic window menu.
- **Hiding in-app menus** (`--app-menus`) only edits apps whose config exists. VS Code takes effect live; the Slack change is unverified (Slack may rewrite the file) and is skipped while Slack runs. Firefox and Thunderbird already hide theirs.
- **Desktop.** With no app focused Orbit shows nothing; the Places menu stays visible.
- Tested on Fedora 44, GNOME Shell 50.6, one laptop. Other distros are untested.

## Undo and recovery

```
~/.local/share/gnome-rice/scripts/rollback.sh before-all     # restore your settings from before the install
```

If the shell will not load: Ctrl+Alt+F3, log in, run `~/.local/share/gnome-rice/scripts/panic.sh` (turns off all user extensions), then reboot or `sudo systemctl restart gdm`, log in, and run the rollback.

Rollback restores the settings and the enabled-extension list; it does not delete installed extension files (they do nothing unless enabled). Snapshots are in `~/.local/state/ricing/snapshots`.

## What is in here

| Path | Purpose |
|---|---|
| `install.sh` | clone/update, then apply |
| `scripts/apply-all.sh` | snapshot (`before-all`), then apply the default steps |
| `scripts/apply.sh <step>...` | apply `manifests/<step>.conf`: install pinned zips (checksum-verified against `vendor/SHA256SUMS`), load dconf profiles, enable extensions |
| `scripts/snapshot.sh`, `rollback.sh`, `panic.sh` | checkpoint, restore, emergency off-switch (all work from a TTY) |
| `scripts/app-menus.sh` | hide in-app menu bars; `restore` undoes |
| `manifests/`, `profiles/` | the steps and the settings they load (only the GNOME dconf paths listed in `scripts/lib.sh` can be written) |
