# dotfiles

configuration files managed via symbolic links.
see [AGENTS.md](AGENTS.md) for repo conventions and manifest format.

## quick install

### git bash (windows / linux / macOS)

> **one-liner**

```bash
curl -sL https://raw.githubusercontent.com/erikjoachim/dotfiles/main/install.sh | bash
```

> **or from a local clone**

```bash
cd dotfiles
./install.sh
```

### powershell (windows)

> **one-liner**

```powershell
irm https://raw.githubusercontent.com/erikjoachim/dotfiles/main/install.ps1 | iex
```

>  **or from a local clone**
```powershell
cd dotfiles
.\install.ps1
```

## Usage

| Action | Git Bash | PowerShell | Description |
|--------|----------|-----------|-------------|
| **install** | `./install.sh` | `.\install.ps1` | creates symlinks for every manifest entry matching current platform. |
| **dry run** | `./install.sh --dry-run` | `.\install.ps1 -WhatIf` | reports every action without touching the filesystem. |
| **verify** | `./install.sh --verify` | `.\install.ps1 -Verify` | checks all entries/sources/symlinks are correct. exit 0 on success, 1 on failure. |
| **uninstall** | `./install.sh --uninstall` | `.\install.ps1 -Uninstall` | removes managed symlinks. never removes repo files. |

## troubleshooting

### "access denied" creating symlinks

enable **Developer Mode** in Windows Settings, or run PowerShell as
Administrator.

### broken links after moving the repository

just re-run the installer. it detects incorrect or broken links and
replaces them.

### "git is required" error in bootstrap mode

the one-liner (`irm ... | iex`) needs Git to clone the repository.
