# dotfiles

Configs for bash, wezterm, alacritty.

## Install

One-liner:

#### unix

```bash
bash <(curl -sL https://raw.githubusercontent.com/erikjoachim/dotfiles/main/install.sh)
```

#### windows

```bash
irm https://raw.githubusercontent.com/erikjoachim/dotfiles/main/install.ps1 | iex
```

Or clone and run:
```bash
git clone https://github.com/erikjoachim/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh
```

## Files

| Source | Destination |
|--------|-------------|
| `.bashrc` | `~/.bashrc` |
| `.wezterm.lua` | `~/.wezterm.lua` |
| `alacritty.toml` | Windows: `%APPDATA%\alacritty`<br>Unix: `~/.config/alacritty` |
