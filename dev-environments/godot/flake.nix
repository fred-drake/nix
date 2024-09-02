{
  description = "A Nix-flake-based Godot development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/3007f981ee958d8e7607a7c5a2de09e634cafc4c";

    # Repository for VSCode extensions
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the same nixpkgs as above
    };
  };

  outputs = { self, nixpkgs, nix-vscode-extensions, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;  # Allow unfree packages
        };
      });
    in
    {

      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            (with dotnetCorePackages; combinePackages [
              sdk_8_0
            ])
            (vscode-with-extensions.override {
              vscodeExtensions = with nix-vscode-extensions.extensions.${pkgs.system}.vscode-marketplace; [
                ms-dotnettools.csharp
                geequlim.godot-tools
                aliasadidev.nugetpackagemanagergui
                revrenlove.c-sharp-utilities
              ];
            })
          ];

          env = {
            # Descriptive shell name gets used in the oh-my-posh prompt
            NIX_SHELL_NAME = "dotnet " + (builtins.readFile (pkgs.runCommand "dotnet-version" {} ''
              ${pkgs.dotnetCorePackages.sdk_8_0}/bin/dotnet --version | tr -d '\n' > $out
            ''));
          };

          shellHook = ''
            echo "Godot environment is ready"
            echo -n ".NET version "
            dotnet --version
          '';
        };
      });
    };
}
