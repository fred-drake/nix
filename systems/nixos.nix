{
  inputs,
  outputs,
  nixpkgs,
  secrets,
  ...
}: let
  inherit (inputs) home-manager disko nixos-hardware;
  inherit (inputs.self) lib;
in {
  macbookx86 = let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
      overlays = [import ./overlays/default.nix {inherit inputs;}];
    };
  in
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      inherit pkgs;
      specialArgs = {inherit inputs outputs nixpkgs;};
      modules = [
        inputs.nur.nixosModules.nur
        ./modules/nixos/macbookx86/configuration.nix
        nixos-hardware.nixosModules.apple-t2
        home-manager.nixosModules.home-manager
        {
          home-manager = lib.mkHomeManager {
            inherit inputs secrets;
            imports = [
              ./modules/home-manager/workstation.nix
              ./modules/home-manager/linux-desktop.nix
            ];
          };
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
        home-manager = lib.mkHomeManager {
          inherit inputs secrets;
          imports = [];
        };
      }
    ];
  };

  aarch64-initial = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    pkgs = import nixpkgs {
      system = "aarch64-linux";
    };
    specialArgs = {inherit inputs outputs nixpkgs;};
    modules = [
      disko.nixosModules.disko
      ./modules/nixos/aarch64-initial/configuration.nix
    ];
  };

  nixosaarch64vm = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    pkgs = import nixpkgs {
      system = "aarch64-linux";
      crossSystem = {
        config = "aarch64-darwin";
      };
    };
    specialArgs = {inherit inputs outputs nixpkgs;};
    modules = [
      disko.nixosModules.disko
      ./modules/nixos/nixosaarch64vm/configuration.nix
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.fdrake = import ./modules/home-manager;
      }
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
        home-manager = lib.mkHomeManager {
          inherit inputs secrets;
          imports = [];
        };
      }
    ];
  };
}
