{
  self,
  nixpkgs-stable,
  nixos-hardware,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";
in {
  # Base configuration
  _arm64builder = {
    nixpkgs = {
      system = "aarch64-linux";
      overlays = [];
      config = {};
    };

    networking.extraHosts = ''
      192.168.50.26 dev.brainrush.ai
      ${soft-secrets.host.gitea.service_ip_address} gitea.${soft-secrets.networking.domain}
    '';

    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      nixos-hardware.nixosModules.raspberry-pi-4
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/arm64builder/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.arm64builder.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "arm64builder-init" = {
    imports = [
      self.colmena._arm64builder
    ];
  };

  # Full configuration
  "arm64builder" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._arm64builder
      (nodeExporter.mkNodeExporter "arm64builder")
    ];

    # Include the Prometheus modules with proper parameters
    _module.args = {
      inherit secrets;
    };
  };
}
