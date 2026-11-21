# Installation

Hyprdock installs only for your user (into `~/.local`), no root needed for Hyprdock itself.

## 1. Dependencies

### Gentoo

Quickshell lives in the GURU overlay:

```sh
sudo eselect repository enable guru
sudo emaint sync -r guru
sudo emerge --ask gui-apps/quickshell media-fonts/jetbrains-mono
```

Quickshell needs the Hyprland support flag. If emerge says so, enable it, for example:

```sh
echo "gui-apps/quickshell hyprland" | sudo tee /etc/portage/package.use/quickshell
```

Check the exact flags with `equery uses gui-apps/quickshell`.

### Arch

```sh
sudo pacman -S quickshell ttf-jetbrains-mono
```

### Other distributions

Install Quickshell from [quickshell.org](https://quickshell.org/docs/guide/install-setup/), plus the JetBrains Mono font.

## 2. Install Hyprdock

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

## 3. Run

```sh
hyprdock
```

The first start creates an empty dock with a "+" button. Click it (or run `hyprdock settings`) and add your apps.

## 4. Autostart

Add to your `hyprland.lua`:

```lua
hl.exec_cmd("hyprdock")
```

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

Run `hyprdock` in a terminal, errors are printed there.

| Problem | What to try |
|---------|-------------|
| `Quickshell is not installed` | Install it (step 1), check `which qs` |
| Dock doesn't appear | Make sure Hyprland is running and you started Hyprdock inside that session |
| Site icon is a letter | Needs internet for favicons, or set an icon manually when adding |
| No "running" dot | The window class differs from the app name; harmless |
| Wrong font | Install JetBrains Mono, run `fc-cache -f` |
