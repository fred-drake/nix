{
  description = "A Nix-flake-based Python development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/d68746a3c4ccce698285e1f7a4760a61a756ff47";

    # Repository for VSCode extensions
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the same nixpkgs as above
    };
  };

  outputs = { self, nixpkgs, nix-vscode-extensions, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;  # Allow unfree packages
        };
        commonVSCodeExtensions = import ../../apps/vscode-extensions.nix { inherit pkgs nix-vscode-extensions; };
        marketplace = nix-vscode-extensions.extensions.${pkgs.system}.vscode-marketplace;
      in f {
        inherit pkgs commonVSCodeExtensions marketplace;
      });
    in
    {

      devShells = forEachSupportedSystem ({ pkgs, commonVSCodeExtensions, marketplace }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            ruff
            (vscode-with-extensions.override {
              vscodeExtensions = commonVSCodeExtensions.common ++ (with marketplace; [
                ms-python.python
                ms-toolsai.jupyter
                njpwerner.autodocstring
                tamasfe.even-better-toml
                ninoseki.vscode-pylens
                usernamehw.errorlens
                charliermarsh.ruff
                # KevinRose.vsc-python-indent
              ]);
            })
          ];

          env = {
            # Descriptive shell name gets used in the oh-my-posh prompt
            NIX_SHELL_NAME = "python ";
          };

          shellHook = ''
            echo "Python environment is ready"
            python --version
          '';
        };
      });
    };
}
