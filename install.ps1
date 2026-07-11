#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Install, verify, or uninstall dotfiles via symbolic links.
.DESCRIPTION
  Reads dotfiles.yaml and creates symlinks so each managed config
  file lives in the repo and is referenced from its normal application
  path.
.PARAMETER WhatIf
  Dry-run: show actions without making changes.
.PARAMETER Verify
  Check every manifest entry, source file, and symlink.  Exit 1 on failure.
.PARAMETER Uninstall
  Remove managed symlinks.
.EXAMPLE
  .\install.ps1
  .\install.ps1 -WhatIf
  .\install.ps1 -Verify
  .\install.ps1 -Uninstall
#>
param(
    [switch]$WhatIf,
    [switch]$Verify,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

# ---------- configuration ----------
$repoUrl = 'https://github.com/erikjoachim/dotfiles.git'
$bootstrapDir = Join-Path $HOME 'dotfiles'

# ---------- helpers ----------
function Write-Action {
    param([string]$Message, [string]$Kind = 'INFO')
    $color = @{
        INFO    = 'Cyan'
        OK      = 'Green'
        SKIP    = 'DarkYellow'
        LINK    = 'Green'
        UNLINK  = 'Red'
        REMOVE  = 'Red'
        ERROR   = 'Red'
        DRY_RUN = 'Magenta'
    }
    $c = if ($color.ContainsKey($Kind)) { $color[$Kind] } else { 'White' }
    Write-Host "[$Kind] $Message" -ForegroundColor $c
}

function Expand-Path {
    param([string]$Path)
    # Expand ~ to $HOME
    if ($Path -match '^~[/\\](.*)$') {
        $Path = Join-Path $HOME $matches[1]
    } elseif ($Path -eq '~') {
        $Path = $HOME
    }
    # Expand %VAR% environment variables
    $Path = [Environment]::ExpandEnvironmentVariables($Path)
    return $Path
}

function Get-CurrentPlatform {
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { return 'windows' }
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Unix) {
        $uname = (uname -s)
        if ($uname -eq 'Darwin') { return 'macos' }
        return 'linux'
    }
    return 'unknown'
}

function Get-TargetFromSymlink {
    param([string]$Path)
    try {
        $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        if ($item.LinkType -eq 'SymbolicLink') {
            return $item.Target
        }
    } catch {}
    return $null
}

# ---------- YAML parser ----------
function Get-ManifestEntries {
    param([string]$ManifestPath)

    if (-not (Test-Path $ManifestPath)) {
        throw "Manifest not found: $ManifestPath"
    }

    $platform = Get-CurrentPlatform
    $entries = @()
    $current = $null

    switch -Regex -File $ManifestPath {
        '^\s*#|^dotfiles:\s*$' {
            # comment or header – skip
            continue
        }
        '^\s*$' {
            # blank line separates entries
            if ($current -and $current.ContainsKey('source')) {
                $entries += [PSCustomObject]$current
                $current = $null
            }
            continue
        }
        '^\s+-\s+source:\s+(.+)$' {
            if ($current -and $current.ContainsKey('source')) {
                $entries += [PSCustomObject]$current
            }
            $current = @{ source = $matches[1].Trim() }
        }
        '^\s+target:\s+(.+)$' {
            if ($current) { $current.target = $matches[1].Trim() }
        }
        '^\s+platforms:\s+\[(.+)\]$' {
            if ($current) {
                $current.platforms = $matches[1] -split ',' | ForEach-Object { $_.Trim() }
            }
        }
    }

    # finalise last entry
    if ($current -and $current.ContainsKey('source')) {
        $entries += [PSCustomObject]$current
    }

    # filter by current platform
    return $entries | Where-Object {
        -not $_.platforms -or $_.platforms -contains $platform
    }
}

# ---------- bootstrap ----------
function Invoke-Bootstrap {
    Write-Action "Dotfiles directory not detected – cloning to $bootstrapDir" 'INFO'

    if (Test-Path $bootstrapDir) {
        if ($(Get-ChildItem -LiteralPath $bootstrapDir).Count -gt 0) {
            Write-Action "Target $bootstrapDir already exists and is not empty – aborting bootstrap" 'ERROR'
            Write-Action "Remove or rename it first, or run install from a cloned copy" 'INFO'
            exit 1
        }
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Action 'git is required for bootstrap mode' 'ERROR'
        exit 1
    }

    if (-not $WhatIf) {
        git clone $repoUrl $bootstrapDir
        if (-not $?) { exit 1 }
        Write-Action "Cloned to $bootstrapDir" 'OK'
    } else {
        Write-Action "Would clone $repoUrl -> $bootstrapDir" 'DRY_RUN'
    }

    $nestedArgs = @{}
    if ($WhatIf) { $nestedArgs.WhatIf = $true }
    if ($Verify) { $nestedArgs.Verify = $true }
    if ($Uninstall) { $nestedArgs.Uninstall = $true }

    $childPath = Join-Path $bootstrapDir 'install.ps1'
    if (Test-Path $childPath) {
        & $childPath @nestedArgs
        exit $LASTEXITCODE
    }
}

# ---------- verification ----------
function Invoke-VerifyMode {
    param([string]$RepoRoot, [array]$Entries)
    $allOk = $true

    foreach ($e in $Entries) {
        $src = Join-Path $RepoRoot $e.source
        $dst = Expand-Path $e.target

        # source exists in repo
        if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
            Write-Action "MISSING SOURCE: $($e.source)" 'ERROR'
            $allOk = $false
            continue
        }

        # destination exists
        if (-not (Test-Path -LiteralPath $dst)) {
            Write-Action "MISSING LINK: $dst" 'ERROR'
            $allOk = $false
            continue
        }

        # destination is a symlink
        $target = Get-TargetFromSymlink $dst
        if (-not $target) {
            if ((Get-Item -LiteralPath $dst -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                Write-Action "BROKEN LINK: $dst" 'ERROR'
            } else {
                Write-Action "REGULAR FILE (not a symlink): $dst" 'ERROR'
            }
            $allOk = $false
            continue
        }

        # points to correct source
        $resolvedTarget = Resolve-Path $target -ErrorAction SilentlyContinue
        $resolvedSrc = Resolve-Path $src -ErrorAction SilentlyContinue
        if (-not $resolvedTarget -or -not $resolvedSrc) {
            Write-Action "BROKEN LINK: $dst -> $target" 'ERROR'
            $allOk = $false
            continue
        }
        if ($resolvedTarget.Path -ne $resolvedSrc.Path) {
            Write-Action "WRONG TARGET: $dst -> $resolvedTarget (expected $resolvedSrc)" 'ERROR'
            $allOk = $false
            continue
        }

        Write-Action "OK: $($e.source) -> $dst" 'OK'
    }

    if (-not $allOk) { exit 1 }
    Write-Action 'All entries verified successfully' 'OK'
}

# ---------- uninstall ----------
function Invoke-UninstallMode {
    param([string]$RepoRoot, [array]$Entries)

    foreach ($e in $Entries) {
        $src = Join-Path $RepoRoot $e.source
        $dst = Expand-Path $e.target

        if (-not (Test-Path -LiteralPath $dst)) {
            Write-Action "SKIP (not installed): $dst" 'SKIP'
            continue
        }

        $target = Get-TargetFromSymlink $dst
        if (-not $target) {
            Write-Action "SKIP (regular file, not ours): $dst" 'SKIP'
            continue
        }

        $resolvedTarget = Resolve-Path $target -ErrorAction SilentlyContinue
        $resolvedSrc = Resolve-Path $src -ErrorAction SilentlyContinue
        if ($resolvedTarget -and $resolvedSrc -and $resolvedTarget.Path -eq $resolvedSrc.Path) {
            # It's our symlink – remove it
            if (-not $WhatIf) {
                Remove-Item -LiteralPath $dst -Force
                Write-Action "REMOVED: $dst" 'REMOVE'
            } else {
                Write-Action "WOULD REMOVE: $dst" 'DRY_RUN'
            }
        } else {
            Write-Action "SKIP (symlink not pointing to repo): $dst -> $target" 'SKIP'
        }
    }
}

# ---------- install ----------
function Install-Dotfile {
    param(
        [string]$SourcePath,
        [string]$DestPath
    )

    # parent directory
    $parentDir = Split-Path $DestPath -Parent
    if (-not (Test-Path -LiteralPath $parentDir)) {
        if (-not $WhatIf) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            Write-Action "Created directory $parentDir" 'INFO'
        } else {
            Write-Action "Would create directory $parentDir" 'DRY_RUN'
        }
    }

    # destination already exists
    if (Test-Path -LiteralPath $DestPath) {
        $existingTarget = Get-TargetFromSymlink $DestPath

        if ($existingTarget) {
            # It's a symlink – check if it points to the right place
            $resolvedTarget = Resolve-Path $existingTarget -ErrorAction SilentlyContinue
            $resolvedSrc = Resolve-Path $SourcePath -ErrorAction SilentlyContinue

            if ($resolvedTarget -and $resolvedSrc -and $resolvedTarget.Path -eq $resolvedSrc.Path) {
                Write-Action "Already correct: $DestPath" 'SKIP'
                return
            }

            # Wrong or broken symlink – replace
            if (-not $WhatIf) {
                Remove-Item -LiteralPath $DestPath -Force
                Write-Action "Removed incorrect link: $DestPath" 'LINK'
            } else {
                Write-Action "Would remove incorrect link: $DestPath" 'DRY_RUN'
            }
        } else {
            # Regular file – remove it (repo is source of truth)
            if (-not $WhatIf) {
                Remove-Item -LiteralPath $DestPath -Force
                Write-Action "Removed regular file: $DestPath" 'REMOVE'
            } else {
                Write-Action "Would remove regular file: $DestPath" 'DRY_RUN'
            }
        }
    }

    # Create symlink
    if (-not $WhatIf) {
        try {
            New-Item -ItemType SymbolicLink -Path $DestPath -Target $SourcePath -Force -ErrorAction Stop | Out-Null
            Write-Action "Linked: $DestPath -> $SourcePath" 'LINK'
        } catch {
            Write-Action "Symlink creation failed: $($_.Exception.Message)" 'ERROR'
            Write-Action "Try running PowerShell as Administrator, or enable Developer Mode in Windows Settings" 'INFO'
            Write-Action "Falling back to copy: $SourcePath -> $DestPath" 'INFO'
            Copy-Item -LiteralPath $SourcePath -Destination $DestPath -Force
            Write-Action "Copied: $DestPath (not a symlink)" 'LINK'
        }
    } else {
        Write-Action "Would link: $DestPath -> $SourcePath" 'DRY_RUN'
    }
}

# ===================================================================
# MAIN
# ===================================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $scriptDir 'dotfiles.yaml'

# ---- bootstrap ----
if (-not (Test-Path $manifestPath)) {
    Invoke-Bootstrap
    exit 0
}

$repoRoot = $scriptDir

# ---- parse manifest ----
$entries = Get-ManifestEntries -ManifestPath $manifestPath

if ($entries.Count -eq 0) {
    Write-Action 'No entries match the current platform – nothing to do' 'INFO'
    exit 0
}

# ---- dispatch ----
if ($Verify) {
    Invoke-VerifyMode -RepoRoot $repoRoot -Entries $entries
    exit 0
}

if ($Uninstall) {
    Invoke-UninstallMode -RepoRoot $repoRoot -Entries $entries
    exit 0
}

# ---- install ----
foreach ($e in $entries) {
    $src = Join-Path $repoRoot $e.source
    $dst = Expand-Path $e.target

    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
        Write-Action "Source file missing: $src" 'ERROR'
        continue
    }

    Install-Dotfile -SourcePath $src -DestPath $dst
}

Write-Action 'Done' 'OK'
