# Home Manager feature: editor configuration (helix, etc.)
{...}: {
  my.modules.home-manager.editor = {
    imports = [../home-manager/features/editor.nix];
  };
}
