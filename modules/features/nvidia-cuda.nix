# NVIDIA GPU + CUDA feature — contributes to NixOS via deferredModules.
# Applies to hosts with my.hasNvidia = true.
# NOTE: anton (WSL2) has its own CUDA config via Colmena — it uses
# wsl.useWindowsDriver for GPU passthrough, which is fundamentally
# different from bare-metal NVIDIA. This module handles bare-metal only.
_: {
  my.modules.nixos.nvidia-cuda = {
    config,
    lib,
    pkgs,
    pkgsCuda ? pkgs,
    pkgsUnstable ? pkgs,
    ...
  }:
    lib.mkIf config.my.hasNvidia {
      services.xserver.videoDrivers = ["nvidia"];

      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
        };
        nvidia = {
          package = config.boot.kernelPackages.nvidiaPackages.beta;
          modesetting.enable = true;
          nvidiaSettings = true;
          open = true;
          powerManagement.enable = false;
        };
        nvidia-container-toolkit.enable = true;
      };

      environment.systemPackages = with pkgs; [
        pkgsCuda.cudaPackages.cudatoolkit
        pkgsUnstable.cudaPackages.cudnn
        pkgsCuda.nvidia-container-toolkit
        crun
      ];

      # Podman NVIDIA runtime integration
      virtualisation.containers.containersConf.settings = {
        engine = {
          runtimes = {
            nvidia = [
              "${pkgsCuda.nvidia-container-toolkit}/bin/nvidia-container-runtime"
            ];
          };
        };
      };

      # CDI hook symlink for podman/crun
      systemd.tmpfiles.rules = [
        "L+ /usr/bin/nvidia-cdi-hook - - - - ${pkgsCuda.nvidia-container-toolkit.tools}/bin/nvidia-cdi-hook"
      ];
    };
}
