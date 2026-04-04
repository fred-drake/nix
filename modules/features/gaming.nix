# Gaming feature — contributes to NixOS via deferredModules.
# Applies to hosts with my.hasGaming = true.
{lib, ...}: {
  my.modules.nixos.gaming = {
    config,
    lib,
    pkgs,
    ...
  }:
    lib.mkIf config.my.hasGaming {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        gamescopeSession.enable = true;
      };

      programs.gamemode.enable = true;

      environment.systemPackages = with pkgs; [
        gamescope
        protonup-qt
      ];

      # Xbox wireless controller support
      boot.extraModulePackages = with config.boot.kernelPackages; [
        xpadneo
      ];
      boot.kernelModules = ["xpadneo"];

      # Bluetooth for wireless controllers
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Privacy = "device";
            JustWorksRepairing = "always";
            Class = "0x000100";
            FastConnectable = true;
          };
        };
      };

      services.blueman.enable = true;
    };
}
