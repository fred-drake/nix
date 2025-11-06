{
  pkgs,
  inputs,
  ...
}: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages."${pkgs.stdenv.hostPlatform.system}".hyprland;
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    waybar
    wofi
    wlogout
    hyprshot
    satty
    inputs.rose-pine-hyprcursor.packages.${pkgs.stdenv.hostPlatform.system}.default
    xdg-desktop-portal-gtk
  ];

  programs.waybar = {
    enable = true;
  };
}
