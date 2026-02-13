{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  nixpkgsVersion = import ../../lib/mk-nixpkgs-version.nix {inherit nixpkgs-stable;};
in {
  # Base configuration for Ironforge
  _ironforge = {
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
      ../hetzner-common
      ../../modules/nixos
      ../../modules/nixos/host/ironforge/configuration.nix
      nixpkgsVersion
    ];
    deployment = {
      buildOnTarget = true;
      targetHost = "10.1.1.3";
      targetUser = "root";
    };
  };

  # Initial setup configuration
  "ironforge-init" = {
    imports = [
      self.colmena._ironforge
    ];
  };

  # Full configuration
  "ironforge" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._ironforge
      ../../modules/secrets/ironforge.nix
      ../../modules/nixos/host/ironforge/resume.nix
      (nodeExporter.mkNodeExporter "ironforge")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
