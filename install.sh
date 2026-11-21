#!/bin/sh
# Hyprdock installer. Installs for the current user only (no root needed).
#   ./install.sh            install / update
#   ./install.sh --remove   uninstall (your config is kept)
set -e

DATA="${XDG_DATA_HOME:-$HOME/.local/share}/hyprdock"
BIN="$HOME/.local/bin"
SRC=$(cd "$(dirname "$0")" && pwd)

if [ "$1" = "--remove" ]; then
    rm -rf "$DATA" "$BIN/hyprdock"
    echo "Hyprdock removed. Settings are still in ~/.config/hyprdock (delete by hand if you want)."
    exit 0
fi

echo "==> Checking dependencies"
missing=0
if ! command -v qs >/dev/null 2>&1 && ! command -v quickshell >/dev/null 2>&1; then
    echo "  [!] quickshell not found (required). See INSTALL.md"; missing=1
fi
command -v hyprctl >/dev/null 2>&1 || { echo "  [!] hyprctl not found (Hyprland is required)"; missing=1; }
fc-list 2>/dev/null | grep -qi "JetBrains Mono" || \
    echo "  [i] JetBrains Mono font not found: install it (Gentoo: media-fonts/jetbrains-mono)"
[ "$missing" -eq 0 ] || { echo "Install the missing required packages and run again."; exit 1; }

echo "==> Installing to $DATA"
rm -rf "$DATA"
mkdir -p "$DATA" "$BIN"
cp -r "$SRC/shell.qml" "$SRC/components" "$SRC/services" "$SRC/settings" "$DATA/"
install -m 755 "$SRC/bin/hyprdock" "$BIN/hyprdock"

case ":$PATH:" in
    *":$BIN:"*) ;;
    *) echo "  [i] $BIN is not in your PATH. Add this line to ~/.bashrc:"
       echo "      export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

cat <<MSG

Done.

Start it now:        hyprdock
Open the settings:   hyprdock settings   (or right-click any icon in the dock)

Autostart: add this line to your hyprland.lua:
    hl.exec_cmd("hyprdock")
MSG
