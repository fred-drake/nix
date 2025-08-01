{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" {home = null;};
in {
  # Base configuration for Gitea Runner
  _gitea-runner-1 = {
    nixpkgs = {
      system = "x86_64-linux";
      overlays = [];
      config = {};
    };

    networking.extraHosts = ''
      192.168.50.26 dev.brainrush.ai
      ${soft-secrets.host.gitea.service_ip_address} gitea.${soft-secrets.networking.domain}
      ${soft-secrets.host.sonarqube.service_ip_address} sonarqube.${soft-secrets.networking.domain}
    '';

    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/gitea-runner-1/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.gitea-runner-1.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "gitea-runner-1-init" = {
    imports = [
      self.colmena._gitea-runner-1
    ];
  };

  # Full configuration
  "gitea-runner-1" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._gitea-runner-1
      (import ../../apps/gitea-runner "gitea-runner-1")
      (nodeExporter.mkNodeExporter "gitea-runner-1")
    ];

    # Include the Prometheus modules with proper parameters
    _module.args = {
      inherit secrets;
    };
  };
}
