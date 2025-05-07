{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";
in {
  # Base configuration for Uptime Kuma
  _uptime-kuma = {
    nixpkgs.system = "x86_64-linux";
    nixpkgs.overlays = [];
    nixpkgs.config = {};
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/uptime-kuma/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.uptime-kuma.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "uptime-kuma-init" = {
    imports = [
      self.colmena._uptime-kuma
    ];
  };

  # Full configuration
  "uptime-kuma" = {
    imports = [
      self.colmena._uptime-kuma
      ../../apps/uptime-kuma.nix
    ];
  };
}
