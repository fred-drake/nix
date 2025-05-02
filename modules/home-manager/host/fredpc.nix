# Configuration specific to the MacBook Pro device.
{
  config,
  lib,
  ...
}: let
  home = config.home.homeDirectory;
in {
  # wayland.windowManager.hyprland = {
  #   enable = true;
  #   package = pkgs.hyprland;
  #   xwayland.enable = true;
  #   systemd.enable = true;
  # };
  imports = [../../../apps/hyprland.nix];

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface".color-scheme = "prefer-dark";
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-type = "nothing";
        sleep-inactive-ac-timeout = 0;
        sleep-inactive-battery-timeout = 0;
      };
    };
  };

  # Tie Windsurf extensions to the server used for SSH connections
  home.activation = {
    windsurf-extensions = lib.hm.dag.entryAfter ["writeBoundary"] ''
      EXT_DIR=$(grep exec /etc/profiles/per-user/fdrake/bin/code | cut -f5 -d' ')
      mkdir -p ${home}/.windsurf-server
      rm -rf ${home}/.windsurf-server/extensions
      ln -s $EXT_DIR ${home}/.windsurf-server
    '';
  };
}
