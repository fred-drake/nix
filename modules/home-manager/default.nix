{...}: {
  imports = [
    ./features/nixvim.nix
    ./features/shells.nix
    ./features/editor.nix
    ./features/dev-tools.nix
    ./features/terminal.nix
    ./features/dotfiles.nix
    ./features/vscode-family.nix
    ./features/network-tools.nix
    ./features/media-apps.nix
    ./features/ai-tools.nix
    ./secrets.nix
    ./claude-code.nix
  ];

  programs.neovim.enable = false;

  home.stateVersion = "24.05";
}
