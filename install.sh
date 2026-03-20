#!/bin/bash

repo_url="https://github.com/erikjoachim/dotfiles.git"
temp_dir=$(mktemp -d)

git clone --depth 1 "$repo_url" "$temp_dir" 2>/dev/null || exit 1
cd "$temp_dir"

# Bashrc
if [ -f ".bashrc" ]; then
    [ -f "$HOME/.bashrc" ] && mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
    cp .bashrc "$HOME/.bashrc"
    read -p "cdinit path (enter to skip): " path
    [ -n "$path" ] && sed -i "s|<PERSONAL_PROJECTS_PATH>|$path|g" "$HOME/.bashrc"
fi

# Wezterm
[ -f ".wezterm.lua" ] && [ ! -f "$HOME/.wezterm.lua" ] && cp .wezterm.lua "$HOME/.wezterm.lua"

# Alacritty
if [ -f "alacritty.toml" ]; then
    dir="$([ -n "$APPDATA" ] && echo "$APPDATA/alacritty" || echo "$HOME/.config/alacritty")"
    mkdir -p "$dir"
    [ -f "$dir/alacritty.toml" ] && mv "$dir/alacritty.toml" "$dir/alacritty.toml.bak"
    cp alacritty.toml "$dir/alacritty.toml"
    read -p "alacritty working dir (enter to skip): " path
    [ -n "$path" ] && sed -i "s|<WORKING_DIRECTORY>|$path|g" "$dir/alacritty.toml"
fi

cd /
rm -rf "$temp_dir"
echo "Done"