# Home Manager feature: Woodpecker CI agent (macOS iOS builder)
_: {
  my.modules.home-manager.woodpecker-agent = {
    imports = [../home-manager/features/woodpecker-agent.nix];
  };
}
