# dotfiles repo conventions

Repo = single source of truth for config files.
Applications read/write from normal paths via symlinks pointing here.

## Structure
- `wezterm/.wezterm.lua`  → `~/.wezterm.lua`
- `alacritty/alacritty.toml` → `~/AppData/Roaming/alacritty/alacritty.toml` (win) / `~/.config/alacritty/alacritty.toml` (lin/mac)
- `bash/.bashrc` → `~/.bashrc`
- `dotfiles.yaml` — shared manifest, both installers consume it
- `install.ps1` / `install.sh` — rewrite symlinks from manifest

## Adding a dotfile
1. Add file to repo in app-named subdir
2. Add entry to `dotfiles.yaml` with source, target, optional platforms
3. Installer code untouched

## Manifest format
```yaml
dotfiles:
  - source: wezterm/.wezterm.lua
    target: ~/.wezterm.lua
    platforms: [windows, linux, macos]  # omit for all
```

## Installers
- Both parse same YAML (zero-dependency parsers)
- `install.ps1` — PowerShell 5.1+, flags: `-WhatIf` `-Verify` `-Uninstall`
- `install.sh` — Git Bash, flags: `--dry-run` `--verify` `--uninstall`
- Bootstrap mode: if YAML missing, clone to `~/dotfiles` then install
- Backup existing files as `<name>.backup.<YYYYMMDD>`
- Idempotent: skip correct symlinks, repair broken/wrong links

## Key rules
- Never copy files to destination — always symlink
- Never delete user files — backup first
- `dotfiles.yaml` is the ONLY mapping — no hardcoded paths in installers
- Expand `~` and `%VAR%` in target paths
