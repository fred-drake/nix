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
  _woodpecker = {
    nixpkgs = {
      system = "x86_64-linux";
      overlays = [];
      config = {};
    };

    networking.extraHosts = ''
      ${soft-secrets.host.gitea.service_ip_address} gitea.${soft-secrets.networking.domain}
    '';

    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/woodpecker/configuration.nix
      ../../modules/secrets/cloudflare.nix
      nixpkgsVersion
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.woodpecker.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "woodpecker-init" = {
    imports = [
      self.colmena._woodpecker
    ];
  };

  # Full configuration
  "woodpecker" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._woodpecker
      ../../modules/secrets/woodpecker.nix
      ../../apps/woodpecker.nix
      (nodeExporter.mkNodeExporter "woodpecker")
    ];

    # Include the Prometheus modules with proper parameters
    _module.args = {
      inherit secrets;
    };
  };
}
