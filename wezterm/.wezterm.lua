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
--  PROCESS CONFIG: Icon and friendly name for each process
-- ============================================================
local processes = {
    ["debug"]       = { icon = wezterm.nerdfonts.cod_debug_console,   name = "debug" },
    ["bash"]        = { icon = wezterm.nerdfonts.cod_terminal_bash,  name = "bash" },
    ["bash.exe"]    = { icon = wezterm.nerdfonts.cod_terminal_bash,  name = "bash" },
    ["cargo"]       = { icon = wezterm.nerdfonts.dev_rust,           name = "cargo" },
    ["curl"]        = { icon = wezterm.nerdfonts.md_waves,           name = "curl" },
    ["docker"]      = { icon = wezterm.nerdfonts.linux_docker,       name = "docker" },
    ["docker.exe"]  = { icon = wezterm.nerdfonts.linux_docker,       name = "docker" },
    ["gh"]          = { icon = wezterm.nerdfonts.dev_github_badge,   name = "gh" },
    ["git"]         = { icon = wezterm.nerdfonts.dev_git,             name = "git" },
    ["git.exe"]     = { icon = wezterm.nerdfonts.dev_git,             name = "git" },
    ["go"]          = { icon = wezterm.nerdfonts.seti_go,             name = "go" },
    ["kubectl.exe"] = { icon = wezterm.nerdfonts.linux_docker,       name = "kubectl" },
    ["lua"]         = { icon = wezterm.nerdfonts.seti_lua,            name = "lua" },
    ["make"]        = { icon = wezterm.nerdfonts.seti_makefile,      name = "make" },
    ["node"]        = { icon = wezterm.nerdfonts.md_hexagon,         name = "node" },
    ["node.exe"]    = { icon = wezterm.nerdfonts.md_hexagon,         name = "node" },
    ["npm"]         = { icon = wezterm.nerdfonts.md_hexagon,         name = "npm" },
    ["npx"]         = { icon = wezterm.nerdfonts.md_hexagon,         name = "npx" },
    ["nvim"]        = { icon = wezterm.nerdfonts.custom_vim,         name = "nvim" },
    ["nvim.exe"]    = { icon = wezterm.nerdfonts.custom_vim,         name = "nvim" },
    ["opencode"]    = { icon = wezterm.nerdfonts.cod_code,            name = "opencode" },
    ["oc"]          = { icon = wezterm.nerdfonts.cod_code,            name = "opencode" },
    ["sudo"]        = { icon = wezterm.nerdfonts.fa_hashtag,         name = "sudo" },
    ["vim"]         = { icon = wezterm.nerdfonts.dev_vim,            name = "vim" },
    ["vim.exe"]     = { icon = wezterm.nerdfonts.dev_vim,            name = "vim" },
    ["wget"]        = { icon = wezterm.nerdfonts.md_arrow_down_box,  name = "wget" },
    ["zsh"]         = { icon = wezterm.nerdfonts.dev_terminal,       name = "zsh" },
    ["lazygit"]     = { icon = wezterm.nerdfonts.dev_github_alt,     name = "lazygit" },
    ["pwsh"]        = { icon = wezterm.nerdfonts.cod_terminal_powershell, name = "pwsh" },
    ["powershell.exe"] = { icon = wezterm.nerdfonts.cod_terminal_powershell, name = "powershell" },
    ["cmd.exe"]     = { icon = wezterm.nerdfonts.cod_terminal_cmd,    name = "cmd" },
    ["python.exe"]  = { icon = wezterm.nerdfonts.mdi_language_python, name = "python" },
    ["python"]      = { icon = wezterm.nerdfonts.mdi_language_python, name = "python" },
    ["python3"]     = { icon = wezterm.nerdfonts.mdi_language_python, name = "python" },
}

-- Helper to get process info
local get_process_info = function(name)
    local lower = string.lower(name)
    if processes[lower] then
        return processes[lower]
    end
    for key, proc in pairs(processes) do
        if string.find(lower, key, 1, true) then
            return proc
        end
    end
    return { icon = '', name = name, keep_custom = false }
end

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
    local proc_info = get_process_info(process)
    local icon = proc_info.icon .. ' '

    title = wezterm.truncate_right(proc_info.name, max_width - 3)

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

-- ============================================================
--  FORMAT TAB TITLE: Main callback
-- ============================================================
wezterm.on('format-tab-title', function(tab, tabs, panes, wezterm_config, hover, max_width)
    local active_bg = "#bd93f9"  -- Purple for active tab
    local active_fg = "#1e1e1e"  -- Dark text
    local inactive_bg = "#1e1e1e" -- Dark background
    local inactive_fg = "#c0c0c0" -- Light text
    local background = "#1e1e1e"   -- Tab bar background

    local title = tab_title(tab, max_width)
    local tab_idx = tab_current_idx(tabs, tab)
    local tab_meta = tab_current_meta(tab_idx, tab)
    local is_last = tab_idx == #tabs

    local tab_text = string.format(' %s %s%s', tab_meta, separators.arrow_thin_left, title)

    if tab.is_active then
        -- ACTIVE TAB: Purple background with dark text
        return {
            { Background = { Color = active_bg } },
            { Foreground = { Color = active_fg } },
            { Attribute = { Intensity = "Bold" } },
            { Text = tab_text },
            { Background = { Color = background } },
            { Foreground = { Color = active_bg } },
            { Text = separators.arrow_solid_left },
            { Background = { Color = is_last and background or inactive_bg } },
            { Foreground = { Color = background } },
            { Text = separators.arrow_solid_left },
        }
    else
        -- INACTIVE TAB: Dark background with light text
        local next_tab = tabs[tab_idx + 1]
        local next_bg = is_last and background
            or (next_tab and next_tab.is_active and active_bg or inactive_bg)

        return {
            { Background = { Color = inactive_bg } },
            { Foreground = { Color = inactive_fg } },
            { Text = tab_text },
            { Background = { Color = background } },
            { Foreground = { Color = inactive_bg } },
            { Text = separators.arrow_solid_left },
            { Background = { Color = next_bg } },
            { Foreground = { Color = background } },
            { Text = separators.arrow_solid_left },
        }
    end
end)

config.initial_cols = 80
config.initial_rows = 30
config.default_prog = { "C:\\Program Files\\Git\\bin\\bash.exe", "--login" }

return config
