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
    vscode.url = "github:fred-drake/vscode";
    # vscode.url = "git+file:///Users/fdrake/Source/github.com/fred-drake/vscode"; # For locally testing my contributions
  };

  # Output configuration
  outputs = {
    self,
    nixpkgs,
    home-manager,
    darwin,
    disko,
    ...
  } @ inputs: let
    inherit (self) outputs;

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

    overlayPackages = final: prev: {
      wireguard-tools = inputs.nixpkgs-stable.legacyPackages.${prev.system}.wireguard-tools;
    };

    # Function to create Neovim packages with unique names
    mkNeovimPackages = pkgs: neovimPkgs: let
      mkNeovimAlias = name: pkg:
        pkgs.runCommand "neovim-${name}" {} ''
          mkdir -p $out/bin
          ln -s ${pkg}/bin/nvim $out/bin/nvim-${name}
        '';
    in
      builtins.mapAttrs mkNeovimAlias neovimPkgs;

    # Function to create VSCode packages with unique names
    mkVSCodePackages = pkgs: vscodePkgs: let
      mkVSCodeAlias = name: pkg:
        pkgs.runCommand "vscode-${name}" {} ''
          mkdir -p $out/bin
          ln -s ${pkg}/bin/code $out/bin/code-${name}
        '';
    in
      builtins.mapAttrs mkVSCodeAlias vscodePkgs;

    mkVSCodeModule = {
      pkgs,
      inputs,
    }: {
      home.packages =
        (builtins.attrValues (mkVSCodePackages pkgs inputs.vscode.packages.${pkgs.system}))
        ++ [inputs.vscode.packages.${pkgs.system}.default];
    };

    # Create a home manager configuration, with additional imports specific to the configuration
    mkHomeManager = imports: {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      users.fdrake.imports =
        [
          ./modules/home-manager
          ({pkgs, ...}: {
            home.packages =
              (builtins.attrValues (mkNeovimPackages pkgs inputs.neovim.packages.${pkgs.system}))
              ++ [inputs.neovim.packages.${pkgs.system}.default];
          })
        ]
        ++ imports;
      extraSpecialArgs = {inherit inputs;};
    };
  in
    inputs.flake-utils.lib.eachDefaultSystem (system: {})
    // {
      # NixOS configurations
      nixosConfigurations = {
        macbookx86 = let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
            overlays = [overlayPackages];
          };
        in
          nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            pkgs = pkgs;
            specialArgs = {inherit inputs outputs nixpkgs;};
            modules = [
              inputs.nur.nixosModules.nur
              ./modules/nixos/macbookx86/configuration.nix
              inputs.nixos-hardware.nixosModules.apple-t2
              home-manager.nixosModules.home-manager
              {
                home-manager = mkHomeManager [
                  ./modules/home-manager/workstation.nix
                  ./modules/home-manager/linux-desktop.nix
                  (mkVSCodeModule {inherit pkgs inputs;})
                ];
              }
            ];
          };
        nixoswinvm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          pkgs = import nixpkgs {
            system = "x86_64-linux";
          };
          specialArgs = {inherit inputs outputs nixpkgs;};
          modules = [
            disko.nixosModules.disko
            ./modules/nixos/nixoswinvm/configuration.nix
            ./modules/nixos/nixoswinvm/hardware-configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = mkHomeManager [];
            }
          ];
        };
        nixosaarch64vm = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          pkgs = import nixpkgs {
            system = "aarch64-linux";
          };
          specialArgs = {inherit inputs outputs nixpkgs;};
          modules = [
            disko.nixosModules.disko
            ./modules/nixos/nixosaarch64vm/configuration.nix
            # home-manager.nixosModules.home-manager
            # {
            #   home-manager = mkHomeManager [];
            # }
          ];
        };
        forgejo = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            ./modules/nixos/forgejo/configuration.nix
            ./modules/nixos/forgejo/hardware-configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = mkHomeManager [];
            }
          ];
        };
      };

      # Darwin (macOS) configurations
      darwinConfigurations = {
        mac-studio = let
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = true; # Allow unfree packages
            overlays = [overlayPackages];
          };
        in
          darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            pkgs = pkgs;
            specialArgs = {inherit inputs outputs nixpkgs non-mac-mini-casks;};
            modules = [
              ./modules/darwin
              ./modules/darwin/mac-studio
              home-manager.darwinModules.home-manager
              {
                home-manager = mkHomeManager [
                  ./modules/home-manager/workstation.nix
                  ./modules/home-manager/darwin.nix
                  (mkVSCodeModule {inherit pkgs inputs;})
                ];
              }
            ];
          };
        macbook-pro = let
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = true; # Allow unfree packages
            overlays = [overlayPackages];
          };
        in
          darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            pkgs = pkgs;
            specialArgs = {inherit inputs outputs nixpkgs non-mac-mini-casks;};
            modules = [
              ./modules/darwin
              ./modules/darwin/macbook-pro
              home-manager.darwinModules.home-manager
              {
                home-manager = mkHomeManager [
                  ./modules/home-manager/workstation.nix
                  ./modules/home-manager/darwin.nix
                  (mkVSCodeModule {inherit pkgs inputs;})
                ];
              }
            ];
          };
        laisas-mac-mini = let
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = true; # Allow unfree packages
            overlays = [overlayPackages];
          };
        in
          darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            pkgs = pkgs;
            specialArgs = {inherit inputs outputs nixpkgs;};
            modules = [
              ./modules/darwin
              ./modules/darwin/laisas-mac-mini
              home-manager.darwinModules.home-manager
              {
                home-manager = mkHomeManager [
                  ./modules/home-manager/workstation.nix
                  ./modules/home-manager/darwin.nix
                  (mkVSCodeModule {inherit pkgs inputs;})
                ];
              }
            ];
          };
      };
    };
}
