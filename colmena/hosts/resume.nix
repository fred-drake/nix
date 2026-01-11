{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" {home = null;};
in {
  _resume = {
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
      ../../modules/nixos/host/resume/configuration.nix
      ../../modules/secrets/cloudflare.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.resume.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "resume-init" = {
    imports = [
      self.colmena._resume
    ];
  };

  # Full configuration
  "resume" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._resume
      ../../modules/secrets/resume.nix
      ../../apps/resume.nix
      (nodeExporter.mkNodeExporter "resume")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
