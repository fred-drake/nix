{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" {home = null;};
in {
  # Base configuration for SonarQube
  _sonarqube = {
    nixpkgs.system = "x86_64-linux";
    nixpkgs.overlays = [];
    nixpkgs.config = {};
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/sonarqube/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.sonarqube.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "sonarqube-init" = {
    imports = [
      self.colmena._sonarqube
    ];
  };

  # Full configuration
  "sonarqube" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._sonarqube
      ../../modules/secrets/sonarqube.nix
      ../../apps/sonarqube.nix
      (nodeExporter.mkNodeExporter "sonarqube")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
