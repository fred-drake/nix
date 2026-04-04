# Home Manager feature: VS Code / Cursor / Windsurf configuration
{...}: {
  my.modules.home-manager.vscode-family = {
    imports = [../home-manager/features/vscode-family.nix];
  };
}
