{
  # Description of the flake
  description = "Nix Flake";

  # Input sources for the flake
  inputs = {
    # Use a specific commit hash for nixpkgs instead of a branch for stability
    nixpkgs.url = "github:nixos/nixpkgs/b74e7a74498f63ffac3153df86d8be73d8936f0e";

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

    # Repository for VSCode extensions
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
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
    nix-vscode-extensions,
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

    commonVSCodeExtensions = with pkgs.vscode-extensions; [
      # Add your common extensions here, for example:
      vscodevim.vim
      ms-vsliveshare.vsliveshare
      eamodio.gitlens
      # Add more as needed
    ];

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
      Freds-Mac-Studio = darwin.lib.darwinSystem {
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
              extraSpecialArgs = { inherit nix-vscode-extensions; };
              users.fdrake.imports = [ ./modules/home-manager ];
            };
          }
        ];
      };
      Freds-MacBook-Pro = darwin.lib.darwinSystem {
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
              extraSpecialArgs = { inherit nix-vscode-extensions; };
              users.fdrake.imports = [ ./modules/home-manager ];
            };
          }
        ];
      };
    };
  };
}
