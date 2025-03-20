{
  inputs,
  outputs,
  nixpkgs,
  nixpkgs-stable,
  nixpkgs-unstable,
  nixpkgs-fred-unstable,
  nixpkgs-fred-testing,
  secrets,
  homebrew-core,
  homebrew-cask,
  homebrew-bundle,
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
    "zed"
  ];

  mkDarwinSystem = {
    hostname,
    extraModules ? [],
    pkgs ? null,
    pkgs-stable ? null,
    pkgs-unstable ? null,
    pkgs-fred-unstable ? null,
    pkgs-fred-testing ? null,
  }: let
    systemPkgs =
      if pkgs != null
      then pkgs
      else if pkgs-stable != null
      then pkgs-stable
      else if pkgs-unstable != null
      then pkgs-unstable
      else if pkgs-fred-unstable != null
      then pkgs-fred-unstable
      else if pkgs-fred-testing != null
      then pkgs-fred-testing
      else
        import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
          overlays = [(import ../overlays/default.nix {inherit inputs;})];
        };
  in
    darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = systemPkgs;
      specialArgs = {
        inherit
          inputs
          outputs
          nixpkgs
          nixpkgs-stable
          nixpkgs-unstable
          nixpkgs-fred-testing
          nixpkgs-fred-unstable
          non-mac-mini-casks
          ;
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
        };
      }
    ];
  };
}
