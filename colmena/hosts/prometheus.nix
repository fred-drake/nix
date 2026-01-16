{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" {home = null;};
  nixpkgsVersion = import ../../lib/mk-nixpkgs-version.nix {inherit nixpkgs-stable;};
in {
  # Base configuration for Prometheus
  _prometheus = {
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
      ../../modules/nixos/host/prometheus/configuration.nix
      nixpkgsVersion
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.prometheus.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "prometheus-init" = {
    imports = [
      self.colmena._prometheus
    ];
  };

  # Full configuration
  "prometheus" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._prometheus
      ../../apps/prometheus.nix
      (nodeExporter.mkNodeExporter "prometheus")
    ];

    # Include the Prometheus modules with proper parameters
    _module.args = {
      inherit secrets;
    };
  };
}
