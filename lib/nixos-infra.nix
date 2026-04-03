# Shared NixOS infrastructure — imported by modules/hosts/nixos.nix.
{
  inputs,
  config,
}: let
  inherit (inputs) secrets sops-nix;

  nixosOptionsModule = import ./my-options-module.nix;

  # deferredModule fragments contributed by feature modules
  deferredNixosModules = builtins.attrValues config.my.modules.nixos;
  deferredHmModules = builtins.attrValues config.my.modules.home-manager;

  # Common NixOS modules included in every NixOS system configuration
  commonModules =
    [
      nixosOptionsModule
      secrets.nixosModules.soft-secrets
      sops-nix.nixosModules.sops
    ]
    ++ deferredNixosModules;
in {
  inherit commonModules deferredHmModules;
}
