# Home Manager feature: terminal emulator configuration (kitty, tmux, etc.)
{...}: {
  my.modules.home-manager.terminal = {
    imports = [../home-manager/features/terminal.nix];
  };
}
