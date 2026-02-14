{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" {home = null;};
  nixpkgsVersion = import ../../lib/mk-nixpkgs-version.nix {inherit nixpkgs-stable;};
in {
  _scanner = {
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
      ../../modules/nixos/host/scanner/configuration.nix
      nixpkgsVersion
    ];
    deployment = {
      buildOnTarget = true;
      targetHost = soft-secrets.host.scanner.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "scanner-init" = {
    imports = [
      self.colmena._scanner
    ];
  };

  # Full configuration
  "scanner" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._scanner
      ../../modules/secrets/scanner.nix
      ../../modules/nixos/host/scanner/scanner.nix
      (nodeExporter.mkNodeExporter "scanner")
    ];

    # Include the Prometheus modules with proper parameters
    _module.args = {
      inherit secrets;
    };
  };
}
