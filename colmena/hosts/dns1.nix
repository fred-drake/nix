{
  self,
  nixpkgs-stable,
  nixos-hardware,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" { home = null; };
in {
  # Base configuration
  _dns1 = {
    nixpkgs = {
      system = "aarch64-linux";
      overlays = [];
      config = {};
    };
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      nixos-hardware.nixosModules.raspberry-pi-4
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/dns1/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.dns1.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "dns1-init" = {
    imports = [
      self.colmena._dns1
    ];
  };

  # Full configuration
  "dns1" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._dns1
      ../../apps/blocky.nix
      (nodeExporter.mkNodeExporter "dns1")
    ];

    # Include the Prometheus modules with proper parameters
    _module.args = {
      inherit secrets;
    };
  };
}
