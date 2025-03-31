# Configuration specific to the MacBook Pro device.
{
  config,
  pkgs,
  ...
}: {
  # wayland.windowManager.hyprland = {
  #   enable = true;
  #   package = pkgs.hyprland;
  #   xwayland.enable = true;
  #   systemd.enable = true;
  # };
  imports = [../../../apps/hyprland.nix];
}
