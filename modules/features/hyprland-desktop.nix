# Hyprland desktop feature — contributes to both NixOS and Home Manager
# via deferredModules. Applies to hosts with my.hasHyprland = true.
_: {
  # NixOS-level Hyprland config — programs, packages, session variables
  my.modules.nixos.hyprland = {
    config,
    lib,
    pkgs,
    ...
  }:
    lib.mkIf config.my.hasHyprland {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
        package = pkgs.hyprland-packages.hyprland;
      };

      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      networking.networkmanager.enable = true;

      environment.systemPackages = with pkgs; [
        waybar
        wofi
        wlogout
        hyprshot
        satty
        rose-pine-hyprcursor
        xdg-desktop-portal-gtk
      ];

      programs.waybar = {
        enable = true;
      };
    };

  # HM-level Hyprland config — imports the existing feature module.
  # The feature module uses capability guards (hasHyprland) internally.
  my.modules.home-manager.hyprland = {
    imports = [../home-manager/features/hyprland];
  };
}
