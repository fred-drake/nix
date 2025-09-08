# Configuration specific to the MacBook Pro device.
{
  pkgs,
  config,
  ...
}: {
  # wayland.windowManager.hyprland = {
  #   enable = true;
  #   package = pkgs.hyprland;
  #   xwayland.enable = true;
  #   systemd.enable = true;
  # };

  imports = [../hyprland];

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

  sops.secrets.wireguard-brainrush-stage = {
    sopsFile = config.secrets.host.fredpc.wireguard-brainrush-stage;
    mode = "0400";
    key = "data";
  };
  home.file.".config/wireguard/brainrush-stage.conf".source = config.lib.file.mkOutOfStoreSymlink config.sops.secrets.wireguard-brainrush-stage.path;

  home.file.".config/wireguard/brainrush-stage-public-key.txt".text = ''
    Dri6Y1cfpQ2moikPW7Lzo2HbqMNHefsCpMcYgL0uEFk=
  '';

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      droidcam-obs
    ];
  };
}
