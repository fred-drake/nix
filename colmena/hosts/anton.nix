{
  self,
  nixpkgs-stable,
  nixpkgs-unstable,
  nixos-wsl,
  secrets,
  sops-nix,
  home-manager,
  nixvim,
  nix-index-database,
  nixosOptionsModule,
  deferredNixosModules,
  deferredHmModules,
  ...
}: let
  inherit (import nixpkgs-unstable {system = "x86_64-linux";}) lib;
  nixpkgsVersion = import ../../lib/mk-nixpkgs-version.nix {nixpkgs-stable = nixpkgs-unstable;};
  mkHomeManager = import ../../lib/mk-home-manager.nix {
    inputs = {inherit sops-nix secrets nixvim nix-index-database;};
  };
  pkgsStable = import nixpkgs-stable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in {
  # Base configuration for Anton (WSL)
  _anton = {
    # Use nixpkgs-unstable directly (not meta.nixpkgs which is nixpkgs-stable)
    # so that home-manager and CUDA packages resolve correctly.
    nixpkgs.pkgs = import nixpkgs-unstable {
      system = "x86_64-linux";
      config = {
        allowUnfree = true;
      };
    };
    nixpkgs.config = lib.mkForce {};
    documentation.nixos.enable = false;
    imports =
      [
        nixosOptionsModule
        nixos-wsl.nixosModules.default
        secrets.nixosModules.soft-secrets
        secrets.nixosModules.secrets
        sops-nix.nixosModules.sops
        ../../modules/services/wsl-server.nix
        ../../modules/nixos/host/anton/configuration.nix
        nixpkgsVersion
        home-manager.nixosModules.home-manager
        {
          home-manager = mkHomeManager {
            hostName = "anton";
            username = "nixos";
            inherit pkgsStable;
            deferredHomeManagerModules = deferredHmModules;
          };
        }
      ]
      ++ deferredNixosModules;
    my = {
      hostName = "anton";
      isServer = true;
    };
    deployment = {
      buildOnTarget = true;
      targetHost = "anton";
      targetUser = "nixos";
    };
  };

  # Initial setup configuration
  "anton-init" = {
    imports = [
      self.colmena._anton
    ];
  };

  # Full configuration
  "anton" = {
    imports = [
      self.colmena._anton
    ];
  };
}
