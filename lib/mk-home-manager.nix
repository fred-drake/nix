# Build the home-manager attrset for a given host.
# Called by modules/hosts/nixos.nix and modules/hosts/darwin.nix.
{inputs}: let
  myOptionsModule = import ./my-options-module.nix;
  inherit (inputs) sops-nix secrets nixvim nix-index-database;
in
  {
    hostName,
    username ? "fdrake",
    pkgsStable ? null,
    imports ? [],
    deferredHomeManagerModules ? [],
  }: {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.${username}.imports =
      [
        ../modules/home-manager
        sops-nix.homeManagerModules.sops
        secrets.nixosModules.soft-secrets
        secrets.nixosModules.secrets
        nixvim.homeModules.nixvim
        nix-index-database.homeModules.nix-index
        myOptionsModule
        {
          my.hostName = hostName;
        }
      ]
      ++ imports
      ++ deferredHomeManagerModules;
    extraSpecialArgs =
      {}
      // (
        if pkgsStable != null
        then {inherit pkgsStable;}
        else {}
      );
  }
