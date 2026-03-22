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
    ansi = { "#000000", "#ff5555", "#50fa7b", "#f1fa8c", "#bd93f9", "#ff79c6", "#8be9fd", "#bbbbbb" },
    brights = { "#555555", "#ff5555", "#50fa7b", "#f1fa8c", "#bd93f9", "#ff79c6", "#8be9fd", "#ffffff" },

    -- === TOGGLE TAB BAR COLORS ===
    -- These colors are used by the retro tab bar styling
    -- =================================
    tab_bar = {
        background = "#1e1e1e",
        active_tab = {
            bg_color = "#bd93f9",
            fg_color = "#1e1e1e",
            intensity = "Normal",
            italic = false,
            strikethrough = false,
            underline = "None",
        },
        inactive_tab = {
            bg_color = "#1e1e1e",
            fg_color = "#c0c0c0",
            intensity = "Normal",
            italic = false,
            strikethrough = false,
            underline = "None",
        },
        inactive_tab_hover = {
            bg_color = "#2e2e2e",
            fg_color = "#ffffff",
            intensity = "Normal",
            italic = true,
            strikethrough = false,
            underline = "None",
        },
        new_tab = {
            bg_color = "#1e1e1e",
            fg_color = "#c0c0c0",
            intensity = "Normal",
            italic = false,
            strikethrough = false,
            underline = "None",
        },
        new_tab_hover = {
            bg_color = "#bd93f9",
            fg_color = "#1e1e1e",
            intensity = "Normal",
            italic = false,
            strikethrough = false,
            underline = "None",
        },
    },
  }
}

-- ============================================================
--  TAB BAR CONFIGURATION
-- ============================================================
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32
config.unzoom_on_switch_pane = true

-- ============================================================
--  KEYBINDINGS
-- ============================================================
config.keys = {
  -- Ctrl+Backspace deletes previous word
  {
    key = "Backspace",
    mods = "CTRL",
        action = wezterm.action.SendKey { key = 'w', mods = 'CTRL' },
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

config.initial_cols = 80
config.initial_rows = 30
config.default_prog = { "C:\\Program Files\\Git\\bin\\bash.exe", "--login" }

return config
