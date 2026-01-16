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
  _paperless = {
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
      ../../modules/nixos/host/paperless/configuration.nix
      nixpkgsVersion
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.paperless.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "paperless-init" = {
    imports = [
      self.colmena._paperless
    ];
  };

  # Full configuration
  "paperless" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._paperless
      ../../modules/secrets/paperless.nix
      ../../modules/nixos/host/paperless/paperless.nix
      (nodeExporter.mkNodeExporter "paperless")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
