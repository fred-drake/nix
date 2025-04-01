{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";
in {
  # Base configuration for Prowlarr nodes
  _prowlarr = {
    nixpkgs.system = "x86_64-linux";
    nixpkgs.overlays = [];
    nixpkgs.config = {};
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/prowlarr/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.prowlarr.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "prowlarr-init" = self.colmena._prowlarr;

  # Full configuration with the app
  "prowlarr" = {
    imports = [
      self.colmena._prowlarr
      ../../apps/prowlarr.nix
    ];
  };
}
