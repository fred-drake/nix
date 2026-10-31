{
  self,
  nixpkgs-stable,
  nixpkgs-unstable,
  nixos-wsl,
  secrets,
  sops-nix,
  home-manager,
  nixvim,
  nix-index-database,
  nixosOptionsModule,
  deferredNixosModules,
  deferredHmModules,
  ...
}: let
  nixpkgsVersion = import ../../lib/mk-nixpkgs-version.nix {nixpkgs-stable = nixpkgs-unstable;};
  mkHomeManager = import ../../lib/mk-home-manager.nix {
    inputs = {inherit sops-nix secrets nixvim nix-index-database;};
  };
  pkgsStable = import nixpkgs-stable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in {
  # Base configuration for Anton (WSL)
  _anton = {
    # Module set + packages come from nixpkgs-unstable via colmena
    # meta.nodeNixpkgs.anton (see colmena/default.nix), so home-manager and
    # CUDA packages resolve correctly. Using only nixpkgs.pkgs = unstable
    # with the stable module set caused a systemd unit skew: stable getty.nix
    # expects example/systemd/system/autovt@.service, which unstable systemd
    # 260.1 dropped (it moved to a getty@ alias).
    nixpkgs.config.allowUnfree = true;
    documentation.nixos.enable = false;
    imports =
      [
        nixosOptionsModule
        nixos-wsl.nixosModules.default
        secrets.nixosModules.soft-secrets
        secrets.nixosModules.secrets
        sops-nix.nixosModules.sops
        ../../modules/services/wsl-server.nix
        ../../modules/nixos/host/anton/configuration.nix
        nixpkgsVersion
        home-manager.nixosModules.home-manager
        {
          home-manager = mkHomeManager {
            hostName = "anton";
            username = "nixos";
            inherit pkgsStable;
            deferredHomeManagerModules = deferredHmModules;
          };
        }
      ]
      ++ deferredNixosModules;
    my = {
      hostName = "anton";
      isServer = true;
    };
    deployment = {
      buildOnTarget = true;
      targetHost = "anton";
      targetUser = "nixos";
    };
  };

  # Initial setup configuration
  "anton-init" = {
    imports = [
      self.colmena._anton
    ];
  };

  # Full configuration
  "anton" = {
    imports = [
      self.colmena._anton
    ];
  };
}
