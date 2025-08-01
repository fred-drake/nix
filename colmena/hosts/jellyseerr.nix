{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" {home = null;};
in {
  # Base configuration
  _jellyseerr = {
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
      ../../modules/nixos/host/jellyseerr/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.jellyseerr.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "jellyseerr-init" = {
    imports = [
      self.colmena._jellyseerr
    ];
  };

  # Full configuration
  "jellyseerr" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._jellyseerr
      ../../apps/jellyseerr.nix
      (nodeExporter.mkNodeExporter "jellyseerr")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
