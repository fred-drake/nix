{
  self,
  nixpkgs-stable,
  nixpkgs-unstable,
  secrets,
  sops-nix,
  nixosOptionsModule,
  deferredNixosModules,
  ...
}: let
  nixpkgsVersion = import ../../lib/mk-nixpkgs-version.nix {inherit nixpkgs-stable;};
in {
  # Base configuration for Undercity — dedicated public Matrix homeserver.
  # Functions like orgrimmar/ironforge from the server perspective (Hetzner
  # app-server base: podman + nginx + ACME), but its only service is Matrix.
  _undercity = {
    nixpkgs = {
      system = "x86_64-linux";
      # Phase 2 (MatrixRTC): stable 25.05 ships livekit 1.8.4 / lk-jwt-service
      # 0.3.0 — too old for current Element clients (the
      # MISSING_MATRIX_RTC_TRANSPORT skew). Pull just these two binaries from
      # nixpkgs-unstable (1.13.1 / 0.4.4) so the native services.livekit /
      # services.lk-jwt-service config stays on stable while the binaries stay
      # contemporary. Same trick as woodpecker-agent in overlays/default.nix.
      overlays = [
        (_final: prev: {
          inherit
            (nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system})
            livekit
            lk-jwt-service
            ;
        })
      ];
    };
    imports =
      [
        nixosOptionsModule
        secrets.nixosModules.soft-secrets
        secrets.nixosModules.secrets
        sops-nix.nixosModules.sops
        "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
        ../../modules/services/hetzner-server.nix
        ../../modules/nixos/host/undercity/configuration.nix
        nixpkgsVersion
      ]
      ++ deferredNixosModules;
    my = {
      hostName = "undercity";
      isServer = true;
      # Monitoring stays off until undercity is added to nix-secrets soft-secrets
      # (the node exporter binds soft-secrets.host.undercity.admin_ip_address).
      hasMonitoring = false;
    };
    deployment = {
      buildOnTarget = true;
      # TODO(terraform): confirm undercity's private/tailnet IP.
      targetHost = "10.1.1.6";
      targetPort = 2222;
      targetUser = "root";
    };
  };

  # Initial setup configuration (port 22 for the first deploy onto the fresh
  # NixOS box; the config then switches SSH to 2222).
  "undercity-init" = {
    imports = [
      self.colmena._undercity
    ];
    deployment.targetPort = nixpkgs-stable.lib.mkForce 22;
  };

  # Full configuration
  "undercity" = {
    imports = [
      self.colmena._undercity
      ../../modules/services/matrix-synapse.nix
      ../../modules/services/matrix-rtc.nix
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
