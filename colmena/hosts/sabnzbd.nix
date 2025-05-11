{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";
in {
  # Base configuration for Sabnzbd nodes
  _sabnzbd = {
    nixpkgs.system = "x86_64-linux";
    nixpkgs.overlays = [];
    nixpkgs.config.allowUnfree = true;
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/sabnzbd/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.sabnzbd.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "sabnzbd-init" = self.colmena._sabnzbd;

  # Full configuration with the app
  "sabnzbd" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._sabnzbd
      ../../apps/sabnzbd.nix
      (nodeExporter.mkNodeExporter "sabnzbd")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
