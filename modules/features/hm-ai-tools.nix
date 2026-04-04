# Home Manager feature: AI tools configuration
{...}: {
  my.modules.home-manager.ai-tools = {
    imports = [../home-manager/features/ai-tools.nix];
  };
}
