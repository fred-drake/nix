# Godot Development Environment Flake
#
# This flake defines a Nix-based development environment for Godot projects.
# It includes:
#   - .NET SDK and tools
#   -Custom shell environment with .NET version in prompt

{
  description = "A Nix-flake-based Godot development environment";

  # Define the inputs for the flake
  # This includes the nixpkgs repository and the repository for VSCode extensions

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
      # Define the supported systems for the development environment
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      # Function to generate attributes for each supported system
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: let
        # Import the nixpkgs for the given system
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;  # Allow unfree packages
        };

        # Import common VSCode extensions
        commonVSCodeExtensions = import ../../apps/vscode-extensions.nix { inherit pkgs nix-vscode-extensions; };

        # Get the marketplace extensions for the given system
        marketplace = nix-vscode-extensions.extensions.${pkgs.system}.vscode-marketplace;
      in f {
        inherit pkgs commonVSCodeExtensions marketplace;
      });
    in
    {

      # Define the development shells for each supported system
      devShells = forEachSupportedSystem ({ pkgs, commonVSCodeExtensions, marketplace }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            netcoredbg # Third party debugger required when using Cursor IDE
            (with dotnetCorePackages; combinePackages [
              sdk_8_0 # .NET SDK version 8.0
            ])
            (vscode-with-extensions.override {
              vscodeExtensions = commonVSCodeExtensions.common ++ (with marketplace; [
                ms-dotnettools.vscode-dotnet-runtime       # .NET runtime support for VSCode
                ms-dotnettools.csharp                      # C# language support for VSCode
                geequlim.godot-tools                       # Godot engine tools for VSCode
                aliasadidev.nugetpackagemanagergui         # NuGet package manager GUI for VSCode
                revrenlove.c-sharp-utilities               # Additional C# utilities for VSCode
              ]);
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
