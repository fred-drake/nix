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
  # Base configuration for Orgrimmar
  _orgrimmar = {
    nixpkgs = {
      system = "x86_64-linux";
      overlays = [];
    };
    # Host's /etc/hosts is used by native `podman run`, but podman's Docker-compat
    # API (used by Woodpecker's docker backend) generates a minimal hosts file
    # that excludes these entries. Run dnsmasq as the host resolver so aardvark-dns
    # forwards container queries here and every container — however it was created —
    # resolves the internal gitea hostname.
    networking.extraHosts = ''
      10.1.1.4 gitea.${soft-secrets.networking.domain}
    '';
    services.dnsmasq = {
      enable = true;
      resolveLocalQueries = true;
      settings = {
        server = ["8.8.8.8" "1.1.1.1"];
        # aardvark-dns already binds :53 on every podman bridge gateway, so
        # restrict dnsmasq to the loopback interface and skip other interfaces.
        listen-address = ["127.0.0.1"];
        bind-interfaces = true;
        cache-size = 1000;
      };
    };
    imports =
      [
        nixosOptionsModule
        secrets.nixosModules.soft-secrets
        secrets.nixosModules.secrets
        sops-nix.nixosModules.sops
        "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
        ../../modules/services/hetzner-server.nix
        ../../modules/nixos/host/orgrimmar/configuration.nix
        nixpkgsVersion
      ]
      ++ deferredNixosModules;
    my = {
      hostName = "orgrimmar";
      isServer = true;
      hasMonitoring = true;
    };
    deployment = {
      buildOnTarget = true;
      targetHost = "10.1.1.4";
      targetPort = 2222;
      targetUser = "root";
    };
  };

  # Initial setup configuration (port 22 for first deploy, config switches to 2222)
  "orgrimmar-init" = {
    imports = [
      self.colmena._orgrimmar
    ];
    deployment.targetPort = nixpkgs-stable.lib.mkForce 22;
  };

  # Full configuration
  "orgrimmar" = {
    imports = [
      self.colmena._orgrimmar
      ../../modules/services/resume.nix
      ../../modules/services/woodpecker-ci.nix
      ../../modules/services/gitea.nix
      ../../modules/services/paperless.nix
      ../../modules/services/calibre.nix
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
