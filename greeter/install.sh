#!/bin/sh
# Installs the island login screen for greetd.
#
#   doas ./install.sh                       install + copy your look (nothing switched yet)
#   doas ./install.sh --enable              also make greetd start at boot
#   doas ./install.sh --compositor mango    run the login screen in MangoWM
#                                           (default: Hyprland if installed, else MangoWM)
#
# Works with doas or sudo, OpenRC or systemd. Safe to re-run: do it after
# pulling updates so the login screen gets the island's new theme.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
island="$here/../island"
dest=/etc/greetd/island
user=${DOAS_USER:-${SUDO_USER:-}}
enable=0
comp=""

while [ $# -gt 0 ]; do
	case "$1" in
	--enable) enable=1 ;;
	--compositor) comp=${2:-}; shift ;;
	*) echo "Unknown option: $1" >&2; exit 2 ;;
	esac
	shift
done

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
die() { printf '\033[31m!!\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Run as root: doas ./install.sh (or sudo)"
[ -n "$user" ] && [ "$user" != root ] || die "Couldn't tell who you are. Run it with doas or sudo from your own account."
command -v greetd >/dev/null || die "greetd isn't installed (Gentoo: gui-libs/greetd)."
command -v quickshell >/dev/null || die "quickshell isn't on PATH."
command -v python3 >/dev/null || die "python3 is needed for island-greeter-sync."
[ -d "$island/theme" ] || die "Can't find the island next to this folder ($island)."

# the greeter account: greetd on Gentoo, greeter on Arch and others
greeter=""
for g in greetd greeter _greetd; do getent passwd "$g" >/dev/null && { greeter=$g; break; }; done
[ -n "$greeter" ] || die "No greeter account found. Reinstall greetd (Gentoo: it pulls in acct-user/greetd)."

# which compositor runs the login screen
if [ -z "$comp" ]; then
	if command -v Hyprland >/dev/null; then comp=hyprland
	elif command -v mango >/dev/null; then comp=mango
	else die "Neither Hyprland nor mango is installed."; fi
fi
case "$comp" in
hyprland)
	if command -v start-hyprland >/dev/null; then cmd="start-hyprland -- --config $dest/hyprland.lua"
	else cmd="Hyprland --config $dest/hyprland.lua"; fi ;;
mango) cmd="$dest/start-mango.sh" ;;
*) die "--compositor must be hyprland or mango" ;;
esac

say "Installing the login screen to $dest ($comp)"
mkdir -p "$dest"
cp -r "$here/shell/." "$dest/"
# the island's look, shared so both always match
for d in theme media accent assets; do
	rm -rf "${dest:?}/$d" && cp -r "$island/$d" "$dest/$d"
done
mkdir -p "$dest/components"
for f in Card GlassLayer PButton PIcon PText Chip Avatar; do
	cp "$island/components/$f.qml" "$dest/components/"
done
cp "$island/services/Clock.qml" "$dest/services/"
chown -R root:root "$dest"
find "$dest" -type d -exec chmod 755 {} +
find "$dest" -type f -exec chmod 644 {} +
chmod 755 "$dest/run.sh" "$dest/start-mango.sh"

# the part you own: this machine's settings + media (island-greeter-sync)
mkdir -p "$dest/user/files"
chown -R "$user:" "$dest/user"
chmod 755 "$dest/user" "$dest/user/files"

install -m 755 "$here/bin/island-greeter-sync" /usr/local/bin/island-greeter-sync

# greetd configs: the real one (written with --enable) and a test one on VT 8
write_conf() {   # vt, file, [switch]
	{
		echo "[terminal]"
		echo "vt = $1"
		[ -n "${3:-}" ] && echo "switch = true"
		echo
		echo "[default_session]"
		echo "command = \"$cmd\""
		echo "user = \"$greeter\""
	} > "$2"
	chmod 644 "$2"
}
write_conf 8 /etc/greetd/island-test.toml switch

# the greeter account needs a home for compositor and Quickshell caches
ghome=$(getent passwd "$greeter" | cut -d: -f6)
if [ -n "$ghome" ] && [ "$ghome" != / ] && [ ! -d "$ghome" ]; then
	mkdir -p "$ghome" && chown "$greeter:" "$ghome" && chmod 750 "$ghome"
fi

# OpenRC: add a service if the package didn't ship one
if [ -x /sbin/openrc-run ] && [ ! -e /etc/init.d/greetd ]; then
	install -m 755 "$here/system/greetd" /etc/init.d/greetd
	say "Added /etc/init.d/greetd"
fi
# lets the login screen's Sleep / Reboot / Power buttons work
if [ -d /etc/polkit-1/rules.d ]; then
	sed "s/@GREETER@/$greeter/" "$here/system/10-island-greeter-power.rules" > /etc/polkit-1/rules.d/10-island-greeter-power.rules
	chmod 644 /etc/polkit-1/rules.d/10-island-greeter-power.rules
fi

say "Copying your lock screen look"
uhome=$(getent passwd "$user" | cut -d: -f6)
# not a login shell, so a tty autostart never runs here
su "$user" -s /bin/sh -c "HOME='$uhome' /usr/local/bin/island-greeter-sync" || say "Sync failed: run island-greeter-sync yourself to see why"

if [ "$enable" = 1 ]; then
	[ -f /etc/greetd/config.toml ] && cp /etc/greetd/config.toml "/etc/greetd/config.toml.bak.$(date +%s)"
	write_conf 7 /etc/greetd/config.toml
	if [ -x /sbin/openrc-run ]; then rc-update add greetd default
	elif command -v systemctl >/dev/null; then systemctl enable greetd
	fi
	say "greetd will show the login screen on next boot (VT 7)."
else
	say "Installed. Nothing is switched yet."
	say "Test from a tty that isn't running a desktop (Ctrl+Alt+F2):"
	say "  doas greetd --config /etc/greetd/island-test.toml   (opens on Ctrl+Alt+F8)"
	say "  If it says XDG_RUNTIME_DIR is not set, test with the service instead:"
	say "  doas ./greeter/install.sh --enable && doas rc-service greetd start"
fi
