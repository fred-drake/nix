{
  inputs,
  config,
  ...
}: let
  nixosOptionsModule = import ../../lib/my-options-module.nix;
  deferredNixosModules = builtins.attrValues config.my.modules.nixos;
in {
  flake.colmena = import ../../colmena {
    inherit (inputs) self;
    inherit
      (inputs)
      nixpkgs-stable
      nixpkgs-unstable
      nixos-hardware
      secrets
      sops-nix
      nixarr
      nixos-wsl
      ;
    inherit nixosOptionsModule deferredNixosModules;
  };
}
