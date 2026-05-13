{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  nixosOptionsModule,
  deferredNixosModules,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" {home = null;};
  nixpkgsVersion = import ../../lib/mk-nixpkgs-version.nix {inherit nixpkgs-stable;};
in {
  # Base configuration for Stormwind
  _stormwind = {
    nixpkgs = {
      system = "x86_64-linux";
      overlays = [];
    };
    # Resolve gitea internally so podman can pull traceway from gitea's container registry.
    networking.extraHosts = ''
      10.1.1.4 gitea.${soft-secrets.networking.domain}
    '';
    imports =
      [
        nixosOptionsModule
        secrets.nixosModules.soft-secrets
        secrets.nixosModules.secrets
        sops-nix.nixosModules.sops
        "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
        ../../modules/services/hetzner-server.nix
        ../../modules/nixos/host/stormwind/configuration.nix
        nixpkgsVersion
      ]
      ++ deferredNixosModules;
    my = {
      hostName = "stormwind";
      isServer = true;
      hasMonitoring = true;
    };
    deployment = {
      buildOnTarget = true;
      targetHost = "10.1.1.5";
      targetPort = 2222;
      targetUser = "root";
    };
  };

  # Initial setup configuration (port 22 for first deploy, config switches to 2222)
  "stormwind-init" = {
    imports = [
      self.colmena._stormwind
    ];
    deployment.targetPort = nixpkgs-stable.lib.mkForce 22;
  };

  # Full configuration
  "stormwind" = {
    imports = [
      self.colmena._stormwind
      ../../modules/services/traceway.nix
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
