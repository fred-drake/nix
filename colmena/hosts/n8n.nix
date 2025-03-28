{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";
in {
  # Base configuration for N8N
  _n8n = {
    nixpkgs.system = "x86_64-linux";
    nixpkgs.overlays = [];
    nixpkgs.config = {};
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos/n8n/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.n8n.admin_ip_address;
      targetUser = "default";
    };
  };

  # Initial setup configuration
  "n8n-init" = {
    imports = [
      self.colmena._n8n
    ];
  };

  # Full configuration
  "n8n" = {
    imports = [
      self.colmena._n8n
      ../../apps/n8n.nix
    ];
  };
}
