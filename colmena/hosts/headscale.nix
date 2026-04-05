{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  nixosOptionsModule,
  deferredNixosModules,
  ...
}: let
  nixpkgsVersion = import ../../lib/mk-nixpkgs-version.nix {inherit nixpkgs-stable;};
in {
  # Base configuration for Headscale
  _headscale = {
    nixpkgs = {
      system = "x86_64-linux";
      overlays = [];
      config = {};
    };
    imports =
      [
        nixosOptionsModule
        secrets.nixosModules.soft-secrets
        secrets.nixosModules.secrets
        sops-nix.nixosModules.sops
        "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
        ../../modules/services/hetzner-server.nix
        ../../modules/nixos/host/headscale/configuration.nix
        nixpkgsVersion
      ]
      ++ deferredNixosModules;
    my = {
      hostName = "headscale";
      isServer = true;
      hasMonitoring = true;
    };
    deployment = {
      buildOnTarget = true;
      targetHost = "157.180.42.128";
      targetUser = "root";
    };
  };

  # Initial setup configuration
  "headscale-init" = {
    imports = [
      self.colmena._headscale
    ];
  };

  # Full configuration
  "headscale" = {
    imports = [
      self.colmena._headscale
      ../../modules/services/headscale-vpn.nix
      ../../modules/services/tailscale-client.nix
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
