{pkgs, ...}: let
  nix4vscode = pkgs.callPackage ./nix4vscode.nix {};
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
    update-nvim-plugins.exec = ''
      SRCFILE=$DEVENV_ROOT/apps/nixvim/plugins/plugins-src.nix
      echo "####################################" > $SRCFILE
      echo "# Auto-generated -- do not modify! #" >> $SRCFILE
      echo "####################################" >> $SRCFILE
      echo "{pkgs, ...}: {" >> $SRCFILE
      ${pkgs.tomlq}/bin/tq --file apps/nixvim/plugins/plugins.toml --output json '.plugins' | \
      ${pkgs.jq}/bin/jq -r '.[] | "\(.name) = \(.url)"' | \
      while IFS== read -r name url; do
        processed_url=pkgs.$(nurl "''${url# }" | tr -d '\n')  # Added pkgs. before nurl
        echo "  ''${name} = ''${processed_url};"  # Maintained semicolon and indentation
      done >> $SRCFILE
      echo "}" >> $SRCFILE
      ${pkgs.alejandra}/bin/alejandra --quiet $SRCFILE
    '';

    system-flake-rebuild.exec = ''
      if [ ! -z "$1" ]; then
          export HOST="$1"
      else
          export HOST=$(hostname --short)
      fi

      if [ "$(uname -s)" = "Darwin" ]; then
          if [ "$HOST" = "freds-macbook-pro" ] || [ "$HOST" = "fred-macbook-pro-wireless" ]; then
              darwin-rebuild --show-trace --flake .#macbook-pro switch
          else
              darwin-rebuild --show-trace --flake .#"$HOST" switch
          fi
      else
          sudo nixos-rebuild --show-trace --flake .#"$HOST" switch
      fi
    '';

    update-cursor-extensions.exec = ''
      TOML_FILE=$DEVENV_ROOT/modules/cursor/extensions.toml
      EXTENSIONS_PATH=$DEVENV_ROOT/modules/cursor/extensions.nix
      echo "Updating Cursor extensions..."
      echo "####################################" > $EXTENSIONS_PATH
      echo "# Auto-generated -- do not modify! #" >> $EXTENSIONS_PATH
      echo "####################################" >> $EXTENSIONS_PATH
      ${nix4vscode}/bin/nix4vscode $TOML_FILE >> $EXTENSIONS_PATH
      ${pkgs.alejandra}/bin/alejandra $EXTENSIONS_PATH
    '';
  };

  # Aider assistance
  env.AIDER_LINT_CMD = "statix check";

  enterShell = ''
    uv tool install --force --python python3.12 aider-chat@latest
    uv tool upgrade aider-chat
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
