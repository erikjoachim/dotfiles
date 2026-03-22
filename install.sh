#!/bin/bash

repo_url="https://github.com/erikjoachim/dotfiles.git"
temp_dir=$(mktemp -d)

git clone --depth 1 "$repo_url" "$temp_dir" 2>/dev/null || exit 1
cd "$temp_dir"

echo "Select dotfiles to install:"
echo "  1) bashrc"
echo "  2) wezterm"
echo "  3) alacritty"
echo "  a) all"
echo "  (space-separated for multiple, e.g. '1 3')"
read -p "Selection: " selection

install_bashrc() {
    [ -f ".bashrc" ] || return
    [ -f "$HOME/.bashrc" ] && mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
    cp .bashrc "$HOME/.bashrc"
    read -p "cdinit path (enter to skip): " path
    [ -n "$path" ] && sed -i "s|<PERSONAL_PROJECTS_PATH>|$path|g" "$HOME/.bashrc"
}

install_wezterm() {
    [ -f ".wezterm.lua" ] || return
    [ -f "$HOME/.wezterm.lua" ] && mv "$HOME/.wezterm.lua" "$HOME/.wezterm.lua.bak"
    cp .wezterm.lua "$HOME/.wezterm.lua"
}

install_alacritty() {
    [ -f "alacritty.toml" ] || return
    dir="$([ -n "$APPDATA" ] && echo "$APPDATA/alacritty" || echo "$HOME/.config/alacritty")"
    mkdir -p "$dir"
    [ -f "$dir/alacritty.toml" ] && mv "$dir/alacritty.toml" "$dir/alacritty.toml.bak"
    cp alacritty.toml "$dir/alacritty.toml"
    read -p "alacritty working dir (enter to skip): " path
    [ -n "$path" ] && sed -i "s|<WORKING_DIRECTORY>|$path|g" "$dir/alacritty.toml"
}

if [[ "$selection" == *"a"* ]]; then
    install_bashrc
    install_wezterm
    install_alacritty
else
    [[ "$selection" == *"1"* ]] && install_bashrc
    [[ "$selection" == *"2"* ]] && install_wezterm
    [[ "$selection" == *"3"* ]] && install_alacritty
fi

cd /
rm -rf "$temp_dir"
echo "Done"