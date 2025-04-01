{
  inputs,
  outputs,
  nixpkgs,
  ...
}: let
  inherit (inputs) home-manager disko nixos-hardware secrets sops-nix;
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
        secrets.nixosModules.soft-secrets
        sops-nix.nixosModules.sops
        ../modules/nixos/host/macbookx86/configuration.nix
        nixos-hardware.nixosModules.apple-t2
        home-manager.nixosModules.home-manager
        {
          home-manager = lib.mkHomeManager {
            inherit inputs secrets;
            imports = [
              ../modules/home-manager/workstation.nix
              ../modules/home-manager/linux-desktop.nix
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
      secrets.nixosModules.soft-secrets
      sops-nix.nixosModules.sops
      ../modules/nixos
      ../modules/nixos/host/nixoswinvm/configuration.nix
      ../modules/nixos/host/nixoswinvm/hardware-configuration.nix
      home-manager.nixosModules.home-manager
      {
        home-manager = lib.mkHomeManager {
          inherit inputs secrets;
          imports = [];
        };
      }
    ];
  };

  fredpc = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    specialArgs = {inherit inputs outputs nixpkgs;};
    modules = [
      secrets.nixosModules.soft-secrets
      sops-nix.nixosModules.sops
      ../modules/nixos
      ../modules/nixos/host/fredpc/configuration.nix
      ../modules/nixos/host/fredpc/hardware-configuration.nix
      home-manager.nixosModules.home-manager
      {
        home-manager = lib.mkHomeManager {
          inherit inputs secrets;
          imports = [
            ../modules/home-manager/workstation.nix
            ../modules/home-manager/host/fredpc.nix
          ];
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
      secrets.nixosModules.soft-secrets
      sops-nix.nixosModules.sops
      ../modules/nixos
      ../modules/nixos/host/aarch64-initial/configuration.nix
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
      secrets.nixosModules.soft-secrets
      sops-nix.nixosModules.sops
      ../modules/nixos
      ../modules/nixos/host/nixosaarch64vm/configuration.nix
      home-manager.nixosModules.home-manager
      {
        # home-manager.useGlobalPkgs = true;
        # home-manager.useUserPackages = true;
        # home-manager.users.fdrake = import ../modules/home-manager;
        home-manager = lib.mkHomeManager {
          inherit inputs secrets;
          imports = [];
        };
      }
    ];
  };

  forgejo = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      disko.nixosModules.disko
      ../modules/nixos
      ../modules/nixos/host/forgejo/configuration.nix
      ../modules/nixos/host/forgejo/hardware-configuration.nix
      home-manager.nixosModules.home-manager
      {
        home-manager = lib.mkHomeManager {
          inherit inputs secrets;
          imports = [];
        };
      }
    ];
  };

  adguard1 = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    pkgs = import nixpkgs {
      system = "aarch64-linux";
    };
    specialArgs = {inherit inputs outputs nixpkgs;};
    modules = [
      secrets.nixosModules.soft-secrets
      nixos-hardware.nixosModules.raspberry-pi-4
      "${nixpkgs}/nixos/modules/profiles/minimal.nix"
      ../modules/nixos
      ../modules/nixos/host/adguard1/configuration.nix
    ];
  };
}
