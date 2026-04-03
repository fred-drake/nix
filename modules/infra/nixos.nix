# NixOS configuration infrastructure — replaces systems/nixos.nix.
# Each host is defined inline here; in Phase 4 they'll move to modules/hosts/.
{
  inputs,
  config,
  ...
}: let
  mkHomeManager = import ../../lib/mk-home-manager.nix {inherit inputs;};
  inherit (inputs) home-manager disko nixos-hardware secrets sops-nix;

  # Shared options module injected into every NixOS config.
  # Provides config.my.* for host metadata so deferred modules can self-guard.
  nixosOptionsModule = {lib, ...}: {
    options.my = {
      hostName = lib.mkOption {
        type = lib.types.str;
        description = "The hostname of the current system being configured.";
      };
      isWorkstation = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether this host is a full workstation.";
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "fdrake";
        description = "The primary user account name.";
      };
    };
  };

  # deferredModule fragments contributed by feature modules
  deferredNixosModules = builtins.attrValues config.my.modules.nixos;
  deferredHmModules = builtins.attrValues config.my.modules.home-manager;

  # Common NixOS modules included in every NixOS system configuration
  commonModules =
    [
      nixosOptionsModule
      secrets.nixosModules.soft-secrets
      sops-nix.nixosModules.sops
    ]
    ++ deferredNixosModules;
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
          {my.hostName = "macbookx86";}
          inputs.nur.nixosModules.nur
          ../../modules/nixos/host/macbookx86/configuration.nix
          nixos-hardware.nixosModules.apple-t2
          home-manager.nixosModules.home-manager
          {
            home-manager = mkHomeManager {
              hostName = "macbookx86";
              deferredHomeManagerModules = deferredHmModules;
              imports = [
                ../../modules/home-manager/features/linux-apps.nix
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
          {my.hostName = "fredpc";}
          secrets.nixosModules.secrets
          ../../modules/nixos
          ../../modules/nixos/host/fredpc/configuration.nix
          ../../modules/nixos/host/fredpc/hardware-configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = mkHomeManager {
              hostName = "fredpc";
              deferredHomeManagerModules = deferredHmModules;
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
          {my.hostName = "nixosaarch64vm";}
          disko.nixosModules.disko
          ../../modules/nixos
          ../../modules/nixos/host/nixosaarch64vm/configuration.nix
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
