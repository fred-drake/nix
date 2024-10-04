{
  description = "Development environment for Cover Letter Writer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {self, ...} @ inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config = {allowUnfree = true;};
      };
    in {
      checks = {
        pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            nixpkgs-fmt.enable = true;
            just.enable = true;
          };
        };
      };
      devShells.default = pkgs.mkShell {
        buildInputs =
          self.checks.${system}.pre-commit-check.enabledPackages
          ++ (with pkgs; [
            git
            cargo
            just
            aider-chat
            alejandra
          ]);

        shellHook = ''
          echo "Welcome to this Nix flake development environment!"
        '';
      };
    });
}
