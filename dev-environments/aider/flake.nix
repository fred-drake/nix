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
        venvDir = "/Users/fdrake/aider/.venv";
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonPackage
            pythonPackage.pkgs.venvShellHook
          ];

          venvDir = venvDir;

          postVenvCreation = ''
            pip install --upgrade pip
            pip install wheel
            pip install aider-chat
          '';

          postShellHook = ''
          '';

        };
      }
    );
}
