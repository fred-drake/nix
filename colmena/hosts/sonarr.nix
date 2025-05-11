{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";
in {
  # Base configuration for Sonarr nodes
  _sonarr = {
    nixpkgs.system = "x86_64-linux";
    nixpkgs.overlays = [];
    nixpkgs.config = {};
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/sonarr/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.sonarr.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "sonarr-init" = self.colmena._sonarr;

  # Full configuration with the app
  "sonarr" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._sonarr
      ../../apps/sonarr.nix
      (nodeExporter.mkNodeExporter "sonarr")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
