{pkgs ? import <nixpkgs> {}}: let
  container-digest = pkgs.callPackage ./container-digest.nix {};
  npm-refresh = pkgs.callPackage ./npm-refresh.nix {};

  # Helper scripts
  update-fetcher-repos = pkgs.writeShellScriptBin "update-fetcher-repos" ''
    SRCFILE=''${PROJECT_ROOT:-$(pwd)}/apps/fetcher/repos-src.nix
    TOMLFILE=''${PROJECT_ROOT:-$(pwd)}/apps/fetcher/repos.toml
    echo "####################################" > $SRCFILE
    echo "# Auto-generated -- do not modify! #" >> $SRCFILE
    echo "####################################" >> $SRCFILE
    echo "{pkgs, ...}: {" >> $SRCFILE
    ${pkgs.tomlq}/bin/tq --file $TOMLFILE --output json '.repos' | \
    ${pkgs.jq}/bin/jq -r '.[] | "\(.name) = \(.url)"' | \
    while IFS== read -r name url; do
      processed_url=pkgs.$(${pkgs.nurl}/bin/nurl "''${url# }" | tr -d '\n')
      echo "  ''${name} = ''${processed_url};"
    done >> $SRCFILE
    echo "}" >> $SRCFILE
    ${pkgs.alejandra}/bin/alejandra --quiet $SRCFILE
  '';

  system-flake-rebuild = pkgs.writeShellScriptBin "system-flake-rebuild" ''
    if [ ! -z "$1" ]; then
        export CMD="$1"
    else
        export CMD=switch
    fi
    if [ ! -z "$2" ]; then
        export HOST="$2"
    else
        export HOST=$(hostname --short)
    fi

    if [ "$(uname -s)" = "Darwin" ]; then
        if [ "$HOST" = "freds-macbook-pro" ] || [ "$HOST" = "fred-macbook-pro-wireless" ]; then
            darwin-rebuild --show-trace --flake .#macbook-pro $CMD
        else
            darwin-rebuild --show-trace --flake .#"$HOST" $CMD
        fi
    else
        nixos-rebuild --show-trace --flake .#"$HOST" $CMD
    fi
  '';

  update-container-digests = pkgs.writeShellScriptBin "update-container-digests" ''
    SHA_FILE=''${PROJECT_ROOT:-$(pwd)}/apps/fetcher/containers-sha.nix
    echo "Updating container digests..."
    echo "####################################" > $SHA_FILE
    echo "# Auto-generated -- do not modify! #" >> $SHA_FILE
    echo "####################################" >> $SHA_FILE
    ${container-digest}/bin/container-digest --containers ''${PROJECT_ROOT:-$(pwd)}/apps/fetcher/containers.toml --output-format nix >> $SHA_FILE
    ${pkgs.alejandra}/bin/alejandra --quiet $SHA_FILE
  '';

  update-npm-packages = pkgs.writeShellScriptBin "update-npm-packages" ''
    TOML_FILE=''${PROJECT_ROOT:-$(pwd)}/apps/fetcher/npm-packages.toml
    NIX_FILE=''${PROJECT_ROOT:-$(pwd)}/apps/fetcher/npm-packages.nix
    echo "Updating NPM packages..."
    ${npm-refresh}/bin/npm-refresh $TOML_FILE > $NIX_FILE
    ${pkgs.alejandra}/bin/alejandra --quiet $NIX_FILE
  '';
in
  pkgs.mkShell {
    buildInputs = with pkgs; [
      colmena
      git
      just
      alejandra
      nixos-anywhere
      nixd
      nurl
      tomlq
      statix
      nodejs_22
      uv

      # Additional dependencies needed by scripts
      # jq

      # Helper scripts
      update-fetcher-repos
      system-flake-rebuild
      update-container-digests
      update-npm-packages
    ];

    # Environment variables for Aider
    AIDER_LINT_CMD = "statix check";
    AIDER_TEST_CMD = "just build";
    AIDER_AUTO_TEST = "true";

    # Set PROJECT_ROOT for scripts
    PROJECT_ROOT = toString ./.;

    shellHook = ''
      # Add user's local bin to PATH
      export PATH="$PATH:$HOME/.local/bin"

      echo "Nix development shell activated"
      echo "Project root: $PROJECT_ROOT"
    '';
  }
