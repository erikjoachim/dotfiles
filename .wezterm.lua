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

-- ============================================================
--  ICON MAPPING: Process name -> Nerd Font icon
-- ============================================================
local icons = {
    ["debug"] = wezterm.nerdfonts.cod_debug_console,
    ["bash"] = wezterm.nerdfonts.cod_terminal_bash,
    ["cargo"] = wezterm.nerdfonts.dev_rust,
    ["curl"] = wezterm.nerdfonts.md_waves,
    ["docker"] = wezterm.nerdfonts.linux_docker,
    ["docker-compose"] = wezterm.nerdfonts.linux_docker,
    ["gh"] = wezterm.nerdfonts.dev_github_badge,
    ["git"] = wezterm.nerdfonts.dev_git,
    ["go"] = wezterm.nerdfonts.seti_go,
    ["kubectl"] = wezterm.nerdfonts.linux_docker,
    ["lua"] = wezterm.nerdfonts.seti_lua,
    ["make"] = wezterm.nerdfonts.seti_makefile,
    ["node"] = wezterm.nerdfonts.md_hexagon,
    ["nvim"] = wezterm.nerdfonts.custom_vim,
    ["sudo"] = wezterm.nerdfonts.fa_hashtag,
    ["vim"] = wezterm.nerdfonts.dev_vim,
    ["wget"] = wezterm.nerdfonts.md_arrow_down_box,
    ["zsh"] = wezterm.nerdfonts.dev_terminal,
    ["lazygit"] = wezterm.nerdfonts.dev_github_alt,
}

-- ============================================================
--  POWERLINE SEPARATORS
-- ============================================================
local separators = {
    arrow_solid_left = '\u{e0b0}',
    arrow_solid_right = '\u{e0b2}',
    arrow_thin_left = '\u{e0b1}',
    arrow_thin_right = '\u{e0b3}',
}

-- ============================================================
--  TOGGLE ZOOM INDICATOR
--  Set to false to disable zoom indicators in tabs
-- ============================================================
local ZOOM_INDICATOR_ENABLED = true

-- ============================================================
--  HELPER: Parse title to extract process name and custom title
-- ============================================================
local function parse_title(title)
    local process, custom = title:match '^(%S+)%s*%-?%s*(.*)$'
    return process or 'unknown', custom or ''
end

-- ============================================================
--  HELPER: Get formatted tab title with icon
-- ============================================================
local function tab_title(tab, max_width)
    local title = (tab.tab_title and #tab.tab_title > 0) and tab.tab_title
        or tab.active_pane.title
    local process, custom = parse_title(title)
    local icon = ''

    local proc = string.lower(process)

    if icons[proc] then
        icon = icons[proc] .. ' '
    end

    if custom ~= '' then
        title = custom
    end

    title = wezterm.truncate_right(title, max_width - 3)

    return ' ' .. icon .. title .. ' '
end

-- ============================================================
--  HELPER: Get current tab index (1-based)
-- ============================================================
local function tab_current_idx(tabs, tab)
    local idx = 0
    for i, t in ipairs(tabs) do
        if t.tab_id == tab.tab_id then
            idx = i
            break
        end
    end
    return idx
end

-- ============================================================
--  HELPER: Get tab metadata (index + zoom indicator)
-- ============================================================
local function tab_current_meta(idx, tab)
    -- Early return if zoom indicator is disabled
    if not ZOOM_INDICATOR_ENABLED then
        return tostring(idx)
    end

    -- Get pane information
    local mux_tab = wezterm.mux.get_tab(tab.tab_id)
    local panes = mux_tab:panes_with_info()
    local npanes = #panes

    -- Early return for single pane
    if npanes == 1 then
        return tostring(idx)
    end

    -- Check for zoomed pane
    local is_zoomed = false
    for _, pane in ipairs(panes) do
        if pane.is_zoomed then
            is_zoomed = true
            break
        end
    end

    -- Show zoom indicator
    if is_zoomed then
        return '\u{f833}'  -- Nerd Font zoom icon
    end

    return tostring(idx)
end

config.initial_cols = 80
config.initial_rows = 30
config.default_prog = { "C:\\Program Files\\Git\\bin\\bash.exe", "--login" }

return config
