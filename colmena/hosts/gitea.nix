{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets";
in {
  # Base configuration for Gitea
  _gitea = {
    nixpkgs.system = "x86_64-linux";
    nixpkgs.overlays = [];
    nixpkgs.config = {};
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../../modules/nixos
      ../../modules/nixos/host/gitea/configuration.nix
    ];
    deployment = {
      buildOnTarget = false;
      targetHost = soft-secrets.host.gitea.admin_ip_address;
      targetUser = "default";
      targetPort = 2222;
    };
  };

  # Initial setup configuration
  "gitea-init" = {
    imports = [
      self.colmena._gitea
    ];
  };

  # Full configuration
  "gitea" = {
    imports = [
      self.colmena._gitea
      ../../apps/gitea.nix
      ../../apps/prometheus-client/gitea.nix
    ];

    # Include the Prometheus modules with proper parameters
    _module.args = {
      inherit secrets;
    };
  };
}
