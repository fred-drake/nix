{pkgs, ...}: let
  container-digest = pkgs.callPackage ./container-digest.nix {};
  npm-refresh = pkgs.callPackage ./npm-refresh.nix {};
in {
  # https://devenv.sh/basics/

  cachix.enable =
    false;

  # https://devenv.sh/packages/
  packages = with pkgs; [
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
  ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;
  # languages.python.enable = true;
  # languages.python.version = "3.12";
  # languages.python.uv.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  # Example: scripts.ide.exec = ''nvim --cmd "let g:augment_workspace_folders = [\"$DEVENV_ROOT\"]"'';
  scripts = {
    update-fetcher-repos.exec = ''
      SRCFILE=$DEVENV_ROOT/apps/fetcher/repos-src.nix
      TOMLFILE=$DEVENV_ROOT/apps/fetcher/repos.toml
      echo "####################################" > $SRCFILE
      echo "# Auto-generated -- do not modify! #" >> $SRCFILE
      echo "####################################" >> $SRCFILE
      echo "{pkgs, ...}: {" >> $SRCFILE
      ${pkgs.tomlq}/bin/tq --file $TOMLFILE --output json '.repos' | \
      ${pkgs.jq}/bin/jq -r '.[] | "\(.name) = \(.url)"' | \
      while IFS== read -r name url; do
        processed_url=pkgs.$(nurl "''${url# }" | tr -d '\n')
        echo "  ''${name} = ''${processed_url};"
      done >> $SRCFILE
      echo "}" >> $SRCFILE
      ${pkgs.alejandra}/bin/alejandra --quiet $SRCFILE
    '';

    system-flake-rebuild.exec = ''
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

    update-container-digests.exec = ''
      SHA_FILE=$DEVENV_ROOT/apps/fetcher/containers-sha.nix
      echo "Updating container digests..."
      echo "####################################" > $SHA_FILE
      echo "# Auto-generated -- do not modify! #" >> $SHA_FILE
      echo "####################################" >> $SHA_FILE
      ${container-digest}/bin/container-digest --containers $DEVENV_ROOT/apps/fetcher/containers.toml --output-format nix >> $SHA_FILE
      ${pkgs.alejandra}/bin/alejandra --quiet $SHA_FILE
    '';

    update-npm-packages.exec = ''
      TOML_FILE=$DEVENV_ROOT/apps/fetcher/npm-packages.toml
      NIX_FILE=$DEVENV_ROOT/apps/fetcher/npm-packages.nix
      echo "Updating NPM packages..."
      ${npm-refresh}/bin/npm-refresh $TOML_FILE > $NIX_FILE
      ${pkgs.alejandra}/bin/alejandra --quiet $NIX_FILE
    '';
  };

  # Aider assistance
  env.AIDER_LINT_CMD = "statix check";
  env.AIDER_TEST_CMD = "just build";
  env.AIDER_AUTO_TEST = "true";

  enterShell = ''
    export PATH="$PATH:$HOME/.local/bin"
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
