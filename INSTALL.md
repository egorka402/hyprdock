# Installation

Hyprdock installs only for your user (into `~/.local`). Root is needed only to install its dependencies.

You need [Hyprland](https://hypr.land) already running.

## Quick install (Gentoo, Arch, Fedora)

```sh
git clone https://github.com/egorka402/hyprdock.git
cd hyprdock
./install.sh --deps
```

`--deps` installs the missing dependencies (Quickshell and the JetBrains Mono font), shows you every command first,
and asks before running them with `sudo`. Then it installs Hyprdock itself and, if you use a Hyprland Lua config
(`hyprland.lua`), offers to add Hyprdock to your autostart (`Add it? [y/N]`).

Handy options:

```sh
./install.sh --deps --dry-run   # only show what would be done
./install.sh --deps -y          # don't ask questions
```

Other distributions: install the dependencies by hand (below), then run plain `./install.sh`.

## What gets installed

| Dependency | Why |
|------------|-----|
| Quickshell (with Wayland, layer-shell and Hyprland support) | draws the dock |
| JetBrains Mono | the font |

### By hand: Gentoo

Quickshell lives in the GURU overlay:

```sh
sudo emerge --ask app-eselect/eselect-repository
sudo eselect repository enable guru
sudo emaint sync -r guru
echo "gui-apps/quickshell ~amd64" | sudo tee /etc/portage/package.accept_keywords/hyprdock
echo "gui-apps/quickshell wayland layer-shell hyprland" | sudo tee /etc/portage/package.use/hyprdock
sudo emerge --ask gui-apps/quickshell media-fonts/jetbrains-mono
```

(If `/etc/portage/package.use` is a single file instead of a folder, add the line to that file.)

### By hand: Arch

Quickshell is in the AUR:

```sh
yay -S quickshell
sudo pacman -S ttf-jetbrains-mono
```

### By hand: Fedora

```sh
sudo dnf copr enable errornointernet/quickshell
sudo dnf install quickshell jetbrains-mono-fonts
```

### Other distributions

Follow the [official Quickshell install guide](https://quickshell.org/docs/guide/install-setup/) and install the JetBrains Mono font
(Debian/Ubuntu: `fonts-jetbrains-mono`).

## Install Hyprdock (if you didn't use `--deps`)

```sh
git clone https://github.com/egorka402/hyprdock.git
cd hyprdock
./install.sh
```

If the installer says `~/.local/bin` is not in your PATH, add to `~/.bashrc`:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

and open a new terminal.

## Run

```sh
hyprdock
```

Hyprdock runs in the background, so you can close the terminal. The first start creates an empty dock with a "+" button.
Click it (or run `hyprdock settings`) and add your apps.

Other commands: `hyprdock stop`, `hyprdock restart`, `hyprdock logs` (show errors), `hyprdock run` (run in the terminal).

## Autostart

If you use a Hyprland **Lua** config (`~/.config/hypr/hyprland.lua`), `./install.sh` offers to add this block for you
(it makes a backup first, and `./install.sh --remove` takes it out again):

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("/home/YOUR_USER/.local/bin/hyprdock")
end)
```

Doing it yourself:
- **hyprland.lua:** put `hl.exec_cmd("/home/YOUR_USER/.local/bin/hyprdock")` inside your existing `hl.on("hyprland.start", ...)` block
  (or into the script it runs).
- **hyprland.conf (old format):** add `exec-once = /home/YOUR_USER/.local/bin/hyprdock`

Use the full path, because Hyprland doesn't always see the PATH from your `~/.bashrc`.

Optional keybind to open settings:

```lua
hl.bind("SUPER + D", hl.dsp.exec_cmd("hyprdock settings"))
```

> The exact Lua function names depend on your Hyprland version. If one doesn't work, copy the style of the lines already in your config.

## Update

```sh
cd hyprdock
git pull
./install.sh
hyprdock restart
```

## Uninstall

```sh
./install.sh --remove
rm -rf ~/.config/hyprdock    # optional: also delete your settings
```

## Troubleshooting

Run `hyprdock logs` to see the latest errors (or `hyprdock run` to watch them live in the terminal).

| Problem | What to try |
|---------|-------------|
| `Quickshell is not installed` | Run `./install.sh --deps`, check `which qs` |
| Quickshell starts but complains about Hyprland or layer-shell | Quickshell was built without them. On Gentoo enable the `wayland layer-shell hyprland` USE flags and rebuild |
| Dock doesn't appear | Make sure Hyprland is running and you started Hyprdock inside that session |
| Site icon is a letter | Needs internet for favicons, or set an icon manually when adding |
| No "running" dot | The window class differs from the app name; harmless |
| Wrong font | Install JetBrains Mono, run `fc-cache -f` |
