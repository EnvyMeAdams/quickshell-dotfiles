#!/bin/sh
# One-line setup for the island (and optionally the login screen):
#
#   curl -fsSL https://raw.githubusercontent.com/EnvyMeAdams/quickshell-dotfiles/main/setup.sh | sh
#
# Options (put them after "sh -s --"):
#   --greeter          also install the login screen (asks for doas/sudo)
#   --enable           with --greeter: start the login screen at boot
#   --mango            with --greeter: run the login screen in MangoWM
#   --dir PATH         where to keep the repo (default ~/quickshell-dotfiles)
#   --no-start         don't (re)start Quickshell at the end
#
# Safe to run again: it updates the repo instead of cloning it twice, and
# your settings in ~/.config/island are never touched.

# everything lives in main() so a half-downloaded script never runs
main() {
    set -eu

    repo_url="https://github.com/EnvyMeAdams/quickshell-dotfiles.git"
    dir="$HOME/quickshell-dotfiles"
    greeter=0; enable=0; mango=0; start=1

    while [ $# -gt 0 ]; do
        case "$1" in
            --greeter) greeter=1 ;;
            --enable) enable=1 ;;
            --mango) mango=1 ;;
            --no-start) start=0 ;;
            --dir) shift; dir="$1" ;;
            -h|--help) echo "Options: --greeter  --enable  --mango  --dir PATH  --no-start"; return 0 ;;
            *) echo "Unknown option: $1" >&2; return 1 ;;
        esac
        shift
    done

    say()  { printf '\033[1;35m==>\033[0m %s\n' "$*"; }
    warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
    die()  { printf '\033[1;31m  x\033[0m %s\n' "$*" >&2; exit 1; }
    have() { command -v "$1" >/dev/null 2>&1; }

    [ "$(id -u)" -ne 0 ] || die "Run this as yourself, not root. It asks for doas/sudo only when needed."
    have git || die "git is not installed."

    # ── get or update the repo ──
    if [ -d "$dir/.git" ]; then
        say "Updating $dir"
        if [ -n "$(git -C "$dir" status --porcelain --untracked-files=no)" ]; then
            warn "You have local changes in $dir, so it wasn't updated."
            warn "Commit or stash them, then run this again."
        else
            git -C "$dir" pull --ff-only --quiet || warn "Couldn't update (offline?). Using what's there."
        fi
    elif [ -e "$dir" ]; then
        die "$dir exists but isn't a git clone. Move it, or use --dir PATH."
    else
        say "Downloading to $dir"
        git clone --quiet --depth 1 "$repo_url" "$dir"
    fi

    # ── link the island ──
    say "Linking the island"
    out=$(sh "$dir/install.sh") || die "Linking failed: $out"
    printf '%s\n' "$out" | grep -E '^(Linked|Already|Moved)' | sed 's/^/    /'

    # ── login screen ──
    if [ "$greeter" -eq 1 ]; then
        if have doas; then root=doas; elif have sudo; then root=sudo; else die "Need doas or sudo for the login screen."; fi
        set --
        [ "$enable" -eq 1 ] && set -- "$@" --enable
        [ "$mango" -eq 1 ] && set -- "$@" --compositor mango
        say "Installing the login screen ($root will ask for your password)"
        # stdin is this script when piped from curl; give the password prompt the terminal
        $root sh "$dir/greeter/install.sh" "$@" < /dev/tty
    fi

    # ── what's missing ──
    missing=""
    for c in quickshell nmcli cava wf-recorder slurp pactl wl-copy fd ffmpegthumbnailer fuser curl xdg-open; do
        have "$c" || missing="$missing $c"
    done
    if [ -n "$missing" ]; then
        warn "Not installed (the island works, these features stay off):$missing"
        warn "See the Dependencies table in $dir/README.md"
    fi
    for d in mako dunst swaync; do
        pgrep -x "$d" >/dev/null 2>&1 && warn "$d is running. Stop it so the island can show notifications."
    done

    # ── start it ──
    if [ "$start" -eq 1 ] && have quickshell && [ -n "${WAYLAND_DISPLAY:-}" ]; then
        say "Restarting Quickshell"
        pkill -x quickshell 2>/dev/null || true
        sleep 0.5
        (setsid quickshell >/dev/null 2>&1 &)
    elif [ "$start" -eq 1 ]; then
        warn "Not in a Wayland session. Start it later with: quickshell"
    fi

    echo
    say "Done. Update any time by running the same command again."
    [ "$greeter" -eq 1 ] || echo "    Login screen too:  curl -fsSL https://raw.githubusercontent.com/EnvyMeAdams/quickshell-dotfiles/main/setup.sh | sh -s -- --greeter"
}

main "$@"
