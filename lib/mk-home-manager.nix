# Build the home-manager attrset for a given host.
# Called by modules/hosts/nixos.nix and modules/hosts/darwin.nix.
{inputs}: let
  myOptionsModule = import ./my-options-module.nix;
in
  {
    hostName,
    imports ? [],
    deferredHomeManagerModules ? [],
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
      ++ imports
      ++ deferredHomeManagerModules;
    extraSpecialArgs = {
      inherit inputs;
    };
  }
