# dotfiles

Configs for bash, wezterm, alacritty.

## Install

One-liner:
```bash
bash <(curl -sL https://raw.githubusercontent.com/erikjoachim/dotfiles/main/install.sh)  # unix
irm https://raw.githubusercontent.com/erikjoachim/dotfiles/main/install.ps1 | iex  # windows
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
