# NixOS configuration infrastructure — replaces systems/nixos.nix.
# Each host is defined inline here; in Phase 4 they'll move to modules/hosts/.
{inputs, ...}: let
  mkHomeManager = import ../../lib/mk-home-manager.nix {inherit inputs;};
  inherit (inputs) home-manager disko nixos-hardware secrets sops-nix;

  # Common NixOS modules included in every NixOS system configuration
  commonModules = [
    secrets.nixosModules.soft-secrets
    sops-nix.nixosModules.sops
  ];
in {
  flake.nixosConfigurations = {
    macbookx86 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [import ../../overlays/default.nix {inherit inputs;}];
      };
      specialArgs = {
        inherit inputs;
        outputs = inputs.self;
        nixpkgs = inputs.nixpkgs;
      };
      modules =
        commonModules
        ++ [
          inputs.nur.nixosModules.nur
          ../../modules/nixos/host/macbookx86/configuration.nix
          nixos-hardware.nixosModules.apple-t2
          home-manager.nixosModules.home-manager
          {
            home-manager = mkHomeManager {
              hostName = "macbookx86";
              imports = [
                ../../modules/home-manager/linux-desktop.nix
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
          (import ../../overlays/default.nix {inherit inputs;})
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
        outputs = inputs.self;
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
          secrets.nixosModules.secrets
          ../../modules/nixos
          ../../modules/nixos/host/fredpc/configuration.nix
          ../../modules/nixos/host/fredpc/hardware-configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = mkHomeManager {
              hostName = "fredpc";
              imports = [
                ../../modules/home-manager/host/fredpc.nix
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
        outputs = inputs.self;
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
          disko.nixosModules.disko
          ../../modules/nixos
          ../../modules/nixos/host/nixosaarch64vm/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = mkHomeManager {
              hostName = "nixosaarch64vm";
            };
          }
        ];
    };
  };
}
