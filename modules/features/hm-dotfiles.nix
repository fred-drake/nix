# Home Manager feature: dotfile management (home.file entries)
_: {
  my.modules.home-manager.dotfiles = {
    imports = [../home-manager/features/dotfiles.nix];
  };
}
