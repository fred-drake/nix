{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" {home = null;};
in {
  # Base configuration for Prowlarr nodes
  _prowlarr = {
    nixpkgs = {
      system = "x86_64-linux";
      overlays = [];
      config = {};
    };
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
  "prowlarr" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._prowlarr
      ../../apps/prowlarr.nix
      (nodeExporter.mkNodeExporter "prowlarr")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
