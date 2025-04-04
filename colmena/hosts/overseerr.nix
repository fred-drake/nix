{
  self,
  nixpkgs-stable,
  nixpkgs-unstable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";
  system = "x86_64-linux";

  # Create an overlay that prefers unstable packages
  unstableOverlay = final: prev: {
    inherit (import nixpkgs-unstable {inherit system;}) jellyseerr nginx;
  };
in {
  # Base configuration for Overseerr
  _overseerr = {
    nixpkgs.system = system;
    nixpkgs.overlays = [unstableOverlay];
    nixpkgs.config.allowUnfree = true;
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/overseerr/configuration.nix
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
