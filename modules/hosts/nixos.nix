# NixOS host definitions — one nixosSystem per host.
{
  inputs,
  config,
  ...
}: let
  root = ../..;
  infra = import ../../lib/nixos-infra.nix {inherit inputs config;};
  mkHomeManager = import ../../lib/mk-home-manager.nix {inherit inputs;};
  inherit (inputs) disko home-manager nixos-hardware secrets;
  inherit (infra) commonModules deferredHmModules;

  # Centralized pkgs for each architecture
  x86Pkgs = import ../../lib/mkPkgs.nix {
    inherit inputs;
    system = "x86_64-linux";
  };
  aarch64Pkgs = import ../../lib/mkPkgs.nix {
    inherit inputs;
    system = "aarch64-linux";
  };
in {
  flake.nixosConfigurations = {
    macbookx86 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      pkgs = x86Pkgs.pkgs;
      modules =
        commonModules
        ++ [
          {
            my.hostName = "macbookx86";
            my.isWorkstation = true;
            my.hasDesktop = true;
            my.hasGnome = true;
            my.hasPipewire = true;
          }
          inputs.nur.nixosModules.nur
          (root + "/modules/nixos/host/macbookx86/configuration.nix")
          nixos-hardware.nixosModules.apple-t2
          home-manager.nixosModules.home-manager
          {
            home-manager = mkHomeManager {
              hostName = "macbookx86";
              pkgsStable = x86Pkgs.pkgsStable;
              deferredHomeManagerModules = deferredHmModules;
              imports = [];
            };
          }
        ];
    };

    fredpc = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # fredpc has an extra overlay that pins devenv from nixpkgs-unstable
      pkgs = x86Pkgs.mkPkgs inputs.nixpkgs {
        overlays =
          x86Pkgs.vscodeOverlays
          ++ [
            (_: _prev: {
              inherit
                (x86Pkgs.pkgsUnstable)
                devenv
                ;
            })
          ];
      };
      specialArgs = {
        inherit (x86Pkgs) pkgsCuda pkgsUnstable pkgsStable;
      };
      modules =
        commonModules
        ++ [
          {
            my.hostName = "fredpc";
            my.isWorkstation = true;
            my.hasDesktop = true;
            my.hasHyprland = true;
            my.hasGnome = true;
            my.hasNvidia = true;
            my.hasGaming = true;
            my.hasGpuPassthrough = true;
            my.hasPipewire = true;
          }
          secrets.nixosModules.secrets
          (root + "/modules/nixos")
          (root + "/modules/nixos/host/fredpc/configuration.nix")
          (root + "/modules/nixos/host/fredpc/hardware-configuration.nix")
          home-manager.nixosModules.home-manager
          {
            home-manager = mkHomeManager {
              hostName = "fredpc";
              pkgsStable = x86Pkgs.pkgsStable;
              deferredHomeManagerModules = deferredHmModules;
              imports = [
                (root + "/modules/home-manager/host/fredpc.nix")
              ];
            };
          }
        ];
    };

    nixosaarch64vm = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      pkgs = aarch64Pkgs.mkPkgs inputs.nixpkgs {
        overlays = [inputs.nix4vscode.overlays.forVscode];
      };
      specialArgs = {
        # Note: nixosaarch64vm uses x86_64-linux pkgs for unstable/stable
        # with cudaSupport — preserving existing behavior (see plan N6/R6)
        pkgsUnstable = x86Pkgs.mkPkgs inputs.nixpkgs-unstable {cudaSupport = true;};
        pkgsStable = x86Pkgs.mkPkgs inputs.nixpkgs-stable {cudaSupport = true;};
      };
      modules =
        commonModules
        ++ [
          {my.hostName = "nixosaarch64vm";} # server — all capability flags default to false
          disko.nixosModules.disko
          (root + "/modules/nixos")
          (root + "/modules/nixos/host/nixosaarch64vm/configuration.nix")
          home-manager.nixosModules.home-manager
          {
            home-manager = mkHomeManager {
              hostName = "nixosaarch64vm";
              pkgsStable = aarch64Pkgs.pkgsStable;
              deferredHomeManagerModules = deferredHmModules;
            };
          }
        ];
    };
  };
}
