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
  _minio = {
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
      ../../modules/nixos/host/minio/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.minio.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "minio-init" = {
    imports = [
      self.colmena._minio
    ];
  };

  # Full configuration
  "minio" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._minio
      ../../modules/nixos/host/minio/minio.nix
      (nodeExporter.mkNodeExporter "minio")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
