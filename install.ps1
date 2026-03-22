$repoUrl = "https://github.com/erikjoachim/dotfiles.git"
$tempDir = [System.IO.Path]::GetTempPath() + "dotfiles-" + (Get-Random)

git clone --depth 1 $repoUrl $tempDir
if (-not $?) { exit 1 }
Push-Location $tempDir

Write-Host "Select dotfiles to install:"
Write-Host "  1) bashrc"
Write-Host "  2) wezterm"
Write-Host "  3) alacritty"
Write-Host "  a) all"
Write-Host "  (comma-separated for multiple, e.g. '1,3')"
$selection = Read-Host "Selection"

function Install-Bashrc {
    if (-not (Test-Path ".bashrc")) { return }
    $dest = "$env:USERPROFILE\.bashrc"
    if (Test-Path $dest) { Move-Item $dest "$dest.bak" -Force }
    Copy-Item ".bashrc" $dest -Force
    $path = Read-Host "cdinit path (enter to skip)"
    if ($path) {
        (Get-Content $dest) -replace '<PERSONAL_PROJECTS_PATH>', $path | Set-Content $dest
    }
}

function Install-Wezterm {
    if (-not (Test-Path ".wezterm.lua")) { return }
    $dest = "$env:USERPROFILE\.wezterm.lua"
    if (Test-Path $dest) { Move-Item $dest "$dest.bak" -Force }
    Copy-Item ".wezterm.lua" $dest -Force
}

function Install-Alacritty {
    if (-not (Test-Path "alacritty.toml")) { return }
    $configDir = "$env:APPDATA\alacritty"
    if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
    $dest = "$configDir\alacritty.toml"
    if (Test-Path $dest) { Move-Item $dest "$dest.bak" -Force }
    Copy-Item "alacritty.toml" $dest -Force
    $path = Read-Host "alacritty working dir (enter to skip)"
    if ($path) {
        (Get-Content $dest) -replace '<WORKING_DIRECTORY>', $path | Set-Content $dest
    }
}

if ($selection -match "a") {
    Install-Bashrc
    Install-Wezterm
    Install-Alacritty
} else {
    if ($selection -match "1") { Install-Bashrc }
    if ($selection -match "2") { Install-Wezterm }
    if ($selection -match "3") { Install-Alacritty }
}

Pop-Location
Remove-Item -Recurse -Force $tempDir
Write-Host "Done"