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

config.colors = {
    cursor_bg = "#7aa2f7",
    cursor_border = "#7aa2f7",
}

config.window_decorations = "RESIZE"
config.enable_tab_bar = false

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
        key = "s",
        mods = "LEADER",
        action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
    },
    {
        key = "c",
        mods = "LEADER",
        -- action = wezterm.action.ShowTabNavigator,
        action = act.ShowLauncherArgs({ flags = "FUZZY|TABS" }),
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
}

-- Smart Splits Neovim configuration
smart_splits.apply_to_config(config, {
    direction_keys = { "h", "j", "k", "l" },
    -- modifier keys to combine with direction_keys
    modifiers = {
        move = "CTRL", -- modifier to use for pane movement, e.g. CTRL+h to move left
        resize = "META", -- modifier to use for pane resize, e.g. META+h to resize to the left
    },
    -- log level to use: info, warn, error
    log_level = "info",
})

return config
