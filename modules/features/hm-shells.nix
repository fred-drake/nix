# Home Manager feature: shell configuration (fish, bash, starship, etc.)
{...}: {
  my.modules.home-manager.shells = {
    imports = [../home-manager/features/shells.nix];
  };
}
