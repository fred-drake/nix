{
  description = "A Python development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        pythonPackage = pkgs.python3;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonPackage
          ];

          postShellHook = ''
          '';

        };
      }
    );
}
