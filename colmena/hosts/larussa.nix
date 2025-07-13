{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" { home = null; };
in {
  # Base configuration for Larussa
  _larussa = {
    nixpkgs.system = "x86_64-linux";
    nixpkgs.overlays = [];
    nixpkgs.config.allowUnfree = true;
    nixpkgs.config = {};
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/larussa/configuration.nix
      ../../modules/nixos/host/larussa/hardware-configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.larussa.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "larussa-init" = {
    imports = [
      self.colmena._larussa
    ];
  };

  # Full configuration
  "larussa" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._larussa
      ../../modules/nixos/host/larussa/disks.nix
      ../../modules/nixos/host/larussa/nfs-server.nix
      ../../modules/nixos/host/larussa/jellyfin.nix
      ../../modules/nixos/host/larussa/radarr.nix
      ../../modules/nixos/host/larussa/sonarr.nix
      (nodeExporter.mkNodeExporter "larussa")
    ];

    # Include the Prometheus modules with proper parameters
    _module.args = {
      inherit secrets;
    };
  };
}
