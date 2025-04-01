{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";
in {
  # Base configuration for Radarr nodes
  _radarr = {
    nixpkgs.system = "x86_64-linux";
    nixpkgs.overlays = [];
    nixpkgs.config = {};
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/radarr/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.radarr.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "radarr-init" = self.colmena._radarr;

  # Full configuration with the app
  "radarr" = {
    imports = [
      self.colmena._radarr
      ../../apps/radarr.nix
    ];
  };
}
