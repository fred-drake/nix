# Home Manager feature: Claude Code configuration
{...}: {
  my.modules.home-manager.claude-code = {
    imports = [../home-manager/features/claude-code.nix];
  };
}
