# quickshell-dotfiles

A cream-and-ink pastel **dynamic island** for Wayland, built in
[Quickshell](https://quickshell.org), plus a matching **login screen** for
greetd. Works on **Hyprland** and **MangoWM**.

> This project is vibe-coded: written with an AI assistant and tested by hand.
> MangoWM support hasn't been tested on a real MangoWM machine yet.

```
island/     the dynamic island (Quickshell config)
greeter/    the login screen: the island's lock screen, signing you in through greetd
setup.sh    one-line installer (curl … | sh)
install.sh  links island/ into ~/.config/quickshell
```

## Nothing personal in here

Everything that belongs to one machine stays **outside** the repo, so a laptop
and a desktop can share this repo and still keep their own wallpapers, lock
video, monitors and accounts:

| What | Where it lives (per machine, never committed) |
|---|---|
| Island settings: wallpapers, lock/saver video, accent, name, search engine… | `~/.config/island/settings.json` |
| Login screen copy of those + your media | `/etc/greetd/island/user/` |
| Monitor layout, cursor, keybinds | your compositor config |

Pulling an update never touches any of these.

## Install the island

Copy and paste this into a terminal (as yourself, not root):

```sh
curl -fsSL https://raw.githubusercontent.com/EnvyMeAdams/quickshell-dotfiles/main/setup.sh | sh
```

It downloads the repo to `~/quickshell-dotfiles`, links `island/` to
`~/.config/quickshell` (backing up what's there), lists any missing
dependencies and restarts Quickshell. Run the same line again to update.

With the login screen too:

```sh
curl -fsSL https://raw.githubusercontent.com/EnvyMeAdams/quickshell-dotfiles/main/setup.sh | sh -s -- --greeter --enable
```

| Option | Does |
|---|---|
| `--greeter` | also install the login screen (asks for doas/sudo) |
| `--enable` | with `--greeter`: start the login screen at boot |
| `--mango` | with `--greeter`: run the login screen in MangoWM |
| `--dir PATH` | keep the repo somewhere else |
| `--no-start` | don't restart Quickshell at the end |

If you've changed files in the repo, it won't update over them; it tells you
instead.

### Install by hand

```sh
git clone https://github.com/EnvyMeAdams/quickshell-dotfiles.git ~/quickshell-dotfiles
cd ~/quickshell-dotfiles
./install.sh            # links island/ to ~/.config/quickshell (backs up what's there)
quickshell              # or restart it if it's already running
```

Update later with `git pull` (then restart Quickshell).

Only one notification daemon can run at a time: stop mako/dunst/swaync first.
Stop any other wallpaper tool too (swww, hyprpaper, mpvpaper): the island draws
the wallpaper.

### Keybinds

Every action is an IPC call: `quickshell ipc call island <name>`. Settings →
Shortcuts lists the names and has a "How to Bind" panel.

Hyprland (Lua config):

```lua
local function island(cmd) return hl.dsp.exec_cmd("quickshell ipc call island " .. cmd) end
hl.bind("ALT + Space", island("launcher"))
hl.bind("ALT + Tab",   island("windows"))
hl.bind("SUPER + S",   island("sound"))
hl.bind("SUPER + L",   island("lock"))
```

MangoWM (`~/.config/mango/config.conf`):

```
bind=ALT,space,spawn,quickshell ipc call island launcher
bind=ALT,Tab,spawn,quickshell ipc call island windows
bind=SUPER,s,spawn,quickshell ipc call island sound
bind=SUPER,l,spawn,quickshell ipc call island lock
```

## Install the login screen

Needs greetd (Gentoo: `gui-libs/greetd`). Works with doas or sudo, OpenRC or
systemd.

```sh
doas ./greeter/install.sh                        # install, nothing switched yet
doas ./greeter/install.sh --enable               # start it at boot (VT 7)
doas ./greeter/install.sh --compositor mango     # run it in MangoWM instead of Hyprland
```

Then start the copier from your compositor's autostart. It keeps the login
screen matching this machine's island (lock video, colours, monitors, cursor):

```lua
-- Hyprland
hl.on("hyprland.start", function () hl.exec_cmd("island-greeter-sync --watch") end)
```
```
# MangoWM
exec-once=island-greeter-sync --watch
```

After `git pull`, re-run `doas ./greeter/install.sh` so the login screen gets
the island's new theme.

**Before enabling:** if your shell profile autostarts the compositor, limit it
to tty1, or greetd will start it twice:

```sh
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = /dev/tty1 ]; then
    exec dbus-run-session start-hyprland
fi
```

**Testing:** run `greetd --config /etc/greetd/island-test.toml` from a tty with
no desktop running; it opens on VT 8. If it fails with `XDG_RUNTIME_DIR is not
set`, that's elogind refusing a session inside your tty login. Test with the
service instead (`rc-service greetd start`, then Ctrl+Alt+F7).

Without systemd, the session is started inside `dbus-run-session`, the same as a
tty login.

## Dependencies

| Feature | Needs |
|---|---|
| Core | quickshell, pipewire + wireplumber, Hyprland or MangoWM |
| MangoWM tags | `mmsg` (comes with mango) |
| Fonts | JetBrains Mono (icons are bundled in `island/assets/fonts`) |
| Network | NetworkManager (`nmcli`) |
| Visualizer | cava |
| Wallpaper | Qt Multimedia for videos, ffmpegthumbnailer for video thumbnails |
| Lock | PAM (`island/lock/pam/password.conf`) |
| Web search | curl, xdg-utils |
| Launcher | wl-clipboard, xdg-utils, fd (optional, faster file search) |
| Camera light | psmisc (`fuser`) |
| Screenshot | Hyprland: hyprshot · others: grim, slurp, wl-clipboard |
| Night Light | Hyprland: hyprsunset · others: wlsunset |
| Recording | wf-recorder, slurp (region), pipewire-pulse (`pactl`) |
| Wallpaper accent | Quickshell with ColorQuantizer |
| Laptop extras | brightnessctl, bluez (battery is read from `/sys`, nothing to install) |
| Tray | Quickshell with SystemTray (hidden if your build lacks it) |
| Login screen | greetd, python3, polkit (for its power buttons) |

Screenshot and Night Light pick the right tool for your compositor. Leave
them empty in Settings → Commands for automatic, or type your own command.

## Compositor support

| | Hyprland | MangoWM | other |
|---|---|---|---|
| Island, lock, screensaver, wallpaper | ✓ | ✓ | ✓ |
| ALT+TAB window switcher | ✓ | ✓ | ✓ |
| Workspace / tag in the pill | ✓ | ✓ (via `mmsg -w`) | – |
| Island follows the focused display | ✓ | ✓ | follows the active window |
| `island:` global shortcuts | ✓ | use `bind=…spawn` | – |
| Login screen runs in it | ✓ | ✓ | – |

All compositor-specific code is in `island/services/Compositor.qml` and
`island/compositor/`.

## Lock safety

The lock loads separately from the island. If your Quickshell build can't load
it, locking runs the Fallback Lock command instead (Settings → Lock & Saver).
Stuck Lock on that page explains how to recover from a tty. Test once while
you can still reach a tty (Ctrl+Alt+F2).

## Layout

```
island/
  shell.qml          entry point + IPC commands
  theme/             colours, sizes, the pill shape table
  services/          audio, media, notifications, network, settings, compositor
  compositor/        Hyprland and MangoWM backends (loaded at runtime)
  components/        Card, buttons, sliders, toggles, fields
  island/            the window and the morphing pill (views/, hub/, settings/)
  desktop/           wallpaper layer
  media/             video + backdrop pieces
  lock/              lock screen, screensaver, idle timers
  accent/            wallpaper colour picker
  scripts/           recording, screenshots
greeter/
  shell/             the login screen (Quickshell) + its compositor configs
  bin/               island-greeter-sync
  system/            OpenRC service, polkit rule
  install.sh
```

The icon font in `island/assets/fonts` is Material Symbols (Apache 2.0).
