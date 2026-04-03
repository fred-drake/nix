{
  config,
  lib,
  ...
}: let
  home = config.home.homeDirectory;
in {
  home = {
    activation = {
      ssh-restrict = lib.hm.dag.entryAfter ["writeBoundary"] ''
        mkdir -p ${home}/.ssh
        chmod 700 ${home}/.ssh
      '';
      ssh-authorized-keys-copy = lib.hm.dag.entryAfter ["linkGeneration"] ''
        # Remove symlink and create actual file for SSH authorized_keys
        rm -f ${home}/.ssh/authorized_keys
        echo "${config.soft-secrets.workstation.ssh.authorized-keys}" > ${home}/.ssh/authorized_keys
        chmod 600 ${home}/.ssh/authorized_keys
      '';
      zed-settings-copy = lib.hm.dag.entryAfter ["writeBoundary"] ''
        cp -f ${home}/.config/zed/settings-original.json ${home}/.config/zed/settings.json
        cp -f ${home}/.config/zed/keymap-original.json ${home}/.config/zed/keymap.json
      '';
    };

    file = {
      # Note: authorized_keys is handled by home.activation to ensure it's a real file, not a symlink
      "ssh-config" = {
        text = config.soft-secrets.workstation.ssh.config;
        target = ".ssh/config";
      };

      ".ssh" = {
        source = ../../../homefiles/ssh;
        recursive = true;
      };

      ".config" = {
        source = ../../../homefiles/config;
        recursive = true;
      };

      ".config/ghostty/config".text = ''
        app-notifications = no-clipboard-copy
      '';

      ".config/television/config.toml".text = ''
        [shell_integration.channel_triggers]
        "git-branch" = ["git checkout", "git branch"]
        "files" =  ["cat", "less", "bat", "vim", "nvim", "hx"]
        "dirs" = ["cd"]
      '';

      "Pictures" = {
        source = ../../../homefiles/Pictures;
        recursive = true;
      };

      ".hgignore_global" = {source = ../../../homefiles/hgignore_global;};
      ".ideavimrc" = {source = ../../../homefiles/ideavimrc;};
      ".wezterm.lua" = {source = ../../../homefiles/wezterm.lua;};
    };
  };
}
