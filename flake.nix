{
  description = "Nix Flake";

  nixConfig = {
    trusted-users = ["root" "fdrake"];
  };

  # Input sources for the flake
  inputs = {
    # Nixpkgs repository, based on my current level of debugging and stability
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11"; # Stable channel
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable"; # Typically 3-4 days behind master
    nixpkgs.url = "github:nixos/nixpkgs"; # Absolutely bleeding edge
    nixpkgs-fred-unstable.url = "github:fred-drake/nixpkgs/fred-unstable"; # Modules that have not yet been pulled into upstream
    nixpkgs-fred-testing.url = "git+file:///Users/fdrake/Source/github.com/fred-drake/nixpkgs"; # For locally testing my contributions

    # Secrets inputs
    secrets.url = "git+ssh://git@github.com/fred-drake/nix-secrets.git";
    sops-nix.url = "github:Mic92/sops-nix";

    colmena.url = "github:zhaofengli/colmena";

    # A collection of NixOS modules covering hardware quirks.
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # Pure Nix flake utility functions
    flake-utils.url = "github:numtide/flake-utils";

    # Manage a user environment using Nix
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the same nixpkgs as above
    };

    # nix modules for darwin
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the same nixpkgs as above
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew"; # Nix Homebrew integration

    # Nix User Repository: User contributed nix packages
    nur.url = "github:nix-community/NUR";
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim.url = "github:fred-drake/neovim"; # My custom neovim configuration

    # vscode.url = "github:fred-drake/vscode"; # My custom vscode configuration
  };

  # Output configuration
  outputs = {
    self,
    colmena,
    nixpkgs,
    nixpkgs-stable,
    nixpkgs-unstable,
    nixpkgs-fred-unstable,
    nixpkgs-fred-testing,
    nixos-hardware,
    home-manager,
    darwin,
    disko,
    nix-homebrew,
    secrets,
    sops-nix,
    ...
  } @ inputs: let
    inherit (self) outputs;
  in
    inputs.flake-utils.lib.eachDefaultSystem (system: {})
    // {
      # NixOS configurations
      nixosConfigurations = import ./systems/nixos.nix {
        inherit
          inputs
          outputs
          colmena
          nixpkgs
          nixpkgs-stable
          nixpkgs-unstable
          nixpkgs-fred-unstable
          nixpkgs-fred-testing
          secrets
          ;
      };

      # Darwin (macOS) configurations
      darwinConfigurations = import ./systems/darwin.nix {
        inherit
          inputs
          outputs
          nixpkgs
          nixpkgs-stable
          nixpkgs-unstable
          nixpkgs-fred-unstable
          nixpkgs-fred-testing
          secrets
          ;
      };

      colmena = {
        meta = {
          nixpkgs = import nixpkgs {system = "aarch64-linux";};
        };
        "adguard1" = let
          config =
            (import "${nixpkgs}/nixos/lib/eval-config.nix" {
              system = "aarch64-linux";
              modules = [
                secrets.nixosModules.soft-secrets
                nixos-hardware.nixosModules.raspberry-pi-4
                "${nixpkgs}/nixos/modules/profiles/minimal.nix"
                ./modules/nixos/adguard1/configuration.nix
              ];
              specialArgs = {inherit secrets;};
            })
            .config;
        in {
          nixpkgs.system = "aarch64-linux";
          nixpkgs.overlays = [];
          nixpkgs.config = {};
          imports = [
            secrets.nixosModules.soft-secrets
            nixos-hardware.nixosModules.raspberry-pi-4
            "${nixpkgs}/nixos/modules/profiles/minimal.nix"
            ./modules/nixos/adguard1/configuration.nix
          ];
          deployment = {
            buildOnTarget = false;
            targetHost = config.soft-secrets.host.adguard1.admin_ip_address;
            targetUser = "default";
          };
        };
        "adguard2" = {
          nixpkgs.system = "aarch64-linux";
          nixpkgs.overlays = [];
          nixpkgs.config = {};
          imports = [
            secrets.nixosModules.soft-secrets
            nixos-hardware.nixosModules.raspberry-pi-4
            "${nixpkgs}/nixos/modules/profiles/minimal.nix"
            ./modules/nixos/adguard2/configuration.nix
          ];
          deployment = {
            buildOnTarget = false;
            targetHost = "192.168.208.9";
            targetUser = "default";
          };
        };
      };

      # Library functions
      lib = {
        mkHomeManager = import ./lib/mk-home-manager.nix;
        mkNeovimPackages = import ./lib/mk-neovim-packages.nix;
      };
    };
}
