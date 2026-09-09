# dotfiles

configuration files managed via symbolic links.

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

> **repo location:** the repository can be cloned anywhere. Symlinks point from standard config locations (`~/.bashrc`, `%AppData%/...`) back to the repo's actual path.
>
> moving the repo later only requires re-running the installer to repair links.

### powershell (windows)

> **one-liner**

```powershell
irm https://raw.githubusercontent.com/erikjoachim/dotfiles/main/install.ps1 | iex
```

> **or from a local clone**

```powershell
cd dotfiles
.\install.ps1
```

## Usage

| Action        | Git Bash                   | PowerShell                 | Description                                                                       |
| ------------- | -------------------------- | -------------------------- | --------------------------------------------------------------------------------- |
| **install**   | `./install.sh`             | `.\install.ps1`            | creates symlinks for every manifest entry matching current platform.              |
| **dry run**   | `./install.sh --dry-run`   | `.\install.ps1 -WhatIf`    | reports every action without touching the filesystem.                             |
| **verify**    | `./install.sh --verify`    | `.\install.ps1 -Verify`    | checks all entries/sources/symlinks are correct. exit 0 on success, 1 on failure. |
| **uninstall** | `./install.sh --uninstall` | `.\install.ps1 -Uninstall` | removes managed symlinks. never removes repo files.                               |

## ssh agent (`ssa`) + git identities

details live in [`git/README.md`](git/README.md). short form:

```bash
ssa            # personal keys (default)
ssa work       # all work keys: GitHub + Azure DevOps
ssa all        # both sets
```

directory selects git identity (`/c/projects/work/*` → work, `/c/projects/personal/*` → personal, else personal default). repo ships routing only, zero secrets. machine-local identity files created once from `git/gitconfig-*.example` templates.

> first install symlinks `~/.ssh/config` and `~/.gitconfig` —
> back up existing files first (`.backup-dotfiles` suffix).
> local overrides: `~/.ssh/config.local`, `~/.gitconfig.local`.

## troubleshooting

### "Error connecting to agent: No such file or directory" from `ssa`

stale agent env fixed in current `.bashrc`: reload with `source ~/.bashrc`
(or open fresh tab) and run `ssa` again. old code only started agent when
`SSH_AUTH_SOCK` empty; new code probes `ssh-add -l` and purges dead sockets.

### "access denied" creating symlinks

enable **Developer Mode** in Windows Settings, or run PowerShell as
Administrator.

### broken links after moving the repository

just re-run the installer. it detects incorrect or broken links and
replaces them.

### "git is required" error in bootstrap mode

the one-liner (`irm ... | iex`) needs Git to clone the repository.
