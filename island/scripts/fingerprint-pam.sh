#!/bin/sh
# Fingerprint for doas and app permission prompts (polkit).
#
#   doas sh fingerprint-pam.sh install   install the helper, add it to doas + polkit
#   doas sh fingerprint-pam.sh remove    take it out again (password only)
#   sh fingerprint-pam.sh status         what's set up
#
# The helper (scripts/fingerprint-auth) is copied root-owned to
# /usr/local/libexec, so nothing your account can edit runs during a login.
# Each PAM file is backed up once to <file>.island-bak before the first change.
# Your password always works: the fingerprint step is "sufficient", so if it
# fails, times out or the helper is missing, PAM asks for the password.
set -eu

helper=/usr/local/libexec/island-fingerprint-auth
here=$(dirname "$(readlink -f "$0")")
line="auth sufficient pam_exec.so quiet stdout $helper"
files="/etc/pam.d/doas /etc/pam.d/polkit-1"

name() { case "$1" in */doas) echo "doas" ;; *) echo "app permission prompts (polkit)" ;; esac; }

status() {
    [ -x "$helper" ] && echo "helper: installed ($helper)" || echo "helper: not installed"
    for f in $files; do
        if [ ! -f "$f" ]; then echo "$(name "$f"): no $f"
        elif grep -qF "$helper" "$f"; then echo "$(name "$f"): fingerprint on"
        else echo "$(name "$f"): password only"; fi
    done
}

need_root() { [ "$(id -u)" -eq 0 ] || { echo "Run it with doas: doas sh $0 $1" >&2; exit 1; }; }

case "${1:-status}" in
install)
    need_root install
    install -D -m 0755 -o root -g root "$here/fingerprint-auth" "$helper"
    echo "installed $helper"
    for f in $files; do
        if [ ! -f "$f" ]; then echo "skipped $(name "$f"): no $f"; continue; fi
        [ -f "$f.island-bak" ] || cp -p "$f" "$f.island-bak"
        # drop older fingerprint lines (a plain pam_fprintd one, or ours), then add ours once
        sed -i -e '/pam_fprintd\.so/d' -e "\\|$helper|d" "$f"
        if grep -q '^#%PAM-1.0' "$f"; then
            sed -i "/^#%PAM-1.0/a $line" "$f"
        else
            sed -i "1i $line" "$f"
        fi
        echo "fingerprint on for $(name "$f") (backup: $f.island-bak)"
    done
    ;;
remove)
    need_root remove
    for f in $files; do
        [ -f "$f" ] || continue
        sed -i "\\|$helper|d" "$f"
        echo "password only for $(name "$f")"
    done
    rm -f "$helper"
    echo "removed $helper"
    ;;
status)
    status ;;
*)
    echo "usage: $0 install | remove | status" >&2; exit 2 ;;
esac
