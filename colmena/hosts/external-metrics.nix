{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" {home = null;};
in {
  # Base configuration for external metrics
  _external-metrics = {
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
      ../../modules/nixos/host/external-metrics/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.external-metrics.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "external-metrics-init" = {
    imports = [
      self.colmena._external-metrics
    ];
  };

  # Full configuration
  "external-metrics" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._external-metrics
      ../../modules/nixos/host/external-metrics/metric-containers.nix
      (nodeExporter.mkNodeExporter "external-metrics")
    ];

    _module.args = {
      inherit secrets soft-secrets;
    };
  };
}
