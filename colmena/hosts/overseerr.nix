{
  self,
  nixpkgs-stable,
  nixpkgs-unstable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";
  system = "x86_64-linux";
  pkgs = import nixpkgs-unstable {
    inherit system;
    config = {};
  };
in {
  # Base configuration for Overseerr
  _overseerr = {
    nixpkgs.system = system;
    nixpkgs.overlays = [];
    nixpkgs.config = {};
    nixpkgs.pkgs = pkgs;
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-unstable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/overseerr/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.overseerr.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "overseerr-init" = {
    imports = [
      self.colmena._overseerr
    ];
  };

  # Full configuration
  "overseerr" = {
    imports = [
      self.colmena._overseerr
      ../../apps/overseerr.nix
    ];
  };
}
