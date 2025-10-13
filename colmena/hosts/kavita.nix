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
  _kavita = {
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
      ../../modules/nixos/host/kavita/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.kavita.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "kavita-init" = {
    imports = [
      self.colmena._kavita
    ];
  };

  # Full configuration
  "kavita" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._kavita
      ../../modules/nixos/host/kavita/kavita.nix
      (nodeExporter.mkNodeExporter "kavita")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
