{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" { home = null; };
in {
  # Base configuration for Grafana
  _grafana = {
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
      ../../modules/nixos/host/grafana/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.grafana.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "grafana-init" = {
    imports = [
      self.colmena._grafana
    ];
  };

  # Full configuration
  "grafana" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix { inherit secrets; };
  in {
    imports = [
      self.colmena._grafana
      ../../apps/grafana.nix
      (nodeExporter.mkNodeExporter "grafana")
    ];

    # Include the Grafana modules with proper parameters
    _module.args = {
      inherit secrets;
    };
  };
}
