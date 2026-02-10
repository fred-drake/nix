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
  # Base configuration for Headscale
  _headscale = {
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
      ../../modules/nixos/host/headscale/configuration.nix
      nixpkgsVersion
    ];
    deployment = {
      buildOnTarget = true;
      targetHost = "157.180.42.128";
      targetUser = "root";
    };
  };

  # Initial setup configuration
  "headscale-init" = {
    imports = [
      self.colmena._headscale
    ];
  };

  # Full configuration
  "headscale" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._headscale
      ../../modules/nixos/host/headscale/headscale.nix
      ../../modules/nixos/host/headscale/tailscale-client.nix
      (nodeExporter.mkNodeExporter "headscale")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
