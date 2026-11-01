#!/bin/sh
# Links island/ into ~/.config/quickshell, so `git pull` updates the island.
# Your settings (~/.config/island) are separate and never touched.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
target="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"

[ "$(id -u)" -ne 0 ] || { echo "Run this as yourself, not root." >&2; exit 1; }

if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$here/island" ]; then
    echo "Already linked: $target -> $here/island"
else
    if [ -e "$target" ] || [ -L "$target" ]; then
        bak="$target.bak-$(date +%Y%m%d-%H%M%S)"
        mv "$target" "$bak"
        echo "Moved your old config to $bak"
    fi
    mkdir -p "$(dirname "$target")"
    ln -s "$here/island" "$target"
    echo "Linked $target -> $here/island"
fi

echo
echo "Restart the island:   pkill -x quickshell; quickshell >/dev/null 2>&1 &"
echo "Login screen (greetd): doas ./greeter/install.sh"
