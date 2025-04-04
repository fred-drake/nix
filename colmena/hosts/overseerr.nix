{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";
in {
  # Base configuration for Overseerr
  _overseerr = {
    nixpkgs.system = "x86_64-linux";
    nixpkgs.overlays = [];
    nixpkgs.config = {};
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/overseerr/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.overseerr.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "overseerr-init" = {
    imports = [
      self.colmena._overseerr
    ];
  };

  # Full configuration
  "overseerr" = {
    imports = [
      self.colmena._overseerr
      ../../apps/overseerr.nix
    ];
  };
}
