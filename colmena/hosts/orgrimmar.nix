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
  # Base configuration for Orgrimmar
  _orgrimmar = {
    nixpkgs = {
      system = "x86_64-linux";
      overlays = [];
    };
    networking.extraHosts = ''
      127.0.0.1 gitea.${soft-secrets.networking.domain}
    '';
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../hetzner-common
      ../../modules/nixos
      ../../modules/nixos/host/orgrimmar/configuration.nix
      nixpkgsVersion
    ];
    deployment = {
      buildOnTarget = true;
      targetHost = "10.1.1.4";
      targetPort = 2222;
      targetUser = "root";
    };
  };

  # Initial setup configuration (port 22 for first deploy, config switches to 2222)
  "orgrimmar-init" = {
    imports = [
      self.colmena._orgrimmar
    ];
    deployment.targetPort = nixpkgs-stable.lib.mkForce 22;
  };

  # Full configuration
  "orgrimmar" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._orgrimmar
      ../../modules/secrets/orgrimmar.nix
      ../../modules/nixos/host/orgrimmar/resume.nix
      ../../modules/nixos/host/orgrimmar/woodpecker.nix
      ../../modules/nixos/host/orgrimmar/gitea.nix
      ../../modules/nixos/host/orgrimmar/paperless.nix
      ../../modules/nixos/host/orgrimmar/calibre.nix
      (nodeExporter.mkNodeExporter "orgrimmar")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
