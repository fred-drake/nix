# Home Manager feature: development tools (git, direnv, etc.)
_: {
  my.modules.home-manager.dev-tools = {
    imports = [../home-manager/features/dev-tools.nix];
  };
}
