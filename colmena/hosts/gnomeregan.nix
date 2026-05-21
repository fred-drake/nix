{
  self,
  nixpkgs-stable,
  nixpkgs-unstable,
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
  # Module set + packages come from nixpkgs-unstable via
  # colmena meta.nodeNixpkgs.gnomeregan (see colmena/default.nix).
  # Pin the etc/nixos/version.json source to match.
  nixpkgsVersion = import ../../lib/mk-nixpkgs-version.nix {nixpkgs-stable = nixpkgs-unstable;};
  mkHomeManager = import ../../lib/mk-home-manager.nix {
    inputs = {inherit sops-nix secrets nixvim nix-index-database;};
  };
  pkgsStable = import nixpkgs-stable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in {
  # Base configuration for Gnomeregan (local LAN NixOS host).
  _gnomeregan = {
    nixpkgs.config.allowUnfree = true;
    imports =
      [
        nixosOptionsModule
        secrets.nixosModules.soft-secrets
        secrets.nixosModules.secrets
        sops-nix.nixosModules.sops
        ../../modules/nixos/host/gnomeregan/configuration.nix
        nixpkgsVersion
        home-manager.nixosModules.home-manager
        {
          home-manager = mkHomeManager {
            hostName = "gnomeregan";
            inherit pkgsStable;
            deferredHomeManagerModules = deferredHmModules;
            imports = [
              ../../modules/home-manager/host/gnomeregan.nix
            ];
          };
        }
      ]
      ++ deferredNixosModules;
    my = {
      hostName = "gnomeregan";
      isServer = true;
    };
    deployment = {
      buildOnTarget = true;
      targetHost = "192.168.30.7";
      targetUser = "fdrake";
    };
  };

  # Initial setup configuration
  "gnomeregan-init" = {
    imports = [
      self.colmena._gnomeregan
    ];
  };

  # Full configuration
  "gnomeregan" = {
    imports = [
      self.colmena._gnomeregan
      ../../modules/services/glance-dashboard.nix
      ../../modules/services/borg-backup.nix
    ];
  };
}
