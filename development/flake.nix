{
  description = "Development environment for Cover Letter Writer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/935bc62216cc9c87e5604d5bc576c607fca45dee";
    flake-utils.url = "github:numtide/flake-utils";

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the same nixpkgs as above
    };

    # Home Manager for managing user environments
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the same nixpkgs as above
    };

  };

  outputs = { self, nixpkgs, flake-utils, nix-vscode-extensions, home-manager, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
        lib = nixpkgs.lib;
        marketplace = nix-vscode-extensions.extensions.${pkgs.system}.vscode-marketplace;
        vscode = (import ../apps/vscode/vscode.nix) { inherit pkgs nix-vscode-extensions lib; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            cargo
            just
            (vscode-with-extensions.override {
              vscodeExtensions = vscode.globalExtensions ++ (with marketplace; [
              ]);
            })
          ];

          shellHook = ''
            echo "Welcome to this Nix flake development environment!"
          '';
        };
      }
    );
}
