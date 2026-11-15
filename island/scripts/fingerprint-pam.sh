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
# polkit often ships its file in /usr/lib/pam.d only; then a copy is made in
# /etc/pam.d (which wins), marked so that "remove" deletes it again.
# Your password always works: the fingerprint step is "sufficient", so if it
# fails, times out or the helper is missing, PAM asks for the password.
set -eu

helper=/usr/local/libexec/island-fingerprint-auth
here=$(dirname "$(readlink -f "$0")")
line="auth sufficient pam_exec.so quiet stdout $helper"
files="/etc/pam.d/doas /etc/pam.d/polkit-1"
vendor_dirs="/usr/lib/pam.d /usr/share/pam.d /lib/pam.d"
marker="# made by island fingerprint-pam.sh from the system copy; 'remove' deletes it"

# the system's own copy of a PAM file, when /etc/pam.d doesn't have one
vendor() { for d in $vendor_dirs; do [ -f "$d/$(basename "$1")" ] && { echo "$d/$(basename "$1")"; return; }; done; }

name() { case "$1" in */doas) echo "doas" ;; *) echo "app permission prompts (polkit)" ;; esac; }

status() {
    [ -x "$helper" ] && echo "helper: installed ($helper)" || echo "helper: not installed"
    for f in $files; do
        if [ ! -f "$f" ]; then
            if [ -n "$(vendor "$f")" ]; then echo "$(name "$f"): password only (system copy in $(vendor "$f"))"
            else echo "$(name "$f"): not found"; fi
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
        if [ ! -f "$f" ]; then
            v=$(vendor "$f")
            if [ -z "$v" ]; then echo "skipped $(name "$f"): no PAM file found"; continue; fi
            # header (if any) first, then our marker, then the rest
            awk -v m="$marker" 'NR == 1 && /^#%PAM/ { print; print m; next } NR == 1 { print m } { print }' "$v" > "$f"
            chmod 644 "$f"
            echo "copied $v to $f"
        elif [ ! -f "$f.island-bak" ] && ! grep -qF "$marker" "$f"; then
            cp -p "$f" "$f.island-bak"
        fi
        # drop older fingerprint lines (a plain pam_fprintd one, or ours), then add ours once
        sed -i -e '/pam_fprintd\.so/d' -e "\\|$helper|d" "$f"
        if grep -q '^#%PAM-1.0' "$f"; then
            sed -i "/^#%PAM-1.0/a $line" "$f"
        else
            sed -i "1i $line" "$f"
        fi
        if [ -f "$f.island-bak" ]; then echo "fingerprint on for $(name "$f") (backup: $f.island-bak)"
        else echo "fingerprint on for $(name "$f")"; fi
    done
    ;;
remove)
    need_root remove
    for f in $files; do
        [ -f "$f" ] || continue
        if grep -qF "$marker" "$f"; then
            rm -f "$f"
            echo "password only for $(name "$f") (removed our copy, the system one is used again)"
            continue
        fi
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
