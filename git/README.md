# Setup git + SSH for auth & verified commits — multi-service

## Prerequisites

- Git 2.34+
- OpenSSH client

## 1. Generate SSH keys — one per service

```bash
ssh-keygen -t ed25519 -C "github-personal"  -f ~/.ssh/github-personal
ssh-keygen -t ed25519 -C "gitlab-personal"  -f ~/.ssh/gitlab-personal
ssh-keygen -t ed25519 -C "azdevops-personal" -f ~/.ssh/azdevops-personal
ssh-keygen -t ed25519 -C "azdevops-work"    -f ~/.ssh/azdevops-work
```

## 2. Add keys to services

Copy key: `cat ~/.ssh/<key>.pub` (or `type` on Windows CMD)

Add each `.pub` to its service with these capabilities:

- **GitHub** → Settings → SSH and GPG keys → New → check both **Authentication** + **Signing**
- **GitLab** → Settings → SSH Keys → Usage → **Authentication & Signing**
- **Azure DevOps** → User settings → SSH public keys → type: `authentication-signing`

## 3. Create dir layout

```
c:/projects/personal/github/
c:/projects/personal/gitlab/
c:/projects/personal/azdevops/
c:/projects/work/azdevops/
# or ~/src/personal/..., ~/src/work/...
```

Clone repos into matching dirs.

## 4. Create `~/.ssh/config`

```ini
Host github.com
    IdentityFile ~/.ssh/github-personal

Host gitlab.com
    IdentityFile ~/.ssh/gitlab-personal

Host ssh.dev.azure.com
    IdentityFile ~/.ssh/azdevops-personal
```

- Personal + work both on Azure DevOps? Use `Match` blocks or skip `~/.ssh/config` and use `core.sshCommand` per include (step 6).

## 5. Create per-service git includes

**`~/.gitconfig-personal-github`**
```ini
[user]
    name = "Your Name"
    signingKey = ~/.ssh/github-personal.pub
```

**`~/.gitconfig-personal-gitlab`**
```ini
[user]
    name = "Your Name"
    signingKey = ~/.ssh/gitlab-personal.pub
```

**`~/.gitconfig-personal-azdevops`**
```ini
[user]
    name = "Your Name"
    signingKey = ~/.ssh/azdevops-personal.pub
```

**`~/.gitconfig-work-azdevops`**
```ini
[user]
    name = "Your Name"
    signingKey = ~/.ssh/azdevops-work.pub
[core]
    sshCommand = ssh -i ~/.ssh/azdevops-work
```

`core.sshCommand` in the work include handles auth key routing when `~/.ssh/config` can't distinguish personal vs work Azure DevOps on the same host.

## 6. Create `~/.gitconfig`

```ini
[user]
    email = "your@email.com"

[core]
    editor = vim

[init]
    defaultBranch = main

[gpg]
    format = ssh

[gpg "ssh"]
    program = C:/Windows/System32/OpenSSH/ssh-keygen.exe

[commit]
    gpgSign = true

[tag]
    gpgSign = true

[includeIf "gitdir:C:/projects/personal/github/"]
    path = ~/.gitconfig-personal-github

[includeIf "gitdir:C:/projects/personal/gitlab/"]
    path = ~/.gitconfig-personal-gitlab

[includeIf "gitdir:C:/projects/personal/azdevops/"]
    path = ~/.gitconfig-personal-azdevops

[includeIf "gitdir:C:/projects/work/azdevops/"]
    path = ~/.gitconfig-work-azdevops
```

Adjust `gitdir:` paths to match step 3 layout. Use `C:/...` on Windows, `~/...` on Linux/macOS.

## 7. Verify

```bash
# Auth
cd c:/projects/personal/github/some-repo
git fetch

# Signing
git commit --allow-empty -m "test signed commit"
git log --show-signature -1
# → "Good "git" signature"

# Push
git push

# Check UI — commit shows "Verified" badge
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Permission denied (publickey)` | Wrong auth key. Run `ssh -vT git@github.com` to see what's offered. Fix `~/.ssh/config`. |
| `signingkey must not be a pem file` | Use `.pub` path, not private key |
| `gpg: failed to sign the data` | Check `gpg.format = ssh` and `gpg.ssh.program` path |
| Commit not "Verified" on GitHub | Key added as **Signing Key**? (not just Auth) |
| Commit not "Verified" on GitLab | Key Usage set to **Signing**? |
| Commit not "Verified" on Azure DevOps | Key type set to `signing` or `authentication-signing`? |
| `includeIf` not loading | `git config --show-origin --get user.signingKey` inside repo |
| Windows path issues | Use `C:/...` forward slashes in gitconfig |

## Company machine notes

- `gpg.ssh.program` path may differ — run `where ssh-keygen`
- `~/.ssh/config` may be locked — use `core.sshCommand` in includes
- HTTPS-only clone policy? You can still sign with SSH keys; auth via Git Credential Manager
- Cert-based SSH org? Auth works via cert, but `signingKey` is still your `.pub` file. Verify with IT

## Reference: `git/gitconfig` in this repo

Minimal single-service template (personal GitHub). Copy the `[gpg]`, `[commit]`, `[tag]` blocks into `~/.gitconfig` above.
