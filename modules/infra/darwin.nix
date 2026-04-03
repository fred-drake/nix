# Darwin configuration infrastructure — replaces systems/darwin.nix.
# Each host is defined inline here; in Phase 4 they'll move to modules/hosts/.
{inputs, ...}: let
  mkHomeManager = import ../../lib/mk-home-manager.nix {inherit inputs;};
  inherit (inputs) darwin home-manager nix-homebrew secrets sops-nix;

  # Some casks take space on a limited Mac Mini, so only install them
  # on Mac Studio and MacBook Pro.
  non-mac-mini-casks = [
    "godot"
    "steam"
    "wine-stable"
    "winbox"
  ];

  # Homebrew tap wiring — shared across all Darwin hosts
  homebrewModule = {
    nix-homebrew = {
      enable = true;
      enableRosetta = true;
      user = "fdrake";
      taps = {
        "homebrew/homebrew-core" = inputs.homebrew-core;
        "homebrew/homebrew-cask" = inputs.homebrew-cask;
        "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
        "nikitabobko/homebrew-tap" = inputs.homebrew-nikitabobko;
        "fred-drake/homebrew-tap" = inputs.homebrew-fdrake;
        "sst/homebrew-tap" = inputs.homebrew-sst;
        "steipete/homebrew-tap" = inputs.homebrew-steipete;
      };
      mutableTaps = false;
    };
  };

  # Common Darwin modules included in every Darwin system configuration
  commonModules = [
    secrets.nixosModules.soft-secrets
    sops-nix.darwinModules.sops
    ../../modules/darwin
    nix-homebrew.darwinModules.nix-homebrew
    homebrewModule
    home-manager.darwinModules.home-manager
  ];

  mkDarwinSystem = {
    hostname,
    extraModules ? [],
    system ? "aarch64-darwin",
  }: let
    systemPkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (import ../../overlays/default.nix {inherit inputs;})
        inputs.nix4vscode.overlays.forVscode
      ];
    };
  in
    darwin.lib.darwinSystem {
      inherit system;
      pkgs = systemPkgs;
      specialArgs = {
        inherit inputs non-mac-mini-casks;
        outputs = inputs.self;
        nixpkgs = inputs.nixpkgs;
        nix-jetbrains-plugins = inputs.nix-jetbrains-plugins;
        pkgsUnstable = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            (import ../../overlays/default.nix {inherit inputs;})
            inputs.nix4vscode.overlays.forVscode
          ];
        };
        pkgsStable = import inputs.nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            (import ../../overlays/default.nix {inherit inputs;})
            inputs.nix4vscode.overlays.forVscode
          ];
        };
        pkgsFredTesting = import inputs.nixpkgs-fred-testing {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            (import ../../overlays/default.nix {inherit inputs;})
            inputs.nix4vscode.overlays.forVscode
          ];
        };
        pkgsFredUnstable = import inputs.nixpkgs-fred-unstable {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            (import ../../overlays/default.nix {inherit inputs;})
            inputs.nix4vscode.overlays.forVscode
          ];
        };
      };
      modules =
        commonModules
        ++ [../../modules/darwin/${hostname}]
        ++ extraModules;
    };
in {
  flake.darwinConfigurations = {
    mac-studio = mkDarwinSystem {
      hostname = "mac-studio";
      extraModules = [
        {
          home-manager = mkHomeManager {
            hostName = "mac-studio";
            imports = [
              ../../modules/home-manager/features/darwin-hm.nix
              ../../modules/home-manager/host/mac-studio.nix
            ];
          };
        }
      ];
    };

    macbook-pro = mkDarwinSystem {
      hostname = "macbook-pro";
      extraModules = [
        {
          home-manager = mkHomeManager {
            hostName = "macbook-pro";
            imports = [
              ../../modules/home-manager/features/darwin-hm.nix
              ../../modules/home-manager/host/macbook-pro.nix
            ];
          };
        }
      ];
    };

    laisas-mac-mini = mkDarwinSystem {
      hostname = "laisas-mac-mini";
      extraModules = [
        {
          home-manager = mkHomeManager {
            hostName = "laisas-mac-mini";
            imports = [
              ../../modules/home-manager/features/darwin-hm.nix
            ];
          };
        }
      ];
    };
  };
}
