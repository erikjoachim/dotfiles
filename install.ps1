$repoUrl = "https://github.com/erikjoachim/dotfiles.git"
$tempDir = [System.IO.Path]::GetTempPath() + "dotfiles-" + (Get-Random)

git clone --depth 1 $repoUrl $tempDir
if (-not $?) { exit 1 }
Push-Location $tempDir

# Bashrc
if (Test-Path ".bashrc") {
    $dest = "$env:USERPROFILE\.bashrc"
    if (Test-Path $dest) { Move-Item $dest "$dest.bak" -Force }
    Copy-Item ".bashrc" $dest -Force
    $path = Read-Host "cdinit path (enter to skip)"
    if ($path) {
        (Get-Content $dest) -replace '<PERSONAL_PROJECTS_PATH>', $path | Set-Content $dest
    }
}

# Wezterm
$wezDest = "$env:USERPROFILE\.wezterm.lua"
if (Test-Path ".wezterm.lua" -and -not (Test-Path $wezDest)) {
    Copy-Item ".wezterm.lua" $wezDest -Force
}

# Alacritty
if (Test-Path "alacritty.toml") {
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

Pop-Location
Remove-Item -Recurse -Force $tempDir
Write-Host "Done"