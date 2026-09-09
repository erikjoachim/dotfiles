# Git + SSH profiles — personal / work, multi-service

Chain: directory → `includeIf` → identity → SSH host alias → key.
`ssa` preloads keys. SSH config enforces selection.

## Key rule

One key per trust boundary, reused across services:

| Key                          | Scope                                       |
| ---------------------------- | ------------------------------------------- |
| `~/.ssh/id_ed25519_personal` | all personal services                       |
| `~/.ssh/id_ed25519_work`     | GitHub work + Azure DevOps work             |
| `~/.ssh/id_ed25519_<org>`    | exception only — org mandates dedicated key |

Legacy names still work as candidates: `~/.ssh/githubssh`, `~/.ssh/github-work`.
Separate per-service keys on same laptop add files, zero security.

```bash
ssh-keygen -t ed25519 -C "personal" -f ~/.ssh/id_ed25519_personal
ssh-keygen -t ed25519 -C "work"     -f ~/.ssh/id_ed25519_work
```

Register each `.pub` in its services with auth + signing:

- **GitHub** → Settings → SSH and GPG keys → New → **Authentication** + **Signing**
- **Azure DevOps** → User settings → SSH public keys → `authentication-signing`

## Dir layout

```
/c/projects/personal/<repo>   # or ~/projects/personal/
/c/projects/work/<repo>       # or ~/projects/work/
```

Flat legacy dirs (`/c/projects/<repo>`) inherit personal default. No rewrites needed.

## SSH aliases (`ssh/config`, managed)

```bash
git clone git@github-personal:<org>/<repo>.git
git clone git@github-work:<org>/<repo>.git
git clone git@azure-work:v3/<org>/<project>/<repo>   # Azure DevOps
```

Per-machine extras (never committed): `~/.ssh/config.local`, `~/.ssh/config.d/*.conf`.

## Agent (`ssa`, from `bash/.bashrc`)

```bash
ssa                  # personal (default)
ssa work             # all work keys: GitHub + ADO
ssa all              # both sets
ssa ~/.ssh/my-key    # explicit path
```

Persists via `~/.ssh/agent.env`. Stale sockets recycled automatically.
Overrides: `SSA_PERSONAL_KEYS`, `SSA_WORK_KEYS`, `SSA_AGENT_ENV`.

## Git identities (secret-free, repo is public)

Committed `git/gitconfig` holds routing only — zero emails. Machine-local files:

| File                    | Content                           | When          |
| ----------------------- | --------------------------------- | ------------- |
| `~/.gitconfig.local`    | default (personal) identity       | always        |
| `~/.gitconfig-work`     | work identity + work url rewrites | work machines |
| `~/.gitconfig-personal` | personal url rewrites             | optional      |

Setup:

```bash
cp git/gitconfig-local.example ~/.gitconfig.local         # fill personal email
cp git/gitconfig-work.example ~/.gitconfig-work           # work machines only
cp git/gitconfig-personal.example ~/.gitconfig-personal   # optional
```

Work scope rewrites `git@github.com:` → `git@github-work:` and
`git@ssh.dev.azure.com:` → `git@azure-work:` — existing checkouts
authenticate as work with zero remote edits. Personal-only machines keep
`work`/`personal` stubs empty; routing dormant, default holds.

Routing (in committed base, `gitdir/i` covers `/c/` + `C:/` spellings):

| Directory                                         | File                    |
| ------------------------------------------------- | ----------------------- |
| `/c/projects/work/*`, `~/projects/work/*`         | `~/.gitconfig-work`     |
| `/c/projects/personal/*`, `~/projects/personal/*` | `~/.gitconfig-personal` |
| everything else                                   | `~/.gitconfig.local`    |

## Verify

```bash
# routing
git -C /c/projects/work/<repo> config --show-origin --get user.email
git -C /c/projects/personal/<repo> config --show-origin --get-regexp 'url.*insteadOf'

# ssh
ssh -G github-work | grep -Ei '^(hostname|identityfile)'
ssh -G azure-work | grep -Ei '^(hostname|identityfile)'

# agent
ssa work && ssh-add -l

# signing
git commit --allow-empty -m "test signed commit"
git log --show-signature -1   # → Good "git" signature, Verified badge in UI
```

## Troubleshooting

| Symptom                              | Fix                                                                                 |
| ------------------------------------ | ----------------------------------------------------------------------------------- |
| `Permission denied (publickey)`      | `ssh -vT git@github-work` — check offered key. Fix `~/.ssh/config`.                 |
| `Error connecting to agent`          | `source ~/.bashrc`, fresh tab, `ssa` again. Stale socket auto-purged.               |
| `includeIf` not loading              | Must run inside repo — outside repos `gitdir` never matches. Check `--show-origin`. |
| Windows path issues                  | Patterns use `gitdir/i:` + both `/c/` and `C:/` spellings.                          |
| `signingkey must not be a pem file`  | Use `.pub` path, not private key.                                                   |
| `gpg: failed to sign the data`       | Check `gpg.format = ssh`, `gpg.ssh.program` path (`where ssh-keygen`).              |
| Commit not Verified (GitHub)         | Key added as **Signing**, not just Auth.                                            |
| Commit not Verified (ADO)            | Key type `signing` or `authentication-signing`?                                     |
| `~/.ssh/config` locked (company box) | Put `core.sshCommand = ssh -i <key>` in the scope file instead.                     |
| HTTPS-only clone policy              | Sign with SSH keys anyway; auth via Git Credential Manager.                         |
