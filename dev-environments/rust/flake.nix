# Rust Development Environment Flake
#
# This flake defines a Nix-based development environment for Rust projects.
# It includes:
#   - Rust toolchain (cargo, rustc, rustfmt, clippy)
#   - VSCode with Rust-related extensions
#   - Custom shell environment with Rust version in prompt

{
  description = "A Nix-flake-based Rust development environment";

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
            cargo    # Rust's package manager and build tool
            rustc    # The Rust compiler
            rustfmt  # Rust code formatter
            clippy   # Rust linter for catching common mistakes and improving code style
            libiconv # Library for converting character encodings
            gcc      # GNU Compiler Collection, required for building some Rust dependencies
            clang    # C language family frontend for LLVM, used for compiling C/C++ code
            llvmPackages.libclang # LLVM's C interface, used by some Rust tools for code analysis
            pkg-config # Helper tool used when compiling applications and libraries
            (vscode-with-extensions.override {
              vscodeExtensions = commonVSCodeExtensions.common ++ (with marketplace; [
                rust-lang.rust-analyzer        # Rust language server for code analysis and intelligent features
                tamasfe.even-better-toml       # Enhanced TOML file support, useful for Cargo.toml files
                vadimcn.vscode-lldb            # Native debugger support for Rust
                fill-labs.dependi              # Dependency management and visualization for Rust projects
                usernamehw.errorlens           # Inline error and warning highlighting
                bierner.docs-view              # Markdown documentation viewer, helpful for Rust docs
                belfz.search-crates-io         # Quick search and integration with crates.io
              ]);
            })
          ];

          env = {
            # Descriptive shell name gets used in the oh-my-posh prompt
            NIX_SHELL_NAME = "rust " + (builtins.readFile (pkgs.runCommand "cargo-version" {} ''
              ${pkgs.rustc}/bin/rustc --version | cut -d ' ' -f 2 | tr -d '\n' > $out
            ''));
          };

          shellHook = ''
            echo "Rust environment is ready"
            rustc --version
          '';
        };
      });
    };
}
