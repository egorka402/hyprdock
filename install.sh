#!/bin/sh
# Hyprdock installer. Installs Hyprdock for the current user only (~/.local).
#
#   ./install.sh --deps     install missing dependencies first (asks before using sudo), then Hyprdock
#   ./install.sh            install / update Hyprdock (only checks the dependencies)
#   ./install.sh --remove   uninstall (your settings are kept)
#
# Options: -y / --yes   don't ask questions
#          --dry-run    only show what would be done
#
# --deps works automatically on Gentoo, Arch (and derivatives) and Fedora.
set -e

DATA="${XDG_DATA_HOME:-$HOME/.local/share}/hyprdock"
BIN="$HOME/.local/bin"
SRC=$(cd "$(dirname "$0")" && pwd)

DEPS=0
REMOVE=0
YES=0
DRY=0

for arg in "$@"; do
    case "$arg" in
        --deps) DEPS=1 ;;
        --remove) REMOVE=1 ;;
        -y|--yes) YES=1 ;;
        --dry-run) DRY=1 ;;
        -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "install.sh: unknown option '$arg' (try --help)" >&2; exit 1 ;;
    esac
done

SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO="sudo"

have_qs()   { command -v qs >/dev/null 2>&1 || command -v quickshell >/dev/null 2>&1; }
have_font() { fc-list 2>/dev/null | grep -qi "jetbrains mono"; }

# Print a command and (unless --dry-run) run it.
run() {
    echo "  \$ $*"
    [ "$DRY" -eq 1 ] || "$@"
}

# Gentoo: put a line into /etc/portage/<package.use|package.accept_keywords>.
portage_conf() {
    path="/etc/portage/$1"
    line="$2"
    if [ ! -e "$path" ]; then
        run $SUDO mkdir -p "$path"
    fi
    if [ -d "$path" ]; then
        echo "  \$ write '$line' to $path/hyprdock"
        [ "$DRY" -eq 1 ] || echo "$line" | $SUDO tee "$path/hyprdock" >/dev/null
    else
        echo "  \$ add '$line' to $path"
        if [ "$DRY" -eq 0 ] && ! grep -qxF "$line" "$path" 2>/dev/null; then
            echo "$line" | $SUDO tee -a "$path" >/dev/null
        fi
    fi
}

deps_gentoo() {
    if ! have_qs; then
        # Quickshell lives in the GURU overlay.
        run $SUDO emerge --noreplace app-eselect/eselect-repository
        if ! eselect repository list -i 2>/dev/null | grep -qw guru; then
            run $SUDO eselect repository enable guru
        fi
        run $SUDO emaint sync -r guru
        arch=$(portageq envvar ARCH 2>/dev/null || echo amd64)
        portage_conf package.accept_keywords "gui-apps/quickshell ~$arch"
        portage_conf package.use "gui-apps/quickshell wayland layer-shell hyprland"
        run $SUDO emerge --noreplace gui-apps/quickshell
    fi
    if ! have_font; then
        run $SUDO emerge --noreplace media-fonts/jetbrains-mono
    fi
}

deps_arch() {
    if ! have_qs; then
        if pacman -Si quickshell >/dev/null 2>&1; then
            run $SUDO pacman -S --needed quickshell
        elif command -v yay >/dev/null 2>&1; then
            run yay -S --needed quickshell
        elif command -v paru >/dev/null 2>&1; then
            run paru -S --needed quickshell
        else
            echo "  [!] Quickshell is in the AUR. Install an AUR helper (yay or paru) and run this again."
            return 1
        fi
    fi
    if ! have_font; then
        run $SUDO pacman -S --needed ttf-jetbrains-mono
    fi
}

deps_fedora() {
    if ! have_qs; then
        run $SUDO dnf -y copr enable errornointernet/quickshell
        run $SUDO dnf install -y quickshell
    fi
    if ! have_font; then
        run $SUDO dnf install -y jetbrains-mono-fonts
    fi
}

deps_other() {
    cat <<MSG
  [!] This distribution can't be set up automatically yet.
      1. Install Quickshell: https://quickshell.org/docs/guide/install-setup/
      2. Install the JetBrains Mono font
         (Debian/Ubuntu: fonts-jetbrains-mono, openSUSE: jetbrains-mono-fonts)
      3. Run ./install.sh again
MSG
    return 1
}

install_deps() {
    echo "==> Dependencies"
    if have_qs && have_font; then
        echo "  Quickshell and JetBrains Mono are already installed."
        return 0
    fi

    ids=$( . "${HYPRDOCK_OS_RELEASE:-/etc/os-release}" 2>/dev/null; echo "$ID $ID_LIKE" )
    case " $ids " in
        *" gentoo "*) family=gentoo ;;
        *" arch "*)   family=arch ;;
        *" fedora "*) family=fedora ;;
        *)            family=other ;;
    esac

    echo "  Detected: $family. These commands will be run (some use sudo):"
    orig=$DRY
    DRY=1
    "deps_$family"
    DRY=$orig

    [ "$DRY" -eq 1 ] && return 0

    if [ "$YES" -eq 0 ]; then
        printf "  Continue? [y/N] "
        read -r answer
        case "$answer" in
            y|Y|yes|YES) ;;
            *) echo "  Skipped."; return 0 ;;
        esac
    fi
    "deps_$family"
}

# ----------------------------------------------------------------------------

if [ "$REMOVE" -eq 1 ]; then
    rm -rf "$DATA" "$BIN/hyprdock"
    echo "Hyprdock removed. Settings are still in ~/.config/hyprdock (delete by hand if you want)."
    exit 0
fi

[ "$DEPS" -eq 1 ] && install_deps
[ "$DRY" -eq 1 ] && exit 0

echo "==> Checking dependencies"
missing=0
have_qs || { echo "  [!] quickshell not found (required). Run ./install.sh --deps or see INSTALL.md"; missing=1; }
command -v hyprctl >/dev/null 2>&1 || { echo "  [!] hyprctl not found (Hyprland is required)"; missing=1; }
have_font || echo "  [i] JetBrains Mono font not found: run ./install.sh --deps or install it by hand"
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
