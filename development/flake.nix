{
  description = "Development environment for Cover Letter Writer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/935bc62216cc9c87e5604d5bc576c607fca45dee";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
        lib = nixpkgs.lib;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            cargo
            just
          ];

          shellHook = ''
            echo "Welcome to this Nix flake development environment!"
          '';
        };
      }
    );
}
