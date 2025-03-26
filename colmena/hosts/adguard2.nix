{
  self,
  nixpkgs-stable,
  nixos-hardware,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";
in {
  # Base configuration for AdGuard2
  _adguard2 = {
    nixpkgs.system = "aarch64-linux";
    nixpkgs.overlays = [];
    nixpkgs.config = {};
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      nixos-hardware.nixosModules.raspberry-pi-4
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos/adguard2/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.adguard2.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "adguard2-init" = {
    imports = [
      self.colmena._adguard2
    ];
  };

  # Full configuration
  "adguard2" = {
    imports = [
      self.colmena._adguard2
      ../../apps/adguard.nix
    ];
  };
}
