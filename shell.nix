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
    ${pkgs.jq}/bin/jq -c '.[]' | \
    while IFS= read -r repo; do
      name=$(echo "$repo" | ${pkgs.jq}/bin/jq -r '.name')
      url=$(echo "$repo" | ${pkgs.jq}/bin/jq -r '.url')
      rev=$(echo "$repo" | ${pkgs.jq}/bin/jq -r '.rev // empty')

      if [ -n "$rev" ]; then
        processed_url=pkgs.$(${pkgs.nurl}/bin/nurl "$url" "$rev" | tr -d '\n')
      else
        processed_url=pkgs.$(${pkgs.nurl}/bin/nurl "$url" | tr -d '\n')
      fi
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
        if [ "$HOST" = "freds-macbook-pro" ] || [ "$HOST" = "fred-macbook-pro-wireless" ] || [ "$HOST" = "Mac" ] || [ "$HOST" = "mac" ]; then
            darwin-rebuild --show-trace --flake .#macbook-pro $CMD
        elif [ "$HOST" = "Laisas-Mac-mini" ] || [ "$HOST" = "laisas-mac-mini" ]; then
            darwin-rebuild --show-trace --flake .#laisas-mac-mini $CMD
        else
            darwin-rebuild --show-trace --flake .#"$HOST" $CMD
        fi
    else
        nixos-rebuild --show-trace --flake .#"$HOST" $CMD
    fi
  '';

  update-container-digests = pkgs.writeShellScriptBin "update-container-digests" ''
    set -euo pipefail
    SHA_FILE=''${PROJECT_ROOT:-$(pwd)}/apps/fetcher/containers-sha.nix
    TMP_FILE=$(${pkgs.coreutils}/bin/mktemp "''${SHA_FILE}.XXXXXX")
    trap 'rm -f "$TMP_FILE"' EXIT
    echo "Updating container digests..."
    echo "####################################" > "$TMP_FILE"
    echo "# Auto-generated -- do not modify! #" >> "$TMP_FILE"
    echo "####################################" >> "$TMP_FILE"
    ${container-digest}/bin/container-digest --containers ''${PROJECT_ROOT:-$(pwd)}/apps/fetcher/containers.toml --output-format nix >> "$TMP_FILE"
    ${pkgs.gnused}/bin/sed -i 's/^{\.\.\.}: {$/_: {/' "$TMP_FILE"
    ${pkgs.alejandra}/bin/alejandra --quiet "$TMP_FILE"
    mv "$TMP_FILE" "$SHA_FILE"
  '';

  update-claude-plugins = pkgs.writeShellScriptBin "update-claude-plugins" ''
    SRCFILE=''${PROJECT_ROOT:-$(pwd)}/apps/fetcher/claude-plugins-src.nix
    TOMLFILE=''${PROJECT_ROOT:-$(pwd)}/apps/fetcher/claude-plugins.toml
    echo "####################################" > $SRCFILE
    echo "# Auto-generated -- do not modify! #" >> $SRCFILE
    echo "####################################" >> $SRCFILE
    echo "{pkgs, ...}: {" >> $SRCFILE
    ${pkgs.tomlq}/bin/tq --file $TOMLFILE --output json '.repos' | \
    ${pkgs.jq}/bin/jq -c '.[]' | \
    while IFS= read -r repo; do
      name=$(echo "$repo" | ${pkgs.jq}/bin/jq -r '.name')
      url=$(echo "$repo" | ${pkgs.jq}/bin/jq -r '.url')
      rev=$(echo "$repo" | ${pkgs.jq}/bin/jq -r '.rev // empty')
      fetcher=$(echo "$repo" | ${pkgs.jq}/bin/jq -r '.fetcher // empty')

      if [ "$fetcher" = "tarball" ]; then
        # Resolve to a concrete commit so the URL is reproducible.
        if [ -n "$rev" ]; then
          resolved_rev="$rev"
        else
          resolved_rev=$(${pkgs.git}/bin/git ls-remote "$url" HEAD | ${pkgs.coreutils}/bin/cut -f1)
        fi
        archive_url="$url/archive/''${resolved_rev}.tar.gz"
        sha256=$(${pkgs.nix}/bin/nix-prefetch-url --type sha256 --unpack "$archive_url" 2>/dev/null)
        echo "  ''${name} = builtins.fetchTarball {"
        echo "    url = \"''${archive_url}\";"
        echo "    sha256 = \"''${sha256}\";"
        echo "  };"
      else
        if [ -n "$rev" ]; then
          processed_url=pkgs.$(${pkgs.nurl}/bin/nurl "$url" "$rev" | tr -d '\n')
        else
          processed_url=pkgs.$(${pkgs.nurl}/bin/nurl "$url" | tr -d '\n')
        fi
        echo "  ''${name} = ''${processed_url};"
      fi
    done >> $SRCFILE
    echo "}" >> $SRCFILE
    ${pkgs.alejandra}/bin/alejandra --quiet $SRCFILE
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
      gh
      hcloud
      just
      alejandra
      nixos-anywhere
      nixd
      nurl
      tomlq
      statix
      nodejs_22
      uv
      deadnix
      python3
      python3Packages.pyyaml

      # Additional dependencies needed by scripts
      # jq

      # Helper scripts
      update-fetcher-repos
      update-claude-plugins
      system-flake-rebuild
      update-container-digests
      update-npm-packages
    ];

    # Environment variables for Aider
    AIDER_LINT_CMD = "statix check";
    AIDER_TEST_CMD = "just build";
    AIDER_AUTO_TEST = "true";

    shellHook = ''
      # Add user's local bin to PATH
      export PATH="$PATH:$HOME/.local/bin"

      # Load the Hetzner Cloud API token at runtime (never via readFile, which
      # would bake the secret into the world-readable nix store).
      if [ -r "$HOME/.config/sops-nix/secrets/hetzner-home-api-token" ]; then
        export HCLOUD_TOKEN="$(cat "$HOME/.config/sops-nix/secrets/hetzner-home-api-token")"
      fi

      # Authenticate GitHub API calls (nurl in update-claude-plugins, etc.) so
      # they don't hit the unauthenticated 60 req/hr limit and 403. Fall back to
      # the gh CLI's token if GITHUB_TOKEN isn't already set in the environment.
      if [ -z "''${GITHUB_TOKEN:-}" ] && command -v gh >/dev/null 2>&1; then
        _gh_token="$(gh auth token 2>/dev/null)"
        if [ -n "$_gh_token" ]; then
          export GITHUB_TOKEN="$_gh_token"
        fi
        unset _gh_token
      fi

      # Set PROJECT_ROOT to the actual working directory, not the nix store copy
      export PROJECT_ROOT="$PWD"

      echo "Nix development shell activated"
      echo "Project root: $PROJECT_ROOT"
    '';
  }
