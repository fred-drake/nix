{
  # Description of the flake
  description = "Nix Flake";

  # Input sources for the flake
  inputs = {
    # Use a specific commit hash for nixpkgs instead of a branch for stability
    nixpkgs.url = "github:nixos/nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    # Formatter for the flake
    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager for managing user environments
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the same nixpkgs as above
    };

    # nix-darwin for managing macOS system configuration
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the same nixpkgs as above
    };
  };

  # Output configuration
  outputs = {
    self,
    alejandra,
    flake-utils,
    nixpkgs,
    home-manager,
    darwin,
    ...
  } @ inputs:
  let
    inherit (self) outputs;
    systems = [ "x86_64-linux" "aarch64-darwin" ]; # Supported systems
    forAllSystems = nixpkgs.lib.genAttrs systems;

    # Common modules for all configurations
    genericModules = [{
      nix = {
        settings.experimental-features = [ "nix-command" "flakes" ];
        registry.nixos.flake = inputs.self;
        nixPath = [ "nixpkgs=${nixpkgs.outPath}" ];
      };
      environment.etc."nix/inputs/nixpkgs".source = nixpkgs.outPath;
    }];

    # pkgs = import nixpkgs { inherit system; };
    pkgs = import nixpkgs {
      system = "aarch64-darwin";
      config.allowUnfree = true; # Allow unfree packages
    };

  in
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      # Formatter for the flake
      formatter = alejandra.defaultPackage.${system};

    }) // {

    # NixOS configurations (empty in this case)
    nixosConfigurations = { };

    # Darwin (macOS) configurations
    darwinConfigurations = {
      mac-studio = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true; # Allow unfree packages
        };
        specialArgs = { inherit inputs outputs nixpkgs; };
        modules = [
          ./modules/darwin
          ./modules/darwin/mac-studio
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.fdrake.imports = [ ./modules/home-manager ];
            };
          }
        ];
      };
      fred-macbook-pro-wireless = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true; # Allow unfree packages
        };
        specialArgs = { inherit inputs outputs nixpkgs; };
        modules = [
          ./modules/darwin
          ./modules/darwin/macbook-pro
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.fdrake.imports = [ ./modules/home-manager ];
            };
          }
        ];
      };
    };
  };
}
