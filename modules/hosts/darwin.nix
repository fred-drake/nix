# Darwin host definitions — one darwinSystem per host.
# Shared infrastructure (commonModules, mkDarwinSystem) is in lib/darwin-infra.nix.
{
  inputs,
  config,
  ...
}: let
  root = ../..;
  infra = import ../../lib/darwin-infra.nix {inherit inputs config root;};
  mkHomeManager = import ../../lib/mk-home-manager.nix {inherit inputs;};
  darwinPkgs = import ../../lib/mkPkgs.nix {
    inherit inputs;
    system = "aarch64-darwin";
  };
  inherit (infra) mkDarwinSystem deferredHmModules;
in {
  flake.darwinConfigurations = {
    macbook-pro = mkDarwinSystem {
      hostname = "macbook-pro";
      extraModules = [
        {
          home-manager = mkHomeManager {
            hostName = "macbook-pro";
            inherit (darwinPkgs) pkgsStable;
            deferredHomeManagerModules = deferredHmModules;
            imports = [
              (root + "/modules/home-manager/host/macbook-pro.nix")
            ];
          };
          ids.gids.nixbld = 350;
        }
      ];
    };

    laisas-mac-mini = mkDarwinSystem {
      hostname = "laisas-mac-mini";
      isWorkstation = false;
      extraModules = [
        {
          home-manager = mkHomeManager {
            hostName = "laisas-mac-mini";
            inherit (darwinPkgs) pkgsStable;
            deferredHomeManagerModules = deferredHmModules;
            imports = [];
          };
        }
      ];
    };
  };
}
