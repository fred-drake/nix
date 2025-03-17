{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  nix4vscode = pkgs.callPackage ./nix4vscode.nix {};
in {
  # https://devenv.sh/basics/

  cachix.enable =
    false;

  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
    just
    alejandra
    nixos-anywhere
    nix4vscode
    nixd
  ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  # scripts.ide.exec = ''
  #   nvim --cmd "let g:augment_workspace_folders = [\"$DEVENV_ROOT\"]"
  # '';

  scripts.system-flake-rebuild.exec = ''
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

  scripts.update-cursor-extensions.exec = ''
    TOML_FILE=./modules/cursor/extensions.toml
    EXTENSIONS_PATH=./modules/cursor/extensions.nix
    echo "Updating Cursor extensions..."
    echo "####################################" > $EXTENSIONS_PATH
    echo "# Auto-generated -- do not modify! #" >> $EXTENSIONS_PATH
    echo "####################################" >> $EXTENSIONS_PATH
    nix4vscode $TOML_FILE >> $EXTENSIONS_PATH
    alejandra $EXTENSIONS_PATH
  '';

  enterShell = ''
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
