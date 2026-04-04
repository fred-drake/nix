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
in {
  flake.nixosConfigurations = {
    macbookx86 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [import (root + "/overlays/default.nix") {inherit inputs;}];
      };
      specialArgs = {
        inherit inputs;

        nixpkgs = inputs.nixpkgs;
      };
      modules =
        commonModules
        ++ [
          {
            my.hostName = "macbookx86";
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
              deferredHomeManagerModules = deferredHmModules;
              imports = [
                (root + "/modules/home-manager/features/linux-apps.nix")
              ];
            };
          }
        ];
    };

    fredpc = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [
          (import (root + "/overlays/default.nix") {inherit inputs;})
          inputs.nix4vscode.overlays.forVscode
          (_: _prev: {
            inherit
              ((import inputs.nixpkgs-unstable {
                system = "x86_64-linux";
                config.allowUnfree = true;
              }))
              devenv
              ;
          })
        ];
      };
      specialArgs = {
        inherit inputs;

        nixpkgs = inputs.nixpkgs;
        nixpkgs-unstable = inputs.nixpkgs-unstable;
        nix4vscode = inputs.nix4vscode;
        pkgsCuda = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          config.cudaSupport = true;
        };
        pkgsUnstable = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        pkgsStable = import inputs.nixpkgs-stable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
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
      pkgs = import inputs.nixpkgs {
        system = "aarch64-linux";
        config.allowUnfree = true;
        overlays = [
          inputs.nix4vscode.overlays.forVscode
        ];
      };
      specialArgs = {
        inherit inputs;

        nixpkgs = inputs.nixpkgs;
        nixpkgs-unstable = inputs.nixpkgs-unstable;
        nix4vscode = inputs.nix4vscode;
        secrets = inputs.secrets;
        # Note: nixosaarch64vm uses x86_64-linux pkgs for unstable/stable
        # with cudaSupport — preserving existing behavior (see plan N6/R6)
        pkgsUnstable = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
          config.cudaSupport = true;
        };
        pkgsStable = import inputs.nixpkgs-stable {
          system = "x86_64-linux";
          config.allowUnfree = true;
          config.cudaSupport = true;
        };
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
              deferredHomeManagerModules = deferredHmModules;
            };
          }
        ];
    };
  };
}
