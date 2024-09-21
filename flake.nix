{
  # Description of the flake
  description = "Nix Flake";

  nixConfig = {
    extra-substituters = [
      # "https://hydra.soopy.moe"
      "https://cache.soopy.moe" # toggle these if this one doesn't work.
    ];
    extra-trusted-public-keys =
      [ "hydra.soopy.moe:IZ/bZ1XO3IfGtq66g+C85fxU/61tgXLaJ2MlcGGXU8Q=" ];
  };

  # Input sources for the flake
  inputs = {
    # Use a specific commit hash for nixpkgs instead of a branch for stability
    nixpkgs.url = "github:nixos/nixpkgs";
    nixos-hardware.url = "github:nixos/nixos-hardware";

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

    nur.url = "github:nix-community/NUR";
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  # Output configuration
  outputs = {
    self,
    alejandra,
    flake-utils,
    nixpkgs,
    nixos-hardware,
    home-manager,
    darwin,
    nur,
    ...
  } @ inputs:
  let
    inherit (self) outputs;
    systems = [ "x86_64-linux" "aarch64-darwin" ]; # Supported systems

    # Common modules for all configurations
    genericModules = [{
      nix = {
        settings.experimental-features = [ "nix-command" "flakes" ];
        registry.nixos.flake = inputs.self;
        nixPath = [ "nixpkgs=${nixpkgs.outPath}" ];
      };
      environment.etc."nix/inputs/nixpkgs".source = nixpkgs.outPath;
    }];
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

    # NixOS configurations
    nixosConfigurations = {
      macbookx86 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        specialArgs = { inherit inputs outputs nixpkgs; };
        modules = [
          nur.nixosModules.nur
          ./hosts/macbookx86/configuration.nix
          ./substituter.nix
          nixos-hardware.nixosModules.apple-t2
          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              users.fdrake.imports = [ ./modules/home-manager ./modules/home-manager/linux ];
              extraSpecialArgs = { inherit inputs; };
            };
          }
        ];
      };
    };

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
              users.fdrake.imports = [ ./modules/home-manager ./modules/home-manager/darwin ./modules/home-manager/mac-studio ];
            };
          }
        ];
      };
      freds-macbook-pro = darwin.lib.darwinSystem {
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
              users.fdrake.imports = [ ./modules/home-manager ./modules/home-manager/darwin ];
            };
          }
        ];
      };
    };
  };
}
