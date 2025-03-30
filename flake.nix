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
    nixpkgs-fred-testing.url = "github:fred-drake/nixpkgs/fred-unstable"; # Modules that have not yet been pulled into upstream
    # nixpkgs-fred-testing.url = "git+file:///Users/fdrake/Source/github.com/fred-drake/nixpkgs"; # For locally testing my contributions

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

    # nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew"; # Nix Homebrew integration
    nix-homebrew.url = "git+https://github.com/zhaofengli/nix-homebrew?ref=refs/pull/71/merge";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-fdrake = {
      url = "github:fred-drake/homebrew-tap";
      flake = false;
    };
    homebrew-nikitabobko = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };

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

    # neovim.url = "github:fred-drake/neovim"; # My custom neovim configuration
    nixvim.url = "github:nix-community/nixvim";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      # IMPORTANT: we're using "libgbm" and is only available in unstable so ensure
      # to have it up to date or simply don't specify the nixpkgs input
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    homebrew-core,
    homebrew-cask,
    homebrew-bundle,
    homebrew-fdrake,
    homebrew-nikitabobko,
    secrets,
    sops-nix,
    nixvim,
    ...
  } @ inputs: let
    inherit (self) outputs;
    soft-secrets = import "${secrets}/soft-secrets";
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
          homebrew-core
          homebrew-cask
          homebrew-bundle
          homebrew-fdrake
          homebrew-nikitabobko
          ;
      };

      colmena = import ./colmena {
        inherit self nixpkgs-stable nixos-hardware secrets sops-nix;
      };

      # Library functions
      lib = {
        mkHomeManager = import ./lib/mk-home-manager.nix;
        mkNeovimPackages = import ./lib/mk-neovim-packages.nix;
      };
    };
}
