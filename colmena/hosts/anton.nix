{
  self,
  nixpkgs-unstable,
  nixos-wsl,
  secrets,
  sops-nix,
  nixosOptionsModule,
  deferredNixosModules,
  ...
}: let
  nixpkgsVersion = import ../../lib/mk-nixpkgs-version.nix {nixpkgs-stable = nixpkgs-unstable;};
in {
  # Base configuration for Anton (WSL)
  _anton = {
    nixpkgs = {
      system = "x86_64-linux";
      overlays = [];
      config = {
        allowUnfree = true;
        cudaSupport = true;
      };
    };
    imports =
      [
        nixosOptionsModule
        nixos-wsl.nixosModules.default
        secrets.nixosModules.soft-secrets
        secrets.nixosModules.secrets
        sops-nix.nixosModules.sops
        ../../modules/services/wsl-server.nix
        ../../modules/nixos
        ../../modules/nixos/host/anton/configuration.nix
        nixpkgsVersion
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
