# Shared NixOS infrastructure — imported by both modules/infra/nixos.nix
# and modules/hosts/*.nix (NixOS hosts).
{
  inputs,
  config,
}: let
  inherit (inputs) secrets sops-nix;

  # Shared options module injected into every NixOS config.
  # Provides config.my.* for host metadata so deferred modules can self-guard.
  nixosOptionsModule = {lib, ...}: {
    options.my = {
      hostName = lib.mkOption {
        type = lib.types.str;
        description = "The hostname of the current system being configured.";
      };
      isWorkstation = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether this host is a full workstation.";
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "fdrake";
        description = "The primary user account name.";
      };
    };
  };

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
