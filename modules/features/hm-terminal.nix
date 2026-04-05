# Home Manager feature: terminal emulator configuration (kitty, tmux, etc.)
_: {
  my.modules.home-manager.terminal = {
    imports = [../home-manager/features/terminal.nix];
  };
}
