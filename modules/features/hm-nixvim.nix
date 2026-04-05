# Home Manager feature: Nixvim configuration
_: {
  my.modules.home-manager.nixvim = {
    imports = [../home-manager/features/nixvim.nix];
  };
}
