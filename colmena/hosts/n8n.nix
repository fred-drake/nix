{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" {home = null;};
in {
  # Base configuration for N8N
  _n8n = {
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
      ../../modules/nixos/host/n8n/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.n8n.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "n8n-init" = {
    imports = [
      self.colmena._n8n
    ];
  };

  # Full configuration
  "n8n" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._n8n
      ../../apps/n8n.nix
      (nodeExporter.mkNodeExporter "n8n")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
