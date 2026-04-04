# Hyprland desktop feature — contributes to both NixOS and Home Manager
# via deferredModules. Applies to hosts with my.hasHyprland = true.
{lib, ...}: {
  # NixOS-level Hyprland config — programs, packages, session variables
  my.modules.nixos.hyprland = {
    config,
    lib,
    pkgs,
    inputs,
    ...
  }:
    lib.mkIf config.my.hasHyprland {
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
    };

  # HM-level Hyprland config — imports the existing feature module.
  # The feature module itself is guarded with mkIf on hostName.
  my.modules.home-manager.hyprland = {
    imports = [../home-manager/features/hyprland];
  };
}
