{
  inputs,
  outputs,
  nixpkgs,
  nixpkgs-stable,
  nixpkgs-unstable,
  nix4vscode,
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
              ../modules/home-manager/linux-desktop.nix
            ];
            hostArgs.hostName = "macbookx86";
          };
        }
      ];
    };

  fredpc = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
      config.cudaSupport = true;
      overlays = [
        (import ../overlays/default.nix {inherit inputs;})
        nix4vscode.overlays.forVscode
        (_: _prev: {
          inherit
            ((import nixpkgs-unstable {
              system = "x86_64-linux";
              config.allowUnfree = true;
            }))
            devenv
            ;
        })
      ];
    };
    specialArgs = {
      inherit inputs outputs nixpkgs nixpkgs-unstable nix4vscode;
      pkgsUnstable = import nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
        config.cudaSupport = true;
      };
      pkgsStable = import nixpkgs-stable {
        system = "x86_64-linux";
        config.allowUnfree = true;
        config.cudaSupport = true;
      };
    };
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
            ../modules/home-manager/host/fredpc.nix
          ];
          hostArgs.hostName = "fredpc";
        };
      }
    ];
  };

  nixosaarch64vm = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    pkgs = import nixpkgs {
      system = "aarch64-linux";
      config.allowUnfree = true;
      overlays = [
        nix4vscode.overlays.forVscode
      ];
    };
    specialArgs = {
      inherit inputs outputs nixpkgs nixpkgs-unstable nix4vscode secrets;
      pkgsUnstable = import nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
        config.cudaSupport = true;
      };
      pkgsStable = import nixpkgs-stable {
        system = "x86_64-linux";
        config.allowUnfree = true;
        config.cudaSupport = true;
      };
    };
    modules = [
      disko.nixosModules.disko
      secrets.nixosModules.soft-secrets
      sops-nix.nixosModules.sops
      ../modules/nixos
      ../modules/nixos/host/nixosaarch64vm/configuration.nix
      home-manager.nixosModules.home-manager
      {
        home-manager = lib.mkHomeManager {
          inherit inputs secrets;
          imports = [
          ];
          hostArgs.hostName = "nixosaarch64vm";
        };
      }
    ];
  };
}
