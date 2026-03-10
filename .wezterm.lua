local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font("MesloLGM Nerd Font")
config.font_size = 11
config.color_scheme = "CustomDark"

config.color_schemes = {
  ["CustomDark"] = {
    foreground = "#c0c0c0",
    background = "#1e1e1e",  -- dark gray background
    cursor_bg = "#ffffff",
    cursor_border = "#ffffff",
    cursor_fg = "#000000",
    selection_bg = "#444444",
    selection_fg = "#ffffff",
    ansi = {"#000000","#ff5555","#50fa7b","#f1fa8c","#bd93f9","#ff79c6","#8be9fd","#bbbbbb"},
    brights = {"#555555","#ff5555","#50fa7b","#f1fa8c","#bd93f9","#ff79c6","#8be9fd","#ffffff"}
  }
}

-- keybindings
config.keys = {
  -- Ctrl+Backspace deletes previous word
  {
    key = "Backspace",
    mods = "CTRL",
    action = wezterm.action.SendString("\x1b\x7f"),
  },
  -- Ctrl+C: Copy if text selected, otherwise send interrupt to process
  {
    key = "c",
    mods = "CTRL",
    action = wezterm.action.CopyTo("Clipboard"),
  },
  -- Ctrl+V: Paste from clipboard
  {
    key = "v",
    mods = "CTRL",
    action = wezterm.action.PasteFrom("Clipboard"),
  },
}

wezterm.plugin
  .require('https://github.com/yriveiro/wezterm-tabs')
  .apply_to_config(config, { tabs = { tab_bar_at_bottom = true } })

config.initial_cols = 80
config.initial_rows = 30
config.default_prog = { "C:\\Program Files\\Git\\bin\\bash.exe", "--login" }

return config
