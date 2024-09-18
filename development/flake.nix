{
  description = "Development environment for Cover Letter Writer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
            aider-chat
          ];

          shellHook = ''
            echo "Welcome to this Nix flake development environment!"
          '';
        };
      }
    );
}
