# dotfiles

Configuration files managed via symbolic links.

The repository is the **single source of truth** for every managed
configuration file.  Applications read and write from their normal
paths (e.g. `%USERPROFILE%`, `%APPDATA%`), but those paths are
symbolic links pointing back into this repository.  Changes are
instantly visible to Git – no copy or sync steps required.

## Prerequisites

- **Windows 11:** Enable **Developer Mode** (Settings → Privacy &
  security → For developers → Developer Mode).  This allows symbolic
  link creation without administrator elevation.
- **Git** – required for bootstrap mode (one-liner install).
- **PowerShell 5.1+** or **Git Bash**.

## Quick Install

### PowerShell (Windows)

```powershell
# One-liner (clones to ~/dotfiles, then installs)
irm https://raw.githubusercontent.com/erikjoachim/dotfiles/main/install.ps1 | iex

# Or from a local clone
cd dotfiles
.\install.ps1
```

### Git Bash (Windows / Linux / macOS)

```bash
# One-liner
bash <(curl -sL https://raw.githubusercontent.com/erikjoachim/dotfiles/main/install.sh)

# Or from a local clone
cd dotfiles
./install.sh
```

Both installers read the shared `dotfiles.yaml` manifest, create
required directories, back up any existing files, and create symbolic
links.

## Repository Layout

```
dotfiles/
├── alacritty/
│   └── alacritty.toml        → %APPDATA%\alacritty\alacritty.toml
├── bash/
│   └── .bashrc               → %USERPROFILE%\.bashrc
├── git/                      (future)
├── powershell/               (future)
├── wezterm/
│   └── .wezterm.lua          → %USERPROFILE%\.wezterm.lua
├── dotfiles.yaml             shared manifest
├── install.ps1               PowerShell installer
├── install.sh                Git Bash installer
└── README.md
```

## Manifest (`dotfiles.yaml`)

The manifest defines every managed dotfile:

```yaml
dotfiles:
  - source: wezterm/.wezterm.lua
    target: ~/.wezterm.lua
    platforms: [windows, linux, macos]

  - source: alacritty/alacritty.toml
    target: ~/AppData/Roaming/alacritty/alacritty.toml
    platforms: [windows]

  - source: bash/.bashrc
    target: ~/.bashrc
    platforms: [windows, linux, macos]
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `source` | yes | Path relative to repository root |
| `target` | yes | Installation path.  Supports `~` and `%ENV_VAR%` expansion |
| `platforms` | no | List of OS: `windows`, `linux`, `macos`.  Omit for all |

### Adding a New Dotfile

1. Add the file to the repository (e.g. `vim/.vimrc`)
2. Add one entry to `dotfiles.yaml`
3. Re-run the installer

No installer code changes required.

## Usage

### Install

```powershell
.\install.ps1
```

```bash
./install.sh
```

Creates symlinks for every manifest entry matching the current
platform.  Existing files are backed up to `<name>.backup.<YYYYMMDD>`
before being replaced.

### Dry Run

```powershell
.\install.ps1 -WhatIf
```

```bash
./install.sh --dry-run
```

Reports every action the installer would take without touching the
filesystem.

### Verify

```powershell
.\install.ps1 -Verify
```

```bash
./install.sh --verify
```

Checks:
- Every manifest entry exists
- Every repository source file exists
- Every installed symlink exists and points to the correct target
- No broken, missing, or unexpected regular files

Returns exit code 0 on success, 1 on failure.

### Uninstall

```powershell
.\install.ps1 -Uninstall
```

```bash
./install.sh --uninstall
```

Removes managed symbolic links and restores the most recent backup
file (if one exists).  Never removes repository files.

## Backup Behavior

When a destination already contains a regular file (not a symlink),
the installer renames it to `<filename>.backup.<YYYYMMDD>` before
creating the symlink.

On uninstall, the most recent backup is restored automatically.

## Troubleshooting

### "Access denied" creating symlinks

Enable **Developer Mode** in Windows Settings, or run PowerShell as
Administrator.

### Broken links after moving the repository

Just re-run the installer.  It detects incorrect or broken links and
replaces them.

### "git is required" error in bootstrap mode

The one-liner (`irm ... | iex`) needs Git to clone the repository.
Install Git for Windows from https://git-scm.com.
