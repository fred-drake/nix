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
  # Base configuration for Uptime Kuma
  _uptime-kuma = {
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
      ../../modules/nixos/host/uptime-kuma/configuration.nix
      nixpkgsVersion
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.uptime-kuma.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "uptime-kuma-init" = {
    imports = [
      self.colmena._uptime-kuma
    ];
  };

  # Full configuration
  "uptime-kuma" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._uptime-kuma
      ../../apps/uptime-kuma.nix
      (nodeExporter.mkNodeExporter "uptime-kuma")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
