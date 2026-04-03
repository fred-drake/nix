# Build the home-manager attrset for a given host.
# Called by modules/infra/nixos.nix and modules/infra/darwin.nix.
{inputs}: let
  # Shared options module injected into every HM config.
  # Provides config.my.* for host metadata (replaces hostArgs/specialArgs).
  myOptionsModule = {lib, ...}: {
    options.my = {
      hostName = lib.mkOption {
        type = lib.types.str;
        description = "The hostname of the current system being configured.";
      };
      isWorkstation = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether this host is a workstation (controls cask/app installation).";
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "fdrake";
        description = "The primary user account name.";
      };
    };
  };
in
  {
    hostName,
    imports ? [],
  }: {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.fdrake.imports =
      [
        ../modules/home-manager
        inputs.sops-nix.homeManagerModules.sops
        inputs.secrets.nixosModules.soft-secrets
        inputs.secrets.nixosModules.secrets
        inputs.nixvim.homeModules.nixvim
        inputs.nix-index-database.homeModules.nix-index
        myOptionsModule
        {
          my.hostName = hostName;
        }
      ]
      ++ imports;
    # Kept for backwards compatibility — downstream HM modules still reference
    # these. Will be removed when features are migrated in Phase 2.
    extraSpecialArgs = {
      inherit inputs;
      secrets = inputs.secrets;
      hostArgs = {inherit hostName;};
    };
  }
