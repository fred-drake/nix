{
  pkgs,
  lib,
  ...
}: let
  vscode-config = (import ../../../apps/vscode/global-configuration.nix) {inherit pkgs lib;};
  discordo-config = ''
    [theme.title]
    alignment = "left"
    normal_style = { attributes = "dim" }
    active_style = { foreground = "purple", attributes = "bold" }

    [theme.footer]
    alignment = "left"
    normal_style = { attributes = "dim" }
    active_style = { foreground = "purple", attributes = "bold" }

    [theme.border]
    enabled = true
    padding = [0, 0, 1, 1]
    normal_style = { foreground = "purple", attributes = "dim" }
    active_style = { foreground = "purple", attributes = "bold" }
    normal_set = "round"
    active_set = "round"

    [theme.guilds_tree]
    auto_expand_folders = true
    graphics = true
    graphics_color = "purple"

    [theme.messages_list]
    reply_indicator = ">"
    forwarded_indicator = "<"
    mention_style = { foreground = "yellow", attributes = "bold" }
    emoji_style = { foreground = "yellow" }
    url_style = { foreground = "aqua" }
    attachment_style = { foreground = "aqua" }
    message_style = { attributes = "dim" }
    selected_message_style = { attributes = "reverse" }
  '';
in {
  home.file =
    if pkgs.stdenv.hostPlatform.isDarwin
    then {
      "Library/Application Support/discordo/config.toml" = {
        text = discordo-config;
      };
      ".config/discordo/config.toml" = {
        text = discordo-config;
      };
      "Library/Application Support/Code/User/settings.json" = {
        text = builtins.toJSON vscode-config.globalSettings;
      };
      "Library/Application Support/Code/User/keybindings.json" = {
        text = builtins.toJSON vscode-config.globalKeyBindings;
      };
      "Library/Application Support/Cursor/User/settings.json" = {
        text = builtins.toJSON vscode-config.globalSettings;
      };
      "Library/Application Support/Cursor/User/keybindings.json" = {
        text = builtins.toJSON vscode-config.globalKeyBindings;
      };
      "Library/Application Support/Windsurf/User/settings.json" = {
        text = builtins.toJSON vscode-config.globalSettings;
      };
      "Library/Application Support/Windsurf/User/keybindings.json" = {
        text = builtins.toJSON vscode-config.globalKeyBindings;
      };
    }
    else {
      ".config/discordo/config.toml" = {
        text = discordo-config;
      };
      ".config/Code/User/settings.json" = {
        text = builtins.toJSON vscode-config.globalSettings;
      };
      ".config/Code/User/keybindings.json" = {
        text = builtins.toJSON vscode-config.globalKeyBindings;
      };
      ".config/Cursor/User/settings.json" = {
        text = builtins.toJSON vscode-config.globalSettings;
      };
      ".config/Cursor/User/keybindings.json" = {
        text = builtins.toJSON vscode-config.globalKeyBindings;
      };
      ".config/Windsurf/User/settings.json" = {
        text = builtins.toJSON vscode-config.globalSettings;
      };
      ".config/Windsurf/User/keybindings.json" = {
        text = builtins.toJSON vscode-config.globalKeyBindings;
      };
    };

  home.packages =
    (with pkgs; [
      discordo
    ])
    ++ (
      if pkgs.stdenv.hostPlatform.isDarwin
      then [
        (pkgs.writeShellScriptBin "windsurf-code" ''
          EXT_DIR=$(grep exec /etc/profiles/per-user/fdrake/bin/code | cut -f5 -d' ')
          exec /opt/homebrew/bin/windsurf --extensions-dir $EXT_DIR "$@"
        '')
      ]
      else []
    );
}
