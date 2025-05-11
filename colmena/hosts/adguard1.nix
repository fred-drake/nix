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
  # Base configuration for AdGuard1
  _adguard1 = {
    nixpkgs.system = "aarch64-linux";
    nixpkgs.overlays = [];
    nixpkgs.config = {};
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      nixos-hardware.nixosModules.raspberry-pi-4
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/adguard1/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.adguard1.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "adguard1-init" = {
    imports = [
      self.colmena._adguard1
    ];
  };

  # Full configuration
  "adguard1" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix { inherit secrets; };
  in {
    imports = [
      self.colmena._adguard1
      ../../apps/blocky.nix
      (nodeExporter.mkNodeExporter "adguard1")
    ];

    # Include the Prometheus modules with proper parameters
    _module.args = {
      inherit secrets;
    };
  };
}
