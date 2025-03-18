{
  description = "Nix Flake";

  nixConfig = {
    trusted-users = ["root" "fdrake"];
  };

  # Input sources for the flake
  inputs = {
    # Nixpkgs repository, based on my current level of debugging and stability
    nixpkgs.url = "github:nixos/nixpkgs"; # Absolutely bleeding edge
    # nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"; # Typically 3-4 days behind master
    # nixpkgs.url = "git+file:///Users/fdrake/Source/github.com/fred-drake/nixpkgs"; # For locally testing my contributions
    # nixpkgs.url = "github:fred-drake/nixpkgs"; # My fork of nixpkgs, for when I am waiting for my contributions to be merged

    # Secrets inputs
    secrets.url = "git+ssh://git@github.com/fred-drake/nix-secrets.git";
    sops-nix.url = "github:Mic92/sops-nix";

    # Nix stable channel, for packages that break with nixpkgs-unstable
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

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

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

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

    # My custom neovim configuration
    neovim.url = "github:fred-drake/neovim";
    # neovim.url = "git+file:///Users/fdrake/Source/github.com/fred-drake/neovim"; # For locally testing my contributions

    # My custom vscode configuration
    # vscode.url = "github:fred-drake/vscode";
    # vscode.url = "git+file:///Users/fdrake/Source/github.com/fred-drake/vscode"; # For locally testing my contributions
  };

  # Output configuration
  outputs = {
    self,
    nixpkgs,
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
      nixosConfigurations = import ./systems/nixos.nix {inherit inputs outputs nixpkgs secrets;};

      # Darwin (macOS) configurations
      darwinConfigurations = import ./systems/darwin.nix {inherit inputs outputs nixpkgs secrets;};

      # Library functions
      lib = {
        mkHomeManager = import ./lib/mk-home-manager.nix;
        mkNeovimPackages = import ./lib/mk-neovim-packages.nix;
      };
    };
}
