{
  self,
  nixpkgs-stable,
  secrets,
  sops-nix,
  nixarr,
  ...
}: let
  soft-secrets = import "${secrets}/soft-secrets" {home = null;};
  nixpkgsVersion = import ../../lib/mk-nixpkgs-version.nix {inherit nixpkgs-stable;};
in {
  # Base configuration for Ironforge
  _ironforge = {
    nixpkgs = {
      system = "x86_64-linux";
      overlays = [];
      config = {
        allowUnfreePredicate = pkg:
          builtins.elem (pkg.pname or "") [
            "unrar"
          ];
      };
    };
    networking.extraHosts = ''
      127.0.0.1 jellyfin.${soft-secrets.networking.domain}
      127.0.0.1 jellyseerr.${soft-secrets.networking.domain}
      127.0.0.1 sonarr.${soft-secrets.networking.domain}
      127.0.0.1 radarr.${soft-secrets.networking.domain}
      127.0.0.1 lidarr.${soft-secrets.networking.domain}
      127.0.0.1 prowlarr.${soft-secrets.networking.domain}
      127.0.0.1 sabnzbd.${soft-secrets.networking.domain}
      127.0.0.1 bazarr.${soft-secrets.networking.domain}
    '';
    imports = [
      secrets.nixosModules.soft-secrets
      secrets.nixosModules.secrets
      sops-nix.nixosModules.sops
      nixarr.nixosModules.default
      "${nixpkgs-stable}/nixos/modules/profiles/minimal.nix"
      ../hetzner-common
      ../../modules/nixos
      ../../modules/nixos/host/ironforge/configuration.nix
      nixpkgsVersion
    ];
    deployment = {
      buildOnTarget = true;
      targetHost = "10.1.1.3";
      targetPort = 2222;
      targetUser = "root";
    };
  };

  # Initial setup configuration
  "ironforge-init" = {
    imports = [
      self.colmena._ironforge
    ];
  };

  # Full configuration
  "ironforge" = let
    nodeExporter = import ../../lib/mk-prometheus-node-exporter.nix {inherit secrets;};
  in {
    imports = [
      self.colmena._ironforge
      ../../modules/secrets/ironforge.nix
      ../../modules/nixos/host/ironforge/nixarr.nix
      (nodeExporter.mkNodeExporter "ironforge")
    ];

    _module.args = {
      inherit secrets;
    };
  };
}
