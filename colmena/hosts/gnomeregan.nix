{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  nixosOptionsModule,
  deferredNixosModules,
  ...
}: let
  nixpkgsVersion = import ../../lib/mk-nixpkgs-version.nix {inherit nixpkgs-stable;};
in {
  # Base configuration for Gnomeregan (local LAN NixOS host).
  _gnomeregan = {
    nixpkgs = {
      system = "x86_64-linux";
      overlays = [];
      config = {};
    };
    imports =
      [
        nixosOptionsModule
        secrets.nixosModules.soft-secrets
        secrets.nixosModules.secrets
        sops-nix.nixosModules.sops
        ../../modules/nixos/host/gnomeregan/configuration.nix
        nixpkgsVersion
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
    ];
  };
}
