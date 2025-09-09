local wezterm = require("wezterm")
local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")
local config = wezterm.config_builder()
local act = wezterm.action
local mux = wezterm.mux

-- General
config.font_size = 17
config.line_height = 1.2
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.color_scheme = "tokyonight_night"

-- Tab bar
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.tab_and_split_indices_are_zero_based = false

config.colors = {
    cursor_bg = "#7aa2f7",
    cursor_border = "#7aa2f7",
}

-- Dim inactive panes for better focus contrast
config.inactive_pane_hsb = {
    saturation = 0.6,
    brightness = 0.4,
}

config.window_decorations = "RESIZE"
config.enable_tab_bar = true
config.window_background_opacity = 0.8

-- SSH Domains with multiplexer support
config.ssh_domains = {
    {
        name = "fredpc",
        remote_address = "192.168.30.58",
        username = "fdrake",
        multiplexing = "WezTerm",
    },
}

-- Unix domain for local multiplexing
config.unix_domains = {
    {
        name = "local-mux",
    },
}

-- Set default domain to local multiplexer
config.default_domain = "local-mux"

-- Key Bindings
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
    {
        key = "w",
        mods = "CMD",
        action = act.CloseCurrentPane({ confirm = false }),
    },
    {
        key = "|",
        mods = "LEADER",
        action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
    },
    {
        key = "-",
        mods = "LEADER",
        action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
    },
    {
        key = "h",
        mods = "CTRL",
        action = act.ActivatePaneDirection("Left"),
    },
    {
        key = "j",
        mods = "CTRL",
        action = act.ActivatePaneDirection("Down"),
    },
    {
        key = "k",
        mods = "CTRL",
        action = act.ActivatePaneDirection("Up"),
    },
    {
        key = "l",
        mods = "CTRL",
        action = act.ActivatePaneDirection("Right"),
    },
    {
        key = "LeftArrow",
        mods = "CTRL|SHIFT",
        action = act.AdjustPaneSize({ "Left", 2 }),
    },
    {
        key = "RightArrow",
        mods = "CTRL|SHIFT",
        action = act.AdjustPaneSize({ "Right", 2 }),
    },
    {
        key = "DownArrow",
        mods = "CTRL|SHIFT",
        action = act.AdjustPaneSize({ "Down", 2 }),
    },
    {
        key = "UpArrow",
        mods = "CTRL|SHIFT",
        action = act.AdjustPaneSize({ "Up", 2 }),
    },
    {
        key = "s",
        mods = "LEADER",
        action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
    },
    {
        key = "c",
        mods = "LEADER",
        action = act.SpawnTab("CurrentPaneDomain"),
    },
    {
        key = ",",
        mods = "LEADER",
        action = act.PromptInputLine({
            description = "Enter new name for tab",
            action = wezterm.action_callback(function(window, pane, line)
                if line then
                    window:active_tab():set_title(line)
                end
            end),
        }),
    },
    {
        key = "K",
        mods = "LEADER|SHIFT",
        action = act.CloseCurrentTab({ confirm = false }),
    },
    {
        key = "$",
        mods = "LEADER|SHIFT",
        action = act.PromptInputLine({
            description = "Enter new name for session",
            action = wezterm.action_callback(function(window, pane, line)
                if line then
                    mux.rename_workspace(window:mux_window():get_workspace(), line)
                end
            end),
        }),
    },
    {
        key = "d",
        mods = "LEADER",
        action = act.DetachDomain("CurrentPaneDomain"),
    },
    {
        key = "Enter",
        mods = "ALT",
        action = act.DisableDefaultAssignment,
    },
    {
        key = "=",
        mods = "LEADER",
        action = act.ResetFontAndWindowSize,
    },
    {
        key = "x",
        mods = "LEADER",
        action = act.CloseCurrentPane({ confirm = true }),
    },
}

for i = 1, 9 do
    table.insert(config.keys, {
        key = tostring(i),
        mods = "LEADER",
        action = act.ActivateTab(i - 1),
    })
end

-- Smart Splits Neovim configuration
smart_splits.apply_to_config(config, {
    direction_keys = { "h", "j", "k", "l" },
    resize = { "LeftArrow", "DownArrow", "UpArrow", "RightArrow" },
    -- modifier keys to combine with direction_keys
    modifiers = {
        move = "CTRL", -- modifier to use for pane movement
        resize = "CTRL|SHIFT", -- modifier to use for pane resize
    },
    -- log level to use: info, warn, error
    log_level = "info",
})

return config
