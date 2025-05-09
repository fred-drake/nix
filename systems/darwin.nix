{
  inputs,
  outputs,
  nixpkgs,
  nixpkgs-stable,
  nixpkgs-unstable,
  nixpkgs-fred-unstable,
  nixpkgs-fred-testing,
  homebrew-core,
  homebrew-cask,
  homebrew-bundle,
  homebrew-nikitabobko,
  homebrew-fdrake,
  nix-jetbrains-plugins,
  ...
}: let
  inherit (inputs) darwin home-manager nix-homebrew secrets sops-nix;
  inherit (inputs.self) lib;

  # Some casks take space on a limited Mac Mini, so only install them
  # on Mac Studio and MacBook Pro.
  non-mac-mini-casks = [
    "godot-mono"
    "steam"
    "transmission"
    "ultimaker-cura"
    "wine-stable"
    "winbox"
    # "zed"  # Temporary disable to run the pre-release
  ];

  mkDarwinSystem = {
    hostname,
    extraModules ? [],
    system ? "aarch64-darwin",
  }: let
    systemPkgs = import nixpkgs {
      system = system;
      config.allowUnfree = true;
      overlays = [(import ../overlays/default.nix {inherit inputs;})];
    };
  in
    darwin.lib.darwinSystem {
      system = system;
      pkgs = systemPkgs;
      specialArgs = {
        inherit
          inputs
          outputs
          nixpkgs
          nix-jetbrains-plugins
          non-mac-mini-casks
          ;
        pkgsUnstable = import nixpkgs-unstable {
          system = system;
          config.allowUnfree = true;
          overlays = [(import ../overlays/default.nix {inherit inputs;})];
        };
        pkgsStable = import nixpkgs-stable {
          system = system;
          config.allowUnfree = true;
          overlays = [(import ../overlays/default.nix {inherit inputs;})];
        };
        pkgsFredTesting = import nixpkgs-fred-testing {
          system = system;
          config.allowUnfree = true;
          overlays = [(import ../overlays/default.nix {inherit inputs;})];
        };
        pkgsFredUnstable = import nixpkgs-fred-unstable {
          system = system;
          config.allowUnfree = true;
          overlays = [(import ../overlays/default.nix {inherit inputs;})];
        };
      };
      modules =
        [
          secrets.nixosModules.soft-secrets
          sops-nix.darwinModules.sops
          ../modules/darwin
          ../modules/darwin/${hostname}
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "fdrake";
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;
                "nikitabobko/homebrew-tap" = homebrew-nikitabobko;
                "fred-drake/homebrew-tap" = homebrew-fdrake;
              };
              mutableTaps = false;
            };
          }
          home-manager.darwinModules.home-manager
        ]
        ++ extraModules;
    };
in {
  freds-mac-studio = mkDarwinSystem {
    hostname = "mac-studio";
    extraModules = [
      {
        home-manager = lib.mkHomeManager {
          inherit inputs secrets;
          imports = [
            ../modules/home-manager/workstation.nix
            ../modules/home-manager/darwin.nix
          ];
          hostArgs.hostName = "mac-studio";
        };
      }
    ];
  };

  macbook-pro = mkDarwinSystem {
    hostname = "macbook-pro";
    extraModules = [
      {
        home-manager = lib.mkHomeManager {
          inherit inputs secrets;
          imports = [
            ../modules/home-manager/workstation.nix
            ../modules/home-manager/darwin.nix
            ../modules/home-manager/host/macbook-pro.nix
          ];
          hostArgs.hostName = "macbook-pro";
        };
      }
    ];
  };

  laisas-mac-mini = mkDarwinSystem {
    hostname = "laisas-mac-mini";
    extraModules = [
      {
        home-manager = lib.mkHomeManager {
          inherit inputs secrets;
          imports = [
            ../modules/home-manager/workstation.nix
            ../modules/home-manager/darwin.nix
          ];
          hostArgs.hostName = "laisas-mac-mini";
        };
      }
    ];
  };
}
