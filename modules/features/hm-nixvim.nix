# Home Manager feature: Nixvim configuration
{...}: {
  my.modules.home-manager.nixvim = {
    imports = [../home-manager/features/nixvim.nix];
  };
}
